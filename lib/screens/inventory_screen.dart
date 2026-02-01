import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/product.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../l10n/app_localizations.dart';

class InventoryScreen extends StatefulWidget {
  final void Function(Product product)? onEditProduct;

  const InventoryScreen({super.key, this.onEditProduct});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _searchFocused = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return StreamBuilder<List<Product>>(
      stream: _firestoreService.getProducts(),
      builder: (context, snapshot) {
        final allProducts = snapshot.data ?? [];
        final products = allProducts.where((p) {
          if (_searchQuery.isEmpty) return true;
          return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.brand.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

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
            const SizedBox(height: 16),
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
                        hintText: l.searchProduct,
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

  Widget _buildEmptyState() {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
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
          Text(
            l.addYourFirstProduct,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
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
    final shipped =
        products.where((p) => p.status == ProductStatus.shipped).length;
    final inStock =
        products.where((p) => p.status == ProductStatus.inInventory).length;
    final listed =
        products.where((p) => p.status == ProductStatus.listed).length;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        StaggeredFadeSlide(
          index: 0,
          child: _buildSummaryCard(l.totalInventoryValue,
              '€${totalValue.toStringAsFixed(2)}', Icons.euro, AppColors.accentBlue),
        ),
        const SizedBox(height: 12),
        StaggeredFadeSlide(
          index: 1,
          child: _buildSummaryCard(l.shippedProducts, '$shipped',
              Icons.local_shipping, AppColors.accentOrange),
        ),
        const SizedBox(height: 12),
        StaggeredFadeSlide(
          index: 2,
          child: _buildSummaryCard(l.inInventory, '$inStock',
              Icons.inventory_2, AppColors.accentTeal),
        ),
        const SizedBox(height: 12),
        StaggeredFadeSlide(
          index: 3,
          child: _buildSummaryCard(l.onSale, '$listed', Icons.storefront,
              AppColors.accentGreen),
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
              _getProductIcon(product.brand),
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

  Color _getProductColor(String brand) {
    switch (brand.toUpperCase()) {
      case 'NIKE':
        return const Color(0xFFFF6B35);
      case 'ADIDAS':
        return const Color(0xFF00B4D8);
      case 'STONE ISLAND':
        return const Color(0xFFFFC107);
      case 'BITCOIN':
        return const Color(0xFFF7931A);
      default:
        return AppColors.accentBlue;
    }
  }

  IconData _getProductIcon(String brand) {
    switch (brand.toUpperCase()) {
      case 'NIKE':
        return Icons.directions_run;
      case 'ADIDAS':
        return Icons.sports_soccer;
      case 'STONE ISLAND':
        return Icons.checkroom;
      case 'BITCOIN':
        return Icons.currency_bitcoin;
      default:
        return Icons.shopping_bag;
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
