const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

// ── Sendcloud Secrets ──────────────────────────────
const SENDCLOUD_PUBLIC_KEY = defineSecret("SENDCLOUD_PUBLIC_KEY");
const SENDCLOUD_SECRET_KEY = defineSecret("SENDCLOUD_SECRET_KEY");

const SENDCLOUD_API_BASE = "https://panel.sendcloud.sc/api/v2";

/**
 * Sendcloud Webhook Receiver
 * 
 * Riceve notifiche di tracking da Sendcloud e aggiorna Firestore.
 * URL: https://europe-west1-inventorymanager-dev-20262.cloudfunctions.net/sendcloudWebhook
 */
exports.sendcloudWebhook = onRequest({ region: "europe-west1" }, async (req, res) => {
  // Solo POST
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  try {
    const payload = req.body;
    
    console.log("Sendcloud webhook received:", JSON.stringify(payload));

    // Sendcloud può mandare una verifica — rispondi 200
    if (!payload || !payload.action) {
      return res.status(200).json({ status: "ok" });
    }

    const action = payload.action;
    const parcel = payload.parcel || {};
    const trackingNumber = parcel.tracking_number;

    if (!trackingNumber) {
      console.warn("No tracking number in webhook payload");
      return res.status(200).json({ status: "ok", message: "no tracking number" });
    }

    // Mappa stati Sendcloud → stati app
    const statusMap = {
      1: "announced",
      3: "in_transit",
      4: "in_transit",
      5: "in_transit",
      6: "in_transit",
      8: "in_transit",
      11: "delivered",
      12: "delivery_attempt",
      22: "in_transit",
      31: "in_transit",
      32: "in_transit",
      62: "in_transit",
      80: "cancelled",
      92: "exception",
      99: "ready_to_send",
      999: "unknown",
      1000: "error",
      1001: "returned",
      2000: "label_printed",
    };

    const appStatus = statusMap[parcel.status?.id] || "unknown";

    // Cerca la spedizione in Firestore per tracking number
    const shipmentsRef = db.collection("shipments");
    const snapshot = await shipmentsRef
      .where("trackingNumber", "==", trackingNumber)
      .limit(1)
      .get();

    const eventData = {
      status: parcel.status?.message || "Unknown",
      statusId: parcel.status?.id || null,
      timestamp: payload.timestamp || new Date().toISOString(),
      location: parcel.to_address?.city || null,
    };

    const updateData = {
      status: appStatus,
      sendcloudStatus: parcel.status?.message || "Unknown",
      sendcloudStatusId: parcel.status?.id || null,
      carrier: parcel.carrier?.code || null,
      trackingUrl: parcel.tracking_url || null,
      lastUpdate: FieldValue.serverTimestamp(),
      lastEvent: eventData,
    };

    if (!snapshot.empty) {
      const doc = snapshot.docs[0];
      const trackingHistory = doc.data().trackingHistory || [];
      trackingHistory.push(eventData);
      updateData.trackingHistory = trackingHistory;

      await doc.ref.update(updateData);
      console.log(`Updated shipment ${doc.id} for tracking ${trackingNumber}`);
    } else {
      updateData.trackingNumber = trackingNumber;
      updateData.trackingHistory = [eventData];
      updateData.createdAt = FieldValue.serverTimestamp();
      
      const newDoc = await shipmentsRef.add(updateData);
      console.log(`Created new shipment ${newDoc.id} for tracking ${trackingNumber}`);
    }

    return res.status(200).json({ status: "ok" });
  } catch (error) {
    console.error("Webhook error:", error);
    return res.status(200).json({ status: "error", message: error.message });
  }
});

// ═══════════════════════════════════════════════════════
//  CORS helper
// ═══════════════════════════════════════════════════════
function setCors(res) {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
}

// ═══════════════════════════════════════════════════════
//  registerTracking — register a parcel on Sendcloud
// ═══════════════════════════════════════════════════════
exports.registerTracking = onRequest(
  { region: "europe-west1", secrets: [SENDCLOUD_PUBLIC_KEY, SENDCLOUD_SECRET_KEY] },
  async (req, res) => {
    setCors(res);
    if (req.method === "OPTIONS") return res.status(204).send("");

    if (req.method !== "POST") {
      return res.status(405).json({ error: "Method not allowed" });
    }

    try {
      const { trackingNumber, carrier } = req.body;

      if (!trackingNumber) {
        return res.status(400).json({ error: "trackingNumber is required" });
      }

      const pubKey = SENDCLOUD_PUBLIC_KEY.value();
      const secKey = SENDCLOUD_SECRET_KEY.value();
      const auth = Buffer.from(`${pubKey}:${secKey}`).toString("base64");

      // Create parcel on Sendcloud
      const parcelData = {
        parcel: {
          name: "Vault Shipment",
          tracking_number: trackingNumber,
          carrier: carrier || undefined,
          request_label: false,
        },
      };

      const response = await fetch(`${SENDCLOUD_API_BASE}/parcels`, {
        method: "POST",
        headers: {
          "Authorization": `Basic ${auth}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(parcelData),
      });

      const data = await response.json();

      if (!response.ok) {
        console.error("Sendcloud API error:", JSON.stringify(data));
        return res.status(response.status).json({
          error: "Sendcloud API error",
          details: data,
        });
      }

      const parcel = data.parcel || {};

      return res.status(200).json({
        success: true,
        sendcloudId: parcel.id || null,
        status: parcel.status?.message || null,
        trackingUrl: parcel.tracking_url || null,
        carrier: parcel.carrier?.code || null,
      });
    } catch (error) {
      console.error("registerTracking error:", error);
      return res.status(500).json({ error: error.message });
    }
  }
);

// ═══════════════════════════════════════════════════════
//  getTrackingStatus — get parcel status from Sendcloud
// ═══════════════════════════════════════════════════════
exports.getTrackingStatus = onRequest(
  { region: "europe-west1", secrets: [SENDCLOUD_PUBLIC_KEY, SENDCLOUD_SECRET_KEY] },
  async (req, res) => {
    setCors(res);
    if (req.method === "OPTIONS") return res.status(204).send("");

    if (req.method !== "POST" && req.method !== "GET") {
      return res.status(405).json({ error: "Method not allowed" });
    }

    try {
      const trackingNumber = req.body?.trackingNumber || req.query?.trackingNumber;
      const sendcloudId = req.body?.sendcloudId || req.query?.sendcloudId;

      if (!trackingNumber && !sendcloudId) {
        return res.status(400).json({ error: "trackingNumber or sendcloudId is required" });
      }

      const pubKey = SENDCLOUD_PUBLIC_KEY.value();
      const secKey = SENDCLOUD_SECRET_KEY.value();
      const auth = Buffer.from(`${pubKey}:${secKey}`).toString("base64");

      let parcel = null;

      // If we have a sendcloudId, fetch directly
      if (sendcloudId) {
        const response = await fetch(`${SENDCLOUD_API_BASE}/parcels/${sendcloudId}`, {
          headers: { "Authorization": `Basic ${auth}` },
        });

        if (response.ok) {
          const data = await response.json();
          parcel = data.parcel || null;
        }
      }

      // If no parcel yet, search by tracking number
      if (!parcel && trackingNumber) {
        const response = await fetch(
          `${SENDCLOUD_API_BASE}/parcels?tracking_number=${encodeURIComponent(trackingNumber)}`,
          { headers: { "Authorization": `Basic ${auth}` } }
        );

        if (response.ok) {
          const data = await response.json();
          const parcels = data.parcels || [];
          parcel = parcels.find((p) => p.tracking_number === trackingNumber) || parcels[0] || null;
        }
      }

      if (!parcel) {
        return res.status(404).json({ error: "Parcel not found on Sendcloud" });
      }

      // Build tracking history from status_history if available
      const statusHistory = (parcel.status_history || []).map((h) => ({
        status: h.status?.message || h.message || "Unknown",
        statusId: h.status?.id || h.id || null,
        timestamp: h.created || h.timestamp || null,
        location: h.location || null,
        description: h.description || h.status?.message || null,
      }));

      return res.status(200).json({
        success: true,
        sendcloudId: parcel.id,
        trackingNumber: parcel.tracking_number,
        status: parcel.status?.message || "Unknown",
        statusId: parcel.status?.id || null,
        trackingUrl: parcel.tracking_url || null,
        carrier: parcel.carrier?.code || null,
        carrierName: parcel.carrier?.name || null,
        trackingHistory: statusHistory,
        lastUpdate: parcel.updated_at || null,
      });
    } catch (error) {
      console.error("getTrackingStatus error:", error);
      return res.status(500).json({ error: error.message });
    }
  }
);

// ═══════════════════════════════════════════════════════
//  listSendcloudParcels — list parcels from Sendcloud
// ═══════════════════════════════════════════════════════
exports.listSendcloudParcels = onRequest(
  { region: "europe-west1", secrets: [SENDCLOUD_PUBLIC_KEY, SENDCLOUD_SECRET_KEY] },
  async (req, res) => {
    setCors(res);
    if (req.method === "OPTIONS") return res.status(204).send("");

    try {
      const limit = req.query?.limit || req.body?.limit || 25;
      const cursor = req.query?.cursor || req.body?.cursor || "";

      const pubKey = SENDCLOUD_PUBLIC_KEY.value();
      const secKey = SENDCLOUD_SECRET_KEY.value();
      const auth = Buffer.from(`${pubKey}:${secKey}`).toString("base64");

      let url = `${SENDCLOUD_API_BASE}/parcels?limit=${limit}`;
      if (cursor) url += `&cursor=${cursor}`;

      const response = await fetch(url, {
        headers: { "Authorization": `Basic ${auth}` },
      });

      if (!response.ok) {
        const errorData = await response.json();
        return res.status(response.status).json({ error: "Sendcloud API error", details: errorData });
      }

      const data = await response.json();
      const parcels = (data.parcels || []).map((p) => ({
        sendcloudId: p.id,
        trackingNumber: p.tracking_number,
        status: p.status?.message || "Unknown",
        statusId: p.status?.id || null,
        trackingUrl: p.tracking_url || null,
        carrier: p.carrier?.code || null,
        carrierName: p.carrier?.name || null,
        createdAt: p.created_at || null,
      }));

      return res.status(200).json({
        success: true,
        parcels: parcels,
        next: data.next || null,
        previous: data.previous || null,
      });
    } catch (error) {
      console.error("listSendcloudParcels error:", error);
      return res.status(500).json({ error: error.message });
    }
  }
);
