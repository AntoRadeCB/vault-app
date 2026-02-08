import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/ocr_scanner_dialog.dart';
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
  final _checklistSearchController = TextEditingController();

  // Local UI state — NOT tied to widget.product.isOpened
  bool _isOpened = false;
  bool _opening = false;
  bool _finishing = false;
  final List<_PullEntry> _pulls = [];
  int _quantityToOpen = 1;

  // Expansion checklist state
  List<CardBlueprint> _expansionCards = [];
  final Map<String, int> _checkedCardCounts = {};
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

      // Strategy 4: Infer expansion from product name (e.g., "Riftbound Booster Pack" → look for "Riftbound" expansion)
      if (expansionId == null) {
        final expansions = await _catalogService.getExpansions();
        final productNameLower = widget.product.name.toLowerCase();
        final brandLower = widget.product.brand.toLowerCase();
        for (final exp in expansions) {
          final eName = (exp['name'] as String? ?? '').toLowerCase();
          if (eName.isNotEmpty &&
              (productNameLower.contains(eName) || brandLower.contains(eName))) {
            expansionId = exp['id'] as int?;
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

  /// Tap → add one more copy
  void _incrementChecklistCard(CardBlueprint card) {
    setState(() {
      final current = _checkedCardCounts[card.id] ?? 0;
      _checkedCardCounts[card.id] = current + 1;

      // Find existing pull entry and increment, or create new
      final existing = _pulls.where((p) => p.cardBlueprintId == card.id).firstOrNull;
      if (existing != null) {
        existing.quantity = current + 1;
      } else {
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

  /// Long press → remove one copy (or remove entirely if count reaches 0)
  void _decrementChecklistCard(CardBlueprint card) {
    setState(() {
      final current = _checkedCardCounts[card.id] ?? 0;
      if (current <= 1) {
        _checkedCardCounts.remove(card.id);
        _pulls.removeWhere((p) => p.cardBlueprintId == card.id);
      } else {
        _checkedCardCounts[card.id] = current - 1;
        final existing = _pulls.where((p) => p.cardBlueprintId == card.id).firstOrNull;
        if (existing != null) existing.quantity = current - 1;
      }
    });
  }

  void _addPull({CardBlueprint? card}) {
    if (card == null) return;

    final value = card.marketPrice != null
        ? card.marketPrice!.cents / 100
        : null;

    setState(() {
      // If card already in pulls, increment quantity
      final existing = _pulls.where((p) => p.cardBlueprintId == card.id).firstOrNull;
      if (existing != null) {
        existing.quantity += 1;
      } else {
        _pulls.add(_PullEntry(
          cardName: card.name,
          cardBlueprintId: card.id,
          cardImageUrl: card.imageUrl,
          cardExpansion: card.expansionName,
          rarity: card.rarity,
          estimatedValue: value,
        ));
      }
      _checkedCardCounts[card.id] = (_checkedCardCounts[card.id] ?? 0) + 1;
    });
  }

  void _removePull(int index) {
    setState(() {
      final pull = _pulls[index];
      if (pull.cardBlueprintId != null) {
        _checkedCardCounts.remove(pull.cardBlueprintId);
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
          for (int i = 0; i < pull.quantity; i++) {
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
        }

        // 2. Add pulled cards — merge into existing product if same blueprintId
        // Fetch current products once to check for duplicates
        final currentProducts = await _fs.getProducts().first;
        final existingByBlueprint = <String, Product>{};
        for (final p in currentProducts) {
          if (p.kind == ProductKind.singleCard && p.cardBlueprintId != null) {
            existingByBlueprint[p.cardBlueprintId!] = p;
          }
        }

        for (final pull in _pulls) {
          final existing = pull.cardBlueprintId != null
              ? existingByBlueprint[pull.cardBlueprintId!]
              : null;
          if (existing != null && existing.id != null) {
            // Increment existing product quantity
            await _fs.updateProduct(existing.id!, {
              'quantity': existing.quantity + pull.quantity,
            });
          } else {
            // Create new product
            final newProduct = Product(
              name: pull.cardName,
              brand: widget.product.brand,
              quantity: pull.quantity.toDouble(),
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

  Future<void> _openScan({String mode = 'ocr'}) async {
    final numbers = await OcrScannerDialog.scan(
      context,
      expansionCards: _expansionCards,
      mode: mode,
    );
    if (!mounted || numbers.isEmpty) return;
    for (final num in numbers) {
      await _handleOcrResult(num);
    }
  }

  /// Match OCR collector number to catalog card and add as pull.
  Future<void> _handleOcrResult(String collectorNumber) async {
    CardBlueprint? match;

    // First try within current expansion (if loaded)
    if (_expansionCards.isNotEmpty) {
      match = _expansionCards
          .where(
              (c) => _matchesCollectorNumber(c.collectorNumber, collectorNumber))
          .firstOrNull;
    }

    // Fallback to all cards
    if (match == null) {
      try {
        final allCards = await _catalogService.getAllCards();
        match = allCards
            .where((c) =>
                _matchesCollectorNumber(c.collectorNumber, collectorNumber))
            .firstOrNull;
      } catch (_) {}
    }

    if (!mounted) return;

    if (match != null) {
      _addPull(card: match);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Aggiunta: ${match.name}'),
          backgroundColor: AppColors.accentGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Numero $collectorNumber non trovato nel catalogo'),
          backgroundColor: AppColors.accentOrange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Compare collector numbers with normalization (leading zeros, case).
  bool _matchesCollectorNumber(String? cardNum, String ocrNum) {
    if (cardNum == null) return false;
    // Exact match
    if (cardNum == ocrNum) return true;
    // Case-insensitive
    if (cardNum.toLowerCase() == ocrNum.toLowerCase()) return true;
    // Numeric comparison (strip leading zeros)
    final cardInt = int.tryParse(cardNum);
    final ocrInt = int.tryParse(ocrNum);
    if (cardInt != null && ocrInt != null) return cardInt == ocrInt;
    return false;
  }

  double get _totalPullValue {
    return _pulls.fold(0.0, (sum, p) => sum + (p.estimatedValue ?? 0) * p.quantity);
  }

  int get _totalPullCount {
    return _pulls.fold(0, (sum, p) => sum + p.quantity);
  }

  int get _checkedTotalCount =>
      _checkedCardCounts.values.fold(0, (a, b) => a + b);

  int get _checkedUniqueCount => _checkedCardCounts.length;

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
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 20),

          // Product info card (compact when opened)
          StaggeredFadeSlide(
            index: 1,
            child: _isOpened ? _buildCompactProductStrip() : _buildProductInfoCard(),
          ),
          if (!_isOpened) const SizedBox(height: 24),
          if (_isOpened) const SizedBox(height: 12),

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
              const SizedBox(height: 12),
            ],

            // Pulls list
            if (_pulls.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.list_alt, color: AppColors.textMuted, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '$_totalPullCount carte trovate',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                          width: 36,
                          height: 50,
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
                                              size: 18)),
                                )
                              : const Icon(Icons.style,
                                  color: AppColors.textMuted, size: 18),
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
                        if (pull.quantity > 1)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'x${pull.quantity}',
                              style: const TextStyle(
                                color: AppColors.accentBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (pull.estimatedValue != null)
                          Text(
                            '€${(pull.estimatedValue! * pull.quantity).toStringAsFixed(2)}',
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
                const SizedBox(height: 100), // Space for sticky button
              ],
            ],
          ),
        ),
      ),
      // Sticky finish button at bottom
      if (_isOpened)
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withValues(alpha: 0),
                AppColors.background,
                AppColors.background,
              ],
              stops: const [0, 0.3, 1],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGreen.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
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
                        const Icon(Icons.check_circle, color: Colors.white, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          _pulls.isEmpty 
                              ? 'Fatto' 
                              : 'Conferma $_totalPullCount ${_totalPullCount == 1 ? 'carta' : 'carte'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_pulls.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '€${_totalPullValue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
    );
  }

  /// Compact strip shown after opening — product info + pull value in one row
  Widget _buildCompactProductStrip() {
    final productImage = widget.product.displayImageUrl;
    final hasImage = productImage.isNotEmpty;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Product thumbnail
          Container(
            width: 32,
            height: hasImage ? 44 : 32,
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(hasImage ? 4 : 8),
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Image.network(
                      productImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.inventory_2,
                          color: AppColors.accentGreen,
                          size: 16),
                    ),
                  )
                : const Icon(Icons.inventory_2,
                    color: AppColors.accentGreen, size: 16),
          ),
          const SizedBox(width: 10),
          // Product name + kind
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.product.kindLabel,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Pull value summary
          if (_pulls.isNotEmpty) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '€${_totalPullValue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.accentGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$_totalPullCount carte',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ] else
            Text(
              widget.product.formattedPrice,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
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
    final totalCount = _expansionCards.length;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      glowColor: AppColors.accentPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + progress + action buttons — entire row is tappable
          GestureDetector(
            onTap: () => setState(() => _showChecklist = !_showChecklist),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(
                  _showChecklist ? Icons.folder_open : Icons.folder,
                  color: AppColors.accentPurple, size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: '🎴 Seleziona Carte ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: '$_checkedUniqueCount/$totalCount',
                          style: TextStyle(
                            color: _checkedUniqueCount > 0
                                ? AppColors.accentGreen
                                : AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_checkedTotalCount != _checkedUniqueCount)
                          TextSpan(
                            text: ' ($_checkedTotalCount copie)',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Scan button (Gemini OCR) — stops propagation
                GestureDetector(
                  onTap: () => _openScan(mode: 'ocr'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accentTeal, Color(0xFF00ACC1)],
                      ),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_camera,
                            color: Colors.white, size: 13),
                        SizedBox(width: 3),
                        Text('Scan',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Toggle arrow indicator
                AnimatedRotation(
                  turns: _showChecklist ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textMuted,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),

          // Progress bar
          if (_showChecklist) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: totalCount > 0 ? _checkedUniqueCount / totalCount : 0,
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
                        final count = _checkedCardCounts[card.id] ?? 0;
                        return _buildChecklistCard(card, count);
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  /// Find variant cards (same name, different id/collector number)
  List<CardBlueprint> _getVariants(CardBlueprint card) {
    return _expansionCards
        .where((c) => c.name == card.name && c.id != card.id)
        .toList();
  }

  /// Swap a checked card with one of its variants
  void _swapCardVariant(CardBlueprint oldCard, CardBlueprint newCard) {
    setState(() {
      final count = _checkedCardCounts[oldCard.id] ?? 0;
      if (count <= 0) return;

      // Remove old card from checklist counts
      _checkedCardCounts.remove(oldCard.id);
      // Add new card with same count
      _checkedCardCounts[newCard.id] = (_checkedCardCounts[newCard.id] ?? 0) + count;

      // Update pulls
      final pullIdx = _pulls.indexWhere((p) => p.cardBlueprintId == oldCard.id);
      if (pullIdx >= 0) {
        final existingNew = _pulls.indexWhere((p) => p.cardBlueprintId == newCard.id);
        if (existingNew >= 0) {
          // New card already in pulls — merge quantities
          _pulls[existingNew].quantity += _pulls[pullIdx].quantity;
          _pulls.removeAt(pullIdx);
        } else {
          // Replace pull entry
          _pulls[pullIdx] = _PullEntry(
            cardName: newCard.name,
            cardBlueprintId: newCard.id,
            cardImageUrl: newCard.imageUrl,
            cardExpansion: newCard.expansionName,
            rarity: newCard.rarity,
            estimatedValue: newCard.marketPrice != null
                ? newCard.marketPrice!.cents / 100
                : null,
            quantity: count,
          );
        }
      }
    });
  }

  /// Show bottom sheet to pick a variant
  void _showVariantPicker(CardBlueprint card) {
    final variants = _getVariants(card);
    if (variants.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.5,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Varianti di ${card.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Current card
                  _buildVariantTile(card, isCurrent: true, onTap: () => Navigator.pop(ctx)),
                  const Divider(color: Colors.white12, height: 1),
                  // Other variants
                  ...variants.map((v) => _buildVariantTile(v, isCurrent: false, onTap: () {
                    Navigator.pop(ctx);
                    _swapCardVariant(card, v);
                  })),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantTile(CardBlueprint card, {required bool isCurrent, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 40,
          height: 56,
          child: card.imageUrl != null
              ? Image.network(card.imageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: card.rarityColor.withValues(alpha: 0.15),
                    child: Icon(Icons.style, color: card.rarityColor, size: 18),
                  ))
              : Container(
                  color: card.rarityColor.withValues(alpha: 0.15),
                  child: Icon(Icons.style, color: card.rarityColor, size: 18),
                ),
        ),
      ),
      title: Text(
        '#${card.collectorNumber ?? '?'} — ${card.name}',
        style: TextStyle(
          color: isCurrent ? AppColors.accentGreen : Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        [
          if (card.rarity != null) card.rarity!,
          if (card.version != null && card.version!.isNotEmpty) card.version!,
        ].join(' · '),
        style: TextStyle(
          color: isCurrent
              ? AppColors.accentGreen.withValues(alpha: 0.7)
              : AppColors.textMuted,
          fontSize: 11,
        ),
      ),
      trailing: isCurrent
          ? const Icon(Icons.check_circle, color: AppColors.accentGreen, size: 20)
          : Icon(Icons.swap_horiz, color: Colors.white.withValues(alpha: 0.4), size: 20),
    );
  }

  Widget _buildChecklistCard(CardBlueprint card, int count) {
    final isChecked = count > 0;
    final hasVariants = isChecked && _getVariants(card).isNotEmpty;
    return GestureDetector(
      onTap: () => _incrementChecklistCard(card),
      onLongPress: count > 0 ? () => _decrementChecklistCard(card) : null,
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

            // Count badge overlay
            Positioned(
              top: 4,
              right: 4,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: count > 1 ? 26 : 22,
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
                    ? Center(
                        child: count > 1
                            ? Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : const Icon(Icons.check,
                                color: Colors.white, size: 14),
                      )
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

            // Swap variant badge (top-left, only when checked & has variants)
            if (hasVariants)
              Positioned(
                top: 4,
                left: 4,
                child: GestureDetector(
                  onTap: () => _showVariantPicker(card),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(Icons.swap_horiz,
                        color: Colors.white, size: 14),
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
  int quantity;

  _PullEntry({
    required this.cardName,
    this.cardBlueprintId,
    this.cardImageUrl,
    this.cardExpansion,
    this.rarity,
    this.estimatedValue,
    this.quantity = 1,
  });
}
