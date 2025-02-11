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

  module Set = {
    type t<'value>

    @ocaml.doc("Creates a new `Set` object.") @new
    external make: unit => t<'value> = "Set"

    @ocaml.doc("Creates a new `Set` object.") @new
    external fromEntries: array<'value> => t<'value> = "Set"

    @ocaml.doc("Returns the number of values in the `Set` object.") @get
    external size: t<'value> => int = "size"

    @ocaml.doc("Appends `value` to the `Set` object. Returns the `Set` object with added value.")
    @send
    external add: (t<'value>, 'value) => t<'value> = "add"

    let addMany = (set, values) => values->Js.Array2.forEach(value => set->add(value)->ignore)

    @ocaml.doc("Removes all elements from the `Set` object.") @send
    external clear: t<'value> => unit = "clear"

    @ocaml.doc(
      "Removes the element associated to the `value` and returns a boolean asserting whether an element was successfully removed or not. `Set.prototype.has(value)` will return `false` afterwards."
    )
    @send
    external delete: (t<'value>, 'value) => bool = "delete"

    @ocaml.doc(
      "Returns a boolean asserting whether an element is present with the given value in the `Set` object or not."
    )
    @send
    external has: (t<'value>, 'value) => bool = "has"

    external toArray: t<'a> => array<'a> = "Array.from"

    @ocaml.doc(
      "Calls `callbackFn` once for each value present in the `Set` object, in insertion order."
    )
    @send
    external forEach: (t<'value>, 'value => unit) => unit = "forEach"

    @ocaml.doc(
      "Calls `callbackFn` once for each value present in the `Set` object, in insertion order."
    )
    @send
    external forEachWithSet: (t<'value>, ('value, 'value, t<'value>) => unit) => unit = "forEach"
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
    Js.log(`Searching for active product "${productConfig.ref}"...`)
    let product = switch await stripe->Product.search({
      query: `active:"true" AND metadata["#product_ref"]:"${productConfig.ref}"`,
      limit: 2,
    }) {
    | {data: []} => {
        Js.log(`No active product "${productConfig.ref}" found. Creating a new one...`)
        let p = await stripe->Product.create({
          name: productConfig.name,
          unitLabel: ?productConfig.unitLabel,
          metadata: Js.Dict.fromArray([("#product_ref", productConfig.ref)]),
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

    let createPriceFromConfig = async priceConfig => {
      let (metadata, recurring, transferLookupKey, nickname) = switch priceConfig.recurring {
      | Licensed({interval}) => (None, {Price.interval: interval}, true, None)
      | Metered({interval, ref}) => {
          let meters = switch meters {
          | Some(m) => m
          | None =>
            Js.Exn.raiseError(`The "meters" argument is required when product catalog contains a Metered price`)
          }
          let usedCustomerMeters = switch usedCustomerMeters {
          | Some(m) => m
          | None =>
            Js.Exn.raiseError(`The "usedCustomerMeters" argument is required when product catalog contains a Metered price`)
          }
          let rec getEventName = (~meterRef, ~counter=0) => {
            let eventName = switch counter {
            | 0 => meterRef
            | _ => `${meterRef}_${(counter + 1)->Js.Int.toString}`
            }
            if usedCustomerMeters->Stdlib.Set.has(eventName) {
              getEventName(~meterRef, ~counter=counter + 1)
            } else {
              eventName
            }
          }
          let eventName = getEventName(~meterRef=ref)
          let meter = switch meters->Js.Dict.get(eventName) {
          | Some(meter) => meter
          | None =>
            Js.log(`Meter "${eventName}" does not exist. Creating...`)
            let meter = await stripe->Meter.create({
              displayName: ref,
              eventName,
              defaultAggregation: {
                formula: Sum,
              },
            })
            Js.log(`Meter "${eventName}" successfully created. Meter ID: ${meter.id}`)
            meter
          }

          (
            Some(
              Js.Dict.fromArray([
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
      ->Js.Array2.filter(priceConfig => {
        switch (interval, priceConfig.recurring) {
        | (Some(expectedInterval), Metered({interval}))
        | (Some(expectedInterval), Licensed({interval})) =>
          interval === expectedInterval
        | (None, _) => true
        }
      })
      ->Js.Array2.map(async priceConfig => {
        let existingPrice = prices.data->Js.Array2.find(price => {
          let isPriceInSync =
            priceConfig.currency === price.currency &&
            switch (priceConfig.lookupKey, price.lookupKey) {
            | (Some(true), Value(lookupKey)) => priceConfig.ref === lookupKey
            | (Some(true), Null)
            | (_, Value(_)) => false
            | (_, Null) => true
            } &&
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
                let usedCustomerMeters = switch usedCustomerMeters {
                | Some(m) => m
                | None =>
                  Js.Exn.raiseError(`The "usedCustomerMeters" argument is required when product catalog contains a Metered price`)
                }

                priceRecurring.usageType === Metered &&
                priceRecurring.interval === interval &&
                priceRecurring.meter->Js.Null.toOption->Js.Option.isSome &&
                price.metadata->Js.Dict.unsafeGet("#meter_ref") === ref &&
                switch price.metadata->Js.Dict.get("#meter_event_name") {
                | None => false
                | Some(meterEventName) => !(usedCustomerMeters->Stdlib.Set.has(meterEventName))
                }
              }
            }
          isPriceInSync
        })
        switch existingPrice {
        | Some(price) => {
            Js.log(
              `Found an existing price "${priceConfig.ref}" for product "${productConfig.ref}". Price ID: ${price.id}`,
            )
            price
          }
        | None => {
            Js.log(
              `Price "${priceConfig.ref}" for product "${productConfig.ref}" is not in sync. Updating...`,
            )
            let price = await createPriceFromConfig(priceConfig)
            Js.log(
              `Price "${priceConfig.ref}" for product "${productConfig.ref}" successfully recreated with the new values. Price ID: ${price.id}`,
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

  let sync = async (stripe: stripe, productCatalog: t, ~usedCustomerMeters=?, ~interval=?) => {
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
      ->Js.Array2.map(p => stripe->syncProduct(p, ~meters?, ~usedCustomerMeters?, ~interval?))
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

  let getMeterEventName = (subscription, ~meterRef) => {
    subscription.items.data
    ->Js.Array2.find(item => {
      item.price.metadata->Js.Dict.unsafeGet("#meter_ref") === meterRef
    })
    ->Belt.Option.flatMap(i => i.price.metadata->Js.Dict.get("#meter_event_name"))
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
      matches: 'v. S.t<'v> => 'v,
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
    products: (~tier: 'tier, ~data: 'data) => array<ProductCatalog.productConfig>,
    termsOfServiceConsent?: bool,
  }

  let refField = "#subscription_ref"
  let tierField = "#subscription_tier"

  let listSubscriptions = async (stripe, ~config, ~customerId=?) => {
    switch await stripe->Subscription.list({
      customer: ?customerId,
      limit: 100,
    }) {
    | {hasMore: true} =>
      Js.Exn.raiseError(`Found more than 100 subscriptions, which is not supported yet`)
    | {data: subscriptions} =>
      subscriptions->Js.Array2.filter(subscription => {
        subscription.metadata->Js.Dict.unsafeGet(refField) === config.ref
      })
    }
  }

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
      ~config,
      ~customerId,
      ~usedMetersAcc=?,
    ) => {
      Js.log(
        `Searching for an existing "${config.ref}" subscription for customer "${customerId}"...`,
      )
      let subscriptions = await stripe->listSubscriptions(~config, ~customerId)
      Js.log(
        `Found ${subscriptions
          ->Js.Array2.length
          ->Js.Int.toString} subscriptions for the customer. Validating that the new subscription is not already active...`,
      )
      subscriptions->Js.Array2.find(subscription => {
        switch usedMetersAcc {
        | Some(usedMetersAcc) =>
          subscription.items.data->Belt.Array.forEach(item => {
            switch item.price.metadata->Js.Dict.get("#meter_event_name") {
            | None => ()
            | Some(meterEventName) => usedMetersAcc->Stdlib.Set.add(meterEventName)->ignore
            }
          })
        | None => ()
        }
        if (
          data["primaryFields"]->Js.Array2.every(name => {
            subscription.metadata->Js.Dict.unsafeGet(name) === data["dict"]->Js.Dict.unsafeGet(name)
          })
        ) {
          Js.log(`Found an existing subscription. Subscription ID: ${subscription.id}`)
          if subscription.status->Subscription.isTerminatedStatus {
            Js.log(
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
    internalRetrieveCustomer(stripe, processData(data, ~config))
  }

  let retrieveSubscription = async (stripe, ~config, data) => {
    let processedData = processData(data, ~config)
    switch await internalRetrieveCustomer(stripe, processedData) {
    | Some(customer) =>
      await internalRetrieveSubscription(stripe, processedData, ~customerId=customer.id, ~config)
    | None => None
    }
  }

  type hostedCheckoutSessionParams<'data, 'tier> = {
    config: t<'data, 'tier>,
    successUrl: string,
    cancelUrl?: string,
    billingCycleAnchor?: int,
    interval?: Price.interval,
    data: 'data,
    tier: 'tier,
    description?: string,
    allowPromotionCodes?: bool,
  }

  let createHostedCheckoutSession = async (stripe, params) => {
    let data = processData(params.data, ~config=params.config)

    let tierMetadataFields = [tierField]

    let tierSchema = S.union(
      params.config.tiers->Js.Array2.map(((tierRef, tierConfig)) => {
        S.object(s => {
          let matchesCounter = ref(-1)
          s.tag(tierField, tierRef)
          let tier = tierConfig({
            metadata: (name, schema) => {
              validateMetadataSchema(schema)
              tierMetadataFields->Js.Array2.push(name)->ignore
              s.field(name, schema)
            },
            // We don't need the data in schema,
            // only for typesystem
            matches: schema => {
              matchesCounter := matchesCounter.contents + 1
              s.field(`#matches${matchesCounter.contents->Js.Int.toString}`, schema)
            },
          })
          tier
        })
      }),
    )
    let rawTier: dict<string> = params.tier->S.reverseConvertOrThrow(tierSchema)->Obj.magic

    let tierId = rawTier->Js.Dict.unsafeGet(tierField)
    let products = switch params.config.products(~data=params.data, ~tier=params.tier) {
    | [] => Js.Exn.raiseError(`Tier "${tierId}" doesn't have any products configured`)
    | p => p
    }

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

    let usedCustomerMeters = Stdlib.Set.make()

    switch await internalRetrieveSubscription(
      stripe,
      data,
      ~customerId=customer.id,
      ~config=params.config,
      ~usedMetersAcc=usedCustomerMeters,
    ) {
    | None => Js.log(`Customer doesn't have an active "${params.config.ref}" subscription`)
    | Some(subscription) =>
      Js.Exn.raiseError(
        `There's already an active "${params.config.ref}" subscription for ${data["primaryFields"]
          ->Js.Array2.map(name => `${name}=${data["dict"]->Js.Dict.unsafeGet(name)}`)
          ->Js.Array2.joinWith(
            ", ",
          )} with the "${tierId}" tier and id "${subscription.id}". Either update the existing subscription or cancel it and create a new one`,
      )
    }

    let productItems =
      await stripe->ProductCatalog.sync(
        {ProductCatalog.products: products},
        ~usedCustomerMeters,
        ~interval=?params.interval,
      )

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
        let lineItemPrice = switch (prices, params.interval) {
        | ([], None) => Js.Exn.raiseError(`Product "${product.name}" doesn't have any prices`)
        | ([], Some(interval)) =>
          Js.Exn.raiseError(
            `Product "${product.name}" doesn't have prices for interval "${(interval :> string)}"`,
          )
        | ([price], _) => price
        | (_, None) =>
          Js.Exn.raiseError(
            `Product "${product.name}" has multiple prices but no interval specified. Use "interval" param to dynamically choose which price use for the tier`,
          )
        | (_, Some(interval)) =>
          Js.Exn.raiseError(
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
    Js.log(session)
    Js.log("Successfully created a new checkout session")
  }
}
