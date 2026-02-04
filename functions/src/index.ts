import { onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { defineSecret } from "firebase-functions/params";
import express from "express";

import { db } from "./config/firebase.config";
import { swaggerSpec } from "./config/swagger.config";
import { corsMiddleware } from "./middlewares/cors.middleware";
import { authMiddleware } from "./middlewares/auth.middleware";

import productsRoutes from "./routes/products.routes";
import purchasesRoutes from "./routes/purchases.routes";
import salesRoutes from "./routes/sales.routes";
import shipmentsRoutes from "./routes/shipments.routes";
import notificationsRoutes from "./routes/notifications.routes";
import statsRoutes from "./routes/stats.routes";
import profileRoutes from "./routes/profile.routes";

// Import docs (for swagger-jsdoc to pick up annotations)
import "./docs/products.docs";
import "./docs/purchases.docs";
import "./docs/sales.docs";
import "./docs/shipments.docs";
import "./docs/notifications.docs";
import "./docs/stats.docs";

import { FieldValue } from "firebase-admin/firestore";
import { mapMilestoneToAppStatus } from "./services/tracking.service";

// ── Secrets ───────────────────────────────────────
const SHIP24_API_KEY = defineSecret("SHIP24_API_KEY");
const SHIP24_WEBHOOK_SECRET = defineSecret("SHIP24_WEBHOOK_SECRET");
const CARDTRADER_API_TOKEN = defineSecret("CARDTRADER_API_TOKEN");
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

// ── Express App ───────────────────────────────────
const app = express();

// Middleware
app.use(corsMiddleware);
app.use(express.json());

// Swagger docs (no auth required)
const swaggerHtml = `<!DOCTYPE html>
<html><head>
  <title>Vault API Docs</title>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css">
</head><body>
  <div id="swagger-ui"></div>
  <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
  <script>
    // Detect base path dynamically
    const currentPath = window.location.pathname;
    const basePath = currentPath.replace(/\\/docs\\/?$/, '');
    SwaggerUIBundle({
      url: basePath + '/docs.json',
      dom_id: '#swagger-ui',
      presets: [SwaggerUIBundle.presets.apis, SwaggerUIBundle.SwaggerUIStandalonePreset],
      layout: 'BaseLayout',
    });
  </script>
</body></html>`;

app.get("/docs", (_req, res) => {
  res.setHeader("Content-Type", "text/html");
  res.send(swaggerHtml);
});
app.get("/docs.json", (_req, res) => {
  res.setHeader("Content-Type", "application/json");
  res.send(swaggerSpec);
});

// Health check (no auth required)
app.get("/health", (_req, res) => {
  res.json({ status: "ok", version: "2.0.0", timestamp: new Date().toISOString() });
});

// Auth middleware for all API routes
app.use(authMiddleware);

// Routes
app.use("/products", productsRoutes);
app.use("/purchases", purchasesRoutes);
app.use("/sales", salesRoutes);
app.use("/shipments", shipmentsRoutes);
app.use("/notifications", notificationsRoutes);
app.use("/stats", statsRoutes);
app.use("/profile", profileRoutes);

// 404 handler
app.use((_req, res) => {
  res.status(404).json({ error: "Not found" });
});

// ── Main API Export ───────────────────────────────
export const api = onRequest(
  {
    region: "europe-west1",
    secrets: [SHIP24_API_KEY],
  },
  app
);

// ── Ship24 Webhook (standalone, separate secrets) ─
// mapMilestoneToAppStatus is imported from tracking.service.ts
// to avoid duplication.

export const trackingWebhook = onRequest(
  {
    region: "europe-west1",
    secrets: [SHIP24_WEBHOOK_SECRET],
  },
  async (req, res) => {
    // CORS
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    try {
      // Verify webhook secret — reject requests with invalid secrets
      const webhookSecret = SHIP24_WEBHOOK_SECRET.value();
      const headerSecret =
        (req.headers["x-ship24-webhook-secret"] as string) ||
        (req.headers["x-webhook-secret"] as string) ||
        (req.headers["authorization"] as string)?.replace("Bearer ", "") ||
        "";

      if (webhookSecret && headerSecret !== webhookSecret) {
        console.warn(
          "Webhook secret mismatch — rejecting request. Expected:",
          webhookSecret.substring(0, 4) + "***",
          "got header keys:",
          Object.keys(req.headers)
            .filter((k) => k.startsWith("x-") || k === "authorization")
            .join(", ")
        );
        res.status(401).json({ error: "Unauthorized" });
        return;
      }

      const payload = req.body;
      const trackings = payload?.trackings || [];

      if (trackings.length === 0) {
        res.status(200).json({ status: "ok", message: "no trackings" });
        return;
      }

      for (const tracking of trackings) {
        const tracker = tracking.tracker || {};
        const shipment = tracking.shipment || {};
        const events = tracking.events || [];
        const trackingNumber = tracker.trackingNumber;

        if (!trackingNumber) continue;

        const appStatus = mapMilestoneToAppStatus(shipment.statusMilestone);

        // Build tracking history from events
        const trackingHistory = events.map((e: any) => ({
          status: e.status || "Unknown",
          statusCode: e.statusCode || null,
          statusMilestone: e.statusMilestone || null,
          timestamp: e.occurrenceDatetime || null,
          location: e.location || null,
          description: e.status || null,
          courierCode: e.courierCode || null,
        }));

        // Determine carrier from events or tracker
        const carrierCode =
          events.length > 0
            ? events[0].courierCode
            : tracker.courierCode?.[0] || null;

        // Search all users for this tracking number using collectionGroup
        // query instead of iterating every user document.
        // TODO: For scale, consider a top-level `trackingIndex` collection
        // mapping trackingCode → { userId, shipmentId }.
        const shipmentsSnap = await db
          .collectionGroup("shipments")
          .where("trackingCode", "==", trackingNumber)
          .limit(5)
          .get();

        for (const shipmentDoc of shipmentsSnap.docs) {
          // shipmentDoc.ref.parent is the "shipments" collection ref;
          // shipmentDoc.ref.parent.parent is the user document ref.
          const userDocRef = shipmentDoc.ref.parent.parent;
          if (!userDocRef) continue;

          const oldData = shipmentDoc.data();
          const oldStatus = oldData.status;

          // Update shipment
          await shipmentDoc.ref.update({
            status: appStatus,
            ship24Status: shipment.statusMilestone || "unknown",
            ship24StatusCode: shipment.statusCode || null,
            trackingApiStatus: shipment.statusMilestone || null,
            lastUpdate: FieldValue.serverTimestamp(),
            lastEvent: events.length > 0 ? events[0].status : null,
            trackingHistory: trackingHistory,
            carrier: carrierCode || oldData.carrier,
            externalTrackingUrl: `https://t.ship24.com/t/${trackingNumber}`,
            estimatedDelivery:
              shipment.delivery?.estimatedDeliveryDate || null,
            originCountry: shipment.originCountryCode || null,
            destinationCountry: shipment.destinationCountryCode || null,
          });

          // Create notification if status changed
          if (oldStatus !== appStatus) {
            const statusLabels: Record<string, string> = {
              pending: "In attesa",
              inTransit: "In transito",
              delivered: "Consegnato",
              exception: "Problema",
              unknown: "Sconosciuto",
            };

            await userDocRef.collection("notifications").add({
              type: "tracking_update",
              title: "Aggiornamento Spedizione",
              message: `${oldData.productName || trackingNumber}: ${statusLabels[appStatus] || appStatus}`,
              trackingCode: trackingNumber,
              shipmentId: shipmentDoc.id,
              oldStatus: oldStatus,
              newStatus: appStatus,
              statusMilestone: shipment.statusMilestone,
              read: false,
              createdAt: FieldValue.serverTimestamp(),
            });
          }

          console.log(
            `Updated shipment ${shipmentDoc.id} for ${trackingNumber}: ${oldStatus} → ${appStatus}`
          );
        }
      }

      res.status(200).json({ status: "ok" });
    } catch (error: any) {
      console.error("Webhook error:", error);
      res.status(200).json({ status: "error", message: error.message });
    }
  }
);

// ═══════════════════════════════════════════════════════
//  CardTrader — Constants & Helpers
// ═══════════════════════════════════════════════════════
const CT_API_BASE = "https://api.cardtrader.com/api/v2";
const RIFTBOUND_GAME_ID = 22;
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

async function ctFetch(path: string, token: string) {
  const res = await fetch(`${CT_API_BASE}${path}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`CardTrader API ${path} returned ${res.status}: ${text}`);
  }
  return res.json();
}

function sleep(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}

function setCors(res: any) {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
}

// Map CardTrader categoryId to our ProductKind
const CATEGORY_TO_KIND: Record<number, string> = {
  258: "singleCard",
  259: "boosterBox",
  260: "boosterPack",
  261: "bundle",
  262: "bundle",
  263: "display",
  283: "bundle",
  284: "singleCard",
};

// ═══════════════════════════════════════════════════════
//  imageProxy — CORS proxy for CardTrader images
// ═══════════════════════════════════════════════════════
export const imageProxy = onRequest(
  { region: "europe-west1", memory: "256MiB" },
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");
    if (req.method === "OPTIONS") { res.status(204).send(""); return; }

    const url = req.query.url as string;
    if (!url || !url.startsWith("https://www.cardtrader.com/")) {
      res.status(400).json({ error: "Invalid or missing url param" });
      return;
    }

    try {
      const response = await fetch(url);
      if (!response.ok) {
        res.status(response.status).send("Upstream error");
        return;
      }
      const buffer = Buffer.from(await response.arrayBuffer());
      const contentType = response.headers.get("content-type") || "image/jpeg";

      res.set("Content-Type", contentType);
      res.set("Cache-Control", "public, max-age=86400, s-maxage=86400");
      res.send(buffer);
    } catch (error: any) {
      console.error("imageProxy error:", error.message);
      res.status(500).json({ error: error.message });
    }
  }
);

// ═══════════════════════════════════════════════════════
//  syncRiftboundCatalog — Import all Riftbound cards
// ═══════════════════════════════════════════════════════
export const syncRiftboundCatalog = onRequest(
  { region: "europe-west1", secrets: [CARDTRADER_API_TOKEN], timeoutSeconds: 300, memory: "512MiB" },
  async (req, res) => {
    setCors(res);
    if (req.method === "OPTIONS") { res.status(204).send(""); return; }

    try {
      const token = CARDTRADER_API_TOKEN.value();

      // 1. Get all Riftbound expansions
      const allExpansions: any[] = await ctFetch("/expansions", token);
      const riftExpansions = allExpansions.filter((e: any) => e.game_id === RIFTBOUND_GAME_ID);
      console.log(`Found ${riftExpansions.length} Riftbound expansions`);

      // 2. Build expansion lookup
      const expMap: Record<number, { name: string; code: string }> = {};
      for (const exp of riftExpansions) {
        expMap[exp.id] = { name: exp.name, code: exp.code };
      }

      // 3. Fetch blueprints for each expansion
      let totalCards = 0;
      let batch = db.batch();
      let batchCount = 0;
      const BATCH_LIMIT = 490;

      const categoryNames: Record<number, string> = {
        258: "Single", 259: "Booster Box", 260: "Booster",
        261: "Bundle", 262: "Starter Deck", 263: "Box Set",
        283: "Complete Set", 284: "Oversized",
      };

      for (const exp of riftExpansions) {
        console.log(`Fetching blueprints for ${exp.name} (id: ${exp.id})...`);
        const blueprints: any[] = await ctFetch(`/blueprints/export?expansion_id=${exp.id}`, token);
        const items = blueprints.filter((b: any) => RIFTBOUND_CATALOG_CATEGORIES.has(b.category_id));
        console.log(`  → ${items.length} items in ${exp.name}`);

        for (const bp of items) {
          const docRef = db.collection("cardCatalog").doc(String(bp.id));
          let rawImageUrl: string | null = null;
          if (bp.image?.show?.url) {
            rawImageUrl = `https://www.cardtrader.com${bp.image.show.url}`;
          } else if (bp.image_url) {
            rawImageUrl = bp.image_url.replace("https://cardtrader.com", "https://www.cardtrader.com");
          }
          const imageUrl = rawImageUrl
            ? `https://europe-west1-inventorymanager-dev-20262.cloudfunctions.net/imageProxy?url=${encodeURIComponent(rawImageUrl)}`
            : null;

          batch.set(docRef, {
            blueprintId: bp.id,
            name: bp.name,
            version: bp.version || null,
            game: "riftbound",
            gameId: bp.game_id,
            categoryId: bp.category_id,
            categoryName: categoryNames[bp.category_id] || null,
            kind: CATEGORY_TO_KIND[bp.category_id] || "singleCard",
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

          if (batchCount >= BATCH_LIMIT) {
            await batch.commit();
            batch = db.batch();
            batchCount = 0;
          }
        }

        await sleep(200);
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      // 4. Store metadata
      await db.collection("cardCatalog").doc("_meta").set({
        game: "Riftbound",
        gameId: RIFTBOUND_GAME_ID,
        totalCards: totalCards,
        expansions: riftExpansions.map((e: any) => ({ id: e.id, name: e.name, code: e.code })),
        lastSync: FieldValue.serverTimestamp(),
      });

      console.log(`✅ Synced ${totalCards} Riftbound cards`);
      res.status(200).json({ success: true, totalCards, expansions: riftExpansions.length });
    } catch (error: any) {
      console.error("syncRiftboundCatalog error:", error);
      res.status(500).json({ error: error.message });
    }
  }
);

// ═══════════════════════════════════════════════════════
//  updateRiftboundPrices — Fetch market prices (hourly)
// ═══════════════════════════════════════════════════════
export const updateRiftboundPrices = onSchedule(
  {
    schedule: "every 1 hours",
    region: "europe-west1",
    secrets: [CARDTRADER_API_TOKEN],
    timeoutSeconds: 300,
    memory: "512MiB",
  },
  async () => {
    try {
      const token = CARDTRADER_API_TOKEN.value();
      const allExpansions: any[] = await ctFetch("/expansions", token);
      const riftExpansions = allExpansions.filter((e: any) => e.game_id === RIFTBOUND_GAME_ID);

      let updatedCount = 0;

      for (const exp of riftExpansions) {
        console.log(`Fetching prices for ${exp.name}...`);
        try {
          const products: Record<string, any[]> = await ctFetch(`/marketplace/products?expansion_id=${exp.id}`, token);
          const entries = Object.entries(products);
          console.log(`  → ${entries.length} blueprints with listings`);

          let batch = db.batch();
          let batchCount = 0;

          for (const [blueprintId, listings] of entries) {
            if (!Array.isArray(listings) || listings.length === 0) continue;
            const cheapest = listings[0];
            if (!cheapest?.price) continue;

            const docRef = db.collection("cardCatalog").doc(blueprintId);
            batch.set(docRef, {
              marketPrice: {
                cents: cheapest.price.cents,
                currency: cheapest.price.currency,
                formatted: cheapest.price.formatted || `€${(cheapest.price.cents / 100).toFixed(2)}`,
                sellersCount: listings.length,
                updatedAt: FieldValue.serverTimestamp(),
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
        } catch (expError: any) {
          console.error(`Error fetching prices for ${exp.name}:`, expError.message);
        }

        await sleep(1200);
      }

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
export const updateRiftboundPricesHttp = onRequest(
  { region: "europe-west1", secrets: [CARDTRADER_API_TOKEN], timeoutSeconds: 300, memory: "512MiB" },
  async (req, res) => {
    setCors(res);
    if (req.method === "OPTIONS") { res.status(204).send(""); return; }

    try {
      const token = CARDTRADER_API_TOKEN.value();
      const allExpansions: any[] = await ctFetch("/expansions", token);
      const riftExpansions = allExpansions.filter((e: any) => e.game_id === RIFTBOUND_GAME_ID);

      let updatedCount = 0;

      for (const exp of riftExpansions) {
        console.log(`Fetching prices for ${exp.name}...`);
        try {
          const products: Record<string, any[]> = await ctFetch(`/marketplace/products?expansion_id=${exp.id}`, token);
          const entries = Object.entries(products);

          let batch = db.batch();
          let batchCount = 0;

          for (const [blueprintId, listings] of entries) {
            if (!Array.isArray(listings) || listings.length === 0) continue;
            const cheapest = listings[0];
            if (!cheapest?.price) continue;

            const docRef = db.collection("cardCatalog").doc(blueprintId);
            batch.set(docRef, {
              marketPrice: {
                cents: cheapest.price.cents,
                currency: cheapest.price.currency,
                formatted: cheapest.price.formatted || `€${(cheapest.price.cents / 100).toFixed(2)}`,
                sellersCount: listings.length,
                updatedAt: FieldValue.serverTimestamp(),
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
        } catch (expError: any) {
          console.error(`Error fetching prices for ${exp.name}:`, expError.message);
        }

        await sleep(1200);
      }

      await db.collection("cardCatalog").doc("_meta").set({
        lastPriceUpdate: FieldValue.serverTimestamp(),
        lastPriceUpdateCount: updatedCount,
      }, { merge: true });

      console.log(`✅ Updated prices for ${updatedCount} cards`);
      res.status(200).json({ success: true, updatedCount });
    } catch (error: any) {
      console.error("updateRiftboundPricesHttp error:", error);
      res.status(500).json({ error: error.message });
    }
  }
);

// ═══════════════════════════════════════════════════════
//  scanCard — AI Vision card recognition via OpenAI
// ═══════════════════════════════════════════════════════
import OpenAI from "openai";

export const scanCard = onRequest(
  { region: "europe-west1", secrets: [OPENAI_API_KEY], timeoutSeconds: 30, memory: "256MiB" },
  async (req, res) => {
    setCors(res);
    if (req.method === "OPTIONS") { res.status(204).send(""); return; }
    if (req.method !== "POST") { res.status(405).json({ error: "POST only" }); return; }

    const { image } = req.body;
    if (!image || typeof image !== "string") {
      res.status(400).json({ error: "Missing 'image' (base64)" });
      return;
    }

    try {
      const openai = new OpenAI({ apiKey: OPENAI_API_KEY.value() });

      const imageUrl = image.startsWith("data:")
        ? image
        : `data:image/jpeg;base64,${image}`;

      const response = await openai.chat.completions.create({
        model: "gpt-5-mini",
        max_completion_tokens: 2048,
        messages: [
          {
            role: "system",
            content: "You are a trading card scanner. You identify collector numbers and card names from card images. Cards can be in ANY language (English, Chinese, Japanese, Korean, etc). Always reply in the exact format specified.",
          },
          {
            role: "user",
            content: [
              {
                type: "text",
                text: `Identify this trading card. Find:
1. The collector number (usually small text at the bottom, like "001/165", "SV049/SV100", "TG01", or just "042")
2. The card name (the main title of the card, in whatever language it's printed)

Reply in EXACTLY this format:
COLLECTOR_NUMBER|CARD_NAME

Examples:
001/165|Pikachu
SV049/SV100|リザードンex
042/165|喷火龙
TG01/TG30|Charizard

If you see NO trading card or cannot find a collector number, reply exactly: NONE`,
              },
              {
                type: "image_url",
                image_url: { url: imageUrl, detail: "high" },
              },
            ],
          },
        ],
      });

      const rawAnswer = response.choices[0]?.message?.content;
      console.log("scanCard raw response:", JSON.stringify(response.choices[0]?.message));
      const answer = (rawAnswer ?? "NONE").trim();

      if (!answer || answer === "NONE" || answer.toUpperCase() === "NONE") {
        res.status(200).json({ found: false });
        return;
      }

      const parts = answer.split("|");
      const fullNumber = parts[0].trim();
      const cardName = parts.length > 1 ? parts.slice(1).join("|").trim() : null;

      // Extract just the number part (before slash)
      const numberOnly = fullNumber.replace(/\s*[/\\].*$/, "").trim();

      res.status(200).json({
        found: true,
        collectorNumber: fullNumber,
        numberOnly,
        cardName,
      });
    } catch (error: any) {
      console.error("scanCard error:", error.message);
      res.status(500).json({ error: error.message });
    }
  }
);
