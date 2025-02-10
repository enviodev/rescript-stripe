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
    | Metered({interval: Price.interval})
    | Licensed({interval: Price.interval})

  type priceConfig = {
    currency: currency,
    lookupKey: string,
    unitAmountInCents: int,
    recurring: recurringConfig,
  }

  type productConfig = {
    name: string,
    lookupKey: string,
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
    let unsyncedPriceConfigs = Js.Dict.empty()

    for idx in 0 to productConfig.prices->Js.Array2.length - 1 {
      let priceConfig = productConfig.prices->Js.Array2.unsafe_get(idx)
      unsyncedPriceConfigs->Js.Dict.set(priceConfig.lookupKey, priceConfig)
      switch priceConfig.recurring {
      | Licensed(_) => ()
      | Metered(_) =>
        switch meters {
        | None =>
          Js.Exn.raiseError(
            `Product "${productConfig.name}" has a mettered price. It's required to provide a map of metters to perform the sync`,
          )
        | Some(_) => ()
        }
      }
    }

    if (
      unsyncedPriceConfigs->Js.Dict.keys->Js.Array2.length !==
        productConfig.prices->Js.Array2.length
    ) {
      Js.Exn.raiseError(
        `Product '${productConfig.name}' has price configurations with duplicated lookup keys. It's allowed to have only unique lookup keys.`,
      )
    }

    Js.log(`Searching for active product "${productConfig.lookupKey}"...`)
    let product = switch await stripe->Product.search({
      query: `active:"true" AND metadata["lookup_key"]:"${productConfig.lookupKey}"`,
      limit: 2,
    }) {
    | {data: []} => {
        Js.log(`No active product "${productConfig.lookupKey}" found. Creating a new one...`)
        let p = await stripe->Product.create({
          name: productConfig.name,
          unitLabel: ?productConfig.unitLabel,
          metadata: Js.Dict.fromArray([("lookup_key", productConfig.lookupKey)]),
        })
        Js.log(`Product "${productConfig.lookupKey}" successfully created. Product ID: ${p.id}`)
        p
      }
    | {data: [p]} => {
        Js.log(`Found an existing product "${productConfig.lookupKey}". Product ID: ${p.id}`)

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
            `Syncing product "${productConfig.lookupKey}" fields ${fieldNamesToSync->Js.Array2.joinWith(
                ", ",
              )}...`,
          )
          let p = await stripe->Product.update(p.id, fieldsToSync)
          Js.log(`Product "${productConfig.lookupKey}" fields successfully updated`)
          p
        } else {
          Js.log(`Product "${productConfig.lookupKey}" is in sync`)
          p
        }
      }
    | {data: _} =>
      Js.Exn.raiseError(
        `There are multiple active products "${productConfig.lookupKey}". Please go to dashboard and delete not needed ones (https://dashboard.stripe.com/test/products?active=true)`,
      )
    }

    Js.log(`Searching for product "${productConfig.lookupKey}" active prices...`)
    let prices = await stripe->Price.list({product: product.id, active: true})
    Js.log(
      `Found ${prices.data
        ->Js.Array2.length
        ->Js.Int.toString} product "${productConfig.lookupKey}" active prices`,
    )
    if prices.hasMore {
      Js.Exn.raiseError(
        `The pagination on prices is not supported yet. Product "${productConfig.lookupKey}" has to many active prices`,
      )
    }

    let createPriceFromConfig = async (priceConfig, ~transferLookupKey=?) => {
      await stripe->Price.create({
        currency: priceConfig.currency,
        product: product.id,
        unitAmountInCents: priceConfig.unitAmountInCents,
        lookupKey: priceConfig.lookupKey,
        recurring: switch priceConfig.recurring {
        | Licensed({interval}) => {interval: interval}
        | Metered({interval}) => {
            let meter = switch meters->Belt.Option.getExn->Js.Dict.get(priceConfig.lookupKey) {
            | Some(meter) => meter
            | None =>
              Js.log(`Meter "${priceConfig.lookupKey}" does not exist. Creating...`)
              let meter = await stripe->Meter.create({
                displayName: priceConfig.lookupKey,
                eventName: priceConfig.lookupKey,
                defaultAggregation: {
                  formula: Sum,
                },
              })
              Js.log(`Meter "${priceConfig.lookupKey}" successfully created. Meter ID: ${meter.id}`)
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

    let priceUpdatePromises = prices.data->Js.Array2.map(async price => {
      let maybePriceConfig = switch price.lookupKey {
      | Value(lookupKey) => unsyncedPriceConfigs->Js.Dict.get(lookupKey)
      | Null => None
      }
      switch maybePriceConfig {
      | Some(priceConfig) =>
        unsyncedPriceConfigs->Stdlib.Dict.unsafeDeleteKey(priceConfig.lookupKey)
        Js.log(`Found an existing price "${priceConfig.lookupKey}". Price ID: ${price.id}`)
        let isPriceInSync =
          priceConfig.currency === price.currency &&
          Js.Null.Value(priceConfig.unitAmountInCents) === price.unitAmountInCents &&
          switch price.recurring {
          | Null => false
          | Value(priceRecurring) =>
            switch priceConfig.recurring {
            | Licensed({interval}) =>
              priceRecurring.usageType === Licensed &&
              priceRecurring.interval === interval &&
              priceRecurring.meter === Null
            | Metered({interval}) =>
              priceRecurring.usageType === Metered &&
              priceRecurring.interval === interval &&
              priceRecurring.meter->Js.Null.toOption ===
                meters
                ->Belt.Option.getExn
                ->Js.Dict.get(priceConfig.lookupKey)
                ->Belt.Option.map(m => m.id)
            }
          }
        if isPriceInSync {
          Js.log(`Price "${priceConfig.lookupKey}" is in sync`)
          Some(price)
        } else {
          Js.log(`Price "${priceConfig.lookupKey}" is not in sync. Updating...`)
          let (newPrice, _) = await Stdlib.Promise.all2((
            createPriceFromConfig(priceConfig, ~transferLookupKey=true),
            stripe->Price.update(price.id, {active: false}),
          ))
          Js.log(
            `Price "${priceConfig.lookupKey}" successfully recreated with the new values. New Price ID: ${newPrice.id}. Old Price ID: ${price.id}`,
          )
          Some(newPrice)
        }
      | None => {
          Js.log(
            `Price ${price.id} with lookupKey ${price.lookupKey->Obj.magic} is not configured on product ${productConfig.lookupKey}. Setting it to inactive...`,
          )
          let _ = await stripe->Price.update(price.id, {active: false})
          Js.log(`Price ${price.id} successfully set to inactive`)
          None
        }
      }
    })

    let priceCreatePromises =
      unsyncedPriceConfigs
      ->Js.Dict.values
      ->Js.Array2.map(async priceConfig => {
        Js.log(
          `Price "${priceConfig.lookupKey}" is missing on product "${productConfig.lookupKey}"". Creating it...`,
        )
        let price = await createPriceFromConfig(priceConfig)
        Js.log(`Price "${priceConfig.lookupKey}" successfully created. Price ID: ${price.id}`)
        Some(price)
      })

    let prices =
      (
        await Stdlib.Promise.all(priceUpdatePromises->Js.Array2.concat(priceCreatePromises))
      )->Belt.Array.keepMap(p => p)

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
  type t = {
    id: string,
    metadata: dict<string>,
    status: status,
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
    id: string,
    data: s => 'data,
    tiers: array<(string, Tier.s => 'tier)>,
    termsOfServiceConsent?: bool,
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
  let createHostedCheckoutSession = {
    let idField = "subscription_id"
    let tierField = "subscription_tier"

    let validateMetadataSchema = schema => {
      switch schema->S.classify {
      | String
      | Literal(String(_)) => ()
      | _ => Js.Exn.raiseError("Currently only string schemas are supported for data fields")
      }
    }

    async (stripe, params) => {
      let primaryFields = [idField]
      let customerLookupFields = []
      let dataMetadataFields = [idField]
      let tierMetadataFields = [tierField]
      let productsByTier = Js.Dict.empty()
      let dataSchema = S.object(s => {
        s.tag(idField, params.config.id)
        params.config.data({
          primary: (name, schema, ~customerLookup=false) => {
            validateMetadataSchema(schema)
            primaryFields->Js.Array2.push(name)->ignore
            dataMetadataFields->Js.Array2.push(name)->ignore
            if customerLookup {
              customerLookupFields->Js.Array2.push(name)->ignore
            }
            s.field(name, schema)
          },
          metadata: (name, schema) => {
            validateMetadataSchema(schema)
            dataMetadataFields->Js.Array2.push(name)->ignore
            s.field(name, schema)
          },
        })
      })
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
      if customerLookupFields->Js.Array2.length === 0 {
        Js.Exn.raiseError(
          "The data schema must define at least one primary field with ~customerLookup=true",
        )
      }
      let rawData: dict<string> = params.data->S.reverseConvertOrThrow(dataSchema)->Obj.magic
      let rawTier: dict<string> = params.tier->S.reverseConvertOrThrow(tierSchema)->Obj.magic

      let tierId = rawTier->Js.Dict.unsafeGet(tierField)
      let products = switch productsByTier->Js.Dict.get(tierId) {
      | Some([]) => Js.Exn.raiseError(`Tier "${tierId}" doesn't have any products configured`)
      | Some(p) => p
      | None => Js.Exn.raiseError(`Tier "${tierId}" is not configured on the subscription plan`)
      }
      let specificInterval: option<Price.interval> =
        rawTier->Js.Dict.unsafeGet("~~interval")->Obj.magic

      let customerSearchQuery =
        customerLookupFields
        ->Js.Array2.map(name => {
          `metadata["${name}"]:"${rawData->Js.Dict.unsafeGet(name)}"`
        })
        ->Js.Array2.joinWith("AND")
      Js.log(`Searching for an existing customer with query: ${customerSearchQuery}`)
      let customer = switch await stripe->Customer.search({
        query: customerSearchQuery,
        limit: 2,
      }) {
      | {data: [c]} => {
          Js.log(`Successfully found customer with id: ${c.id}`)
          c
        }
      | {data: []} =>
        Js.log(`No customer found. Creating a new one...`)
        let c = await Customer.create(
          stripe,
          {
            metadata: customerLookupFields
            ->Js.Array2.map(name => {
              (name, rawData->Js.Dict.unsafeGet(name))
            })
            ->Js.Dict.fromArray,
          },
        )
        Js.log(`Successfully created a new customer with id: ${c.id}`)
        c
      | {data: _} =>
        Js.Exn.raiseError(`Found multiple customers for the search query: ${customerSearchQuery}`)
      }

      Js.log(`Searching for an existing "${params.config.id}" subscription...`)
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
        let maybeExistingSubscription = subscriptions->Js.Array2.find(subscription => {
          if (
            primaryFields->Js.Array2.every(name => {
              subscription.metadata->Js.Dict.unsafeGet(name) === rawData->Js.Dict.unsafeGet(name)
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
        switch maybeExistingSubscription {
        | None => Js.log(`Customer doesn't have an active "${params.config.id}" subscription`)
        | Some(subscription) =>
          Js.Exn.raiseError(
            `There's already an active "${subscription.id}" subscription for ${primaryFields
              ->Js.Array2.map(name => `${name}=${rawData->Js.Dict.unsafeGet(name)}`)
              ->Js.Array2.joinWith(
                ", ",
              )} with the "${tierId}" tier. Either update the existing subscription or cancel it and create a new one`,
          )
        }
      }

      let productItems = await stripe->ProductCatalog.sync({ProductCatalog.products: products})

      Js.log(
        `Creating a new checkout session for subscription "${params.config.id}" tier "${tierId}"...`,
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
          metadata: dataMetadataFields
          ->Js.Array2.map(name => (name, rawData->Js.Dict.unsafeGet(name)))
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
      Js.log("Successfully created a new checkout session")
      Js.log(session)
    }
  }
}
