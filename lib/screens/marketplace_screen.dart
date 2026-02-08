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

class MarketplaceScreen extends StatefulWidget {
  final void Function(Product product)? onEditProduct;
  final void Function(Product product)? onOpenProduct;

  const MarketplaceScreen({super.key, this.onEditProduct, this.onOpenProduct});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with TickerProviderStateMixin {
  late TabController _mainTabController;
  final FirestoreService _firestoreService = FirestoreService();
  final CardCatalogService _catalogService = CardCatalogService();
  final EbayService _ebayService = EbayService();

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _mainTabController.addListener(() {
      if (!_mainTabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: StaggeredFadeSlide(
            index: 0,
            child: Row(
              children: [
                const Text(
                  'Marketplace',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accentGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.storefront, color: AppColors.accentGreen, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'vendita',
                        style: TextStyle(
                          color: AppColors.accentGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Main tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: StaggeredFadeSlide(
            index: 1,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: TabBar(
                controller: _mainTabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF2E7D32)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGreen.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Inventario'),
                  Tab(text: 'eBay'),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TabBarView(
            controller: _mainTabController,
            physics: const BouncingScrollPhysics(),
            children: [
              _InventarioTab(
                firestoreService: _firestoreService,
                catalogService: _catalogService,
                ebayService: _ebayService,
                onEditProduct: widget.onEditProduct,
                onOpenProduct: widget.onOpenProduct,
              ),
              _EbayTab(ebayService: _ebayService),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════
//  Tab 1: Inventario
// ═══════════════════════════════════════════════════

class _InventarioTab extends StatefulWidget {
  final FirestoreService firestoreService;
  final CardCatalogService catalogService;
  final EbayService ebayService;
  final void Function(Product product)? onEditProduct;
  final void Function(Product product)? onOpenProduct;

  const _InventarioTab({
    required this.firestoreService,
    required this.catalogService,
    required this.ebayService,
    this.onEditProduct,
    this.onOpenProduct,
  });

  @override
  State<_InventarioTab> createState() => _InventarioTabState();
}

class _InventarioTabState extends State<_InventarioTab>
    with SingleTickerProviderStateMixin {
  late TabController _sortController;
  String _searchQuery = '';
  bool _searchFocused = false;
  String _kindFilter = 'all';
  Map<String, double> _livePrices = {};

  @override
  void initState() {
    super.initState();
    _sortController = TabController(length: 3, vsync: this);
    _sortController.addListener(() {
      if (!_sortController.indexIsChanging) setState(() {});
    });
    _loadLivePrices();
  }

  Future<void> _loadLivePrices() async {
    try {
      final cards = await widget.catalogService.getAllCards();
      final prices = <String, double>{};
      for (final card in cards) {
        if (card.marketPrice != null) {
          prices[card.id] = card.marketPrice!.cents / 100;
        }
      }
      if (mounted) setState(() => _livePrices = prices);
    } catch (_) {}
  }

  @override
  void dispose() {
    _sortController.dispose();
    super.dispose();
  }

  List<Product> _applyFilters(List<Product> products) {
    var filtered = products.where((p) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!p.name.toLowerCase().contains(q) &&
            !p.brand.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    if (_kindFilter != 'all') {
      filtered = filtered.where((p) {
        switch (_kindFilter) {
          case 'singleCard':
            return p.kind == ProductKind.singleCard;
          case 'boosterPack':
            return p.kind == ProductKind.boosterPack;
          case 'boosterBox':
            return p.kind == ProductKind.boosterBox;
          case 'display':
            return p.kind == ProductKind.display;
          default:
            return true;
        }
      }).toList();
    }

    // Sort
    switch (_sortController.index) {
      case 0: // Nome
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 1: // Prezzo
        filtered.sort((a, b) => (b.sellPrice ?? b.marketPrice ?? b.price)
            .compareTo(a.sellPrice ?? a.marketPrice ?? a.price));
        break;
      case 2: // Recenti
        // Default order from Firestore (most recent first)
        break;
    }

    return filtered;
  }

  List<Product> _applyInventoryLogic(
      List<Product> products, bool autoInventory, int profileTarget) {
    final result = <Product>[];
    for (final p in products) {
      if (p.kind != ProductKind.singleCard) {
        result.add(p);
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

  void _showEditSellPrice(Product product) {
    final controller = TextEditingController(
      text: product.sellPrice?.toStringAsFixed(2) ?? '',
    );
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Prezzo di vendita',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'Prezzo di mercato: ${product.formattedMarketPrice.isNotEmpty ? product.formattedMarketPrice : "N/A"}',
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText:
                      product.marketPrice?.toStringAsFixed(2) ?? '0.00',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixText: '€ ',
                  prefixStyle: const TextStyle(
                      color: AppColors.accentGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.accentGreen, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                            child: Text('Annulla',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final value =
                            double.tryParse(controller.text.trim());
                        if (product.id != null) {
                          widget.firestoreService.updateProduct(
                              product.id!, {'sellPrice': value});
                        }
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF43A047), Color(0xFF2E7D32)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                            child: Text('Salva',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15))),
                      ),
                    ),
                  ),
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
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading:
                  const Icon(Icons.sell, color: AppColors.accentGreen),
              title: const Text('Pubblica su eBay',
                  style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Crea inserzione eBay',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (_) => EbayListingDialog(
                    product: product,
                    ebayService: widget.ebayService,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined,
                  color: AppColors.accentBlue),
              title: const Text('Modifica prezzo',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _showEditSellPrice(product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline,
                  color: AppColors.accentRed),
              title: const Text('Rimuovi',
                  style: TextStyle(color: AppColors.accentRed)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmRemove(product);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rimuovi dal marketplace',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Rimuovere "${product.name}" dall\'inventario di vendita?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (product.id != null) {
                // Reset inventoryQty to 0 (removes from selling inventory)
                widget.firestoreService
                    .updateProduct(product.id!, {'inventoryQty': 0, 'sellPrice': null});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} rimosso dal marketplace'),
                    backgroundColor: AppColors.accentRed,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            child: const Text('Rimuovi',
                style: TextStyle(
                    color: AppColors.accentRed,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = ProfileProvider.maybeOf(context);
    final profileTarget = provider?.profile?.collectionTarget ?? 1;
    final autoInventory = provider?.profile?.autoInventory ?? false;

    return StreamBuilder<List<Product>>(
      stream: widget.firestoreService.getProducts(),
      builder: (context, snapshot) {
        final allProducts = snapshot.data ?? [];
        final inventoryProducts =
            _applyInventoryLogic(allProducts, autoInventory, profileTarget);
        final products = _applyFilters(inventoryProducts);

        return Column(
          children: [
            // Kind filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'Tutto', Icons.grid_view),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                        'singleCard', 'Carte', Icons.style),
                    const SizedBox(width: 6),
                    _buildFilterChip('boosterPack', 'Buste',
                        Icons.inventory_2_outlined),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                        'boosterBox', 'Box', Icons.all_inbox),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                        'display', 'Display', Icons.view_module),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Sort tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: TabBar(
                  controller: _sortController,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF43A047), Color(0xFF2E7D32)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 11),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Nome'),
                    Tab(text: 'Prezzo'),
                    Tab(text: 'Recenti'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Focus(
                onFocusChange: (f) =>
                    setState(() => _searchFocused = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _searchFocused
                          ? AppColors.accentGreen.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                    boxShadow: _searchFocused
                        ? [
                            BoxShadow(
                              color: AppColors.accentGreen
                                  .withValues(alpha: 0.12),
                              blurRadius: 16,
                            ),
                          ]
                        : [],
                  ),
                  child: TextField(
                    onChanged: (value) =>
                        setState(() => _searchQuery = value),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Cerca prodotto...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: _searchFocused
                            ? AppColors.accentGreen
                            : AppColors.textMuted,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Item count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${products.length} prodotti',
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Product list
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accentGreen))
                  : products.isEmpty
                      ? _buildEmptyState()
                      : _buildProductList(products),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _kindFilter == value;
    return ScaleOnPress(
      onTap: () => setState(() => _kindFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentGreen.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.accentGreen.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isSelected
                    ? AppColors.accentGreen
                    : AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.storefront_outlined,
                  color: AppColors.accentGreen.withValues(alpha: 0.5), size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nessun prodotto in vendita',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sposta le carte dalla collezione al marketplace\nper iniziare a vendere',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(List<Product> products) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => widget.onEditProduct?.call(product),
            onLongPress: () => _showProductActions(product),
            child: _buildProductCard(product),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    if (product.isCard && product.kind == ProductKind.singleCard) {
      return _buildCardProductCard(product);
    }
    return _buildSealedProductCard(product);
  }

  Widget _buildSealedProductCard(Product product) {
    final badgeColor = AppColors.accentOrange;
    final productImage = product.displayImageUrl;
    final hasImage = productImage.isNotEmpty;

    IconData kindIcon;
    switch (product.kind) {
      case ProductKind.singleCard:
        kindIcon = Icons.style;
        break;
      case ProductKind.boosterPack:
        kindIcon = Icons.inventory_2_outlined;
        break;
      case ProductKind.boosterBox:
        kindIcon = Icons.all_inbox;
        break;
      case ProductKind.display:
        kindIcon = Icons.view_module;
        break;
      case ProductKind.bundle:
        kindIcon = Icons.card_giftcard;
        break;
    }

    return GlassCard(
      padding: const EdgeInsets.all(14),
      glowColor: badgeColor,
      child: Row(
        children: [
          Container(
            width: 52,
            height: hasImage ? 72 : 52,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(hasImage ? 6 : 12),
              border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
              boxShadow: hasImage
                  ? [BoxShadow(color: badgeColor.withValues(alpha: 0.15), blurRadius: 6)]
                  : null,
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.network(productImage, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(kindIcon, color: badgeColor, size: 24)),
                  )
                : Icon(kindIcon, color: badgeColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(product.kindLabel,
                          style: TextStyle(
                              color: badgeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 6),
                    Text('Qta: ${product.formattedQuantity}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(product.formattedPrice,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 6),
              if (product.canBeOpened && product.quantity > 0)
                ScaleOnPress(
                  onTap: () => widget.onOpenProduct?.call(product),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFE53935)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_open,
                            color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text('Apri',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardProductCard(Product product) {
    Color getRarityColor(String? rarity) {
      switch (rarity?.toLowerCase()) {
        case 'common': return const Color(0xFF9E9E9E);
        case 'uncommon': return const Color(0xFF4CAF50);
        case 'rare': return const Color(0xFF2196F3);
        case 'epic': return const Color(0xFFAB47BC);
        case 'alternate art': return const Color(0xFFFFD700);
        case 'promo': return const Color(0xFFFF6B35);
        case 'showcase': return const Color(0xFFE91E63);
        default: return AppColors.accentBlue;
      }
    }

    final rarityColor = getRarityColor(product.cardRarity);
    final livePrice = (product.cardBlueprintId != null)
        ? _livePrices[product.cardBlueprintId!]
        : null;
    final displayMarketPrice = livePrice ?? product.marketPrice;
    final hasMarketPrice = displayMarketPrice != null;
    final isAutoExcess = product.inventoryQty <= 0;

    String formatMktPrice(double p) {
      if (p >= 1000) return '€${p.toStringAsFixed(0)}';
      return '€${p.toStringAsFixed(2)}';
    }

    return GlassCard(
      padding: const EdgeInsets.all(10),
      glowColor: rarityColor,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: rarityColor.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                    color: rarityColor.withValues(alpha: 0.15),
                    blurRadius: 6),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: product.cardImageUrl != null
                  ? Image.network(product.cardImageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                            color: rarityColor.withValues(alpha: 0.1),
                            child: Icon(Icons.style,
                                color: rarityColor, size: 22),
                          ))
                  : Container(
                      color: rarityColor.withValues(alpha: 0.1),
                      child:
                          Icon(Icons.style, color: rarityColor, size: 22),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(product.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (isAutoExcess)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.accentOrange
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: AppColors.accentOrange
                                  .withValues(alpha: 0.3)),
                        ),
                        child: const Text('auto',
                            style: TextStyle(
                                color: AppColors.accentOrange,
                                fontSize: 8,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (product.cardExpansion != null) ...[
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(product.cardExpansion!,
                              style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (product.cardRarity != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: rarityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(product.cardRarity!,
                            style: TextStyle(
                                color: rarityColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('Qta: ${product.formattedQuantity}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _showEditSellPrice(product),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.sellPrice != null
                          ? '€${product.sellPrice!.toStringAsFixed(2)}'
                          : (hasMarketPrice
                              ? formatMktPrice(displayMarketPrice)
                              : product.formattedPrice),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.edit,
                        color: AppColors.textMuted, size: 11),
                  ],
                ),
              ),
              if (hasMarketPrice && product.sellPrice != null) ...[
                const SizedBox(height: 1),
                Text(formatMktPrice(displayMarketPrice),
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        decoration: TextDecoration.lineThrough)),
              ] else if (hasMarketPrice &&
                  product.sellPrice == null) ...[
                const SizedBox(height: 1),
                Builder(builder: (context) {
                  final pnl = displayMarketPrice - product.price;
                  final isUp = pnl >= 0;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          isUp
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: isUp
                              ? AppColors.accentGreen
                              : AppColors.accentRed,
                          size: 10),
                      Text(
                          '${isUp ? "+" : ""}€${pnl.toStringAsFixed(2)}',
                          style: TextStyle(
                              color: isUp
                                  ? AppColors.accentGreen
                                  : AppColors.accentRed,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  );
                }),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
//  Tab 2: eBay
// ═══════════════════════════════════════════════════

class _EbayTab extends StatefulWidget {
  final EbayService ebayService;
  const _EbayTab({required this.ebayService});

  @override
  State<_EbayTab> createState() => _EbayTabState();
}

class _EbayTabState extends State<_EbayTab> {
  bool _connected = false;
  String? _ebayUserId;
  bool _loading = true;
  bool _connecting = false;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      final status = await widget.ebayService.getConnectionStatus();
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
      final url = await widget.ebayService.getAuthUrl();
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (!mounted) return;
      final code = await _showCodeDialog();
      if (code != null && code.isNotEmpty) {
        await widget.ebayService.connectEbay(code);
        await _checkConnection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Errore: $e'),
              backgroundColor: AppColors.accentRed),
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Codice di autorizzazione',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Dopo aver autorizzato su eBay, incolla qui il codice dalla URL di callback.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration:
                  const InputDecoration(hintText: 'Codice...'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue),
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Connetti'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncOrders() async {
    setState(() => _syncing = true);
    try {
      await widget.ebayService.fetchOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Errore sync: $e'),
              backgroundColor: AppColors.accentRed),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child:
              CircularProgressIndicator(color: AppColors.accentBlue));
    }

    if (!_connected) {
      return _buildConnectPrompt();
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Connection status
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accentGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text('Connesso come $_ebayUserId',
                    style: const TextStyle(
                        color: AppColors.accentGreen, fontSize: 13)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _syncing ? null : _syncOrders,
                  icon: _syncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accentBlue))
                      : const Icon(Icons.sync, size: 18),
                  label: const Text('Aggiorna',
                      style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
        // Active Listings section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('Inserzioni attive',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: StreamBuilder<List<EbayListing>>(
              stream: widget.ebayService.streamListings(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accentBlue));
                }
                final listings = snap.data ?? [];
                if (listings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            color: AppColors.textMuted, size: 36),
                        const SizedBox(height: 8),
                        const Text('Nessuna inserzione',
                            style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: listings.length,
                  itemBuilder: (context, i) {
                    final listing = listings[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        child: ListTile(
                          leading: listing.imageUrls.isNotEmpty
                              ? ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  child: Image.network(
                                      listing.imageUrls.first,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover),
                                )
                              : Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLight,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.image,
                                      color: AppColors.textMuted),
                                ),
                          title: Text(listing.title,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                              '${listing.formattedPrice} · ${listing.statusLabel}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                          trailing: _statusDot(listing.status),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        // Orders section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Ordini recenti',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 300,
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
                            color: AppColors.textMuted, size: 36),
                        const SizedBox(height: 8),
                        const Text('Nessun ordine',
                            style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: orders.length,
                  itemBuilder: (context, i) {
                    final order = orders[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => _showOrderDetail(order),
                        child: GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.items.isNotEmpty
                                            ? order.items.first.title
                                            : order.ebayOrderId,
                                        style: const TextStyle(
                                            color:
                                                AppColors.textPrimary,
                                            fontSize: 14,
                                            fontWeight:
                                                FontWeight.w500),
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${order.buyerUsername} · ${order.formattedTotal}',
                                        style: const TextStyle(
                                            color: AppColors
                                                .textSecondary,
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

  Widget _buildConnectPrompt() {
    return Center(
      child: StaggeredFadeSlide(
        index: 0,
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
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
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
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _connecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
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

  Widget _statusDot(String status) {
    final color = status == 'active'
        ? AppColors.accentGreen
        : status == 'draft'
            ? AppColors.accentOrange
            : AppColors.textMuted;
    return Container(
      width: 10,
      height: 10,
      decoration:
          BoxDecoration(color: color, shape: BoxShape.circle),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }
}

