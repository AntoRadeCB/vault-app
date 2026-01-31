import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html;
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../models/shipment.dart';
import '../services/firestore_service.dart';
import '../services/sendcloud_service.dart';

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
  final SendcloudService _sendcloud = SendcloudService();
  bool _isRefreshing = false;
  late Shipment _shipment;

  @override
  void initState() {
    super.initState();
    _shipment = widget.shipment;
  }

  Future<void> _refreshTracking() async {
    setState(() => _isRefreshing = true);

    try {
      final result = await _sendcloud.getTrackingStatus(
        trackingNumber: _shipment.trackingCode,
        sendcloudId: _shipment.sendcloudId,
      );

      if (!mounted) return;

      // Map Sendcloud status to app status
      String appStatusStr;
      switch (result.appStatus) {
        case ShipmentStatus.pending:
          appStatusStr = 'pending';
          break;
        case ShipmentStatus.inTransit:
          appStatusStr = 'inTransit';
          break;
        case ShipmentStatus.delivered:
          appStatusStr = 'delivered';
          break;
        case ShipmentStatus.exception:
          appStatusStr = 'exception';
          break;
        default:
          appStatusStr = 'unknown';
      }

      if (_shipment.id != null) {
        await _fs.updateShipmentSendcloud(
          _shipment.id!,
          sendcloudId: result.sendcloudId,
          sendcloudStatus: result.status,
          sendcloudTrackingUrl: result.trackingUrl,
          appStatus: appStatusStr,
          trackingHistory:
              result.trackingHistory.isNotEmpty ? result.trackingHistory : null,
        );
      }

      // Update local state
      setState(() {
        _shipment = _shipment.copyWith(
          sendcloudId: result.sendcloudId,
          sendcloudStatus: result.status,
          sendcloudTrackingUrl: result.trackingUrl,
          status: result.appStatus,
          trackingHistory:
              result.trackingHistory.isNotEmpty ? result.trackingHistory : null,
          lastUpdate: DateTime.now(),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aggiornato: ${result.status}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    } on SendcloudException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.accentOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: AppColors.accentRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _updateStatus(ShipmentStatus newStatus) {
    if (_shipment.id == null) return;
    final statusStr = newStatus == ShipmentStatus.pending
        ? 'pending'
        : newStatus == ShipmentStatus.inTransit
            ? 'inTransit'
            : newStatus == ShipmentStatus.delivered
                ? 'delivered'
                : 'exception';
    _fs.updateShipment(_shipment.id!, {
      'status': statusStr,
      'lastUpdate': DateTime.now(),
    });
    setState(() {
      _shipment = _shipment.copyWith(
        status: newStatus,
        lastUpdate: DateTime.now(),
      );
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

  void _openCarrierPage() {
    final url = _shipment.carrierTrackingUrl;
    html.window.open(url, '_blank');
  }

  Color get _statusColor {
    switch (_shipment.status) {
      case ShipmentStatus.pending:
        return AppColors.accentOrange;
      case ShipmentStatus.inTransit:
        return AppColors.accentBlue;
      case ShipmentStatus.delivered:
        return AppColors.accentGreen;
      case ShipmentStatus.exception:
        return AppColors.accentRed;
      case ShipmentStatus.unknown:
        return AppColors.textMuted;
    }
  }

  IconData get _statusIcon {
    switch (_shipment.status) {
      case ShipmentStatus.pending:
        return Icons.schedule;
      case ShipmentStatus.inTransit:
        return Icons.local_shipping;
      case ShipmentStatus.delivered:
        return Icons.check_circle;
      case ShipmentStatus.exception:
        return Icons.warning;
      case ShipmentStatus.unknown:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _shipment;

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
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 22),
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
                // Refresh button
                ScaleOnPress(
                  onTap: _isRefreshing ? null : _refreshTracking,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.accentBlue.withValues(alpha: 0.2)),
                    ),
                    child: _isRefreshing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accentBlue,
                            ),
                          )
                        : const Icon(Icons.refresh,
                            color: AppColors.accentBlue, size: 22),
                  ),
                ),
                // Status update menu
                PopupMenuButton<ShipmentStatus>(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: _updateStatus,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _statusColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon, color: _statusColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          s.displayStatus,
                          style: TextStyle(
                            color: _statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down,
                            color: _statusColor, size: 16),
                      ],
                    ),
                  ),
                  itemBuilder: (_) => [
                    _menuItem(ShipmentStatus.pending, 'In attesa',
                        Icons.schedule, AppColors.accentOrange),
                    _menuItem(ShipmentStatus.inTransit, 'In transito',
                        Icons.local_shipping, AppColors.accentBlue),
                    _menuItem(ShipmentStatus.delivered, 'Consegnato',
                        Icons.check_circle, AppColors.accentGreen),
                    _menuItem(ShipmentStatus.exception, 'Problema',
                        Icons.warning, AppColors.accentRed),
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
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
                                      color:
                                          s.type == ShipmentType.purchase
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
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13),
                                ),
                                if (s.sendcloudId != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentTeal
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'SENDCLOUD',
                                      style: TextStyle(
                                        color: AppColors.accentTeal,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code,
                            color: AppColors.textMuted, size: 16),
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
                            Clipboard.setData(
                                ClipboardData(text: s.trackingCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Codice copiato!'),
                                backgroundColor: AppColors.accentTeal,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                margin: const EdgeInsets.all(16),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Icon(Icons.copy,
                              color: AppColors.textMuted, size: 16),
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
                        border: Border.all(
                            color:
                                AppColors.accentTeal.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.open_in_new,
                              color: AppColors.accentTeal, size: 16),
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

        // Tracking Timeline
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: StaggeredFadeSlide(
              index: 2,
              child: _buildTrackingTimeline(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingTimeline() {
    final history = _shipment.trackingHistory;

    if (history == null || history.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timeline,
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                  size: 56),
              const SizedBox(height: 16),
              const Text(
                'Nessun evento di tracking',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Premi il bottone 🔄 per aggiornare\nlo stato da Sendcloud',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ScaleOnPress(
                onTap: _isRefreshing ? null : _refreshTracking,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppColors.blueButtonGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isRefreshing)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(Icons.refresh,
                            color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Aggiorna da Sendcloud',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sort events: most recent first
    final sortedHistory = List<TrackingEvent>.from(history);
    sortedHistory.sort((a, b) {
      if (a.timestamp == null && b.timestamp == null) return 0;
      if (a.timestamp == null) return 1;
      if (b.timestamp == null) return -1;
      return b.timestamp!.compareTo(a.timestamp!);
    });

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.timeline, color: AppColors.accentBlue, size: 18),
              const SizedBox(width: 8),
              const Text(
                'CRONOLOGIA TRACKING',
                style: TextStyle(
                  color: AppColors.accentBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                '${sortedHistory.length} eventi',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Timeline
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: sortedHistory.length,
              itemBuilder: (context, index) {
                final event = sortedHistory[index];
                final isFirst = index == 0;
                final isLast = index == sortedHistory.length - 1;

                return _TimelineEventTile(
                  event: event,
                  isFirst: isFirst,
                  isLast: isLast,
                  statusColor: isFirst ? _statusColor : AppColors.textMuted,
                );
              },
            ),
          ),
        ],
      ),
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
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// A single timeline event tile
class _TimelineEventTile extends StatelessWidget {
  final TrackingEvent event;
  final bool isFirst;
  final bool isLast;
  final Color statusColor;

  const _TimelineEventTile({
    required this.event,
    required this.isFirst,
    required this.isLast,
    required this.statusColor,
  });

  IconData get _eventIcon {
    final status = event.status.toLowerCase();
    if (status.contains('deliver') || status.contains('consegn')) {
      return Icons.check_circle;
    }
    if (status.contains('transit') || status.contains('transito') || status.contains('route')) {
      return Icons.local_shipping;
    }
    if (status.contains('hub') || status.contains('sort') || status.contains('warehouse')) {
      return Icons.warehouse;
    }
    if (status.contains('pickup') || status.contains('collect') || status.contains('ritir')) {
      return Icons.inventory;
    }
    if (status.contains('exception') || status.contains('error') || status.contains('problem')) {
      return Icons.warning;
    }
    if (status.contains('return') || status.contains('reso')) {
      return Icons.undo;
    }
    if (status.contains('label') || status.contains('print') || status.contains('annou')) {
      return Icons.description;
    }
    return Icons.circle;
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column (line + dot)
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Top line
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 8,
                    color: AppColors.textMuted.withValues(alpha: 0.2),
                  )
                else
                  const SizedBox(height: 8),
                // Dot
                Container(
                  width: isFirst ? 16 : 10,
                  height: isFirst ? 16 : 10,
                  decoration: BoxDecoration(
                    color: isFirst
                        ? statusColor
                        : AppColors.textMuted.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    boxShadow: isFirst
                        ? [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: isFirst
                      ? Icon(_eventIcon, color: Colors.white, size: 10)
                      : null,
                ),
                // Bottom line
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : AppColors.textMuted.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Event content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFirst
                    ? statusColor.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isFirst
                      ? statusColor.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.04),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _eventIcon,
                        color: isFirst ? statusColor : AppColors.textMuted,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.description ?? event.status,
                          style: TextStyle(
                            color: isFirst ? Colors.white : AppColors.textSecondary,
                            fontWeight: isFirst ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (event.timestamp != null) ...[
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.textMuted.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(event.timestamp!),
                          style: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (event.location != null &&
                          event.location!.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: AppColors.textMuted.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: TextStyle(
                              color:
                                  AppColors.textMuted.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime ts) {
    final now = DateTime.now();
    final diff = now.difference(ts);

    final time =
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';

    if (diff.inDays == 0) {
      return 'Oggi, $time';
    } else if (diff.inDays == 1) {
      return 'Ieri, $time';
    } else {
      return '${ts.day}/${ts.month}/${ts.year} $time';
    }
  }
}
