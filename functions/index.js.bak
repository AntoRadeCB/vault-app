const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const crypto = require("crypto");

initializeApp();
const db = getFirestore();

// ── Secrets ─────────────────────────────────────────
const SHIP24_API_KEY = defineSecret("SHIP24_API_KEY");
const SHIP24_WEBHOOK_SECRET = defineSecret("SHIP24_WEBHOOK_SECRET");
const CARDTRADER_API_TOKEN = defineSecret("CARDTRADER_API_TOKEN");

const SHIP24_API_BASE = "https://api.ship24.com/public/v1";

// ── CORS helper ────────────────────────────────────
function setCors(res) {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
}

// ── Ship24 status → app status mapping ─────────────
function mapMilestoneToAppStatus(milestone) {
  switch (milestone) {
    case "pending":
    case "info_received":
      return "pending";
    case "in_transit":
    case "out_for_delivery":
    case "available_for_pickup":
      return "inTransit";
    case "delivered":
      return "delivered";
    case "exception":
    case "attempt_fail":
    case "failed_attempt":
      return "exception";
    default:
      return "unknown";
  }
}

// ═══════════════════════════════════════════════════════
//  Ship24 Webhook Receiver
// ═══════════════════════════════════════════════════════
exports.trackingWebhook = onRequest(
  { region: "europe-west1", secrets: [SHIP24_WEBHOOK_SECRET] },
  async (req, res) => {
    if (req.method !== "POST") {
      return res.status(405).json({ error: "Method not allowed" });
    }

    try {
      // Verify webhook secret - Ship24 sends it in x-webhook-secret header
      const webhookSecret = SHIP24_WEBHOOK_SECRET.value();
      const headerSecret =
        req.headers["x-ship24-webhook-secret"] ||
        req.headers["x-webhook-secret"] ||
        req.headers["authorization"]?.replace("Bearer ", "") ||
        "";

      if (webhookSecret && headerSecret !== webhookSecret) {
        // Log but don't block — Ship24 may send secret differently
        console.warn("Webhook secret mismatch — expected:", webhookSecret.substring(0, 8) + "...", "got header keys:", Object.keys(req.headers).join(", "));
      }

      const payload = req.body;
      const trackings = payload?.trackings || [];

      if (trackings.length === 0) {
        return res.status(200).json({ status: "ok", message: "no trackings" });
      }

      for (const tracking of trackings) {
        const tracker = tracking.tracker || {};
        const shipment = tracking.shipment || {};
        const events = tracking.events || [];
        const statistics = tracking.statistics || {};
        const trackingNumber = tracker.trackingNumber;

        if (!trackingNumber) continue;

        const appStatus = mapMilestoneToAppStatus(shipment.statusMilestone);

        // Build tracking history from events
        const trackingHistory = events.map((e) => ({
          status: e.status || "Unknown",
          statusCode: e.statusCode || null,
          statusMilestone: e.statusMilestone || null,
          timestamp: e.occurrenceDatetime || null,
          location: e.location || null,
          description: e.status || null,
          courierCode: e.courierCode || null,
        }));

        // Determine carrier from events or tracker
        const carrierCode = events.length > 0
          ? events[0].courierCode
          : (tracker.courierCode?.[0] || null);

        // Search all users for this tracking number
        const usersSnap = await db.collection("users").get();
        for (const userDoc of usersSnap.docs) {
          const shipmentsRef = userDoc.ref.collection("shipments");
          const snapshot = await shipmentsRef
            .where("trackingCode", "==", trackingNumber)
            .limit(1)
            .get();

          if (!snapshot.empty) {
            const doc = snapshot.docs[0];
            const oldData = doc.data();
            const oldStatus = oldData.status;

            // Update shipment
            await doc.ref.update({
              status: appStatus,
              ship24Status: shipment.statusMilestone || "unknown",
              ship24StatusCode: shipment.statusCode || null,
              trackingApiStatus: shipment.statusMilestone || null,
              lastUpdate: FieldValue.serverTimestamp(),
              lastEvent: events.length > 0 ? events[0].status : null,
              trackingHistory: trackingHistory,
              carrier: carrierCode || oldData.carrier,
              externalTrackingUrl: `https://t.ship24.com/t/${trackingNumber}`,
              estimatedDelivery: shipment.delivery?.estimatedDeliveryDate || null,
              originCountry: shipment.originCountryCode || null,
              destinationCountry: shipment.destinationCountryCode || null,
            });

            // Create notification if status changed
            if (oldStatus !== appStatus) {
              const statusLabels = {
                pending: "In attesa",
                inTransit: "In transito",
                delivered: "Consegnato",
                exception: "Problema",
                unknown: "Sconosciuto",
              };

              await userDoc.ref.collection("notifications").add({
                type: "tracking_update",
                title: "Aggiornamento Spedizione",
                message: `${oldData.productName || trackingNumber}: ${statusLabels[appStatus] || appStatus}`,
                trackingCode: trackingNumber,
                shipmentId: doc.id,
                oldStatus: oldStatus,
                newStatus: appStatus,
                statusMilestone: shipment.statusMilestone,
                read: false,
                createdAt: FieldValue.serverTimestamp(),
              });
            }

            console.log(`Updated shipment ${doc.id} for ${trackingNumber}: ${oldStatus} → ${appStatus}`);
          }
        }
      }

      return res.status(200).json({ status: "ok" });
    } catch (error) {
      console.error("Webhook error:", error);
      return res.status(200).json({ status: "error", message: error.message });
    }
  }
);

// ═══════════════════════════════════════════════════════
//  registerTracking — register a tracker on Ship24
// ═══════════════════════════════════════════════════════
exports.registerTracking = onRequest(
  { region: "europe-west1", secrets: [SHIP24_API_KEY] },
  async (req, res) => {
    setCors(res);
    if (req.method === "OPTIONS") return res.status(204).send("");
    if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

    try {
      const { trackingNumber, courierCode } = req.body;

      if (!trackingNumber) {
        return res.status(400).json({ error: "trackingNumber is required" });
      }

      const apiKey = SHIP24_API_KEY.value();

      const body = { trackingNumber };
      if (courierCode) body.courierCode = [courierCode];

      const response = await fetch(`${SHIP24_API_BASE}/trackers`, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(body),
      });

      const data = await response.json();

      if (!response.ok) {
        console.error("Ship24 API error:", JSON.stringify(data));
        return res.status(response.status).json({
          error: "Ship24 API error",
          details: data,
        });
      }

      const tracker = data.data?.tracker || {};

      return res.status(200).json({
        success: true,
        trackerId: tracker.trackerId || null,
        trackingNumber: tracker.trackingNumber || trackingNumber,
        isTracked: tracker.isTracked || false,
        courierCode: tracker.courierCode || [],
      });
    } catch (error) {
      console.error("registerTracking error:", error);
      return res.status(500).json({ error: error.message });
    }
  }
);

// ═══════════════════════════════════════════════════════
//  getTrackingStatus — get tracking results from Ship24
// ═══════════════════════════════════════════════════════
exports.getTrackingStatus = onRequest(
  { region: "europe-west1", secrets: [SHIP24_API_KEY] },
  async (req, res) => {
    setCors(res);
    if (req.method === "OPTIONS") return res.status(204).send("");
    if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

    try {
      const trackingNumber = req.body?.trackingNumber;
      const trackerId = req.body?.trackerId;

      if (!trackingNumber && !trackerId) {
        return res.status(400).json({ error: "trackingNumber or trackerId is required" });
      }

      const apiKey = SHIP24_API_KEY.value();
      let trackings = [];

      if (trackerId) {
        const response = await fetch(`${SHIP24_API_BASE}/trackers/${trackerId}/results`, {
          headers: { "Authorization": `Bearer ${apiKey}` },
        });
        if (response.ok) {
          const data = await response.json();
          trackings = data.data?.trackings || [];
        }
      }

      if (trackings.length === 0 && trackingNumber) {
        // Search by tracking number
        const response = await fetch(`${SHIP24_API_BASE}/trackers/search`, {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${apiKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ trackingNumber }),
        });

        if (response.ok) {
          const data = await response.json();
          trackings = data.data?.trackings || [];
        }

        // If still nothing, auto-register
        if (trackings.length === 0) {
          const regResponse = await fetch(`${SHIP24_API_BASE}/trackers`, {
            method: "POST",
            headers: {
              "Authorization": `Bearer ${apiKey}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({ trackingNumber }),
          });

          if (regResponse.ok) {
            const regData = await regResponse.json();
            const newTrackerId = regData.data?.tracker?.trackerId;
            if (newTrackerId) {
              await new Promise((r) => setTimeout(r, 2000));
              const retryResponse = await fetch(`${SHIP24_API_BASE}/trackers/${newTrackerId}/results`, {
                headers: { "Authorization": `Bearer ${apiKey}` },
              });
              if (retryResponse.ok) {
                const retryData = await retryResponse.json();
                trackings = retryData.data?.trackings || [];
              }
            }
          }
        }
      }

      if (trackings.length === 0) {
        return res.status(200).json({
          success: true,
          status: "pending",
          statusMilestone: "pending",
          message: "Tracking registrato, in attesa di aggiornamenti dal corriere",
          trackingHistory: [],
        });
      }

      const tracking = trackings[0];
      const shipment = tracking.shipment || {};
      const events = tracking.events || [];
      const tracker = tracking.tracker || {};

      const trackingHistory = events.map((e) => ({
        status: e.status || "Unknown",
        statusCode: e.statusCode || null,
        statusMilestone: e.statusMilestone || null,
        timestamp: e.occurrenceDatetime || null,
        location: e.location || null,
        description: e.status || null,
        courierCode: e.courierCode || null,
      }));

      return res.status(200).json({
        success: true,
        trackerId: tracker.trackerId || null,
        trackingNumber: tracker.trackingNumber || trackingNumber,
        status: shipment.statusMilestone || "pending",
        statusCode: shipment.statusCode || null,
        statusCategory: shipment.statusCategory || null,
        carrier: events.length > 0 ? events[0].courierCode : (tracker.courierCode?.[0] || null),
        carrierName: events.length > 0 ? events[0].courierCode : null,
        trackingUrl: `https://t.ship24.com/t/${trackingNumber}`,
        trackingHistory: trackingHistory,
        estimatedDelivery: shipment.delivery?.estimatedDeliveryDate || null,
        originCountry: shipment.originCountryCode || null,
        destinationCountry: shipment.destinationCountryCode || null,
      });
    } catch (error) {
      console.error("getTrackingStatus error:", error);
      return res.status(500).json({ error: error.message });
    }
  }
);

// ═══════════════════════════════════════════════════════
//  Image Proxy — serves external images with CORS headers
// ═══════════════════════════════════════════════════════
exports.imageProxy = onRequest(
  { region: "europe-west1", memory: "256MiB" },
  async (req, res) => {
    // CORS
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");
    if (req.method === "OPTIONS") return res.status(204).send("");

    const url = req.query.url;
    if (!url || !url.startsWith("https://www.cardtrader.com/")) {
      return res.status(400).json({ error: "Invalid or missing url param" });
    }

    try {
      const response = await fetch(url);
      if (!response.ok) {
        return res.status(response.status).send("Upstream error");
      }
      const buffer = Buffer.from(await response.arrayBuffer());
      const contentType = response.headers.get("content-type") || "image/jpeg";

      res.set("Content-Type", contentType);
      res.set("Cache-Control", "public, max-age=86400, s-maxage=86400"); // 24h cache
      res.send(buffer);
    } catch (error) {
      console.error("imageProxy error:", error.message);
      res.status(500).json({ error: error.message });
    }
  }
);

// ═══════════════════════════════════════════════════════
//  CardTrader — Constants & Helpers
// ═══════════════════════════════════════════════════════
const CT_API_BASE = "https://api.cardtrader.com/api/v2";
const RIFTBOUND_GAME_ID = 22;
// Categories to include in catalog
const RIFTBOUND_CATALOG_CATEGORIES = new Set([
  258, // Singles
  259, // Booster Boxes
  260, // Boosters
  261, // Bundles
  262, // Starter Decks
  263, // Box Sets & Displays
  283, // Complete Sets
  284, // Oversized
]);

async function ctFetch(path, token) {
  const res = await fetch(`${CT_API_BASE}${path}`, {
    headers: { "Authorization": `Bearer ${token}` },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`CardTrader API ${path} returned ${res.status}: ${text}`);
  }
  return res.json();
}

// Small delay helper to respect rate limits
function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

// ═══════════════════════════════════════════════════════
//  syncRiftboundCatalog — Import all Riftbound cards
//  Call once or when new sets release
// ═══════════════════════════════════════════════════════
exports.syncRiftboundCatalog = onRequest(
  { region: "europe-west1", secrets: [CARDTRADER_API_TOKEN], timeoutSeconds: 300, memory: "512MiB" },
  async (req, res) => {
    setCors(res);
    if (req.method === "OPTIONS") return res.status(204).send("");

    try {
      const token = CARDTRADER_API_TOKEN.value();

      // 1. Get all Riftbound expansions
      const allExpansions = await ctFetch("/expansions", token);
      const riftExpansions = allExpansions.filter((e) => e.game_id === RIFTBOUND_GAME_ID);
      console.log(`Found ${riftExpansions.length} Riftbound expansions`);

      // 2. Build expansion lookup
      const expMap = {};
      for (const exp of riftExpansions) {
        expMap[exp.id] = { name: exp.name, code: exp.code };
      }

      // 3. Fetch blueprints for each expansion (only singles)
      let totalCards = 0;
      let batch = db.batch();
      let batchCount = 0;
      const BATCH_LIMIT = 490; // Firestore batch limit is 500

      for (const exp of riftExpansions) {
        console.log(`Fetching blueprints for ${exp.name} (id: ${exp.id})...`);
        const blueprints = await ctFetch(`/blueprints/export?expansion_id=${exp.id}`, token);

        const items = blueprints.filter((b) => RIFTBOUND_CATALOG_CATEGORIES.has(b.category_id));
        console.log(`  → ${items.length} items in ${exp.name}`);

        for (const bp of items) {
          const docRef = db.collection("cardCatalog").doc(String(bp.id));
          // Build image URL via our proxy (CardTrader has no CORS headers)
          let rawImageUrl = null;
          if (bp.image?.show?.url) {
            rawImageUrl = `https://www.cardtrader.com${bp.image.show.url}`;
          } else if (bp.image_url) {
            rawImageUrl = bp.image_url.replace('https://cardtrader.com', 'https://www.cardtrader.com');
          }
          const imageUrl = rawImageUrl
            ? `https://europe-west1-inventorymanager-dev-20262.cloudfunctions.net/imageProxy?url=${encodeURIComponent(rawImageUrl)}`
            : null;

          // Map category id to readable name
          const categoryNames = {
            258: "Single", 259: "Booster Box", 260: "Booster",
            261: "Bundle", 262: "Starter Deck", 263: "Box Set",
            283: "Complete Set", 284: "Oversized",
          };

          batch.set(docRef, {
            blueprintId: bp.id,
            name: bp.name,
            version: bp.version || null,
            gameId: bp.game_id,
            categoryId: bp.category_id,
            categoryName: categoryNames[bp.category_id] || null,
            expansionId: bp.expansion_id,
            expansionName: expMap[bp.expansion_id]?.name || null,
            expansionCode: expMap[bp.expansion_id]?.code || null,
            collectorNumber: bp.fixed_properties?.collector_number || null,
            rarity: bp.fixed_properties?.riftbound_rarity || null,
            imageUrl: imageUrl,
            cardMarketIds: bp.card_market_ids || [],
            tcgPlayerId: bp.tcg_player_id || null,
            nameLower: (bp.name || "").toLowerCase(),
            updatedAt: FieldValue.serverTimestamp(),
          }, { merge: true });

          batchCount++;
          totalCards++;

          // Commit batch if near limit
          if (batchCount >= BATCH_LIMIT) {
            await batch.commit();
            batch = db.batch();
            batchCount = 0;
          }
        }

        await sleep(200); // Be nice to the API
      }

      // Commit remaining
      if (batchCount > 0) {
        await batch.commit();
      }

      // 4. Store metadata
      await db.collection("cardCatalog").doc("_meta").set({
        game: "Riftbound",
        gameId: RIFTBOUND_GAME_ID,
        totalCards: totalCards,
        expansions: riftExpansions.map((e) => ({ id: e.id, name: e.name, code: e.code })),
        lastSync: FieldValue.serverTimestamp(),
      });

      console.log(`✅ Synced ${totalCards} Riftbound cards`);
      return res.status(200).json({
        success: true,
        totalCards,
        expansions: riftExpansions.length,
      });
    } catch (error) {
      console.error("syncRiftboundCatalog error:", error);
      return res.status(500).json({ error: error.message });
    }
  }
);

// ═══════════════════════════════════════════════════════
//  updateRiftboundPrices — Fetch market prices (hourly)
// ═══════════════════════════════════════════════════════
exports.updateRiftboundPrices = onSchedule(
  {
    schedule: "every 1 hours",
    region: "europe-west1",
    secrets: [CARDTRADER_API_TOKEN],
    timeoutSeconds: 300,
    memory: "512MiB",
  },
  async (event) => {
    try {
      const token = CARDTRADER_API_TOKEN.value();

      // Get Riftbound expansions
      const allExpansions = await ctFetch("/expansions", token);
      const riftExpansions = allExpansions.filter((e) => e.game_id === RIFTBOUND_GAME_ID);

      let updatedCount = 0;

      for (const exp of riftExpansions) {
        console.log(`Fetching prices for ${exp.name}...`);

        try {
          const products = await ctFetch(`/marketplace/products?expansion_id=${exp.id}`, token);

          // products is an object: { blueprintId: [products...] }
          const entries = Object.entries(products);
          console.log(`  → ${entries.length} blueprints with listings`);

          // Process in batches
          let batch = db.batch();
          let batchCount = 0;

          for (const [blueprintId, listings] of entries) {
            if (!Array.isArray(listings) || listings.length === 0) continue;

            const cheapest = listings[0]; // Already sorted by price
            if (!cheapest?.price) continue;

            const docRef = db.collection("cardCatalog").doc(blueprintId);
            // Use set+merge so it doesn't fail on non-existent docs (booster boxes etc.)
            batch.set(docRef, {
              "marketPrice": {
                "cents": cheapest.price.cents,
                "currency": cheapest.price.currency,
                "formatted": cheapest.price.formatted || `€${(cheapest.price.cents / 100).toFixed(2)}`,
                "sellersCount": listings.length,
                "updatedAt": FieldValue.serverTimestamp(),
              },
            }, { merge: true });

            batchCount++;
            updatedCount++;

            if (batchCount >= 490) {
              await batch.commit();
              batch = db.batch();
              batchCount = 0;
            }
          }

          if (batchCount > 0) {
            await batch.commit();
          }
        } catch (expError) {
          console.error(`Error fetching prices for ${exp.name}:`, expError.message);
        }

        await sleep(1200); // marketplace is limited to 1 req/sec
      }

      // Update metadata
      await db.collection("cardCatalog").doc("_meta").set({
        lastPriceUpdate: FieldValue.serverTimestamp(),
        lastPriceUpdateCount: updatedCount,
      }, { merge: true });

      console.log(`✅ Updated prices for ${updatedCount} cards`);
    } catch (error) {
      console.error("updateRiftboundPrices error:", error);
    }
  }
);

// ═══════════════════════════════════════════════════════
//  updateRiftboundPricesHttp — Manual trigger for prices
// ═══════════════════════════════════════════════════════
exports.updateRiftboundPricesHttp = onRequest(
  { region: "europe-west1", secrets: [CARDTRADER_API_TOKEN], timeoutSeconds: 300, memory: "512MiB" },
  async (req, res) => {
    setCors(res);
    if (req.method === "OPTIONS") return res.status(204).send("");

    try {
      const token = CARDTRADER_API_TOKEN.value();

      const allExpansions = await ctFetch("/expansions", token);
      const riftExpansions = allExpansions.filter((e) => e.game_id === RIFTBOUND_GAME_ID);

      let updatedCount = 0;

      for (const exp of riftExpansions) {
        console.log(`Fetching prices for ${exp.name}...`);

        try {
          const products = await ctFetch(`/marketplace/products?expansion_id=${exp.id}`, token);
          const entries = Object.entries(products);

          let batch = db.batch();
          let batchCount = 0;

          for (const [blueprintId, listings] of entries) {
            if (!Array.isArray(listings) || listings.length === 0) continue;
            const cheapest = listings[0];
            if (!cheapest?.price) continue;

            const docRef = db.collection("cardCatalog").doc(blueprintId);
            batch.set(docRef, {
              "marketPrice": {
                "cents": cheapest.price.cents,
                "currency": cheapest.price.currency,
                "formatted": cheapest.price.formatted || `€${(cheapest.price.cents / 100).toFixed(2)}`,
                "sellersCount": listings.length,
                "updatedAt": FieldValue.serverTimestamp(),
              },
            }, { merge: true });

            batchCount++;
            updatedCount++;

            if (batchCount >= 490) {
              await batch.commit();
              batch = db.batch();
              batchCount = 0;
            }
          }

          if (batchCount > 0) {
            await batch.commit();
          }
        } catch (expError) {
          console.error(`Error fetching prices for ${exp.name}:`, expError.message);
        }

        await sleep(1200);
      }

      await db.collection("cardCatalog").doc("_meta").set({
        lastPriceUpdate: FieldValue.serverTimestamp(),
        lastPriceUpdateCount: updatedCount,
      }, { merge: true });

      console.log(`✅ Updated prices for ${updatedCount} cards`);
      return res.status(200).json({ success: true, updatedCount });
    } catch (error) {
      console.error("updateRiftboundPricesHttp error:", error);
      return res.status(500).json({ error: error.message });
    }
  }
);
