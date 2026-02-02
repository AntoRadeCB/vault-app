import { db } from "../config/firebase.config";

export interface Stats {
  capitaleImmobilizzato: number;
  ordiniInArrivo: number;
  capitaleSpedito: number;
  profittoConsolidato: number;
  salesCount: number;
  purchasesCount: number;
  totalRevenue: number;
  totalSpent: number;
  totalFees: number;
  inventoryCount: number;
  totalQuantity: number;
  avgProfitPerSale: number;
  bestSale: { productName: string; profit: number } | null;
  totalInventoryValue: number;
  roi: number;
}

export async function computeStats(uid: string): Promise<Stats> {
  const userRef = db.collection("users").doc(uid);

  const [productsSnap, salesSnap, purchasesSnap, shipmentsSnap] = await Promise.all([
    userRef.collection("products").get(),
    userRef.collection("sales").get(),
    userRef.collection("purchases").get(),
    userRef.collection("shipments").get(),
  ]);

  // Products
  const products = productsSnap.docs.map((d) => d.data());
  const inventoryProducts = products.filter((p) => p.status === "inInventory" || p.status === "listed");
  const shippedProducts = products.filter((p) => p.status === "shipped");

  const inventoryCount = inventoryProducts.length;
  const totalQuantity = products.reduce((sum, p) => sum + (p.quantity ?? 0), 0);
  const totalInventoryValue = inventoryProducts.reduce(
    (sum, p) => sum + (p.price ?? 0) * (p.quantity ?? 1),
    0
  );

  // Capital tied up in inventory
  const capitaleImmobilizzato = totalInventoryValue;

  // Shipments analysis
  const shipments = shipmentsSnap.docs.map((d) => d.data());
  const incomingShipments = shipments.filter(
    (s) => s.type === "purchase" && s.status !== "delivered"
  );
  const ordiniInArrivo = incomingShipments.length;

  // Capital shipped (sales shipped but not yet delivered)
  const shippedSaleShipments = shipments.filter(
    (s) => s.type === "sale" && s.status !== "delivered"
  );
  const capitaleSpedito = shippedProducts.reduce(
    (sum, p) => sum + (p.price ?? 0) * (p.quantity ?? 1),
    0
  );

  // Sales
  const sales = salesSnap.docs.map((d) => d.data());
  const salesCount = sales.length;
  const totalRevenue = sales.reduce((sum, s) => sum + (s.salePrice ?? 0), 0);
  const totalFees = sales.reduce((sum, s) => sum + (s.fees ?? 0), 0);

  // Profit consolidated = sum of (salePrice - purchasePrice - fees) for each sale
  const profittoConsolidato = sales.reduce(
    (sum, s) => sum + ((s.salePrice ?? 0) - (s.purchasePrice ?? 0) - (s.fees ?? 0)),
    0
  );

  const avgProfitPerSale = salesCount > 0 ? profittoConsolidato / salesCount : 0;

  // Best sale
  let bestSale: { productName: string; profit: number } | null = null;
  for (const s of sales) {
    const profit = (s.salePrice ?? 0) - (s.purchasePrice ?? 0) - (s.fees ?? 0);
    if (!bestSale || profit > bestSale.profit) {
      bestSale = { productName: s.productName ?? "Unknown", profit };
    }
  }

  // Purchases
  const purchases = purchasesSnap.docs.map((d) => d.data());
  const purchasesCount = purchases.length;
  const totalSpent = purchases.reduce((sum, p) => sum + (p.price ?? 0) * (p.quantity ?? 1), 0);

  // ROI
  const roi = totalSpent > 0 ? ((totalRevenue - totalSpent) / totalSpent) * 100 : 0;

  return {
    capitaleImmobilizzato,
    ordiniInArrivo,
    capitaleSpedito,
    profittoConsolidato,
    salesCount,
    purchasesCount,
    totalRevenue,
    totalSpent,
    totalFees,
    inventoryCount,
    totalQuantity,
    avgProfitPerSale: Math.round(avgProfitPerSale * 100) / 100,
    bestSale,
    totalInventoryValue,
    roi: Math.round(roi * 100) / 100,
  };
}
