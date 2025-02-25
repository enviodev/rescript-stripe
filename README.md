# ReScript Stripe 💸

ReScript client for the Stripe API.

```
npm install rescript-stripe
```

## Bindings

The package contains partial bindings for the Stripe NodeJs client.

Please, create a PR if you need something missing.

## Billing as a Config

Describe your Billing as a config and interact with Stripe API with the best DX possible and Git history.

```rescript
module CourseSubscription = {
  type data = {
    userId: string,
    courseName: string,
    courseId: string,
  }
  type plan =
    | Starter
    | Pro({withExtraSeats: bool})

  let userId = Stripe.Metadata.ref("user_id", S.string)
  let courseId = Stripe.Metadata.ref("course_id", S.string)
  let withExtraSeats = Stripe.Metadata.ref("with_extra_seats", S.bool)

  let config = {
    Stripe.Billing.ref: "course",
    data: s => {
      userId: s.primary(userId, ~customerLookup=true),
      courseId: s.primary(courseId),
      courseName: s.matches(S.string),
    },
    termsOfServiceConsent: true,
    plans: [
      (
        "starter",
        s => {
          s.tag(withExtraSeats, false)
          Starter
        },
      ),
      (
        "pro",
        s => {
          Pro({
            withExtraSeats: s.field(withExtraSeats),
          })
        },
      ),
    ],
    products: (~plan, ~data) => {
      switch plan {
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
await stripe->Stripe.Billing.createHostedCheckoutSession({
  config: CourseSubscription.config,
  data: {
    userId: "dzakh",
    courseId: "rescript-schema-to-the-moon",
    courseName: "ReScript Schema to the Moon",
  },
  plan: Starter,
  interval: Month,
  allowPromotionCodes: true,
  successUrl: `https://x.com/dzakh_dev`,
})
```

### Retrieve customer

```rescript
let customer = await stripe->Stripe.Billing.retrieveCustomer({
  userId: "dzakh",
  courseId: "rescript-schema-to-the-moon",
  courseName: "ReScript Schema to the Moon",
}, ~config=CourseSubscription.config)
```

### Retrieve subscription

```rescript
let subscription = await stripe->Stripe.Billing.retrieveSubscription({
  userId: "dzakh",
  courseId: "rescript-schema-to-the-moon",
  courseName: "ReScript Schema to the Moon",
}, ~config=CourseSubscription.config)
```

#### Retrieve subscription with customer

```rescript
let {subscription, customer} = await stripe->Stripe.Billing.retrieveSubscriptionWithCustomer({
  userId: "dzakh",
  courseId: "rescript-schema-to-the-moon",
  courseName: "ReScript Schema to the Moon",
}, ~config=CourseSubscription.config)
```

#### Get subscription metadata

```rescript
let userId = subscription->Stripe.Metadata.get(CourseSubscription.userId)
//? string
```

> 🧠 This is 100% type safe and works only on subscriptions belonging to the "Course Subscription" config.

> ⚠️ This requires that all plans have the same set of metadata fields. There's no explicit validation for this yet.

#### Verify that subscription belongs to the config

```rescript
let genericSubscription = await stripe->Stripe.Subscription.retrieve("sub_123")

let userId = subscription->Stripe.Metadata.get(CourseSubscription.userId)
//? Compilation error

subscription->Stripe.Billing.verify(CourseSubscription.config)->Option.map(subscription => {
  let userId = subscription->Stripe.Metadata.get(CourseSubscription.userId)
  //? string
  userId
})
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

### Customer portal helpers

```rescript
let link = stripe->Stripe.CustomerPortal.prefillEmail(~link="https://customer.portal.com", ~email="stripe@customer.com")
```

### Handling a WebHook with [rescript-rest](https://github.com/DZakh/rescript-rest) and [Next.js](https://nextjs.org/)

```rescript
let stripe = Stripe.make("sk_test_...")

let route = Rest.route(() => {
  path: "/api/stripe/webhook",
  method: Post,
  input: s => {
    "body": s.rawBody(S.string),
    "sig": s.header("stripe-signature", S.string),
  },
  responses: [
    s => {
      s.status(200)
      let _ = s.data(S.literal({"received": true}))
      Ok()
    },
    s => {
      s.status(400)
      Error(s.data(S.string))
    },
  ],
})

// Disable bodyParsing to make Raw Body work
let config: RestNextJs.config = {api: {bodyParser: false}}

let default = RestNextJs.handler(route, async ({input}) => {
  stripe
  ->Stripe.Webhook.constructEvent(
    ~body=input["body"],
    ~sig=input["sig"],
    // You can find your endpoint's secret in your webhook settings
    ~secret="whsec_...",
  )
  ->Result.map(event => {
    switch event {
    | CustomerSubscriptionCreated({data: {object: subscription}}) =>
      await processSubscription(subscription)
    | _ => ()
    }
  })
})
```

### Create/Find Customer and Checkout Session for selected plan

```rescript
let session = await stripe->Stripe.Billing.createHostedCheckoutSession({
  config: CourseSubscription.config,
  data: {
    userId: "dzakh",
    courseId: "rescript-schema-to-the-moon",
    courseName: "ReScript Schema to the Moon",
  },
  plan: Starter,
  interval: Year,
  allowPromotionCodes: true,
  successUrl: `https://myapp.com/success`,
})
Console.log(session.url)
```

> 🧠 It'll throw if the subscription already exist
> 🧠 Customer, products, prices, meters are automatically created when they are not found
