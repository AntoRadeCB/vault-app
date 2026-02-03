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
      name: 'Charizard VMAX',
      brand: 'POKÉMON',
      quantity: 1,
      price: 45,
      status: ProductStatus.inInventory,
      kind: ProductKind.singleCard,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Product(
      id: 'demo-2',
      name: 'Pikachu Gold Star',
      brand: 'POKÉMON',
      quantity: 1,
      price: 320,
      status: ProductStatus.listed,
      kind: ProductKind.singleCard,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Product(
      id: 'demo-3',
      name: 'Pokémon 151 Booster Pack',
      brand: 'POKÉMON',
      quantity: 6,
      price: 4.50,
      status: ProductStatus.inInventory,
      kind: ProductKind.boosterPack,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Product(
      id: 'demo-4',
      name: 'MTG Murders at Karlov Manor Display',
      brand: 'MTG',
      quantity: 1,
      price: 120,
      status: ProductStatus.inInventory,
      kind: ProductKind.display,
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
      name: 'Yu-Gi-Oh! Age of Overlord Booster Box',
      brand: 'YU-GI-OH!',
      quantity: 1,
      price: 65,
      status: ProductStatus.shipped,
      kind: ProductKind.boosterBox,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Product(
      id: 'demo-7',
      name: 'One Piece OP-06 Booster Pack',
      brand: 'ONE PIECE',
      quantity: 10,
      price: 4,
      status: ProductStatus.inInventory,
      kind: ProductKind.boosterPack,
      isOpened: true,
      openedAt: DateTime.now().subtract(const Duration(days: 4)),
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    Product(
      id: 'demo-8',
      name: 'Scarlet & Violet ETB',
      brand: 'POKÉMON',
      quantity: 1,
      price: 42,
      status: ProductStatus.inInventory,
      kind: ProductKind.bundle,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  static final List<Purchase> purchases = [
    Purchase(
      id: 'demo-p1',
      productName: 'Charizard VMAX',
      price: 45,
      quantity: 1,
      date: DateTime.now().subtract(const Duration(days: 10)),
      workspace: 'cards',
    ),
    Purchase(
      id: 'demo-p2',
      productName: 'Pikachu Gold Star',
      price: 320,
      quantity: 1,
      date: DateTime.now().subtract(const Duration(days: 1)),
      workspace: 'cards',
    ),
    Purchase(
      id: 'demo-p3',
      productName: 'Pokémon 151 Booster Pack',
      price: 4.50,
      quantity: 6,
      date: DateTime.now().subtract(const Duration(days: 5)),
      workspace: 'cards',
    ),
    Purchase(
      id: 'demo-p4',
      productName: 'MTG Murders at Karlov Manor Display',
      price: 120,
      quantity: 1,
      date: DateTime.now().subtract(const Duration(days: 3)),
      workspace: 'cards',
    ),
    Purchase(
      id: 'demo-p5',
      productName: 'Riftbound Starter Box',
      price: 35,
      quantity: 2,
      date: DateTime.now().subtract(const Duration(days: 7)),
      workspace: 'cards',
    ),
    Purchase(
      id: 'demo-p6',
      productName: 'Yu-Gi-Oh! Age of Overlord Booster Box',
      price: 65,
      quantity: 1,
      date: DateTime.now().subtract(const Duration(days: 2)),
      workspace: 'cards',
    ),
  ];

  static final List<Sale> sales = [
    Sale(
      id: 'demo-s1',
      productName: 'Umbreon VMAX Alt Art',
      salePrice: 180,
      purchasePrice: 85,
      fees: 14,
      date: DateTime.now().subtract(const Duration(days: 8)),
    ),
    Sale(
      id: 'demo-s2',
      productName: 'Black Lotus (Played)',
      salePrice: 4500,
      purchasePrice: 3200,
      fees: 180,
      date: DateTime.now().subtract(const Duration(days: 12)),
    ),
    Sale(
      id: 'demo-s3',
      productName: 'Luffy Leader OP-01',
      salePrice: 45,
      purchasePrice: 20,
      fees: 4,
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
      productName: 'Yu-Gi-Oh! Age of Overlord Booster Box',
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
      productName: 'Pikachu Gold Star',
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
