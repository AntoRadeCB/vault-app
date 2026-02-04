import 'package:cloud_firestore/cloud_firestore.dart';

class Purchase {
  final String? id;
  final String productName;
  final double price;
  final double quantity;
  final DateTime date;
  final String workspace;

  const Purchase({
    this.id,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.date,
    required this.workspace,
  });

  factory Purchase.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Purchase(
      id: doc.id,
      productName: data['productName'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: (data['quantity'] ?? 0).toDouble(),
      date: data['date'] != null
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      workspace: data['workspace'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'date': Timestamp.fromDate(date),
      'workspace': workspace,
    };
  }

  double get totalCost => price * quantity;
}
