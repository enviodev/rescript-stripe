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

var Stdlib = {
  $$Promise: $$Promise,
  Dict: Dict
};

function make(prim) {
  return new Stripe(prim);
}

var Meter = {};

var Price = {};

var Product = {};

async function syncProduct(stripe, productConfig, meters) {
  console.log("Searching for active product \"" + productConfig.ref + "\"...");
  var match = await stripe.products.search({
        query: "active:\"true\" AND metadata[\"product_ref\"]:\"" + productConfig.ref + "\"",
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
                    "product_ref",
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
  var createPriceFromConfig = async function (priceConfig, transferLookupKey) {
    var match = priceConfig.recurring;
    var tmp;
    tmp = match.TAG === "Metered" ? Js_dict.fromArray([[
              "#meter_ref",
              match.ref
            ]]) : undefined;
    var match$1 = priceConfig.recurring;
    var tmp$1;
    if (match$1.TAG === "Metered") {
      var ref = match$1.ref;
      var meters$1 = meters !== undefined ? meters : Js_exn.raiseError("The Meters hash map argument is required when you defined metered prices");
      var meter = Js_dict.get(meters$1, ref);
      var meter$1;
      if (meter !== undefined) {
        meter$1 = meter;
      } else {
        console.log("Meter \"" + ref + "\" does not exist. Creating...");
        var meter$2 = await stripe.billing.meters.create({
              default_aggregation: {
                formula: "sum"
              },
              display_name: ref,
              event_name: ref
            });
        console.log("Meter \"" + ref + "\" successfully created. Meter ID: " + meter$2.id);
        meter$1 = meter$2;
      }
      tmp$1 = {
        interval: match$1.interval,
        meter: meter$1.id,
        usage_type: "metered"
      };
    } else {
      tmp$1 = {
        interval: match$1.interval
      };
    }
    return await stripe.prices.create({
                currency: priceConfig.currency,
                product: product.id,
                metadata: tmp,
                recurring: tmp$1,
                unit_amount: priceConfig.unitAmountInCents,
                lookup_key: priceConfig.lookupKey,
                transfer_lookup_key: transferLookupKey
              });
  };
  var prices$1 = await Promise.all(productConfig.prices.map(async function (priceConfig) {
            var existingPrice = prices.data.find(function (price) {
                  if (!(priceConfig.currency === price.currency && priceConfig.lookupKey === Caml_option.null_to_opt(price.lookup_key) && priceConfig.unitAmountInCents === price.unit_amount)) {
                    return false;
                  }
                  var priceRecurring = price.recurring;
                  if (priceRecurring === null) {
                    return false;
                  }
                  var match = priceConfig.recurring;
                  if (match.TAG === "Metered") {
                    if (priceRecurring.usage_type === "metered" && priceRecurring.interval === match.interval && Js_option.isSome(Caml_option.null_to_opt(priceRecurring.meter))) {
                      return price.metadata["#meter_ref"] === match.ref;
                    } else {
                      return false;
                    }
                  } else if (priceRecurring.usage_type === "licensed" && priceRecurring.interval === match.interval) {
                    return priceRecurring.meter === null;
                  } else {
                    return false;
                  }
                });
            if (existingPrice !== undefined) {
              console.log("Found an existing price \"" + Belt_Option.getWithDefault(priceConfig.lookupKey, "-") + "\" for product \"" + productConfig.ref + "\". Price ID: " + existingPrice.id);
              return existingPrice;
            }
            console.log("A price for product \"" + productConfig.ref + "\" is not in sync. Updating...");
            var price = await createPriceFromConfig(priceConfig, true);
            console.log("Price for product \"" + productConfig.ref + "\" successfully recreated with the new values. Price ID: " + price.id);
            return price;
          }));
  return {
          product: product,
          prices: prices$1
        };
}

async function sync(stripe, productCatalog) {
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
            return syncProduct(stripe, p, meters);
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

var Subscription = {
  isTerminatedStatus: isTerminatedStatus,
  getMeterId: getMeterId
};

var Session = {};

var Checkout = {
  Session: Session
};

var Tier = {};

var refField = "#subscription_ref";

var tierField = "#subscription_tier";

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

async function internalRetrieveSubscription(stripe, data, subecriptionRef, customer) {
  console.log("Searching for an existing \"" + subecriptionRef + "\" subscription...");
  var match = await stripe.subscriptions.list({
        customer: customer.id,
        status: "active",
        limit: 100
      });
  if (match.has_more) {
    return Js_exn.raiseError("Customers has more than 100 subscriptions, which is not supported yet");
  }
  var subscriptions = match.data;
  console.log("Found " + subscriptions.length.toString() + " subscriptions for the customer. Validating that the new subscription is not already active...");
  return Caml_option.undefined_to_opt(subscriptions.find(function (subscription) {
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
    return await internalRetrieveSubscription(stripe, processedData, config.ref, customer);
  }
  
}

async function createHostedCheckoutSession(stripe, params) {
  var data = processData(params.data, params.config);
  var tierMetadataFields = [tierField];
  var productsByTier = {};
  var tierSchema = S$RescriptSchema.union(params.config.tiers.map(function (param) {
            var tierConfig = param[1];
            var id = param[0];
            return S$RescriptSchema.object(function (s) {
                        var products = [];
                        var tier = tierConfig({
                              metadata: (function (name, schema) {
                                  validateMetadataSchema(schema);
                                  tierMetadataFields.push(name);
                                  return s.f(name, schema);
                                }),
                              interval: (function () {
                                  return s.f("~~interval", S$RescriptSchema.$$enum([
                                                  "day",
                                                  "week",
                                                  "month",
                                                  "year"
                                                ]));
                                }),
                              product: (function (productConfig) {
                                  products.push(productConfig);
                                })
                            });
                        s.tag(tierField, id);
                        productsByTier[id] = products;
                        return tier;
                      });
          }));
  var rawTier = S$RescriptSchema.reverseConvertOrThrow(params.tier, tierSchema);
  var tierId = rawTier[tierField];
  var p = Js_dict.get(productsByTier, tierId);
  var products = p !== undefined ? (
      p.length !== 0 ? p : Js_exn.raiseError("Tier \"" + tierId + "\" doesn't have any products configured")
    ) : Js_exn.raiseError("Tier \"" + tierId + "\" is not configured on the subscription plan");
  var specificInterval = rawTier["~~interval"];
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
  var subscription = await internalRetrieveSubscription(stripe, data, params.config.ref, customer);
  if (subscription !== undefined) {
    Js_exn.raiseError("There's already an active \"" + subscription.id + "\" subscription for " + data.primaryFields.map(function (name) {
                return name + "=" + data.dict[name];
              }).join(", ") + " with the \"" + tierId + "\" tier. Either update the existing subscription or cancel it and create a new one");
  } else {
    console.log("Customer doesn't have an active \"" + params.config.ref + "\" subscription");
  }
  var productItems = await sync(stripe, {
        products: products
      });
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
              var lineItemPrice;
              var exit = 0;
              var len = prices.length;
              if (len !== 1) {
                if (len !== 0) {
                  exit = 1;
                } else {
                  lineItemPrice = Js_exn.raiseError("Product \"" + product.name + "\" doesn't have any prices");
                }
              } else {
                var price = prices[0];
                if (specificInterval !== undefined) {
                  exit = 1;
                } else {
                  lineItemPrice = price;
                }
              }
              if (exit === 1) {
                if (specificInterval !== undefined) {
                  var p = Belt_Array.reduce(prices, undefined, (function (acc, price) {
                          var match = price.recurring;
                          var isValid;
                          isValid = match === null ? true : match.interval === specificInterval;
                          if (acc !== undefined) {
                            if (isValid) {
                              return Js_exn.raiseError("Product \"" + product.name + "\" has multiple prices for the \"" + specificInterval + "\" interval billing");
                            } else {
                              return acc;
                            }
                          } else if (isValid) {
                            return price;
                          } else {
                            return acc;
                          }
                        }));
                  lineItemPrice = p !== undefined ? p : Js_exn.raiseError("Product \"" + product.name + "\" doesn't have a price for the \"" + specificInterval + "\" interval billing");
                } else {
                  lineItemPrice = Js_exn.raiseError("Product \"" + product.name + "\" have multiple prices but no interval specified. Use \"s.interval\" to dynamically choose which price use for the tier");
                }
              }
              var match = lineItemPrice.recurring;
              var id = lineItemPrice.id;
              if (match === null) {
                return {
                        price: id,
                        quantity: 1
                      };
              }
              var tmp = match.meter;
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
  retrieveCustomer: retrieveCustomer,
  retrieveSubscription: retrieveSubscription,
  createHostedCheckoutSession: createHostedCheckoutSession
};

export {
  Stdlib ,
  make ,
  Meter ,
  Price ,
  Product ,
  ProductCatalog ,
  Customer ,
  Subscription ,
  Checkout ,
  TieredSubscription ,
}
/* stripe Not a pure module */
