import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/glow_text_field.dart';
import '../widgets/card_search_field.dart';
import '../widgets/card_browser_sheet.dart';
import '../models/product.dart';
import '../models/card_pull.dart';
import '../models/card_blueprint.dart';
import '../services/firestore_service.dart';
import '../services/card_catalog_service.dart';

/// Screen for opening a sealed product (pack/box) and logging pulled cards.
class OpenProductScreen extends StatefulWidget {
  final Product product;
  final VoidCallback? onBack;
  final VoidCallback? onDone;

  const OpenProductScreen({
    super.key,
    required this.product,
    this.onBack,
    this.onDone,
  });

  @override
  State<OpenProductScreen> createState() => _OpenProductScreenState();
}

class _OpenProductScreenState extends State<OpenProductScreen> {
  final FirestoreService _fs = FirestoreService();
  final CardCatalogService _catalogService = CardCatalogService();
  final _pullNameController = TextEditingController();
  final _pullValueController = TextEditingController();
  final _checklistSearchController = TextEditingController();

  // Local UI state — NOT tied to widget.product.isOpened
  bool _isOpened = false;
  bool _opening = false;
  bool _finishing = false;
  final List<_PullEntry> _pulls = [];
  int _quantityToOpen = 1;

  // Expansion checklist state
  List<CardBlueprint> _expansionCards = [];
  final Set<String> _checkedCardIds = {};
  bool _loadingExpansion = false;
  String _checklistSearch = '';
  bool _showChecklist = true;

  @override
  void initState() {
    super.initState();
    // _isOpened starts as false — user must click "Apri!" to open
  }

  @override
  void dispose() {
    _pullNameController.dispose();
    _pullValueController.dispose();
    _checklistSearchController.dispose();
    super.dispose();
  }

  int get _maxQuantity => widget.product.quantity.toInt().clamp(1, 999);

  /// When user clicks "Apri!", just flip local UI state and load expansion data
  void _openProduct() {
    if (_opening) return;
    setState(() {
      _opening = true;
      _isOpened = true;
      _opening = false;
    });
    _loadExpansionCards();
  }

  /// Load expansion cards for the checklist
  Future<void> _loadExpansionCards() async {
    setState(() => _loadingExpansion = true);
    try {
      int? expansionId;

      // Strategy 1: Look up the product's cardBlueprintId to get expansionId
      if (widget.product.cardBlueprintId != null) {
        final blueprint =
            await _catalogService.getCard(widget.product.cardBlueprintId!);
        if (blueprint != null && blueprint.expansionId != null) {
          expansionId = blueprint.expansionId;
        }
      }

      // Strategy 2: Match by expansion name in the catalog
      if (expansionId == null && widget.product.cardExpansion != null) {
        final expansions = await _catalogService.getExpansions();
        final expName = widget.product.cardExpansion!.toLowerCase();
        for (final exp in expansions) {
          final name = (exp['name'] as String? ?? '').toLowerCase();
          if (name == expName || name.contains(expName) || expName.contains(name)) {
            expansionId = exp['id'] as int?;
            break;
          }
        }
      }

      // Strategy 3: Search all cards for matching expansion name
      if (expansionId == null && widget.product.cardExpansion != null) {
        final allCards = await _catalogService.getAllCards();
        final expName = widget.product.cardExpansion!.toLowerCase();
        for (final card in allCards) {
          if (card.expansionName != null &&
              card.expansionName!.toLowerCase() == expName &&
              card.expansionId != null) {
            expansionId = card.expansionId;
            break;
          }
        }
      }

      if (expansionId != null) {
        final cards = await _catalogService.getCardsByExpansion(expansionId);
        // Filter to only single cards (not packs/boxes)
        final singleCards =
            cards.where((c) => c.kind == null || c.kind == 'singleCard').toList();

        // Sort by collector number
        singleCards.sort((a, b) {
          final aNum = int.tryParse(a.collectorNumber ?? '') ?? 9999;
          final bNum = int.tryParse(b.collectorNumber ?? '') ?? 9999;
          return aNum.compareTo(bNum);
        });

        if (mounted) {
          setState(() => _expansionCards = singleCards);
        }
      }
    } catch (_) {
      // Silently fail — checklist just won't show
    } finally {
      if (mounted) setState(() => _loadingExpansion = false);
    }
  }

  void _toggleChecklistCard(CardBlueprint card) {
    setState(() {
      if (_checkedCardIds.contains(card.id)) {
        // Uncheck — remove from pulls
        _checkedCardIds.remove(card.id);
        _pulls.removeWhere((p) => p.cardBlueprintId == card.id);
      } else {
        // Check — add to pulls
        _checkedCardIds.add(card.id);
        _pulls.add(_PullEntry(
          cardName: card.name,
          cardBlueprintId: card.id,
          cardImageUrl: card.imageUrl,
          cardExpansion: card.expansionName,
          rarity: card.rarity,
          estimatedValue: card.marketPrice != null
              ? card.marketPrice!.cents / 100
              : null,
        ));
      }
    });
  }

  void _addPull({CardBlueprint? card}) {
    final name = card?.name ?? _pullNameController.text.trim();
    if (name.isEmpty) return;

    final valueText = _pullValueController.text.trim();
    double? value = double.tryParse(valueText);
    if (card?.marketPrice != null && value == null) {
      value = card!.marketPrice!.cents / 100;
    }

    setState(() {
      _pulls.add(_PullEntry(
        cardName: name,
        cardBlueprintId: card?.id,
        cardImageUrl: card?.imageUrl,
        cardExpansion: card?.expansionName,
        rarity: card?.rarity,
        estimatedValue: value,
      ));
      if (card != null) {
        _checkedCardIds.add(card.id);
      }
      _pullNameController.clear();
      _pullValueController.clear();
    });
  }

  void _removePull(int index) {
    setState(() {
      final pull = _pulls[index];
      if (pull.cardBlueprintId != null) {
        _checkedCardIds.remove(pull.cardBlueprintId);
      }
      _pulls.removeAt(index);
    });
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    try {
      final productId = widget.product.id;
      final isDemoMode = FirestoreService.demoMode;

      if (productId != null && !isDemoMode) {
        // 1. Save all pulls as CardPull records (history tracking)
        for (final pull in _pulls) {
          final cardPull = CardPull(
            parentProductId: productId,
            cardName: pull.cardName,
            cardBlueprintId: pull.cardBlueprintId,
            cardImageUrl: pull.cardImageUrl,
            rarity: pull.rarity,
            estimatedValue: pull.estimatedValue,
            pulledAt: DateTime.now(),
          );
          await _fs.addCardPull(cardPull);
        }

        // 2. Add pulled cards as new Product items in inventory
        for (final pull in _pulls) {
          final newProduct = Product(
            name: pull.cardName,
            brand: widget.product.brand,
            quantity: 1,
            price: pull.estimatedValue ?? 0,
            status: ProductStatus.inInventory,
            kind: ProductKind.singleCard,
            cardBlueprintId: pull.cardBlueprintId,
            cardImageUrl: pull.cardImageUrl,
            cardExpansion: pull.cardExpansion,
            cardRarity: pull.rarity,
            marketPrice: pull.estimatedValue,
            parentProductId: productId,
            createdAt: DateTime.now(),
          );
          await _fs.addProduct(newProduct);
        }

        // 3. Decrement source product quantity by the number opened
        await _fs.decrementProductQuantity(
            productId, _quantityToOpen.toDouble());
      }

      if (mounted) widget.onDone?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  Future<void> _openCardBrowser() async {
    final card = await CardBrowserSheet.show(context);
    if (card != null && mounted) {
      _addPull(card: card);
    }
  }

  double get _totalPullValue {
    return _pulls.fold(0.0, (sum, p) => sum + (p.estimatedValue ?? 0));
  }

  List<CardBlueprint> get _filteredExpansionCards {
    if (_checklistSearch.isEmpty) return _expansionCards;
    final q = _checklistSearch.toLowerCase();
    return _expansionCards.where((c) {
      return c.name.toLowerCase().contains(q) ||
          (c.collectorNumber ?? '').contains(q) ||
          (c.rarity ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          StaggeredFadeSlide(
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
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _isOpened ? 'Registra Pulls' : 'Apri Prodotto',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Product info card
          StaggeredFadeSlide(
            index: 1,
            child: _buildProductInfoCard(),
          ),
          const SizedBox(height: 24),

          // Quantity selector (before opening)
          if (!_isOpened && _maxQuantity > 1)
            StaggeredFadeSlide(
              index: 2,
              child: _buildQuantitySelector(),
            ),
          if (!_isOpened && _maxQuantity > 1) const SizedBox(height: 16),

          // Open button (if not opened yet)
          if (!_isOpened)
            StaggeredFadeSlide(
              index: 3,
              child: ShimmerButton(
                baseGradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFE53935)],
                ),
                onTap: _opening ? null : _openProduct,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_opening)
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      else ...[
                        const Icon(Icons.lock_open,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          _quantityToOpen > 1
                              ? 'Apri $_quantityToOpen! 🎉'
                              : 'Apri! 🎉',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // Pull logging interface (shown after opening)
          if (_isOpened) ...[
            // Pull total value
            if (_pulls.isNotEmpty)
              StaggeredFadeSlide(
                index: 2,
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  glowColor: AppColors.accentGreen,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              AppColors.accentGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.trending_up,
                            color: AppColors.accentGreen, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Valore totale pulls',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                          Text(
                            '€${_totalPullValue.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.accentGreen,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '${_pulls.length} carte',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Expansion checklist section
            if (_loadingExpansion)
              StaggeredFadeSlide(
                index: 2,
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accentPurple.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Caricamento espansione...',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_expansionCards.isNotEmpty) ...[
              StaggeredFadeSlide(
                index: 2,
                child: _buildExpansionChecklist(),
              ),
              const SizedBox(height: 16),
            ],

            // Quick add pull (manual)
            StaggeredFadeSlide(
              index: 3,
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.add_circle_outline,
                            color: AppColors.accentBlue, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Aggiungi carta',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        ScaleOnPress(
                          onTap: _openCardBrowser,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF764ba2),
                                  Color(0xFF667eea)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.style,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Catalogo',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GlowTextField(
                      controller: _pullNameController,
                      hintText: 'Nome carta...',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GlowTextField(
                            controller: _pullValueController,
                            hintText: 'Valore €',
                            keyboardType: TextInputType.number,
                            prefixText: '€ ',
                          ),
                        ),
                        const SizedBox(width: 8),
                        ScaleOnPress(
                          onTap: () => _addPull(),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: AppColors.blueButtonGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pulls list
            ...List.generate(_pulls.length, (i) {
              final pull = _pulls[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: StaggeredFadeSlide(
                  index: 4 + i,
                  child: GlassCard(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        // Card image or icon
                        Container(
                          width: 40,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: AppColors.surface,
                          ),
                          child: pull.cardImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(pull.cardImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.style,
                                              color: AppColors.textMuted,
                                              size: 20)),
                                )
                              : const Icon(Icons.style,
                                  color: AppColors.textMuted, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pull.cardName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (pull.rarity != null)
                                Text(
                                  pull.rarity!,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (pull.estimatedValue != null)
                          Text(
                            '€${pull.estimatedValue!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.accentGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(width: 8),
                        ScaleOnPress(
                          onTap: () => _removePull(i),
                          child: const Icon(Icons.close,
                              color: AppColors.textMuted, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // Finish button
            StaggeredFadeSlide(
              index: 4 + _pulls.length,
              child: ShimmerButton(
                baseGradient: const LinearGradient(
                  colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                ),
                onTap: _finishing ? null : _finish,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_finishing)
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      else ...[
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        const Text(
                          'Fatto',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductInfoCard() {
    final productImage = widget.product.displayImageUrl;
    final hasImage = productImage.isNotEmpty;
    final accentColor =
        _isOpened ? AppColors.accentGreen : AppColors.accentOrange;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      glowColor: accentColor,
      child: Row(
        children: [
          Container(
            width: 56,
            height: hasImage ? 78 : 56,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(hasImage ? 6 : 12),
              border: hasImage
                  ? Border.all(color: accentColor.withValues(alpha: 0.3))
                  : null,
              boxShadow: hasImage
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.15),
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
                        _isOpened ? Icons.inventory_2 : Icons.lock,
                        color: accentColor,
                        size: 28,
                      ),
                    ),
                  )
                : Icon(
                    _isOpened ? Icons.inventory_2 : Icons.lock,
                    color: accentColor,
                    size: 28,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.product.kindLabel,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (widget.product.cardExpansion != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentPurple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.product.cardExpansion!,
                            style: const TextStyle(
                              color: AppColors.accentPurple,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (widget.product.quantity > 1) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Quantità disponibile: ${widget.product.formattedQuantity}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            widget.product.formattedPrice,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      glowColor: AppColors.accentBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.numbers, color: AppColors.accentBlue, size: 18),
              SizedBox(width: 8),
              Text(
                'Quanti vuoi aprire?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Decrement button
              ScaleOnPress(
                onTap: _quantityToOpen > 1
                    ? () => setState(() => _quantityToOpen--)
                    : null,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _quantityToOpen > 1
                        ? AppColors.accentBlue.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _quantityToOpen > 1
                          ? AppColors.accentBlue.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Icon(
                    Icons.remove,
                    color: _quantityToOpen > 1
                        ? AppColors.accentBlue
                        : AppColors.textMuted,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Quantity display
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.blueButtonGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentBlue.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Text(
                  '$_quantityToOpen',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Increment button
              ScaleOnPress(
                onTap: _quantityToOpen < _maxQuantity
                    ? () => setState(() => _quantityToOpen++)
                    : null,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _quantityToOpen < _maxQuantity
                        ? AppColors.accentBlue.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _quantityToOpen < _maxQuantity
                          ? AppColors.accentBlue.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    color: _quantityToOpen < _maxQuantity
                        ? AppColors.accentBlue
                        : AppColors.textMuted,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'su ${widget.product.formattedQuantity} disponibili',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionChecklist() {
    final filteredCards = _filteredExpansionCards;
    final checkedCount = _checkedCardIds.length;
    final totalCount = _expansionCards.length;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      glowColor: AppColors.accentPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with toggle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.checklist,
                    color: AppColors.accentPurple, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Checklist Espansione',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$checkedCount/$totalCount trovate',
                      style: TextStyle(
                        color: checkedCount > 0
                            ? AppColors.accentGreen
                            : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ScaleOnPress(
                onTap: () => setState(() => _showChecklist = !_showChecklist),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showChecklist
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.textMuted,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showChecklist ? 'Nascondi' : 'Mostra',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Progress bar
          if (_showChecklist) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: totalCount > 0 ? checkedCount / totalCount : 0,
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.accentPurple),
              ),
            ),
            const SizedBox(height: 12),

            // Search within checklist
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: TextField(
                controller: _checklistSearchController,
                onChanged: (v) => setState(() => _checklistSearch = v),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Cerca nell\'espansione...',
                  hintStyle: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                      fontSize: 13),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textMuted, size: 18),
                  suffixIcon: _checklistSearch.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.textMuted, size: 16),
                          onPressed: () {
                            _checklistSearchController.clear();
                            setState(() => _checklistSearch = '');
                          },
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Card grid
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: filteredCards.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          _checklistSearch.isNotEmpty
                              ? 'Nessuna carta trovata'
                              : 'Nessuna carta disponibile',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.55,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: filteredCards.length,
                      itemBuilder: (context, index) {
                        final card = filteredCards[index];
                        final isChecked = _checkedCardIds.contains(card.id);
                        return _buildChecklistCard(card, isChecked);
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChecklistCard(CardBlueprint card, bool isChecked) {
    return ScaleOnPress(
      onTap: () => _toggleChecklistCard(card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isChecked
                ? AppColors.accentGreen.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.08),
            width: isChecked ? 2 : 1,
          ),
          boxShadow: isChecked
              ? [
                  BoxShadow(
                    color: AppColors.accentGreen.withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Card content
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card image
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(9)),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isChecked ? 0.5 : 1.0,
                      child: card.imageUrl != null
                          ? Image.network(
                              card.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: card.rarityColor.withValues(alpha: 0.08),
                                child: Center(
                                  child: Icon(Icons.style,
                                      color: card.rarityColor
                                          .withValues(alpha: 0.3),
                                      size: 24),
                                ),
                              ),
                            )
                          : Container(
                              color: card.rarityColor.withValues(alpha: 0.08),
                              child: Center(
                                child: Icon(Icons.style,
                                    color: card.rarityColor
                                        .withValues(alpha: 0.3),
                                    size: 24),
                              ),
                            ),
                    ),
                  ),
                ),
                // Card info
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isChecked
                        ? AppColors.accentGreen.withValues(alpha: 0.08)
                        : AppColors.surface,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.collectorNumber != null
                            ? '#${card.collectorNumber}'
                            : '',
                        style: TextStyle(
                          color: isChecked
                              ? AppColors.accentGreen
                              : AppColors.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        card.name,
                        style: TextStyle(
                          color: isChecked ? AppColors.accentGreen : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Checkbox overlay
            Positioned(
              top: 4,
              right: 4,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isChecked
                      ? AppColors.accentGreen
                      : Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isChecked
                        ? AppColors.accentGreen
                        : Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: isChecked
                    ? const Icon(Icons.check,
                        color: Colors.white, size: 14)
                    : null,
              ),
            ),

            // Price badge
            if (card.marketPrice != null)
              Positioned(
                bottom: 42,
                left: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    card.formattedPrice,
                    style: const TextStyle(
                      color: AppColors.accentGreen,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Local pull entry before saving to Firestore.
class _PullEntry {
  final String cardName;
  final String? cardBlueprintId;
  final String? cardImageUrl;
  final String? cardExpansion;
  final String? rarity;
  final double? estimatedValue;

  const _PullEntry({
    required this.cardName,
    this.cardBlueprintId,
    this.cardImageUrl,
    this.cardExpansion,
    this.rarity,
    this.estimatedValue,
  });
}
