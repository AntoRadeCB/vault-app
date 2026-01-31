import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../models/shipment.dart';
import '../services/firestore_service.dart';
import 'package:flutter/services.dart';

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

  void _confirmDelete(Shipment shipment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Elimina Spedizione',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Eliminare la spedizione ${shipment.trackingCode}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (shipment.id != null) _fs.deleteShipment(shipment.id!);
            },
            child: const Text('Elimina',
                style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: StaggeredFadeSlide(
            index: 0,
            child: Row(
              children: [
                const Text(
                  'Spedizioni',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 12),
                StreamBuilder<int>(
                  stream: _fs.getActiveShipmentsCount(),
                  builder: (context, snap) {
                    final count = snap.data ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accentOrange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '$count ATTIVE',
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: StaggeredFadeSlide(
            index: 1,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Tutte'),
                  Tab(text: 'In Corso'),
                  Tab(text: 'Consegnate'),
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
                  _buildList(all.where((s) => s.status != ShipmentStatus.delivered).toList()),
                  _buildList(all.where((s) => s.status == ShipmentStatus.delivered).toList()),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<Shipment> shipments) {
    if (shipments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined,
                color: AppColors.textMuted.withValues(alpha: 0.5), size: 64),
            const SizedBox(height: 16),
            const Text(
              'Nessuna spedizione',
              style: TextStyle(color: AppColors.textMuted, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aggiungi un codice tracking quando registri\nun acquisto o una vendita',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: shipments.length,
      itemBuilder: (context, index) {
        return StaggeredFadeSlide(
          index: index + 2,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ShipmentCard(
              shipment: shipments[index],
              onTrack: () => _openTrackingDetail(shipments[index]),
              onUpdateStatus: (status) => _updateStatus(shipments[index], status),
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
  final VoidCallback onTrack;
  final void Function(ShipmentStatus) onUpdateStatus;
  final VoidCallback onDelete;

  const _ShipmentCard({
    required this.shipment,
    required this.onTrack,
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  shipment.statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tracking code
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code, color: AppColors.textMuted, size: 16),
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
                    Clipboard.setData(ClipboardData(text: shipment.trackingCode));
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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.open_in_new, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Traccia',
                          style: TextStyle(
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
              // Status update dropdown
              PopupMenuButton<ShipmentStatus>(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: onUpdateStatus,
                itemBuilder: (_) => [
                  _statusMenuItem(ShipmentStatus.pending, 'In attesa', Icons.schedule, AppColors.accentOrange),
                  _statusMenuItem(ShipmentStatus.inTransit, 'In transito', Icons.local_shipping, AppColors.accentBlue),
                  _statusMenuItem(ShipmentStatus.delivered, 'Consegnato', Icons.check_circle, AppColors.accentGreen),
                  _statusMenuItem(ShipmentStatus.exception, 'Problema', Icons.warning, AppColors.accentRed),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: const Icon(Icons.more_horiz, color: AppColors.textMuted, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(Icons.delete_outline, color: AppColors.accentRed, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<ShipmentStatus> _statusMenuItem(
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
