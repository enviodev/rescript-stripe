module Stdlib = {
  module Promise = {
    type t<+'a> = promise<'a>

    @new
    external make: ((@uncurry 'a => unit, 'e => unit) => unit) => t<'a> = "Promise"

    @val @scope("Promise")
    external resolve: 'a => t<'a> = "resolve"

    @send external then: (t<'a>, @uncurry 'a => t<'b>) => t<'b> = "then"

    @send
    external thenResolve: (t<'a>, @uncurry 'a => 'b) => t<'b> = "then"

    @send external finally: (t<'a>, unit => unit) => t<'a> = "finally"

    @scope("Promise") @val
    external reject: exn => t<_> = "reject"

    @scope("Promise") @val
    external all: array<t<'a>> => t<array<'a>> = "all"

    @scope("Promise") @val
    external all2: ((t<'a>, t<'b>)) => t<('a, 'b)> = "all"

    @scope("Promise") @val
    external all3: ((t<'a>, t<'b>, t<'c>)) => t<('a, 'b, 'c)> = "all"

    @scope("Promise") @val
    external all4: ((t<'a>, t<'b>, t<'c>, t<'d>)) => t<('a, 'b, 'c, 'd)> = "all"

    @scope("Promise") @val
    external all5: ((t<'a>, t<'b>, t<'c>, t<'d>, t<'e>)) => t<('a, 'b, 'c, 'd, 'e)> = "all"

    @scope("Promise") @val
    external all6: ((t<'a>, t<'b>, t<'c>, t<'d>, t<'e>, t<'f>)) => t<('a, 'b, 'c, 'd, 'e, 'f)> =
      "all"

    @send
    external catch: (t<'a>, @uncurry exn => t<'a>) => t<'a> = "catch"

    let catch = (promise: promise<'a>, callback: exn => promise<'a>): promise<'a> => {
      catch(promise, err => {
        callback(Js.Exn.anyToExnInternal(err))
      })
    }

    @scope("Promise") @val
    external race: array<t<'a>> => t<'a> = "race"

    external done: promise<'a> => unit = "%ignore"

    external unsafe_async: 'a => promise<'a> = "%identity"
    external unsafe_await: promise<'a> => 'a = "?await"
  }

  module Dict = {
    let unsafeDeleteKey: (dict<'a>, string) => unit = %raw(`function (dict,key) {
      delete dict[key];
    }`)
  }
}

type stripe

@module("stripe") @new external make: string => stripe = "default"
// Prevent "stripe" import in the user's code
let make = make

type page<'item> = {
  object: string,
  url: string,
  @as("has_more")
  hasMore: bool,
  data: array<'item>,
}

@unboxed
type currency = | @as("usd") USD | ISO(string)

@unboxed
type taxBehavior =
  | @as("exclusive") Exclusive | @as("inclusive") Inclusive | @as("unspecified") Unspecified

module Meter = {
  type status = | @as("active") Active | @as("inactive") Inactive

  type t = {
    id: string,
    object: string,
    created: int,
    // customer_mapping
    @as("display_name")
    displayName: string,
    @as("event_name")
    eventName: string,
    // event_time_window
    // livemode
    // status
    // status_transitions
    // updated
    // value_settings
  }

  type aggregationFormula = | @as("sum") Sum | @as("count") Count

  type defaultAggregation = {formula: aggregationFormula}

  type createParams = {
    @as("default_aggregation")
    defaultAggregation: defaultAggregation,
    @as("display_name")
    displayName: string,
    @as("event_name")
    eventName: string,
    @as("customer_mapping")
    customerMapping?: unknown,
    @as("event_time_window")
    eventTimeWindow?: unknown,
    @as("value_settings")
    valueSettings?: unknown,
  }

  @scope(("billing", "meters")) @send
  external create: (stripe, createParams) => promise<t> = "create"

  type listParams = {status?: status, limit?: int}
  @scope(("billing", "meters")) @send
  external list: (stripe, listParams) => promise<page<t>> = "list"
}

module Price = {
  type interval =
    | @as("day") Day
    | @as("week") Week
    | @as("month") Month
    | @as("year") Year

  type usageType = | @as("metered") Metered | @as("licensed") Licensed

  type recurring = {
    interval: interval,
    meter: Js.Null.t<string>,
    @as("interval_count") intervalCount: int,
    @as("usage_type") usageType: usageType,
  }

  type t = {
    id: string,
    active: bool,
    currency: currency,
    metadata: dict<string>,
    nickname: Js.Null.t<string>,
    product: string,
    recurring: Js.Null.t<recurring>,
    interval: interval,
    created: int,
    @as("lookup_key")
    lookupKey: Js.Null.t<string>,
    @as("unit_amount")
    unitAmountInCents: Js.Null.t<int>,
  }

  type recurringParams = {
    interval: interval,
    @as("aggregate_usage")
    aggregateUsage?: unknown,
    @as("interval_count")
    intervalCount?: int,
    @as("meter")
    meter?: string,
    @as("usage_type")
    usageType?: usageType,
  }

  type createParams = {
    currency: currency,
    product: string,
    active?: bool,
    metadata?: dict<string>,
    nickname?: string,
    recurring?: recurringParams,
    @as("tax_behavior")
    taxBehavior?: taxBehavior,
    @as("unit_amount")
    unitAmountInCents: int,
    @as("billing_scheme")
    billingScheme?: unknown,
    @as("currency_options")
    currencyOptions?: unknown,
    @as("lookup_key")
    lookupKey?: string,
    @as("transfer_lookup_key")
    transferLookupKey?: bool,
  }
  @scope("prices") @send
  external create: (stripe, createParams) => promise<t> = "create"

  type updateParams = {mutable active?: bool}
  @scope("prices") @send
  external update: (stripe, string, updateParams) => promise<t> = "update"

  type listParams = {active?: bool, product?: string}
  @scope("prices") @send
  external list: (stripe, listParams) => promise<page<t>> = "list"
}

module Product = {
  /** https://docs.stripe.com/api/products/object */
  type t = {
    id: string,
    active: bool,
    name: string,
    @as("unit_label")
    unitLabel: Js.Null.t<string>,
  }

  type defaultPriceData = {
    currency: currency,
    @as("unit_amount")
    unitAmountInCents: int,
    @as("currency_options")
    currencyOptions?: array<unknown>,
    recurring?: Price.recurringParams,
    @as("tax_behavior")
    taxBehavior?: taxBehavior,
  }

  type createParams = {
    name: string,
    active?: bool,
    description?: string,
    id?: string,
    metadata?: dict<string>,
    @as("tax_code")
    taxCode?: string,
    @as("default_price_data")
    defaultPriceData?: defaultPriceData,
    images?: array<string>,
    @as("marketing_features")
    marketingFeatures?: array<unknown>,
    @as("package_dimensions")
    packageDimensions?: unknown,
    shippable?: bool,
    @as("statement_descriptor")
    statementDescriptor?: string,
    @as("unit_label")
    unitLabel?: string,
    url?: string,
  }

  @scope("products") @send
  external create: (stripe, createParams) => promise<t> = "create"

  type updateParams = {
    @as("unit_label")
    mutable unitLabel?: string,
  }
  @scope("products") @send
  external update: (stripe, string, updateParams) => promise<t> = "update"

  type listParams = {active?: bool}
  @scope("products") @send
  external list: (stripe, listParams) => promise<page<t>> = "list"

  type searchParams = {query: string, limit?: int, page?: string}
  @scope("products") @send
  external search: (stripe, searchParams) => promise<page<t>> = "search"
}

module ProductCatalog = {
  type recurringConfig =
    | Metered({interval: Price.interval, ref: string})
    | Licensed({interval: Price.interval})

  type priceConfig = {
    currency: currency,
    lookupKey?: string,
    unitAmountInCents: int,
    recurring: recurringConfig,
  }

  type productConfig = {
    name: string,
    ref: string,
    prices: array<priceConfig>,
    unitLabel?: string,
  }

  type syncedProduct = {
    product: Product.t,
    prices: array<Price.t>,
  }

  type t = {products: array<productConfig>}

  let syncProduct = async (
    stripe: stripe,
    productConfig: productConfig,
    ~meters: option<dict<Meter.t>>=?,
  ) => {
    Js.log(`Searching for active product "${productConfig.ref}"...`)
    let product = switch await stripe->Product.search({
      query: `active:"true" AND metadata["product_ref"]:"${productConfig.ref}"`,
      limit: 2,
    }) {
    | {data: []} => {
        Js.log(`No active product "${productConfig.ref}" found. Creating a new one...`)
        let p = await stripe->Product.create({
          name: productConfig.name,
          unitLabel: ?productConfig.unitLabel,
          metadata: Js.Dict.fromArray([("product_ref", productConfig.ref)]),
        })
        Js.log(`Product "${productConfig.ref}" successfully created. Product ID: ${p.id}`)
        p
      }
    | {data: [p]} => {
        Js.log(`Found an existing product "${productConfig.ref}". Product ID: ${p.id}`)

        let fieldsToSync: Product.updateParams = {}

        switch (p.unitLabel, productConfig.unitLabel) {
        | (Value(v), Some(configured)) if v === configured => ()
        | (Null, None) => ()
        | (_, Some(configured)) => fieldsToSync.unitLabel = Some(configured)
        | (_, None) => fieldsToSync.unitLabel = Some("")
        }

        let fieldNamesToSync = Js.Dict.keys(fieldsToSync->Obj.magic)

        if fieldNamesToSync->Js.Array2.length > 0 {
          Js.log(
            `Syncing product "${productConfig.ref}" fields ${fieldNamesToSync->Js.Array2.joinWith(
                ", ",
              )}...`,
          )
          let p = await stripe->Product.update(p.id, fieldsToSync)
          Js.log(`Product "${productConfig.ref}" fields successfully updated`)
          p
        } else {
          Js.log(`Product "${productConfig.ref}" is in sync`)
          p
        }
      }
    | {data: _} =>
      Js.Exn.raiseError(
        `There are multiple active products "${productConfig.ref}". Please go to dashboard and delete not needed ones (https://dashboard.stripe.com/test/products?active=true)`,
      )
    }

    Js.log(`Searching for product "${productConfig.ref}" active prices...`)
    let prices = await stripe->Price.list({product: product.id, active: true})
    Js.log(
      `Found ${prices.data
        ->Js.Array2.length
        ->Js.Int.toString} product "${productConfig.ref}" active prices`,
    )
    if prices.hasMore {
      Js.Exn.raiseError(
        `The pagination on prices is not supported yet. Product "${productConfig.ref}" has to many active prices`,
      )
    }

    let createPriceFromConfig = async (priceConfig, ~transferLookupKey=?) => {
      await stripe->Price.create({
        currency: priceConfig.currency,
        product: product.id,
        unitAmountInCents: priceConfig.unitAmountInCents,
        lookupKey: ?priceConfig.lookupKey,
        metadata: ?switch priceConfig.recurring {
        | Licensed(_) => None
        // TODO: Also save meter_event_name
        | Metered({ref}) => Some(Js.Dict.fromArray([("#meter_ref", ref)]))
        },
        recurring: switch priceConfig.recurring {
        | Licensed({interval}) => {interval: interval}
        | Metered({interval, ref}) => {
            let meters = switch meters {
            | Some(m) => m
            | None =>
              Js.Exn.raiseError(`The Meters hash map argument is required when you defined metered prices`)
            }
            let meter = switch meters->Js.Dict.get(ref) {
            | Some(meter) => meter
            | None =>
              Js.log(`Meter "${ref}" does not exist. Creating...`)
              let meter = await stripe->Meter.create({
                displayName: ref,
                eventName: ref,
                defaultAggregation: {
                  formula: Sum,
                },
              })
              Js.log(`Meter "${ref}" successfully created. Meter ID: ${meter.id}`)
              meter
            }

            {
              interval,
              usageType: Metered,
              meter: meter.id,
            }
          }
        },
        ?transferLookupKey,
      })
    }

    let prices =
      await productConfig.prices
      ->Js.Array2.map(async priceConfig => {
        let existingPrice = prices.data->Js.Array2.find(price => {
          let isPriceInSync =
            priceConfig.currency === price.currency &&
            priceConfig.lookupKey === price.lookupKey->Js.Null.toOption &&
            Js.Null.Value(priceConfig.unitAmountInCents) === price.unitAmountInCents &&
            switch price.recurring {
            | Null => false
            | Value(priceRecurring) =>
              switch priceConfig.recurring {
              | Licensed({interval}) =>
                priceRecurring.usageType === Licensed &&
                priceRecurring.interval === interval &&
                priceRecurring.meter === Null
              | Metered({interval, ref}) =>
                priceRecurring.usageType === Metered &&
                priceRecurring.interval === interval &&
                priceRecurring.meter->Js.Null.toOption->Js.Option.isSome &&
                price.metadata->Js.Dict.unsafeGet("#meter_ref") === ref
              }
            }
          isPriceInSync
        })
        switch existingPrice {
        | Some(price) => {
            Js.log(
              `Found an existing price "${priceConfig.lookupKey->Belt.Option.getWithDefault(
                  "-",
                )}" for product "${productConfig.ref}". Price ID: ${price.id}`,
            )
            price
          }
        | None => {
            Js.log(`A price for product "${productConfig.ref}" is not in sync. Updating...`)
            let price = await createPriceFromConfig(priceConfig, ~transferLookupKey=true)
            Js.log(
              `Price for product "${productConfig.ref}" successfully recreated with the new values. Price ID: ${price.id}`,
            )
            price
          }
        }
      })
      ->Stdlib.Promise.all

    {
      product,
      prices,
    }
  }

  let sync = async (stripe: stripe, productCatalog: t) => {
    let isMeterNeeded = productCatalog.products->Js.Array2.some(p =>
      p.prices->Js.Array2.some(p =>
        switch p.recurring {
        | Metered(_) => true
        | _ => false
        }
      )
    )

    let meters = if isMeterNeeded {
      Js.log(`Loading active meters...`)
      let {data: meters} = await stripe->Meter.list({
        status: Active,
        limit: 100,
      })
      Js.log(`Loaded ${meters->Js.Array2.length->Js.Int.toString} active meters`)
      Some(meters->Js.Array2.map(meter => (meter.eventName, meter))->Js.Dict.fromArray)
    } else {
      None
    }

    let products =
      await productCatalog.products
      ->Js.Array2.map(p => stripe->syncProduct(p, ~meters?))
      ->Stdlib.Promise.all
    Js.log(`Successfully finished syncing products`)
    products
  }
}

module Customer = {
  type t = {
    id: string,
    metadata: dict<string>,
    email: Js.Null.t<string>,
    name: Js.Null.t<string>,
  }

  type createParams = {
    name?: string,
    email?: string,
    metadata?: dict<string>,
  }
  @scope("customers") @send
  external create: (stripe, createParams) => promise<t> = "create"

  type searchParams = {
    query: string,
    limit?: int,
    page?: int,
  }
  @scope("customers") @send
  external search: (stripe, searchParams) => promise<page<t>> = "search"
}

module Subscription = {
  type status =
    | @as("incomplete") Incomplete
    | @as("trialing") Trialing
    | @as("active") Active
    | @as("past_due") PastDue
    | @as("canceled") Canceled
    | @as("unpaid") Unpaid
    | @as("incomplete_expired") IncompleteExpired
    | @as("paused") Paused

  type itemPrice = {
    ...Price.t,
  }
  type item = {
    id: string,
    object: string,
    @as("billing_thresholds")
    billingThresholds: Js.Null.t<unknown>,
    metadata: dict<string>,
    created: int,
    subscription: string,
    price: itemPrice,
  }
  type t = {
    id: string,
    metadata: dict<string>,
    status: status,
    items: page<item>,
  }

  type listParams = {
    customer?: string,
    price?: string,
    status?: status,
    limit?: int,
  }
  @scope("subscriptions") @send
  external list: (stripe, listParams) => promise<page<t>> = "list"

  let isTerminatedStatus = status => {
    switch status {
    | Incomplete
    | Trialing
    | Active
    | PastDue
    | Canceled
    | Unpaid
    | IncompleteExpired
    | Paused => false
    }
  }

  let getMeterId = (subscription, ~meterRef) => {
    subscription.items.data
    ->Js.Array2.find(item => {
      item.price.metadata->Js.Dict.unsafeGet("#meter_ref") === meterRef
    })
    ->Belt.Option.flatMap(i => i.price.recurring->Js.Null.toOption)
    ->Belt.Option.flatMap(r => r.meter->Js.Null.toOption)
  }
}

module Checkout = {
  module Session = {
    type t = {
      id: string,
      url: Js.Null.t<string>,
    }

    type termsOfService = | @as("none") None | @as("required") Required
    type mode = | @as("payment") Payment | @as("setup") Setup | @as("subscription") Subscription

    type lineItemParam = {
      price: string,
      quantity?: int,
    }

    type consentCollectionParams = {
      @as("terms_of_service")
      termsOfService: termsOfService,
    }

    type subscriptionDataParams = {
      description?: string,
      metadata?: dict<string>,
      @as("billing_cycle_anchor")
      billingCycleAnchor?: int,
    }

    type createParams = {
      mode: mode,
      @as("success_url")
      successUrl?: string,
      @as("cancel_url")
      cancelUrl?: string,
      @as("consent_collection")
      consentCollection?: consentCollectionParams,
      @as("subscription_data")
      subscriptionData?: subscriptionDataParams,
      @as("allow_promotion_codes")
      allowPromotionCodes?: bool,
      customer?: string,
      @as("line_items")
      lineItems?: array<lineItemParam>,
    }
    @scope(("checkout", "sessions")) @send
    external create: (stripe, createParams) => promise<t> = "create"
  }
}

module TieredSubscription = {
  module Tier = {
    type s = {
      metadata: 'v. (string, S.t<'v>) => 'v,
      interval: unit => Price.interval,
      product: ProductCatalog.productConfig => unit,
    }
  }

  type s = {
    primary: 'v. (string, S.t<'v>, ~customerLookup: bool=?) => 'v,
    metadata: 'v. (string, S.t<'v>) => 'v,
  }

  type t<'data, 'tier> = {
    ref: string,
    data: s => 'data,
    tiers: array<(string, Tier.s => 'tier)>,
    termsOfServiceConsent?: bool,
  }

  let refField = "#subscription_ref"
  let tierField = "#subscription_tier"

  %%private(
    let validateMetadataSchema = schema => {
      switch schema->S.classify {
      | String
      | Literal(String(_)) => ()
      | _ => Js.Exn.raiseError("Currently only string schemas are supported for data fields")
      }
    }

    let processData = (data, ~config) => {
      let primaryFields = [refField]
      let customerLookupFields = []
      let metadataFields = [refField]
      let schema = S.object(s => {
        s.tag(refField, config.ref)
        config.data({
          primary: (name, schema, ~customerLookup=false) => {
            validateMetadataSchema(schema)
            primaryFields->Js.Array2.push(name)->ignore
            metadataFields->Js.Array2.push(name)->ignore
            if customerLookup {
              customerLookupFields->Js.Array2.push(name)->ignore
            }
            s.field(name, schema)
          },
          metadata: (name, schema) => {
            validateMetadataSchema(schema)
            metadataFields->Js.Array2.push(name)->ignore
            s.field(name, schema)
          },
        })
      })

      if customerLookupFields->Js.Array2.length === 0 {
        Js.Exn.raiseError(
          "The data schema must define at least one primary field with ~customerLookup=true",
        )
      }
      let dict: dict<string> = data->S.reverseConvertOrThrow(schema)->Obj.magic
      {
        "value": data,
        "dict": dict,
        "schema": schema,
        "primaryFields": primaryFields,
        "customerLookupFields": customerLookupFields,
        "metadataFields": metadataFields,
      }
    }

    let internalRetrieveCustomer = async (stripe, data) => {
      let customerSearchQuery =
        data["customerLookupFields"]
        ->Js.Array2.map(name => {
          `metadata["${name}"]:"${data["dict"]->Js.Dict.unsafeGet(name)}"`
        })
        ->Js.Array2.joinWith("AND")
      Js.log(`Searching for an existing customer with query: ${customerSearchQuery}`)
      switch await stripe->Customer.search({
        query: customerSearchQuery,
        limit: 2,
      }) {
      | {data: [c]} => {
          Js.log(`Successfully found customer with id: ${c.id}`)
          Some(c)
        }
      | {data: []} =>
        Js.log(`No customer found`)
        None
      | {data: _} =>
        Js.Exn.raiseError(`Found multiple customers for the search query: ${customerSearchQuery}`)
      }
    }

    let internalRetrieveSubscription = async (
      stripe,
      data,
      ~subecriptionRef,
      ~customer: Customer.t,
    ) => {
      Js.log(`Searching for an existing "${subecriptionRef}" subscription...`)
      switch await stripe->Subscription.list({
        customer: customer.id,
        limit: 100,
        status: Active,
      }) {
      | {hasMore: true} =>
        Js.Exn.raiseError(`Customers has more than 100 subscriptions, which is not supported yet`)
      | {data: subscriptions} =>
        Js.log(
          `Found ${subscriptions
            ->Js.Array2.length
            ->Js.Int.toString} subscriptions for the customer. Validating that the new subscription is not already active...`,
        )
        subscriptions->Js.Array2.find(subscription => {
          if (
            data["primaryFields"]->Js.Array2.every(name => {
              subscription.metadata->Js.Dict.unsafeGet(name) ===
                data["dict"]->Js.Dict.unsafeGet(name)
            })
          ) {
            Js.log(`Found an existing subscription. Subscription ID: ${subscription.id}`)
            if subscription.status->Subscription.isTerminatedStatus {
              Js.log(
                `The subscription is terminated with status ${(subscription.status :> string)}. Skipping...`,
              )
              false
            } else {
              true
            }
          } else {
            false
          }
        })
      }
    }
  )

  let retrieveCustomer = (stripe, ~config, data) => {
    internalRetrieveCustomer(stripe, processData(data, ~config))
  }

  let retrieveSubscription = async (stripe, ~config, data) => {
    let processedData = processData(data, ~config)
    switch await internalRetrieveCustomer(stripe, processedData) {
    | Some(customer) =>
      await internalRetrieveSubscription(
        stripe,
        processedData,
        ~customer,
        ~subecriptionRef=config.ref,
      )
    | None => None
    }
  }

  type hostedCheckoutSessionParams<'data, 'tier> = {
    config: t<'data, 'tier>,
    successUrl: string,
    cancelUrl?: string,
    billingCycleAnchor?: int,
    data: 'data,
    tier: 'tier,
    description?: string,
    allowPromotionCodes?: bool,
  }

  let createHostedCheckoutSession = async (stripe, params) => {
    let data = processData(params.data, ~config=params.config)

    let tierMetadataFields = [tierField]
    let productsByTier = Js.Dict.empty()

    let tierSchema = S.union(
      params.config.tiers->Js.Array2.map(((id, tierConfig)) => {
        S.object(s => {
          let products = []
          let tier = tierConfig({
            product: productConfig => {
              products->Js.Array2.push(productConfig)->ignore
            },
            interval: () => s.field("~~interval", S.enum([Price.Day, Week, Month, Year])),
            metadata: (name, schema) => {
              validateMetadataSchema(schema)
              tierMetadataFields->Js.Array2.push(name)->ignore
              s.field(name, schema)
            },
          })
          s.tag(tierField, id)
          productsByTier->Js.Dict.set(id, products)
          tier
        })
      }),
    )
    let rawTier: dict<string> = params.tier->S.reverseConvertOrThrow(tierSchema)->Obj.magic

    let tierId = rawTier->Js.Dict.unsafeGet(tierField)
    let products = switch productsByTier->Js.Dict.get(tierId) {
    | Some([]) => Js.Exn.raiseError(`Tier "${tierId}" doesn't have any products configured`)
    | Some(p) => p
    | None => Js.Exn.raiseError(`Tier "${tierId}" is not configured on the subscription plan`)
    }
    let specificInterval: option<Price.interval> =
      rawTier->Js.Dict.unsafeGet("~~interval")->Obj.magic

    let customer = switch await stripe->internalRetrieveCustomer(data) {
    | Some(c) => c
    | None => {
        Js.log(`Creating a new customer...`)
        let c = await Customer.create(
          stripe,
          {
            metadata: data["customerLookupFields"]
            ->Js.Array2.map(name => {
              (name, data["dict"]->Js.Dict.unsafeGet(name))
            })
            ->Js.Dict.fromArray,
          },
        )
        Js.log(`Successfully created a new customer with id: ${c.id}`)
        c
      }
    }

    switch await internalRetrieveSubscription(
      stripe,
      data,
      ~customer,
      ~subecriptionRef=params.config.ref,
    ) {
    | None => Js.log(`Customer doesn't have an active "${params.config.ref}" subscription`)
    | Some(subscription) =>
      Js.Exn.raiseError(
        `There's already an active "${subscription.id}" subscription for ${data["primaryFields"]
          ->Js.Array2.map(name => `${name}=${data["dict"]->Js.Dict.unsafeGet(name)}`)
          ->Js.Array2.joinWith(
            ", ",
          )} with the "${tierId}" tier. Either update the existing subscription or cancel it and create a new one`,
      )
    }

    let productItems = await stripe->ProductCatalog.sync({ProductCatalog.products: products})

    Js.log(
      `Creating a new checkout session for subscription "${params.config.ref}" tier "${tierId}"...`,
    )
    let session = await stripe->Checkout.Session.create({
      mode: Checkout.Session.Subscription,
      customer: customer.id,
      consentCollection: ?switch params.config.termsOfServiceConsent {
      | Some(true) => Some({Checkout.Session.termsOfService: Required})
      | _ => None
      },
      subscriptionData: {
        description: ?params.description,
        billingCycleAnchor: ?params.billingCycleAnchor,
        metadata: data["metadataFields"]
        ->Js.Array2.map(name => (name, data["dict"]->Js.Dict.unsafeGet(name)))
        ->Js.Array2.concat(
          tierMetadataFields->Js.Array2.map(name => (name, rawTier->Js.Dict.unsafeGet(name))),
        )
        ->Js.Dict.fromArray,
      },
      allowPromotionCodes: ?params.allowPromotionCodes,
      successUrl: params.successUrl,
      cancelUrl: ?params.cancelUrl,
      lineItems: productItems->Js.Array2.map(({
        prices,
        product,
      }): Checkout.Session.lineItemParam => {
        let lineItemPrice = switch (prices, specificInterval) {
        | ([], _) => Js.Exn.raiseError(`Product "${product.name}" doesn't have any prices`)
        | ([price], None) => price
        | (_, None) =>
          Js.Exn.raiseError(
            `Product "${product.name}" have multiple prices but no interval specified. Use "s.interval" to dynamically choose which price use for the tier`,
          )
        | (prices, Some(specificInterval)) =>
          switch prices->Belt.Array.reduce(None, (acc, price) => {
            let isValid = switch price {
            | {recurring: Null} => true
            | {recurring: Value({interval})} => interval === specificInterval
            }
            switch (acc, isValid) {
            | (None, true) => Some(price)
            | (Some(_), true) =>
              Js.Exn.raiseError(
                `Product "${product.name}" has multiple prices for the "${(specificInterval :> string)}" interval billing`,
              )
            | (_, false) => acc
            }
          }) {
          | None =>
            Js.Exn.raiseError(
              `Product "${product.name}" doesn't have a price for the "${(specificInterval :> string)}" interval billing`,
            )
          | Some(p) => p
          }
        }
        switch lineItemPrice {
        | {recurring: Value({meter: Value(_)}), id} => {
            price: id,
          }
        | {id} => {
            price: id,
            quantity: 1,
          }
        }
      }),
    })
    Js.log(session)
    Js.log("Successfully created a new checkout session")
  }
}
