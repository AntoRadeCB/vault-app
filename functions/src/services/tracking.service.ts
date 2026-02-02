const SHIP24_API_BASE = "https://api.ship24.com/public/v1";

export interface TrackingRegistration {
  trackerId: string | null;
  trackingNumber: string;
  isTracked: boolean;
  courierCode: string[];
}

export interface TrackingEventData {
  status: string;
  statusCode: string | null;
  statusMilestone: string | null;
  timestamp: string | null;
  location: string | null;
  description: string | null;
  courierCode: string | null;
}

export interface TrackingStatus {
  trackerId: string | null;
  trackingNumber: string;
  status: string;
  statusCode: string | null;
  statusCategory: string | null;
  carrier: string | null;
  carrierName: string | null;
  trackingUrl: string;
  trackingHistory: TrackingEventData[];
  estimatedDelivery: string | null;
  originCountry: string | null;
  destinationCountry: string | null;
}

export function mapMilestoneToAppStatus(milestone: string): string {
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

function parseEvents(events: any[]): TrackingEventData[] {
  return events.map((e: any) => ({
    status: e.status || "Unknown",
    statusCode: e.statusCode || null,
    statusMilestone: e.statusMilestone || null,
    timestamp: e.occurrenceDatetime || null,
    location: e.location || null,
    description: e.status || null,
    courierCode: e.courierCode || null,
  }));
}

export async function registerTracking(
  apiKey: string,
  trackingNumber: string,
  courierCode?: string
): Promise<TrackingRegistration> {
  const body: any = { trackingNumber };
  if (courierCode) body.courierCode = [courierCode];

  const response = await fetch(`${SHIP24_API_BASE}/trackers`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  const data = await response.json();

  if (!response.ok) {
    throw new Error(`Ship24 API error: ${JSON.stringify(data)}`);
  }

  const tracker = data.data?.tracker || {};
  return {
    trackerId: tracker.trackerId || null,
    trackingNumber: tracker.trackingNumber || trackingNumber,
    isTracked: tracker.isTracked || false,
    courierCode: tracker.courierCode || [],
  };
}

export async function getTrackingStatus(
  apiKey: string,
  trackingNumber?: string,
  trackerId?: string
): Promise<TrackingStatus> {
  let trackings: any[] = [];

  // Try by trackerId first
  if (trackerId) {
    const response = await fetch(`${SHIP24_API_BASE}/trackers/${trackerId}/results`, {
      headers: { Authorization: `Bearer ${apiKey}` },
    });
    if (response.ok) {
      const data = await response.json();
      trackings = data.data?.trackings || [];
    }
  }

  // Try by tracking number search
  if (trackings.length === 0 && trackingNumber) {
    const response = await fetch(`${SHIP24_API_BASE}/trackers/search`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ trackingNumber }),
    });
    if (response.ok) {
      const data = await response.json();
      trackings = data.data?.trackings || [];
    }

    // If still nothing, auto-register and retry
    if (trackings.length === 0) {
      const regResponse = await fetch(`${SHIP24_API_BASE}/trackers`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ trackingNumber }),
      });

      if (regResponse.ok) {
        const regData = await regResponse.json();
        const newTrackerId = regData.data?.tracker?.trackerId;
        if (newTrackerId) {
          await new Promise((r) => setTimeout(r, 2000));
          const retryResponse = await fetch(
            `${SHIP24_API_BASE}/trackers/${newTrackerId}/results`,
            { headers: { Authorization: `Bearer ${apiKey}` } }
          );
          if (retryResponse.ok) {
            const retryData = await retryResponse.json();
            trackings = retryData.data?.trackings || [];
          }
        }
      }
    }
  }

  // No data yet — return pending
  if (trackings.length === 0) {
    return {
      trackerId: null,
      trackingNumber: trackingNumber || "",
      status: "pending",
      statusCode: null,
      statusCategory: null,
      carrier: null,
      carrierName: null,
      trackingUrl: `https://t.ship24.com/t/${trackingNumber}`,
      trackingHistory: [],
      estimatedDelivery: null,
      originCountry: null,
      destinationCountry: null,
    };
  }

  const tracking = trackings[0];
  const shipment = tracking.shipment || {};
  const events = tracking.events || [];
  const tracker = tracking.tracker || {};

  return {
    trackerId: tracker.trackerId || null,
    trackingNumber: tracker.trackingNumber || trackingNumber || "",
    status: shipment.statusMilestone || "pending",
    statusCode: shipment.statusCode || null,
    statusCategory: shipment.statusCategory || null,
    carrier:
      events.length > 0
        ? events[0].courierCode
        : tracker.courierCode?.[0] || null,
    carrierName: events.length > 0 ? events[0].courierCode : null,
    trackingUrl: `https://t.ship24.com/t/${trackingNumber || tracker.trackingNumber}`,
    trackingHistory: parseEvents(events),
    estimatedDelivery: shipment.delivery?.estimatedDeliveryDate || null,
    originCountry: shipment.originCountryCode || null,
    destinationCountry: shipment.destinationCountryCode || null,
  };
}
