import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/ebay_listing.dart';
import '../models/ebay_order.dart';

class EbayService {
  static const String _baseUrl =
      'https://europe-west1-inventorymanager-dev-20262.cloudfunctions.net/api/ebay';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final token = await user.getIdToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$_baseUrl$path'), headers: headers);
    if (res.statusCode != 200) {
      throw Exception('eBay API error (${res.statusCode}): ${res.body}');
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> _post(String path, [Map<String, dynamic>? body]) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('eBay API error (${res.statusCode}): ${res.body}');
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    final res = await http.put(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw Exception('eBay API error (${res.statusCode}): ${res.body}');
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final headers = await _authHeaders();
    final res = await http.delete(Uri.parse('$_baseUrl$path'), headers: headers);
    if (res.statusCode != 200) {
      throw Exception('eBay API error (${res.statusCode}): ${res.body}');
    }
    return jsonDecode(res.body);
  }

  // ── Connection ──

  Future<Map<String, dynamic>> getConnectionStatus() async {
    return _get('/status');
  }

  Future<String> getAuthUrl() async {
    final result = await _get('/auth-url');
    return result['url'] as String;
  }

  Future<void> connectEbay(String code) async {
    await _post('/callback', {'code': code});
  }

  Future<void> disconnectEbay() async {
    await _post('/disconnect');
  }

  // ── Listings ──

  Future<Map<String, dynamic>> createListing(Map<String, dynamic> data) async {
    return _post('/listings', data);
  }

  Future<List<EbayListing>> getListings() async {
    if (_uid == null) return [];
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('ebayListings')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((doc) => EbayListing.fromFirestore(doc)).toList();
  }

  Stream<List<EbayListing>> streamListings() {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(_uid)
        .collection('ebayListings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => EbayListing.fromFirestore(d)).toList());
  }

  Future<void> updateListing(String id, Map<String, dynamic> updates) async {
    await _put('/listings/$id', updates);
  }

  Future<void> deleteListing(String id) async {
    await _delete('/listings/$id');
  }

  // ── Orders ──

  Future<void> fetchOrders() async {
    await _get('/orders');
  }

  Stream<List<EbayOrder>> streamOrders() {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(_uid)
        .collection('ebayOrders')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => EbayOrder.fromFirestore(d)).toList());
  }

  Future<void> shipOrder(String orderId, String trackingNumber, String carrier) async {
    await _post('/orders/$orderId/ship', {
      'trackingNumber': trackingNumber,
      'carrier': carrier,
    });
  }

  Future<void> refundOrder(String orderId, String reason, [double? amount]) async {
    await _post('/orders/$orderId/refund', {
      'reason': reason,
      if (amount != null) 'amount': amount,
    });
  }

  // ── Price Check (no user auth needed) ──

  Future<Map<String, dynamic>> priceCheck(String query, {int limit = 10}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$_baseUrl/price-check').replace(queryParameters: {
      'q': query,
      'limit': limit.toString(),
    });
    final res = await http.get(uri, headers: headers);
    if (res.statusCode != 200) {
      throw Exception('Price check error (${res.statusCode}): ${res.body}');
    }
    return jsonDecode(res.body);
  }

  // ── Policies ──

  Future<Map<String, dynamic>> getPolicies() async {
    return _get('/policies');
  }

  Future<Map<String, dynamic>> createDefaultPolicies([Map<String, dynamic>? config]) async {
    return _post('/policies', config ?? {});
  }

  // ── Helpers ──

  /// Check if a product has any non-ended eBay listing (active or draft)
  Future<EbayListing?> getListingForProduct(String productId) async {
    if (_uid == null) return null;
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('ebayListings')
        .where('productId', isEqualTo: productId)
        .get();
    if (snap.docs.isEmpty) return null;
    // Find any listing that's not ended
    for (final doc in snap.docs) {
      final listing = EbayListing.fromFirestore(doc);
      if (listing.status != 'ended') return listing;
    }
    return null;
  }
}
