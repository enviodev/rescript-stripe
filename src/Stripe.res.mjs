// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Js_exn from "rescript/lib/es6/js_exn.js";
import Stripe from "stripe";
import * as Js_dict from "rescript/lib/es6/js_dict.js";
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

async function syncProduct(stripe, productConfig) {
  var configuredUnitLabel;
  var unsyncedPriceConfigs = {};
  for(var idx = 0 ,idx_finish = productConfig.prices.length; idx < idx_finish; ++idx){
    var priceConfig = productConfig.prices[idx];
    unsyncedPriceConfigs[priceConfig.lookupKey] = priceConfig;
    var match = priceConfig.recurring;
    if (match.TAG === "Metered") {
      var unitLabel = match.unitLabel;
      var anotherUnitLabel = configuredUnitLabel;
      if (anotherUnitLabel !== undefined) {
        Js_exn.raiseError("The product '" + productConfig.name + "' has two different unit labels: " + anotherUnitLabel + " and " + unitLabel + ". It's allowed to have only one unit label.");
      }
      configuredUnitLabel = unitLabel;
    }
    
  }
  var configuredUnitLabel$1 = configuredUnitLabel;
  if (Object.keys(unsyncedPriceConfigs).length !== productConfig.prices.length) {
    Js_exn.raiseError("The product '" + productConfig.name + "' has price configurations with duplicated lookup keys. It's allowed to have only unique lookup keys.");
  }
  console.log("Searching for active product \"" + productConfig.lookupKey + "\"...");
  var match$1 = await stripe.products.search({
        query: "active:\"true\" AND metadata[\"lookup_key\"]:\"" + productConfig.lookupKey + "\"",
        limit: 2
      });
  var match$2 = match$1.data;
  var len = match$2.length;
  var product;
  if (len !== 1) {
    if (len !== 0) {
      product = Js_exn.raiseError("There are multiple active products \"" + productConfig.lookupKey + "\". Please go to dashboard and delete not needed ones (https://dashboard.stripe.com/test/products?active=true)");
    } else {
      console.log("No active product \"" + productConfig.lookupKey + "\" found. Creating a new one...");
      var p = await stripe.products.create({
            name: productConfig.name,
            metadata: Js_dict.fromArray([[
                    "lookup_key",
                    productConfig.lookupKey
                  ]]),
            unit_label: configuredUnitLabel$1
          });
      console.log("Product \"" + productConfig.lookupKey + "\" successfully created. Product ID: " + p.id);
      product = p;
    }
  } else {
    var p$1 = match$2[0];
    console.log("Found an existing product \"" + productConfig.lookupKey + "\". Product ID: " + p$1.id);
    var fieldsToSync = {};
    var match$3 = p$1.unit_label;
    var exit = 0;
    if (match$3 === null) {
      if (configuredUnitLabel$1 !== undefined) {
        exit = 1;
      }
      
    } else if (!(configuredUnitLabel$1 !== undefined && match$3 === configuredUnitLabel$1)) {
      exit = 1;
    }
    if (exit === 1) {
      if (configuredUnitLabel$1 !== undefined) {
        fieldsToSync.unit_label = configuredUnitLabel$1;
      } else {
        fieldsToSync.unit_label = "";
      }
    }
    var fieldNamesToSync = Object.keys(fieldsToSync);
    if (fieldNamesToSync.length > 0) {
      console.log("Syncing product \"" + productConfig.lookupKey + "\" fields " + fieldNamesToSync.join(", ") + "...");
      var p$2 = await stripe.products.update(p$1.id, fieldsToSync);
      console.log("Product \"" + productConfig.lookupKey + "\" fields successfully updated");
      product = p$2;
    } else {
      console.log("Product \"" + productConfig.lookupKey + "\" is in sync");
      product = p$1;
    }
  }
  console.log("Searching for product \"" + productConfig.lookupKey + "\" active prices...");
  var prices = await stripe.prices.list({
        active: true,
        product: product.id
      });
  console.log("Found " + prices.data.length.toString() + " product \"" + productConfig.lookupKey + "\" active prices");
  if (prices.has_more) {
    Js_exn.raiseError("The pagination on prices is not supported yet. Product \"" + productConfig.lookupKey + "\" has to many active prices");
  }
  var createPriceFromConfig = function (priceConfig, transferLookupKey) {
    var match = priceConfig.recurring;
    var tmp;
    tmp = match.TAG === "Metered" ? ({
          interval: match.interval,
          usage_type: "metered"
        }) : ({
          interval: match.interval
        });
    return stripe.prices.create({
                currency: priceConfig.currency,
                product: product.id,
                recurring: tmp,
                unit_amount: priceConfig.unitAmountInCents,
                lookup_key: priceConfig.lookupKey,
                transfer_lookup_key: transferLookupKey
              });
  };
  var priceUpdatePromises = prices.data.map(async function (price) {
        var lookupKey = price.lookup_key;
        var maybePriceConfig;
        maybePriceConfig = lookupKey === null ? undefined : Js_dict.get(unsyncedPriceConfigs, lookupKey);
        if (maybePriceConfig !== undefined) {
          unsafeDeleteKey(unsyncedPriceConfigs, maybePriceConfig.lookupKey);
          console.log("Found an existing price \"" + maybePriceConfig.lookupKey + "\". Price ID: " + price.id);
          var isPriceInSync = maybePriceConfig.currency === price.currency && maybePriceConfig.unitAmountInCents === price.unit_amount;
          if (isPriceInSync) {
            console.log("Price \"" + maybePriceConfig.lookupKey + "\" is in sync");
            return ;
          }
          console.log("Price \"" + maybePriceConfig.lookupKey + "\" is not in sync. Updating...");
          var match = await Promise.all([
                createPriceFromConfig(maybePriceConfig, true),
                stripe.prices.update(price.id, {
                      active: false
                    })
              ]);
          console.log("Price \"" + maybePriceConfig.lookupKey + "\" successfully recreated with the new values. New Price ID: " + match[0].id + ". Old Price ID: " + price.id);
          return ;
        }
        console.log("Price " + price.id + " with lookupKey " + price.lookup_key + " is not configured on product " + productConfig.lookupKey + ". Setting it to inactive...");
        await stripe.prices.update(price.id, {
              active: false
            });
        console.log("Price " + price.id + " successfully set to inactive");
      });
  var priceCreatePromises = Js_dict.values(unsyncedPriceConfigs).map(async function (priceConfig) {
        console.log("Price \"" + priceConfig.lookupKey + "\" is missing on product \"" + productConfig.lookupKey + "\"\". Creating it...");
        var price = await createPriceFromConfig(priceConfig, undefined);
        console.log("Price \"" + priceConfig.lookupKey + "\" successfully created. Price ID: " + price.id);
      });
  await Promise.all(priceUpdatePromises.concat(priceCreatePromises));
  console.log("Successfully finished syncing product catalog");
}

function sync(stripe, productCatalog) {
  Promise.all(productCatalog.products.map(function (p) {
            return syncProduct(stripe, p);
          }));
}

var ProductCatalog = {
  syncProduct: syncProduct,
  sync: sync
};

export {
  Stdlib ,
  make ,
  Meter ,
  Price ,
  Product ,
  ProductCatalog ,
}
/* stripe Not a pure module */
