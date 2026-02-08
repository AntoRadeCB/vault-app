import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';
import '../services/demo_data_service.dart';
import '../services/ebay_service.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;
  final VoidCallback? onBack;
  final VoidCallback? onSaved;

  const EditProductScreen({
    super.key,
    required this.product,
    this.onBack,
    this.onSaved,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final FirestoreService _fs = FirestoreService();
  final EbayService _ebayService = EbayService();
  late Product _product;
  bool _saving = false;
  // eBay price data
  bool _loadingPrices = false;
  Map<String, dynamic>? _ebayPrices;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _fetchEbayPrices();
  }

  Future<void> _fetchEbayPrices() async {
    if (FirestoreService.demoMode) return;
    setState(() => _loadingPrices = true);
    try {
      final query = '${_product.name} ${_product.cardExpansion ?? ''}'.trim();
      final result = await _ebayService.priceCheck(query, limit: 6);
      if (mounted) setState(() => _ebayPrices = result);
    } catch (_) {
      // API not configured yet — ignore
    } finally {
      if (mounted) setState(() => _loadingPrices = false);
    }
  }

  Future<void> _updateField(Map<String, dynamic> updates) async {
    setState(() => _saving = true);
    try {
      if (FirestoreService.demoMode) {
        final idx = DemoDataService.products.indexWhere((p) => p.id == _product.id);
        if (idx >= 0) {
          var p = DemoDataService.products[idx];
          if (updates.containsKey('sellPrice')) p = p.copyWith(sellPrice: updates['sellPrice']);
          if (updates.containsKey('inventoryQty')) p = p.copyWith(inventoryQty: updates['inventoryQty']);
          if (updates.containsKey('quantity')) p = p.copyWith(quantity: updates['quantity']);
          DemoDataService.products[idx] = p;
          setState(() => _product = p);
        }
      } else {
        await _fs.updateProduct(_product.id!, updates);
        // Rebuild product locally
        var p = _product;
        if (updates.containsKey('sellPrice')) p = p.copyWith(sellPrice: (updates['sellPrice'] as num?)?.toDouble());
        if (updates.containsKey('inventoryQty')) p = p.copyWith(inventoryQty: (updates['inventoryQty'] as num).toDouble());
        if (updates.containsKey('quantity')) p = p.copyWith(quantity: (updates['quantity'] as num).toDouble());
        setState(() => _product = p);
      }
      widget.onSaved?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: AppColors.accentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editSellPrice() async {
    final controller = TextEditingController(
      text: _product.sellPrice?.toStringAsFixed(2) ?? _product.marketPrice?.toStringAsFixed(2) ?? '',
    );
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Prezzo di vendita', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  prefixText: '€ ',
                  prefixStyle: TextStyle(color: AppColors.accentGreen, fontSize: 24, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                        child: const Center(child: Text('Annulla', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final v = double.tryParse(controller.text.trim());
                        Navigator.pop(ctx, v);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: AppColors.blueButtonGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text('Salva', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null) {
      await _updateField({'sellPrice': result});
    }
  }

  Future<void> _editInventoryQty() async {
    double qty = _product.inventoryQty;
    final maxQty = _product.quantity;
    final result = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Quantità in vendita', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Max: ${maxQty.toInt()} disponibili', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () { if (qty > 0) setSheetState(() => qty--); },
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.remove, color: AppColors.textSecondary, size: 24),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text('${qty.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  ),
                  GestureDetector(
                    onTap: () { if (qty < maxQty) setSheetState(() => qty++); },
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.add, color: AppColors.accentBlue, size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(ctx, qty),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.blueButtonGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('Conferma', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null) {
      await _updateField({'inventoryQty': result});
    }
  }

  Future<void> _removeFromMarketplace() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rimuovi dal marketplace', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Vuoi rimuovere questo prodotto dal marketplace? Tornerà nella collezione.',
          style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rimuovi', style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _updateField({'inventoryQty': 0, 'sellPrice': null});
      if (mounted) widget.onBack?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _product.displayImageUrl.isNotEmpty;
    final isCard = _product.isCard;
    final sellPrice = _product.effectiveSellPrice;
    final marketPrice = _product.marketPrice;
    final profit = marketPrice != null ? sellPrice - _product.price : null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header with back button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                ScaleOnPress(
                  onTap: () => widget.onBack?.call(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Scheda prodotto',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                if (_saving)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentBlue)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Product image + info card ──
          StaggeredFadeSlide(
            index: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: hasImage
                          ? Image.network(_product.displayImageUrl, width: 100, height: 140, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imagePlaceholder())
                          : _imagePlaceholder(),
                      ),
                      const SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_product.name,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            if (_product.cardExpansion != null)
                              _infoChip(Icons.style, _product.cardExpansion!),
                            if (_product.cardRarity != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: _infoChip(Icons.diamond_outlined, _product.cardRarity!),
                              ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _kindBadge(_product.kindLabel),
                                const SizedBox(width: 8),
                                Text('x${_product.quantity.toInt()}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            if (_product.brand.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(_product.brand,
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Pricing section ──
          StaggeredFadeSlide(
            index: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sell_outlined, color: AppColors.accentGreen, size: 18),
                          const SizedBox(width: 8),
                          const Text('Listino', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Sell price row
                      _priceRow(
                        'Prezzo vendita',
                        '€${sellPrice.toStringAsFixed(2)}',
                        AppColors.accentGreen,
                        onTap: _editSellPrice,
                      ),
                      const Divider(color: Colors.white12, height: 24),
                      // Market price
                      if (marketPrice != null)
                        _priceRow('Prezzo mercato', '€${marketPrice.toStringAsFixed(2)}', AppColors.accentBlue),
                      if (marketPrice != null)
                        const Divider(color: Colors.white12, height: 24),
                      // Purchase price
                      _priceRow('Prezzo acquisto', '€${_product.price.toStringAsFixed(2)}', AppColors.textMuted),
                      if (profit != null) ...[
                        const Divider(color: Colors.white12, height: 24),
                        _priceRow(
                          'Profitto stimato',
                          '${profit >= 0 ? '+' : ''}€${profit.toStringAsFixed(2)}',
                          profit >= 0 ? AppColors.accentGreen : AppColors.accentRed,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Inventory section ──
          StaggeredFadeSlide(
            index: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, color: AppColors.accentBlue, size: 18),
                          const SizedBox(width: 8),
                          const Text('Inventario', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _editInventoryQty,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            children: [
                              Text('In vendita', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                              const Spacer(),
                              Text('${_product.inventoryQty.toInt()} / ${_product.quantity.toInt()}',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              const Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 16),
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

          const SizedBox(height: 12),

          // ── Marketplace status ──
          StaggeredFadeSlide(
            index: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storefront, color: AppColors.accentOrange, size: 18),
                          const SizedBox(width: 8),
                          const Text('Marketplace', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _marketplaceRow('eBay', Icons.store, const Color(0xFFE53238), false),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── eBay recently sold ──
          StaggeredFadeSlide(
            index: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trending_up, color: Color(0xFFE53238), size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Venduto di recente su eBay',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                          if (_loadingPrices)
                            const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE53238))),
                          if (!_loadingPrices && _ebayPrices == null)
                            GestureDetector(
                              onTap: _fetchEbayPrices,
                              child: const Icon(Icons.refresh, color: AppColors.textMuted, size: 18),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_ebayPrices != null && (_ebayPrices!['count'] as int) > 0) ...[
                        // Price range bar
                        _ebayPriceRange(
                          _ebayPrices!['minPrice'] as double?,
                          _ebayPrices!['avgPrice'] as double?,
                          _ebayPrices!['maxPrice'] as double?,
                        ),
                        const SizedBox(height: 12),
                        // Recent items
                        ...(_ebayPrices!['items'] as List).take(4).map<Widget>((item) =>
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _ebayItemRow(item as Map<String, dynamic>),
                          ),
                        ),
                      ] else if (_ebayPrices != null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('Nessun risultato trovato',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        )
                      else if (!_loadingPrices)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('Collega le API eBay per vedere i prezzi',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Actions ──
          StaggeredFadeSlide(
            index: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: _removeFromMarketplace,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.remove_circle_outline, color: AppColors.accentRed, size: 18),
                      SizedBox(width: 8),
                      Text('Rimuovi dal marketplace',
                        style: TextStyle(color: AppColors.accentRed, fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 100, height: 140,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: const Icon(Icons.image_outlined, color: AppColors.textMuted, size: 32),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 14),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _kindBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accentPurple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
        style: const TextStyle(color: AppColors.accentPurple, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  Widget _priceRow(String label, String value, Color valueColor, {VoidCallback? onTap}) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold)),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 14),
            ],
          ],
        ),
      ],
    );
    if (onTap != null) return GestureDetector(onTap: onTap, child: content);
    return content;
  }

  Widget _ebayPriceRange(double? min, double? avg, double? max) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _priceCol('Min', min, AppColors.accentGreen),
          Container(width: 1, height: 30, color: Colors.white12),
          _priceCol('Media', avg, const Color(0xFFE53238)),
          Container(width: 1, height: 30, color: Colors.white12),
          _priceCol('Max', max, AppColors.accentOrange),
        ],
      ),
    );
  }

  Widget _priceCol(String label, double? value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value != null ? '€${value.toStringAsFixed(2)}' : '—',
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _ebayItemRow(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (item['imageUrl'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(item['imageUrl'], width: 32, height: 32, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(width: 32, height: 32)),
            )
          else
            const SizedBox(width: 32, height: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Text(item['title'] ?? '',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text('€${(item['price'] as num).toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _marketplaceRow(String name, IconData icon, Color color, bool isListed, {bool comingSoon = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          const Spacer(),
          if (comingSoon)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Prossimamente', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isListed
                    ? AppColors.accentGreen.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isListed ? 'In vendita' : 'Non pubblicato',
                style: TextStyle(
                  color: isListed ? AppColors.accentGreen : AppColors.textMuted,
                  fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}
