import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shipment.dart';

/// Service that communicates with Sendcloud through Firebase Cloud Functions.
/// NEVER calls Sendcloud API directly — always proxies through Cloud Functions.
class SendcloudService {
  static const String _baseUrl =
      'https://europe-west1-inventorymanager-dev-20262.cloudfunctions.net';

  /// Register a tracking number on Sendcloud via Cloud Function.
  /// Returns a map with { sendcloudId, status, trackingUrl, carrier } on success.
  Future<Map<String, dynamic>> registerTracking(
    String trackingNumber, {
    String? carrier,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/registerTracking'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'trackingNumber': trackingNumber,
          if (carrier != null) 'carrier': carrier,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      }

      throw SendcloudException(
        data['error'] ?? 'Failed to register tracking',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is SendcloudException) rethrow;
      throw SendcloudException('Network error: $e');
    }
  }

  /// Get tracking status from Sendcloud via Cloud Function.
  /// Provide either trackingNumber or sendcloudId (or both).
  Future<SendcloudTrackingResult> getTrackingStatus({
    String? trackingNumber,
    int? sendcloudId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/getTrackingStatus'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (trackingNumber != null) 'trackingNumber': trackingNumber,
          if (sendcloudId != null) 'sendcloudId': sendcloudId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return SendcloudTrackingResult.fromJson(data);
      }

      if (response.statusCode == 404) {
        throw SendcloudException(
          'Pacco non trovato su Sendcloud',
          statusCode: 404,
        );
      }

      throw SendcloudException(
        data['error'] ?? 'Failed to get tracking status',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is SendcloudException) rethrow;
      throw SendcloudException('Network error: $e');
    }
  }

  /// List parcels from Sendcloud account via Cloud Function.
  Future<List<Map<String, dynamic>>> listParcels({int limit = 25}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/listSendcloudParcels'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'limit': limit}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['parcels'] ?? []);
      }

      throw SendcloudException(
        data['error'] ?? 'Failed to list parcels',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is SendcloudException) rethrow;
      throw SendcloudException('Network error: $e');
    }
  }
}

/// Result from Sendcloud tracking status query
class SendcloudTrackingResult {
  final int sendcloudId;
  final String? trackingNumber;
  final String status;
  final int? statusId;
  final String? trackingUrl;
  final String? carrier;
  final String? carrierName;
  final List<TrackingEvent> trackingHistory;
  final String? lastUpdate;

  SendcloudTrackingResult({
    required this.sendcloudId,
    this.trackingNumber,
    required this.status,
    this.statusId,
    this.trackingUrl,
    this.carrier,
    this.carrierName,
    required this.trackingHistory,
    this.lastUpdate,
  });

  factory SendcloudTrackingResult.fromJson(Map<String, dynamic> json) {
    final historyList = (json['trackingHistory'] as List?)
            ?.map((e) => TrackingEvent(
                  status: e['status'] ?? 'Unknown',
                  timestamp: e['timestamp'] != null
                      ? DateTime.tryParse(e['timestamp'])
                      : null,
                  location: e['location'],
                  description: e['description'],
                  statusId: e['statusId'],
                ))
            .toList() ??
        [];

    return SendcloudTrackingResult(
      sendcloudId: json['sendcloudId'] ?? 0,
      trackingNumber: json['trackingNumber'],
      status: json['status'] ?? 'Unknown',
      statusId: json['statusId'],
      trackingUrl: json['trackingUrl'],
      carrier: json['carrier'],
      carrierName: json['carrierName'],
      trackingHistory: historyList,
      lastUpdate: json['lastUpdate'],
    );
  }

  /// Convert Sendcloud status to app ShipmentStatus
  ShipmentStatus get appStatus {
    final id = statusId;
    if (id == null) return ShipmentStatus.unknown;
    if (id == 11) return ShipmentStatus.delivered;
    if (id == 1 || id == 99 || id == 2000) return ShipmentStatus.pending;
    if (id == 80 || id == 92 || id == 1000 || id == 1001) {
      return ShipmentStatus.exception;
    }
    if ([3, 4, 5, 6, 8, 12, 22, 31, 32, 62].contains(id)) {
      return ShipmentStatus.inTransit;
    }
    return ShipmentStatus.unknown;
  }
}

class SendcloudException implements Exception {
  final String message;
  final int? statusCode;

  SendcloudException(this.message, {this.statusCode});

  @override
  String toString() => 'SendcloudException: $message (status: $statusCode)';
}
