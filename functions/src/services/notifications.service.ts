import { db } from "../config/firebase.config";

export interface AppNotification {
  id: string;
  title: string;
  body: string;
  type: "shipmentUpdate" | "sale" | "lowStock" | "system";
  createdAt: string;
  read: boolean;
  referenceId?: string | null;
  metadata?: Record<string, any> | null;
}

function collectionRef(uid: string) {
  return db.collection("users").doc(uid).collection("notifications");
}

function docToNotification(doc: FirebaseFirestore.DocumentSnapshot): AppNotification {
  const data = doc.data()!;
  return {
    id: doc.id,
    title: data.title ?? "",
    body: data.body ?? data.message ?? "",
    type: data.type ?? "system",
    createdAt: data.createdAt?.toDate?.()?.toISOString?.() ?? new Date().toISOString(),
    read: data.read ?? false,
    referenceId: data.referenceId ?? data.shipmentId ?? null,
    metadata: data.metadata ?? null,
  };
}

export async function listNotifications(uid: string): Promise<AppNotification[]> {
  const snap = await collectionRef(uid).orderBy("createdAt", "desc").get();
  return snap.docs.map(docToNotification);
}

export async function getUnreadCount(uid: string): Promise<number> {
  const snap = await collectionRef(uid).where("read", "==", false).get();
  return snap.size;
}

export async function markAsRead(uid: string, id: string): Promise<boolean> {
  const ref = collectionRef(uid).doc(id);
  const doc = await ref.get();
  if (!doc.exists) return false;
  await ref.update({ read: true });
  return true;
}

export async function deleteNotification(uid: string, id: string): Promise<boolean> {
  const ref = collectionRef(uid).doc(id);
  const doc = await ref.get();
  if (!doc.exists) return false;
  await ref.delete();
  return true;
}

export async function clearAllNotifications(uid: string): Promise<number> {
  const snap = await collectionRef(uid).get();
  const batch = db.batch();
  let count = 0;
  for (const doc of snap.docs) {
    batch.delete(doc.ref);
    count++;
  }
  if (count > 0) {
    await batch.commit();
  }
  return count;
}
