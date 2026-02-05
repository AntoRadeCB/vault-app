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

  /// Call once at startup to populate demo data from real catalog.
  /// Picks cards from multiple expansions (Origins + Spiritforged).
  /// Falls back to static data on failure.
  static Future<void> init() async {
    try {
      final catalog = CardCatalogService();
      final allCards = await catalog.getAllCards();
      final riftboundSingles = allCards
          .where((c) =>
              c.game?.toLowerCase() == 'riftbound' &&
              (c.kind == null || c.kind == 'singleCard'))
          .toList();

      if (riftboundSingles.length >= 10) {
        // ── 1. Group cards by expansion ──
        final byExpansion = <String, List<CardBlueprint>>{};
        for (final c in riftboundSingles) {
          final exp = (c.expansionName ?? 'Unknown').toLowerCase();
          byExpansion.putIfAbsent(exp, () => []).add(c);
        }

        // Find Origins and Spiritforged expansions (case-insensitive)
        List<CardBlueprint> originsCards = [];
        List<CardBlueprint> spiritforgedCards = [];
        String originsName = 'Origins';
        String spiritforgedName = 'Spiritforged';

        for (final entry in byExpansion.entries) {
          if (entry.key.contains('origin')) {
            originsCards = entry.value;
            originsName = entry.value.first.expansionName ?? originsName;
          } else if (entry.key.contains('spiritforge')) {
            spiritforgedCards = entry.value;
            spiritforgedName = entry.value.first.expansionName ?? spiritforgedName;
          }
        }

        // ── 2. Pick cards from each expansion by rarity ──
        List<CardBlueprint> _pickFromExpansion(List<CardBlueprint> cards, int target) {
          final byRarity = <String, List<CardBlueprint>>{};
          for (final c in cards) {
            byRarity.putIfAbsent((c.rarity ?? 'common').toLowerCase(), () => []).add(c);
          }
          final picked = <CardBlueprint>[];
          for (final rarity in ['epic', 'alternate art', 'overnumbered', 'rare', 'uncommon', 'common']) {
            final pool = byRarity[rarity];
            if (pool == null) continue;
            final take = rarity == 'common' ? 3 : (rarity == 'uncommon' ? 2 : 1);
            for (var i = 0; i < take && i < pool.length && picked.length < target; i++) {
              picked.add(pool[i]);
            }
          }
          // Fill up if needed
          if (picked.length < target) {
            for (final c in cards) {
              if (!picked.contains(c)) {
                picked.add(c);
                if (picked.length >= target) break;
              }
            }
          }
          return picked;
        }

        // Pick ~10 from Origins, ~8 from Spiritforged
        final originsSelected = originsCards.isNotEmpty ? _pickFromExpansion(originsCards, 10) : <CardBlueprint>[];
        final spiritforgedSelected = spiritforgedCards.isNotEmpty ? _pickFromExpansion(spiritforgedCards, 8) : <CardBlueprint>[];
        final allPicked = [...originsSelected, ...spiritforgedSelected];

        // Fallback: if neither expansion found, pick from all singles
        if (allPicked.isEmpty) {
          allPicked.addAll(_pickFromExpansion(riftboundSingles, 15));
        }

        // ── 3. Build demo single-card products ──
        final demoCards = <Product>[];
        for (var i = 0; i < allPicked.length; i++) {
          final c = allPicked[i];
          final priceVal = c.marketPrice != null
              ? c.marketPrice!.cents / 100
              : 2.0;
          // Vary quantities: 1-4 copies
          final qty = [1, 2, 1, 3, 1, 2, 4, 1, 2, 1, 3, 1, 2, 1, 1, 2, 3, 1][i % 18];
          // Some in inventory (inventoryQty > 0)
          final hasInventory = i % 3 == 0; // every 3rd card
          final isListed = i == 2 || i == 11;
          demoCards.add(Product(
            id: 'demo-${c.id}',
            name: c.name,
            brand: 'RIFTBOUND',
            quantity: qty.toDouble(),
            price: priceVal,
            status: isListed ? ProductStatus.listed : ProductStatus.inInventory,
            kind: ProductKind.singleCard,
            cardBlueprintId: c.id,
            cardImageUrl: c.imageUrl,
            cardExpansion: c.expansionName,
            cardRarity: c.rarity,
            marketPrice: c.marketPrice != null
                ? c.marketPrice!.cents / 100
                : null,
            inventoryQty: hasInventory ? 1 : 0,
            createdAt: DateTime.now().subtract(Duration(days: i + 1)),
          ));
        }

        // ── 4. Find sealed products — prefer Spiritforged expansion ──
        final sealedFromCatalog = allCards.where((c) =>
            c.game?.toLowerCase() == 'riftbound' &&
            c.kind != null &&
            c.kind != 'singleCard').toList();

        // Prefer sealed from Spiritforged, fallback to any
        final sealedExpName = spiritforgedCards.isNotEmpty
            ? spiritforgedName
            : (originsCards.isNotEmpty ? originsName : 'Riftbound');

        CardBlueprint? findSealed(String kind, [String? preferExpansion]) {
          if (preferExpansion != null) {
            final match = sealedFromCatalog.where((c) =>
                c.kind == kind &&
                c.expansionName?.toLowerCase() == preferExpansion.toLowerCase()).firstOrNull;
            if (match != null) return match;
          }
          return sealedFromCatalog.where((c) => c.kind == kind).firstOrNull;
        }

        final catalogPack = findSealed('boosterPack', sealedExpName);
        final catalogBox = findSealed('boosterBox', sealedExpName);

        final sealedProducts = <Product>[
          Product(
            id: 'demo-sealed-box',
            name: catalogBox?.name ?? 'Riftbound Booster Box',
            brand: 'RIFTBOUND',
            quantity: 2,
            price: 35,
            status: ProductStatus.inInventory,
            kind: ProductKind.boosterBox,
            cardExpansion: catalogBox?.expansionName ?? sealedExpName,
            cardImageUrl: catalogBox?.imageUrl,
            cardBlueprintId: catalogBox?.id,
            createdAt: DateTime.now().subtract(const Duration(days: 7)),
          ),
          Product(
            id: 'demo-sealed-pack',
            name: catalogPack?.name ?? 'Riftbound Booster Pack',
            brand: 'RIFTBOUND',
            quantity: 6,
            price: 4.50,
            status: ProductStatus.inInventory,
            kind: ProductKind.boosterPack,
            cardExpansion: catalogPack?.expansionName ?? sealedExpName,
            cardImageUrl: catalogPack?.imageUrl,
            cardBlueprintId: catalogPack?.id,
            createdAt: DateTime.now().subtract(const Duration(days: 4)),
          ),
          Product(
            id: 'demo-sealed-opened',
            name: catalogPack?.name ?? 'Riftbound Booster Pack',
            brand: 'RIFTBOUND',
            quantity: 10,
            price: 4.50,
            status: ProductStatus.inInventory,
            kind: ProductKind.boosterPack,
            cardExpansion: catalogPack?.expansionName ?? sealedExpName,
            cardImageUrl: catalogPack?.imageUrl,
            isOpened: true,
            openedAt: DateTime.now().subtract(const Duration(days: 2)),
            createdAt: DateTime.now().subtract(const Duration(days: 6)),
          ),
        ];

        // ── 5. Combine ──
        products = [...demoCards, ...sealedProducts];

        // Rebuild purchases from actual products
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

        // Generate realistic sales from listed products
        final listedCards = demoCards.where((p) => p.status == ProductStatus.listed).toList();
        sales = listedCards.map((p) {
          final salePrice = (p.marketPrice ?? p.price) * 1.1; // sold at +10%
          return Sale(
            id: 'demo-s-${p.id}',
            productName: p.name,
            salePrice: double.parse(salePrice.toStringAsFixed(2)),
            purchasePrice: p.price,
            fees: double.parse((salePrice * 0.08).toStringAsFixed(2)), // ~8% fees
            date: DateTime.now().subtract(Duration(days: listedCards.indexOf(p) + 3)),
          );
        }).toList();

        // Generate shipments from actual products
        final sealedName = sealedProducts.isNotEmpty ? sealedProducts.first.name : 'Riftbound Box';
        final listedName = listedCards.isNotEmpty ? listedCards.first.name : 'Riftbound Card';
        shipments = [
          Shipment(
            id: 'demo-sh1',
            trackingCode: 'BRT-123456789',
            carrier: 'brt',
            carrierName: 'BRT',
            type: ShipmentType.purchase,
            status: ShipmentStatus.inTransit,
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            productName: sealedName,
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
            productName: listedName,
          ),
        ];
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
      cardExpansion: 'Riftbound',
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
      cardExpansion: 'Riftbound',
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
      cardExpansion: 'Riftbound',
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

  static List<Sale> sales = List<Sale>.from(_defaultSales);

  static final List<Sale> _defaultSales = [];

  static List<Shipment> shipments = List<Shipment>.from(_defaultShipments);

  static final List<Shipment> _defaultShipments = [];

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
