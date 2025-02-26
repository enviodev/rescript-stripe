module Stdlib = {
  external magic: 'a => 'b = "%identity"

  module Array = {
    let lastUnsafe = array => array->Array.getUnsafe(array->Array.length - 1)
  }
}

type stripe

@module("stripe") @new
external make: (string, @as(json`{"telemetry": false}`) _) => stripe = "default"
// Prevent "stripe" import in the user's code
let make = make

type objectWithMetadata = {
  id: string,
  metadata: dict<string>,
}

type metadataLookupCache = {
  mutable hasMore: bool,
  // Prevent race conditions for updating cache
  mutable lock: int,
  mutable items: array<objectWithMetadata>,
}

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

module MeterEvent = {
  type t
  type createParams = {
    @as("event_name")
    eventName: string,
    payload: dict<string>,
    identifier?: string,
    timestamp?: int,
  }
  @scope(("billing", "meterEvents")) @send
  external create: (stripe, createParams) => promise<t> = "create"
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
    meter: null<string>,
    @as("interval_count") intervalCount: int,
    @as("usage_type") usageType: usageType,
  }

  type t = {
    id: string,
    active: bool,
    currency: currency,
    metadata: dict<string>,
    nickname: null<string>,
    product: string,
    recurring: null<recurring>,
    interval: interval,
    created: int,
    @as("lookup_key")
    lookupKey: null<string>,
    @as("unit_amount")
    unitAmountInCents: null<int>,
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

  type listParams = {active?: bool, product?: string, limit?: int}
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
    unitLabel: null<string>,
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
    ref: string,
    currency: currency,
    unitAmountInCents: int,
    recurring: recurringConfig,
    lookupKey?: bool,
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
    ~usedCustomerMeters=?,
    ~interval: option<Price.interval>=?,
  ) => {
    Console.log(`Searching for active product "${productConfig.ref}"...`)
    let product = switch await stripe->Product.search({
      query: `active:"true" AND metadata["#product_ref"]:"${productConfig.ref}"`,
      limit: 2,
    }) {
    | {data: []} => {
        Console.log(`No active product "${productConfig.ref}" found. Creating a new one...`)
        let p = await stripe->Product.create({
          name: productConfig.name,
          unitLabel: ?productConfig.unitLabel,
          metadata: Dict.fromArray([("#product_ref", productConfig.ref)]),
        })
        Console.log(`Product "${productConfig.ref}" successfully created. Product ID: ${p.id}`)
        p
      }
    | {data: [p]} => {
        Console.log(`Found an existing product "${productConfig.ref}". Product ID: ${p.id}`)

        let fieldsToSync: Product.updateParams = {}

        switch (p.unitLabel, productConfig.unitLabel) {
        | (Value(v), Some(configured)) if v === configured => ()
        | (Null, None) => ()
        | (_, Some(configured)) => fieldsToSync.unitLabel = Some(configured)
        | (_, None) => fieldsToSync.unitLabel = Some("")
        }

        let fieldNamesToSync = Dict.keysToArray(fieldsToSync->Obj.magic)

        if fieldNamesToSync->Array.length > 0 {
          Console.log(
            `Syncing product "${productConfig.ref}" fields ${fieldNamesToSync->Array.join(
                ", ",
              )}...`,
          )
          let p = await stripe->Product.update(p.id, fieldsToSync)
          Console.log(`Product "${productConfig.ref}" fields successfully updated`)
          p
        } else {
          Console.log(`Product "${productConfig.ref}" is in sync`)
          p
        }
      }
    | {data: _} =>
      Exn.raiseError(
        `There are multiple active products "${productConfig.ref}". Please go to dashboard and delete not needed ones (https://dashboard.stripe.com/test/products?active=true)`,
      )
    }

    Console.log(`Searching for product "${productConfig.ref}" active prices...`)
    let prices = await stripe->Price.list({product: product.id, active: true, limit: 100})
    Console.log(
      `Found ${prices.data
        ->Array.length
        ->Int.toString} product "${productConfig.ref}" active prices`,
    )
    if prices.hasMore {
      Exn.raiseError(
        `The pagination on prices is not supported yet. Product "${productConfig.ref}" has to many active prices`,
      )
    }

    let createPriceFromConfig = async priceConfig => {
      let (metadata, recurring, transferLookupKey, nickname) = switch priceConfig.recurring {
      | Licensed({interval}) => (None, {Price.interval: interval}, true, None)
      | Metered({interval, ref}) => {
          let meters = switch meters {
          | Some(m) => m
          | None =>
            Exn.raiseError(`The "meters" argument is required when product catalog contains a Metered price`)
          }
          let usedCustomerMeters = switch usedCustomerMeters {
          | Some(m) => m
          | None =>
            Exn.raiseError(`The "usedCustomerMeters" argument is required when product catalog contains a Metered price`)
          }
          let rec getEventName = (~meterRef, ~counter=0) => {
            let eventName = switch counter {
            | 0 => meterRef
            | _ => `${meterRef}_${(counter + 1)->Int.toString}`
            }
            if usedCustomerMeters->Set.has(eventName) {
              getEventName(~meterRef, ~counter=counter + 1)
            } else {
              eventName
            }
          }
          let eventName = getEventName(~meterRef=ref)
          let meter = switch meters->Dict.get(eventName) {
          | Some(meter) => meter
          | None =>
            Console.log(`Meter "${eventName}" does not exist. Creating...`)
            let meter = await stripe->Meter.create({
              displayName: ref,
              eventName,
              defaultAggregation: {
                formula: Sum,
              },
            })
            Console.log(`Meter "${eventName}" successfully created. Meter ID: ${meter.id}`)
            meter
          }

          (
            Some(
              Dict.fromArray([
                ("#meter_ref", ref),
                ("#meter_event_name", eventName),
                ("#price_ref", priceConfig.ref),
              ]),
            ),
            {
              interval,
              usageType: Metered,
              meter: meter.id,
            },
            ref === eventName,
            ref === eventName ? None : Some(`Copy with meter "${eventName}"`),
          )
        }
      }

      await stripe->Price.create({
        currency: priceConfig.currency,
        product: product.id,
        unitAmountInCents: priceConfig.unitAmountInCents,
        lookupKey: ?switch (transferLookupKey, priceConfig.lookupKey) {
        | (true, Some(true)) => Some(priceConfig.ref)
        | _ => None
        },
        ?nickname,
        ?metadata,
        recurring,
        transferLookupKey,
      })
    }

    let prices =
      await productConfig.prices
      ->Array.filter(priceConfig => {
        switch (interval, priceConfig.recurring) {
        | (Some(expectedInterval), Metered({interval}) | Licensed({interval})) =>
          interval === expectedInterval
        | (None, _) => true
        }
      })
      ->Array.map(async priceConfig => {
        let existingPrice = prices.data->Array.find(price => {
          let isPriceInSync =
            priceConfig.currency === price.currency &&
            if (
              // Don't check the lookup key for meter price copies
              price.metadata->Dict.getUnsafe("#meter_ref") ===
                price.metadata->Dict.getUnsafe("#meter_event_name")
            ) {
              switch (priceConfig.lookupKey, price.lookupKey) {
              | (Some(true), Value(lookupKey)) => priceConfig.ref === lookupKey
              | (Some(true), Null)
              | (_, Value(_)) => false
              | (_, Null) => true
              }
            } else {
              true
            } &&
            Null.Value(priceConfig.unitAmountInCents) === price.unitAmountInCents &&
            switch price.recurring {
            | Null => false
            | Value(priceRecurring) =>
              switch priceConfig.recurring {
              | Licensed({interval}) =>
                priceRecurring.usageType === Licensed &&
                priceRecurring.interval === interval &&
                priceRecurring.meter === Null
              | Metered({interval, ref}) =>
                let usedCustomerMeters = switch usedCustomerMeters {
                | Some(m) => m
                | None =>
                  Exn.raiseError(`The "usedCustomerMeters" argument is required when product catalog contains a Metered price`)
                }

                priceRecurring.usageType === Metered &&
                priceRecurring.interval === interval &&
                priceRecurring.meter->Null.toOption->Option.isSome &&
                price.metadata->Dict.getUnsafe("#meter_ref") === ref &&
                switch price.metadata->Dict.get("#meter_event_name") {
                | None => false
                | Some(meterEventName) => {
                    // We need to use a price with another meter in this case
                    // To be able to count the creating subscription separately
                    let hasAnotherSubscriptionWithTheSameMeter =
                      usedCustomerMeters->Set.has(meterEventName)

                    !hasAnotherSubscriptionWithTheSameMeter
                  }
                }
              }
            }
          isPriceInSync
        })
        switch existingPrice {
        | Some(price) => {
            Console.log(
              `Found an existing price "${priceConfig.ref}" for product "${productConfig.ref}". Price ID: ${price.id}`,
            )
            price
          }
        | None => {
            Console.log(
              `Price "${priceConfig.ref}" for product "${productConfig.ref}" is not in sync. Updating...`,
            )
            let price = await createPriceFromConfig(priceConfig)
            Console.log(
              `Price "${priceConfig.ref}" for product "${productConfig.ref}" successfully recreated with the new values. Price ID: ${price.id}`,
            )
            price
          }
        }
      })
      ->Promise.all

    {
      product,
      prices,
    }
  }

  let sync = async (stripe: stripe, productCatalog: t, ~usedCustomerMeters=?, ~interval=?) => {
    let isMeterNeeded = productCatalog.products->Array.some(p =>
      p.prices->Array.some(p =>
        switch p.recurring {
        | Metered(_) => true
        | _ => false
        }
      )
    )

    let meters = if isMeterNeeded {
      Console.log(`Loading active meters...`)
      let {data: meters} = await stripe->Meter.list({
        status: Active,
        limit: 100,
      })
      Console.log(`Loaded ${meters->Array.length->Int.toString} active meters`)
      Some(meters->Array.map(meter => (meter.eventName, meter))->Dict.fromArray)
    } else {
      None
    }

    let products =
      await productCatalog.products
      ->Array.map(p => stripe->syncProduct(p, ~meters?, ~usedCustomerMeters?, ~interval?))
      ->Promise.all
    Console.log(`Successfully finished syncing products`)
    products
  }
}

module Customer = {
  type t = {
    id: string,
    metadata: dict<string>,
    email: null<string>,
    name: null<string>,
    deleted?: bool,
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

  type listParams = {
    email?: string,
    @as("ending_before")
    endingBefore?: string,
    @as("starting_after")
    startingAfter?: string,
    limit?: int,
    @as("test_clock")
    testClock?: bool,
  }
  @scope("customers") @send
  external list: (stripe, listParams) => promise<page<t>> = "list"

  @scope("customers") @send
  external retrieve: (stripe, string) => promise<t> = "retrieve"

  %%private(
    let cache = {
      hasMore: true,
      lock: 0,
      items: [],
    }
  )

  let findByMetadata = async (stripe: stripe, metadata: dict<string>) => {
    let lock = cache.lock + 1
    cache.lock = lock

    let matches = switch Dict.toArray(metadata) {
    | [] => _ => true
    | [(key, value)] => (item: objectWithMetadata) => item.metadata->Dict.getUnsafe(key) === value
    | entries =>
      item => entries->Array.every(((key, value)) => item.metadata->Dict.getUnsafe(key) === value)
    }

    let updateCache = (data, ~hasMore, ~isCatchUp) => {
      if cache.lock === lock {
        if isCatchUp {
          let newCacheItems = data->Array.map(item => {
            id: item.id,
            metadata: item.metadata,
          })
          cache.items = newCacheItems->Array.concat(cache.items)
        } else {
          cache.hasMore = hasMore
          data->Array.forEach(item => {
            cache.items
            ->Array.push({
              id: item.id,
              metadata: item.metadata,
            })
            ->ignore
          })
        }
      }
    }

    let rec lookup = async (~startingAfter) => {
      let page = await stripe->list({
        limit: 1000,
        ?startingAfter,
      })
      updateCache(page.data, ~hasMore=page.hasMore, ~isCatchUp=false)
      let match =
        page.data
        ->(Obj.magic: array<t> => array<objectWithMetadata>)
        ->Array.find(matches)
        ->(Obj.magic: option<objectWithMetadata> => option<t>)

      switch match {
      | Some(_) => match
      | None =>
        if page.hasMore {
          await lookup(~startingAfter=Some((page.data->Stdlib.Array.lastUnsafe).id))
        } else {
          None
        }
      }
    }

    let catchUpToCache = async (~endingBefore) => {
      let data = await (
        stripe
        ->list({
          limit: 100,
          endingBefore,
        })
        ->Obj.magic
      )["autoPagingToArray"]({limit: 10000})
      if data->Array.length === 10000 {
        Exn.raiseError("Too many new customers to cache.")
      }
      updateCache(data, ~hasMore=false, ~isCatchUp=true)
      data
      ->(Obj.magic: array<t> => array<objectWithMetadata>)
      ->Array.find(matches)
      ->(Obj.magic: option<objectWithMetadata> => option<t>)
    }

    switch cache.items {
    | [] => {
        Console.log2(
          "Customer metadata lookup cache is empty. Looking for customers on server...",
          metadata,
        )
        let c = await lookup(~startingAfter=None)
        Console.log2(`Finished looking for customers by metadata`, metadata)
        c
      }
    | items =>
      Console.log2("Searching for customer by metadata in cache", metadata)
      switch cache.items->Array.find(matches) {
      | Some(item) => {
          Console.log2(
            `Successfully found Customer ID "${item.id}" by metadata in cache. Retrieving data...`,
            metadata,
          )
          let customer = await stripe->retrieve(item.id)
          let isValid = switch customer {
          | {deleted: true} => false
          | item => matches(item->(Obj.magic: t => objectWithMetadata))
          }
          Console.log2(
            `Customer ID "${item.id}" ${switch customer {
              | {deleted: true} => "is deleted"
              | _ =>
                isValid ? "matches metadata lookup. Returning!" : "doesn't match cached metadata"
              }}`,
            metadata,
          )
          if isValid {
            Some(customer)
          } else {
            let indexInCache = cache.items->Array.findIndex(item => item.id === customer.id)
            if indexInCache !== -1 {
              switch customer {
              | {deleted: true} =>
                let _ = cache.items->Js.Array2.removeCountInPlace(~pos=indexInCache, ~count=1)
              | _ =>
                cache.items->Array.set(
                  indexInCache,
                  {
                    id: customer.id,
                    metadata: customer.metadata,
                  },
                )
              }
            }
            None
          }
        }
      | None =>
        Console.log2(
          "Customer by metadata isn't found in cache. Requesting newly created customers...",
          metadata,
        )
        switch await catchUpToCache(~endingBefore=(items->Array.getUnsafe(0)).id) {
        | Some(customer) as match => {
            Console.log2(`Successfully found customer "${customer.id}" by metadata`, metadata)
            match
          }
        | None if cache.hasMore =>
          Console.log2(
            `Any new customer doesn't match metadata. Looking for older customers on server...`,
            metadata,
          )
          let c = await lookup(~startingAfter=Some((cache.items->Stdlib.Array.lastUnsafe).id))
          Console.log2(`Finished looking for customers by metadata`, metadata)
          c
        | None => {
            Console.log2(`Customer by metadata isn't found`, metadata)
            None
          }
        }
      }
    }
  }
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
    billingThresholds: null<unknown>,
    metadata: dict<string>,
    created: int,
    subscription: string,
    price: itemPrice,
  }
  type t = {
    id: string,
    metadata: dict<string>,
    status: status,
    customer: string,
    @as("current_period_end")
    currentPeriodEnd: int,
    @as("current_period_start")
    currentPeriodStart: int,
    @as("cancel_at_period_end")
    cancelAtPeriodEnd: bool,
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
    ->Array.find(item => {
      item.price.metadata->Dict.getUnsafe("#meter_ref") === meterRef
    })
    ->Option.flatMap(i => i.price.recurring->Null.toOption)
    ->Option.flatMap(r => r.meter->Null.toOption)
  }

  let getMeterEventName = (subscription, ~meterRef) => {
    subscription.items.data
    ->Array.find(item => {
      item.price.metadata->Dict.getUnsafe("#meter_ref") === meterRef
    })
    ->Option.flatMap(i => i.price.metadata->Dict.get("#meter_event_name"))
  }

  let reportMeterUsage = async (
    stripe,
    subscription,
    ~meterRef,
    ~value,
    ~timestamp=?,
    ~identifier=?,
  ) => {
    switch getMeterEventName(subscription, ~meterRef) {
    | Some(meterEventName) =>
      let _ = await stripe->MeterEvent.create({
        eventName: meterEventName,
        payload: Dict.fromArray([
          ("value", value->Int.toString),
          ("stripe_customer_id", subscription.customer),
        ]),
        ?timestamp,
        ?identifier,
      })
      Ok()
    | None => Error(#MeterNotFound)
    }
  }
}

module CustomerPortal = {
  %%private(
    @val
    external encodeURIComponent: string => string = "encodeURIComponent"
  )

  let prefillEmail = (~link, ~email=?) => {
    switch email {
    | Some(email) => `${link}?prefilled_email=${encodeURIComponent(email)}`
    | None => link
    }
  }
}

module Checkout = {
  module Session = {
    type t = {
      id: string,
      url: null<string>,
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

module Webhook = {
  type data<'object> = {object: 'object}

  type genericEvent<'object> = {
    id: string,
    @as("type")
    type_: string,
    object: string,
    @as("api_version")
    apiVersion: string,
    created: int,
    livemode: bool,
    @as("pending_webhooks")
    pendingWebhooks: int,
    data: data<'object>,
  }

  type event =
    | CustomerSubscriptionCreated(genericEvent<Subscription.t>)
    | CustomerSubscriptionUpdated(genericEvent<Subscription.t>)
    | CustomerSubscriptionDeleted(genericEvent<Subscription.t>)
    | Unknown(genericEvent<dict<unknown>>)

  @scope("webhooks") @send
  external constructEvent: (
    stripe,
    ~body: string,
    ~sig: string,
    ~secret: string,
  ) => genericEvent<dict<unknown>> = "constructEvent"
  let constructEvent = (stripe, ~body, ~sig, ~secret) => {
    try {
      let event = constructEvent(stripe, ~body, ~sig, ~secret)
      switch (event->Obj.magic)["type"] {
      | "customer.subscription.created" => CustomerSubscriptionCreated(event->Obj.magic)
      | "customer.subscription.updated" => CustomerSubscriptionUpdated(event->Obj.magic)
      | "customer.subscription.deleted" => CustomerSubscriptionDeleted(event->Obj.magic)
      | _ => Unknown(event)
      }->Ok
    } catch {
    | Exn.Error(err) => Error(err->Exn.message->Option.getUnsafe)
    }
  }
}

type metadataRef<'config, 'value> = private {
  fieldName: string,
  schema: S.t<'value>,
  coereced: S.t<'value>,
}

module Billing = {
  module Plan = {
    type s<'config> = {
      field: 'v. metadataRef<'config, 'v> => 'v,
      tag: 'v. (metadataRef<'config, 'v>, 'v) => unit,
      matches: 'v. S.t<'v> => 'v,
    }
  }

  type s<'config> = {
    primary: 'v. (metadataRef<'config, 'v>, ~customerLookup: bool=?) => 'v,
    field: 'v. metadataRef<'config, 'v> => 'v,
  }

  type rec t<'data, 'plan> = {
    ref: string,
    data: s<t<'data, 'plan>> => 'data,
    plans: array<(string, Plan.s<t<'data, 'plan>> => 'plan)>,
    products: (~plan: 'plan, ~data: 'data) => array<ProductCatalog.productConfig>,
    termsOfServiceConsent?: bool,
  }

  type subscription<'config> = private {...Subscription.t}
  type subscriptionWithCustomer<'config> = {
    customer: option<Customer.t>,
    subscription: option<subscription<'config>>,
  }

  let refField = "#subscription_ref"
  let planField = "#subscription_plan"

  let listSubscriptions = async (stripe, ~config: t<'data, 'plan>, ~customerId=?) => {
    switch await stripe->Subscription.list({
      customer: ?customerId,
      limit: 100,
    }) {
    | {hasMore: true} =>
      Exn.raiseError(`Found more than 100 subscriptions, which is not supported yet`)
    | {data: subscriptions} =>
      subscriptions
      ->Array.filter(subscription => {
        subscription.metadata->Dict.getUnsafe(refField) === config.ref
      })
      ->(Obj.magic: array<Subscription.t> => array<subscription<t<'data, 'plan>>>)
    }
  }

  %%private(
    let processData = (data, ~config) => {
      let primaryFields = [refField]
      let customerLookupFields = []
      let metadataFields = [refField]
      let schema = S.object(s => {
        s.tag(refField, config.ref)
        config.data({
          primary: ({fieldName, coereced}, ~customerLookup=false) => {
            primaryFields->Array.push(fieldName)->ignore
            metadataFields->Array.push(fieldName)->ignore
            if customerLookup {
              customerLookupFields->Array.push(fieldName)->ignore
            }
            s.field(fieldName, coereced)
          },
          field: ({fieldName, coereced}) => {
            metadataFields->Array.push(fieldName)->ignore
            s.field(fieldName, coereced)
          },
        })
      })

      if customerLookupFields->Array.length === 0 {
        Exn.raiseError(
          "The data schema must define at least one primary field with ~customerLookup=true",
        )
      }
      let dict: dict<string> = data->S.reverseConvertOrThrow(schema)->Obj.magic

      let customerMetadata = Dict.make()
      customerLookupFields->Array.forEach(name => {
        customerMetadata->Dict.set(name, dict->Dict.getUnsafe(name))
      })

      {
        "value": data,
        "dict": dict,
        "schema": schema,
        "primaryFields": primaryFields,
        "customerMetadata": customerMetadata,
        "metadataFields": metadataFields,
      }
    }

    let internalRetrieveSubscription = async (
      stripe,
      data,
      ~config,
      ~customerId,
      ~usedMetersAcc=?,
    ) => {
      Console.log(
        `Searching for an existing "${config.ref}" subscription for customer "${customerId}"...`,
      )
      let subscriptions = await stripe->listSubscriptions(~config, ~customerId)
      Console.log(
        `Found ${subscriptions
          ->Array.length
          ->Int.toString} subscriptions for the customer. Validating that the new subscription is not already active...`,
      )
      subscriptions->Array.find(subscription => {
        // FIXME: This shouldn't be stopped by .find
        switch usedMetersAcc {
        | Some(usedMetersAcc) =>
          subscription.items.data->Array.forEach(item => {
            switch item.price.metadata->Dict.get("#meter_event_name") {
            | None => ()
            | Some(meterEventName) => usedMetersAcc->Set.add(meterEventName)->ignore
            }
          })
        | None => ()
        }
        if (
          data["primaryFields"]->Array.every(name => {
            subscription.metadata->Dict.getUnsafe(name) === data["dict"]->Dict.getUnsafe(name)
          })
        ) {
          Console.log(`Found an existing subscription. Subscription ID: ${subscription.id}`)
          if subscription.status->Subscription.isTerminatedStatus {
            Console.log(
              `The subscription "${subscription.id}" is terminated with status ${(subscription.status :> string)}. Skipping...`,
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
  )

  let retrieveCustomer = (stripe, ~config, data) => {
    stripe->Customer.findByMetadata(processData(data, ~config)["customerMetadata"])
  }

  let retrieveSubscriptionWithCustomer = async (stripe, ~config, data) => {
    let processedData = processData(data, ~config)
    switch await stripe->Customer.findByMetadata(processedData["customerMetadata"]) {
    | Some(customer) =>
      switch await internalRetrieveSubscription(
        stripe,
        processedData,
        ~customerId=customer.id,
        ~config,
      ) {
      | Some(subscription) => {customer: Some(customer), subscription: Some(subscription)}
      | None => {
          customer: Some(customer),
          subscription: None,
        }
      }
    | None => {
        customer: None,
        subscription: None,
      }
    }
  }

  let retrieveSubscription = async (stripe, ~config, data) => {
    switch await retrieveSubscriptionWithCustomer(stripe, ~config, data) {
    | {subscription} => subscription
    }
  }

  type hostedCheckoutSessionParams<'data, 'plan> = {
    config: t<'data, 'plan>,
    successUrl: string,
    cancelUrl?: string,
    billingCycleAnchor?: int,
    interval?: Price.interval,
    data: 'data,
    plan: 'plan,
    description?: string,
    allowPromotionCodes?: bool,
  }

  let createHostedCheckoutSession = async (stripe, params) => {
    let data = processData(params.data, ~config=params.config)

    let planMetadataFields = [planField]

    let planSchema = S.union(
      params.config.plans->Array.map(((planRef, planConfig)) => {
        S.object(s => {
          let matchesCounter = ref(-1)
          s.tag(planField, planRef)
          let plan = planConfig({
            // TODO: Validate that all plans have the same metadata fields if they aren't marked as optional
            field: ({fieldName, coereced}) => {
              planMetadataFields->Array.push(fieldName)->ignore
              s.field(fieldName, coereced)
            },
            tag: ({fieldName, coereced}, value) => {
              planMetadataFields->Array.push(fieldName)->ignore
              let _ = s.field(fieldName, coereced->S.coerce(S.literal(value)))
            },
            // We don't need the data in schema,
            // only for typesystem
            matches: schema => {
              matchesCounter := matchesCounter.contents + 1
              s.field(`#matches${matchesCounter.contents->Int.toString}`, schema)
            },
          })
          plan
        })
      }),
    )
    let rawTier: dict<string> = params.plan->S.reverseConvertOrThrow(planSchema)->Obj.magic

    let planId = rawTier->Dict.getUnsafe(planField)
    let products = switch params.config.products(~data=params.data, ~plan=params.plan) {
    | [] => Exn.raiseError(`Tier "${planId}" doesn't have any products configured`)
    | p => p
    }

    let customer = switch await stripe->Customer.findByMetadata(data["customerMetadata"]) {
    | Some(c) => c
    | None => {
        Console.log(`Creating a new customer...`)
        let c = await Customer.create(
          stripe,
          {
            metadata: data["customerMetadata"],
          },
        )
        Console.log(`Successfully created a new customer with id: ${c.id}`)
        c
      }
    }

    let usedCustomerMeters = Set.make()

    switch await internalRetrieveSubscription(
      stripe,
      data,
      ~customerId=customer.id,
      ~config=params.config,
      ~usedMetersAcc=usedCustomerMeters,
    ) {
    | None => Console.log(`Customer doesn't have an active "${params.config.ref}" subscription`)
    | Some(subscription) =>
      Exn.raiseError(
        `There's already an active "${params.config.ref}" subscription for ${data["primaryFields"]
          ->Array.map(name => `${name}=${data["dict"]->Dict.getUnsafe(name)}`)
          ->Array.join(", ")} with the "${subscription.metadata->Dict.getUnsafe(
            planField,
          )}" plan and id "${subscription.id}". Either update the existing subscription or cancel it and create a new one`,
      )
    }

    let productItems =
      await stripe->ProductCatalog.sync(
        {ProductCatalog.products: products},
        ~usedCustomerMeters,
        ~interval=?params.interval,
      )

    Console.log(
      `Creating a new checkout session for subscription "${params.config.ref}" plan "${planId}"...`,
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
        ->Array.map(name => (name, data["dict"]->Dict.getUnsafe(name)))
        ->Array.concat(planMetadataFields->Array.map(name => (name, rawTier->Dict.getUnsafe(name))))
        ->Dict.fromArray,
      },
      allowPromotionCodes: ?params.allowPromotionCodes,
      successUrl: params.successUrl,
      cancelUrl: ?params.cancelUrl,
      lineItems: productItems->Array.map(({prices, product}): Checkout.Session.lineItemParam => {
        let lineItemPrice = switch (prices, params.interval) {
        | ([], None) => Exn.raiseError(`Product "${product.name}" doesn't have any prices`)
        | ([], Some(interval)) =>
          Exn.raiseError(
            `Product "${product.name}" doesn't have prices for interval "${(interval :> string)}"`,
          )
        | ([price], _) => price
        | (_, None) =>
          Exn.raiseError(
            `Product "${product.name}" has multiple prices but no interval specified. Use "interval" param to dynamically choose which price use for the plan`,
          )
        | (_, Some(interval)) =>
          Exn.raiseError(
            `Product "${product.name}" has multiple prices for interval "${(interval :> string)}"`,
          )
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
    Console.log(
      `Successfully created a new checkout session. Session ID: ${session.id}.${switch session.url {
        | Value(url) => ` Url: ${url}`
        | Null => ""
        }}
    `,
    )
    session
  }

  let verify = (subscription: Subscription.t, ~config: t<'data, 'plan>): option<
    subscription<t<'data, 'plan>>,
  > => {
    if subscription.metadata->Dict.getUnsafe(refField) === config.ref {
      Some(subscription->Obj.magic)
    } else {
      None
    }
  }
}

module Metadata = {
  let ref = (fieldName: string, schema: S.t<'value>): metadataRef<'config, 'value> => {
    {"fieldName": fieldName, "schema": schema, "coereced": S.string->S.coerce(schema)}->Obj.magic
  }

  let get = (
    subscription: Billing.subscription<Billing.t<'data, 'plan>>,
    metadataRef: metadataRef<Billing.t<'data, 'plan>, 'value>,
  ): 'value => {
    (subscription->Obj.magic)["metadata"]
    ->Dict.getUnsafe(metadataRef.fieldName)
    ->S.parseOrThrow(metadataRef.schema)
  }
}
