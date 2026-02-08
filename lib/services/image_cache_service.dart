// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Service for caching card images in IndexedDB (web only).
/// Falls back to no-op on non-web platforms.
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  static const String _dbName = 'VaultAppImageCache';
  static const String _storeName = 'images';
  static const int _dbVersion = 1;
  static const Duration _defaultTtl = Duration(days: 7);

  web.IDBDatabase? _db;
  bool _isInitialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  /// Initialize the IndexedDB database
  Future<void> init() async {
    if (_isInitialized) return;
    if (!kIsWeb) {
      _isInitialized = true;
      _initCompleter.complete();
      return;
    }

    try {
      final request = web.window.indexedDB.open(_dbName, _dbVersion);
      
      request.onupgradeneeded = (web.IDBVersionChangeEvent event) {
        final db = (event.target as web.IDBOpenDBRequest).result as web.IDBDatabase;
        if (!db.objectStoreNames.contains(_storeName)) {
          db.createObjectStore(_storeName);
        }
      }.toJS;

      final completer = Completer<web.IDBDatabase>();
      request.onsuccess = (web.Event event) {
        completer.complete((event.target as web.IDBOpenDBRequest).result as web.IDBDatabase);
      }.toJS;
      request.onerror = (web.Event event) {
        completer.completeError('Failed to open IndexedDB');
      }.toJS;

      _db = await completer.future;
      _isInitialized = true;
      _initCompleter.complete();
    } catch (e) {
      debugPrint('ImageCacheService init error: $e');
      _isInitialized = true;
      _initCompleter.complete();
    }
  }

  Future<void> _ensureInit() async {
    if (!_isInitialized) {
      await init();
    }
    if (!_initCompleter.isCompleted) {
      await _initCompleter.future;
    }
  }

  /// Get cached image bytes, or null if not cached/expired
  Future<Uint8List?> get(String url) async {
    if (!kIsWeb) return null;
    await _ensureInit();
    if (_db == null) return null;

    try {
      final tx = _db!.transaction(_storeName.toJS, 'readonly');
      final store = tx.objectStore(_storeName);
      final request = store.get(url.toJS);

      final completer = Completer<JSAny?>();
      request.onsuccess = (web.Event event) {
        completer.complete((event.target as web.IDBRequest).result);
      }.toJS;
      request.onerror = (web.Event event) {
        completer.complete(null);
      }.toJS;

      final result = await completer.future;
      if (result == null) return null;

      final data = (result as JSObject).dartify() as Map<dynamic, dynamic>?;
      if (data == null) return null;

      final expiresAt = data['expiresAt'] as int?;
      if (expiresAt != null && DateTime.now().millisecondsSinceEpoch > expiresAt) {
        // Expired, delete and return null
        _delete(url);
        return null;
      }

      final base64Data = data['data'] as String?;
      if (base64Data == null) return null;

      return base64Decode(base64Data);
    } catch (e) {
      debugPrint('ImageCacheService get error: $e');
      return null;
    }
  }

  /// Store image bytes in cache
  Future<void> put(String url, Uint8List bytes, {Duration? ttl}) async {
    if (!kIsWeb) return;
    await _ensureInit();
    if (_db == null) return;

    try {
      final effectiveTtl = ttl ?? _defaultTtl;
      final expiresAt = DateTime.now().add(effectiveTtl).millisecondsSinceEpoch;
      
      final data = {
        'data': base64Encode(bytes),
        'expiresAt': expiresAt,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      };

      final tx = _db!.transaction(_storeName.toJS, 'readwrite');
      final store = tx.objectStore(_storeName);
      store.put(data.jsify(), url.toJS);
    } catch (e) {
      debugPrint('ImageCacheService put error: $e');
    }
  }

  /// Delete a cached image
  Future<void> _delete(String url) async {
    if (!kIsWeb || _db == null) return;

    try {
      final tx = _db!.transaction(_storeName.toJS, 'readwrite');
      final store = tx.objectStore(_storeName);
      store.delete(url.toJS);
    } catch (e) {
      debugPrint('ImageCacheService delete error: $e');
    }
  }

  /// Clear all cached images
  Future<void> clearAll() async {
    if (!kIsWeb) return;
    await _ensureInit();
    if (_db == null) return;

    try {
      final tx = _db!.transaction(_storeName.toJS, 'readwrite');
      final store = tx.objectStore(_storeName);
      store.clear();
    } catch (e) {
      debugPrint('ImageCacheService clearAll error: $e');
    }
  }

  /// Get cache stats (approximate)
  Future<Map<String, dynamic>> getStats() async {
    if (!kIsWeb || _db == null) {
      return {'count': 0, 'isWeb': kIsWeb};
    }

    try {
      final tx = _db!.transaction(_storeName.toJS, 'readonly');
      final store = tx.objectStore(_storeName);
      final request = store.count();

      final completer = Completer<int>();
      request.onsuccess = (web.Event event) {
        completer.complete((event.target as web.IDBRequest).result as int? ?? 0);
      }.toJS;
      request.onerror = (web.Event event) {
        completer.complete(0);
      }.toJS;

      final count = await completer.future;
      return {'count': count, 'isWeb': true};
    } catch (e) {
      return {'count': 0, 'isWeb': true, 'error': e.toString()};
    }
  }
}
