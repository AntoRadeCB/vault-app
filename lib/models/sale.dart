import 'package:cloud_firestore/cloud_firestore.dart';

class Sale {
  final String? id;
  final String productName;
  final double salePrice;
  final double purchasePrice;
  final double fees;
  final DateTime date;

  const Sale({
    this.id,
    required this.productName,
    required this.salePrice,
    required this.purchasePrice,
    required this.fees,
    required this.date,
  });

  factory Sale.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Sale(
      id: doc.id,
      productName: data['productName'] ?? '',
      salePrice: (data['salePrice'] ?? 0).toDouble(),
      purchasePrice: (data['purchasePrice'] ?? 0).toDouble(),
      fees: (data['fees'] ?? 0).toDouble(),
      date: data['date'] != null
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productName': productName,
      'salePrice': salePrice,
      'purchasePrice': purchasePrice,
      'fees': fees,
      'date': Timestamp.fromDate(date),
    };
  }

  double get profit => salePrice - purchasePrice - fees;
}
