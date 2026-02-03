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
  final _pullNameController = TextEditingController();
  final _pullValueController = TextEditingController();

  bool _isOpened = false;
  bool _opening = false;
  final List<_PullEntry> _pulls = [];

  @override
  void initState() {
    super.initState();
    _isOpened = widget.product.isOpened;
  }

  @override
  void dispose() {
    _pullNameController.dispose();
    _pullValueController.dispose();
    super.dispose();
  }

  Future<void> _markOpened() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      if (widget.product.id != null && !FirestoreService.demoMode) {
        await _fs.markProductOpened(widget.product.id!);
      }
      if (mounted) setState(() => _isOpened = true);
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
      if (mounted) setState(() => _opening = false);
    }
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
        rarity: card?.rarity,
        estimatedValue: value,
      ));
      _pullNameController.clear();
      _pullValueController.clear();
    });
  }

  void _removePull(int index) {
    setState(() => _pulls.removeAt(index));
  }

  Future<void> _finish() async {
    // Save all pulls to Firestore
    if (widget.product.id != null && _pulls.isNotEmpty && !FirestoreService.demoMode) {
      for (final pull in _pulls) {
        final cardPull = CardPull(
          parentProductId: widget.product.id!,
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
    widget.onDone?.call();
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
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
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
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              glowColor: _isOpened ? AppColors.accentGreen : AppColors.accentOrange,
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: (_isOpened ? AppColors.accentGreen : AppColors.accentOrange)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isOpened ? Icons.inventory_2 : Icons.lock,
                      color: _isOpened ? AppColors.accentGreen : AppColors.accentOrange,
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
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                            const SizedBox(width: 8),
                            Text(
                              _isOpened ? 'Aperto 📦' : 'Sigillato 🔒',
                              style: TextStyle(
                                color: _isOpened ? AppColors.accentGreen : AppColors.accentOrange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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
            ),
          ),
          const SizedBox(height: 24),

          // Open button (if not opened yet)
          if (!_isOpened)
            StaggeredFadeSlide(
              index: 2,
              child: ShimmerButton(
                baseGradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFE53935)],
                ),
                onTap: _opening ? null : _markOpened,
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
                        const Icon(Icons.lock_open, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        const Text(
                          'Apri! 🎉',
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
                          color: AppColors.accentGreen.withValues(alpha: 0.12),
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

            // Quick add pull
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
                                colors: [Color(0xFF764ba2), Color(0xFF667eea)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.style, color: Colors.white, size: 14),
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
                onTap: _finish,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Fatto',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
}

/// Local pull entry before saving to Firestore.
class _PullEntry {
  final String cardName;
  final String? cardBlueprintId;
  final String? cardImageUrl;
  final String? rarity;
  final double? estimatedValue;

  const _PullEntry({
    required this.cardName,
    this.cardBlueprintId,
    this.cardImageUrl,
    this.rarity,
    this.estimatedValue,
  });
}
