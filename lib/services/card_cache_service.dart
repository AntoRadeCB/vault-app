import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import '../models/card_blueprint.dart';

@JS('JSON.stringify')
external JSString _jsStringify(JSAny? obj);

/// Local IndexedDB cache for card catalog.
/// On startup: reads _meta.lastSync from Firestore (1 read).
/// If it matches the cached timestamp → load from IndexedDB (0 card reads).
/// If it differs → fetch all cards from Firestore, save to IndexedDB.
class CardCacheService {
  static const _dbName = 'vault_card_cache';
  static const _dbVersion = 1;
  static const _storeName = 'cards';
  static const _metaStore = 'meta';

  static final CardCacheService _instance = CardCacheService._internal();
  factory CardCacheService() => _instance;
  CardCacheService._internal();

  web.IDBDatabase? _db;

  Future<web.IDBDatabase> _openDB() async {
    if (_db != null) return _db!;

    final completer = Completer<web.IDBDatabase>();
    final request = web.window.self.indexedDB.open(_dbName, _dbVersion);

    request.onupgradeneeded = ((web.IDBVersionChangeEvent event) {
      final db = (event.target as web.IDBOpenDBRequest).result as web.IDBDatabase;
      if (!db.objectStoreNames.contains(_storeName)) {
        db.createObjectStore(_storeName, web.IDBObjectStoreParameters(keyPath: 'id'.toJS));
      }
      if (!db.objectStoreNames.contains(_metaStore)) {
        db.createObjectStore(_metaStore);
      }
    }).toJS;

    request.onsuccess = ((web.Event event) {
      _db = (event.target as web.IDBOpenDBRequest).result as web.IDBDatabase;
      completer.complete(_db!);
    }).toJS;

    request.onerror = ((web.Event event) {
      completer.completeError('Failed to open IndexedDB');
    }).toJS;

    return completer.future;
  }

  /// Get cached lastSync timestamp (millis since epoch), or null if no cache.
  Future<int?> getCachedLastSync() async {
    try {
      final db = await _openDB();
      final tx = db.transaction(_metaStore.toJS, 'readonly');
      final store = tx.objectStore(_metaStore);
      final completer = Completer<int?>();

      final request = store.get('lastSync'.toJS);
      request.onsuccess = ((web.Event e) {
        final result = (e.target as web.IDBRequest).result;
        if (result == null || result.isUndefined) {
          completer.complete(null);
        } else {
          completer.complete((result as JSNumber).toDartInt);
        }
      }).toJS;
      request.onerror = ((web.Event e) {
        completer.complete(null);
      }).toJS;

      return completer.future;
    } catch (_) {
      return null;
    }
  }

  /// Save cards to IndexedDB.
  Future<void> saveCards(List<CardBlueprint> cards, int lastSyncMillis) async {
    final db = await _openDB();
    final tx = db.transaction([_storeName.toJS, _metaStore.toJS].toJS, 'readwrite');
    final store = tx.objectStore(_storeName);
    final metaStore = tx.objectStore(_metaStore);

    // Clear old data
    store.clear();

    // Write each card as a JS object
    for (final card in cards) {
      final map = card.toMap();
      map['id'] = card.id;
      store.put(map.jsify());
    }

    // Save sync timestamp
    metaStore.put(lastSyncMillis.toJS, 'lastSync'.toJS);

    final completer = Completer<void>();
    tx.oncomplete = ((web.Event e) => completer.complete()).toJS;
    tx.onerror = ((web.Event e) => completer.completeError('IndexedDB write failed')).toJS;
    return completer.future;
  }

  /// Load all cards from IndexedDB.
  Future<List<CardBlueprint>?> loadCards() async {
    try {
      final db = await _openDB();
      final tx = db.transaction(_storeName.toJS, 'readonly');
      final store = tx.objectStore(_storeName);
      final completer = Completer<List<CardBlueprint>?>();

      final request = store.getAll();
      request.onsuccess = ((web.Event e) {
        final result = (e.target as web.IDBRequest).result;
        if (result == null || result.isUndefined) {
          completer.complete(null);
          return;
        }
        try {
          final jsArray = result as JSArray;
          final cards = <CardBlueprint>[];
          for (var i = 0; i < jsArray.length; i++) {
            final jsObj = jsArray[i];
            final jsonStr = _jsStringify(jsObj).toDart;
            final map = jsonDecode(jsonStr) as Map<String, dynamic>;
            final id = map['id'] as String;
            cards.add(CardBlueprint.fromMap(id, map));
          }
          completer.complete(cards);
        } catch (err) {
          completer.complete(null);
        }
      }).toJS;
      request.onerror = ((web.Event e) {
        completer.complete(null);
      }).toJS;

      return completer.future;
    } catch (_) {
      return null;
    }
  }

  /// Clear all cached data.
  Future<void> clearCache() async {
    try {
      final db = await _openDB();
      final tx = db.transaction([_storeName.toJS, _metaStore.toJS].toJS, 'readwrite');
      tx.objectStore(_storeName).clear();
      tx.objectStore(_metaStore).clear();
    } catch (_) {}
  }
}
