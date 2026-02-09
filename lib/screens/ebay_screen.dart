import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../services/ebay_service.dart';
import '../models/ebay_listing.dart';
import '../models/ebay_order.dart';
import '../widgets/ebay_order_detail.dart';

class EbayScreen extends StatefulWidget {
  const EbayScreen({super.key});

  @override
  State<EbayScreen> createState() => _EbayScreenState();
}

class _EbayScreenState extends State<EbayScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EbayService _ebayService = EbayService();
  bool _connected = false;
  String? _ebayUserId;
  bool _loading = true;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkConnection();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    try {
      final status = await _ebayService.getConnectionStatus();
      if (mounted) {
        setState(() {
          _connected = status['connected'] == true;
          _ebayUserId = status['ebayUserId'];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _connect() async {
    setState(() => _connecting = true);
    try {
      final url = await _ebayService.getAuthUrl();
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      // After user returns, show a dialog to paste the code
      if (!mounted) return;
      final code = await _showCodeDialog();
      if (code != null && code.isNotEmpty) {
        await _ebayService.connectEbay(code);
        await _checkConnection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: AppColors.accentRed),
        );
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<String?> _showCodeDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Codice di autorizzazione',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Dopo aver autorizzato su eBay, incolla qui il codice dalla URL di callback.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Codice...'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Connetti'),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnect() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Disconnetti eBay',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Vuoi disconnettere il tuo account eBay?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disconnetti'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _ebayService.disconnectEbay();
      await _checkConnection();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.accentBlue)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          _buildHeader(),
          if (_connected) ...[
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ListingsTab(ebayService: _ebayService),
                  _OrdersTab(ebayService: _ebayService),
                  _SettingsTab(),
                ],
              ),
            ),
          ] else
            Expanded(child: _buildConnectPrompt()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return StaggeredFadeSlide(
      index: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.store, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('eBay',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  if (_connected)
                    Text(_ebayUserId != null ? 'Connesso come $_ebayUserId' : 'Connesso',
                        style: const TextStyle(
                            color: AppColors.accentGreen, fontSize: 13)),
                ],
              ),
            ),
            if (_connected)
              IconButton(
                onPressed: _disconnect,
                icon: const Icon(Icons.link_off, color: AppColors.accentRed),
                tooltip: 'Disconnetti',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppColors.headerGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textMuted,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Inserzioni'),
          Tab(text: 'Ordini'),
          Tab(text: 'Impostazioni'),
        ],
      ),
    );
  }

  Widget _buildConnectPrompt() {
    return Center(
      child: StaggeredFadeSlide(
        index: 1,
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.store_outlined,
                      color: AppColors.accentBlue, size: 48),
                ),
                const SizedBox(height: 24),
                const Text('Collega il tuo account eBay',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Vendi le tue carte direttamente su eBay dalla tua collezione.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.blueButtonGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ElevatedButton(
                      onPressed: _connecting ? null : _connect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _connecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Connetti eBay',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Listings Tab ──

class _ListingsTab extends StatelessWidget {
  final EbayService ebayService;
  const _ListingsTab({required this.ebayService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EbayListing>>(
      stream: ebayService.streamListings(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.accentBlue));
        }
        final listings = snap.data ?? [];
        if (listings.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined,
                    color: AppColors.textMuted, size: 48),
                const SizedBox(height: 12),
                const Text('Nessuna inserzione',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                const SizedBox(height: 4),
                const Text('Crea la tua prima inserzione dall\'inventario',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: listings.length,
          itemBuilder: (context, i) {
            final listing = listings[i];
            return StaggeredFadeSlide(
              index: i,
              child: GestureDetector(
                onTap: listing.ebayItemId != null
                    ? () => launchUrl(Uri.parse(listing.ebayUrl), mode: LaunchMode.platformDefault)
                    : null,
                child: GlassCard(
                  child: ListTile(
                    leading: listing.imageUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(listing.imageUrls.first,
                                width: 48, height: 48, fit: BoxFit.cover),
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.image,
                                color: AppColors.textMuted),
                          ),
                    title: Text(listing.title,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                        '${listing.formattedPrice} · ${listing.statusLabel}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (listing.ebayItemId != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(Icons.open_in_new,
                                color: AppColors.accentBlue, size: 16),
                          ),
                        _statusDot(listing.status),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusDot(String status) {
    final color = status == 'active'
        ? AppColors.accentGreen
        : status == 'draft'
            ? AppColors.accentOrange
            : AppColors.textMuted;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── Orders Tab ──

class _OrdersTab extends StatefulWidget {
  final EbayService ebayService;
  const _OrdersTab({required this.ebayService});

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  bool _syncing = false;

  Future<void> _syncOrders() async {
    setState(() => _syncing = true);
    try {
      await widget.ebayService.fetchOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore sync: $e'), backgroundColor: AppColors.accentRed),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _syncing ? null : _syncOrders,
                icon: _syncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.accentBlue))
                    : const Icon(Icons.sync, size: 18),
                label: const Text('Aggiorna',
                    style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<EbayOrder>>(
            stream: widget.ebayService.streamOrders(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.accentBlue));
              }
              final orders = snap.data ?? [];
              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          color: AppColors.textMuted, size: 48),
                      const SizedBox(height: 12),
                      const Text('Nessun ordine',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 16)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, i) {
                  final order = orders[i];
                  return StaggeredFadeSlide(
                    index: i,
                    child: GestureDetector(
                      onTap: () => _showOrderDetail(order),
                      child: GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.items.isNotEmpty
                                        ? order.items.first.title
                                        : order.ebayOrderId,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${order.buyerUsername} · ${order.formattedTotal}',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            _orderBadge(order.status),
                          ],
                        ),
                      ),
                    ),
                  ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showOrderDetail(EbayOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EbayOrderDetailSheet(
        order: order,
        ebayService: widget.ebayService,
      ),
    );
  }

  Widget _orderBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'NOT_STARTED':
        color = AppColors.accentOrange;
        label = 'Pagato';
        break;
      case 'IN_PROGRESS':
        color = AppColors.accentBlue;
        label = 'In corso';
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
        color = AppColors.textMuted;
        label = status;
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
}

// ── Settings Tab ──

class _SettingsTab extends StatefulWidget {
  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  final EbayService _ebayService = EbayService();
  bool _loading = true;
  bool _creating = false;
  Map<String, dynamic>? _policies;
  String? _error;

  bool get _hasPolicies =>
      (_policies?['fulfillment'] as List?)?.isNotEmpty == true &&
      (_policies?['return'] as List?)?.isNotEmpty == true &&
      (_policies?['payment'] as List?)?.isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    _loadPolicies();
  }

  Future<void> _loadPolicies() async {
    try {
      final policies = await _ebayService.getPolicies();
      if (mounted) setState(() { _policies = policies; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _createPolicies() async {
    setState(() => _creating = true);
    try {
      await _ebayService.createDefaultPolicies();
      await _loadPolicies();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Policy create con successo!', style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: AppColors.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentBlue));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Setup banner if no policies
        if (!_hasPolicies) ...[
          StaggeredFadeSlide(
            index: 0,
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning_amber, color: AppColors.accentOrange, size: 28),
                    ),
                    const SizedBox(height: 12),
                    const Text('Configura le policy di vendita',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      'Per pubblicare inserzioni su eBay servono policy di spedizione, reso e pagamento. Creale con un tap.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _creating ? null : _createPolicies,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _creating
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Crea policy predefinite', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Show existing policies
        if (_hasPolicies) ...[
          _policyCard('Spedizione', Icons.local_shipping, AppColors.accentBlue, _policies!['fulfillment'] as List),
          const SizedBox(height: 12),
          _policyCard('Reso', Icons.assignment_return, AppColors.accentOrange, _policies!['return'] as List),
          const SizedBox(height: 12),
          _policyCard('Pagamento', Icons.payment, AppColors.accentGreen, _policies!['payment'] as List),
          const SizedBox(height: 24),
        ],

        if (_error != null)
          Text(_error!, style: const TextStyle(color: AppColors.accentRed, fontSize: 12), textAlign: TextAlign.center),

        const Text(
          'Le impostazioni avanzate possono essere modificate direttamente su eBay Seller Hub.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _policyCard(String title, IconData icon, Color color, List policies) {
    return StaggeredFadeSlide(
      index: 0,
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${policies.length}', style: const TextStyle(color: AppColors.accentGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...policies.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  p['name'] ?? p['fulfillmentPolicyId'] ?? 'Policy',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
