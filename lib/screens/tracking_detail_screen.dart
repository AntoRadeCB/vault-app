import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../models/shipment.dart';
import '../services/firestore_service.dart';

class TrackingDetailScreen extends StatefulWidget {
  final Shipment shipment;
  final VoidCallback? onBack;

  const TrackingDetailScreen({
    super.key,
    required this.shipment,
    this.onBack,
  });

  @override
  State<TrackingDetailScreen> createState() => _TrackingDetailScreenState();
}

class _TrackingDetailScreenState extends State<TrackingDetailScreen> {
  final FirestoreService _fs = FirestoreService();
  late final String _viewType;
  bool _iframeLoaded = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'tracking-${widget.shipment.trackingCode}-${DateTime.now().millisecondsSinceEpoch}';

    // Use 17track for universal tracking embed
    final trackUrl = 'https://t.17track.net/it#nums=${widget.shipment.trackingCode}';

    // Register the iframe view factory
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = trackUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.borderRadius = '12px'
          ..allowFullscreen = true;

        iframe.onLoad.listen((_) {
          if (mounted) setState(() => _iframeLoaded = true);
        });

        return iframe;
      },
    );
  }

  void _updateStatus(ShipmentStatus newStatus) {
    if (widget.shipment.id == null) return;
    final statusStr = newStatus == ShipmentStatus.pending
        ? 'pending'
        : newStatus == ShipmentStatus.inTransit
            ? 'inTransit'
            : newStatus == ShipmentStatus.delivered
                ? 'delivered'
                : 'exception';
    _fs.updateShipment(widget.shipment.id!, {
      'status': statusStr,
      'lastUpdate': DateTime.now(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Stato aggiornato: ${_statusLabel(newStatus)}'),
        backgroundColor: AppColors.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _statusLabel(ShipmentStatus s) {
    switch (s) {
      case ShipmentStatus.pending: return 'In attesa';
      case ShipmentStatus.inTransit: return 'In transito';
      case ShipmentStatus.delivered: return 'Consegnato';
      case ShipmentStatus.exception: return 'Problema';
      case ShipmentStatus.unknown: return 'Sconosciuto';
    }
  }

  void _openCarrierPage() {
    final url = widget.shipment.trackingUrl;
    html.window.open(url, '_blank');
  }

  Color get _statusColor {
    switch (widget.shipment.status) {
      case ShipmentStatus.pending: return AppColors.accentOrange;
      case ShipmentStatus.inTransit: return AppColors.accentBlue;
      case ShipmentStatus.delivered: return AppColors.accentGreen;
      case ShipmentStatus.exception: return AppColors.accentRed;
      case ShipmentStatus.unknown: return AppColors.textMuted;
    }
  }

  IconData get _statusIcon {
    switch (widget.shipment.status) {
      case ShipmentStatus.pending: return Icons.schedule;
      case ShipmentStatus.inTransit: return Icons.local_shipping;
      case ShipmentStatus.delivered: return Icons.check_circle;
      case ShipmentStatus.exception: return Icons.warning;
      case ShipmentStatus.unknown: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.shipment;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: StaggeredFadeSlide(
            index: 0,
            child: Row(
              children: [
                ScaleOnPress(
                  onTap: widget.onBack,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Tracciamento',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                // Status update menu
                PopupMenuButton<ShipmentStatus>(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: _updateStatus,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _statusColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon, color: _statusColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          s.statusLabel,
                          style: TextStyle(
                            color: _statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down, color: _statusColor, size: 16),
                      ],
                    ),
                  ),
                  itemBuilder: (_) => [
                    _menuItem(ShipmentStatus.pending, 'In attesa', Icons.schedule, AppColors.accentOrange),
                    _menuItem(ShipmentStatus.inTransit, 'In transito', Icons.local_shipping, AppColors.accentBlue),
                    _menuItem(ShipmentStatus.delivered, 'Consegnato', Icons.check_circle, AppColors.accentGreen),
                    _menuItem(ShipmentStatus.exception, 'Problema', Icons.warning, AppColors.accentRed),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Shipment info card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: StaggeredFadeSlide(
            index: 1,
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              glowColor: _statusColor,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.productName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (s.type == ShipmentType.purchase
                                            ? AppColors.accentBlue
                                            : AppColors.accentGreen)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    s.typeLabel.toUpperCase(),
                                    style: TextStyle(
                                      color: s.type == ShipmentType.purchase
                                          ? AppColors.accentBlue
                                          : AppColors.accentGreen,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  s.carrierName,
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Tracking code bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code, color: AppColors.textMuted, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.trackingCode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: s.trackingCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Codice copiato!'),
                                backgroundColor: AppColors.accentTeal,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.all(16),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Icon(Icons.copy, color: AppColors.textMuted, size: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Open carrier page button
                  GestureDetector(
                    onTap: _openCarrierPage,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.accentTeal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.open_in_new, color: AppColors.accentTeal, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Apri su ${s.carrierName}',
                            style: const TextStyle(
                              color: AppColors.accentTeal,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 17track iframe
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: StaggeredFadeSlide(
              index: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Stack(
                    children: [
                      // Iframe
                      SizedBox.expand(
                        child: HtmlElementView(viewType: _viewType),
                      ),
                      // Loading overlay
                      if (!_iframeLoaded)
                        Container(
                          color: AppColors.surface,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: AppColors.accentTeal),
                                SizedBox(height: 16),
                                Text(
                                  'Caricamento tracciamento...',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  PopupMenuItem<ShipmentStatus> _menuItem(
      ShipmentStatus status, String label, IconData icon, Color color) {
    return PopupMenuItem(
      value: status,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
