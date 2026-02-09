import { onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
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
import ebayRoutes from "./routes/ebay.routes";
import * as ebayController from "./controllers/ebay.controller";
import { EBAY_CLIENT_ID, EBAY_CLIENT_SECRET, EBAY_REDIRECT_URI } from "./config/ebay.config";

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
app.use("/ebay", ebayRoutes);

// 404 handler
app.use((_req, res) => {
  res.status(404).json({ error: "Not found" });
});

// ── Main API Export ───────────────────────────────
export const api = onRequest(
  {
    region: "europe-west1",
    
  },
  app
);

// ── eBay Webhook (standalone, no auth) ─
export const ebayWebhook = onRequest(
  {
    region: "europe-west1",
    
  },
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    await ebayController.handleWebhook(req as any, res as any);
  }
);

// ── Ship24 Webhook (standalone, separate secrets) ─
// mapMilestoneToAppStatus is imported from tracking.service.ts
// to avoid duplication.

export const trackingWebhook = onRequest(
  {
    region: "europe-west1",
    
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
      const webhookSecret = process.env.SHIP24_WEBHOOK_SECRET || "";
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
  { region: "europe-west1",  timeoutSeconds: 300, memory: "512MiB" },
  async (req, res) => {
    setCors(res);
    if (req.method === "OPTIONS") { res.status(204).send(""); return; }

    try {
      const token = process.env.CARDTRADER_API_TOKEN || "";

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

          // Back image URL (for double-faced cards)
          let backImageUrl: string | null = null;
          if (bp.back_image?.show?.url && !bp.back_image.show.url.includes("fallbacks/")) {
            const rawBack = `https://www.cardtrader.com${bp.back_image.show.url}`;
            backImageUrl = `https://europe-west1-inventorymanager-dev-20262.cloudfunctions.net/imageProxy?url=${encodeURIComponent(rawBack)}`;
          }

          // Extract available languages from editable_properties
          const langProp = (bp.editable_properties || []).find((p: any) => p.name === "riftbound_language");
          const availableLanguages: string[] = langProp?.possible_values || [];

          // Check if foil variant exists
          const foilProp = (bp.editable_properties || []).find((p: any) => p.name === "riftbound_foil");
          const hasFoil = foilProp ? true : false;

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
            backImageUrl: backImageUrl,
            cardMarketIds: bp.card_market_ids || [],
            tcgPlayerId: bp.tcg_player_id || null,
            availableLanguages: availableLanguages,
            hasFoil: hasFoil,
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
    
    timeoutSeconds: 300,
    memory: "512MiB",
  },
  async () => {
    try {
      const token = process.env.CARDTRADER_API_TOKEN || "";
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
  { region: "europe-west1",  timeoutSeconds: 300, memory: "512MiB" },
  async (req, res) => {
    setCors(res);
    if (req.method === "OPTIONS") { res.status(204).send(""); return; }

    try {
      const token = process.env.CARDTRADER_API_TOKEN || "";
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
  { region: "europe-west1",  timeoutSeconds: 30, memory: "256MiB" },
  async (req, res) => {
    setCors(res);
    if (req.method === "OPTIONS") { res.status(204).send(""); return; }
    if (req.method !== "POST") { res.status(405).json({ error: "POST only" }); return; }

    const { image, expansion, cards } = req.body;
    if (!image || typeof image !== "string") {
      res.status(400).json({ error: "Missing 'image' (base64)" });
      return;
    }

    try {
      const imageSize = image.length;
      const hasContext = !!(expansion || cards);
      console.log(`scanCard v6: image=${imageSize} chars, expansion=${expansion || 'none'}, cards=${cards?.length || 0}`);

      const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY || "" });

      const imageUrl = image.startsWith("data:")
        ? image
        : `data:image/jpeg;base64,${image}`;

      // ── Build system prompt for single-card identification ──
      let systemPrompt = `You are a Riftbound (League of Legends TCG) card identification expert.
Your job: identify the ONE trading card shown in the photo with 100% accuracy.

STEP-BY-STEP PROCESS:
1. Read the COLLECTOR NUMBER printed on the card. This is the MOST RELIABLE identifier.
   - Located at bottom-left or bottom-right of the card
   - Format: "025/240", "025", "007a", "301"
   - Alternate Art variants have suffix "a" (e.g. "007a", "027a")
   - Showcase variants have high numbers (246+, 301+)
2. Match the collector number to the reference list.
3. Verify: does the card name, champion, and artwork match what you see?
4. Cards exist in English, Simplified Chinese (zh-CN), and French — text may be in any language, but ALWAYS return the ENGLISH name.
5. If NOT confident, reply NONE rather than guess wrong.`;

      let userPrompt = `Identify the Riftbound trading card in this photo.`;

      if (expansion) {
        userPrompt += `\nExpansion: "${expansion}".`;
      }

      if (cards && Array.isArray(cards) && cards.length > 0) {
        userPrompt += `\n\nREFERENCE LIST (COLLECTOR_NUMBER|NAME or ...NAME|RARITY or ...NAME|RARITY|VERSION):`;
        userPrompt += `\n${cards.join('\n')}`;
        userPrompt += `\n\nSTEPS:`;
        userPrompt += `\n1. Read the collector number printed on the card`;
        userPrompt += `\n2. Find the matching entry in the list by collector number`;
        userPrompt += `\n3. Verify the card name/artwork matches`;
        userPrompt += `\n4. If collector number is unreadable, use champion name + artwork to find the best match`;
      }

      userPrompt += `\n\nOUTPUT — exactly one line, nothing else:
COLLECTOR_NUMBER|CARD_NAME_EN

Example: 025|Jinx - Demolitionist

If you cannot identify the card, reply exactly: NONE`;

      const response = await openai.chat.completions.create({
        model: "gpt-5.2",
        max_completion_tokens: 256,
        messages: [
          {
            role: "system",
            content: systemPrompt,
          },
          {
            role: "user",
            content: [
              {
                type: "text",
                text: userPrompt,
              },
              {
                type: "image_url",
                image_url: { url: imageUrl, detail: "high" },
              },
            ],
          },
        ],
      });

      console.log("scanCard v6 response:", JSON.stringify({
        content: response.choices[0]?.message?.content,
        finish: response.choices[0]?.finish_reason,
        usage: response.usage,
        model: response.model,
      }));
      const rawAnswer = response.choices[0]?.message?.content;
      const answer = (rawAnswer ?? "NONE").trim();

      if (!answer || answer === "NONE" || answer.toUpperCase() === "NONE") {
        res.status(200).json({ found: false, cards: [] });
        return;
      }

      // Parse response: COLLECTOR_NUMBER|CARD_NAME or CARD_NAME|EXTRA_INFO
      const lines = answer.split("\n").map((l: string) => l.trim()).filter((l: string) => l && l !== "NONE");
      const parsedCards: Array<{ cardName: string; extraInfo: string | null }> = [];

      for (const line of lines) {
        const parts = line.split("|");
        const cardName = parts[0].trim();
        if (!cardName || cardName === "NONE") continue;
        const extraInfo = parts.length > 1 ? parts.slice(1).join("|").trim() : null;
        parsedCards.push({ cardName, extraInfo });
      }

      if (parsedCards.length === 0) {
        res.status(200).json({ found: false, cards: [] });
        return;
      }

      // Return full response with collector number info
      // cardName field = first part (could be collector num or name)
      // extraInfo = second part (name or extra info)
      const firstCard = parsedCards[0];
      res.status(200).json({
        found: true,
        cardName: firstCard.extraInfo || firstCard.cardName, // name (second part if available)
        extraInfo: firstCard.extraInfo ? firstCard.cardName : null, // collector num (first part)
        fullResponse: answer,
        cards: parsedCards,
      });
    } catch (error: any) {
      console.error("scanCard error:", error.message);
      res.status(500).json({ error: error.message });
    }
  }
);

// ═══════════════════════════════════════════════════════
//  scanCardOcr — Free tier OCR via Gemini Flash (Vertex AI)
// ═══════════════════════════════════════════════════════
import { VertexAI } from "@google-cloud/vertexai";

export const scanCardOcr = onRequest(
  { region: "europe-west1", timeoutSeconds: 20, memory: "256MiB" },
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
      const imageSize = image.length;
      console.log(`scanCardOcr: image=${imageSize} chars`);

      const vertexAi = new VertexAI({
        project: "inventorymanager-dev-20262",
        location: "us-central1",
      });

      const model = vertexAi.getGenerativeModel({
        model: "gemini-2.5-flash-lite",
        generationConfig: { maxOutputTokens: 128, temperature: 0.1 },
      });

      // Strip data URI prefix if present, get raw base64
      const base64Data = image.replace(/^data:image\/\w+;base64,/, "");

      const result = await model.generateContent({
        contents: [{
          role: "user",
          parts: [
            {
              text: `Read the set code, collector number, and card name from this Riftbound (League of Legends TCG) trading card photo.

The collector number is printed small at the bottom of the card. It includes:
- Set code prefix: 3 letters like "OGN", "RSB", "RFT", etc.
- Number: like "025/240" or "025" or "007a"

The card name is the large title text on the card. It may be in English, French, or Simplified Chinese.

Reply with EXACTLY one line:
SET_CODE|COLLECTOR_NUMBER|CARD_NAME

Examples:
OGN|025|Jinx - Demolitionist
RSB|142|Teemo

If you cannot read the text clearly, reply: NONE`,
            },
            {
              inlineData: {
                mimeType: "image/jpeg",
                data: base64Data,
              },
            },
          ],
        }],
      });

      const rawAnswer = result.response?.candidates?.[0]?.content?.parts?.[0]?.text ?? "NONE";
      const answer = rawAnswer.trim();
      console.log(`scanCardOcr response: "${answer}"`);

      if (!answer || answer === "NONE" || answer.toUpperCase() === "NONE") {
        res.status(200).json({ found: false, cards: [] });
        return;
      }

      // Parse: SET_CODE|COLLECTOR_NUMBER|CARD_NAME or fallback to old format
      const parts = answer.split("|").map((s: string) => s.trim());
      
      let setCode: string | null = null;
      let rawCollectorNum = "";
      let cardName: string | null = null;
      
      if (parts.length >= 3) {
        // New format: SET_CODE|COLLECTOR_NUMBER|CARD_NAME
        setCode = parts[0].toUpperCase();
        rawCollectorNum = parts[1];
        cardName = parts.slice(2).join("|").trim();
      } else if (parts.length === 2) {
        // Old format: COLLECTOR_NUMBER|CARD_NAME
        rawCollectorNum = parts[0];
        cardName = parts[1];
      } else {
        rawCollectorNum = parts[0] || "";
      }

      // Extract clean collector number from messy formats:
      // "025/240" → "025", "007a" → "007a"
      function extractCollectorNumber(raw: string): string | null {
        if (!raw) return null;
        let s = raw.trim();
        // Strip total after slash: "308/298" → "308"
        s = s.replace(/\/\d+$/, "");
        // Trim whitespace
        s = s.trim();
        // Must contain at least one digit
        if (!/\d/.test(s)) return null;
        return s || null;
      }

      const cleanNum = extractCollectorNumber(rawCollectorNum);
      console.log(`scanCardOcr parsed: set="${setCode}", raw="${rawCollectorNum}" → clean="${cleanNum}", name="${cardName}"`);

      if (!cleanNum && !cardName) {
        res.status(200).json({ found: false, cards: [] });
        return;
      }

      // Match against Firestore catalog
      let matchedCard: any = null;

      if (cleanNum) {
        // Try multiple collector number formats (with/without leading zeros)
        const numVariants = new Set<string>();
        numVariants.add(cleanNum); // e.g. "308"
        // Pad to 3 digits: "308" → "308", "42" → "042", "7" → "007"
        const digits = cleanNum.replace(/[^0-9]/g, "");
        const suffix = cleanNum.replace(/^[0-9]+/, ""); // "a" from "007a"
        if (digits) {
          numVariants.add(digits + suffix);
          numVariants.add(digits.padStart(3, "0") + suffix);
          numVariants.add(String(parseInt(digits, 10)) + suffix);
        }

        // Query Firestore with all variants
        const variantArray = [...numVariants];
        const snap = await db.collection("cardCatalog")
          .where("collectorNumber", "in", variantArray)
          .limit(20)
          .get();

        if (!snap.empty) {
          const docs = snap.docs.map(d => ({ id: d.id, ...d.data() }));
          
          // First priority: match by expansion code if provided
          if (setCode) {
            matchedCard = docs.find((d: any) => 
              d.expansionCode?.toUpperCase() === setCode
            );
          }
          
          // Second priority: match by name similarity
          if (!matchedCard && cardName) {
            const nameLower = cardName.toLowerCase();
            matchedCard = docs.find((d: any) =>
              d.name?.toLowerCase().includes(nameLower) ||
              d.nameLower?.includes(nameLower)
            );
          }
          
          // Fallback to first match
          if (!matchedCard) {
            matchedCard = docs[0];
          }
        }
      }

      // Fallback: try name search if number didn't match
      if (!matchedCard && cardName) {
        const nameSnap = await db.collection("cardCatalog")
          .where("nameLower", "==", cardName.toLowerCase())
          .limit(1)
          .get();
        if (!nameSnap.empty) {
          matchedCard = { id: nameSnap.docs[0].id, ...nameSnap.docs[0].data() };
        }
      }

      const firstCard = {
        cardName: cleanNum || rawCollectorNum || "",
        extraInfo: matchedCard?.name || cardName || null,
      };

      res.status(200).json({
        found: !!matchedCard,
        cardName: matchedCard?.name || cardName || cleanNum,
        extraInfo: matchedCard?.collectorNumber || cleanNum,
        fullResponse: answer,
        cards: [firstCard],
        // Matched catalog data for frontend
        matchedBlueprintId: matchedCard?.blueprintId || null,
        matchedId: matchedCard?.id || null,
        matchedName: matchedCard?.name || null,
        matchedCollectorNumber: matchedCard?.collectorNumber || null,
        matchedExpansionCode: matchedCard?.expansionCode || null,
        matchedExpansionName: matchedCard?.expansionName || null,
        matchedImageUrl: matchedCard?.imageUrl || null,
        matchedRarity: matchedCard?.rarity || null,
        matchedPrice: matchedCard?.marketPrice || null,
        // AI detected set code (for debugging)
        detectedSetCode: setCode,
      });
    } catch (error: any) {
      console.error("scanCardOcr error:", error.message);
      res.status(500).json({ error: error.message });
    }
  }
);

// ═══════════════════════════════════════════════════════
//  generateFingerprints — Multi-region dHash with voting
//  3 overlapping regions for more robust matching
// ═══════════════════════════════════════════════════════
const DHASH_SIZE = 9; // 9x8 pixels -> 8x8 = 64 bit hash
const DHASH_LENGTH = 64;
const MULTI_HASH_LENGTH = 64 * 3; // 3 hashes = 192 values

// Region definitions (percentage of card height/width)
const REGIONS = [
  { name: "top", top: 0.10, height: 0.30, left: 0.10, width: 0.80 },
  { name: "mid", top: 0.25, height: 0.35, left: 0.10, width: 0.80 },
  { name: "bot", top: 0.15, height: 0.35, left: 0.10, width: 0.80 },
];

async function generateMultiDHashFromUrl(imageUrl: string): Promise<number[] | null> {
  try {
    const sharp = await import("sharp");
    
    const response = await fetch(imageUrl);
    if (!response.ok) return null;
    const buffer = Buffer.from(await response.arrayBuffer());

    const metadata = await sharp.default(buffer).metadata();
    const imgWidth = metadata.width || 200;
    const imgHeight = metadata.height || 280;
    
    const allHashes: number[] = [];
    
    for (const region of REGIONS) {
      const cropTop = Math.floor(imgHeight * region.top);
      const cropHeight = Math.floor(imgHeight * region.height);
      const cropLeft = Math.floor(imgWidth * region.left);
      const cropWidth = Math.floor(imgWidth * region.width);
      
      const { data } = await sharp.default(buffer)
        .extract({ left: cropLeft, top: cropTop, width: cropWidth, height: cropHeight })
        .resize(DHASH_SIZE, 8, { fit: "fill", kernel: "cubic" }) // cubic = bicubic, similar to bilinear
        .grayscale()
        .raw()
        .toBuffer({ resolveWithObject: true });

      // Generate dHash for this region
      for (let y = 0; y < 8; y++) {
        for (let x = 0; x < 8; x++) {
          const leftIdx = y * DHASH_SIZE + x;
          const rightIdx = y * DHASH_SIZE + x + 1;
          allHashes.push(data[leftIdx] > data[rightIdx] ? 1 : 0);
        }
      }
    }

    return allHashes; // 192 values (3 x 64)
  } catch (error) {
    console.error(`Multi-dHash error for ${imageUrl}:`, error);
    return null;
  }
}

export const generateFingerprints = onRequest(
  { 
    region: "europe-west1", 
    timeoutSeconds: 540, 
    memory: "1GiB",
  },
  async (req, res) => {
    setCors(res);
    if (req.method === "OPTIONS") { res.status(204).send(""); return; }

    try {
      // Get limit from query (default 1000, max 2000)
      const limit = Math.min(parseInt(req.query.limit as string) || 1000, 2000);
      const skipExisting = req.query.skipExisting !== "false";

      // Fetch ALL cards from catalog (no limit on query, filter after)
      const snapshot = await db.collection("cardCatalog").get();
      console.log(`Found ${snapshot.size} cards to process`);

      let processed = 0;
      let skipped = 0;
      let errors = 0;
      let batch = db.batch();
      let batchCount = 0;

      for (const doc of snapshot.docs) {
        if (doc.id === "_meta") continue;
        
        const data = doc.data();
        
        // Only process singleCard or null kind
        const kind = data.kind as string | null;
        if (kind && kind !== "singleCard") {
          continue;
        }
        
        // Skip if already has multiHash
        if (skipExisting && data.multiHash && Array.isArray(data.multiHash) && data.multiHash.length === MULTI_HASH_LENGTH) {
          skipped++;
          continue;
        }

        // Skip if no image
        if (!data.imageUrl) {
          skipped++;
          continue;
        }
        
        // Respect limit
        if (processed >= limit) break;

        // Generate multi-region dHash
        const multiHash = await generateMultiDHashFromUrl(data.imageUrl);
        if (multiHash && multiHash.length === MULTI_HASH_LENGTH) {
          batch.update(doc.ref, { multiHash });
          processed++;
          batchCount++;
        } else {
          errors++;
        }

        // Commit batch every 400 documents
        if (batchCount >= 400) {
          await batch.commit();
          batch = db.batch();
          batchCount = 0;
          console.log(`Committed batch, processed: ${processed}`);
        }

        // Small delay to avoid rate limits
        await sleep(100);
      }

      // Commit remaining
      if (batchCount > 0) {
        await batch.commit();
      }

      // Update meta
      await db.collection("cardCatalog").doc("_meta").set({
        lastMultiHashUpdate: FieldValue.serverTimestamp(),
        multiHashCount: processed,
      }, { merge: true });

      console.log(`✅ Generated ${processed} fingerprints, skipped ${skipped}, errors ${errors}`);
      res.status(200).json({
        success: true,
        processed,
        skipped,
        errors,
        total: snapshot.size,
      });
    } catch (error: any) {
      console.error("generateFingerprints error:", error.message);
      res.status(500).json({ error: error.message });
    }
  }
);

// ═══════════════════════════════════════════════════════
//  getFingerprints — Fetch all fingerprints for client-side matching
// ═══════════════════════════════════════════════════════
export const getFingerprints = onRequest(
  { 
    region: "europe-west1", 
    memory: "512MiB",
  },
  async (req, res) => {
    setCors(res);
    if (req.method === "OPTIONS") { res.status(204).send(""); return; }

    try {
      // Fetch all cards with multiHash
      const snapshot = await db.collection("cardCatalog")
        .where("multiHash", "!=", null)
        .select("multiHash") // Only fetch multiHash field to reduce payload
        .get();

      const hashes: Record<string, number[]> = {};
      for (const doc of snapshot.docs) {
        const data = doc.data();
        if (data.multiHash && Array.isArray(data.multiHash)) {
          hashes[doc.id] = data.multiHash;
        }
      }

      res.set("Cache-Control", "public, max-age=3600"); // Cache for 1 hour
      res.status(200).json({
        success: true,
        count: Object.keys(hashes).length,
        hashes,
      });
    } catch (error: any) {
      console.error("getFingerprints error:", error.message);
      res.status(500).json({ error: error.message });
    }
  }
);
