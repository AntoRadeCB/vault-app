enum ProductStatus { shipped, inInventory, listed }

class Product {
  final String name;
  final String brand;
  final double quantity;
  final double price;
  final ProductStatus status;
  final String? imageUrl;

  const Product({
    required this.name,
    required this.brand,
    required this.quantity,
    required this.price,
    required this.status,
    this.imageUrl,
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
