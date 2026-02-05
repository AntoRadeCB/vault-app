import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/product.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../services/card_catalog_service.dart';
import '../providers/profile_provider.dart';
import '../models/user_profile.dart';
import '../l10n/app_localizations.dart';
import 'dart:math' as math;

class InventoryScreen extends StatefulWidget {
  final void Function(Product product)? onEditProduct;
  final void Function(Product product)? onOpenProduct;

  const InventoryScreen({super.key, this.onEditProduct, this.onOpenProduct});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _searchFocused = false;
  String _kindFilter = 'all'; // all, singleCard, boosterPack, boosterBox, display
  final FirestoreService _firestoreService = FirestoreService();
  final CardCatalogService _catalogService = CardCatalogService();
  Map<String, double> _livePrices = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadLivePrices();
  }

  Future<void> _loadLivePrices() async {
    try {
      final cards = await _catalogService.getAllCards();
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
    _tabController.dispose();
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

    return filtered;
  }

  void _confirmDelete(Product product) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.deleteProduct,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          l.confirmDeleteProduct(product.name),
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
              if (product.id != null) {
                _firestoreService.deleteProduct(product.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l.productDeleted(product.name)),
                    backgroundColor: AppColors.accentRed,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            child: Text(l.delete,
                style: const TextStyle(
                    color: AppColors.accentRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Compute effective collection target for a product
  int _effectiveTarget(Product p, int profileTarget) {
    return p.collectionTargetOverride ?? profileTarget;
  }

  /// Filter products for inventory view:
  /// - Non-singleCard: show as-is
  /// - SingleCard: only show if qty > effectiveTarget, display excess qty
  List<Product> _applyInventoryLogic(List<Product> products, int profileTarget) {
    final result = <Product>[];
    for (final p in products) {
      if (p.kind != ProductKind.singleCard) {
        result.add(p);
      } else {
        final target = _effectiveTarget(p, profileTarget);
        final excess = p.quantity - target;
        if (excess > 0) {
          // Show card with excess quantity
          result.add(p.copyWith(quantity: excess));
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final provider = ProfileProvider.maybeOf(context);
    final profileTarget = provider?.profile?.collectionTarget ?? 1;

    return StreamBuilder<List<Product>>(
      stream: _firestoreService.getProducts(),
      builder: (context, snapshot) {
        final allProducts = snapshot.data ?? [];
        // Apply inventory logic: only show excess for single cards
        final inventoryProducts = _applyInventoryLogic(allProducts, profileTarget);
        final products = _applyFilters(inventoryProducts);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: StaggeredFadeSlide(
                index: 0,
                child: Row(
                  children: [
                    Text(
                      l.inventory,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accentBlue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        l.nRecords(products.length),
                        style: const TextStyle(
                          color: AppColors.accentBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ─── Kind filter chips ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: StaggeredFadeSlide(
                index: 0,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'Tutto', Icons.grid_view),
                      const SizedBox(width: 6),
                      _buildFilterChip('singleCard', 'Carte', Icons.style),
                      const SizedBox(width: 6),
                      _buildFilterChip('boosterPack', 'Buste', Icons.inventory_2_outlined),
                      const SizedBox(width: 6),
                      _buildFilterChip('boosterBox', 'Box', Icons.all_inbox),
                      const SizedBox(width: 6),
                      _buildFilterChip('display', 'Display', Icons.view_module),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: StaggeredFadeSlide(
                index: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
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
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: l.historicalRecords),
                      Tab(text: l.productSummary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: StaggeredFadeSlide(
                index: 2,
                child: Focus(
                  onFocusChange: (f) => setState(() => _searchFocused = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _searchFocused
                            ? AppColors.accentBlue.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                      boxShadow: _searchFocused
                          ? [
                              BoxShadow(
                                color: AppColors.accentBlue
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
                        hintText: 'Cerca carta, busta, box...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: _searchFocused
                              ? AppColors.accentBlue
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
            ),
            const SizedBox(height: 16),
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accentBlue))
                  : TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        products.isEmpty
                            ? _buildEmptyState()
                            : _buildProductList(products),
                        _buildProductSummary(products),
                      ],
                    ),
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
              ? AppColors.accentBlue.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.accentBlue.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isSelected ? AppColors.accentBlue : AppColors.textMuted),
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
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.style_outlined,
              color: AppColors.textMuted.withValues(alpha: 0.5), size: 64),
          const SizedBox(height: 16),
          Text(
            l.noProducts,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aggiungi la tua prima carta o busta',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<Product> products) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return StaggeredFadeSlide(
          index: index + 3,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Dismissible(
              key: ValueKey(products[index].id ?? products[index].name),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.delete_outline,
                    color: AppColors.accentRed, size: 24),
              ),
              confirmDismiss: (_) async {
                _confirmDelete(products[index]);
                return false;
              },
              child: GestureDetector(
                onTap: () => widget.onEditProduct?.call(products[index]),
                child: HoverLiftCard(
                  liftAmount: 3,
                  child: _buildProductCard(products[index]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductSummary(List<Product> products) {
    final l = AppLocalizations.of(context)!;
    final totalValue =
        products.fold<double>(0, (sum, p) => sum + (p.price * p.quantity));
    final singleCards =
        products.where((p) => p.kind == ProductKind.singleCard).length;
    final sealedProducts =
        products.where((p) => p.kind != ProductKind.singleCard).length;
    final inStock =
        products.where((p) => p.status == ProductStatus.inInventory).length;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        StaggeredFadeSlide(
          index: 0,
          child: _buildSummaryCard('Valore Collezione',
              '€${totalValue.toStringAsFixed(2)}', Icons.euro, AppColors.accentBlue),
        ),
        const SizedBox(height: 12),
        StaggeredFadeSlide(
          index: 1,
          child: _buildSummaryCard('Carte Singole', '$singleCards',
              Icons.style, AppColors.accentPurple),
        ),
        const SizedBox(height: 12),
        StaggeredFadeSlide(
          index: 2,
          child: _buildSummaryCard('Prodotti Sigillati', '$sealedProducts',
              Icons.inventory_2_outlined, AppColors.accentOrange),
        ),
        const SizedBox(height: 12),
        StaggeredFadeSlide(
          index: 3,
          child: _buildSummaryCard(l.inInventory, '$inStock',
              Icons.inventory_2, AppColors.accentTeal),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      glowColor: color,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    // Use card-specific display if it's a linked card
    if (product.isCard && product.kind == ProductKind.singleCard) {
      return _buildCardProductCard(product);
    }

    // Sealed/opened product display
    if (product.kind != ProductKind.singleCard) {
      return _buildSealedProductCard(product);
    }

    return _buildGenericProductCard(product);
  }

  Widget _buildSealedProductCard(Product product) {
    final badgeColor = AppColors.accentOrange;
    final productImage = product.displayImageUrl;
    final hasImage = productImage.isNotEmpty;

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
              border: Border.all(
                color: badgeColor.withValues(alpha: 0.2),
              ),
              boxShadow: hasImage
                  ? [
                      BoxShadow(
                        color: badgeColor.withValues(alpha: 0.15),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.network(
                      productImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        _kindIcon(product.kind),
                        color: badgeColor,
                        size: 24,
                      ),
                    ),
                  )
                : Icon(
                    _kindIcon(product.kind),
                    color: badgeColor,
                    size: 24,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
                      child: Text(
                        product.kindLabel,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Qta: ${product.formattedQuantity}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                product.formattedPrice,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              if (product.canBeOpened && product.quantity > 0)
                ScaleOnPress(
                  onTap: () => widget.onOpenProduct?.call(product),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFE53935)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_open, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text('Apri',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                )
              else
                _buildStatusBadge(product.status, product.statusLabel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenericProductCard(Product product) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      glowColor: _getProductColor(product.brand),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getProductColor(product.brand).withValues(alpha: 0.2),
                  _getProductColor(product.brand).withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getProductColor(product.brand).withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              Icons.style,
              color: _getProductColor(product.brand),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getProductColor(product.brand)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.brand,
                        style: TextStyle(
                          color: _getProductColor(product.brand),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Qta: ${product.formattedQuantity}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                product.formattedPrice,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              _buildStatusBadge(product.status, product.statusLabel),
            ],
          ),
        ],
      ),
    );
  }

  IconData _kindIcon(ProductKind kind) {
    switch (kind) {
      case ProductKind.singleCard:
        return Icons.style;
      case ProductKind.boosterPack:
        return Icons.inventory_2_outlined;
      case ProductKind.boosterBox:
        return Icons.all_inbox;
      case ProductKind.display:
        return Icons.view_module;
      case ProductKind.bundle:
        return Icons.card_giftcard;
    }
  }

  Color _getRarityColor(String? rarity) {
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

  Widget _buildCardProductCard(Product product) {
    final rarityColor = _getRarityColor(product.cardRarity);
    // Use live price from catalog if available, fallback to stored price
    final livePrice = (product.cardBlueprintId != null)
        ? _livePrices[product.cardBlueprintId!]
        : null;
    final displayMarketPrice = livePrice ?? product.marketPrice;
    final hasMarketPrice = displayMarketPrice != null;

    String formatMktPrice(double p) {
      if (p >= 1000) return '€${p.toStringAsFixed(0)}';
      return '€${p.toStringAsFixed(2)}';
    }

    return GlassCard(
      padding: const EdgeInsets.all(10),
      glowColor: rarityColor,
      child: Row(
        children: [
          // Card image
          Container(
            width: 52,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: rarityColor.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: rarityColor.withValues(alpha: 0.15),
                  blurRadius: 6,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: product.cardImageUrl != null
                  ? Image.network(
                      product.cardImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: rarityColor.withValues(alpha: 0.1),
                        child: Icon(Icons.style, color: rarityColor, size: 22),
                      ),
                    )
                  : Container(
                      color: rarityColor.withValues(alpha: 0.1),
                      child: Icon(Icons.style, color: rarityColor, size: 22),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (product.cardExpansion != null) ...[
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            product.cardExpansion!,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (product.cardRarity != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: rarityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          product.cardRarity!,
                          style: TextStyle(
                            color: rarityColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Qta: ${product.formattedQuantity}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Purchase price
              Text(
                product.formattedPrice,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              if (hasMarketPrice) ...[
                const SizedBox(height: 2),
                // Live market price (prominent)
                Text(
                  formatMktPrice(displayMarketPrice),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 1),
                // P&L indicator
                Builder(builder: (context) {
                  final pnl = displayMarketPrice - product.price;
                  final isUp = pnl >= 0;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUp ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isUp ? AppColors.accentGreen : AppColors.accentRed,
                        size: 10,
                      ),
                      Text(
                        '${isUp ? "+" : ""}€${pnl.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isUp ? AppColors.accentGreen : AppColors.accentRed,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                }),
              ] else ...[
                Text(
                  product.formattedPrice,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              _buildStatusBadge(product.status, product.statusLabel),
            ],
          ),
        ],
      ),
    );
  }

  Color _getProductColor(String brand) {
    switch (brand.toUpperCase()) {
      case 'POKÉMON':
      case 'POKEMON':
        return const Color(0xFFFFCB05);
      case 'MTG':
      case 'MAGIC':
        return const Color(0xFF764ba2);
      case 'YU-GI-OH!':
      case 'YUGIOH':
        return const Color(0xFFE53935);
      case 'RIFTBOUND':
        return const Color(0xFF667eea);
      case 'ONE PIECE':
        return const Color(0xFFFF7043);
      default:
        return AppColors.accentBlue;
    }
  }

  Widget _buildStatusBadge(ProductStatus status, String label) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    switch (status) {
      case ProductStatus.shipped:
        textColor = const Color(0xFFFF6B6B);
        bgColor = textColor.withValues(alpha: 0.12);
        borderColor = textColor.withValues(alpha: 0.25);
        break;
      case ProductStatus.inInventory:
        textColor = AppColors.accentBlue;
        bgColor = textColor.withValues(alpha: 0.12);
        borderColor = textColor.withValues(alpha: 0.25);
        break;
      case ProductStatus.listed:
        textColor = AppColors.accentGreen;
        bgColor = textColor.withValues(alpha: 0.12);
        borderColor = textColor.withValues(alpha: 0.25);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
