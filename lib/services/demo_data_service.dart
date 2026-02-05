import '../models/product.dart';
import '../models/purchase.dart';
import '../models/sale.dart';
import '../models/shipment.dart';

/// Provides static sample data for demo mode (no auth needed).
/// All data is in-memory — nothing touches Firestore.
class DemoDataService {
  static final List<Product> products = [
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

  static final List<Purchase> purchases = [
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
