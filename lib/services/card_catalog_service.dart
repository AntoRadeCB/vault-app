import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/card_blueprint.dart';
import 'card_cache_service.dart';

class CardCatalogService {
  // Singleton for cache sharing across widgets
  static final CardCatalogService _instance = CardCatalogService._internal();
  factory CardCatalogService() => _instance;
  CardCatalogService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CardCacheService _cache = CardCacheService();

  // In-memory cache for fast autocomplete
  List<CardBlueprint>? _cachedCards;
  bool _loading = false;

  /// Get all cards — tries IndexedDB first, fetches from Firestore only if needed.
  Future<List<CardBlueprint>> getAllCards() async {
    // Already in memory? Return immediately.
    if (_cachedCards != null) return _cachedCards!;

    if (_loading) {
      while (_loading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedCards ?? [];
    }

    _loading = true;
    try {
      // 1. Read _meta from Firestore (1 read)
      final metaDoc = await _db.collection('cardCatalog').doc('_meta').get();
      final metaData = metaDoc.data() as Map<String, dynamic>?;
      final serverSync = metaData?['lastSync'] as Timestamp?;
      final serverMillis = serverSync?.millisecondsSinceEpoch ?? 0;

      // 2. Check local cache timestamp
      final localMillis = await _cache.getCachedLastSync();

      // 3. If timestamps match → load from IndexedDB
      if (localMillis != null && localMillis == serverMillis && serverMillis > 0) {
        final localCards = await _cache.loadCards();
        if (localCards != null && localCards.isNotEmpty) {
          _cachedCards = _sortCards(localCards);
          return _cachedCards!;
        }
      }

      // 4. Timestamps differ or no local cache → fetch from Firestore
      final snap = await _db.collection('cardCatalog').get();
      final cards = snap.docs
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

      _cachedCards = _sortCards(cards);

      // 5. Save to IndexedDB for next time
      try {
        await _cache.saveCards(_cachedCards!, serverMillis);
      } catch (_) {
        // IndexedDB save failed — no big deal, will fetch next time
      }

      return _cachedCards!;
    } catch (e) {
      // Firestore failed — try loading from local cache as fallback
      final localCards = await _cache.loadCards();
      if (localCards != null && localCards.isNotEmpty) {
        _cachedCards = _sortCards(localCards);
        return _cachedCards!;
      }
      rethrow;
    } finally {
      _loading = false;
    }
  }

  List<CardBlueprint> _sortCards(List<CardBlueprint> cards) {
    cards.sort((a, b) {
      final expCmp = (b.expansionId ?? 0).compareTo(a.expansionId ?? 0);
      if (expCmp != 0) return expCmp;
      final aNum = int.tryParse(a.collectorNumber ?? '') ?? 9999;
      final bNum = int.tryParse(b.collectorNumber ?? '') ?? 9999;
      return aNum.compareTo(bNum);
    });
    return cards;
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
    // Try from cached list first
    final cards = await getAllCards();
    final match = cards.where((c) => c.id == blueprintId);
    if (match.isNotEmpty) return match.first;
    // Fallback to direct Firestore read
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

  /// Clear all caches (memory + IndexedDB)
  void clearCache() {
    _cachedCards = null;
    _cache.clearCache();
  }
}
