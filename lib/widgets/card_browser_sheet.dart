import 'package:flutter/material.dart';
import '../models/card_blueprint.dart';
import '../models/product.dart';
import '../services/card_catalog_service.dart';
import '../theme/app_theme.dart';

/// Full-screen bottom sheet to browse and pick a card visually.
/// Structure: Game tabs → Expansion filter → Card grid.
class CardBrowserSheet extends StatefulWidget {
  /// Optional: filter by tracked games (empty = show all)
  final List<String> trackedGames;

  /// Product kind — determines whether to show cards or expansions
  final ProductKind productKind;

  const CardBrowserSheet({
    super.key,
    this.trackedGames = const [],
    this.productKind = ProductKind.singleCard,
  });

  static Future<CardBlueprint?> show(
    BuildContext context, {
    List<String> trackedGames = const [],
    ProductKind productKind = ProductKind.singleCard,
  }) {
    return showModalBottomSheet<CardBlueprint>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CardBrowserSheet(
        trackedGames: trackedGames,
        productKind: productKind,
      ),
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

  // Expansion mode state (for sealed products)
  List<Map<String, dynamic>> _displayedExpansions = [];
  final Map<int, String?> _expansionImages = {};
  final Map<int, int> _expansionCardCounts = {};

  // Game tabs — discovered from data, with fallback
  List<_GameInfo> _games = [];
  String? _selectedGame;
  int? _selectedExpansionId;
  bool _loading = true;
  String _searchQuery = '';

  bool get _isSealed => widget.productKind != ProductKind.singleCard;

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

      _expansions = results[0] as List<Map<String, dynamic>>;
      _allCards = results[1] as List<CardBlueprint>;

      // Discover games from card data, filtered by tracked games
      final tracked = widget.trackedGames;
      final gameSet = <String>{};
      for (final c in _allCards) {
        final g = c.game ?? 'riftbound';
        if (tracked.isEmpty || tracked.contains(g)) {
          gameSet.add(g);
        }
      }

      // Filter cards to only tracked games
      if (tracked.isNotEmpty) {
        _allCards = _allCards.where((c) {
          final g = c.game ?? 'riftbound';
          return tracked.contains(g);
        }).toList();
      }

      _games = gameSet.map((g) => _GameInfo.fromId(g)).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      // Default to first game
      _selectedGame = _games.isNotEmpty ? _games.first.id : null;

      // Sort expansions: highest id first (newest)
      _expansions.sort((a, b) => (b['id'] as int? ?? 0).compareTo(a['id'] as int? ?? 0));

      // Pre-compute expansion card counts
      for (final c in _allCards) {
        if (c.expansionId != null) {
          _expansionCardCounts[c.expansionId!] =
              (_expansionCardCounts[c.expansionId!] ?? 0) + 1;
        }
      }

      setState(() => _loading = false);

      if (_isSealed) {
        _filterExpansions();
        _loadExpansionImages();
      } else {
        _filterCards();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _filterCards() {
    final query = _searchQuery.toLowerCase();
    final game = _selectedGame;

    final filtered = _allCards.where((card) {
      final cardGame = card.game ?? 'riftbound';
      // Game filter (skip if searching across all)
      if (query.isEmpty && game != null && cardGame != game) {
        return false;
      }
      // Expansion filter
      if (_selectedExpansionId != null &&
          card.expansionId != _selectedExpansionId) {
        return false;
      }
      // Search
      if (query.isNotEmpty && !card.name.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();

    // Sort: by expansion (newest first), then by collector number
    filtered.sort((a, b) {
      final expCmp = (b.expansionId ?? 0).compareTo(a.expansionId ?? 0);
      if (expCmp != 0) return expCmp;
      final aNum = int.tryParse(a.collectorNumber ?? '') ?? 9999;
      final bNum = int.tryParse(b.collectorNumber ?? '') ?? 9999;
      return aNum.compareTo(bNum);
    });

    // Push cards without images to the end
    final withImg = filtered.where((c) => c.imageUrl != null).toList();
    final noImg = filtered.where((c) => c.imageUrl == null).toList();

    setState(() {
      _displayedCards = [...withImg, ...noImg];
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  void _selectGame(String gameId) {
    _selectedGame = gameId;
    _selectedExpansionId = null; // Reset expansion filter
    if (_isSealed) {
      _filterExpansions();
    } else {
      _filterCards();
    }
  }

  void _selectExpansion(int? expansionId) {
    _selectedExpansionId = expansionId;
    _filterCards();
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    if (_isSealed) {
      _filterExpansions();
    } else {
      _filterCards();
    }
  }

  void _filterExpansions() {
    final query = _searchQuery.toLowerCase();
    final game = _selectedGame;

    // Get expansion IDs for the selected game
    final gameExpIds = <int>{};
    if (game != null) {
      for (final c in _allCards) {
        if ((c.game ?? 'riftbound') == game && c.expansionId != null) {
          gameExpIds.add(c.expansionId!);
        }
      }
    }

    final filtered = _expansions.where((exp) {
      final id = exp['id'] as int?;
      // Game filter
      if (game != null && id != null && !gameExpIds.contains(id)) return false;
      // Search filter
      if (query.isNotEmpty) {
        final name = (exp['name'] as String? ?? '').toLowerCase();
        if (!name.contains(query)) return false;
      }
      return true;
    }).toList();

    // Sort newest first
    filtered.sort((a, b) => (b['id'] as int? ?? 0).compareTo(a['id'] as int? ?? 0));

    setState(() => _displayedExpansions = filtered);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  Future<void> _loadExpansionImages() async {
    for (final exp in _expansions) {
      final id = exp['id'] as int?;
      if (id != null && !_expansionImages.containsKey(id)) {
        final img = await _catalog.getExpansionImage(id);
        if (mounted) {
          setState(() => _expansionImages[id] = img);
        }
      }
    }
  }

  String _kindLabel(ProductKind kind) {
    switch (kind) {
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

  /// Expansions filtered for the currently selected game
  List<Map<String, dynamic>> get _filteredExpansions {
    if (_selectedGame == null) return _expansions;
    final gameExpIds = <int>{};
    for (final c in _allCards) {
      if ((c.game ?? 'riftbound') == _selectedGame && c.expansionId != null) {
        gameExpIds.add(c.expansionId!);
      }
    }
    return _expansions
        .where((e) => gameExpIds.contains(e['id'] as int?))
        .toList();
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
          _buildHeader(),
          _buildSearchBar(),
          // Game tabs (only if >1 game)
          if (_games.length > 1) _buildGameTabs(),
          // Expansion chips (only for card mode, not sealed)
          if (!_isSealed && _filteredExpansions.isNotEmpty && _searchQuery.isEmpty)
            _buildExpansionChips(),
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _isSealed
                    ? '${_displayedExpansions.length} espansioni'
                    : '${_displayedCards.length} carte',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.accentBlue))
                : _isSealed
                    ? (_displayedExpansions.isEmpty
                        ? _buildEmptyState()
                        : _buildExpansionGrid())
                    : (_displayedCards.isEmpty
                        ? _buildEmptyState()
                        : _buildCardGrid()),
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
                child: Icon(
                  _isSealed ? Icons.inventory_2 : Icons.style,
                  color: AppColors.accentPurple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSealed ? 'Catalogo Espansioni' : 'Catalogo Carte',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isSealed
                          ? 'Sfoglia espansioni per prodotti sigillati'
                          : 'Sfoglia per gioco ed espansione',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 13),
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
                  child: const Icon(Icons.close,
                      color: AppColors.textMuted, size: 20),
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
          hintText: _isSealed ? 'Cerca espansione...' : 'Cerca carta...',
          hintStyle:
              TextStyle(color: AppColors.textMuted.withValues(alpha: 0.6)),
          filled: true,
          fillColor: AppColors.surface,
          prefixIcon:
              const Icon(Icons.search, color: AppColors.textMuted, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear,
                      color: AppColors.textMuted, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.accentPurple, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildGameTabs() {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: _games.map((game) {
          final isSelected = _selectedGame == game.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _selectGame(game.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? game.color.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? game.color.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(game.icon, size: 16, color: isSelected ? game.color : AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      game.label,
                      style: TextStyle(
                        color: isSelected ? game.color : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpansionChips() {
    final exps = _filteredExpansions;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _ExpansionChip(
              label: 'Tutte',
              isSelected: _selectedExpansionId == null,
              onTap: () => _selectExpansion(null),
            ),
            const SizedBox(width: 8),
            ...exps.map((exp) {
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
      ),
    );
  }

  Widget _buildCardGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                ? (_isSealed ? 'Nessuna espansione trovata' : 'Nessuna carta trovata')
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

  Widget _buildExpansionGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _displayedExpansions.length,
      itemBuilder: (context, index) {
        final exp = _displayedExpansions[index];
        final id = exp['id'] as int? ?? 0;
        final cardCount = _expansionCardCounts[id] ?? 0;
        return _ExpansionGridTile(
          expansion: exp,
          imageUrl: _expansionImages[id],
          cardCount: cardCount,
          kindLabel: _kindLabel(widget.productKind),
          onTap: () {
            final card = CardBlueprint(
              id: 'exp_$id',
              blueprintId: -id,
              name: '${exp['name'] ?? 'Expansion'} ${_kindLabel(widget.productKind)}',
              game: _selectedGame,
              expansionId: id,
              expansionName: exp['name'] as String?,
            );
            Navigator.pop(context, card);
          },
        );
      },
    );
  }
}

// ─── Game info ────────────────────────────────────
class _GameInfo {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final int sortOrder;

  const _GameInfo({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.sortOrder,
  });

  factory _GameInfo.fromId(String id) {
    switch (id.toLowerCase()) {
      case 'riftbound':
        return const _GameInfo(
          id: 'riftbound',
          label: 'Riftbound',
          icon: Icons.auto_awesome,
          color: AppColors.accentPurple,
          sortOrder: 0,
        );
      case 'pokemon':
        return _GameInfo(
          id: 'pokemon',
          label: 'Pokémon TCG',
          icon: Icons.catching_pokemon,
          color: const Color(0xFFFFCB05),
          sortOrder: 1,
        );
      case 'mtg':
        return const _GameInfo(
          id: 'mtg',
          label: 'Magic: The Gathering',
          icon: Icons.shield,
          color: Color(0xFFE47B30),
          sortOrder: 2,
        );
      case 'yugioh':
        return const _GameInfo(
          id: 'yugioh',
          label: 'Yu-Gi-Oh!',
          icon: Icons.star,
          color: Color(0xFF8B4513),
          sortOrder: 3,
        );
      case 'onepiece':
        return const _GameInfo(
          id: 'onepiece',
          label: 'One Piece',
          icon: Icons.sailing,
          color: Color(0xFFE74C3C),
          sortOrder: 4,
        );
      default:
        return _GameInfo(
          id: id,
          label: id[0].toUpperCase() + id.substring(1),
          icon: Icons.style,
          color: AppColors.accentBlue,
          sortOrder: 99,
        );
    }
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
            color: isSelected
                ? AppColors.accentPurple
                : AppColors.textSecondary,
            fontSize: 12,
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
          // Collector number + name
          Text(
            card.collectorNumber != null
                ? '#${card.collectorNumber} ${card.name}'
                : card.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Price + rarity
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported_outlined,
                color: card.rarityColor.withValues(alpha: 0.3), size: 28),
            const SizedBox(height: 4),
            Text(
              'No img',
              style: TextStyle(
                color: card.rarityColor.withValues(alpha: 0.4),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Expansion grid tile (for sealed products) ───
class _ExpansionGridTile extends StatelessWidget {
  final Map<String, dynamic> expansion;
  final String? imageUrl;
  final int cardCount;
  final String kindLabel;
  final VoidCallback onTap;

  const _ExpansionGridTile({
    required this.expansion,
    required this.imageUrl,
    required this.cardCount,
    required this.kindLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = expansion['name'] as String? ?? 'Expansion';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.accentPurple.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentPurple.withValues(alpha: 0.08),
              blurRadius: 12,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Representative card image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _expPlaceholder(),
                      )
                    : _expPlaceholder(),
              ),
            ),
            // Info area
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Kind badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          kindLabel,
                          style: const TextStyle(
                            color: AppColors.accentPurple,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Card count
                      Text(
                        '$cardCount carte',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _expPlaceholder() {
    return Container(
      color: AppColors.accentPurple.withValues(alpha: 0.06),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2,
                color: AppColors.accentPurple.withValues(alpha: 0.3), size: 32),
            const SizedBox(height: 4),
            Text(
              kindLabel,
              style: TextStyle(
                color: AppColors.accentPurple.withValues(alpha: 0.4),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
