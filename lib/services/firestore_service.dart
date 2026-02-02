import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../models/purchase.dart';
import '../models/sale.dart';
import '../models/shipment.dart';
import '../models/app_notification.dart';

// ═══════════════════════════════════════════════════
//  DEMO DATA — Rich sample data for unauthenticated users
// ═══════════════════════════════════════════════════
class _DemoData {
  static final _now = DateTime.now();

  static List<Product> get products => [
        Product(
          id: 'demo_p1',
          name: 'Nike Air Max 90',
          brand: 'NIKE',
          quantity: 1,
          price: 45,
          status: ProductStatus.shipped,
          createdAt: _now.subtract(const Duration(days: 2)),
        ),
        Product(
          id: 'demo_p2',
          name: 'Adidas Forum Low',
          brand: 'ADIDAS',
          quantity: 2,
          price: 65,
          status: ProductStatus.inInventory,
          createdAt: _now.subtract(const Duration(days: 5)),
        ),
        Product(
          id: 'demo_p3',
          name: 'Stone Island Hoodie',
          brand: 'STONE ISLAND',
          quantity: 1,
          price: 120,
          status: ProductStatus.listed,
          createdAt: _now.subtract(const Duration(days: 8)),
        ),
        Product(
          id: 'demo_p4',
          name: 'Supreme Box Logo Tee',
          brand: 'SUPREME',
          quantity: 1,
          price: 85,
          status: ProductStatus.inInventory,
          createdAt: _now.subtract(const Duration(days: 3)),
        ),
        Product(
          id: 'demo_p5',
          name: 'Jordan 4 Retro',
          brand: 'JORDAN',
          quantity: 1,
          price: 190,
          status: ProductStatus.shipped,
          createdAt: _now.subtract(const Duration(days: 1)),
        ),
        Product(
          id: 'demo_p6',
          name: 'The North Face Nuptse',
          brand: 'THE NORTH FACE',
          quantity: 1,
          price: 150,
          status: ProductStatus.inInventory,
          createdAt: _now.subtract(const Duration(days: 12)),
        ),
        Product(
          id: 'demo_p7',
          name: 'Carhartt WIP Jacket',
          brand: 'CARHARTT',
          quantity: 1,
          price: 95,
          status: ProductStatus.listed,
          createdAt: _now.subtract(const Duration(days: 6)),
        ),
      ];

  static List<Sale> get sales => [
        Sale(
          id: 'demo_s1',
          productName: 'Nike Dunk Low',
          salePrice: 130,
          purchasePrice: 90,
          fees: 13,
          date: _now.subtract(const Duration(days: 3)),
        ),
        Sale(
          id: 'demo_s2',
          productName: 'Yeezy 350',
          salePrice: 280,
          purchasePrice: 220,
          fees: 28,
          date: _now.subtract(const Duration(days: 7)),
        ),
        Sale(
          id: 'demo_s3',
          productName: 'Palace Tee',
          salePrice: 75,
          purchasePrice: 35,
          fees: 8,
          date: _now.subtract(const Duration(days: 14)),
        ),
        Sale(
          id: 'demo_s4',
          productName: 'Stone Island Polo',
          salePrice: 95,
          purchasePrice: 55,
          fees: 10,
          date: _now.subtract(const Duration(days: 21)),
        ),
      ];

  static List<Purchase> get purchases => [
        Purchase(
          id: 'demo_pu1',
          productName: 'Nike Air Max 90',
          price: 45,
          quantity: 1,
          date: _now.subtract(const Duration(days: 2)),
          workspace: 'Reselling Vinted 2025',
        ),
        Purchase(
          id: 'demo_pu2',
          productName: 'Adidas Forum Low',
          price: 65,
          quantity: 2,
          date: _now.subtract(const Duration(days: 5)),
          workspace: 'Reselling Vinted 2025',
        ),
        Purchase(
          id: 'demo_pu3',
          productName: 'Stone Island Hoodie',
          price: 120,
          quantity: 1,
          date: _now.subtract(const Duration(days: 8)),
          workspace: 'Reselling Vinted 2025',
        ),
        Purchase(
          id: 'demo_pu4',
          productName: 'Supreme Box Logo Tee',
          price: 85,
          quantity: 1,
          date: _now.subtract(const Duration(days: 3)),
          workspace: 'Reselling Vinted 2025',
        ),
        Purchase(
          id: 'demo_pu5',
          productName: 'Jordan 4 Retro',
          price: 190,
          quantity: 1,
          date: _now.subtract(const Duration(days: 1)),
          workspace: 'Reselling Vinted 2025',
        ),
        Purchase(
          id: 'demo_pu6',
          productName: 'The North Face Nuptse',
          price: 150,
          quantity: 1,
          date: _now.subtract(const Duration(days: 12)),
          workspace: 'Reselling Vinted 2025',
        ),
      ];

  static List<Shipment> get shipments => [
        Shipment(
          id: 'demo_sh1',
          trackingCode: 'RR123456789IT',
          carrier: 'poste_italiane',
          carrierName: 'Poste Italiane',
          type: ShipmentType.purchase,
          productName: 'Nike Air Max 90',
          status: ShipmentStatus.pending,
          createdAt: _now.subtract(const Duration(days: 1)),
          lastEvent: 'Spedizione registrata',
        ),
        Shipment(
          id: 'demo_sh2',
          trackingCode: '1Z999AA10123456784',
          carrier: 'ups',
          carrierName: 'UPS',
          type: ShipmentType.sale,
          productName: 'Stone Island Hoodie',
          status: ShipmentStatus.inTransit,
          createdAt: _now.subtract(const Duration(days: 3)),
          lastUpdate: _now.subtract(const Duration(hours: 6)),
          lastEvent: 'In transito — Hub di Milano',
          trackingHistory: [
            TrackingEvent(
              status: 'In transito',
              timestamp: _now.subtract(const Duration(hours: 6)),
              location: 'Milano, IT',
              description: 'Il pacco è stato processato nel centro di smistamento',
            ),
            TrackingEvent(
              status: 'Ritirato',
              timestamp: _now.subtract(const Duration(days: 2)),
              location: 'Roma, IT',
              description: 'Il corriere ha ritirato il pacco',
            ),
          ],
        ),
        Shipment(
          id: 'demo_sh3',
          trackingCode: 'BRT000123456789',
          carrier: 'brt',
          carrierName: 'BRT',
          type: ShipmentType.purchase,
          productName: 'Jordan 4 Retro',
          status: ShipmentStatus.delivered,
          createdAt: _now.subtract(const Duration(days: 7)),
          lastUpdate: _now.subtract(const Duration(days: 5)),
          lastEvent: 'Consegnato',
          trackingHistory: [
            TrackingEvent(
              status: 'Consegnato',
              timestamp: _now.subtract(const Duration(days: 5)),
              location: 'Firenze, IT',
              description: 'Il pacco è stato consegnato',
            ),
            TrackingEvent(
              status: 'In consegna',
              timestamp: _now.subtract(const Duration(days: 5, hours: 4)),
              location: 'Firenze, IT',
              description: 'Il pacco è in consegna',
            ),
            TrackingEvent(
              status: 'In transito',
              timestamp: _now.subtract(const Duration(days: 6)),
              location: 'Bologna, IT',
              description: 'Il pacco è in transito',
            ),
          ],
        ),
      ];

  static List<AppNotification> get notifications => [
        AppNotification(
          id: 'demo_n1',
          title: 'Spedizione consegnata',
          body: 'Il tuo ordine "Jordan 4 Retro" è stato consegnato a Firenze.',
          type: NotificationType.shipmentUpdate,
          createdAt: _now.subtract(const Duration(days: 5)),
          read: true,
          referenceId: 'demo_sh3',
        ),
        AppNotification(
          id: 'demo_n2',
          title: 'Nuova vendita!',
          body: 'Hai venduto "Nike Dunk Low" per €130. Profitto: €27 🎉',
          type: NotificationType.sale,
          createdAt: _now.subtract(const Duration(days: 3)),
          read: false,
        ),
        AppNotification(
          id: 'demo_n3',
          title: 'Stock basso',
          body: 'Hai solo 1 pezzo di "Supreme Box Logo Tee" in inventario.',
          type: NotificationType.lowStock,
          createdAt: _now.subtract(const Duration(days: 1)),
          read: false,
        ),
      ];
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Whether the service is in demo mode (no authenticated user)
  bool get isDemoMode => _uid == null;

  // ─── Helper: user-scoped collection ──────────────
  CollectionReference _userCollection(String collection) {
    return _db.collection('users').doc(_uid).collection(collection);
  }

  // ═══════════════════════════════════════════════════
  //  PRODUCTS
  // ═══════════════════════════════════════════════════

  Future<DocumentReference> addProduct(Product product) {
    if (isDemoMode) return Future.error('demo');
    return _userCollection('products').add(product.toFirestore());
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) {
    if (isDemoMode) return Future.error('demo');
    return _userCollection('products').doc(id).update(data);
  }

  Future<void> deleteProduct(String id) {
    if (isDemoMode) return Future.error('demo');
    return _userCollection('products').doc(id).delete();
  }

  Stream<List<Product>> getProducts() {
    if (isDemoMode) return Stream.value(_DemoData.products);
    return _userCollection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  Future<Product?> getProductById(String id) async {
    if (isDemoMode) {
      try {
        return _DemoData.products.firstWhere((p) => p.id == id);
      } catch (_) {
        return null;
      }
    }
    final doc = await _userCollection('products').doc(id).get();
    if (!doc.exists) return null;
    return Product.fromFirestore(doc);
  }

  /// Find product by barcode
  Future<Product?> getProductByBarcode(String barcode) async {
    if (isDemoMode) return null;
    final snap = await _userCollection('products')
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Product.fromFirestore(snap.docs.first);
  }

  // ═══════════════════════════════════════════════════
  //  PURCHASES
  // ═══════════════════════════════════════════════════

  Future<DocumentReference> addPurchase(Purchase purchase) {
    if (isDemoMode) return Future.error('demo');
    return _userCollection('purchases').add(purchase.toFirestore());
  }

  Stream<List<Purchase>> getPurchases() {
    if (isDemoMode) return Stream.value(_DemoData.purchases);
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
    if (isDemoMode) return Future.error('demo');
    return _userCollection('sales').add(sale.toFirestore());
  }

  Stream<List<Sale>> getSales() {
    if (isDemoMode) return Stream.value(_DemoData.sales);
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
  //  SHIPMENTS
  // ═══════════════════════════════════════════════════

  Future<DocumentReference> addShipment(Shipment shipment) {
    if (isDemoMode) return Future.error('demo');
    return _userCollection('shipments').add(shipment.toFirestore());
  }

  Future<void> updateShipment(String id, Map<String, dynamic> data) {
    if (isDemoMode) return Future.error('demo');
    return _userCollection('shipments').doc(id).update(data);
  }

  Future<void> deleteShipment(String id) {
    if (isDemoMode) return Future.error('demo');
    return _userCollection('shipments').doc(id).delete();
  }

  Stream<List<Shipment>> getShipments() {
    if (isDemoMode) return Stream.value(_DemoData.shipments);
    return _userCollection('shipments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Shipment.fromFirestore(doc)).toList());
  }

  Stream<List<Shipment>> getActiveShipments() {
    return getShipments().map((shipments) =>
        shipments.where((s) => s.status != ShipmentStatus.delivered).toList());
  }

  Stream<int> getActiveShipmentsCount() {
    return getActiveShipments().map((s) => s.length);
  }

  /// Find a shipment by tracking code
  Future<Shipment?> getShipmentByTrackingCode(String code) async {
    if (isDemoMode) {
      try {
        return _DemoData.shipments.firstWhere((s) => s.trackingCode == code);
      } catch (_) {
        return null;
      }
    }
    final snap = await _userCollection('shipments')
        .where('trackingCode', isEqualTo: code)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Shipment.fromFirestore(snap.docs.first);
  }

  /// Update shipment with Ship24 tracking data
  Future<void> updateShipmentTracking(
    String id, {
    String? trackerId,
    String? trackingApiStatus,
    String? externalTrackingUrl,
    String? appStatus,
    List<TrackingEvent>? trackingHistory,
  }) {
    if (isDemoMode) return Future.error('demo');
    final Map<String, dynamic> data = {
      'lastUpdate': FieldValue.serverTimestamp(),
    };
    if (trackerId != null) data['trackerId'] = trackerId;
    if (trackingApiStatus != null) data['trackingApiStatus'] = trackingApiStatus;
    if (externalTrackingUrl != null) data['externalTrackingUrl'] = externalTrackingUrl;
    if (appStatus != null) data['status'] = appStatus;
    if (trackingHistory != null) {
      data['trackingHistory'] = trackingHistory.map((e) => e.toMap()).toList();
    }
    return _userCollection('shipments').doc(id).update(data);
  }

  // ═══════════════════════════════════════════════════
  //  NOTIFICATIONS
  // ═══════════════════════════════════════════════════

  Future<DocumentReference> addNotification(AppNotification notification) {
    if (isDemoMode) return Future.error('demo');
    return _userCollection('notifications').add(notification.toFirestore());
  }

  Stream<List<AppNotification>> getNotifications() {
    if (isDemoMode) return Stream.value(_DemoData.notifications);
    return _userCollection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => AppNotification.fromFirestore(doc)).toList());
  }

  Stream<int> getUnreadNotificationCount() {
    if (isDemoMode) {
      return Stream.value(
          _DemoData.notifications.where((n) => !n.read).length);
    }
    return _userCollection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markNotificationRead(String id) {
    if (isDemoMode) return Future.error('demo');
    return _userCollection('notifications').doc(id).update({'read': true});
  }

  Future<void> deleteNotification(String id) {
    if (isDemoMode) return Future.error('demo');
    return _userCollection('notifications').doc(id).delete();
  }

  Future<void> clearAllNotifications() async {
    if (isDemoMode) return;
    final snap = await _userCollection('notifications').get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    return batch.commit();
  }

  // ═══════════════════════════════════════════════════
  //  USER PROFILE
  // ═══════════════════════════════════════════════════

  Future<void> setUserProfile(Map<String, dynamic> data) {
    if (isDemoMode) return Future.error('demo');
    return _db.collection('users').doc(_uid).set(data, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> getUserProfile() {
    if (isDemoMode) return Stream.value(null);
    return _db.collection('users').doc(_uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return doc.data();
    });
  }
}
