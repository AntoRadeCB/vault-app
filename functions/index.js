const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

// ── Ship24 Secret ──────────────────────────────────
const SHIP24_API_KEY = defineSecret("SHIP24_API_KEY");

const SHIP24_API_BASE = "https://api.ship24.com/public/v1";

// ── CORS helper ────────────────────────────────────
function setCors(res) {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
}

// ═══════════════════════════════════════════════════════
//  Ship24 Webhook Receiver
// ═══════════════════════════════════════════════════════
exports.trackingWebhook = onRequest({ region: "europe-west1" }, async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  try {
    const payload = req.body;
    console.log("Ship24 webhook received:", JSON.stringify(payload));

    // Ship24 manda un array di trackings
    const trackings = payload?.trackings || [];

    for (const tracking of trackings) {
      const tracker = tracking.tracker || {};
      const shipment = tracking.shipment || {};
      const events = tracking.events || [];
      const trackingNumber = tracker.trackingNumber;

      if (!trackingNumber) continue;

      // Mappa status Ship24 → status app
      const milestoneMap = {
        "pending": "pending",
        "info_received": "pending",
        "in_transit": "inTransit",
        "out_for_delivery": "inTransit",
        "attempt_fail": "exception",
        "available_for_pickup": "inTransit",
        "delivered": "delivered",
        "exception": "exception",
      };

      const appStatus = milestoneMap[shipment.statusMilestone] || "unknown";

      // Converti eventi Ship24 → tracking history
      const trackingHistory = events.map((e) => ({
        status: e.status || "Unknown",
        statusCode: e.statusCode || null,
        timestamp: e.occurrenceDatetime || null,
        location: e.location || null,
        description: e.status || null,
        courierCode: e.courierCode || null,
      }));

      // Cerca spedizione in Firestore per tracking number (in tutti gli utenti)
      const usersSnap = await db.collection("users").get();
      for (const userDoc of usersSnap.docs) {
        const shipmentsRef = userDoc.ref.collection("shipments");
        const snapshot = await shipmentsRef
          .where("trackingCode", "==", trackingNumber)
          .limit(1)
          .get();

        if (!snapshot.empty) {
          const doc = snapshot.docs[0];
          await doc.ref.update({
            status: appStatus,
            ship24Status: shipment.statusMilestone || "unknown",
            ship24StatusCode: shipment.statusCode || null,
            lastUpdate: FieldValue.serverTimestamp(),
            lastEvent: events.length > 0 ? events[0].status : null,
            trackingHistory: trackingHistory,
            carrier: events.length > 0 ? events[0].courierCode : null,
          });
          console.log(`Updated shipment ${doc.id} for tracking ${trackingNumber}`);
        }
      }
    }

    return res.status(200).json({ status: "ok" });
  } catch (error) {
    console.error("Webhook error:", error);
    return res.status(200).json({ status: "error", message: error.message });
  }
});

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

      const body = {
        trackingNumber: trackingNumber,
      };
      if (courierCode) {
        body.courierCode = [courierCode];
      }

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
        // Fetch by tracker ID
        const response = await fetch(`${SHIP24_API_BASE}/trackers/${trackerId}/results`, {
          headers: { "Authorization": `Bearer ${apiKey}` },
        });
        if (response.ok) {
          const data = await response.json();
          trackings = data.data?.trackings || [];
        }
      }

      // If no results or no trackerId, search by tracking number
      if (trackings.length === 0 && trackingNumber) {
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
        } else {
          // Se non trovato, registra automaticamente e riprova
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
              // Aspetta un attimo e riprova
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
