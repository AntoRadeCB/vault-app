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
      name: 'Nike Air Max 90',
      brand: 'NIKE',
      quantity: 2,
      price: 89.99,
      status: ProductStatus.inInventory,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Product(
      id: 'demo-2',
      name: 'Adidas Yeezy 350 V2',
      brand: 'ADIDAS',
      quantity: 1,
      price: 220,
      status: ProductStatus.shipped,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Product(
      id: 'demo-3',
      name: 'New Balance 550',
      brand: 'NEW BALANCE',
      quantity: 3,
      price: 65,
      status: ProductStatus.inInventory,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    Product(
      id: 'demo-4',
      name: 'Jordan 1 Retro High OG',
      brand: 'NIKE',
      quantity: 1,
      price: 170,
      status: ProductStatus.listed,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Product(
      id: 'demo-5',
      name: 'Charizard VMAX',
      brand: 'POKÉMON',
      quantity: 1,
      price: 45,
      status: ProductStatus.inInventory,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Product(
      id: 'demo-6',
      name: 'Pikachu Gold Star',
      brand: 'POKÉMON',
      quantity: 1,
      price: 320,
      status: ProductStatus.listed,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Product(
      id: 'demo-7',
      name: 'Stone Island Hoodie',
      brand: 'STONE ISLAND',
      quantity: 1,
      price: 185,
      status: ProductStatus.inInventory,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  static final List<Purchase> purchases = [
    Purchase(
      id: 'demo-p1',
      productName: 'Nike Air Max 90',
      price: 89.99,
      quantity: 2,
      date: DateTime.now().subtract(const Duration(days: 5)),
      workspace: 'demo',
    ),
    Purchase(
      id: 'demo-p2',
      productName: 'Adidas Yeezy 350 V2',
      price: 220,
      quantity: 1,
      date: DateTime.now().subtract(const Duration(days: 3)),
      workspace: 'demo',
    ),
    Purchase(
      id: 'demo-p3',
      productName: 'New Balance 550',
      price: 65,
      quantity: 3,
      date: DateTime.now().subtract(const Duration(days: 7)),
      workspace: 'demo',
    ),
    Purchase(
      id: 'demo-p4',
      productName: 'Jordan 1 Retro High OG',
      price: 170,
      quantity: 1,
      date: DateTime.now().subtract(const Duration(days: 2)),
      workspace: 'demo',
    ),
    Purchase(
      id: 'demo-p5',
      productName: 'Charizard VMAX',
      price: 45,
      quantity: 1,
      date: DateTime.now().subtract(const Duration(days: 10)),
      workspace: 'demo',
    ),
    Purchase(
      id: 'demo-p6',
      productName: 'Pikachu Gold Star',
      price: 320,
      quantity: 1,
      date: DateTime.now().subtract(const Duration(days: 1)),
      workspace: 'demo',
    ),
  ];

  static final List<Sale> sales = [
    Sale(
      id: 'demo-s1',
      productName: 'Nike Dunk Low Panda',
      salePrice: 155,
      purchasePrice: 95,
      fees: 12,
      date: DateTime.now().subtract(const Duration(days: 4)),
    ),
    Sale(
      id: 'demo-s2',
      productName: 'Stone Island Cargo Pants',
      salePrice: 280,
      purchasePrice: 120,
      fees: 22,
      date: DateTime.now().subtract(const Duration(days: 6)),
    ),
    Sale(
      id: 'demo-s3',
      productName: 'Umbreon VMAX Alt Art',
      salePrice: 180,
      purchasePrice: 85,
      fees: 14,
      date: DateTime.now().subtract(const Duration(days: 8)),
    ),
    Sale(
      id: 'demo-s4',
      productName: 'Jordan 4 Military Black',
      salePrice: 310,
      purchasePrice: 190,
      fees: 25,
      date: DateTime.now().subtract(const Duration(days: 12)),
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
      productName: 'Adidas Yeezy 350 V2',
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
      productName: 'Jordan 1 Retro High OG',
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
