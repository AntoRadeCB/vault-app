import { db } from "../config/firebase.config";
import { FieldValue } from "firebase-admin/firestore";

export interface TrackingEvent {
  status: string;
  statusCode?: string | null;
  statusMilestone?: string | null;
  timestamp?: string | null;
  location?: string | null;
  description?: string | null;
  courierCode?: string | null;
}

export interface Shipment {
  id: string;
  trackingCode: string;
  carrier?: string | null;
  carrierName?: string | null;
  type?: "purchase" | "sale";
  productName: string;
  productId?: string | null;
  status: "pending" | "inTransit" | "delivered" | "exception" | "unknown";
  createdAt: string;
  lastUpdate?: string | null;
  lastEvent?: string | null;
  trackerId?: string | null;
  trackingApiStatus?: string | null;
  trackingHistory?: TrackingEvent[];
  externalTrackingUrl?: string | null;
}

function collectionRef(uid: string) {
  return db.collection("users").doc(uid).collection("shipments");
}

function docToShipment(doc: FirebaseFirestore.DocumentSnapshot): Shipment {
  const data = doc.data()!;
  return {
    id: doc.id,
    trackingCode: data.trackingCode ?? "",
    carrier: data.carrier ?? null,
    carrierName: data.carrierName ?? null,
    type: data.type ?? undefined,
    productName: data.productName ?? "",
    productId: data.productId ?? null,
    status: data.status ?? "pending",
    createdAt: data.createdAt?.toDate?.()?.toISOString?.() ?? new Date().toISOString(),
    lastUpdate: data.lastUpdate?.toDate?.()?.toISOString?.() ?? null,
    lastEvent: data.lastEvent ?? null,
    trackerId: data.trackerId ?? null,
    trackingApiStatus: data.trackingApiStatus ?? null,
    trackingHistory: data.trackingHistory ?? [],
    externalTrackingUrl: data.externalTrackingUrl ?? null,
  };
}

export async function listShipments(uid: string): Promise<Shipment[]> {
  const snap = await collectionRef(uid).orderBy("createdAt", "desc").get();
  return snap.docs.map(docToShipment);
}

export async function getShipment(uid: string, id: string): Promise<Shipment | null> {
  const doc = await collectionRef(uid).doc(id).get();
  if (!doc.exists) return null;
  return docToShipment(doc);
}

export async function createShipment(
  uid: string,
  data: Omit<Shipment, "id" | "createdAt">
): Promise<Shipment> {
  const ref = await collectionRef(uid).add({
    ...data,
    trackingHistory: data.trackingHistory ?? [],
    status: data.status ?? "pending",
    createdAt: FieldValue.serverTimestamp(),
  });
  const doc = await ref.get();
  return docToShipment(doc);
}

export async function updateShipment(
  uid: string,
  id: string,
  data: Partial<Omit<Shipment, "id" | "createdAt">>
): Promise<Shipment | null> {
  const ref = collectionRef(uid).doc(id);
  const doc = await ref.get();
  if (!doc.exists) return null;
  await ref.update(data as { [key: string]: any });
  const updated = await ref.get();
  return docToShipment(updated);
}

export async function deleteShipment(uid: string, id: string): Promise<boolean> {
  const ref = collectionRef(uid).doc(id);
  const doc = await ref.get();
  if (!doc.exists) return false;
  await ref.delete();
  return true;
}

export async function updateShipmentTracking(
  uid: string,
  id: string,
  trackingData: {
    trackerId?: string;
    trackingApiStatus?: string;
    carrier?: string;
    lastEvent?: string;
    lastUpdate?: any;
    trackingHistory?: TrackingEvent[];
    externalTrackingUrl?: string;
    status?: string;
  }
): Promise<Shipment | null> {
  const ref = collectionRef(uid).doc(id);
  const doc = await ref.get();
  if (!doc.exists) return null;
  await ref.update({
    ...trackingData,
    lastUpdate: FieldValue.serverTimestamp(),
  });
  const updated = await ref.get();
  return docToShipment(updated);
}
