import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  shipmentUpdate,
  sale,
  lowStock,
  system,
}

class AppNotification {
  final String? id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool read;
  final String? referenceId; // e.g. shipment id, product id
  final Map<String, dynamic>? metadata;

  const AppNotification({
    this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.read = false,
    this.referenceId,
    this.metadata,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: _typeFromString(data['type']),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      read: data['read'] ?? false,
      referenceId: data['referenceId'],
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'type': _typeToString(type),
      'createdAt': Timestamp.fromDate(createdAt),
      'read': read,
      if (referenceId != null) 'referenceId': referenceId,
      if (metadata != null) 'metadata': metadata,
    };
  }

  String get typeLabel {
    switch (type) {
      case NotificationType.shipmentUpdate:
        return 'SPEDIZIONE';
      case NotificationType.sale:
        return 'VENDITA';
      case NotificationType.lowStock:
        return 'STOCK BASSO';
      case NotificationType.system:
        return 'SISTEMA';
    }
  }

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      createdAt: createdAt,
      read: read ?? this.read,
      referenceId: referenceId,
      metadata: metadata,
    );
  }

  static NotificationType _typeFromString(String? s) {
    switch (s) {
      case 'shipmentUpdate':
        return NotificationType.shipmentUpdate;
      case 'sale':
        return NotificationType.sale;
      case 'lowStock':
        return NotificationType.lowStock;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.system;
    }
  }

  static String _typeToString(NotificationType t) {
    switch (t) {
      case NotificationType.shipmentUpdate:
        return 'shipmentUpdate';
      case NotificationType.sale:
        return 'sale';
      case NotificationType.lowStock:
        return 'lowStock';
      case NotificationType.system:
        return 'system';
    }
  }
}
