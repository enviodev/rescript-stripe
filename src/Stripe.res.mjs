// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Js_exn from "rescript/lib/es6/js_exn.js";
import Stripe from "stripe";
import * as Js_dict from "rescript/lib/es6/js_dict.js";
import * as Js_option from "rescript/lib/es6/js_option.js";
import * as Belt_Array from "rescript/lib/es6/belt_Array.js";
import * as Belt_Option from "rescript/lib/es6/belt_Option.js";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as S$RescriptSchema from "rescript-schema/src/S.res.mjs";
import * as Caml_js_exceptions from "rescript/lib/es6/caml_js_exceptions.js";

function $$catch(promise, callback) {
  return promise.catch(function (err) {
              return callback(Caml_js_exceptions.internalToOCamlException(err));
            });
}

var $$Promise = {
  $$catch: $$catch
};

var unsafeDeleteKey = (function (dict,key) {
      delete dict[key];
    });

var Dict = {
  unsafeDeleteKey: unsafeDeleteKey
};

function addMany(set, values) {
  values.forEach(function (value) {
        set.add(value);
      });
}

var $$Set = {
  addMany: addMany
};

var Stdlib = {
  $$Promise: $$Promise,
  Dict: Dict,
  $$Set: $$Set
};

function make(prim) {
  return new Stripe(prim);
}

var Meter = {};

var MeterEvent = {};

var Price = {};

var Product = {};

async function syncProduct(stripe, productConfig, meters, usedCustomerMeters, interval) {
  console.log("Searching for active product \"" + productConfig.ref + "\"...");
  var match = await stripe.products.search({
        query: "active:\"true\" AND metadata[\"#product_ref\"]:\"" + productConfig.ref + "\"",
        limit: 2
      });
  var match$1 = match.data;
  var len = match$1.length;
  var product;
  if (len !== 1) {
    if (len !== 0) {
      product = Js_exn.raiseError("There are multiple active products \"" + productConfig.ref + "\". Please go to dashboard and delete not needed ones (https://dashboard.stripe.com/test/products?active=true)");
    } else {
      console.log("No active product \"" + productConfig.ref + "\" found. Creating a new one...");
      var p = await stripe.products.create({
            name: productConfig.name,
            metadata: Js_dict.fromArray([[
                    "#product_ref",
                    productConfig.ref
                  ]]),
            unit_label: productConfig.unitLabel
          });
      console.log("Product \"" + productConfig.ref + "\" successfully created. Product ID: " + p.id);
      product = p;
    }
  } else {
    var p$1 = match$1[0];
    console.log("Found an existing product \"" + productConfig.ref + "\". Product ID: " + p$1.id);
    var fieldsToSync = {};
    var match$2 = p$1.unit_label;
    var match$3 = productConfig.unitLabel;
    var exit = 0;
    if (match$2 === null) {
      if (match$3 !== undefined) {
        exit = 1;
      }
      
    } else if (!(match$3 !== undefined && match$2 === match$3)) {
      exit = 1;
    }
    if (exit === 1) {
      if (match$3 !== undefined) {
        fieldsToSync.unit_label = match$3;
      } else {
        fieldsToSync.unit_label = "";
      }
    }
    var fieldNamesToSync = Object.keys(fieldsToSync);
    if (fieldNamesToSync.length > 0) {
      console.log("Syncing product \"" + productConfig.ref + "\" fields " + fieldNamesToSync.join(", ") + "...");
      var p$2 = await stripe.products.update(p$1.id, fieldsToSync);
      console.log("Product \"" + productConfig.ref + "\" fields successfully updated");
      product = p$2;
    } else {
      console.log("Product \"" + productConfig.ref + "\" is in sync");
      product = p$1;
    }
  }
  console.log("Searching for product \"" + productConfig.ref + "\" active prices...");
  var prices = await stripe.prices.list({
        active: true,
        product: product.id
      });
  console.log("Found " + prices.data.length.toString() + " product \"" + productConfig.ref + "\" active prices");
  if (prices.has_more) {
    Js_exn.raiseError("The pagination on prices is not supported yet. Product \"" + productConfig.ref + "\" has to many active prices");
  }
  var createPriceFromConfig = async function (priceConfig) {
    var match = priceConfig.recurring;
    var match$1;
    if (match.TAG === "Metered") {
      var ref = match.ref;
      var meters$1 = meters !== undefined ? meters : Js_exn.raiseError("The \"meters\" argument is required when product catalog contains a Metered price");
      var usedCustomerMeters$1 = usedCustomerMeters !== undefined ? Caml_option.valFromOption(usedCustomerMeters) : Js_exn.raiseError("The \"usedCustomerMeters\" argument is required when product catalog contains a Metered price");
      var getEventName = function (meterRef, _counterOpt) {
        while(true) {
          var counterOpt = _counterOpt;
          var counter = counterOpt !== undefined ? counterOpt : 0;
          var eventName = counter !== 0 ? meterRef + "_" + (counter + 1 | 0).toString() : meterRef;
          if (!usedCustomerMeters$1.has(eventName)) {
            return eventName;
          }
          _counterOpt = counter + 1 | 0;
          continue ;
        };
      };
      var eventName = getEventName(ref, undefined);
      var meter = Js_dict.get(meters$1, eventName);
      var meter$1;
      if (meter !== undefined) {
        meter$1 = meter;
      } else {
        console.log("Meter \"" + eventName + "\" does not exist. Creating...");
        var meter$2 = await stripe.billing.meters.create({
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
        Js_dict.fromArray([
              [
                "#meter_ref",
                ref
              ],
              [
                "#meter_event_name",
                eventName
              ],
              [
                "#price_ref",
                priceConfig.ref
              ]
            ]),
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
    var transferLookupKey = match$1[2];
    var match$2 = priceConfig.lookupKey;
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
  var prices$1 = await Promise.all(productConfig.prices.filter(function (priceConfig) {
              var match = priceConfig.recurring;
              if (interval !== undefined) {
                return match.interval === interval;
              } else {
                return true;
              }
            }).map(async function (priceConfig) {
            var existingPrice = prices.data.find(function (price) {
                  var tmp = false;
                  if (priceConfig.currency === price.currency) {
                    var match = priceConfig.lookupKey;
                    var match$1 = price.lookup_key;
                    var tmp$1;
                    var exit = 0;
                    if (match !== undefined && match) {
                      tmp$1 = match$1 === null ? false : priceConfig.ref === match$1;
                    } else {
                      exit = 1;
                    }
                    if (exit === 1) {
                      tmp$1 = match$1 === null ? true : false;
                    }
                    tmp = tmp$1;
                  }
                  if (!(tmp && priceConfig.unitAmountInCents === price.unit_amount)) {
                    return false;
                  }
                  var priceRecurring = price.recurring;
                  if (priceRecurring === null) {
                    return false;
                  }
                  var match$2 = priceConfig.recurring;
                  if (match$2.TAG !== "Metered") {
                    if (priceRecurring.usage_type === "licensed" && priceRecurring.interval === match$2.interval) {
                      return priceRecurring.meter === null;
                    } else {
                      return false;
                    }
                  }
                  var usedCustomerMeters$1 = usedCustomerMeters !== undefined ? Caml_option.valFromOption(usedCustomerMeters) : Js_exn.raiseError("The \"usedCustomerMeters\" argument is required when product catalog contains a Metered price");
                  if (!(priceRecurring.usage_type === "metered" && priceRecurring.interval === match$2.interval && Js_option.isSome(Caml_option.null_to_opt(priceRecurring.meter)) && price.metadata["#meter_ref"] === match$2.ref)) {
                    return false;
                  }
                  var meterEventName = Js_dict.get(price.metadata, "#meter_event_name");
                  if (meterEventName !== undefined) {
                    return !usedCustomerMeters$1.has(meterEventName);
                  } else {
                    return false;
                  }
                });
            if (existingPrice !== undefined) {
              console.log("Found an existing price \"" + priceConfig.ref + "\" for product \"" + productConfig.ref + "\". Price ID: " + existingPrice.id);
              return existingPrice;
            }
            console.log("Price \"" + priceConfig.ref + "\" for product \"" + productConfig.ref + "\" is not in sync. Updating...");
            var price = await createPriceFromConfig(priceConfig);
            console.log("Price \"" + priceConfig.ref + "\" for product \"" + productConfig.ref + "\" successfully recreated with the new values. Price ID: " + price.id);
            return price;
          }));
  return {
          product: product,
          prices: prices$1
        };
}

async function sync(stripe, productCatalog, usedCustomerMeters, interval) {
  var isMeterNeeded = productCatalog.products.some(function (p) {
        return p.prices.some(function (p) {
                    var match = p.recurring;
                    if (match.TAG === "Metered") {
                      return true;
                    } else {
                      return false;
                    }
                  });
      });
  var meters;
  if (isMeterNeeded) {
    console.log("Loading active meters...");
    var match = await stripe.billing.meters.list({
          status: "active",
          limit: 100
        });
    var meters$1 = match.data;
    console.log("Loaded " + meters$1.length.toString() + " active meters");
    meters = Js_dict.fromArray(meters$1.map(function (meter) {
              return [
                      meter.event_name,
                      meter
                    ];
            }));
  } else {
    meters = undefined;
  }
  var products = await Promise.all(productCatalog.products.map(function (p) {
            return syncProduct(stripe, p, meters, usedCustomerMeters, interval);
          }));
  console.log("Successfully finished syncing products");
  return products;
}

var ProductCatalog = {
  syncProduct: syncProduct,
  sync: sync
};

var Customer = {};

function isTerminatedStatus(status) {
  return false;
}

function getMeterId(subscription, meterRef) {
  return Belt_Option.flatMap(Belt_Option.flatMap(Caml_option.undefined_to_opt(subscription.items.data.find(function (item) {
                          return item.price.metadata["#meter_ref"] === meterRef;
                        })), (function (i) {
                    return Caml_option.null_to_opt(i.price.recurring);
                  })), (function (r) {
                return Caml_option.null_to_opt(r.meter);
              }));
}

function getMeterEventName(subscription, meterRef) {
  return Belt_Option.flatMap(Caml_option.undefined_to_opt(subscription.items.data.find(function (item) {
                      return item.price.metadata["#meter_ref"] === meterRef;
                    })), (function (i) {
                return Js_dict.get(i.price.metadata, "#meter_event_name");
              }));
}

async function reportMeterUsage(stripe, subscription, meterRef, value, timestamp, identifier) {
  var meterEventName = getMeterEventName(subscription, meterRef);
  if (meterEventName !== undefined) {
    await stripe.billing.meterEvents.create({
          event_name: meterEventName,
          payload: Js_dict.fromArray([
                [
                  "value",
                  value.toString()
                ],
                [
                  "stripe_customer_id",
                  subscription.customer
                ]
              ]),
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

var Subscription = {
  isTerminatedStatus: isTerminatedStatus,
  getMeterId: getMeterId,
  getMeterEventName: getMeterEventName,
  reportMeterUsage: reportMeterUsage
};

var Session = {};

var Checkout = {
  Session: Session
};

var Tier = {};

var refField = "#subscription_ref";

var tierField = "#subscription_tier";

async function listSubscriptions(stripe, config, customerId) {
  var match = await stripe.subscriptions.list({
        customer: customerId,
        limit: 100
      });
  if (match.has_more) {
    return Js_exn.raiseError("Found more than 100 subscriptions, which is not supported yet");
  } else {
    return match.data.filter(function (subscription) {
                return subscription.metadata[refField] === config.ref;
              });
  }
}

function validateMetadataSchema(schema) {
  var match = schema.t;
  if (typeof match !== "object") {
    if (match === "string") {
      return ;
    } else {
      return Js_exn.raiseError("Currently only string schemas are supported for data fields");
    }
  } else if (match.TAG === "literal" && match._0.kind === "String") {
    return ;
  } else {
    return Js_exn.raiseError("Currently only string schemas are supported for data fields");
  }
}

function processData(data, config) {
  var primaryFields = [refField];
  var customerLookupFields = [];
  var metadataFields = [refField];
  var schema = S$RescriptSchema.object(function (s) {
        s.tag(refField, config.ref);
        return config.data({
                    primary: (function (name, schema, customerLookupOpt) {
                        var customerLookup = customerLookupOpt !== undefined ? customerLookupOpt : false;
                        validateMetadataSchema(schema);
                        primaryFields.push(name);
                        metadataFields.push(name);
                        if (customerLookup) {
                          customerLookupFields.push(name);
                        }
                        return s.f(name, schema);
                      }),
                    metadata: (function (name, schema) {
                        validateMetadataSchema(schema);
                        metadataFields.push(name);
                        return s.f(name, schema);
                      })
                  });
      });
  if (customerLookupFields.length === 0) {
    Js_exn.raiseError("The data schema must define at least one primary field with ~customerLookup=true");
  }
  var dict = S$RescriptSchema.reverseConvertOrThrow(data, schema);
  return {
          value: data,
          dict: dict,
          schema: schema,
          primaryFields: primaryFields,
          customerLookupFields: customerLookupFields,
          metadataFields: metadataFields
        };
}

async function internalRetrieveCustomer(stripe, data) {
  var customerSearchQuery = data.customerLookupFields.map(function (name) {
          return "metadata[\"" + name + "\"]:\"" + data.dict[name] + "\"";
        }).join("AND");
  console.log("Searching for an existing customer with query: " + customerSearchQuery);
  var match = await stripe.customers.search({
        query: customerSearchQuery,
        limit: 2
      });
  var match$1 = match.data;
  var len = match$1.length;
  if (len !== 1) {
    if (len !== 0) {
      return Js_exn.raiseError("Found multiple customers for the search query: " + customerSearchQuery);
    } else {
      console.log("No customer found");
      return ;
    }
  }
  var c = match$1[0];
  console.log("Successfully found customer with id: " + c.id);
  return c;
}

async function internalRetrieveSubscription(stripe, data, config, customerId, usedMetersAcc) {
  console.log("Searching for an existing \"" + config.ref + "\" subscription for customer \"" + customerId + "\"...");
  var subscriptions = await listSubscriptions(stripe, config, customerId);
  console.log("Found " + subscriptions.length.toString() + " subscriptions for the customer. Validating that the new subscription is not already active...");
  return Caml_option.undefined_to_opt(subscriptions.find(function (subscription) {
                  if (usedMetersAcc !== undefined) {
                    var usedMetersAcc$1 = Caml_option.valFromOption(usedMetersAcc);
                    Belt_Array.forEach(subscription.items.data, (function (item) {
                            var meterEventName = Js_dict.get(item.price.metadata, "#meter_event_name");
                            if (meterEventName !== undefined) {
                              usedMetersAcc$1.add(meterEventName);
                              return ;
                            }
                            
                          }));
                  }
                  if (data.primaryFields.every(function (name) {
                          return subscription.metadata[name] === data.dict[name];
                        })) {
                    console.log("Found an existing subscription. Subscription ID: " + subscription.id);
                    return true;
                  } else {
                    return false;
                  }
                }));
}

function retrieveCustomer(stripe, config, data) {
  return internalRetrieveCustomer(stripe, processData(data, config));
}

async function retrieveSubscription(stripe, config, data) {
  var processedData = processData(data, config);
  var customer = await internalRetrieveCustomer(stripe, processedData);
  if (customer !== undefined) {
    return await internalRetrieveSubscription(stripe, processedData, config, customer.id, undefined);
  }
  
}

async function createHostedCheckoutSession(stripe, params) {
  var data = processData(params.data, params.config);
  var tierMetadataFields = [tierField];
  var tierSchema = S$RescriptSchema.union(params.config.tiers.map(function (param) {
            var tierConfig = param[1];
            var tierRef = param[0];
            return S$RescriptSchema.object(function (s) {
                        var matchesCounter = {
                          contents: -1
                        };
                        s.tag(tierField, tierRef);
                        return tierConfig({
                                    metadata: (function (name, schema) {
                                        validateMetadataSchema(schema);
                                        tierMetadataFields.push(name);
                                        return s.f(name, schema);
                                      }),
                                    matches: (function (schema) {
                                        matchesCounter.contents = matchesCounter.contents + 1 | 0;
                                        return s.f("#matches" + matchesCounter.contents.toString(), schema);
                                      })
                                  });
                      });
          }));
  var rawTier = S$RescriptSchema.reverseConvertOrThrow(params.tier, tierSchema);
  var tierId = rawTier[tierField];
  var p = params.config.products(params.tier, params.data);
  var products = p.length !== 0 ? p : Js_exn.raiseError("Tier \"" + tierId + "\" doesn't have any products configured");
  var c = await internalRetrieveCustomer(stripe, data);
  var customer;
  if (c !== undefined) {
    customer = c;
  } else {
    console.log("Creating a new customer...");
    var c$1 = await stripe.customers.create({
          metadata: Js_dict.fromArray(data.customerLookupFields.map(function (name) {
                    return [
                            name,
                            data.dict[name]
                          ];
                  }))
        });
    console.log("Successfully created a new customer with id: " + c$1.id);
    customer = c$1;
  }
  var usedCustomerMeters = new Set();
  var subscription = await internalRetrieveSubscription(stripe, data, params.config, customer.id, Caml_option.some(usedCustomerMeters));
  if (subscription !== undefined) {
    Js_exn.raiseError("There's already an active \"" + params.config.ref + "\" subscription for " + data.primaryFields.map(function (name) {
                return name + "=" + data.dict[name];
              }).join(", ") + " with the \"" + subscription.metadata[tierField] + "\" tier and id \"" + subscription.id + "\". Either update the existing subscription or cancel it and create a new one");
  } else {
    console.log("Customer doesn't have an active \"" + params.config.ref + "\" subscription");
  }
  var productItems = await sync(stripe, {
        products: products
      }, Caml_option.some(usedCustomerMeters), params.interval);
  console.log("Creating a new checkout session for subscription \"" + params.config.ref + "\" tier \"" + tierId + "\"...");
  var match = params.config.termsOfServiceConsent;
  var session = await stripe.checkout.sessions.create({
        mode: "subscription",
        success_url: params.successUrl,
        cancel_url: params.cancelUrl,
        consent_collection: match !== undefined && match ? ({
              terms_of_service: "required"
            }) : undefined,
        subscription_data: {
          description: params.description,
          metadata: Js_dict.fromArray(data.metadataFields.map(function (name) {
                      return [
                              name,
                              data.dict[name]
                            ];
                    }).concat(tierMetadataFields.map(function (name) {
                        return [
                                name,
                                rawTier[name]
                              ];
                      }))),
          billing_cycle_anchor: params.billingCycleAnchor
        },
        allow_promotion_codes: params.allowPromotionCodes,
        customer: customer.id,
        line_items: productItems.map(function (param) {
              var prices = param.prices;
              var product = param.product;
              var match = params.interval;
              var len = prices.length;
              var lineItemPrice = len !== 1 ? (
                  len !== 0 ? (
                      match !== undefined ? Js_exn.raiseError("Product \"" + product.name + "\" has multiple prices for interval \"" + match + "\"") : Js_exn.raiseError("Product \"" + product.name + "\" has multiple prices but no interval specified. Use \"interval\" param to dynamically choose which price use for the tier")
                    ) : (
                      match !== undefined ? Js_exn.raiseError("Product \"" + product.name + "\" doesn't have prices for interval \"" + match + "\"") : Js_exn.raiseError("Product \"" + product.name + "\" doesn't have any prices")
                    )
                ) : prices[0];
              var match$1 = lineItemPrice.recurring;
              var id = lineItemPrice.id;
              if (match$1 === null) {
                return {
                        price: id,
                        quantity: 1
                      };
              }
              var tmp = match$1.meter;
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
  console.log(session);
  console.log("Successfully created a new checkout session");
}

var TieredSubscription = {
  Tier: Tier,
  refField: refField,
  tierField: tierField,
  listSubscriptions: listSubscriptions,
  retrieveCustomer: retrieveCustomer,
  retrieveSubscription: retrieveSubscription,
  createHostedCheckoutSession: createHostedCheckoutSession
};

export {
  Stdlib ,
  make ,
  Meter ,
  MeterEvent ,
  Price ,
  Product ,
  ProductCatalog ,
  Customer ,
  Subscription ,
  Checkout ,
  TieredSubscription ,
}
/* stripe Not a pure module */
