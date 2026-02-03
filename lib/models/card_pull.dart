import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single card pulled from opening a sealed product (pack/box).
class CardPull {
  final String? id;
  final String parentProductId; // the pack/box that was opened
  final String cardName;
  final String? cardBlueprintId;
  final String? cardImageUrl;
  final String? rarity;
  final double? estimatedValue;
  final DateTime pulledAt;

  const CardPull({
    this.id,
    required this.parentProductId,
    required this.cardName,
    this.cardBlueprintId,
    this.cardImageUrl,
    this.rarity,
    this.estimatedValue,
    required this.pulledAt,
  });

  factory CardPull.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CardPull(
      id: doc.id,
      parentProductId: data['parentProductId'] ?? '',
      cardName: data['cardName'] ?? '',
      cardBlueprintId: data['cardBlueprintId'],
      cardImageUrl: data['cardImageUrl'],
      rarity: data['rarity'],
      estimatedValue: (data['estimatedValue'] as num?)?.toDouble(),
      pulledAt: data['pulledAt'] != null
          ? (data['pulledAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'parentProductId': parentProductId,
      'cardName': cardName,
      if (cardBlueprintId != null) 'cardBlueprintId': cardBlueprintId,
      if (cardImageUrl != null) 'cardImageUrl': cardImageUrl,
      if (rarity != null) 'rarity': rarity,
      if (estimatedValue != null) 'estimatedValue': estimatedValue,
      'pulledAt': Timestamp.fromDate(pulledAt),
    };
  }

  CardPull copyWith({
    String? id,
    String? parentProductId,
    String? cardName,
    String? cardBlueprintId,
    String? cardImageUrl,
    String? rarity,
    double? estimatedValue,
    DateTime? pulledAt,
  }) {
    return CardPull(
      id: id ?? this.id,
      parentProductId: parentProductId ?? this.parentProductId,
      cardName: cardName ?? this.cardName,
      cardBlueprintId: cardBlueprintId ?? this.cardBlueprintId,
      cardImageUrl: cardImageUrl ?? this.cardImageUrl,
      rarity: rarity ?? this.rarity,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      pulledAt: pulledAt ?? this.pulledAt,
    );
  }
}
