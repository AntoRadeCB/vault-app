import 'package:flutter/material.dart';
import '../models/card_blueprint.dart';
import '../services/card_catalog_service.dart';
import '../theme/app_theme.dart';

/// Full-screen bottom sheet to browse and pick a card visually.
/// Shows expansions → card grid with images. Much friendlier than
/// typing a card name manually.
class CardBrowserSheet extends StatefulWidget {
  const CardBrowserSheet({super.key});

  /// Show the sheet and return the selected [CardBlueprint] or null.
  static Future<CardBlueprint?> show(BuildContext context) {
    return showModalBottomSheet<CardBlueprint>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CardBrowserSheet(),
    );
  }

  @override
  State<CardBrowserSheet> createState() => _CardBrowserSheetState();
}

class _CardBrowserSheetState extends State<CardBrowserSheet> {
  final CardCatalogService _catalog = CardCatalogService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _expansions = [];
  List<CardBlueprint> _allCards = [];
  List<CardBlueprint> _displayedCards = [];
  int? _selectedExpansionId;
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _catalog.getExpansions(),
        _catalog.getAllCards(),
      ]);
      if (!mounted) return;
      setState(() {
        _expansions = results[0] as List<Map<String, dynamic>>;
        _allCards = results[1] as List<CardBlueprint>;
        _displayedCards = _allCards;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _filterCards() {
    final query = _searchQuery.toLowerCase();
    setState(() {
      _displayedCards = _allCards.where((card) {
        final matchesExpansion = _selectedExpansionId == null ||
            card.expansionId == _selectedExpansionId;
        final matchesSearch =
            query.isEmpty || card.name.toLowerCase().contains(query);
        return matchesExpansion && matchesSearch;
      }).toList();
    });

    // Scroll to top when filter changes
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  void _selectExpansion(int? expansionId) {
    _selectedExpansionId = expansionId;
    _filterCards();
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _filterCards();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ─── Handle + Header ───
          _buildHeader(),
          // ─── Search bar ───
          _buildSearchBar(),
          // ─── Expansion chips ───
          if (_expansions.isNotEmpty) _buildExpansionChips(),
          // ─── Card grid ───
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accentBlue))
                : _displayedCards.isEmpty
                    ? _buildEmptyState()
                    : _buildCardGrid(),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 12),
        // Drag handle
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.style,
                    color: AppColors.accentPurple, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catalogo Carte',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Cerca o sfoglia per espansione',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Cerca carta...',
          hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.6)),
          filled: true,
          fillColor: AppColors.surface,
          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.accentPurple, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildExpansionChips() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // "All" chip
          _ExpansionChip(
            label: 'Tutte',
            isSelected: _selectedExpansionId == null,
            onTap: () => _selectExpansion(null),
          ),
          const SizedBox(width: 8),
          ..._expansions.map((exp) {
            final id = exp['id'] as int?;
            final name = exp['name'] as String? ?? '?';
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ExpansionChip(
                label: name,
                isSelected: _selectedExpansionId == id,
                onTap: () => _selectExpansion(id),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCardGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        childAspectRatio: 0.58,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
      ),
      itemCount: _displayedCards.length,
      itemBuilder: (context, index) {
        final card = _displayedCards[index];
        return _CardGridTile(
          card: card,
          onTap: () => Navigator.pop(context, card),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'Nessuna carta trovata'
                : 'Catalogo vuoto',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _searchQuery.isNotEmpty
                ? 'Prova un termine diverso'
                : 'Aggiungi carte al catalogo per vederle qui',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Expansion filter chip ────────────────────────
class _ExpansionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ExpansionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentPurple.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.accentPurple.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.accentPurple : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─── Card grid tile ───────────────────────────────
class _CardGridTile extends StatelessWidget {
  final CardBlueprint card;
  final VoidCallback onTap;

  const _CardGridTile({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card image
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: card.rarityColor.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: card.rarityColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: card.imageUrl != null
                    ? Image.network(
                        card.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Card name
          Text(
            card.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Price + rarity
          const SizedBox(height: 2),
          Row(
            children: [
              if (card.marketPrice != null)
                Text(
                  card.formattedPrice,
                  style: const TextStyle(
                    color: AppColors.accentGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (card.marketPrice != null && card.rarity != null)
                const SizedBox(width: 4),
              if (card.rarity != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: card.rarityColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      card.rarity!,
                      style: TextStyle(
                        color: card.rarityColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: card.rarityColor.withValues(alpha: 0.08),
      child: Center(
        child: Icon(Icons.style, color: card.rarityColor.withValues(alpha: 0.4), size: 32),
      ),
    );
  }
}
