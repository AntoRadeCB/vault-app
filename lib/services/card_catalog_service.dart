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

      // Sort client-side
      _cachedCards!.sort((a, b) => a.name.compareTo(b.name));

      _cacheTime = DateTime.now();
      return _cachedCards!;
    } catch (e) {
      rethrow;
    } finally {
      _loading = false;
    }
  }

  /// Search cards by name (client-side filter from cache for speed)
  Future<List<CardBlueprint>> searchCards(String query) async {
    if (query.trim().isEmpty) return [];

    final cards = await getAllCards();
    if (cards.isEmpty) return [];

    final q = query.toLowerCase();
    return cards
        .where((c) => c.name.toLowerCase().contains(q))
        .take(20)
        .toList();
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
