import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../models/purchase.dart';
import '../models/sale.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ─── Helper: user-scoped collection ──────────────
  CollectionReference _userCollection(String collection) {
    return _db.collection('users').doc(_uid).collection(collection);
  }

  // ═══════════════════════════════════════════════════
  //  PRODUCTS
  // ═══════════════════════════════════════════════════

  Future<DocumentReference> addProduct(Product product) {
    return _userCollection('products').add(product.toFirestore());
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) {
    return _userCollection('products').doc(id).update(data);
  }

  Future<void> deleteProduct(String id) {
    return _userCollection('products').doc(id).delete();
  }

  Stream<List<Product>> getProducts() {
    return _userCollection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  Future<Product?> getProductById(String id) async {
    final doc = await _userCollection('products').doc(id).get();
    if (!doc.exists) return null;
    return Product.fromFirestore(doc);
  }

  // ═══════════════════════════════════════════════════
  //  PURCHASES
  // ═══════════════════════════════════════════════════

  Future<DocumentReference> addPurchase(Purchase purchase) {
    return _userCollection('purchases').add(purchase.toFirestore());
  }

  Stream<List<Purchase>> getPurchases() {
    return _userCollection('purchases')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Purchase.fromFirestore(doc)).toList());
  }

  // ═══════════════════════════════════════════════════
  //  SALES
  // ═══════════════════════════════════════════════════

  Future<DocumentReference> addSale(Sale sale) {
    return _userCollection('sales').add(sale.toFirestore());
  }

  Stream<List<Sale>> getSales() {
    return _userCollection('sales')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Sale.fromFirestore(doc)).toList());
  }

  // ═══════════════════════════════════════════════════
  //  STATS (computed from real data)
  // ═══════════════════════════════════════════════════

  /// Capitale Immobilizzato = sum(price * quantity) for products with status "inInventory"
  Stream<double> getCapitaleImmobilizzato() {
    return getProducts().map((products) {
      return products
          .where((p) => p.status == ProductStatus.inInventory)
          .fold<double>(0, (acc, p) => acc + (p.price * p.quantity));
    });
  }

  /// Ordini in Arrivo = sum(price * quantity) for products with status "shipped"
  Stream<double> getOrdiniInArrivo() {
    return getProducts().map((products) {
      return products
          .where((p) => p.status == ProductStatus.shipped)
          .fold<double>(0, (acc, p) => acc + (p.price * p.quantity));
    });
  }

  /// Capitale Spedito = sum(price * quantity) for products with status "listed"
  Stream<double> getCapitaleSpedito() {
    return getProducts().map((products) {
      return products
          .where((p) => p.status == ProductStatus.listed)
          .fold<double>(0, (acc, p) => acc + (p.price * p.quantity));
    });
  }

  /// Profitto Consolidato = sum of all sales profits
  Stream<double> getProfittoConsolidato() {
    return getSales().map((sales) {
      return sales.fold<double>(0, (acc, s) => acc + s.profit);
    });
  }

  /// Sales Count
  Stream<int> getSalesCount() {
    return getSales().map((sales) => sales.length);
  }

  /// Purchases Count
  Stream<int> getPurchasesCount() {
    return getPurchases().map((purchases) => purchases.length);
  }

  /// Total Fees Paid
  Stream<double> getTotalFeesPaid() {
    return getSales().map((sales) {
      return sales.fold<double>(0, (acc, s) => acc + s.fees);
    });
  }

  /// Total Revenue = sum of all sale prices
  Stream<double> getTotalRevenue() {
    return getSales().map((sales) {
      return sales.fold<double>(0, (acc, s) => acc + s.salePrice);
    });
  }

  /// Total Spent = sum of all purchase costs
  Stream<double> getTotalSpent() {
    return getPurchases().map((purchases) {
      return purchases.fold<double>(0, (acc, p) => acc + p.totalCost);
    });
  }

  /// Items count in inventory
  Stream<int> getInventoryItemCount() {
    return getProducts().map((products) => products.length);
  }

  /// Total inventory quantity
  Stream<double> getTotalInventoryQuantity() {
    return getProducts().map((products) {
      return products.fold<double>(0, (acc, p) => acc + p.quantity);
    });
  }

  /// Average profit per sale
  Stream<double> getAverageProfitPerSale() {
    return getSales().map((sales) {
      if (sales.isEmpty) return 0.0;
      final totalProfit = sales.fold<double>(0, (acc, s) => acc + s.profit);
      return totalProfit / sales.length;
    });
  }

  /// Best sale (highest profit)
  Stream<Sale?> getBestSale() {
    return getSales().map((sales) {
      if (sales.isEmpty) return null;
      return sales.reduce((a, b) => a.profit > b.profit ? a : b);
    });
  }

  /// Total inventory value (all products regardless of status)
  Stream<double> getTotalInventoryValue() {
    return getProducts().map((products) {
      return products.fold<double>(0, (acc, p) => acc + (p.price * p.quantity));
    });
  }

  /// ROI % = (total profit / total spent) * 100
  Stream<double> getROI() {
    return getCombinedSalesPurchases().map((data) {
      final sales = data['sales'] as List<Sale>;
      final purchases = data['purchases'] as List<Purchase>;
      final totalProfit = sales.fold<double>(0, (acc, s) => acc + s.profit);
      final totalSpent = purchases.fold<double>(0, (acc, p) => acc + p.totalCost);
      if (totalSpent == 0) return 0.0;
      return (totalProfit / totalSpent) * 100;
    });
  }

  /// Combined stream of sales + purchases (emits when either changes)
  Stream<Map<String, dynamic>> getCombinedSalesPurchases() {
    return getSales().asyncExpand((sales) {
      return getPurchases().map((purchases) {
        return {'sales': sales, 'purchases': purchases};
      });
    });
  }

  // ═══════════════════════════════════════════════════
  //  USER PROFILE
  // ═══════════════════════════════════════════════════

  Future<void> setUserProfile(Map<String, dynamic> data) {
    return _db.collection('users').doc(_uid).set(data, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> getUserProfile() {
    return _db.collection('users').doc(_uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return doc.data();
    });
  }
}
