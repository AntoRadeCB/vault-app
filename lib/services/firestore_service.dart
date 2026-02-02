import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../models/purchase.dart';
import '../models/sale.dart';
import '../models/shipment.dart';
import '../models/app_notification.dart';
import '../models/profile.dart';

// ═══════════════════════════════════════════════════
//  DEMO DATA — Rich sample data for unauthenticated users
//  Now organized by demo profile
// ═══════════════════════════════════════════════════
class _DemoData {
  static final _now = DateTime.now();

  // ─── Demo Profiles ─────────────────────────────────
  static List<Profile> get profiles => [
        Profile(
          id: 'demo_profile_1',
          name: 'Reselling Vinted',
          features: ['reselling', 'shipping', 'analytics', 'inventory', 'pricing', 'collecting'],
          platforms: ['vinted', 'ebay', 'depop'],
          category: 'generic',
          experienceLevel: 'intermediate',
          budget: 500,
          createdAt: _now.subtract(const Duration(days: 30)),
        ),
        Profile(
          id: 'demo_profile_2',
          name: 'Pokémon TCG',
          features: ['collecting', 'analytics', 'inventory', 'pricing'],
          platforms: ['cardmarket', 'ebay'],
          category: 'cards',
          experienceLevel: 'expert',
          budget: 200,
          createdAt: _now.subtract(const Duration(days: 20)),
        ),
        Profile(
          id: 'demo_profile_3',
          name: 'Sneaker Vault',
          features: ['reselling', 'shipping', 'analytics', 'inventory', 'pricing'],
          platforms: ['stockx', 'goat', 'ebay'],
          category: 'sneakers',
          experienceLevel: 'intermediate',
          budget: 1000,
          createdAt: _now.subtract(const Duration(days: 15)),
        ),
      ];

  // ─── Profile 1: Reselling Vinted (generic) ─────────
  static List<Product> get productsGeneric => [
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

  static List<Sale> get salesGeneric => [
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

  static List<Purchase> get purchasesGeneric => [
        Purchase(
          id: 'demo_pu1',
          productName: 'Nike Air Max 90',
          price: 45,
          quantity: 1,
          date: _now.subtract(const Duration(days: 2)),
          workspace: 'Reselling Vinted',
        ),
        Purchase(
          id: 'demo_pu2',
          productName: 'Adidas Forum Low',
          price: 65,
          quantity: 2,
          date: _now.subtract(const Duration(days: 5)),
          workspace: 'Reselling Vinted',
        ),
        Purchase(
          id: 'demo_pu3',
          productName: 'Stone Island Hoodie',
          price: 120,
          quantity: 1,
          date: _now.subtract(const Duration(days: 8)),
          workspace: 'Reselling Vinted',
        ),
        Purchase(
          id: 'demo_pu4',
          productName: 'Supreme Box Logo Tee',
          price: 85,
          quantity: 1,
          date: _now.subtract(const Duration(days: 3)),
          workspace: 'Reselling Vinted',
        ),
        Purchase(
          id: 'demo_pu5',
          productName: 'Jordan 4 Retro',
          price: 190,
          quantity: 1,
          date: _now.subtract(const Duration(days: 1)),
          workspace: 'Reselling Vinted',
        ),
        Purchase(
          id: 'demo_pu6',
          productName: 'The North Face Nuptse',
          price: 150,
          quantity: 1,
          date: _now.subtract(const Duration(days: 12)),
          workspace: 'Reselling Vinted',
        ),
      ];

  static List<Shipment> get shipmentsGeneric => [
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

  static List<AppNotification> get notificationsGeneric => [
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

  // ─── Profile 2: Pokémon TCG (cards) ────────────────
  static List<Product> get productsCards => [
        Product(
          id: 'demo_cp1',
          name: 'Charizard VMAX',
          brand: 'POKÉMON',
          quantity: 1,
          price: 280,
          status: ProductStatus.inInventory,
          createdAt: _now.subtract(const Duration(days: 3)),
        ),
        Product(
          id: 'demo_cp2',
          name: 'Pikachu Gold Star',
          brand: 'POKÉMON',
          quantity: 1,
          price: 450,
          status: ProductStatus.listed,
          createdAt: _now.subtract(const Duration(days: 7)),
        ),
        Product(
          id: 'demo_cp3',
          name: 'Mewtwo GX',
          brand: 'POKÉMON',
          quantity: 2,
          price: 35,
          status: ProductStatus.inInventory,
          createdAt: _now.subtract(const Duration(days: 10)),
        ),
        Product(
          id: 'demo_cp4',
          name: 'Booster Box Base Set',
          brand: 'POKÉMON',
          quantity: 1,
          price: 8500,
          status: ProductStatus.inInventory,
          createdAt: _now.subtract(const Duration(days: 14)),
        ),
        Product(
          id: 'demo_cp5',
          name: 'Trainer Gallery Lot',
          brand: 'POKÉMON',
          quantity: 15,
          price: 12,
          status: ProductStatus.listed,
          createdAt: _now.subtract(const Duration(days: 1)),
        ),
      ];

  static List<Sale> get salesCards => [
        Sale(
          id: 'demo_cs1',
          productName: 'Umbreon VMAX Alt Art',
          salePrice: 320,
          purchasePrice: 180,
          fees: 16,
          date: _now.subtract(const Duration(days: 5)),
        ),
        Sale(
          id: 'demo_cs2',
          productName: 'Eevee Heroes Booster Box',
          salePrice: 210,
          purchasePrice: 140,
          fees: 10,
          date: _now.subtract(const Duration(days: 12)),
        ),
        Sale(
          id: 'demo_cs3',
          productName: 'Rayquaza V Alt Art',
          salePrice: 150,
          purchasePrice: 85,
          fees: 8,
          date: _now.subtract(const Duration(days: 18)),
        ),
      ];

  static List<Purchase> get purchasesCards => [
        Purchase(
          id: 'demo_cpu1',
          productName: 'Charizard VMAX',
          price: 280,
          quantity: 1,
          date: _now.subtract(const Duration(days: 3)),
          workspace: 'Pokémon TCG',
        ),
        Purchase(
          id: 'demo_cpu2',
          productName: 'Pikachu Gold Star',
          price: 450,
          quantity: 1,
          date: _now.subtract(const Duration(days: 7)),
          workspace: 'Pokémon TCG',
        ),
        Purchase(
          id: 'demo_cpu3',
          productName: 'Booster Box Base Set',
          price: 8500,
          quantity: 1,
          date: _now.subtract(const Duration(days: 14)),
          workspace: 'Pokémon TCG',
        ),
      ];

  static List<Shipment> get shipmentsCards => [];

  static List<AppNotification> get notificationsCards => [
        AppNotification(
          id: 'demo_cn1',
          title: 'Nuova vendita!',
          body: 'Hai venduto "Umbreon VMAX Alt Art" per €320. Profitto: €124 🎉',
          type: NotificationType.sale,
          createdAt: _now.subtract(const Duration(days: 5)),
          read: false,
        ),
        AppNotification(
          id: 'demo_cn2',
          title: 'Prezzo in crescita',
          body: 'Il valore di "Charizard VMAX" è salito del 15% questa settimana.',
          type: NotificationType.system,
          createdAt: _now.subtract(const Duration(days: 2)),
          read: false,
        ),
      ];

  // ─── Profile 3: Sneaker Vault (sneakers) ───────────
  static List<Product> get productsSneakers => [
        Product(
          id: 'demo_sp1',
          name: 'Jordan 1 Retro High OG',
          brand: 'JORDAN',
          quantity: 1,
          price: 170,
          status: ProductStatus.inInventory,
          createdAt: _now.subtract(const Duration(days: 2)),
        ),
        Product(
          id: 'demo_sp2',
          name: 'Yeezy 350 V2 Zebra',
          brand: 'ADIDAS',
          quantity: 1,
          price: 230,
          status: ProductStatus.shipped,
          createdAt: _now.subtract(const Duration(days: 4)),
        ),
        Product(
          id: 'demo_sp3',
          name: 'Nike Dunk Low Panda',
          brand: 'NIKE',
          quantity: 2,
          price: 110,
          status: ProductStatus.listed,
          createdAt: _now.subtract(const Duration(days: 6)),
        ),
        Product(
          id: 'demo_sp4',
          name: 'Air Max 90 OG',
          brand: 'NIKE',
          quantity: 1,
          price: 140,
          status: ProductStatus.inInventory,
          createdAt: _now.subtract(const Duration(days: 9)),
        ),
        Product(
          id: 'demo_sp5',
          name: 'New Balance 550',
          brand: 'NEW BALANCE',
          quantity: 1,
          price: 120,
          status: ProductStatus.listed,
          createdAt: _now.subtract(const Duration(days: 11)),
        ),
      ];

  static List<Sale> get salesSneakers => [
        Sale(
          id: 'demo_ss1',
          productName: 'Jordan 4 Black Cat',
          salePrice: 420,
          purchasePrice: 280,
          fees: 42,
          date: _now.subtract(const Duration(days: 3)),
        ),
        Sale(
          id: 'demo_ss2',
          productName: 'Nike SB Dunk Low Travis Scott',
          salePrice: 1200,
          purchasePrice: 850,
          fees: 120,
          date: _now.subtract(const Duration(days: 10)),
        ),
        Sale(
          id: 'demo_ss3',
          productName: 'Yeezy 700 Wave Runner',
          salePrice: 350,
          purchasePrice: 220,
          fees: 35,
          date: _now.subtract(const Duration(days: 16)),
        ),
      ];

  static List<Purchase> get purchasesSneakers => [
        Purchase(
          id: 'demo_spu1',
          productName: 'Jordan 1 Retro High OG',
          price: 170,
          quantity: 1,
          date: _now.subtract(const Duration(days: 2)),
          workspace: 'Sneaker Vault',
        ),
        Purchase(
          id: 'demo_spu2',
          productName: 'Yeezy 350 V2 Zebra',
          price: 230,
          quantity: 1,
          date: _now.subtract(const Duration(days: 4)),
          workspace: 'Sneaker Vault',
        ),
        Purchase(
          id: 'demo_spu3',
          productName: 'Nike Dunk Low Panda',
          price: 110,
          quantity: 2,
          date: _now.subtract(const Duration(days: 6)),
          workspace: 'Sneaker Vault',
        ),
        Purchase(
          id: 'demo_spu4',
          productName: 'Air Max 90 OG',
          price: 140,
          quantity: 1,
          date: _now.subtract(const Duration(days: 9)),
          workspace: 'Sneaker Vault',
        ),
      ];

  static List<Shipment> get shipmentsSneakers => [
        Shipment(
          id: 'demo_ssh1',
          trackingCode: '1Z888BB20234567890',
          carrier: 'ups',
          carrierName: 'UPS',
          type: ShipmentType.purchase,
          productName: 'Yeezy 350 V2 Zebra',
          status: ShipmentStatus.inTransit,
          createdAt: _now.subtract(const Duration(days: 3)),
          lastUpdate: _now.subtract(const Duration(hours: 12)),
          lastEvent: 'In transito — Hub di Amsterdam',
          trackingHistory: [
            TrackingEvent(
              status: 'In transito',
              timestamp: _now.subtract(const Duration(hours: 12)),
              location: 'Amsterdam, NL',
              description: 'Il pacco è stato processato',
            ),
            TrackingEvent(
              status: 'Spedito',
              timestamp: _now.subtract(const Duration(days: 2)),
              location: 'Londra, UK',
              description: 'Il pacco è stato spedito',
            ),
          ],
        ),
        Shipment(
          id: 'demo_ssh2',
          trackingCode: 'RR987654321IT',
          carrier: 'poste_italiane',
          carrierName: 'Poste Italiane',
          type: ShipmentType.sale,
          productName: 'Nike Dunk Low Panda',
          status: ShipmentStatus.pending,
          createdAt: _now.subtract(const Duration(hours: 6)),
          lastEvent: 'Etichetta creata',
        ),
      ];

  static List<AppNotification> get notificationsSneakers => [
        AppNotification(
          id: 'demo_sn1',
          title: 'Nuova vendita!',
          body: 'Hai venduto "Jordan 4 Black Cat" per €420. Profitto: €98 🔥',
          type: NotificationType.sale,
          createdAt: _now.subtract(const Duration(days: 3)),
          read: false,
        ),
        AppNotification(
          id: 'demo_sn2',
          title: 'Spedizione in transito',
          body: 'Il tuo ordine "Yeezy 350 V2 Zebra" è in transito da Amsterdam.',
          type: NotificationType.shipmentUpdate,
          createdAt: _now.subtract(const Duration(hours: 12)),
          read: false,
        ),
        AppNotification(
          id: 'demo_sn3',
          title: 'Drop imminente',
          body: 'Nike Dunk Low "Panda" restock previsto per domani alle 10:00.',
          type: NotificationType.system,
          createdAt: _now.subtract(const Duration(hours: 2)),
          read: false,
        ),
      ];

  // ─── Helper: get data by profile ID ────────────────
  static List<Product> productsForProfile(String profileId) {
    switch (profileId) {
      case 'demo_profile_2':
        return productsCards;
      case 'demo_profile_3':
        return productsSneakers;
      case 'demo_profile_1':
      default:
        return productsGeneric;
    }
  }

  static List<Sale> salesForProfile(String profileId) {
    switch (profileId) {
      case 'demo_profile_2':
        return salesCards;
      case 'demo_profile_3':
        return salesSneakers;
      case 'demo_profile_1':
      default:
        return salesGeneric;
    }
  }

  static List<Purchase> purchasesForProfile(String profileId) {
    switch (profileId) {
      case 'demo_profile_2':
        return purchasesCards;
      case 'demo_profile_3':
        return purchasesSneakers;
      case 'demo_profile_1':
      default:
        return purchasesGeneric;
    }
  }

  static List<Shipment> shipmentsForProfile(String profileId) {
    switch (profileId) {
      case 'demo_profile_2':
        return shipmentsCards;
      case 'demo_profile_3':
        return shipmentsSneakers;
      case 'demo_profile_1':
      default:
        return shipmentsGeneric;
    }
  }

  static List<AppNotification> notificationsForProfile(String profileId) {
    switch (profileId) {
      case 'demo_profile_2':
        return notificationsCards;
      case 'demo_profile_3':
        return notificationsSneakers;
      case 'demo_profile_1':
      default:
        return notificationsGeneric;
    }
  }
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Currently active profile ID for authenticated users
  static String? activeProfileId;

  /// Currently active demo profile ID for demo mode
  static String activeDemoProfileId = 'demo_profile_1';

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Whether the service is in demo mode (no authenticated user)
  bool get isDemoMode => _uid == null;

  /// The effective profile ID (demo or real)
  String? get _effectiveProfileId =>
      isDemoMode ? activeDemoProfileId : activeProfileId;

  // ─── Helper: user-scoped collection through profile ─
  CollectionReference _userCollection(String collection) {
    final profileId = _effectiveProfileId;
    if (profileId != null && profileId.isNotEmpty) {
      return _db
          .collection('users')
          .doc(_uid)
          .collection('profiles')
          .doc(profileId)
          .collection(collection);
    }
    // Fallback: old-style direct under user (for migration)
    return _db.collection('users').doc(_uid).collection(collection);
  }

  // ═══════════════════════════════════════════════════
  //  PROFILES
  // ═══════════════════════════════════════════════════

  /// Get all profiles for current user
  Stream<List<Profile>> getProfiles() {
    if (isDemoMode) return Stream.value(_DemoData.profiles);
    return _db
        .collection('users')
        .doc(_uid)
        .collection('profiles')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Profile.fromFirestore(doc)).toList());
  }

  /// Get all profiles once (future)
  Future<List<Profile>> getProfilesOnce() async {
    if (isDemoMode) return _DemoData.profiles;
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('profiles')
        .orderBy('createdAt', descending: false)
        .get();
    return snap.docs.map((doc) => Profile.fromFirestore(doc)).toList();
  }

  /// Add a new profile
  Future<DocumentReference> addProfile(Profile profile) {
    if (isDemoMode) return Future.error('demo');
    return _db
        .collection('users')
        .doc(_uid)
        .collection('profiles')
        .add(profile.toFirestore());
  }

  /// Update a profile
  Future<void> updateProfile(String id, Map<String, dynamic> data) {
    if (isDemoMode) return Future.error('demo');
    return _db
        .collection('users')
        .doc(_uid)
        .collection('profiles')
        .doc(id)
        .update(data);
  }

  /// Delete a profile
  Future<void> deleteProfile(String id) {
    if (isDemoMode) return Future.error('demo');
    return _db
        .collection('users')
        .doc(_uid)
        .collection('profiles')
        .doc(id)
        .delete();
  }

  /// Set active profile (updates user doc and static field)
  Future<void> setActiveProfile(String profileId) async {
    if (isDemoMode) {
      activeDemoProfileId = profileId;
      return;
    }
    activeProfileId = profileId;
    await _db.collection('users').doc(_uid).set(
      {'activeProfileId': profileId},
      SetOptions(merge: true),
    );
  }

  /// Get active profile object
  Future<Profile?> getActiveProfile() async {
    if (isDemoMode) {
      try {
        return _DemoData.profiles
            .firstWhere((p) => p.id == activeDemoProfileId);
      } catch (_) {
        return _DemoData.profiles.first;
      }
    }

    if (activeProfileId == null || activeProfileId!.isEmpty) {
      // Try to load from user doc
      final userDoc = await _db.collection('users').doc(_uid).get();
      final data = userDoc.data();
      if (data != null && data['activeProfileId'] != null) {
        activeProfileId = data['activeProfileId'];
      }
    }

    if (activeProfileId == null || activeProfileId!.isEmpty) return null;

    final doc = await _db
        .collection('users')
        .doc(_uid)
        .collection('profiles')
        .doc(activeProfileId)
        .get();
    if (!doc.exists) return null;
    return Profile.fromFirestore(doc);
  }

  /// Get a single profile by ID
  Future<Profile?> getProfileById(String profileId) async {
    if (isDemoMode) {
      try {
        return _DemoData.profiles.firstWhere((p) => p.id == profileId);
      } catch (_) {
        return null;
      }
    }
    final doc = await _db
        .collection('users')
        .doc(_uid)
        .collection('profiles')
        .doc(profileId)
        .get();
    if (!doc.exists) return null;
    return Profile.fromFirestore(doc);
  }

  /// Migrate old-style data (products directly under user) to a default profile
  Future<void> migrateToProfiles() async {
    if (isDemoMode) return;

    // Check if user already has profiles
    final profilesSnap = await _db
        .collection('users')
        .doc(_uid)
        .collection('profiles')
        .limit(1)
        .get();

    if (profilesSnap.docs.isNotEmpty) return; // Already has profiles

    // Check if user has old-style products
    final oldProducts = await _db
        .collection('users')
        .doc(_uid)
        .collection('products')
        .limit(1)
        .get();

    if (oldProducts.docs.isEmpty) return; // No old data to migrate

    // Create default profile
    final profileRef = await addProfile(Profile(
      name: 'Profilo principale',
      features: ['reselling', 'shipping', 'analytics', 'inventory', 'pricing', 'collecting'],
      category: 'generic',
      experienceLevel: 'intermediate',
      createdAt: DateTime.now(),
    ));

    final newProfileId = profileRef.id;

    // Migrate products
    final collections = ['products', 'sales', 'purchases', 'shipments', 'notifications'];
    for (final collection in collections) {
      final oldDocs = await _db
          .collection('users')
          .doc(_uid)
          .collection(collection)
          .get();

      final batch = _db.batch();
      for (final doc in oldDocs.docs) {
        final newRef = _db
            .collection('users')
            .doc(_uid)
            .collection('profiles')
            .doc(newProfileId)
            .collection(collection)
            .doc(doc.id);
        batch.set(newRef, doc.data());
      }
      await batch.commit();

      // Delete old docs
      final deleteBatch = _db.batch();
      for (final doc in oldDocs.docs) {
        deleteBatch.delete(doc.reference);
      }
      await deleteBatch.commit();
    }

    // Set as active profile
    await setActiveProfile(newProfileId);
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
    if (isDemoMode) {
      return Stream.value(_DemoData.productsForProfile(activeDemoProfileId));
    }
    return _userCollection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  Future<Product?> getProductById(String id) async {
    if (isDemoMode) {
      try {
        return _DemoData.productsForProfile(activeDemoProfileId)
            .firstWhere((p) => p.id == id);
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
    if (isDemoMode) {
      return Stream.value(_DemoData.purchasesForProfile(activeDemoProfileId));
    }
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
    if (isDemoMode) {
      return Stream.value(_DemoData.salesForProfile(activeDemoProfileId));
    }
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
  //  BUDGET STATS
  // ═══════════════════════════════════════════════════

  /// Compute budget stats from profile budget + all purchases/sales chronologically.
  /// Returns {'budget': currentBudget, 'ricavi': ricavi, 'maxBudget': maxBudget}
  Stream<Map<String, double>> getBudgetStats(double maxBudget) {
    if (maxBudget <= 0) {
      return Stream.value({'budget': 0.0, 'ricavi': 0.0, 'maxBudget': 0.0});
    }

    return getCombinedSalesPurchases().map((data) {
      final sales = data['sales'] as List<Sale>;
      final purchases = data['purchases'] as List<Purchase>;

      // Merge into a single chronological timeline
      final List<_BudgetEvent> events = [];
      for (final p in purchases) {
        events.add(_BudgetEvent(date: p.date, amount: -p.totalCost));
      }
      for (final s in sales) {
        events.add(_BudgetEvent(date: s.date, amount: s.salePrice));
      }
      events.sort((a, b) => a.date.compareTo(b.date));

      double currentBudget = maxBudget;
      double ricavi = 0.0;

      for (final event in events) {
        currentBudget += event.amount;
        if (currentBudget > maxBudget) {
          ricavi += (currentBudget - maxBudget);
          currentBudget = maxBudget;
        }
      }

      return {
        'budget': currentBudget,
        'ricavi': ricavi,
        'maxBudget': maxBudget,
      };
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
    if (isDemoMode) {
      return Stream.value(_DemoData.shipmentsForProfile(activeDemoProfileId));
    }
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
        return _DemoData.shipmentsForProfile(activeDemoProfileId)
            .firstWhere((s) => s.trackingCode == code);
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
    if (isDemoMode) {
      return Stream.value(
          _DemoData.notificationsForProfile(activeDemoProfileId));
    }
    return _userCollection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => AppNotification.fromFirestore(doc)).toList());
  }

  Stream<int> getUnreadNotificationCount() {
    if (isDemoMode) {
      return Stream.value(
          _DemoData.notificationsForProfile(activeDemoProfileId)
              .where((n) => !n.read)
              .length);
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

/// Helper class for budget timeline events
class _BudgetEvent {
  final DateTime date;
  final double amount; // negative for purchases, positive for sales

  const _BudgetEvent({required this.date, required this.amount});
}
