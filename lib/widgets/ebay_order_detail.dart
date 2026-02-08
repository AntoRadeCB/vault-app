import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/ebay_order.dart';
import '../services/ebay_service.dart';
import 'animated_widgets.dart';

class EbayOrderDetailSheet extends StatefulWidget {
  final EbayOrder order;
  final EbayService ebayService;

  const EbayOrderDetailSheet({
    super.key,
    required this.order,
    required this.ebayService,
  });

  @override
  State<EbayOrderDetailSheet> createState() => _EbayOrderDetailSheetState();
}

class _EbayOrderDetailSheetState extends State<EbayOrderDetailSheet> {
  final _trackingController = TextEditingController();
  String _carrier = 'Poste Italiane';
  bool _shipping = false;
  bool _refunding = false;

  static const _carriers = [
    'Poste Italiane',
    'BRT',
    'GLS',
    'DHL',
    'UPS',
    'FedEx',
    'SDA',
    'TNT',
    'Altro',
  ];

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  Future<void> _markShipped() async {
    final tracking = _trackingController.text.trim();
    if (tracking.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci il numero di tracking'),
          backgroundColor: AppColors.accentOrange,
        ),
      );
      return;
    }
    setState(() => _shipping = true);
    try {
      await widget.ebayService.shipOrder(
          widget.order.ebayOrderId, tracking, _carrier);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ordine segnato come spedito!'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: AppColors.accentRed),
        );
      }
    } finally {
      if (mounted) setState(() => _shipping = false);
    }
  }

  Future<void> _issueRefund() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Conferma rimborso',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Vuoi rimborsare ${widget.order.formattedTotal} a ${widget.order.buyerUsername}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rimborsa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _refunding = true);
    try {
      await widget.ebayService.refundOrder(
          widget.order.ebayOrderId, 'BUYER_CANCEL');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rimborso effettuato'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: AppColors.accentRed),
        );
      }
    } finally {
      if (mounted) setState(() => _refunding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final address = order.shippingAddress;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                const Icon(Icons.receipt_long, color: AppColors.accentBlue, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Ordine',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ),
                _statusBadge(order.status),
              ],
            ),
            const SizedBox(height: 20),

            // Items
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          if (item.imageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(item.imageUrl!,
                                  width: 40, height: 40, fit: BoxFit.cover),
                            ),
                          if (item.imageUrl != null) const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14)),
                                Text('x${item.quantity}',
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Text('€${item.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                )),

            const Divider(color: AppColors.surfaceLight, height: 32),

            // Buyer & address
            _infoRow('Acquirente', order.buyerUsername),
            _infoRow('Totale', order.formattedTotal),
            if (address != null) ...[
              _infoRow('Indirizzo', _formatAddress(address)),
            ],
            if (order.tracking != null) ...[
              _infoRow('Tracking', order.tracking!['trackingNumber'] ?? ''),
              _infoRow('Corriere', order.tracking!['carrier'] ?? ''),
            ],

            const SizedBox(height: 24),

            // Actions
            if (order.canShip) ...[
              const Text('Segna come spedito',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _carrier,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Corriere',
                  labelStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                items: _carriers
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _carrier = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _trackingController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Numero tracking',
                  labelStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.blueButtonGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _shipping ? null : _markShipped,
                    icon: _shipping
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.local_shipping, color: Colors.white),
                    label: const Text('Segna come spedito',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ],

            if (order.canRefund) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _refunding ? null : _issueRefund,
                  icon: _refunding
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.accentRed))
                      : const Icon(Icons.undo, color: AppColors.accentRed),
                  label: const Text('Rimborsa ordine',
                      style: TextStyle(color: AppColors.accentRed)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.accentRed),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'NOT_STARTED':
        color = AppColors.accentOrange;
        label = 'Pagato';
        break;
      case 'FULFILLED':
        color = AppColors.accentGreen;
        label = 'Spedito';
        break;
      case 'REFUNDED':
        color = AppColors.accentRed;
        label = 'Rimborsato';
        break;
      default:
        color = AppColors.accentBlue;
        label = 'In corso';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  String _formatAddress(Map<String, dynamic> addr) {
    final parts = <String>[
      if (addr['fullName'] != null) addr['fullName'],
      if (addr['addressLine1'] != null) addr['addressLine1'],
      if (addr['addressLine2'] != null) addr['addressLine2'],
      if (addr['city'] != null || addr['postalCode'] != null)
        '${addr['postalCode'] ?? ''} ${addr['city'] ?? ''}'.trim(),
      if (addr['countryCode'] != null) addr['countryCode'],
    ];
    return parts.join(', ');
  }
}
