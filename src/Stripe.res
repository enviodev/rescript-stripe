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
  external list: (stripe, ~params: listParams=?) => promise<page<t>> = "list"
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
  external list: (stripe, ~params: listParams=?) => promise<page<t>> = "list"
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
  external list: (stripe, ~params: listParams=?) => promise<page<t>> = "list"

  type searchParams = {query: string, limit?: int, page?: string}
  @scope("products") @send
  external search: (stripe, searchParams) => promise<page<t>> = "search"
}

module ProductCatalog = {
  type recurringConfig =
    | Metered({interval: Price.interval, unitLabel: string})
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
  }

  type t = {products: array<productConfig>}

  let syncProduct = async (
    stripe: stripe,
    productConfig: productConfig,
    ~meters: option<dict<Meter.t>>=?,
  ) => {
    let configuredUnitLabel = ref(None)
    let unsyncedPriceConfigs = Js.Dict.empty()

    for idx in 0 to productConfig.prices->Js.Array2.length - 1 {
      let priceConfig = productConfig.prices->Js.Array2.unsafe_get(idx)

      unsyncedPriceConfigs->Js.Dict.set(priceConfig.lookupKey, priceConfig)

      switch priceConfig.recurring {
      | Licensed(_) => ()
      | Metered({unitLabel}) =>
        switch configuredUnitLabel.contents {
        | None => ()
        | Some(anotherUnitLabel) =>
          Js.Exn.raiseError(
            `Product "${productConfig.name}" has two different unit labels: ${anotherUnitLabel} and ${unitLabel}. It's allowed to have only one unit label`,
          )
        }
        switch meters {
        | None =>
          Js.Exn.raiseError(
            `Product "${productConfig.name}" has a mettered price. It's required to provide a map of metters to perform the sync`,
          )
        | Some(_) => ()
        }
        configuredUnitLabel := Some(unitLabel)
      }
    }

    let configuredUnitLabel = configuredUnitLabel.contents

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
          unitLabel: ?configuredUnitLabel,
          metadata: Js.Dict.fromArray([("lookup_key", productConfig.lookupKey)]),
        })
        Js.log(`Product "${productConfig.lookupKey}" successfully created. Product ID: ${p.id}`)
        p
      }
    | {data: [p]} => {
        Js.log(`Found an existing product "${productConfig.lookupKey}". Product ID: ${p.id}`)

        let fieldsToSync: Product.updateParams = {}

        switch (p.unitLabel, configuredUnitLabel) {
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
    let prices = await stripe->Price.list(~params={product: product.id, active: true})
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
        } else {
          Js.log(`Price "${priceConfig.lookupKey}" is not in sync. Updating...`)
          let (newPrice, _) = await Stdlib.Promise.all2((
            createPriceFromConfig(priceConfig, ~transferLookupKey=true),
            stripe->Price.update(price.id, {active: false}),
          ))
          Js.log(
            `Price "${priceConfig.lookupKey}" successfully recreated with the new values. New Price ID: ${newPrice.id}. Old Price ID: ${price.id}`,
          )
        }
      | None => {
          Js.log(
            `Price ${price.id} with lookupKey ${price.lookupKey->Obj.magic} is not configured on product ${productConfig.lookupKey}. Setting it to inactive...`,
          )
          let _ = await stripe->Price.update(price.id, {active: false})
          Js.log(`Price ${price.id} successfully set to inactive`)
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
      })

    let _ = await Stdlib.Promise.all(priceUpdatePromises->Js.Array2.concat(priceCreatePromises))
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
      let {data: meters} = await stripe->Meter.list(
        ~params={
          status: Active,
          limit: 100,
        },
      )
      Js.log(`Loaded ${meters->Js.Array2.length->Js.Int.toString} active meters`)
      Some(meters->Js.Array2.map(meter => (meter.eventName, meter))->Js.Dict.fromArray)
    } else {
      None
    }

    let _ =
      await productCatalog.products
      ->Js.Array2.map(p => stripe->syncProduct(p, ~meters?))
      ->Stdlib.Promise.all
    Js.log(`Successfully finished syncing product catalog`)
  }
}
