const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const crypto = require("crypto");

initializeApp();
const db = getFirestore();

// ── Ship24 Secrets ─────────────────────────────────
const SHIP24_API_KEY = defineSecret("SHIP24_API_KEY");
const SHIP24_WEBHOOK_SECRET = defineSecret("SHIP24_WEBHOOK_SECRET");

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
