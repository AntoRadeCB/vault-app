import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../models/purchase.dart';
import '../models/sale.dart';
import '../models/shipment.dart';
import '../models/app_notification.dart';
import '../models/user_profile.dart';
import '../models/card_pull.dart';
import 'demo_data_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Global demo mode flag — when true, returns local sample data.
  static bool demoMode = false;

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
    if (demoMode) return Stream.value(DemoDataService.products);
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

  /// Find product by barcode
  Future<Product?> getProductByBarcode(String barcode) async {
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
    return _userCollection('purchases').add(purchase.toFirestore());
  }

  Stream<List<Purchase>> getPurchases() {
    if (demoMode) return Stream.value(DemoDataService.purchases);
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
    if (demoMode) return Stream.value(DemoDataService.sales);
    return _userCollection('sales')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Sale.fromFirestore(doc)).toList());
  }

  // ═══════════════════════════════════════════════════
  //  CARD PULLS (subcollection of products)
  // ═══════════════════════════════════════════════════

  /// Stream card pulls for a specific product (pack/box).
  Stream<List<CardPull>> getCardPulls(String productId) {
    if (demoMode) return Stream.value([]);
    return _userCollection('products')
        .doc(productId)
        .collection('cardPulls')
        .orderBy('pulledAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => CardPull.fromFirestore(doc)).toList());
  }

  /// Add a card pull to a product's subcollection.
  Future<DocumentReference> addCardPull(CardPull pull) {
    return _userCollection('products')
        .doc(pull.parentProductId)
        .collection('cardPulls')
        .add(pull.toFirestore());
  }

  /// Delete a card pull.
  Future<void> deleteCardPull(String productId, String pullId) {
    return _userCollection('products')
        .doc(productId)
        .collection('cardPulls')
        .doc(pullId)
        .delete();
  }

  /// Mark a product as opened (pack/box).
  Future<void> markProductOpened(String productId) {
    return _userCollection('products').doc(productId).update({
      'isOpened': true,
      'openedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Decrement a product's quantity by [amount].
  /// If the resulting quantity is <= 0, delete the product instead.
  Future<void> decrementProductQuantity(String productId, double amount) async {
    final docRef = _userCollection('products').doc(productId);
    final doc = await docRef.get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final currentQty = (data['quantity'] ?? 0).toDouble();
    final newQty = currentQty - amount;
    if (newQty <= 0) {
      await docRef.delete();
    } else {
      await docRef.update({'quantity': newQty});
    }
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

  /// Budget spent this month (net of sale refills).
  ///
  /// Logic:
  /// 1. Sum all purchases this month → gross spent
  /// 2. Sum sale revenue this month → refill amount
  /// 3. Net spent = max(0, gross spent - refill)
  ///
  /// Sales first refill the budget (recover what was spent), then any
  /// surplus counts as pure profit.
  Stream<double> getBudgetSpentThisMonth() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    // Simple approach: purchases stream, with sales fetched once per emission
    return getPurchases().asyncMap((purchases) async {
      final grossSpent = purchases
          .where((p) =>
              p.date.isAfter(monthStart) ||
              p.date.isAtSameMomentAs(monthStart))
          .fold<double>(0, (acc, p) => acc + p.totalCost);

      // Fetch latest sales snapshot
      final sales = await getSales().first;
      final saleRefill = sales
          .where((s) =>
              s.date.isAfter(monthStart) ||
              s.date.isAtSameMomentAs(monthStart))
          .fold<double>(0, (acc, s) => acc + s.salePrice);

      return (grossSpent - saleRefill).clamp(0.0, double.infinity);
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
    return _userCollection('shipments').add(shipment.toFirestore());
  }

  Future<void> updateShipment(String id, Map<String, dynamic> data) {
    return _userCollection('shipments').doc(id).update(data);
  }

  Future<void> deleteShipment(String id) {
    return _userCollection('shipments').doc(id).delete();
  }

  Stream<List<Shipment>> getShipments() {
    if (demoMode) return Stream.value(DemoDataService.shipments);
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
    return _userCollection('notifications').add(notification.toFirestore());
  }

  Stream<List<AppNotification>> getNotifications() {
    if (demoMode) return Stream.value([]);
    return _userCollection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => AppNotification.fromFirestore(doc)).toList());
  }

  Stream<int> getUnreadNotificationCount() {
    if (demoMode) return Stream.value(0);
    return _userCollection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markNotificationRead(String id) {
    return _userCollection('notifications').doc(id).update({'read': true});
  }

  Future<void> deleteNotification(String id) {
    return _userCollection('notifications').doc(id).delete();
  }

  Future<void> clearAllNotifications() async {
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
    return _db.collection('users').doc(_uid).set(data, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> getUserProfile() {
    return _db.collection('users').doc(_uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return doc.data();
    });
  }

  // ═══════════════════════════════════════════════════
  //  PROFILES
  // ═══════════════════════════════════════════════════

  CollectionReference _profilesCollection() {
    return _db.collection('users').doc(_uid).collection('profiles');
  }

  /// Stream all profiles for the current user.
  Stream<List<UserProfile>> getProfiles() {
    if (demoMode) return Stream.value(UserProfile.presets);
    return _profilesCollection()
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => UserProfile.fromFirestore(doc)).toList());
  }

  /// Add a new profile.
  Future<DocumentReference> addProfile(UserProfile profile) {
    return _profilesCollection().add(profile.toFirestore());
  }

  /// Update an existing profile by id.
  Future<void> updateProfile(String id, Map<String, dynamic> data) {
    return _profilesCollection().doc(id).update(data);
  }

  /// Delete a profile.
  Future<void> deleteProfile(String id) {
    return _profilesCollection().doc(id).delete();
  }

  /// Submit user feedback/bug report to Firestore.
  Future<void> submitFeedback(String message, {String type = 'bug'}) {
    return _db.collection('feedback').add({
      'userId': _uid,
      'type': type,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'platform': 'web',
    });
  }

  /// Get the active profile id from the user document.
  Stream<String?> getActiveProfileId() {
    if (demoMode) return Stream.value('generic');
    return _db.collection('users').doc(_uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      return data?['activeProfileId'] as String?;
    });
  }

  /// Set the active profile id on the user document.
  Future<void> setActiveProfile(String profileId) {
    return _db
        .collection('users')
        .doc(_uid)
        .set({'activeProfileId': profileId}, SetOptions(merge: true));
  }

  /// Check if the user has any profiles.
  Future<bool> hasProfiles() async {
    final snap = await _profilesCollection().limit(1).get();
    return snap.docs.isNotEmpty;
  }

  /// Create the 3 default preset profiles if the user has none.
  /// Returns the id of the first (Generico) profile.
  Future<String> initDefaultProfiles() async {
    final snap = await _profilesCollection().limit(1).get();
    if (snap.docs.isNotEmpty) {
      return snap.docs.first.id;
    }

    String firstId = '';
    for (final preset in UserProfile.presets) {
      final ref = await _profilesCollection().add(preset.toFirestore());
      if (firstId.isEmpty) firstId = ref.id;
    }

    // Set the first profile as active
    await setActiveProfile(firstId);
    return firstId;
  }

  /// Seed demo data: sample products, purchases, sales for demo mode.
  Future<void> seedDemoData() async {
    // Check if already seeded
    final existingProducts = await _userCollection('products').limit(1).get();
    if (existingProducts.docs.isNotEmpty) return;

    final now = DateTime.now();

    // Sample products — card-themed
    final products = [
      Product(
        name: 'Charizard VMAX',
        brand: 'POKÉMON',
        quantity: 1,
        price: 45,
        status: ProductStatus.inInventory,
        kind: ProductKind.singleCard,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      Product(
        name: 'Pikachu Gold Star',
        brand: 'POKÉMON',
        quantity: 1,
        price: 320,
        status: ProductStatus.listed,
        kind: ProductKind.singleCard,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Product(
        name: 'Pokémon 151 Booster Pack',
        brand: 'POKÉMON',
        quantity: 6,
        price: 4.50,
        status: ProductStatus.inInventory,
        kind: ProductKind.boosterPack,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Product(
        name: 'MTG Murders at Karlov Manor Display',
        brand: 'MTG',
        quantity: 1,
        price: 120,
        status: ProductStatus.inInventory,
        kind: ProductKind.display,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Product(
        name: 'Riftbound Starter Box',
        brand: 'RIFTBOUND',
        quantity: 2,
        price: 35,
        status: ProductStatus.inInventory,
        kind: ProductKind.boosterBox,
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      Product(
        name: 'Yu-Gi-Oh! Age of Overlord Booster Box',
        brand: 'YU-GI-OH!',
        quantity: 1,
        price: 65,
        status: ProductStatus.shipped,
        kind: ProductKind.boosterBox,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Product(
        name: 'One Piece OP-06 Booster Pack',
        brand: 'ONE PIECE',
        quantity: 10,
        price: 4,
        status: ProductStatus.inInventory,
        kind: ProductKind.boosterPack,
        isOpened: true,
        openedAt: now.subtract(const Duration(days: 4)),
        createdAt: now.subtract(const Duration(days: 6)),
      ),
    ];

    for (final p in products) {
      await addProduct(p);
    }

    // Sample purchases
    final purchases = [
      Purchase(
        productName: 'Charizard VMAX',
        price: 45,
        quantity: 1,
        date: now.subtract(const Duration(days: 10)),
        workspace: 'cards',
      ),
      Purchase(
        productName: 'Pikachu Gold Star',
        price: 320,
        quantity: 1,
        date: now.subtract(const Duration(days: 1)),
        workspace: 'cards',
      ),
      Purchase(
        productName: 'Pokémon 151 Booster Pack',
        price: 4.50,
        quantity: 6,
        date: now.subtract(const Duration(days: 5)),
        workspace: 'cards',
      ),
      Purchase(
        productName: 'MTG Murders at Karlov Manor Display',
        price: 120,
        quantity: 1,
        date: now.subtract(const Duration(days: 3)),
        workspace: 'cards',
      ),
      Purchase(
        productName: 'Riftbound Starter Box',
        price: 35,
        quantity: 2,
        date: now.subtract(const Duration(days: 7)),
        workspace: 'cards',
      ),
      Purchase(
        productName: 'Yu-Gi-Oh! Age of Overlord Booster Box',
        price: 65,
        quantity: 1,
        date: now.subtract(const Duration(days: 2)),
        workspace: 'cards',
      ),
    ];

    for (final p in purchases) {
      await addPurchase(p);
    }

    // Sample sales
    final sales = [
      Sale(
        productName: 'Umbreon VMAX Alt Art',
        salePrice: 180,
        purchasePrice: 85,
        fees: 14,
        date: now.subtract(const Duration(days: 8)),
      ),
      Sale(
        productName: 'Black Lotus (Played)',
        salePrice: 4500,
        purchasePrice: 3200,
        fees: 180,
        date: now.subtract(const Duration(days: 12)),
      ),
      Sale(
        productName: 'Luffy Leader OP-01',
        salePrice: 45,
        purchasePrice: 20,
        fees: 4,
        date: now.subtract(const Duration(days: 4)),
      ),
    ];

    for (final s in sales) {
      await addSale(s);
    }
  }
}
