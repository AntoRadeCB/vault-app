import '../models/product.dart';
import '../models/purchase.dart';
import '../models/sale.dart';
import '../models/shipment.dart';
import '../models/card_blueprint.dart';
import '../services/card_catalog_service.dart';

/// Provides sample data for demo mode (no auth needed).
/// Call [init] once at startup to populate demo cards from the real catalog.
/// All data is in-memory — nothing touches Firestore user collections.
class DemoDataService {
  // Mutable lists — replaced by init() with real catalog data
  static List<Product> products = List<Product>.from(_defaultProducts);
  static List<Purchase> purchases = List<Purchase>.from(_defaultPurchases);

  /// Call once at startup to populate demo single-card data from real catalog.
  /// Falls back to static data on failure.
  static Future<void> init() async {
    try {
      final catalog = CardCatalogService();
      final allCards = await catalog.getAllCards();
      final riftboundCards = allCards
          .where((c) =>
              c.game?.toLowerCase() == 'riftbound' &&
              (c.kind == null || c.kind == 'singleCard'))
          .toList();

      if (riftboundCards.length >= 5) {
        // Pick cards from different rarities for variety
        final byRarity = <String, List<CardBlueprint>>{};
        for (final c in riftboundCards) {
          byRarity.putIfAbsent(c.rarity ?? 'common', () => []).add(c);
        }

        final picked = <CardBlueprint>[];
        for (final rarity in [
          'epic',
          'alternate art',
          'rare',
          'uncommon',
          'common'
        ]) {
          final cards = byRarity[rarity];
          if (cards != null && cards.isNotEmpty) {
            picked.add(cards.first);
            if (picked.length >= 5) break;
          }
        }
        // Fill rest if needed
        while (picked.length < 5) {
          for (final c in riftboundCards) {
            if (!picked.contains(c)) {
              picked.add(c);
              break;
            }
          }
          if (picked.length >= 5) break;
          break; // safety
        }

        // Build demo products from real catalog cards
        final demoCards = <Product>[];
        for (var i = 0; i < picked.length; i++) {
          final c = picked[i];
          final priceVal = c.marketPrice != null
              ? c.marketPrice!.cents / 100
              : 2.0;
          final qty = (i % 3) + 1; // 1, 2, 3 copies
          demoCards.add(Product(
            id: 'demo-${c.id}',
            name: c.name,
            brand: 'RIFTBOUND',
            quantity: qty.toDouble(),
            price: priceVal,
            status: i == 1 ? ProductStatus.listed : ProductStatus.inInventory,
            kind: ProductKind.singleCard,
            cardBlueprintId: c.id,
            cardImageUrl: c.imageUrl,
            cardExpansion: c.expansionName,
            cardRarity: c.rarity,
            marketPrice: c.marketPrice != null
                ? c.marketPrice!.cents / 100
                : null,
            createdAt:
                DateTime.now().subtract(Duration(days: i + 1)),
          ));
        }

        // Replace single-card products, keep sealed products
        products = [
          ...demoCards,
          ..._defaultProducts
              .where((p) => p.kind != ProductKind.singleCard),
        ];

        // Rebuild purchases to match
        purchases = products
            .map((p) => Purchase(
                  id: 'demo-p-${p.id}',
                  productName: p.name,
                  price: p.price * p.quantity,
                  quantity: p.quantity,
                  date: p.createdAt ?? DateTime.now(),
                  workspace: 'default',
                ))
            .toList();
      }
    } catch (_) {
      // Keep default static data on failure — catalog may not be reachable
    }
  }

  // ── Static fallback data ──

  static final List<Product> _defaultProducts = [
    Product(
      id: 'demo-1',
      name: 'Lyra, Keeper of the Veil',
      brand: 'RIFTBOUND',
      quantity: 1,
      price: 12.50,
      status: ProductStatus.inInventory,
      kind: ProductKind.singleCard,
      cardBlueprintId: 'rb-lyra-001',
      cardExpansion: 'Riftbound',
      cardRarity: 'epic',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Product(
      id: 'demo-2',
      name: 'Drakar, the Riftwalker',
      brand: 'RIFTBOUND',
      quantity: 1,
      price: 28.00,
      status: ProductStatus.listed,
      kind: ProductKind.singleCard,
      cardBlueprintId: 'rb-drakar-002',
      cardExpansion: 'Riftbound',
      cardRarity: 'alternate art',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Product(
      id: 'demo-3',
      name: 'Sentinel of the Breach',
      brand: 'RIFTBOUND',
      quantity: 2,
      price: 3.20,
      status: ProductStatus.inInventory,
      kind: ProductKind.singleCard,
      cardBlueprintId: 'rb-sentinel-003',
      cardExpansion: 'Riftbound',
      cardRarity: 'rare',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Product(
      id: 'demo-4',
      name: 'Void Shard Elemental',
      brand: 'RIFTBOUND',
      quantity: 3,
      price: 1.50,
      status: ProductStatus.inInventory,
      kind: ProductKind.singleCard,
      cardBlueprintId: 'rb-voidshard-004',
      cardExpansion: 'Riftbound',
      cardRarity: 'uncommon',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Product(
      id: 'demo-5',
      name: 'Riftbound Starter Box',
      brand: 'RIFTBOUND',
      quantity: 2,
      price: 35,
      status: ProductStatus.inInventory,
      kind: ProductKind.boosterBox,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    Product(
      id: 'demo-6',
      name: 'Riftbound Booster Pack',
      brand: 'RIFTBOUND',
      quantity: 6,
      price: 4.50,
      status: ProductStatus.inInventory,
      kind: ProductKind.boosterPack,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    Product(
      id: 'demo-7',
      name: 'Riftbound Booster Pack',
      brand: 'RIFTBOUND',
      quantity: 10,
      price: 4.50,
      status: ProductStatus.inInventory,
      kind: ProductKind.boosterPack,
      isOpened: true,
      openedAt: DateTime.now().subtract(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
  ];

  static final List<Purchase> _defaultPurchases = [
    Purchase(
      id: 'demo-p1',
      productName: 'Lyra, Keeper of the Veil',
      price: 12.50,
      quantity: 1,
      date: DateTime.now().subtract(const Duration(days: 10)),
      workspace: 'default',
    ),
    Purchase(
      id: 'demo-p2',
      productName: 'Drakar, the Riftwalker',
      price: 28.00,
      quantity: 1,
      date: DateTime.now().subtract(const Duration(days: 1)),
      workspace: 'default',
    ),
    Purchase(
      id: 'demo-p3',
      productName: 'Sentinel of the Breach',
      price: 3.20,
      quantity: 2,
      date: DateTime.now().subtract(const Duration(days: 5)),
      workspace: 'default',
    ),
    Purchase(
      id: 'demo-p4',
      productName: 'Riftbound Starter Box',
      price: 35,
      quantity: 2,
      date: DateTime.now().subtract(const Duration(days: 7)),
      workspace: 'default',
    ),
    Purchase(
      id: 'demo-p5',
      productName: 'Riftbound Booster Pack',
      price: 4.50,
      quantity: 16,
      date: DateTime.now().subtract(const Duration(days: 4)),
      workspace: 'default',
    ),
  ];

  static final List<Sale> sales = [
    Sale(
      id: 'demo-s1',
      productName: 'Aetheris, Planar Sovereign',
      salePrice: 45,
      purchasePrice: 18,
      fees: 4,
      date: DateTime.now().subtract(const Duration(days: 8)),
    ),
    Sale(
      id: 'demo-s2',
      productName: 'Riftbound Collector Bundle',
      salePrice: 120,
      purchasePrice: 75,
      fees: 10,
      date: DateTime.now().subtract(const Duration(days: 12)),
    ),
    Sale(
      id: 'demo-s3',
      productName: 'Void Shard Elemental (Foil)',
      salePrice: 8.50,
      purchasePrice: 3,
      fees: 1,
      date: DateTime.now().subtract(const Duration(days: 4)),
    ),
    Sale(
      id: 'demo-s4',
      productName: 'Riftbound Promo Pack',
      salePrice: 28,
      purchasePrice: 12,
      fees: 2,
      date: DateTime.now().subtract(const Duration(days: 6)),
    ),
  ];

  static final List<Shipment> shipments = [
    Shipment(
      id: 'demo-sh1',
      trackingCode: 'BRT-123456789',
      carrier: 'brt',
      carrierName: 'BRT',
      type: ShipmentType.purchase,
      status: ShipmentStatus.inTransit,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      productName: 'Riftbound Starter Box',
      trackingHistory: [
        TrackingEvent(
          status: 'Pacco ritirato',
          location: 'Milano',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
        ),
        TrackingEvent(
          status: 'In transito',
          location: 'Bologna Hub',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
    ),
    Shipment(
      id: 'demo-sh2',
      trackingCode: 'GLS-987654321',
      carrier: 'gls',
      carrierName: 'GLS',
      type: ShipmentType.sale,
      status: ShipmentStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      productName: 'Drakar, the Riftwalker',
    ),
  ];

  // ── Computed stats (mirrors FirestoreService API) ──

  static double get capitaleImmobilizzato => products
      .where((p) => p.status == ProductStatus.inInventory)
      .fold(0.0, (acc, p) => acc + (p.price * p.quantity));

  static double get ordiniInArrivo => products
      .where((p) => p.status == ProductStatus.shipped)
      .fold(0.0, (acc, p) => acc + (p.price * p.quantity));

  static double get capitaleSpedito => products
      .where((p) => p.status == ProductStatus.listed)
      .fold(0.0, (acc, p) => acc + (p.price * p.quantity));

  static double get profittoConsolidato =>
      sales.fold(0.0, (acc, s) => acc + s.profit);

  static double get totalRevenue =>
      sales.fold(0.0, (acc, s) => acc + s.salePrice);

  static double get totalSpent =>
      purchases.fold(0.0, (acc, p) => acc + p.totalCost);

  static double get totalFees =>
      sales.fold(0.0, (acc, s) => acc + s.fees);

  static double get avgProfitPerSale =>
      sales.isEmpty ? 0 : profittoConsolidato / sales.length;

  static double get roi =>
      totalSpent == 0 ? 0 : (profittoConsolidato / totalSpent) * 100;
}
