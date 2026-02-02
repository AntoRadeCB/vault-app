import { db } from "../config/firebase.config";
import { FieldValue } from "firebase-admin/firestore";

export interface Product {
  id: string;
  name: string;
  brand: string;
  quantity: number;
  price: number;
  status: "shipped" | "inInventory" | "listed";
  imageUrl?: string;
  barcode?: string;
  createdAt: string;
}

function collectionRef(uid: string) {
  return db.collection("users").doc(uid).collection("products");
}

function docToProduct(doc: FirebaseFirestore.DocumentSnapshot): Product {
  const data = doc.data()!;
  return {
    id: doc.id,
    name: data.name ?? "",
    brand: data.brand ?? "",
    quantity: data.quantity ?? 0,
    price: data.price ?? 0,
    status: data.status ?? "inInventory",
    imageUrl: data.imageUrl ?? undefined,
    barcode: data.barcode ?? undefined,
    createdAt: data.createdAt?.toDate?.()?.toISOString?.() ?? new Date().toISOString(),
  };
}

export async function listProducts(uid: string): Promise<Product[]> {
  const snap = await collectionRef(uid).orderBy("createdAt", "desc").get();
  return snap.docs.map(docToProduct);
}

export async function getProduct(uid: string, id: string): Promise<Product | null> {
  const doc = await collectionRef(uid).doc(id).get();
  if (!doc.exists) return null;
  return docToProduct(doc);
}

export async function createProduct(
  uid: string,
  data: Omit<Product, "id" | "createdAt">
): Promise<Product> {
  const ref = await collectionRef(uid).add({
    ...data,
    createdAt: FieldValue.serverTimestamp(),
  });
  const doc = await ref.get();
  return docToProduct(doc);
}

export async function updateProduct(
  uid: string,
  id: string,
  data: Partial<Omit<Product, "id" | "createdAt">>
): Promise<Product | null> {
  const ref = collectionRef(uid).doc(id);
  const doc = await ref.get();
  if (!doc.exists) return null;
  await ref.update(data);
  const updated = await ref.get();
  return docToProduct(updated);
}

export async function deleteProduct(uid: string, id: string): Promise<boolean> {
  const ref = collectionRef(uid).doc(id);
  const doc = await ref.get();
  if (!doc.exists) return false;
  await ref.delete();
  return true;
}

export async function findByBarcode(uid: string, barcode: string): Promise<Product | null> {
  const snap = await collectionRef(uid).where("barcode", "==", barcode).limit(1).get();
  if (snap.empty) return null;
  return docToProduct(snap.docs[0]);
}
