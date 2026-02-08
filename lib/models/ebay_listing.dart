import 'package:cloud_firestore/cloud_firestore.dart';

class EbayListing {
  final String? id;
  final String productId;
  final String? sku;
  final String? offerId;
  final String? ebayItemId;
  final String title;
  final String description;
  final double price;
  final String currency;
  final int quantity;
  final String condition;
  final String categoryId;
  final List<String> imageUrls;
  final String status; // active, draft, ended
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EbayListing({
    this.id,
    required this.productId,
    this.sku,
    this.offerId,
    this.ebayItemId,
    required this.title,
    required this.description,
    required this.price,
    this.currency = 'EUR',
    this.quantity = 1,
    required this.condition,
    required this.categoryId,
    this.imageUrls = const [],
    this.status = 'draft',
    this.createdAt,
    this.updatedAt,
  });

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Attiva';
      case 'draft':
        return 'Bozza';
      case 'ended':
        return 'Terminata';
      default:
        return status;
    }
  }

  String get formattedPrice => '€${price.toStringAsFixed(2)}';

  String get ebayUrl =>
      ebayItemId != null ? 'https://www.ebay.it/itm/$ebayItemId' : '';

  factory EbayListing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EbayListing(
      id: doc.id,
      productId: data['productId'] ?? '',
      sku: data['sku'],
      offerId: data['offerId'],
      ebayItemId: data['ebayItemId'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] ?? 'EUR',
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      condition: data['condition'] ?? 'USED_EXCELLENT',
      categoryId: data['categoryId'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      status: data['status'] ?? 'draft',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'title': title,
        'description': description,
        'price': price,
        'currency': currency,
        'quantity': quantity,
        'condition': condition,
        'categoryId': categoryId,
        'imageUrls': imageUrls,
      };
}
