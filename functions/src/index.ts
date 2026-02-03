import { onRequest } from "firebase-functions/v2/https";
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
