// Generated by ReScript, PLEASE EDIT WITH CARE

import Stripe from "stripe";
import * as Stdlib_Exn from "rescript/lib/es6/Stdlib_Exn.js";
import * as Stdlib_Array from "rescript/lib/es6/Stdlib_Array.js";
import * as Stdlib_Option from "rescript/lib/es6/Stdlib_Option.js";
import * as Primitive_option from "rescript/lib/es6/Primitive_option.js";
import * as S$RescriptSchema from "rescript-schema/src/S.res.mjs";
import * as Primitive_exceptions from "rescript/lib/es6/Primitive_exceptions.js";

function make(prim) {
  return new Stripe(prim, {"telemetry": false});
}

function makeFindByMetadata(name, list, retrieve) {
  let cache = {
    hasMore: true,
    lock: 0,
    items: []
  };
  return async (stripe, metadata) => {
    let lock = cache.lock + 1 | 0;
    cache.lock = lock;
    let entries = Object.entries(metadata);
    let len = entries.length;
    let matches;
    if (len !== 1) {
      matches = len !== 0 ? item => entries.every(param => item.metadata[param[0]] === param[1]) : param => true;
    } else {
      let match = entries[0];
      let value = match[1];
      let key = match[0];
      matches = item => item.metadata[key] === value;
    }
    let updateCache = (data, hasMore, isCatchUp) => {
      if (cache.lock !== lock) {
        return;
      }
      if (isCatchUp) {
        let newCacheItems = data.map(item => ({
          id: item.id,
          metadata: item.metadata
        }));
        cache.items = newCacheItems.concat(cache.items);
        return;
      }
      cache.hasMore = hasMore;
      data.forEach(item => {
        cache.items.push({
          id: item.id,
          metadata: item.metadata
        });
      });
    };
    let lookup = async startingAfter => {
      let page = await list(stripe, {
        limit: 1000,
        starting_after: startingAfter
      });
      updateCache(page.data, page.has_more, false);
      let match = page.data.find(matches);
      if (match !== undefined) {
        return match;
      } else if (page.has_more) {
        return await lookup(Stdlib_Array.last(page.data).id);
      } else {
        return;
      }
    };
    let catchUpToCache = async endingBefore => {
      let data = await list(stripe, {
        limit: 100,
        ending_before: endingBefore
      }).autoPagingToArray({
        limit: 10000
      });
      if (data.length === 10000) {
        Stdlib_Exn.raiseError("Too many new " + name + "s to cache.");
      }
      updateCache(data, false, true);
      return data.find(matches);
    };
    let items = cache.items;
    if (items.length !== 0) {
      console.log("Searching for " + name + "s by metadata in cache", metadata);
      let item = cache.items.find(matches);
      if (item !== undefined) {
        console.log("Successfully found " + name + " ID \"" + item.id + "\" by metadata in cache. Retrieving data...", metadata);
        let item$1 = await retrieve(stripe, item.id);
        let deleted = item$1.deleted;
        let isValid = deleted ? false : matches(item$1);
        console.log(name + " ID \"" + item$1.id + "\" " + (
          deleted ? "is deleted" : (
              isValid ? "matches metadata lookup. Returning!" : "doesn't match cached metadata"
            )
        ), metadata);
        if (isValid) {
          return Primitive_option.some(item$1);
        }
        let indexInCache = cache.items.findIndex(cacheItem => cacheItem.id === item$1.id);
        if (indexInCache !== -1) {
          if (deleted) {
            cache.items.splice(indexInCache, 1);
          } else {
            cache.items[indexInCache] = {
              id: item$1.id,
              metadata: item$1.metadata
            };
          }
        }
        return;
      }
      console.log(name + " by metadata isn't found in cache. Requesting newly created " + name + "s...", metadata);
      let match$1 = await catchUpToCache(items[0].id);
      if (match$1 !== undefined) {
        console.log("Successfully found " + name + " \"" + match$1.id + "\" by metadata", metadata);
        return match$1;
      }
      if (cache.hasMore) {
        console.log("Any new " + name + " doesn't match metadata. Looking for older " + name + "s on server...", metadata);
        let c = await lookup(Stdlib_Array.last(cache.items).id);
        console.log("Finished looking for " + name + "s by metadata", metadata);
        return c;
      }
      console.log(name + " by metadata isn't found", metadata);
      return;
    }
    console.log(name + " metadata lookup cache is empty. Looking for " + name + "s on server...", metadata);
    let c$1 = await lookup(undefined);
    console.log("Finished looking for " + name + "s by metadata", metadata);
    return c$1;
  };
}

let Meter = {};

let MeterEvent = {};

let Price = {};

let findByMetadata = makeFindByMetadata("product", (stripe, params) => stripe.products.list({
  active: true,
  limit: params.limit,
  starting_after: params.starting_after,
  ending_before: params.ending_before
}), (prim0, prim1) => prim0.products.retrieve(prim1));

let Product = {
  findByMetadata: findByMetadata
};

function getPriceConfig(productConfig, interval) {
  let match = productConfig.prices;
  if (match.length === 1) {
    let price = match[0];
    if (price.recurring === undefined) {
      return price;
    }
    
  }
  let match$1 = productConfig.prices.filter(priceConfig => {
    let match = priceConfig.recurring;
    if (interval !== undefined) {
      if (match !== undefined) {
        return match.interval === interval;
      } else {
        return false;
      }
    } else {
      return true;
    }
  });
  let len = match$1.length;
  if (len !== 1) {
    if (len !== 0) {
      if (interval !== undefined) {
        return Stdlib_Exn.raiseError("Product \"" + productConfig.name + "\" has multiple prices for interval \"" + interval + "\"");
      } else {
        return Stdlib_Exn.raiseError("Product \"" + productConfig.name + "\" has multiple prices but no interval specified. Use \"interval\" param to dynamically choose which price use for the plan");
      }
    } else if (interval !== undefined) {
      return Stdlib_Exn.raiseError("Product \"" + productConfig.name + "\" doesn't have prices for interval \"" + interval + "\"");
    } else {
      return Stdlib_Exn.raiseError("Product \"" + productConfig.name + "\" doesn't have any prices");
    }
  } else {
    return match$1[0];
  }
}

async function syncProduct(stripe, productConfig, meters, usedCustomerMeters, interval) {
  console.log("Searching for active product \"" + productConfig.ref + "\"...");
  let p = await findByMetadata(stripe, {
    "#product_ref": productConfig.ref
  });
  let product;
  if (p !== undefined) {
    console.log("Found an existing product \"" + productConfig.ref + "\". Product ID: " + p.id);
    let fieldsToSync = {};
    let match = p.unit_label;
    let match$1 = productConfig.unitLabel;
    let exit = 0;
    if (match === null) {
      if (match$1 !== undefined) {
        exit = 1;
      }
      
    } else if (match$1 === undefined || match !== match$1) {
      exit = 1;
    }
    if (exit === 1) {
      if (match$1 !== undefined) {
        fieldsToSync.unit_label = match$1;
      } else {
        fieldsToSync.unit_label = "";
      }
    }
    if (p.name !== productConfig.name) {
      fieldsToSync.name = productConfig.name;
    }
    let fieldNamesToSync = Object.keys(fieldsToSync);
    if (fieldNamesToSync.length > 0) {
      console.log("Syncing product \"" + productConfig.ref + "\" fields " + fieldNamesToSync.join(", ") + "...");
      let p$1 = await stripe.products.update(p.id, fieldsToSync);
      console.log("Product \"" + productConfig.ref + "\" fields successfully updated");
      product = p$1;
    } else {
      console.log("Product \"" + productConfig.ref + "\" is in sync");
      product = p;
    }
  } else {
    console.log("No active product \"" + productConfig.ref + "\" found. Creating a new one...");
    let p$2 = await stripe.products.create({
      name: productConfig.name,
      metadata: {
        "#product_ref": productConfig.ref
      },
      unit_label: productConfig.unitLabel
    });
    console.log("Product \"" + productConfig.ref + "\" successfully created. Product ID: " + p$2.id);
    product = p$2;
  }
  console.log("Searching for product \"" + productConfig.ref + "\" active prices...");
  let prices = await stripe.prices.list({
    active: true,
    product: product.id,
    limit: 100
  });
  console.log("Found " + prices.data.length.toString() + " product \"" + productConfig.ref + "\" active prices");
  if (prices.has_more) {
    Stdlib_Exn.raiseError("The pagination on prices is not supported yet. Product \"" + productConfig.ref + "\" has to many active prices");
  }
  let createPriceFromConfig = async priceConfig => {
    let match = priceConfig.recurring;
    let match$1;
    if (match !== undefined) {
      if (match.TAG === "Metered") {
        let ref = match.ref;
        let meters$1 = meters !== undefined ? meters : Stdlib_Exn.raiseError("The \"meters\" argument is required when product catalog contains a Metered price");
        let usedCustomerMeters$1 = usedCustomerMeters !== undefined ? Primitive_option.valFromOption(usedCustomerMeters) : Stdlib_Exn.raiseError("The \"usedCustomerMeters\" argument is required when product catalog contains a Metered price");
        let getEventName = (meterRef, _counterOpt) => {
          while (true) {
            let counterOpt = _counterOpt;
            let counter = counterOpt !== undefined ? counterOpt : 0;
            let eventName = counter !== 0 ? meterRef + "_" + (counter + 1 | 0).toString() : meterRef;
            if (!usedCustomerMeters$1.has(eventName)) {
              return eventName;
            }
            _counterOpt = counter + 1 | 0;
            continue;
          };
        };
        let eventName = getEventName(ref, undefined);
        let meter = meters$1[eventName];
        let meter$1;
        if (meter !== undefined) {
          meter$1 = meter;
        } else {
          console.log("Meter \"" + eventName + "\" does not exist. Creating...");
          let meter$2 = await stripe.billing.meters.create({
            default_aggregation: {
              formula: "sum"
            },
            display_name: ref,
            event_name: eventName
          });
          console.log("Meter \"" + eventName + "\" successfully created. Meter ID: " + meter$2.id);
          meter$1 = meter$2;
        }
        match$1 = [
          {
            "#meter_ref": ref,
            "#meter_event_name": eventName
          },
          {
            interval: match.interval,
            meter: meter$1.id,
            usage_type: "metered"
          },
          ref === eventName,
          ref === eventName ? undefined : "Copy with meter \"" + eventName + "\""
        ];
      } else {
        match$1 = [
          undefined,
          {
            interval: match.interval
          },
          true,
          undefined
        ];
      }
    } else {
      match$1 = [
        undefined,
        undefined,
        false,
        undefined
      ];
    }
    let transferLookupKey = match$1[2];
    let match$2 = priceConfig.lookupKey;
    return await stripe.prices.create({
      currency: priceConfig.currency,
      product: product.id,
      metadata: match$1[0],
      nickname: match$1[3],
      recurring: match$1[1],
      unit_amount: priceConfig.unitAmountInCents,
      lookup_key: transferLookupKey && match$2 !== undefined && match$2 ? priceConfig.ref : undefined,
      transfer_lookup_key: transferLookupKey
    });
  };
  let priceConfig = getPriceConfig(productConfig, interval);
  let existingPrice = prices.data.find(price => {
    let tmp = false;
    if (priceConfig.currency === price.currency) {
      let tmp$1;
      if (price.metadata["#meter_ref"] === price.metadata["#meter_event_name"]) {
        let match = priceConfig.lookupKey;
        let match$1 = price.lookup_key;
        let exit = 0;
        if (match !== undefined && match) {
          tmp$1 = match$1 === null ? false : priceConfig.ref === match$1;
        } else {
          exit = 1;
        }
        if (exit === 1) {
          tmp$1 = match$1 === null;
        }
        
      } else {
        tmp$1 = true;
      }
      tmp = tmp$1;
    }
    if (!(tmp && priceConfig.unitAmountInCents === price.unit_amount)) {
      return false;
    }
    let match$2 = price.recurring;
    let match$3 = priceConfig.recurring;
    if (match$2 === null) {
      return match$3 === undefined;
    }
    if (match$3 === undefined) {
      return false;
    }
    if (match$3.TAG !== "Metered") {
      if (match$2.usage_type === "licensed" && match$2.interval === match$3.interval) {
        return match$2.meter === null;
      } else {
        return false;
      }
    }
    let usedCustomerMeters$1 = usedCustomerMeters !== undefined ? Primitive_option.valFromOption(usedCustomerMeters) : Stdlib_Exn.raiseError("The \"usedCustomerMeters\" argument is required when product catalog contains a Metered price");
    if (!(match$2.usage_type === "metered" && match$2.interval === match$3.interval && Stdlib_Option.isSome(Primitive_option.fromNull(match$2.meter)) && price.metadata["#meter_ref"] === match$3.ref)) {
      return false;
    }
    let meterEventName = price.metadata["#meter_event_name"];
    if (meterEventName !== undefined) {
      return !usedCustomerMeters$1.has(meterEventName);
    } else {
      return false;
    }
  });
  let price;
  if (existingPrice !== undefined) {
    console.log("Found an existing price \"" + priceConfig.ref + "\" for product \"" + productConfig.ref + "\". Price ID: " + existingPrice.id);
    price = existingPrice;
  } else {
    console.log("Price \"" + priceConfig.ref + "\" for product \"" + productConfig.ref + "\" is not in sync. Updating...");
    let price$1 = await createPriceFromConfig(priceConfig);
    console.log("Price \"" + priceConfig.ref + "\" for product \"" + productConfig.ref + "\" successfully recreated with the new values. Price ID: " + price$1.id);
    price = price$1;
  }
  return {
    product: product,
    price: price
  };
}

async function sync(stripe, productCatalog, usedCustomerMeters, interval) {
  let isMeterNeeded = productCatalog.products.some(p => p.prices.some(p => {
    let match = p.recurring;
    if (match !== undefined) {
      return match.TAG === "Metered";
    } else {
      return false;
    }
  }));
  let meters;
  if (isMeterNeeded) {
    console.log("Loading active meters...");
    let match = await stripe.billing.meters.list({
      status: "active",
      limit: 100
    });
    let meters$1 = match.data;
    console.log("Loaded " + meters$1.length.toString() + " active meters");
    meters = Object.fromEntries(meters$1.map(meter => [
      meter.event_name,
      meter
    ]));
  } else {
    meters = undefined;
  }
  let products = await Promise.all(productCatalog.products.map(p => syncProduct(stripe, p, meters, usedCustomerMeters, interval)));
  console.log("Successfully finished syncing products");
  return products;
}

let ProductCatalog = {
  getPriceConfig: getPriceConfig,
  syncProduct: syncProduct,
  sync: sync
};

let findByMetadata$1 = makeFindByMetadata("customer", (stripe, params) => stripe.customers.list({
  limit: params.limit,
  starting_after: params.starting_after,
  ending_before: params.ending_before
}), (prim0, prim1) => prim0.customers.retrieve(prim1));

async function findOrCreateByMetadata(stripe, metadata) {
  let c = await findByMetadata$1(stripe, metadata);
  if (c !== undefined) {
    return c;
  }
  console.log("Creating a new customer...");
  let c$1 = await stripe.customers.create({
    metadata: metadata
  });
  console.log("Successfully created a new customer with id: " + c$1.id);
  return c$1;
}

let Customer = {
  findByMetadata: findByMetadata$1,
  findOrCreateByMetadata: findOrCreateByMetadata
};

function isTerminatedStatus(status) {
  return false;
}

function getMeterId(subscription, meterRef) {
  return Stdlib_Option.flatMap(Stdlib_Option.flatMap(subscription.items.data.find(item => item.price.metadata["#meter_ref"] === meterRef), i => Primitive_option.fromNull(i.price.recurring)), r => Primitive_option.fromNull(r.meter));
}

function getMeterEventName(subscription, meterRef) {
  return Stdlib_Option.flatMap(subscription.items.data.find(item => item.price.metadata["#meter_ref"] === meterRef), i => i.price.metadata["#meter_event_name"]);
}

async function reportMeterUsage(stripe, subscription, meterRef, value, timestamp, identifier) {
  let meterEventName = getMeterEventName(subscription, meterRef);
  if (meterEventName !== undefined) {
    await stripe.billing.meterEvents.create({
      event_name: meterEventName,
      payload: {
        value: value.toString(),
        stripe_customer_id: subscription.customer
      },
      identifier: identifier,
      timestamp: timestamp
    });
    return {
      TAG: "Ok",
      _0: undefined
    };
  } else {
    return {
      TAG: "Error",
      _0: "MeterNotFound"
    };
  }
}

let Subscription = {
  isTerminatedStatus: isTerminatedStatus,
  getMeterId: getMeterId,
  getMeterEventName: getMeterEventName,
  reportMeterUsage: reportMeterUsage
};

function prefillEmail(link, email) {
  if (email !== undefined) {
    return link + "?prefilled_email=" + encodeURIComponent(email);
  } else {
    return link;
  }
}

let CustomerPortal = {
  prefillEmail: prefillEmail
};

let Session = {};

let Checkout = {
  Session: Session
};

function constructEvent(stripe, body, sig, secret) {
  try {
    let event = stripe.webhooks.constructEvent(body, sig, secret);
    let match = event.type;
    let tmp;
    switch (match) {
      case "customer.subscription.created" :
        tmp = {
          TAG: "CustomerSubscriptionCreated",
          _0: event
        };
        break;
      case "customer.subscription.deleted" :
        tmp = {
          TAG: "CustomerSubscriptionDeleted",
          _0: event
        };
        break;
      case "customer.subscription.updated" :
        tmp = {
          TAG: "CustomerSubscriptionUpdated",
          _0: event
        };
        break;
      default:
        tmp = {
          TAG: "Unknown",
          _0: event
        };
    }
    return {
      TAG: "Ok",
      _0: tmp
    };
  } catch (raw_err) {
    let err = Primitive_exceptions.internalToException(raw_err);
    if (err.RE_EXN_ID === Stdlib_Exn.$$Error) {
      return {
        TAG: "Error",
        _0: err._1.message
      };
    }
    throw err;
  }
}

let Webhook = {
  constructEvent: constructEvent
};

let Plan = {};

let refField = "#subscription_ref";

let planField = "#subscription_plan";

async function listSubscriptions(stripe, config, customerId) {
  let match = await stripe.subscriptions.list({
    customer: customerId,
    limit: 100
  });
  if (match.has_more) {
    return Stdlib_Exn.raiseError("Found more than 100 subscriptions, which is not supported yet");
  } else {
    return match.data.filter(subscription => subscription.metadata[refField] === config.ref);
  }
}

function calculatePastUsageBill(priceAmount, startedAt, now, interval) {
  let monthlyPrice;
  if (interval !== undefined) {
    switch (interval) {
      case "day" :
      case "week" :
        monthlyPrice = Stdlib_Exn.raiseError("The past usage bill only supports subscriptions with yearly or monthly intervals");
        break;
      case "month" :
        monthlyPrice = priceAmount;
        break;
      case "year" :
        monthlyPrice = priceAmount / 12;
        break;
    }
  } else {
    monthlyPrice = Stdlib_Exn.raiseError("The past usage bill only supports subscriptions with yearly or monthly intervals");
  }
  let yearsDiff = now.getFullYear() - startedAt.getFullYear() | 0;
  let monthsDiff = now.getMonth() - startedAt.getMonth() | 0;
  let totalMonths = (yearsDiff * 12 | 0) + monthsDiff | 0;
  let daysInStartMonth = new Date(startedAt.getFullYear(), startedAt.getMonth() + 1 | 0, 0).getDate();
  let daysUsedFirstMonth = daysInStartMonth - startedAt.getDate() | 0;
  let firstMonthFraction = daysUsedFirstMonth / daysInStartMonth;
  let daysUsedCurrentMonth = now.getDate();
  let daysInCurrentMonth = new Date(now.getFullYear(), now.getMonth() + 1 | 0, 0).getDate();
  let currentMonthFraction = daysUsedCurrentMonth / daysInCurrentMonth;
  let fullMonths = totalMonths - 1 | 0;
  return fullMonths * monthlyPrice + firstMonthFraction * monthlyPrice + currentMonthFraction * monthlyPrice | 0;
}

function toPresetKey(config, processedData) {
  let key = {
    contents: "##" + config.ref
  };
  processedData.presetLookupFields.forEach(name => {
    key.contents = key.contents + ":" + processedData.dict[name];
  });
  return key.contents.slice(0, 40);
}

let startedAtSchema = S$RescriptSchema.union([
  S$RescriptSchema.shape(S$RescriptSchema.literal(0), param => {}),
  S$RescriptSchema.transform(S$RescriptSchema.float, param => ({
    p: float => new Date(float),
    s: date => date.getTime()
  }))
]);

function toPresetSchema(config) {
  return S$RescriptSchema.tuple2(S$RescriptSchema.union(config.plans.map(param => {
    let planConfig = param[1];
    return S$RescriptSchema.schema(s => planConfig({
      field: param => s.m(param.schema),
      tag: (param, param$1) => {},
      matches: schema => s.m(schema)
    }));
  })), startedAtSchema);
}

function processData(data, config) {
  let primaryFields = [refField];
  let customerLookupFields = [];
  let presetLookupFields = [];
  let metadataFields = [refField];
  let schema = S$RescriptSchema.object(s => {
    s.tag(refField, config.ref);
    return config.data({
      primary: (param, $staropt$star) => {
        let fieldName = param.fieldName;
        let customerLookup = $staropt$star !== undefined ? $staropt$star : false;
        primaryFields.push(fieldName);
        metadataFields.push(fieldName);
        if (customerLookup) {
          customerLookupFields.push(fieldName);
        } else {
          presetLookupFields.push(fieldName);
        }
        return s.f(fieldName, param.coereced);
      },
      field: param => {
        let fieldName = param.fieldName;
        metadataFields.push(fieldName);
        return s.f(fieldName, param.coereced);
      }
    });
  });
  if (customerLookupFields.length === 0) {
    Stdlib_Exn.raiseError("The data schema must define at least one primary field with ~customerLookup=true");
  }
  let dict = S$RescriptSchema.reverseConvertOrThrow(data, schema);
  let customerMetadata = {};
  customerLookupFields.forEach(name => {
    customerMetadata[name] = dict[name];
  });
  return {
    value: data,
    dict: dict,
    schema: schema,
    primaryFields: primaryFields,
    customerMetadata: customerMetadata,
    metadataFields: metadataFields,
    presetLookupFields: presetLookupFields
  };
}

async function internalRetrieveSubscription(stripe, data, config, customerId, usedMetersAcc) {
  console.log("Searching for an existing \"" + config.ref + "\" subscription for customer \"" + customerId + "\"...");
  let subscriptions = await listSubscriptions(stripe, config, customerId);
  let s = subscriptions.find(subscription => {
    if (usedMetersAcc !== undefined) {
      let usedMetersAcc$1 = Primitive_option.valFromOption(usedMetersAcc);
      subscription.items.data.forEach(item => {
        let meterEventName = item.price.metadata["#meter_event_name"];
        if (meterEventName !== undefined) {
          usedMetersAcc$1.add(meterEventName);
          return;
        }
        
      });
    }
    if (data.primaryFields.every(name => subscription.metadata[name] === data.dict[name])) {
      console.log("Found an existing subscription. Subscription ID: " + subscription.id);
      return true;
    } else {
      return false;
    }
  });
  if (Stdlib_Option.isNone(s)) {
    console.log("No existing subscriptions \"" + config.ref + "\" found for customer \"" + customerId + "\" with the provided data.");
  }
  return s;
}

function retrieveCustomer(stripe, config, data) {
  return findByMetadata$1(stripe, processData(data, config).customerMetadata);
}

async function retrieveSubscriptionWithCustomer(stripe, config, data) {
  let processedData = processData(data, config);
  let customer = await findByMetadata$1(stripe, processedData.customerMetadata);
  if (customer === undefined) {
    return {
      customer: undefined,
      subscription: undefined,
      preset: undefined
    };
  }
  let preset = customer.metadata[toPresetKey(config, processedData)];
  let preset$1;
  if (preset !== undefined) {
    let presetSchema = toPresetSchema(config);
    try {
      let match = S$RescriptSchema.parseJsonStringOrThrow(preset, presetSchema);
      let startedAt = match[1];
      preset$1 = {
        config: config,
        data: data,
        plan: match[0],
        billPastUsage: startedAt !== undefined ? ({
            startedAt: Primitive_option.valFromOption(startedAt)
          }) : undefined
      };
    } catch (raw_exn) {
      let exn = Primitive_exceptions.internalToException(raw_exn);
      console.log("Failed to parse preset \"" + preset + "\" for \"" + config.ref + "\" subscription.", exn);
      preset$1 = undefined;
    }
  } else {
    preset$1 = undefined;
  }
  let subscription = await internalRetrieveSubscription(stripe, processedData, config, customer.id, undefined);
  if (subscription !== undefined) {
    return {
      customer: customer,
      subscription: subscription,
      preset: preset$1
    };
  } else {
    return {
      customer: customer,
      subscription: undefined,
      preset: preset$1
    };
  }
}

async function retrieveSubscription(stripe, config, data) {
  return (await retrieveSubscriptionWithCustomer(stripe, config, data)).subscription;
}

async function preset(stripe, preset$1) {
  let processedData = processData(preset$1.data, preset$1.config);
  let presetKey = toPresetKey(preset$1.config, processedData);
  let preset$2 = S$RescriptSchema.reverseConvertToJsonStringOrThrow([
    preset$1.plan,
    Stdlib_Option.map(preset$1.billPastUsage, v => v.startedAt)
  ], toPresetSchema(preset$1.config), undefined);
  let metadata = {};
  metadata[presetKey] = preset$2;
  let c = await findByMetadata$1(stripe, processedData.customerMetadata);
  if (c !== undefined) {
    console.log("Setting preset for the existing customer...");
    let c$1 = await stripe.customers.update(c.id, {
      metadata: metadata
    });
    console.log("Successfully set preset for the existing customer");
    return c$1;
  }
  console.log("Creating a new customer...");
  let c$2 = await stripe.customers.create({
    metadata: Object.assign(metadata, processedData.customerMetadata)
  });
  console.log("Successfully created a new customer with id: " + c$2.id);
  return c$2;
}

async function createHostedCheckoutSession(stripe, params) {
  let data = processData(params.data, params.config);
  let planMetadataFields = [planField];
  let planSchema = S$RescriptSchema.union(params.config.plans.map(param => {
    let planConfig = param[1];
    let planRef = param[0];
    return S$RescriptSchema.object(s => {
      let matchesCounter = {
        contents: -1
      };
      s.tag(planField, planRef);
      return planConfig({
        field: param => {
          let fieldName = param.fieldName;
          planMetadataFields.push(fieldName);
          return s.f(fieldName, param.coereced);
        },
        tag: (param, value) => {
          let fieldName = param.fieldName;
          planMetadataFields.push(fieldName);
          s.f(fieldName, S$RescriptSchema.literal(S$RescriptSchema.reverseConvertOrThrow(value, param.coereced)));
        },
        matches: schema => {
          matchesCounter.contents = matchesCounter.contents + 1 | 0;
          return s.f("#matches" + matchesCounter.contents.toString(), schema);
        }
      });
    });
  }));
  let rawPlan = S$RescriptSchema.reverseConvertOrThrow(params.plan, planSchema);
  let now = new Date();
  let planId = rawPlan[planField];
  let products = params.config.products(params.plan, params.data);
  let products$1;
  if (products.length !== 0) {
    let match = params.billPastUsage;
    if (match !== undefined) {
      let startedAt = match.startedAt;
      products$1 = Stdlib_Array.filterMap(products, p => {
        let priceConfig = getPriceConfig(p, params.interval);
        let match = priceConfig.recurring;
        if (match === undefined) {
          return;
        }
        if (match.TAG === "Metered") {
          return;
        }
        let pastUsageBill = calculatePastUsageBill(priceConfig.unitAmountInCents, startedAt, now, params.interval);
        if (pastUsageBill === 0) {
          return;
        } else {
          return {
            name: p.name + " from " + startedAt.toLocaleDateString("en-US", {
              dateStyle: "medium"
            }) + " to " + now.toLocaleDateString("en-US", {
              dateStyle: "medium"
            }),
            ref: p.ref + "_from_" + startedAt.toLocaleDateString("en-US", {
              dateStyle: "short"
            }) + "_to_" + now.toLocaleDateString("en-US", {
              dateStyle: "short"
            }),
            prices: [{
                ref: priceConfig.ref,
                currency: priceConfig.currency,
                unitAmountInCents: pastUsageBill
              }]
          };
        }
      }).concat(products);
    } else {
      products$1 = products;
    }
  } else {
    products$1 = Stdlib_Exn.raiseError("Plan \"" + planId + "\" doesn't have any products configured");
  }
  let customer = await findOrCreateByMetadata(stripe, data.customerMetadata);
  let usedCustomerMeters = new Set();
  let subscription = await internalRetrieveSubscription(stripe, data, params.config, customer.id, Primitive_option.some(usedCustomerMeters));
  if (subscription !== undefined) {
    Stdlib_Exn.raiseError("There's already an active \"" + params.config.ref + "\" subscription for " + data.primaryFields.map(name => name + "=" + data.dict[name]).join(", ") + " with the \"" + subscription.metadata[planField] + "\" plan and id \"" + subscription.id + "\". Either update the existing subscription or cancel it and create a new one");
  } else {
    console.log("Customer doesn't have an active \"" + params.config.ref + "\" subscription");
  }
  let productItems = await sync(stripe, {
    products: products$1
  }, Primitive_option.some(usedCustomerMeters), params.interval);
  console.log("Creating a new checkout session for subscription \"" + params.config.ref + "\" plan \"" + planId + "\"...");
  let match$1 = params.config.termsOfServiceConsent;
  let session = await stripe.checkout.sessions.create({
    automatic_tax: params.automaticTax,
    customer_update: {
      address: "auto",
      name: "auto",
      shipping: "auto"
    },
    mode: "subscription",
    success_url: params.successUrl,
    cancel_url: params.cancelUrl,
    consent_collection: match$1 !== undefined && match$1 ? ({
        terms_of_service: "required"
      }) : undefined,
    subscription_data: {
      description: params.description,
      metadata: Object.fromEntries(data.metadataFields.map(name => [
        name,
        data.dict[name]
      ]).concat(planMetadataFields.map(name => [
        name,
        rawPlan[name]
      ]))),
      billing_cycle_anchor: params.billingCycleAnchor
    },
    allow_promotion_codes: params.allowPromotionCodes,
    customer: customer.id,
    line_items: productItems.map(param => {
      let price = param.price;
      let match = price.recurring;
      let id = price.id;
      if (match === null) {
        return {
          price: id,
          quantity: 1
        };
      }
      let tmp = match.meter;
      if (tmp === null) {
        return {
          price: id,
          quantity: 1
        };
      } else {
        return {
          price: id
        };
      }
    })
  });
  let url = session.url;
  let tmp;
  tmp = url === null ? "" : " Url: " + url;
  console.log("Successfully created a new checkout session. Session ID: " + session.id + "." + tmp + "\n    ");
  return session;
}

function verify(subscription, config) {
  if (subscription.metadata[refField] === config.ref) {
    return subscription;
  }
  
}

let Billing = {
  Plan: Plan,
  refField: refField,
  planField: planField,
  listSubscriptions: listSubscriptions,
  calculatePastUsageBill: calculatePastUsageBill,
  retrieveCustomer: retrieveCustomer,
  retrieveSubscriptionWithCustomer: retrieveSubscriptionWithCustomer,
  retrieveSubscription: retrieveSubscription,
  preset: preset,
  createHostedCheckoutSession: createHostedCheckoutSession,
  verify: verify
};

function ref(fieldName, schema) {
  return {
    fieldName: fieldName,
    schema: schema,
    coereced: S$RescriptSchema.coerce(S$RescriptSchema.string, schema)
  };
}

function get(subscription, metadataRef) {
  return S$RescriptSchema.parseOrThrow(subscription.metadata[metadataRef.fieldName], metadataRef.schema);
}

let Metadata = {
  ref: ref,
  get: get
};

export {
  make,
  makeFindByMetadata,
  Meter,
  MeterEvent,
  Price,
  Product,
  ProductCatalog,
  Customer,
  Subscription,
  CustomerPortal,
  Checkout,
  Webhook,
  Billing,
  Metadata,
}
/* findByMetadata Not a pure module */
