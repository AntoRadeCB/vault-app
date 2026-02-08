import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';

class CardBlueprint {
  final String id; // blueprintId as string
  final int blueprintId;
  final String name;
  final String? version;
  final String? game; // e.g. 'riftbound', 'pokemon', 'mtg'
  final int? expansionId;
  final String? expansionName;
  final String? expansionCode;
  final String? collectorNumber;
  final String? rarity;
  final String? imageUrl;
  final String? backImageUrl;
  final MarketPrice? marketPrice;
  final String? kind; // 'singleCard', 'boosterPack', 'boosterBox', 'display', 'bundle'
  final int? categoryId;
  final String? categoryName;
  final List<String> availableLanguages; // e.g. ['en', 'zh-CN', 'fr']
  final bool hasFoil;

  const CardBlueprint({
    required this.id,
    required this.blueprintId,
    required this.name,
    this.version,
    this.game,
    this.expansionId,
    this.expansionName,
    this.expansionCode,
    this.collectorNumber,
    this.rarity,
    this.imageUrl,
    this.backImageUrl,
    this.marketPrice,
    this.kind,
    this.categoryId,
    this.categoryName,
    this.availableLanguages = const [],
    this.hasFoil = false,
  });

  factory CardBlueprint.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CardBlueprint(
      id: doc.id,
      blueprintId: data['blueprintId'] ?? 0,
      name: data['name'] ?? '',
      version: data['version'],
      game: data['game'] as String?,
      expansionId: data['expansionId'],
      expansionName: data['expansionName'],
      expansionCode: data['expansionCode'],
      collectorNumber: data['collectorNumber'],
      rarity: data['rarity'],
      imageUrl: data['imageUrl'],
      backImageUrl: data['backImageUrl'] as String?,
      marketPrice: data['marketPrice'] != null
          ? MarketPrice.fromMap(data['marketPrice'] as Map<String, dynamic>)
          : null,
      kind: data['kind'] as String?,
      categoryId: data['categoryId'] as int?,
      categoryName: data['categoryName'] as String?,
      availableLanguages: (data['availableLanguages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      hasFoil: data['hasFoil'] as bool? ?? false,
    );
  }

  String get formattedPrice {
    if (marketPrice == null) return 'N/A';
    final euros = marketPrice!.cents / 100;
    if (euros >= 1000) return '€${euros.toStringAsFixed(0)}';
    return '€${euros.toStringAsFixed(2)}';
  }

  Color get rarityColor {
    switch (rarity?.toLowerCase()) {
      case 'common':
        return const Color(0xFF9E9E9E);
      case 'uncommon':
        return const Color(0xFF4CAF50);
      case 'rare':
        return const Color(0xFF2196F3);
      case 'epic':
        return const Color(0xFFAB47BC);
      case 'alternate art':
        return const Color(0xFFFFD700);
      case 'promo':
        return const Color(0xFFFF6B35);
      case 'token':
        return const Color(0xFF78909C);
      case 'showcase':
        return const Color(0xFFE91E63);
      case 'overnumbered':
        return const Color(0xFFFF4081);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  /// Create from plain Map (for JSON serialization)
  factory CardBlueprint.fromMap(String id, Map<String, dynamic> data) {
    return CardBlueprint(
      id: id,
      blueprintId: data['blueprintId'] ?? 0,
      name: data['name'] ?? '',
      version: data['version'],
      game: data['game'] as String?,
      expansionId: data['expansionId'],
      expansionName: data['expansionName'],
      expansionCode: data['expansionCode'],
      collectorNumber: data['collectorNumber'],
      rarity: data['rarity'],
      imageUrl: data['imageUrl'],
      backImageUrl: data['backImageUrl'] as String?,
      marketPrice: data['marketPrice'] != null
          ? MarketPrice.fromMap(data['marketPrice'] as Map<String, dynamic>)
          : null,
      kind: data['kind'] as String?,
      categoryId: data['categoryId'] as int?,
      categoryName: data['categoryName'] as String?,
      availableLanguages: (data['availableLanguages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      hasFoil: data['hasFoil'] as bool? ?? false,
    );
  }

  /// Convert to plain Map (for JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'blueprintId': blueprintId,
      'name': name,
      if (version != null) 'version': version,
      if (game != null) 'game': game,
      if (expansionId != null) 'expansionId': expansionId,
      if (expansionName != null) 'expansionName': expansionName,
      if (expansionCode != null) 'expansionCode': expansionCode,
      if (collectorNumber != null) 'collectorNumber': collectorNumber,
      if (rarity != null) 'rarity': rarity,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (backImageUrl != null) 'backImageUrl': backImageUrl,
      if (marketPrice != null) 'marketPrice': marketPrice!.toMap(),
      if (kind != null) 'kind': kind,
      if (categoryId != null) 'categoryId': categoryId,
      if (categoryName != null) 'categoryName': categoryName,
      if (availableLanguages.isNotEmpty) 'availableLanguages': availableLanguages,
      'hasFoil': hasFoil,
    };
  }
}

class MarketPrice {
  final int cents;
  final String currency;
  final String? formatted;
  final int? sellersCount;
  final DateTime? updatedAt;

  const MarketPrice({
    required this.cents,
    required this.currency,
    this.formatted,
    this.sellersCount,
    this.updatedAt,
  });

  factory MarketPrice.fromMap(Map<String, dynamic> map) {
    DateTime? parsedDate;
    final rawDate = map['updatedAt'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate);
    }
    return MarketPrice(
      cents: map['cents'] ?? 0,
      currency: map['currency'] ?? 'EUR',
      formatted: map['formatted'],
      sellersCount: map['sellersCount'],
      updatedAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cents': cents,
      'currency': currency,
      if (formatted != null) 'formatted': formatted,
      if (sellersCount != null) 'sellersCount': sellersCount,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}
