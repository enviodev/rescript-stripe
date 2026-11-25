open Ava

test("Calculate past usage", t => {
  t->Assert.deepEqual(
    Stripe.Billing.calculatePastUsageBill(
      ~priceAmount=100,
      ~startedAt=Date.fromString("2025-01-01"),
      ~now=Date.fromString("2025-01-01"),
      ~interval=Some(Month),
    ),
    0,
  )
  t->Assert.deepEqual(
    Stripe.Billing.calculatePastUsageBill(
      ~priceAmount=100,
      ~startedAt=Date.fromString("2025-01-01"),
      ~now=Date.fromString("2025-02-01"),
      ~interval=Some(Month),
    ),
    100,
  )
  t->Assert.deepEqual(
    Stripe.Billing.calculatePastUsageBill(
      ~priceAmount=100,
      ~startedAt=Date.fromString("2025-01-01"),
      ~now=Date.fromString("2025-03-01"),
      ~interval=Some(Month),
    ),
    200,
  )
  t->Assert.deepEqual(
    Stripe.Billing.calculatePastUsageBill(
      ~priceAmount=100,
      ~startedAt=Date.fromString("2025-01-01"),
      ~now=Date.fromString("2025-01-15"),
      ~interval=Some(Month),
    ),
    45,
  )
})

// ---------------------------------------------------------------------------
// makeFindByMetadata: the per-process metadata cache
// ---------------------------------------------------------------------------

// A fake Stripe list endpoint over `items` (newest first, as Stripe lists),
// counting calls. Its promise also carries autoPagingToArray, which the
// catch-up path calls on the list result like the Stripe SDK's.
type fakeServer = {
  mutable items: array<Stripe.objectWithMetadata>,
  mutable listCalls: int,
}

let fakeList: (fakeServer, Stripe.baseListParams) => promise<Stripe.page<Stripe.objectWithMetadata>> = %raw(`
  function (server, params) {
    server.listCalls += 1;
    var items = server.items.map(function (i) { return { id: i.id, metadata: Object.assign({}, i.metadata) }; });
    var data;
    if (params.ending_before !== undefined) {
      var end = items.findIndex(function (i) { return i.id === params.ending_before; });
      data = end === -1 ? items : items.slice(0, end);
    } else if (params.starting_after !== undefined) {
      var start = items.findIndex(function (i) { return i.id === params.starting_after; });
      data = items.slice(start + 1);
    } else {
      data = items;
    }
    var limit = params.limit || 100;
    var page = { object: "list", url: "", has_more: data.length > limit, data: data.slice(0, limit) };
    var p = Promise.resolve(page);
    p.autoPagingToArray = function () { return Promise.resolve(data); };
    return p;
  }
`)

let fakeRetrieve: (fakeServer, string) => promise<Stripe.objectWithMetadata> = %raw(`
  function (server, id) {
    var i = server.items.find(function (i) { return i.id === id; });
    return Promise.resolve(i ? { id: i.id, metadata: Object.assign({}, i.metadata) } : { id: id, metadata: {}, deleted: true });
  }
`)

let item = (id, metadata): Stripe.objectWithMetadata => {id, metadata: Dict.fromArray(metadata)}

let makeFind = (server, ~clock: ref<float>) =>
  Stripe.makeFindByMetadata(
    ~name="customer",
    ~list=(_, params) => fakeList(server, params),
    ~retrieve=(_, id) => fakeRetrieve(server, id),
    ~now=() => clock.contents,
  )

let stripe: Stripe.stripe = Obj.magic(0)
let org = Dict.fromArray([("organisation_id", "org1")])
let foundId = (found: option<Stripe.objectWithMetadata>) => found->Option.map(c => c.id)

asyncTest("Finds an existing customer tagged after the cache was filled", async t => {
  let server = {
    items: [item("cus_A", [("organisation_id", "org1")]), item("cus_B", [])],
    listCalls: 0,
  }
  let clock = ref(1_000_000.)
  let find = makeFind(server, ~clock)
  t->Assert.deepEqual(foundId(await find(stripe, org)), Some("cus_A"))

  // An admin moves the org from A to B: A is untagged, B (older than the
  // newest cached customer) is tagged.
  server.items = [item("cus_A", []), item("cus_B", [("organisation_id", "org1")])]
  clock := clock.contents +. 61_000.

  // Before: the stale A match returned None, and B stayed invisible until a
  // restart, so findOrCreateByMetadata created a third customer.
  t->Assert.deepEqual(foundId(await find(stripe, org)), Some("cus_B"))
  // From the cache from now on: one re-read, no further listing.
  let calls = server.listCalls
  t->Assert.deepEqual(foundId(await find(stripe, org)), Some("cus_B"))
  t->Assert.deepEqual(server.listCalls, calls)
})

asyncTest("A miss re-lists from scratch at most once per refresh interval", async t => {
  let server = {items: [item("cus_A", []), item("cus_B", [])], listCalls: 0}
  let clock = ref(1_000_000.)
  let find = makeFind(server, ~clock)
  // Fills the cache from scratch: one list call.
  t->Assert.deepEqual(foundId(await find(stripe, org)), None)
  t->Assert.deepEqual(server.listCalls, 1)

  // Within the interval a miss only catches up on new customers.
  clock := clock.contents +. 30_000.
  t->Assert.deepEqual(foundId(await find(stripe, org)), None)
  t->Assert.deepEqual(server.listCalls, 2)

  // B is tagged; still within the interval, so it is not seen yet.
  server.items = [item("cus_A", []), item("cus_B", [("organisation_id", "org1")])]
  clock := clock.contents +. 20_000.
  t->Assert.deepEqual(foundId(await find(stripe, org)), None)

  // Past the interval the miss re-lists and finds it.
  clock := clock.contents +. 11_000.
  t->Assert.deepEqual(foundId(await find(stripe, org)), Some("cus_B"))
})

asyncTest("A customer created after the cache was filled is found by catching up", async t => {
  let server = {items: [item("cus_A", [])], listCalls: 0}
  let clock = ref(1_000_000.)
  let find = makeFind(server, ~clock)
  t->Assert.deepEqual(foundId(await find(stripe, org)), None)

  server.items = [item("cus_C", [("organisation_id", "org1")]), item("cus_A", [])]
  // Within the interval: found by the catch-up alone, no re-list.
  clock := clock.contents +. 1_000.
  t->Assert.deepEqual(foundId(await find(stripe, org)), Some("cus_C"))
  t->Assert.deepEqual(server.listCalls, 2)
})

asyncTest("A stale cached match is corrected and the search continues", async t => {
  let server = {
    items: [item("cus_A", [("organisation_id", "org1")]), item("cus_B", [])],
    listCalls: 0,
  }
  let clock = ref(1_000_000.)
  let find = makeFind(server, ~clock)
  t->Assert.deepEqual(foundId(await find(stripe, org)), Some("cus_A"))

  // A loses the tag and a new customer C gets it.
  server.items = [
    item("cus_C", [("organisation_id", "org1")]),
    item("cus_A", []),
    item("cus_B", []),
  ]
  // Before: None on the stale A, without looking further.
  t->Assert.deepEqual(foundId(await find(stripe, org)), Some("cus_C"))
})
