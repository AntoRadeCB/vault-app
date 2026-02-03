import 'dart:async';
import 'package:flutter/material.dart';
import '../models/card_blueprint.dart';
import '../models/product.dart';
import '../services/card_catalog_service.dart';
import '../theme/app_theme.dart';

/// Card name autocomplete field.
/// Uses a simple Column-based dropdown (no Overlay) for Flutter web compatibility.
class CardSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final void Function(CardBlueprint card)? onCardSelected;
  final ProductKind? productKind;

  const CardSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.validator,
    this.suffixIcon,
    this.onCardSelected,
    this.productKind,
  });

  @override
  State<CardSearchField> createState() => _CardSearchFieldState();
}

class _CardSearchFieldState extends State<CardSearchField> {
  final CardCatalogService _catalogService = CardCatalogService();
  final FocusNode _focusNode = FocusNode();
  List<CardBlueprint> _suggestions = [];
  List<Map<String, dynamic>> _expansionSuggestions = [];
  bool _focused = false;
  bool _showSuggestions = false;
  Timer? _debounce;
  bool _suppressSuggestions = false;

  bool get _isSealed =>
      widget.productKind != null &&
      widget.productKind != ProductKind.singleCard;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
    // Pre-load the cache
    _catalogService.getAllCards();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _focused = _focusNode.hasFocus;
      if (!_focusNode.hasFocus) {
        // Small delay so tap on suggestion can register
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted && !_focusNode.hasFocus) {
            setState(() => _showSuggestions = false);
          }
        });
      }
    });
  }

  void _onTextChanged() {
    if (_suppressSuggestions) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _search(widget.controller.text);
    });
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _expansionSuggestions = [];
          _showSuggestions = false;
        });
      }
      return;
    }

    try {
      if (_isSealed) {
        final results = await _catalogService.searchExpansions(query);
        if (!mounted) return;
        setState(() {
          _expansionSuggestions = results;
          _suggestions = [];
          _showSuggestions = results.isNotEmpty;
        });
      } else {
        final results = await _catalogService.searchCards(query);
        if (!mounted) return;
        setState(() {
          _suggestions = results;
          _expansionSuggestions = [];
          _showSuggestions = results.isNotEmpty;
        });
      }
    } catch (_) {
      // Search failed silently — user can retry
    }
  }

  void _selectCard(CardBlueprint card) {
    _suppressSuggestions = true;
    widget.controller.text = card.name;
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
      _expansionSuggestions = [];
    });
    _suppressSuggestions = false;
    _focusNode.unfocus();
    widget.onCardSelected?.call(card);
  }

  void _selectExpansion(Map<String, dynamic> expansion) {
    final id = expansion['id'] as int? ?? 0;
    final name = expansion['name'] as String? ?? 'Expansion';
    final kindLabel = _sealedKindLabel();
    final card = CardBlueprint(
      id: 'exp_$id',
      blueprintId: -id,
      name: '$name $kindLabel',
      expansionId: id,
      expansionName: name,
    );
    _selectCard(card);
  }

  String _sealedKindLabel() {
    switch (widget.productKind) {
      case ProductKind.boosterPack:
        return 'Busta';
      case ProductKind.boosterBox:
        return 'Box';
      case ProductKind.display:
        return 'Display';
      case ProductKind.bundle:
        return 'Bundle';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Text field
        Focus(
          onFocusChange: (f) => setState(() => _focused = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: AppColors.accentBlue.withValues(alpha: 0.15),
                        blurRadius: 16,
                      ),
                    ]
                  : [],
            ),
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              validator: widget.validator,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: widget.hintText,
                filled: true,
                fillColor: AppColors.surface,
                suffixIcon: widget.suffixIcon,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.accentBlue,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.accentRed,
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.accentRed,
                    width: 1.5,
                  ),
                ),
                errorStyle: const TextStyle(
                  color: AppColors.accentRed,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
        // Suggestions dropdown (inline, no overlay)
        if (_showSuggestions && (_suggestions.isNotEmpty || _expansionSuggestions.isNotEmpty))
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accentBlue.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _isSealed
                  ? ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _expansionSuggestions.length,
                      itemBuilder: (context, index) {
                        final exp = _expansionSuggestions[index];
                        return _ExpansionSuggestionTile(
                          expansion: exp,
                          kindLabel: _sealedKindLabel(),
                          onTap: () => _selectExpansion(exp),
                        );
                      },
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final card = _suggestions[index];
                        return _CardSuggestionTile(
                          card: card,
                          onTap: () => _selectCard(card),
                        );
                      },
                    ),
            ),
          ),
      ],
    );
  }
}

class _CardSuggestionTile extends StatelessWidget {
  final CardBlueprint card;
  final VoidCallback onTap;

  const _CardSuggestionTile({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ),
        child: Row(
          children: [
            // Card image thumbnail
            Container(
              width: 36,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: card.rarityColor.withValues(alpha: 0.4),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: card.imageUrl != null
                    ? Image.network(
                        card.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: card.rarityColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.style,
                            color: card.rarityColor,
                            size: 18,
                          ),
                        ),
                      )
                    : Container(
                        color: card.rarityColor.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.style,
                          color: card.rarityColor,
                          size: 18,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            // Card info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (card.expansionName != null) ...[
                        Flexible(
                          child: Text(
                            card.expansionName!,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (card.rarity != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: card.rarityColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            card.rarity!,
                            style: TextStyle(
                              color: card.rarityColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Price
            if (card.marketPrice != null)
              Text(
                card.formattedPrice,
                style: const TextStyle(
                  color: AppColors.accentGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExpansionSuggestionTile extends StatelessWidget {
  final Map<String, dynamic> expansion;
  final String kindLabel;
  final VoidCallback onTap;

  const _ExpansionSuggestionTile({
    required this.expansion,
    required this.kindLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = expansion['name'] as String? ?? 'Expansion';
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ),
        child: Row(
          children: [
            // Expansion icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.inventory_2,
                color: AppColors.accentPurple,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            // Expansion info
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Kind badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                kindLabel,
                style: const TextStyle(
                  color: AppColors.accentPurple,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
