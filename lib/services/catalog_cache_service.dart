import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_blueprint.dart';

/// Unified cache service for catalog and prices.
/// 
/// Structure:
///   cardCatalog/_meta     → { version, count }
///   cardCatalog/_data_0   → { cards: { id: cardData, ... } }
///   
///   cardPrices/_meta      → { version, count }
///   cardPrices/_data      → { prices: { id: priceData, ... } }
class CatalogCacheService {
  static final CatalogCacheService _instance = CatalogCacheService._internal();
  factory CatalogCacheService() => _instance;
  CatalogCacheService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Local cache keys
  static const String _catalogVersionKey = 'catalog_version';
  static const String _pricesVersionKey = 'prices_version';
  static const String _catalogDataKey = 'catalog_data';
  static const String _pricesDataKey = 'prices_data';

  // In-memory cache
  List<CardBlueprint>? _cards;
  Map<String, dynamic>? _prices;
  
  int? _catalogVersion;
  int? _pricesVersion;

  // ═══════════════════════════════════════════════════════════════
  //  GETTERS
  // ═══════════════════════════════════════════════════════════════

  List<CardBlueprint> get cards => _cards ?? [];
  Map<String, dynamic> get prices => _prices ?? {};
  
  bool get hasCatalog => _cards != null && _cards!.isNotEmpty;
  bool get hasPrices => _prices != null && _prices!.isNotEmpty;

  // ═══════════════════════════════════════════════════════════════
  //  INITIALIZATION - Check versions and load what's needed
  // ═══════════════════════════════════════════════════════════════

  /// Initialize cache - call on app start
  /// Returns (catalogUpdated, pricesUpdated)
  Future<(bool, bool)> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load local versions
    _catalogVersion = prefs.getInt(_catalogVersionKey);
    _pricesVersion = prefs.getInt(_pricesVersionKey);
    
    // Check server versions (2 reads)
    final serverVersions = await _getServerVersions();
    
    bool catalogUpdated = false;
    bool pricesUpdated = false;
    
    // Load catalog if needed (always load if no local data or version mismatch)
    final needsCatalogLoad = _catalogVersion == null || 
                              _catalogVersion != serverVersions.catalog ||
                              !prefs.containsKey(_catalogDataKey);
    if (needsCatalogLoad) {
      debugPrint('📦 Catalog update needed: $_catalogVersion → ${serverVersions.catalog}');
      await _loadCatalogFromServer(prefs);
      if (serverVersions.catalog != null) {
        _catalogVersion = serverVersions.catalog;
        await prefs.setInt(_catalogVersionKey, _catalogVersion!);
      }
      catalogUpdated = true;
    } else {
      await _loadCatalogFromLocal(prefs);
    }
    
    // Load prices if needed
    if (_pricesVersion != serverVersions.prices) {
      debugPrint('💰 Prices update needed: $_pricesVersion → ${serverVersions.prices}');
      await _loadPricesFromServer(prefs);
      if (serverVersions.prices != null) {
        _pricesVersion = serverVersions.prices;
        await prefs.setInt(_pricesVersionKey, _pricesVersion!);
      }
      pricesUpdated = true;
    } else {
      await _loadPricesFromLocal(prefs);
    }
    
    debugPrint('✅ Cache initialized: ${_cards?.length ?? 0} cards, ${_prices?.length ?? 0} prices');
    
    return (catalogUpdated, pricesUpdated);
  }

  // ═══════════════════════════════════════════════════════════════
  //  VERSION CHECKING
  // ═══════════════════════════════════════════════════════════════

  Future<({int? catalog, int? prices})> _getServerVersions() async {
    try {
      final futures = await Future.wait([
        _db.collection('cardCatalog').doc('_meta').get(),
        _db.collection('cardPrices').doc('_meta').get(),
      ]);
      
      return (
        catalog: futures[0].data()?['version'] as int?,
        prices: futures[1].data()?['version'] as int?,
      );
    } catch (e) {
      debugPrint('Error getting server versions: $e');
      return (catalog: null, prices: null);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  CATALOG LOADING
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadCatalogFromServer(SharedPreferences prefs) async {
    try {
      // Get all data chunks
      final snapshot = await _db.collection('cardCatalog')
          .where(FieldPath.documentId, isNotEqualTo: '_meta')
          .get();
      
      final cards = <CardBlueprint>[];
      
      for (final doc in snapshot.docs) {
        if (doc.id.startsWith('_')) continue; // Skip meta docs
        
        final data = doc.data();
        // Handle both old format (individual docs) and new format (chunked)
        if (data.containsKey('cards')) {
          // New chunked format
          final cardsMap = data['cards'] as Map<String, dynamic>;
          for (final entry in cardsMap.entries) {
            cards.add(CardBlueprint.fromMap(entry.key, entry.value as Map<String, dynamic>));
          }
        } else {
          // Old format - individual card doc
          cards.add(CardBlueprint.fromMap(doc.id, data));
        }
      }
      
      _cards = cards;
      
      // Save to local storage
      final encoded = jsonEncode(cards.map((c) => c.toMap()).toList());
      await prefs.setString(_catalogDataKey, encoded);
      
      debugPrint('📦 Loaded ${cards.length} cards from server');
    } catch (e) {
      debugPrint('Error loading catalog from server: $e');
    }
  }

  Future<void> _loadCatalogFromLocal(SharedPreferences prefs) async {
    try {
      final encoded = prefs.getString(_catalogDataKey);
      if (encoded == null) return;
      
      final List<dynamic> decoded = jsonDecode(encoded);
      _cards = decoded.map((m) => CardBlueprint.fromMap(
        m['id'] as String? ?? '', 
        m as Map<String, dynamic>
      )).toList();
      
      debugPrint('📦 Loaded ${_cards!.length} cards from local cache');
    } catch (e) {
      debugPrint('Error loading catalog from local: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  PRICES LOADING
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadPricesFromServer(SharedPreferences prefs) async {
    try {
      final doc = await _db.collection('cardPrices').doc('_data').get();
      if (!doc.exists) return;
      
      _prices = doc.data()?['prices'] as Map<String, dynamic>? ?? {};
      
      // Save to local
      await prefs.setString(_pricesDataKey, jsonEncode(_prices));
      
      debugPrint('💰 Loaded ${_prices!.length} prices from server');
    } catch (e) {
      debugPrint('Error loading prices from server: $e');
    }
  }

  Future<void> _loadPricesFromLocal(SharedPreferences prefs) async {
    try {
      final encoded = prefs.getString(_pricesDataKey);
      if (encoded == null) return;
      
      _prices = jsonDecode(encoded) as Map<String, dynamic>?;
      
      debugPrint('💰 Loaded ${_prices?.length ?? 0} prices from local cache');
    } catch (e) {
      debugPrint('Error loading prices from local: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  CACHE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  /// Clear all local cache
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_catalogVersionKey);
    await prefs.remove(_pricesVersionKey);
    await prefs.remove(_catalogDataKey);
    await prefs.remove(_pricesDataKey);
    
    _cards = null;
    _prices = null;
    _catalogVersion = null;
    _pricesVersion = null;
    
    debugPrint('🗑️ Cache cleared');
  }
}
