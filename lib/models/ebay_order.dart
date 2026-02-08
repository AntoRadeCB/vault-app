import 'package:cloud_firestore/cloud_firestore.dart';

class EbayOrderItem {
  final String title;
  final String? sku;
  final int quantity;
  final double price;
  final String? imageUrl;

  const EbayOrderItem({
    required this.title,
    this.sku,
    this.quantity = 1,
    this.price = 0,
    this.imageUrl,
  });

  factory EbayOrderItem.fromMap(Map<String, dynamic> map) => EbayOrderItem(
        title: map['title'] ?? '',
        sku: map['sku'],
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        price: (map['price'] as num?)?.toDouble() ?? 0,
        imageUrl: map['imageUrl'],
      );
}

class EbayOrder {
  final String? id;
  final String ebayOrderId;
  final String status; // NOT_STARTED, IN_PROGRESS, FULFILLED, REFUNDED
  final String paymentStatus;
  final double total;
  final String currency;
  final String buyerUsername;
  final List<EbayOrderItem> items;
  final Map<String, dynamic>? shippingAddress;
  final Map<String, dynamic>? tracking;
  final String? creationDate;
  final DateTime? updatedAt;

  const EbayOrder({
    this.id,
    required this.ebayOrderId,
    required this.status,
    this.paymentStatus = 'UNKNOWN',
    required this.total,
    this.currency = 'EUR',
    this.buyerUsername = '',
    this.items = const [],
    this.shippingAddress,
    this.tracking,
    this.creationDate,
    this.updatedAt,
  });

  String get statusLabel {
    switch (status) {
      case 'NOT_STARTED':
        return 'Pagato';
      case 'IN_PROGRESS':
        return 'In corso';
      case 'FULFILLED':
        return 'Spedito';
      case 'REFUNDED':
        return 'Rimborsato';
      default:
        return status;
    }
  }

  String get formattedTotal => '€${total.toStringAsFixed(2)}';

  bool get canShip => status == 'NOT_STARTED' || status == 'IN_PROGRESS';
  bool get canRefund => status != 'REFUNDED';

  factory EbayOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EbayOrder(
      id: doc.id,
      ebayOrderId: data['ebayOrderId'] ?? doc.id,
      status: data['status'] ?? 'NOT_STARTED',
      paymentStatus: data['paymentStatus'] ?? 'UNKNOWN',
      total: (data['total'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] ?? 'EUR',
      buyerUsername: (data['buyer'] as Map<String, dynamic>?)?['username'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((e) => EbayOrderItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      shippingAddress: data['shippingAddress'] as Map<String, dynamic>?,
      tracking: data['tracking'] as Map<String, dynamic>?,
      creationDate: data['creationDate'],
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
