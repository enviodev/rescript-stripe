open Ava

test("Metadata.ref supports optional schemas", t => {
  // Regression: `S.string->S.coerce(S.option(...))` panics because coercing a
  // string to `string | undefined` isn't supported. Metadata.ref must handle
  // optional schemas by coercing the inner schema and wrapping it in an option.
  let optString = Stripe.Metadata.ref("opt_string", S.option(S.string))
  let optInt = Stripe.Metadata.ref("opt_int", S.option(S.int))

  // Present values are coerced from their stored string representation.
  t->Assert.deepEqual("hello"->S.parseOrThrow(optString.coereced), Some("hello"))
  t->Assert.deepEqual("5"->S.parseOrThrow(optInt.coereced), Some(5))

  // Missing values parse to None.
  t->Assert.deepEqual(%raw(`undefined`)->S.parseOrThrow(optInt.coereced), None)
})

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
