import { db } from "../config/firebase.config";
import { FieldValue } from "firebase-admin/firestore";

export interface Purchase {
  id: string;
  productName: string;
  price: number;
  quantity: number;
  date: string;
  workspace: string;
}

function collectionRef(uid: string) {
  return db.collection("users").doc(uid).collection("purchases");
}

function docToPurchase(doc: FirebaseFirestore.DocumentSnapshot): Purchase {
  const data = doc.data()!;
  return {
    id: doc.id,
    productName: data.productName ?? "",
    price: data.price ?? 0,
    quantity: data.quantity ?? 0,
    date: data.date?.toDate?.()?.toISOString?.() ?? new Date().toISOString(),
    workspace: data.workspace ?? "",
  };
}

export async function listPurchases(uid: string): Promise<Purchase[]> {
  const snap = await collectionRef(uid).orderBy("date", "desc").get();
  return snap.docs.map(docToPurchase);
}

export async function createPurchase(
  uid: string,
  data: Omit<Purchase, "id">
): Promise<Purchase> {
  const docData: any = {
    productName: data.productName,
    price: data.price,
    quantity: data.quantity,
    workspace: data.workspace ?? "",
    date: data.date ? new Date(data.date) : FieldValue.serverTimestamp(),
  };
  const ref = await collectionRef(uid).add(docData);
  const doc = await ref.get();
  return docToPurchase(doc);
}
