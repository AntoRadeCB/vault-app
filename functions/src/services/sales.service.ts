import { db } from "../config/firebase.config";
import { FieldValue } from "firebase-admin/firestore";

export interface Sale {
  id: string;
  productName: string;
  salePrice: number;
  purchasePrice: number;
  fees: number;
  date: string;
}

function collectionRef(uid: string) {
  return db.collection("users").doc(uid).collection("sales");
}

function docToSale(doc: FirebaseFirestore.DocumentSnapshot): Sale {
  const data = doc.data()!;
  return {
    id: doc.id,
    productName: data.productName ?? "",
    salePrice: data.salePrice ?? 0,
    purchasePrice: data.purchasePrice ?? 0,
    fees: data.fees ?? 0,
    date: data.date?.toDate?.()?.toISOString?.() ?? new Date().toISOString(),
  };
}

export async function listSales(uid: string): Promise<Sale[]> {
  const snap = await collectionRef(uid).orderBy("date", "desc").get();
  return snap.docs.map(docToSale);
}

export async function createSale(
  uid: string,
  data: Omit<Sale, "id">
): Promise<Sale> {
  const docData: any = {
    productName: data.productName,
    salePrice: data.salePrice,
    purchasePrice: data.purchasePrice,
    fees: data.fees,
    date: data.date ? new Date(data.date) : FieldValue.serverTimestamp(),
  };
  const ref = await collectionRef(uid).add(docData);
  const doc = await ref.get();
  return docToSale(doc);
}
