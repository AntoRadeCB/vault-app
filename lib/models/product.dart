import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductStatus { shipped, inInventory, listed }

enum ProductKind { singleCard, boosterPack, boosterBox, display, bundle }

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
  // Product kind (card, pack, box, etc.)
  final ProductKind kind;
  // Pack/box opening fields
  final bool isOpened;
  final DateTime? openedAt;
  final List<String>? pullIds;
  // If this card came from opening a pack/box
  final String? parentProductId;

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
    this.kind = ProductKind.singleCard,
    this.isOpened = false,
    this.openedAt,
    this.pullIds,
    this.parentProductId,
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

  String get kindLabel {
    switch (kind) {
      case ProductKind.singleCard:
        return 'Carta';
      case ProductKind.boosterPack:
        return 'Busta';
      case ProductKind.boosterBox:
        return 'Box';
      case ProductKind.display:
        return 'Display';
      case ProductKind.bundle:
        return 'Bundle';
    }
  }

  bool get isSealed =>
      kind != ProductKind.singleCard && !isOpened;

  bool get canBeOpened =>
      (kind == ProductKind.boosterPack ||
          kind == ProductKind.boosterBox ||
          kind == ProductKind.display ||
          kind == ProductKind.bundle) &&
      !isOpened;

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

  static ProductKind _kindFromString(String? s) {
    switch (s) {
      case 'boosterPack':
        return ProductKind.boosterPack;
      case 'boosterBox':
        return ProductKind.boosterBox;
      case 'display':
        return ProductKind.display;
      case 'bundle':
        return ProductKind.bundle;
      case 'singleCard':
      default:
        return ProductKind.singleCard;
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
      kind: _kindFromString(data['kind']),
      isOpened: data['isOpened'] ?? false,
      openedAt: data['openedAt'] != null
          ? (data['openedAt'] as Timestamp).toDate()
          : null,
      pullIds: data['pullIds'] != null
          ? List<String>.from(data['pullIds'])
          : null,
      parentProductId: data['parentProductId'],
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
      'kind': kind.name,
      'isOpened': isOpened,
      if (openedAt != null) 'openedAt': Timestamp.fromDate(openedAt!),
      if (pullIds != null) 'pullIds': pullIds,
      if (parentProductId != null) 'parentProductId': parentProductId,
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
    ProductKind? kind,
    bool? isOpened,
    DateTime? openedAt,
    List<String>? pullIds,
    String? parentProductId,
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
      kind: kind ?? this.kind,
      isOpened: isOpened ?? this.isOpened,
      openedAt: openedAt ?? this.openedAt,
      pullIds: pullIds ?? this.pullIds,
      parentProductId: parentProductId ?? this.parentProductId,
    );
  }

  static List<Product> get sampleProducts => [
        const Product(
          name: 'Charizard VMAX',
          brand: 'POKÉMON',
          quantity: 1,
          price: 45,
          status: ProductStatus.inInventory,
          kind: ProductKind.singleCard,
        ),
        const Product(
          name: 'Pokémon 151 Booster Pack',
          brand: 'POKÉMON',
          quantity: 5,
          price: 4.50,
          status: ProductStatus.inInventory,
          kind: ProductKind.boosterPack,
        ),
        const Product(
          name: 'MTG Murders at Karlov Manor Display',
          brand: 'MTG',
          quantity: 1,
          price: 120,
          status: ProductStatus.listed,
          kind: ProductKind.display,
        ),
        const Product(
          name: 'Riftbound Starter Box',
          brand: 'RIFTBOUND',
          quantity: 1,
          price: 35,
          status: ProductStatus.inInventory,
          kind: ProductKind.boosterBox,
        ),
      ];
}
