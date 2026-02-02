import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductStatus { shipped, inInventory, listed }

class Product {
  final String? id;
  final String name;
  final String brand;
  final double quantity;
  final double price;
  final ProductStatus status;
  final String? imageUrl;
  final String? barcode;
  final DateTime? createdAt;
  // CardTrader integration
  final String? cardBlueprintId;
  final String? cardImageUrl;
  final String? cardExpansion;
  final String? cardRarity;
  final double? marketPrice;

  const Product({
    this.id,
    required this.name,
    required this.brand,
    required this.quantity,
    required this.price,
    required this.status,
    this.imageUrl,
    this.barcode,
    this.createdAt,
    this.cardBlueprintId,
    this.cardImageUrl,
    this.cardExpansion,
    this.cardRarity,
    this.marketPrice,
  });

  String get statusLabel {
    switch (status) {
      case ProductStatus.shipped:
        return 'SHIPPED';
      case ProductStatus.inInventory:
        return 'IN INVENTORY';
      case ProductStatus.listed:
        return 'LISTED';
    }
  }

  String get formattedPrice {
    if (price >= 1000) {
      return '€${price.toStringAsFixed(0)}';
    }
    return '€${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}';
  }

  String get formattedQuantity {
    if (quantity == quantity.truncateToDouble()) {
      return quantity.toInt().toString();
    }
    return quantity.toString();
  }

  static ProductStatus _statusFromString(String? s) {
    switch (s) {
      case 'shipped':
        return ProductStatus.shipped;
      case 'listed':
        return ProductStatus.listed;
      case 'inInventory':
      default:
        return ProductStatus.inInventory;
    }
  }

  static String _statusToString(ProductStatus status) {
    switch (status) {
      case ProductStatus.shipped:
        return 'shipped';
      case ProductStatus.inInventory:
        return 'inInventory';
      case ProductStatus.listed:
        return 'listed';
    }
  }

  bool get isCard => cardBlueprintId != null;

  String get displayImageUrl => cardImageUrl ?? imageUrl ?? '';

  String get formattedMarketPrice {
    if (marketPrice == null) return '';
    if (marketPrice! >= 1000) return '€${marketPrice!.toStringAsFixed(0)}';
    return '€${marketPrice!.toStringAsFixed(2)}';
  }

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      price: (data['price'] ?? 0).toDouble(),
      status: _statusFromString(data['status']),
      imageUrl: data['imageUrl'],
      barcode: data['barcode'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      cardBlueprintId: data['cardBlueprintId'],
      cardImageUrl: data['cardImageUrl'],
      cardExpansion: data['cardExpansion'],
      cardRarity: data['cardRarity'],
      marketPrice: (data['marketPrice'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'brand': brand,
      'quantity': quantity,
      'price': price,
      'status': _statusToString(status),
      'imageUrl': imageUrl,
      'barcode': barcode,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      if (cardBlueprintId != null) 'cardBlueprintId': cardBlueprintId,
      if (cardImageUrl != null) 'cardImageUrl': cardImageUrl,
      if (cardExpansion != null) 'cardExpansion': cardExpansion,
      if (cardRarity != null) 'cardRarity': cardRarity,
      if (marketPrice != null) 'marketPrice': marketPrice,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    double? quantity,
    double? price,
    ProductStatus? status,
    String? imageUrl,
    String? barcode,
    DateTime? createdAt,
    String? cardBlueprintId,
    String? cardImageUrl,
    String? cardExpansion,
    String? cardRarity,
    double? marketPrice,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
      createdAt: createdAt ?? this.createdAt,
      cardBlueprintId: cardBlueprintId ?? this.cardBlueprintId,
      cardImageUrl: cardImageUrl ?? this.cardImageUrl,
      cardExpansion: cardExpansion ?? this.cardExpansion,
      cardRarity: cardRarity ?? this.cardRarity,
      marketPrice: marketPrice ?? this.marketPrice,
    );
  }

  static List<Product> get sampleProducts => [
        const Product(
          name: 'Nike Air Max 90',
          brand: 'NIKE',
          quantity: 1,
          price: 45,
          status: ProductStatus.shipped,
        ),
        const Product(
          name: 'Adidas Forum Low',
          brand: 'ADIDAS',
          quantity: 2,
          price: 65,
          status: ProductStatus.inInventory,
        ),
        const Product(
          name: 'Stone Island Hoodie',
          brand: 'STONE ISLAND',
          quantity: 1,
          price: 120,
          status: ProductStatus.listed,
        ),
        const Product(
          name: 'Bitcoin (BTC)',
          brand: 'BITCOIN',
          quantity: 0.25,
          price: 45000,
          status: ProductStatus.inInventory,
        ),
      ];
}
