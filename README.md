# ReScript Stripe 💸

ReScript client for the Stripe API.

```
npm install rescript-stripe
```

## Bindings

The package contains partial bindings for the Stripe NodeJs client.

Please, create a PR if you need something missing.

## Tiered Subscriptions as a code

Describe a Tiered Subscription as a code and interact with Stripe API with the best DX possible.

```rescript
module CourseSubscription = {
  type data = {
    userId: string,
    courseName: string,
    courseId: string,
  }
  type tier =
    | Starter
    | Pro({withExtraSeats: bool})

  let config = {
    Stripe.TieredSubscription.ref: "course",
    data: s => {
      userId: s.primary("user_id", S.string, ~customerLookup=true),
      courseId: s.primary("course_id", S.string),
      courseName: s.matches(S.string),
    },
    termsOfServiceConsent: true,
    tiers: [
      (
        "starter",
        s => {
          Starter
        },
      ),
      (
        "pro",
        s => {
          Pro({
            withExtraSeats: s.metadata("with_extra_seats", S.bool),
          })
        },
      ),
    ],
    products: (~tier, ~data) => {
      switch tier {
      | Starter => [
          {
            name: data.courseName,
            ref: `starter_course_${data.courseId}`,
            prices: [
              {
                ref: `starter_course_${data.courseId}`,
                lookupKey: true,
                currency: USD,
                unitAmountInCents: 10_00,
                recurring: Licensed({
                  interval: Month,
                }),
              },
              {
                ref: `starter_course_${data.courseId}_yearly`,
                lookupKey: true,
                currency: USD,
                unitAmountInCents: 100_00,
                recurring: Licensed({
                  interval: Year,
                }),
              },
            ],
          },
        ]
      | Pro({withExtraSeats}) => [
          {
            Stripe.ProductCatalog.name: data.courseName,
            ref: `pro_course_${data.courseId}`,
            prices: [
              {
                ref: `pro_course_${data.courseId}`,
                lookupKey: true,
                currency: USD,
                unitAmountInCents: 50_00,
                recurring: Licensed({
                  interval: Month,
                }),
              },
              {
                ref: `pro_course_${data.courseId}_yearly`,
                lookupKey: true,
                currency: USD,
                unitAmountInCents: 500_00,
                recurring: Licensed({
                  interval: Year,
                }),
              },
            ],
          },
        ]->Array.concat(
          withExtraSeats ? [
            {
              Stripe.ProductCatalog.name: data.courseName ++ " Additional Seats",
              ref: `pro_course_${data.courseId}_extra_seat`,
              unitLabel: "user",
              prices: [
                {
                  ref: `pro_course_${data.courseId}_extra_seat`,
                  lookupKey: true,
                  currency: USD,
                  unitAmountInCents: 10_00,
                  recurring: Metered({
                    interval: Month,
                    ref: `extra_seat`,
                  }),
                },
                {
                  ref: `pro_course_${data.courseId}_extra_seat_yearly`,
                  currency: USD,
                  unitAmountInCents: 10_00,
                  recurring: Metered({
                    interval: Year,
                    ref: `extra_seat`,
                  }),
                }
              ]
            }]
          : []
        )
      }
    },
  }
}
```

After you described the config, you can use it to interact with Stripe API.

### Create subscription

```rescript
await stripe->Stripe.TieredSubscription.createHostedCheckoutSession({
  config: CourseSubscription.config,
  data: {
    userId: "dzakh",
    courseId: "rescript-schema-to-the-moon",
    courseName: "ReScript Schema to the Moon",
  },
  tier: Starter,
  interval: Month,
  allowPromotionCodes: true,
  successUrl: `https://x.com/dzakh_dev`,
})
```

### Retrieve customer

```rescript
let customer = await stripe->Stripe.TieredSubscription.retrieveCustomer({
  userId: "dzakh",
  courseId: "rescript-schema-to-the-moon",
  courseName: "ReScript Schema to the Moon",
}, ~config=CourseSubscription.config)
```

### Retrieve subscription

```rescript
let subscription = await stripe->Stripe.TieredSubscription.retrieveSubscription({
  userId: "dzakh",
  courseId: "rescript-schema-to-the-moon",
  courseName: "ReScript Schema to the Moon",
}, ~config=CourseSubscription.config)
```

### Get meter event name by reference

```rescript
let eventName = subscription->Stripe.Subscription.getMeterEventName(~meterRef="extra_seat")
```

ReScript Stripe might create multiple meters under the hood, so you need to call the function to get the right meter event name to report usage.

This is done because you can report meter usage per customer, so if a customer has multiple subscriptions, you need to have different meters for each one. ReScript Stripe manages this for you.

### Report usage for a subscription

```rescript
let _ =
  await stripe->Stripe.Subscription.reportMeterUsage(
    subscription,
    ~meterRef="extra_seat",
    ~value=1,
  )
```
