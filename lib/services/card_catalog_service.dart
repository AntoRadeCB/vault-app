import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/card_blueprint.dart';

class CardCatalogService {
  // Singleton for cache sharing across widgets
  static final CardCatalogService _instance = CardCatalogService._internal();
  factory CardCatalogService() => _instance;
  CardCatalogService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // In-memory cache for fast autocomplete
  List<CardBlueprint>? _cachedCards;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 30);
  bool _loading = false;

  /// Get all cards (cached in memory for fast autocomplete)
  Future<List<CardBlueprint>> getAllCards() async {
    if (_cachedCards != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedCards!;
    }

    if (_loading) {
      // Wait for ongoing load
      while (_loading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedCards ?? [];
    }

    _loading = true;
    try {
      // Simple get without orderBy to avoid index issues
      final snap = await _db
          .collection('cardCatalog')
          .get();

      _cachedCards = snap.docs
          .where((doc) => doc.id != '_meta')
          .map((doc) {
            try {
              return CardBlueprint.fromFirestore(doc);
            } catch (_) {
              return null;
            }
          })
          .whereType<CardBlueprint>()
          .toList();

      // Sort by expansion (descending id = newest first), then collector number
      _cachedCards!.sort((a, b) {
        // First by expansion (higher id = newer)
        final expCmp = (b.expansionId ?? 0).compareTo(a.expansionId ?? 0);
        if (expCmp != 0) return expCmp;
        // Then by collector number (numeric sort)
        final aNum = int.tryParse(a.collectorNumber ?? '') ?? 9999;
        final bNum = int.tryParse(b.collectorNumber ?? '') ?? 9999;
        return aNum.compareTo(bNum);
      });

      _cacheTime = DateTime.now();
      return _cachedCards!;
    } catch (e) {
      rethrow;
    } finally {
      _loading = false;
    }
  }

  /// Search cards by name, optionally filtered by product kind
  Future<List<CardBlueprint>> searchCards(String query, {String? kind}) async {
    if (query.trim().isEmpty) return [];

    final cards = await getAllCards();
    if (cards.isEmpty) return [];

    final q = query.toLowerCase();
    var results = cards.where((c) => c.name.toLowerCase().contains(q));
    if (kind != null) {
      results = results.where((c) => c.kind == kind);
    }
    return results.take(20).toList();
  }

  /// Get a single card by blueprintId
  Future<CardBlueprint?> getCard(String blueprintId) async {
    final doc = await _db.collection('cardCatalog').doc(blueprintId).get();
    if (!doc.exists) return null;
    return CardBlueprint.fromFirestore(doc);
  }

  /// Get cards by expansion
  Future<List<CardBlueprint>> getCardsByExpansion(int expansionId) async {
    final cards = await getAllCards();
    return cards.where((c) => c.expansionId == expansionId).toList();
  }

  /// Get available expansions
  Future<List<Map<String, dynamic>>> getExpansions() async {
    final doc = await _db.collection('cardCatalog').doc('_meta').get();
    if (!doc.exists) return [];
    final data = doc.data() as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(data['expansions'] ?? []);
  }

  /// Get catalog metadata
  Future<Map<String, dynamic>?> getCatalogMeta() async {
    final doc = await _db.collection('cardCatalog').doc('_meta').get();
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>;
  }

  /// Clear cache (e.g., after a sync)
  void clearCache() {
    _cachedCards = null;
    _cacheTime = null;
  }
}
