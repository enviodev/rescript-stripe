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
  external all6: ((t<'a>, t<'b>, t<'c>, t<'d>, t<'e>, t<'f>)) => t<('a, 'b, 'c, 'd, 'e, 'f)> = "all"

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
type currency = USD | ISO(string)

@unboxed
type taxBehavior =
  | @as("exclusive") Exclusive | @as("inclusive") Inclusive | @as("unspecified") Unspecified

module Meter = {
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
}

module Price = {
  type t

  type interval =
    | @as("day") Day
    | @as("week") Week
    | @as("month") Month
    | @as("year") Year

  type usageType = | @as("metered") Metered | @as("licensed") Licensed

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

  type updateParams = {
    @as("unit_label")
    mutable unitLabel?: string,
  }

  @scope("products") @send
  external create: (stripe, createParams) => promise<t> = "create"

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
    | Metered({
        interval: Price.interval,
        unitLabel: string,
        defaultAggregation: Meter.defaultAggregation,
      })
    | Licensed({interval: Price.interval})

  type priceConfig = {
    currency: currency,
    unitAmountInCents: int,
    lookupKey: string,
    recurring: recurringConfig,
  }

  type productConfig = {
    name: string,
    prices: array<priceConfig>,
  }

  type t = {products: array<productConfig>}

  let getConfiguredUnitLabel = (productConfig: productConfig) => {
    let val = ref(None)
    productConfig.prices->Js.Array2.forEach(priceConfig => {
      switch priceConfig.recurring {
      | Licensed(_) => ()
      | Metered({unitLabel}) =>
        switch val.contents {
        | None => ()
        | Some(anotherUnitLabel) =>
          Js.Exn.raiseError(
            `The product '${productConfig.name}' has two different unit labels: ${anotherUnitLabel} and ${unitLabel}. It's allowed to have only one unit label.`,
          )
        }
        val := Some(unitLabel)
      }
    })
    val.contents
  }

  let syncProduct = async (stripe: stripe, productConfig: productConfig) => {
    let configuredUnitLabel = productConfig->getConfiguredUnitLabel

    Js.log(`Searching for active product with the name '${productConfig.name}'`)
    let product = switch await stripe->Product.search({
      query: `active:\'true\' AND name:'${productConfig.name}'`,
      limit: 2,
    }) {
    | {data: []} => {
        Js.log(`No active product with the name '${productConfig.name}' found. Creating a new one`)
        let p = await stripe->Product.create({
          name: productConfig.name,
          unitLabel: ?configuredUnitLabel,
        })
        Js.log(
          `Product with the name '${productConfig.name}' successfully created. Product ID: ${p.id}`,
        )
        p
      }
    | {data: [p]} => {
        Js.log(
          `Found an existing product with the name '${productConfig.name}'. Product ID: ${p.id}`,
        )

        let fieldsToSync: Product.updateParams = {}

        switch (p.unitLabel, configuredUnitLabel) {
        | (Value(v), Some(configured)) if v === configured => ()
        | (Null, None) => ()
        | (_, Some(configured)) => fieldsToSync.unitLabel = Some(configured)
        | (_, None) => fieldsToSync.unitLabel = Some("")
        }

        let fieldNamesToSync = Js.Dict.keys(fieldsToSync->Obj.magic)

        if fieldNamesToSync->Js.Array2.length > 0 {
          Js.log(`Syncing product ${p.id} fields ${fieldNamesToSync->Js.Array2.joinWith(", ")}`)
          let p = await stripe->Product.update(p.id, fieldsToSync)
          Js.log(`Product ${p.id} fields successfully updated`)
          p
        } else {
          Js.log(`Product ${p.id} fields are up to date`)
          p
        }
      }
    | {data: _} =>
      Js.Exn.raiseError(
        `There are multiple active products with the name '${productConfig.name}'. Please go to dashboard and delete not needed ones (https://dashboard.stripe.com/test/products?active=true)`,
      )
    }

    Js.log(product)
  }

  let sync = (stripe: stripe, productCatalog: t) => {
    let _ =
      productCatalog.products
      ->Js.Array2.map(p => stripe->syncProduct(p))
      ->Promise.all
  }
}
