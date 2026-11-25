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
  // Fail full listings (not the catch-up of newer customers).
  mutable failFullLists?: bool,
}

let fakeList: (fakeServer, Stripe.baseListParams) => promise<Stripe.page<Stripe.objectWithMetadata>> = %raw(`
  function (server, params) {
    server.listCalls += 1;
    if (server.failFullLists && params.ending_before === undefined) {
      var failed = Promise.reject(new Error("stripe list failed"));
      failed.catch(function () {});
      failed.autoPagingToArray = function () { return Promise.reject(new Error("stripe list failed")); };
      return failed;
    }
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

let makeFindWith = (server, ~clock: ref<float>) =>
  Stripe.makeFindByMetadata(
    ~name="customer",
    ~list=(_, params) => fakeList(server, params),
    ~retrieve=(_, id) => fakeRetrieve(server, id),
    ~now=() => clock.contents,
  )

// As findOrCreateByMetadata calls it: re-list on a miss before creating.
let makeFind = (server, ~clock) => {
  let find = makeFindWith(server, ~clock)
  (stripe, metadata) => find(stripe, ~refreshOnMiss=true, metadata)
}

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

asyncTest("A failed refresh keeps the previous cache", async t => {
  let server = {items: [item("cus_A", []), item("cus_B", [("organisation_id", "org1")])], listCalls: 0}
  let clock = ref(1_000_000.)
  let find = makeFind(server, ~clock)
  t->Assert.deepEqual(foundId(await find(stripe, org)), Some("cus_B"))

  // A miss past the interval re-lists, and Stripe's list fails.
  server.failFullLists = Some(true)
  clock := clock.contents +. 61_000.
  let failed = try {
    let _ = await find(stripe, Dict.fromArray([("organisation_id", "org2")]))
    false
  } catch {
  | _ => true
  }
  t->Assert.is(failed, true)

  // The cached customer is still found by id: before the restore the cache
  // was left empty, and this lookup's full listing would fail too.
  t->Assert.deepEqual(foundId(await find(stripe, org)), Some("cus_B"))
})

asyncTest("A miss after the older pages are scanned still refreshes", async t => {
  // 150 customers: the first lookup matches on the first page of 100, so the
  // cache stays partial.
  let ids = Array.fromInitializer(~length=150, i => `cus_${i->Int.toString}`)
  let server = {
    items: ids->Array.map(id => item(id, id == "cus_5" ? [("organisation_id", "org1")] : [])),
    listCalls: 0,
  }
  let clock = ref(1_000_000.)
  let find = makeFind(server, ~clock)
  t->Assert.deepEqual(foundId(await find(stripe, org)), Some("cus_5"))

  // A cached first-page customer is tagged for another org.
  let org2 = Dict.fromArray([("organisation_id", "org2")])
  server.items = ids->Array.map(id =>
    item(
      id,
      switch id {
      | "cus_5" => [("organisation_id", "org1")]
      | "cus_10" => [("organisation_id", "org2")]
      | _ => []
      },
    )
  )
  clock := clock.contents +. 61_000.
  // Before: catching up and scanning the older pages missed, and it returned
  // None without the refresh.
  t->Assert.deepEqual(foundId(await find(stripe, org2)), Some("cus_10"))
})

asyncTest("An empty completed scan follows the refresh interval", async t => {
  let server = {items: [], listCalls: 0}
  let clock = ref(1_000_000.)
  let find = makeFind(server, ~clock)
  t->Assert.deepEqual(foundId(await find(stripe, org)), None)
  t->Assert.deepEqual(server.listCalls, 1)
  clock := clock.contents +. 1_000.
  t->Assert.deepEqual(foundId(await find(stripe, org)), None)
  t->Assert.deepEqual(server.listCalls, 1)
  clock := clock.contents +. 60_000.
  server.items = [item("cus_A", [("organisation_id", "org1")])]
  t->Assert.deepEqual(foundId(await find(stripe, org)), Some("cus_A"))
})

asyncTest("A plain lookup never re-lists on a miss", async t => {
  let server = {items: [item("cus_A", []), item("cus_B", [])], listCalls: 0}
  let clock = ref(1_000_000.)
  let find = makeFindWith(server, ~clock)
  t->Assert.deepEqual(foundId(await find(stripe, org)), None)
  t->Assert.deepEqual(server.listCalls, 1)

  // B is tagged; long past the interval, a plain miss only catches up on new
  // customers (one call), never a full scan.
  server.items = [item("cus_A", []), item("cus_B", [("organisation_id", "org1")])]
  clock := clock.contents +. 600_000.
  t->Assert.deepEqual(foundId(await find(stripe, org)), None)
  t->Assert.deepEqual(server.listCalls, 2)

  // The create path's lookup does re-list, and finds it.
  t->Assert.deepEqual(foundId(await find(stripe, ~refreshOnMiss=true, org)), Some("cus_B"))
})
