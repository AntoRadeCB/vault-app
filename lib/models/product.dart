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
  final DateTime? createdAt;

  const Product({
    this.id,
    required this.name,
    required this.brand,
    required this.quantity,
    required this.price,
    required this.status,
    this.imageUrl,
    this.createdAt,
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
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
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
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
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
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
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
