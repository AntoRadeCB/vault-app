import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/product.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../services/card_catalog_service.dart';
import '../services/ebay_service.dart';
import '../models/ebay_listing.dart';
import '../models/ebay_order.dart';
import '../widgets/ebay_listing_dialog.dart';
import '../widgets/ebay_order_detail.dart';
import '../providers/profile_provider.dart';
import '../models/user_profile.dart';

// ═══════════════════════════════════════════════════
//  Marketplace Screen — Redesigned for scale
// ═══════════════════════════════════════════════════

class MarketplaceScreen extends StatefulWidget {
  final void Function(Product product)? onEditProduct;
  final void Function(Product product)? onOpenProduct;

  const MarketplaceScreen({super.key, this.onEditProduct, this.onOpenProduct});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final CardCatalogService _catalogService = CardCatalogService();
  final EbayService _ebayService = EbayService();

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

  @override
  Widget build(BuildContext context) {
    final provider = ProfileProvider.maybeOf(context);
    final profileTarget = provider?.profile?.collectionTarget ?? 1;
    final autoInventory = provider?.profile?.autoInventory ?? false;

    return StreamBuilder<List<Product>>(
      stream: _firestoreService.getProducts(),
      builder: (context, productSnap) {
        final allProducts = productSnap.data ?? [];
        final inventoryProducts = _getInventoryProducts(allProducts, autoInventory, profileTarget);

        return StreamBuilder<List<EbayListing>>(
          stream: _ebayService.streamListings(),
          builder: (context, listingSnap) {
            final listings = listingSnap.data ?? [];

            return StreamBuilder<List<EbayOrder>>(
              stream: _ebayService.streamOrders(),
              builder: (context, orderSnap) {
                final orders = orderSnap.data ?? [];

                return Column(
                  children: [
                    // ── Stats header ──
                    _StatsHeader(
                      inventoryCount: inventoryProducts.length,
                      inventoryValue: inventoryProducts.fold(0.0, (s, p) => s + p.effectiveSellPrice * (p.kind == ProductKind.singleCard ? (p.inventoryQty > 0 ? p.inventoryQty : p.quantity) : p.quantity)),
                      activeListings: listings.where((l) => l.status == 'active').length,
                      totalListings: listings.length,
                      soldTotal: orders.where((o) => o.status == 'FULFILLED').fold(0.0, (s, o) => s + o.total),
                      pendingOrders: orders.where((o) => o.status == 'NOT_STARTED' || o.status == 'IN_PROGRESS').length,
                    ),
                    const SizedBox(height: 8),
                    // ── Tabs ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF2E7D32)]),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: AppColors.accentGreen.withValues(alpha: 0.3), blurRadius: 8)],
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: AppColors.textMuted,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                          dividerColor: Colors.transparent,
                          tabs: [
                            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.inventory_2_outlined, size: 14),
                              const SizedBox(width: 4),
                              const Text('Da vendere'),
                              if (inventoryProducts.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                _CountBadge(count: inventoryProducts.length),
                              ],
                            ])),
                            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.storefront, size: 14),
                              const SizedBox(width: 4),
                              const Text('Su eBay'),
                              if (listings.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                _CountBadge(count: listings.length),
                              ],
                            ])),
                            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.receipt_long, size: 14),
                              const SizedBox(width: 4),
                              const Text('Ordini'),
                              if (orders.where((o) => o.status == 'NOT_STARTED').isNotEmpty) ...[
                                const SizedBox(width: 4),
                                _CountBadge(count: orders.where((o) => o.status == 'NOT_STARTED').length, color: AppColors.accentOrange),
                              ],
                            ])),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // ── Tab content ──
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _InventoryTab(
                            products: inventoryProducts,
                            firestoreService: _firestoreService,
                            catalogService: _catalogService,
                            ebayService: _ebayService,
                            onEditProduct: widget.onEditProduct,
                          ),
                          _ListingsTab(
                            listings: listings,
                            ebayService: _ebayService,
                          ),
                          _OrdersTab(
                            orders: orders,
                            ebayService: _ebayService,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  List<Product> _getInventoryProducts(List<Product> products, bool autoInventory, int profileTarget) {
    final result = <Product>[];
    for (final p in products) {
      if (p.kind != ProductKind.singleCard) {
        if (p.inventoryQty > 0) result.add(p);
      } else {
        if (p.inventoryQty > 0) {
          result.add(p.copyWith(quantity: p.inventoryQty));
        } else if (autoInventory) {
          final target = p.collectionTargetOverride ?? profileTarget;
          final excess = p.quantity - target;
          if (excess > 0) {
            result.add(p.copyWith(quantity: excess));
          }
        }
      }
    }
    return result;
  }
}

// ═══════════════════════════════════════════════════
//  Stats Header
// ═══════════════════════════════════════════════════

class _StatsHeader extends StatelessWidget {
  final int inventoryCount;
  final double inventoryValue;
  final int activeListings;
  final int totalListings;
  final double soldTotal;
  final int pendingOrders;

  const _StatsHeader({
    required this.inventoryCount,
    required this.inventoryValue,
    required this.activeListings,
    required this.totalListings,
    required this.soldTotal,
    required this.pendingOrders,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: StaggeredFadeSlide(
        index: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Marketplace', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                // eBay connection indicator
                _EbayConnectionDot(),
              ],
            ),
            const SizedBox(height: 12),
            // Stats row
            Row(
              children: [
                _MiniStat(
                  icon: Icons.inventory_2_outlined,
                  value: inventoryCount.toString(),
                  label: 'in vendita',
                  color: AppColors.accentBlue,
                ),
                const SizedBox(width: 8),
                _MiniStat(
                  icon: Icons.storefront,
                  value: activeListings.toString(),
                  label: 'su eBay',
                  color: AppColors.accentGreen,
                ),
                const SizedBox(width: 8),
                _MiniStat(
                  icon: Icons.payments_outlined,
                  value: '€${soldTotal.toStringAsFixed(0)}',
                  label: 'venduto',
                  color: AppColors.accentTeal,
                ),
                if (pendingOrders > 0) ...[
                  const SizedBox(width: 8),
                  _MiniStat(
                    icon: Icons.hourglass_top,
                    value: pendingOrders.toString(),
                    label: 'da spedire',
                    color: AppColors.accentOrange,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniStat({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 9, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _EbayConnectionDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ebay = EbayService();
    return FutureBuilder<Map<String, dynamic>>(
      future: ebay.getConnectionStatus(),
      builder: (ctx, snap) {
        final connected = snap.data?['connected'] == true;
        if (!snap.hasData) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (connected ? AppColors.accentGreen : AppColors.textMuted).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (connected ? AppColors.accentGreen : AppColors.textMuted).withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: connected ? AppColors.accentGreen : AppColors.textMuted, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(connected ? 'eBay' : 'eBay off', style: TextStyle(color: connected ? AppColors.accentGreen : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;
  const _CountBadge({required this.count, this.color = AppColors.accentGreen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        count > 999 ? '${(count / 1000).toStringAsFixed(1)}k' : count.toString(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
//  Tab 1: Inventario (Da vendere) — Grouped
// ═══════════════════════════════════════════════════

class _InventoryTab extends StatefulWidget {
  final List<Product> products;
  final FirestoreService firestoreService;
  final CardCatalogService catalogService;
  final EbayService ebayService;
  final void Function(Product product)? onEditProduct;

  const _InventoryTab({
    required this.products,
    required this.firestoreService,
    required this.catalogService,
    required this.ebayService,
    this.onEditProduct,
  });

  @override
  State<_InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<_InventoryTab> {
  String _searchQuery = '';
  bool _searchFocused = false;
  final Set<String> _selected = {};
  bool _selectMode = false;
  final Set<String> _collapsedGroups = {};
  Map<String, double> _livePrices = {};

  @override
  void initState() {
    super.initState();
    _loadLivePrices();
  }

  Future<void> _loadLivePrices() async {
    try {
      final cards = await widget.catalogService.getAllCards();
      final prices = <String, double>{};
      for (final card in cards) {
        if (card.marketPrice != null) prices[card.id] = card.marketPrice!.cents / 100;
      }
      if (mounted) setState(() => _livePrices = prices);
    } catch (_) {}
  }

  List<Product> get _filtered {
    if (_searchQuery.isEmpty) return widget.products;
    final q = _searchQuery.toLowerCase();
    return widget.products.where((p) =>
      p.name.toLowerCase().contains(q) || p.brand.toLowerCase().contains(q) ||
      (p.cardExpansion?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  /// Group products: cards by expansion, sealed by kind
  Map<String, List<Product>> get _grouped {
    final products = _filtered;
    final groups = <String, List<Product>>{};
    for (final p in products) {
      final key = p.kind == ProductKind.singleCard
          ? (p.cardExpansion ?? 'Altre carte')
          : p.kindLabel;
      groups.putIfAbsent(key, () => []).add(p);
    }
    // Sort groups: largest first
    final sorted = groups.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    return Map.fromEntries(sorted);
  }

  void _toggleSelect(String productId) {
    setState(() {
      if (_selected.contains(productId)) {
        _selected.remove(productId);
        if (_selected.isEmpty) _selectMode = false;
      } else {
        _selected.add(productId);
        _selectMode = true;
      }
    });
  }

  void _selectGroup(List<Product> group) {
    setState(() {
      final ids = group.where((p) => p.id != null).map((p) => p.id!).toSet();
      final allSelected = ids.every(_selected.contains);
      if (allSelected) {
        _selected.removeAll(ids);
        if (_selected.isEmpty) _selectMode = false;
      } else {
        _selected.addAll(ids);
        _selectMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() { _selected.clear(); _selectMode = false; });
  }

  void _showEditSellPrice(Product product) {
    final controller = TextEditingController(text: product.sellPrice?.toStringAsFixed(2) ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Prezzo di vendita', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Mercato: ${product.formattedMarketPrice.isNotEmpty ? product.formattedMarketPrice : "N/A"}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: product.marketPrice?.toStringAsFixed(2) ?? '0.00',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixText: '€ ',
                  prefixStyle: const TextStyle(color: AppColors.accentGreen, fontSize: 20, fontWeight: FontWeight.bold),
                  filled: true, fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accentGreen, width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text('Annulla', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 15))),
                    ),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: GestureDetector(
                    onTap: () {
                      final value = double.tryParse(controller.text.trim());
                      if (product.id != null) widget.firestoreService.updateProduct(product.id!, {'sellPrice': value});
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF2E7D32)]), borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text('Salva', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductActions(Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.sell, color: AppColors.accentGreen),
              title: const Text('Pubblica su eBay', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Crea inserzione eBay', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              onTap: () { Navigator.pop(ctx); showDialog(context: context, builder: (_) => EbayListingDialog(product: product, ebayService: widget.ebayService)); },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.accentBlue),
              title: const Text('Modifica prezzo', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () { Navigator.pop(ctx); _showEditSellPrice(product); },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: AppColors.accentRed),
              title: const Text('Rimuovi da vendita', style: TextStyle(color: AppColors.accentRed)),
              onTap: () {
                Navigator.pop(ctx);
                if (product.id != null) {
                  widget.firestoreService.updateProduct(product.id!, {'inventoryQty': 0, 'sellPrice': null});
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${product.name} rimosso'),
                    backgroundColor: AppColors.accentRed,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped;

    return Column(
      children: [
        // Search + selection bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _selectMode
              ? _buildSelectionBar()
              : _buildSearchBar(),
        ),
        const SizedBox(height: 6),
        // Item count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('${_filtered.length} prodotti · ${groups.length} gruppi',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
              const Spacer(),
              if (!_selectMode)
                GestureDetector(
                  onTap: () => setState(() => _selectMode = true),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.checklist, color: AppColors.textMuted, size: 14),
                      const SizedBox(width: 3),
                      const Text('Seleziona', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Grouped list
        Expanded(
          child: widget.products.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final entry = groups.entries.elementAt(index);
                    return _buildGroup(entry.key, entry.value);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Focus(
      onFocusChange: (f) => setState(() => _searchFocused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _searchFocused ? AppColors.accentGreen.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Cerca per nome, espansione...',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            prefixIcon: Icon(Icons.search, color: _searchFocused ? AppColors.accentGreen : AppColors.textMuted, size: 18),
            filled: true, fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _clearSelection,
            child: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Text('${_selected.length} selezionati', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          const Spacer(),
          if (_selected.isNotEmpty)
            ScaleOnPress(
              onTap: () {
                // Batch publish: open listing dialog for first selected, or show batch confirm
                final selectedProducts = widget.products.where((p) => p.id != null && _selected.contains(p.id)).toList();
                if (selectedProducts.isEmpty) return;
                if (selectedProducts.length == 1) {
                  showDialog(context: context, builder: (_) => EbayListingDialog(product: selectedProducts.first, ebayService: widget.ebayService));
                } else {
                  _showBatchPublishDialog(selectedProducts);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF2E7D32)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sell, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text('Pubblica ${_selected.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showBatchPublishDialog(List<Product> products) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pubblica su eBay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stai per pubblicare ${products.length} oggetti su eBay.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 12),
            Text('Ogni oggetto userà il prezzo di vendita impostato o il prezzo di mercato.',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.accentOrange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Verifica che i prezzi siano corretti prima di pubblicare.',
                      style: TextStyle(color: AppColors.accentOrange, fontSize: 11))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla', style: TextStyle(color: AppColors.textMuted))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: implement batch publish
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Pubblicazione batch di ${products.length} oggetti in arrivo...'),
                backgroundColor: AppColors.accentGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ));
              _clearSelection();
            },
            child: const Text('Pubblica', style: TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(String groupName, List<Product> products) {
    final isCollapsed = _collapsedGroups.contains(groupName);
    final groupValue = products.fold(0.0, (s, p) {
      final lp = p.cardBlueprintId != null ? _livePrices[p.cardBlueprintId!] : null;
      return s + (p.sellPrice ?? lp ?? p.marketPrice ?? p.price) * (p.kind == ProductKind.singleCard ? (p.inventoryQty > 0 ? p.inventoryQty : p.quantity) : p.quantity);
    });
    final allGroupSelected = products.where((p) => p.id != null).every((p) => _selected.contains(p.id!));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          // Group header
          GestureDetector(
            onTap: () => setState(() {
              if (isCollapsed) { _collapsedGroups.remove(groupName); } else { _collapsedGroups.add(groupName); }
            }),
            onLongPress: () => _selectGroup(products),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  if (_selectMode)
                    GestureDetector(
                      onTap: () => _selectGroup(products),
                      child: Container(
                        width: 20, height: 20,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: allGroupSelected ? AppColors.accentGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: allGroupSelected ? AppColors.accentGreen : AppColors.textMuted),
                        ),
                        child: allGroupSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                      ),
                    ),
                  Icon(isCollapsed ? Icons.chevron_right : Icons.expand_more, color: AppColors.textMuted, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(groupName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                    child: Text('${products.length}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Text('€${groupValue.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          // Group items
          if (!isCollapsed)
            ...products.map((p) => Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: _buildProductItem(p),
            )),
        ],
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    final isSelected = product.id != null && _selected.contains(product.id!);
    final livePrice = product.cardBlueprintId != null ? _livePrices[product.cardBlueprintId!] : null;
    final displayPrice = product.sellPrice ?? livePrice ?? product.marketPrice ?? product.price;
    final isCard = product.kind == ProductKind.singleCard;
    final hasImage = product.displayImageUrl.isNotEmpty;

    Color accentColor;
    if (isCard) {
      switch (product.cardRarity?.toLowerCase()) {
        case 'common': accentColor = const Color(0xFF9E9E9E); break;
        case 'uncommon': accentColor = const Color(0xFF4CAF50); break;
        case 'rare': accentColor = const Color(0xFF2196F3); break;
        case 'epic': accentColor = const Color(0xFFAB47BC); break;
        case 'alternate art': accentColor = const Color(0xFFFFD700); break;
        default: accentColor = AppColors.accentBlue;
      }
    } else {
      accentColor = AppColors.accentOrange;
    }

    return GestureDetector(
      onTap: _selectMode
          ? () { if (product.id != null) _toggleSelect(product.id!); }
          : () => widget.onEditProduct?.call(product),
      onLongPress: () {
        if (_selectMode) {
          _showProductActions(product);
        } else {
          if (product.id != null) _toggleSelect(product.id!);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentGreen.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: AppColors.accentGreen.withValues(alpha: 0.25)) : null,
        ),
        child: Row(
          children: [
            if (_selectMode)
              Container(
                width: 20, height: 20,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accentGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isSelected ? AppColors.accentGreen : AppColors.textMuted),
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
              ),
            // Thumbnail
            Container(
              width: 40, height: isCard ? 56 : 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(isCard ? 4 : 8),
                border: Border.all(color: accentColor.withValues(alpha: 0.2)),
              ),
              child: hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(isCard ? 3 : 7),
                      child: Image.network(product.displayImageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.style, color: accentColor, size: 18)),
                    )
                  : Icon(isCard ? Icons.style : Icons.inventory_2_outlined, color: accentColor, size: 18),
            ),
            const SizedBox(width: 10),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text('×${product.formattedQuantity}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      if (product.cardRarity != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
                          child: Text(product.cardRarity!, style: TextStyle(color: accentColor, fontSize: 8, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Price
            GestureDetector(
              onTap: () => _showEditSellPrice(product),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('€${displayPrice.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 2),
                  const Icon(Icons.edit, color: AppColors.textMuted, size: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.accentGreen.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(Icons.storefront_outlined, color: AppColors.accentGreen.withValues(alpha: 0.5), size: 48),
            ),
            const SizedBox(height: 20),
            const Text('Nessun prodotto in vendita', style: TextStyle(color: AppColors.textSecondary, fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Sposta le carte dalla collezione\nper iniziare a vendere',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
//  Tab 2: Su eBay — Listings with filters
// ═══════════════════════════════════════════════════

class _ListingsTab extends StatefulWidget {
  final List<EbayListing> listings;
  final EbayService ebayService;
  const _ListingsTab({required this.listings, required this.ebayService});

  @override
  State<_ListingsTab> createState() => _ListingsTabState();
}

class _ListingsTabState extends State<_ListingsTab> {
  String _statusFilter = 'all'; // all, active, draft, ended
  String _searchQuery = '';
  bool _syncing = false;

  List<EbayListing> get _filtered {
    var list = widget.listings;
    if (_statusFilter != 'all') {
      list = list.where((l) => l.status == _statusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((l) => l.title.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      await widget.ebayService.fetchOrders();
    } catch (_) {}
    if (mounted) setState(() => _syncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final activeCount = widget.listings.where((l) => l.status == 'active').length;
    final draftCount = widget.listings.where((l) => l.status == 'draft').length;
    final endedCount = widget.listings.where((l) => l.status == 'ended').length;

    return Column(
      children: [
        // Policy banner
        _PolicySetupBanner(ebayService: widget.ebayService),
        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildChip('all', 'Tutti (${widget.listings.length})', null),
                const SizedBox(width: 6),
                _buildChip('active', 'Attive ($activeCount)', AppColors.accentGreen),
                const SizedBox(width: 6),
                _buildChip('draft', 'Bozze ($draftCount)', AppColors.accentOrange),
                const SizedBox(width: 6),
                _buildChip('ended', 'Terminate ($endedCount)', AppColors.textMuted),
                const SizedBox(width: 8),
                // Sync button
                ScaleOnPress(
                  onTap: _syncing ? () {} : _sync,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _syncing
                            ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accentBlue))
                            : Icon(Icons.sync, color: AppColors.accentBlue, size: 14),
                        const SizedBox(width: 4),
                        Text('Sync', style: TextStyle(color: AppColors.accentBlue, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Cerca inserzione...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 16),
                contentPadding: EdgeInsets.zero,
                filled: true, fillColor: Colors.transparent,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${filtered.length} inserzioni', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ),
        ),
        const SizedBox(height: 4),
        // Listing list
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2_outlined, color: AppColors.textMuted, size: 36),
                    const SizedBox(height: 8),
                    Text(widget.listings.isEmpty ? 'Nessuna inserzione' : 'Nessun risultato',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
                  ],
                ))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _buildListingCard(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildChip(String value, String label, Color? dotColor) {
    final isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentGreen.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.accentGreen.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(width: 6, height: 6, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 4),
            ],
            Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildListingCard(EbayListing listing) {
    Color statusColor;
    switch (listing.status) {
      case 'active': statusColor = AppColors.accentGreen; break;
      case 'draft': statusColor = AppColors.accentOrange; break;
      default: statusColor = AppColors.textMuted;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: listing.ebayItemId != null
            ? () => launchUrl(Uri.parse(listing.ebayUrl), mode: LaunchMode.platformDefault)
            : null,
        onLongPress: () => _showEditListingSheet(listing),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              // Image
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: listing.imageUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.network(listing.imageUrls.first, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image, color: AppColors.textMuted, size: 20)),
                      )
                    : const Icon(Icons.image, color: AppColors.textMuted, size: 20),
              ),
              const SizedBox(width: 10),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(listing.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(listing.formattedPrice, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                          child: Text(listing.statusLabel, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (listing.ebayItemId != null)
                const Icon(Icons.open_in_new, color: AppColors.accentBlue, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditListingSheet(EbayListing listing) {
    final titleCtrl = TextEditingController(text: listing.title);
    final descCtrl = TextEditingController(text: listing.description);
    final priceCtrl = TextEditingController(text: listing.price.toStringAsFixed(2));
    final qtyCtrl = TextEditingController(text: listing.quantity.toString());
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: DraggableScrollableSheet(
            initialChildSize: 0.75,
            maxChildSize: 0.95,
            minChildSize: 0.4,
            builder: (_, scrollCtrl) => Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(24),
                children: [
                  // Handle
                  Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)))),
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.edit_outlined, color: AppColors.accentBlue, size: 22),
                      const SizedBox(width: 8),
                      const Text('Modifica inserzione', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (listing.status == 'active' ? AppColors.accentGreen : AppColors.accentOrange).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(listing.statusLabel,
                          style: TextStyle(color: listing.status == 'active' ? AppColors.accentGreen : AppColors.accentOrange, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Title
                  _editField('Titolo', titleCtrl, maxLines: 2),
                  const SizedBox(height: 14),
                  // Price + Quantity row
                  Row(
                    children: [
                      Expanded(child: _editField('Prezzo (€)', priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                      const SizedBox(width: 12),
                      SizedBox(width: 90, child: _editField('Quantità', qtyCtrl, keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Description
                  _editField('Descrizione', descCtrl, maxLines: 5),
                  const SizedBox(height: 24),
                  // Actions
                  Row(
                    children: [
                      Expanded(child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
                          child: const Center(child: Text('Annulla', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 15))),
                        ),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: GestureDetector(
                        onTap: saving ? null : () async {
                          setSheetState(() => saving = true);
                          try {
                            final updates = <String, dynamic>{};
                            if (titleCtrl.text.trim() != listing.title) updates['title'] = titleCtrl.text.trim();
                            if (descCtrl.text.trim() != listing.description) updates['description'] = descCtrl.text.trim();
                            final newPrice = double.tryParse(priceCtrl.text.trim());
                            if (newPrice != null && newPrice != listing.price) updates['price'] = newPrice;
                            final newQty = int.tryParse(qtyCtrl.text.trim());
                            if (newQty != null && newQty != listing.quantity) updates['quantity'] = newQty;

                            if (updates.isNotEmpty && listing.id != null) {
                              await widget.ebayService.updateListing(listing.id!, updates);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(updates.isEmpty ? 'Nessuna modifica' : 'Inserzione aggiornata'),
                                backgroundColor: updates.isEmpty ? AppColors.textMuted : AppColors.accentGreen,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.all(16),
                              ));
                            }
                          } catch (e) {
                            setSheetState(() => saving = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Errore: $e'), backgroundColor: AppColors.accentRed,
                                behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ));
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Salva', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Delete listing
                  if (listing.status != 'ended')
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _confirmDeleteListing(listing);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.accentRed.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline, color: AppColors.accentRed, size: 18),
                            SizedBox(width: 6),
                            Text('Elimina inserzione', style: TextStyle(color: AppColors.accentRed, fontSize: 14, fontWeight: FontWeight.w600)),
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
    );
  }

  Widget _editField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.cardDark,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5)),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteListing(EbayListing listing) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Elimina inserzione', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Vuoi eliminare "${listing.title}" da eBay?', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla', style: TextStyle(color: AppColors.textMuted))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                if (listing.id != null) await widget.ebayService.deleteListing(listing.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Inserzione eliminata'),
                    backgroundColor: AppColors.accentRed,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e'), backgroundColor: AppColors.accentRed));
                }
              }
            },
            child: const Text('Elimina', style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
//  Tab 3: Ordini — Full height, filterable
// ═══════════════════════════════════════════════════

class _OrdersTab extends StatefulWidget {
  final List<EbayOrder> orders;
  final EbayService ebayService;
  const _OrdersTab({required this.orders, required this.ebayService});

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  String _statusFilter = 'all';

  List<EbayOrder> get _filtered {
    if (_statusFilter == 'all') return widget.orders;
    return widget.orders.where((o) => o.status == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final pendingCount = widget.orders.where((o) => o.status == 'NOT_STARTED').length;
    final inProgressCount = widget.orders.where((o) => o.status == 'IN_PROGRESS').length;
    final fulfilledCount = widget.orders.where((o) => o.status == 'FULFILLED').length;

    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildChip('all', 'Tutti (${widget.orders.length})'),
                const SizedBox(width: 6),
                _buildChip('NOT_STARTED', 'Da spedire ($pendingCount)', AppColors.accentOrange),
                const SizedBox(width: 6),
                _buildChip('IN_PROGRESS', 'In corso ($inProgressCount)', AppColors.accentBlue),
                const SizedBox(width: 6),
                _buildChip('FULFILLED', 'Spediti ($fulfilledCount)', AppColors.accentGreen),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${filtered.length} ordini', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ),
        ),
        const SizedBox(height: 6),
        // Orders list
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined, color: AppColors.textMuted, size: 36),
                    const SizedBox(height: 8),
                    const Text('Nessun ordine', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                  ],
                ))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _buildOrderCard(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildChip(String value, String label, [Color? dotColor]) {
    final isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentGreen.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.accentGreen.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(width: 6, height: 6, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 4),
            ],
            Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(EbayOrder order) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (order.status) {
      case 'NOT_STARTED':
        statusColor = AppColors.accentOrange; statusLabel = 'Da spedire'; statusIcon = Icons.local_shipping_outlined; break;
      case 'IN_PROGRESS':
        statusColor = AppColors.accentBlue; statusLabel = 'In corso'; statusIcon = Icons.hourglass_top; break;
      case 'FULFILLED':
        statusColor = AppColors.accentGreen; statusLabel = 'Spedito'; statusIcon = Icons.check_circle_outline; break;
      case 'REFUNDED':
        statusColor = AppColors.accentRed; statusLabel = 'Rimborsato'; statusIcon = Icons.replay; break;
      default:
        statusColor = AppColors.textMuted; statusLabel = order.status; statusIcon = Icons.help_outline;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => EbayOrderDetailSheet(order: order, ebayService: widget.ebayService),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              // Status icon
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.items.isNotEmpty ? order.items.first.title : order.ebayOrderId,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(order.buyerUsername, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        if (order.items.length > 1) ...[
                          const SizedBox(width: 4),
                          Text('· ${order.items.length} oggetti', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Price + status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(order.formattedTotal, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
//  Policy Setup Banner (unchanged logic)
// ═══════════════════════════════════════════════════

class _PolicySetupBanner extends StatefulWidget {
  final EbayService ebayService;
  const _PolicySetupBanner({required this.ebayService});

  @override
  State<_PolicySetupBanner> createState() => _PolicySetupBannerState();
}

class _PolicySetupBannerState extends State<_PolicySetupBanner> {
  bool _loading = true;
  bool _creating = false;
  bool _hasPolicies = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final policies = await widget.ebayService.getPolicies();
      var has = (policies['fulfillment'] as List?)?.isNotEmpty == true &&
          (policies['return'] as List?)?.isNotEmpty == true;
      if (!has) {
        final saved = policies['saved'] as Map<String, dynamic>?;
        has = saved != null && saved['fulfillmentPolicyId'] != null && saved['returnPolicyId'] != null;
      }
      if (mounted) setState(() { _hasPolicies = has; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    setState(() => _creating = true);
    try {
      await widget.ebayService.createDefaultPolicies();
      if (mounted) {
        setState(() => _hasPolicies = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Policy create!', style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e'), backgroundColor: AppColors.accentRed));
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _hasPolicies) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.accentOrange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.accentOrange, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Configura le policy per pubblicare', style: TextStyle(color: AppColors.accentOrange, fontSize: 11, fontWeight: FontWeight.w500))),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _creating ? null : _create,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.accentBlue, borderRadius: BorderRadius.circular(8)),
                child: _creating
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Configura', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
