import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shipment.dart';

/// Service that communicates with Ship24 through Firebase Cloud Functions.
/// NEVER calls Ship24 API directly — always proxies through Cloud Functions.
class TrackingService {
  static const String _baseUrl =
      'https://europe-west1-inventorymanager-dev-20262.cloudfunctions.net';

  /// Register a tracking number on Ship24 via Cloud Function.
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
          if (carrier != null) 'courierCode': carrier,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      }

      throw TrackingException(
        data['error'] ?? 'Failed to register tracking',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is TrackingException) rethrow;
      throw TrackingException('Network error: $e');
    }
  }

  /// Get tracking status from Ship24 via Cloud Function.
  Future<TrackingResult> getTrackingStatus({
    String? trackingNumber,
    String? trackerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/getTrackingStatus'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (trackingNumber != null) 'trackingNumber': trackingNumber,
          if (trackerId != null) 'trackerId': trackerId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return TrackingResult.fromJson(data);
      }

      if (response.statusCode == 404) {
        throw TrackingException(
          'Tracking non trovato',
          statusCode: 404,
        );
      }

      throw TrackingException(
        data['error'] ?? 'Failed to get tracking status',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is TrackingException) rethrow;
      throw TrackingException('Network error: $e');
    }
  }
}

/// Result from Ship24 tracking status query
class TrackingResult {
  final String? trackerId;
  final String? trackingNumber;
  final String status;
  final String? statusCode;
  final String? trackingUrl;
  final String? carrier;
  final String? carrierName;
  final List<TrackingEvent> trackingHistory;
  final String? lastUpdate;
  final String? estimatedDelivery;
  final String? message;

  TrackingResult({
    this.trackerId,
    this.trackingNumber,
    required this.status,
    this.statusCode,
    this.trackingUrl,
    this.carrier,
    this.carrierName,
    required this.trackingHistory,
    this.lastUpdate,
    this.estimatedDelivery,
    this.message,
  });

  factory TrackingResult.fromJson(Map<String, dynamic> json) {
    final historyList = (json['trackingHistory'] as List?)
            ?.map((e) => TrackingEvent(
                  status: e['status'] ?? 'Unknown',
                  timestamp: e['timestamp'] != null
                      ? DateTime.tryParse(e['timestamp'])
                      : null,
                  location: e['location'],
                  description: e['description'],
                  statusId: null,
                ))
            .toList() ??
        [];

    return TrackingResult(
      trackerId: json['trackerId'],
      trackingNumber: json['trackingNumber'],
      status: json['status'] ?? 'pending',
      statusCode: json['statusCode'],
      trackingUrl: json['trackingUrl'],
      carrier: json['carrier'],
      carrierName: json['carrierName'],
      trackingHistory: historyList,
      lastUpdate: json['lastUpdate'],
      estimatedDelivery: json['estimatedDelivery'],
      message: json['message'],
    );
  }

  /// Convert Ship24 milestone to app ShipmentStatus
  ShipmentStatus get appStatus {
    switch (status) {
      case 'delivered':
        return ShipmentStatus.delivered;
      case 'in_transit':
      case 'out_for_delivery':
      case 'available_for_pickup':
        return ShipmentStatus.inTransit;
      case 'exception':
      case 'attempt_fail':
        return ShipmentStatus.exception;
      case 'pending':
      case 'info_received':
        return ShipmentStatus.pending;
      default:
        return ShipmentStatus.unknown;
    }
  }
}

class TrackingException implements Exception {
  final String message;
  final int? statusCode;

  TrackingException(this.message, {this.statusCode});

  @override
  String toString() => 'TrackingException: $message (status: $statusCode)';
}
