import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../models/shipment.dart';
import '../services/firestore_service.dart';
import '../services/tracking_service.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';

class ShipmentsScreen extends StatefulWidget {
  final void Function(Shipment shipment)? onTrackShipment;

  const ShipmentsScreen({super.key, this.onTrackShipment});

  @override
  State<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends State<ShipmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _fs = FirestoreService();
  final TrackingService _tracking = TrackingService();
  final Set<String> _refreshingIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openTrackingDetail(Shipment shipment) {
    widget.onTrackShipment?.call(shipment);
  }

  void _updateStatus(Shipment shipment, ShipmentStatus newStatus) {
    if (shipment.id == null) return;
    final statusStr = newStatus == ShipmentStatus.pending
        ? 'pending'
        : newStatus == ShipmentStatus.inTransit
            ? 'inTransit'
            : newStatus == ShipmentStatus.delivered
                ? 'delivered'
                : 'exception';
    _fs.updateShipment(shipment.id!, {
      'status': statusStr,
      'lastUpdate': DateTime.now(),
    });
  }

  Future<void> _refreshTracking(Shipment shipment) async {
    if (shipment.id == null) return;
    setState(() => _refreshingIds.add(shipment.id!));

    try {
      final result = await _tracking.getTrackingStatus(
        trackingNumber: shipment.trackingCode,
        trackerId: shipment.trackerId,
      );

      if (!mounted) return;

      // Map Ship24 status to app status
      String appStatus;
      switch (result.appStatus) {
        case ShipmentStatus.pending:
          appStatus = 'pending';
          break;
        case ShipmentStatus.inTransit:
          appStatus = 'inTransit';
          break;
        case ShipmentStatus.delivered:
          appStatus = 'delivered';
          break;
        case ShipmentStatus.exception:
          appStatus = 'exception';
          break;
        default:
          appStatus = 'unknown';
      }

      await _fs.updateShipmentTracking(
        shipment.id!,
        trackerId: result.trackerId,
        trackingApiStatus: result.status,
        externalTrackingUrl: result.trackingUrl,
        appStatus: appStatus,
        trackingHistory:
            result.trackingHistory.isNotEmpty ? result.trackingHistory : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.updated(result.status),
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
    } on TrackingException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  e.message,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.accentOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
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
      if (mounted) {
        setState(() => _refreshingIds.remove(shipment.id));
      }
    }
  }

  void _confirmDelete(Shipment shipment) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.deleteShipment,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          l.confirmDeleteShipment(shipment.trackingCode),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel,
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (shipment.id != null) _fs.deleteShipment(shipment.id!);
            },
            child: Text(l.delete,
                style: const TextStyle(
                    color: AppColors.accentRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: StaggeredFadeSlide(
            index: 0,
            child: Row(
              children: [
                Text(
                  l.shipments,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                StreamBuilder<int>(
                  stream: _fs.getActiveShipmentsCount(),
                  builder: (context, snap) {
                    final count = snap.data ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accentOrange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        l.nActive(count),
                        style: const TextStyle(
                          color: AppColors.accentOrange,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: StaggeredFadeSlide(
            index: 1,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: AppColors.blueButtonGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentBlue.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: l.all),
                  Tab(text: l.inProgress),
                  Tab(text: l.delivered),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<List<Shipment>>(
            stream: _fs.getShipments(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accentBlue),
                );
              }
              final all = snapshot.data ?? [];

              return TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildList(all),
                  _buildList(all
                      .where((s) => s.status != ShipmentStatus.delivered)
                      .toList()),
                  _buildList(all
                      .where((s) => s.status == ShipmentStatus.delivered)
                      .toList()),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<Shipment> shipments) {
    final l = AppLocalizations.of(context)!;
    if (shipments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined,
                color: AppColors.textMuted.withValues(alpha: 0.5), size: 64),
            const SizedBox(height: 16),
            Text(
              l.noShipments,
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              l.addTrackingWhenRegistering,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: shipments.length,
      itemBuilder: (context, index) {
        return StaggeredFadeSlide(
          index: index + 2,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ShipmentCard(
              shipment: shipments[index],
              isRefreshing: _refreshingIds.contains(shipments[index].id),
              onTrack: () => _openTrackingDetail(shipments[index]),
              onRefresh: () => _refreshTracking(shipments[index]),
              onUpdateStatus: (status) =>
                  _updateStatus(shipments[index], status),
              onDelete: () => _confirmDelete(shipments[index]),
            ),
          ),
        );
      },
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  final Shipment shipment;
  final bool isRefreshing;
  final VoidCallback onTrack;
  final VoidCallback onRefresh;
  final void Function(ShipmentStatus) onUpdateStatus;
  final VoidCallback onDelete;

  const _ShipmentCard({
    required this.shipment,
    required this.isRefreshing,
    required this.onTrack,
    required this.onRefresh,
    required this.onUpdateStatus,
    required this.onDelete,
  });

  Color get _statusColor {
    switch (shipment.status) {
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
    switch (shipment.status) {
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
    final l = AppLocalizations.of(context)!;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      glowColor: _statusColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: product + type badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_statusIcon, color: _statusColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shipment.productName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (shipment.type == ShipmentType.purchase
                                    ? AppColors.accentBlue
                                    : AppColors.accentGreen)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            shipment.typeLabel.toUpperCase(),
                            style: TextStyle(
                              color: shipment.type == ShipmentType.purchase
                                  ? AppColors.accentBlue
                                  : AppColors.accentGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          shipment.carrierName,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _statusColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  shipment.displayStatus,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tracking code
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code,
                    color: AppColors.textMuted, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    shipment.trackingCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: shipment.trackingCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l.codeCopied),
                        backgroundColor: AppColors.accentTeal,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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

          // Last update indicator
          if (shipment.lastUpdate != null || shipment.trackingApiStatus != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  if (shipment.trackerId != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l.ship24,
                        style: TextStyle(
                          color: AppColors.accentTeal,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  if (shipment.lastUpdate != null)
                    Text(
                      l.lastUpdate(_formatDate(shipment.lastUpdate!)),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ScaleOnPress(
                  onTap: onTrack,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accentTeal, Color(0xFF00897B)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.open_in_new,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          l.track,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Refresh from Ship24 button
              ScaleOnPress(
                onTap: isRefreshing ? null : onRefresh,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.accentBlue.withValues(alpha: 0.2)),
                  ),
                  child: isRefreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentBlue,
                          ),
                        )
                      : const Icon(Icons.refresh,
                          color: AppColors.accentBlue, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              // Status update dropdown
              PopupMenuButton<ShipmentStatus>(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: onUpdateStatus,
                itemBuilder: (_) => [
                  _statusMenuItem(ShipmentStatus.pending, l.pending,
                      Icons.schedule, AppColors.accentOrange),
                  _statusMenuItem(ShipmentStatus.inTransit, l.inTransit,
                      Icons.local_shipping, AppColors.accentBlue),
                  _statusMenuItem(ShipmentStatus.delivered, l.deliveredStatus,
                      Icons.check_circle, AppColors.accentGreen),
                  _statusMenuItem(ShipmentStatus.exception, l.problem,
                      Icons.warning, AppColors.accentRed),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: const Icon(Icons.more_horiz,
                      color: AppColors.textMuted, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.accentRed.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(Icons.delete_outline,
                      color: AppColors.accentRed, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}/${date.year}';
  }

  PopupMenuItem<ShipmentStatus> _statusMenuItem(
      ShipmentStatus status, String label, IconData icon, Color color) {
    return PopupMenuItem(
      value: status,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(label,
              style:
                  TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
