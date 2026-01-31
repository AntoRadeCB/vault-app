import 'package:cloud_firestore/cloud_firestore.dart';

enum ShipmentType { purchase, sale }

enum ShipmentStatus { pending, inTransit, delivered, exception, unknown }

class Shipment {
  final String? id;
  final String trackingCode;
  final String carrier;
  final String carrierName;
  final ShipmentType type;
  final String productName;
  final String? productId;
  final ShipmentStatus status;
  final DateTime createdAt;
  final DateTime? lastUpdate;
  final String? lastEvent;

  const Shipment({
    this.id,
    required this.trackingCode,
    required this.carrier,
    required this.carrierName,
    required this.type,
    required this.productName,
    this.productId,
    this.status = ShipmentStatus.pending,
    required this.createdAt,
    this.lastUpdate,
    this.lastEvent,
  });

  String get statusLabel {
    switch (status) {
      case ShipmentStatus.pending:
        return 'In attesa';
      case ShipmentStatus.inTransit:
        return 'In transito';
      case ShipmentStatus.delivered:
        return 'Consegnato';
      case ShipmentStatus.exception:
        return 'Problema';
      case ShipmentStatus.unknown:
        return 'Sconosciuto';
    }
  }

  String get typeLabel => type == ShipmentType.purchase ? 'Acquisto' : 'Vendita';

  /// Auto-detect carrier from tracking code
  static CarrierInfo detectCarrier(String code) {
    final c = code.trim().toUpperCase();

    // Poste Italiane — RR/LY/CX/EE + 9 digits + IT, or various intl formats
    if (RegExp(r'^[A-Z]{2}\d{9}[A-Z]{2}$').hasMatch(c) && c.endsWith('IT')) {
      return CarrierInfo('poste_italiane', 'Poste Italiane');
    }

    // BRT/Bartolini — typically 12 digits or BRT prefix
    if (c.startsWith('BRT') || (RegExp(r'^\d{12}$').hasMatch(c))) {
      return CarrierInfo('brt', 'BRT');
    }

    // GLS — alphanumeric, often starts with specific patterns
    if (c.startsWith('GLS') || RegExp(r'^[A-Z0-9]{11,14}$').hasMatch(c) && c.contains(RegExp(r'[A-Z]')) && c.contains(RegExp(r'[0-9]'))) {
      // Could be GLS or generic, check more specific patterns first
    }

    // DHL — 10 digits, or JD + 18 digits, or 3-4 digits
    if (RegExp(r'^\d{10}$').hasMatch(c) || c.startsWith('JD') || RegExp(r'^\d{20,22}$').hasMatch(c)) {
      return CarrierInfo('dhl', 'DHL');
    }

    // UPS — 1Z + 16 alphanumeric
    if (c.startsWith('1Z') && c.length == 18) {
      return CarrierInfo('ups', 'UPS');
    }

    // FedEx — 12, 15, or 20 digits
    if (RegExp(r'^\d{12}$').hasMatch(c) || RegExp(r'^\d{15}$').hasMatch(c) || RegExp(r'^\d{20}$').hasMatch(c)) {
      return CarrierInfo('fedex', 'FedEx');
    }

    // SDA — alphanumeric, Italian
    if (c.startsWith('SDA') || RegExp(r'^[A-Z]\d{13}$').hasMatch(c)) {
      return CarrierInfo('sda', 'SDA');
    }

    // InPost / Mondial Relay / Vinted GO
    if (c.startsWith('MP') || c.startsWith('MR')) {
      return CarrierInfo('mondial_relay', 'Mondial Relay');
    }

    // TNT — 9 digits or GD + digits
    if (c.startsWith('GD') || RegExp(r'^\d{9}$').hasMatch(c)) {
      return CarrierInfo('tnt', 'TNT');
    }

    // Amazon Logistics — TBA
    if (c.startsWith('TBA')) {
      return CarrierInfo('amazon', 'Amazon Logistics');
    }

    // Generic fallback
    return CarrierInfo('generic', 'Corriere');
  }

  /// Get tracking URL for the carrier
  String get trackingUrl {
    switch (carrier) {
      case 'poste_italiane':
        return 'https://www.poste.it/cerca/index.html#/risultati-702702702702702-702/$trackingCode';
      case 'brt':
        return 'https://vas.brt.it/vas/sped_det_show.hsm?referer=sped_numspe_par.htm&Ession_id=&bession_id=&Ression_id=&lingua=it&spession_id=$trackingCode';
      case 'dhl':
        return 'https://www.dhl.com/it-it/home/tracciamento.html?tracking-id=$trackingCode';
      case 'ups':
        return 'https://www.ups.com/track?tracknum=$trackingCode&loc=it_IT';
      case 'fedex':
        return 'https://www.fedex.com/fedextrack/?trknbr=$trackingCode';
      case 'sda':
        return 'https://www.sda.it/wps/portal/Servizi_online/ricerca_spedizioni?locale=it&tression_id=$trackingCode';
      case 'gls':
        return 'https://www.gls-italy.com/?option=com_gls&view=track_e_trace&mode=search&numero_spedizione=$trackingCode&tipo_ricerca=NAZ';
      case 'tnt':
        return 'https://www.tnt.it/tracking/traccia.html?cons=$trackingCode';
      case 'mondial_relay':
        return 'https://www.mondialrelay.it/tracking/?numeroExpedition=$trackingCode';
      case 'amazon':
        return 'https://track.amazon.it/tracking/$trackingCode';
      default:
        // Use 17track as universal fallback
        return 'https://t.17track.net/it#nums=$trackingCode';
    }
  }

  factory Shipment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Shipment(
      id: doc.id,
      trackingCode: data['trackingCode'] ?? '',
      carrier: data['carrier'] ?? 'generic',
      carrierName: data['carrierName'] ?? 'Corriere',
      type: data['type'] == 'sale' ? ShipmentType.sale : ShipmentType.purchase,
      productName: data['productName'] ?? '',
      productId: data['productId'],
      status: _statusFromString(data['status']),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastUpdate: data['lastUpdate'] != null
          ? (data['lastUpdate'] as Timestamp).toDate()
          : null,
      lastEvent: data['lastEvent'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'trackingCode': trackingCode,
      'carrier': carrier,
      'carrierName': carrierName,
      'type': type == ShipmentType.sale ? 'sale' : 'purchase',
      'productName': productName,
      'productId': productId,
      'status': _statusToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdate': lastUpdate != null ? Timestamp.fromDate(lastUpdate!) : null,
      'lastEvent': lastEvent,
    };
  }

  static ShipmentStatus _statusFromString(String? s) {
    switch (s) {
      case 'inTransit':
        return ShipmentStatus.inTransit;
      case 'delivered':
        return ShipmentStatus.delivered;
      case 'exception':
        return ShipmentStatus.exception;
      case 'pending':
        return ShipmentStatus.pending;
      default:
        return ShipmentStatus.unknown;
    }
  }

  static String _statusToString(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.pending:
        return 'pending';
      case ShipmentStatus.inTransit:
        return 'inTransit';
      case ShipmentStatus.delivered:
        return 'delivered';
      case ShipmentStatus.exception:
        return 'exception';
      case ShipmentStatus.unknown:
        return 'unknown';
    }
  }

  Shipment copyWith({
    String? id,
    String? trackingCode,
    String? carrier,
    String? carrierName,
    ShipmentType? type,
    String? productName,
    String? productId,
    ShipmentStatus? status,
    DateTime? createdAt,
    DateTime? lastUpdate,
    String? lastEvent,
  }) {
    return Shipment(
      id: id ?? this.id,
      trackingCode: trackingCode ?? this.trackingCode,
      carrier: carrier ?? this.carrier,
      carrierName: carrierName ?? this.carrierName,
      type: type ?? this.type,
      productName: productName ?? this.productName,
      productId: productId ?? this.productId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      lastEvent: lastEvent ?? this.lastEvent,
    );
  }
}

class CarrierInfo {
  final String id;
  final String name;
  const CarrierInfo(this.id, this.name);
}
