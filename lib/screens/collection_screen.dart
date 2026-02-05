import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/product.dart';
import '../models/card_blueprint.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../services/card_catalog_service.dart';

/// Binder-based collection view.
///
/// Flow: Game selection → Expansion binders → Card grid
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

enum _CollectionView { games, expansions, binderDetail }

class _CollectionScreenState extends State<CollectionScreen> {
  _CollectionView _currentView = _CollectionView.games;
  String? _selectedGame; // brand name
  String? _selectedExpansionName;
  int? _selectedExpansionId;

  final FirestoreService _fs = FirestoreService();
  final CardCatalogService _catalogService = CardCatalogService();

  List<CardBlueprint> _catalogCards = [];
  bool _catalogLoaded = false;

  // Precomputed catalog structures
  // expansionName → list of singleCard blueprints
  Map<String, List<CardBlueprint>> _expansionCatalog = {};
  // normalised game name → set of expansion names
  Map<String, Set<String>> _gameExpansionMap = {};

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      _catalogCards = await _catalogService.getAllCards();
      _buildCatalogMaps();
    } catch (_) {}
    if (mounted) setState(() => _catalogLoaded = true);
  }

  void _buildCatalogMaps() {
    _expansionCatalog.clear();
    _gameExpansionMap.clear();

    for (final card in _catalogCards) {
      // Only count single cards (not sealed products in catalog)
      if (card.kind != null && card.kind != 'singleCard') continue;
      final expName = card.expansionName ?? 'Unknown';
      _expansionCatalog.putIfAbsent(expName, () => []).add(card);

      if (card.game != null) {
        final normGame = _normalizeGameName(card.game!);
        _gameExpansionMap.putIfAbsent(normGame, () => {}).add(expName);
      }
    }
  }

  // ─── Navigation ─────────────────────────────────

  void _selectGame(String game) {
    setState(() {
      _selectedGame = game;
      _currentView = _CollectionView.expansions;
    });
  }

  void _selectExpansion(String name, int? expansionId) {
    setState(() {
      _selectedExpansionName = name;
      _selectedExpansionId = expansionId;
      _currentView = _CollectionView.binderDetail;
    });
  }

  void _goBack() {
    setState(() {
      switch (_currentView) {
        case _CollectionView.binderDetail:
          _currentView = _CollectionView.expansions;
          _selectedExpansionName = null;
          _selectedExpansionId = null;
        case _CollectionView.expansions:
          _currentView = _CollectionView.games;
          _selectedGame = null;
        case _CollectionView.games:
          break;
      }
    });
  }

  // ─── Helpers ────────────────────────────────────

  static String _normalizeGameName(String name) {
    return name
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('!', '')
        .replaceAll('-', ' ')
        .trim();
  }

  bool _gamesMatch(String catalogGame, String userBrand) {
    final a = _normalizeGameName(catalogGame);
    final b = _normalizeGameName(userBrand);
    return a == b || a.contains(b) || b.contains(a);
  }

  Color _gameColor(String brand) {
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
      case 'DIGIMON':
        return const Color(0xFF2196F3);
      case 'DRAGON BALL':
        return const Color(0xFFFF9800);
      default:
        return AppColors.accentBlue;
    }
  }

  IconData _gameIcon(String brand) {
    switch (brand.toUpperCase()) {
      case 'POKÉMON':
      case 'POKEMON':
        return Icons.catching_pokemon;
      case 'MTG':
      case 'MAGIC':
        return Icons.auto_awesome;
      case 'RIFTBOUND':
        return Icons.bolt;
      case 'YU-GI-OH!':
      case 'YUGIOH':
        return Icons.flash_on;
      case 'ONE PIECE':
        return Icons.sailing;
      default:
        return Icons.style;
    }
  }

  Color _rarityColor(String? rarity) {
    switch (rarity?.toLowerCase()) {
      case 'common':
        return const Color(0xFF9E9E9E);
      case 'uncommon':
        return const Color(0xFF4CAF50);
      case 'rare':
        return const Color(0xFF2196F3);
      case 'epic':
        return const Color(0xFFAB47BC);
      case 'alternate art':
        return const Color(0xFFFFD700);
      case 'promo':
        return const Color(0xFFFF6B35);
      case 'token':
        return const Color(0xFF78909C);
      case 'showcase':
        return const Color(0xFFE91E63);
      case 'overnumbered':
        return const Color(0xFFFF4081);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  /// Get catalog cards matching a user brand + expansion name.
  List<CardBlueprint> _getCatalogCardsForExpansion(String expansionName) {
    return _expansionCatalog[expansionName] ?? [];
  }

  /// Find the expansionId for a given expansion name from catalog.
  int? _findExpansionId(String expansionName) {
    final cards = _expansionCatalog[expansionName];
    if (cards == null || cards.isEmpty) return null;
    return cards.first.expansionId;
  }

  /// Get expansion code for display.
  String? _findExpansionCode(String expansionName) {
    final cards = _expansionCatalog[expansionName];
    if (cards == null || cards.isEmpty) return null;
    return cards.first.expansionCode;
  }

  // ─── Build ──────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: _fs.getProducts(),
      builder: (context, snapshot) {
        final allProducts = snapshot.data ?? [];
        final singleCards = allProducts
            .where((p) => p.kind == ProductKind.singleCard)
            .toList();

        if (snapshot.connectionState == ConnectionState.waiting &&
            !_catalogLoaded) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accentBlue),
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.03, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey('${_currentView}_$_selectedGame\_$_selectedExpansionName'),
            child: _buildCurrentView(singleCards),
          ),
        );
      },
    );
  }

  Widget _buildCurrentView(List<Product> singleCards) {
    switch (_currentView) {
      case _CollectionView.games:
        return _buildGameSelection(singleCards);
      case _CollectionView.expansions:
        return _buildExpansionBinders(singleCards);
      case _CollectionView.binderDetail:
        return _buildBinderDetail(singleCards);
    }
  }

  // ═══════════════════════════════════════════════════
  //  GAME SELECTION VIEW
  // ═══════════════════════════════════════════════════

  Widget _buildGameSelection(List<Product> singleCards) {
    // Group by brand (game)
    final gameMap = <String, List<Product>>{};
    for (final card in singleCards) {
      gameMap.putIfAbsent(card.brand, () => []).add(card);
    }

    // Also include games that exist in catalog but user has no cards for
    for (final entry in _gameExpansionMap.entries) {
      final normGame = entry.key;
      final alreadyExists = gameMap.keys.any(
        (brand) => _normalizeGameName(brand) == normGame,
      );
      if (!alreadyExists) {
        // Find a display name from catalog
        final firstCard = _catalogCards.firstWhere(
          (c) => c.game != null && _normalizeGameName(c.game!) == normGame,
        );
        gameMap[firstCard.game!.toUpperCase()] = [];
      }
    }

    final gameEntries = gameMap.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: StaggeredFadeSlide(
            index: 0,
            child: Row(
              children: [
                const Text(
                  'Collezione',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accentPurple.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '${singleCards.length} carte',
                    style: const TextStyle(
                      color: AppColors.accentPurple,
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
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: StaggeredFadeSlide(
            index: 1,
            child: Text(
              'Seleziona un gioco per sfogliare i raccoglitori',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: gameEntries.isEmpty
              ? _buildEmptyCollection()
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: gameEntries.length,
                  itemBuilder: (context, index) {
                    final entry = gameEntries[index];
                    return StaggeredFadeSlide(
                      index: index + 2,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildGameTile(entry.key, entry.value),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildGameTile(String brand, List<Product> cards) {
    final color = _gameColor(brand);
    final icon = _gameIcon(brand);

    // Compute stats
    final uniqueCards =
        cards.map((c) => c.cardBlueprintId ?? c.name).toSet().length;
    final totalCopies =
        cards.fold<int>(0, (sum, c) => sum + c.quantity.toInt());

    // Total value from market prices
    double totalValue = 0;
    for (final card in cards) {
      final price = card.marketPrice ?? card.price;
      totalValue += price * card.quantity;
    }

    // Total cards available in catalog for this game
    final normGame = _normalizeGameName(brand);
    int catalogTotal = 0;
    for (final entry in _expansionCatalog.entries) {
      final sampleCard = entry.value.firstOrNull;
      if (sampleCard?.game != null &&
          _normalizeGameName(sampleCard!.game!) == normGame) {
        catalogTotal += entry.value.length;
      }
    }

    final progress = catalogTotal > 0 ? uniqueCards / catalogTotal : 0.0;

    return ScaleOnPress(
      onTap: () => _selectGame(brand),
      child: HoverLiftCard(
        liftAmount: 4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.12),
                color.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withValues(alpha: 0.3),
                                color.withValues(alpha: 0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.2),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Icon(icon, color: color, size: 26),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                brand,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$uniqueCards carte uniche · $totalCopies copie',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '€${totalValue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'valore',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (catalogTotal > 0) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.06),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$uniqueCards / $catalogTotal',
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCollection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.collections_bookmark_outlined,
            color: AppColors.textMuted.withValues(alpha: 0.4),
            size: 72,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nessuna carta in collezione',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Apri buste o aggiungi carte singole\nper iniziare la tua collezione',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  EXPANSION BINDERS VIEW
  // ═══════════════════════════════════════════════════

  Widget _buildExpansionBinders(List<Product> singleCards) {
    final game = _selectedGame!;
    final color = _gameColor(game);

    // Filter cards for this game
    final gameCards =
        singleCards.where((c) => c.brand == game).toList();

    // Group by expansion
    final expansionMap = <String, List<Product>>{};
    for (final card in gameCards) {
      final exp = card.cardExpansion ?? 'Sconosciuta';
      expansionMap.putIfAbsent(exp, () => []).add(card);
    }

    // Also include catalog expansions for this game that user hasn't collected yet
    final normGame = _normalizeGameName(game);
    for (final entry in _expansionCatalog.entries) {
      final sampleCard = entry.value.firstOrNull;
      if (sampleCard?.game != null &&
          _normalizeGameName(sampleCard!.game!) == normGame) {
        expansionMap.putIfAbsent(entry.key, () => []);
      }
    }

    // Sort: expansions with most owned cards first
    final expansionEntries = expansionMap.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with back
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: StaggeredFadeSlide(
            index: 0,
            child: Row(
              children: [
                ScaleOnPress(
                  onTap: _goBack,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_gameIcon(game), color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game,
                        style: TextStyle(
                          color: color,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        '${expansionEntries.length} espansioni',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: expansionEntries.isEmpty
              ? Center(
                  child: Text(
                    'Nessuna espansione disponibile',
                    style: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: expansionEntries.length,
                  itemBuilder: (context, index) {
                    final entry = expansionEntries[index];
                    return StaggeredFadeSlide(
                      index: index + 1,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildBinderCard(
                          game,
                          entry.key,
                          entry.value,
                          color,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBinderCard(
    String game,
    String expansionName,
    List<Product> ownedCards,
    Color gameColor,
  ) {
    final catalogCards = _getCatalogCardsForExpansion(expansionName);
    final totalInExpansion = catalogCards.length;
    final expansionCode = _findExpansionCode(expansionName);
    final expansionId = _findExpansionId(expansionName);

    // Unique cards owned (by blueprintId)
    final ownedBlueprintIds = <String>{};
    for (final card in ownedCards) {
      if (card.cardBlueprintId != null) {
        ownedBlueprintIds.add(card.cardBlueprintId!);
      }
    }
    final uniqueOwned = ownedBlueprintIds.length;

    // Binder value: sum market prices of owned cards from catalog
    double binderValue = 0;
    for (final card in ownedCards) {
      final price = card.marketPrice ?? card.price;
      binderValue += price * card.quantity;
    }

    final progress =
        totalInExpansion > 0 ? uniqueOwned / totalInExpansion : 0.0;
    final isComplete = totalInExpansion > 0 && uniqueOwned >= totalInExpansion;

    // Accent color: slightly shift the game color for variety
    final accentColor = isComplete ? AppColors.accentGreen : gameColor;

    return ScaleOnPress(
      onTap: () => _selectExpansion(expansionName, expansionId),
      child: HoverLiftCard(
        liftAmount: 3,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                accentColor.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.08),
                blurRadius: 16,
                spreadRadius: -2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Binder icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColor.withValues(alpha: 0.25),
                                accentColor.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isComplete
                                ? Icons.emoji_events
                                : Icons.menu_book,
                            color: accentColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expansionName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (expansionCode != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.06),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        expansionCode,
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    totalInExpansion > 0
                                        ? '$uniqueOwned / $totalInExpansion carte'
                                        : '${ownedCards.length} carte',
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
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
                              '€${binderValue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isComplete)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGreen
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '✨ COMPLETA',
                                  style: TextStyle(
                                    color: AppColors.accentGreen,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    if (totalInExpansion > 0) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.06),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(accentColor),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  BINDER DETAIL VIEW (Card Grid)
  // ═══════════════════════════════════════════════════

  Widget _buildBinderDetail(List<Product> singleCards) {
    final game = _selectedGame!;
    final expansion = _selectedExpansionName!;
    final color = _gameColor(game);

    // Get all catalog cards for this expansion
    final catalogCards = _getCatalogCardsForExpansion(expansion);

    // Sort by collector number
    final sortedCatalog = List<CardBlueprint>.from(catalogCards)
      ..sort((a, b) {
        final aNum = int.tryParse(a.collectorNumber ?? '') ?? 9999;
        final bNum = int.tryParse(b.collectorNumber ?? '') ?? 9999;
        return aNum.compareTo(bNum);
      });

    // Build ownership map: blueprintId → list of owned products
    final gameCards = singleCards
        .where((c) => c.brand == game && c.cardExpansion == expansion)
        .toList();

    final ownershipMap = <String, List<Product>>{};
    for (final card in gameCards) {
      if (card.cardBlueprintId != null) {
        ownershipMap
            .putIfAbsent(card.cardBlueprintId!, () => [])
            .add(card);
      }
    }

    // Rarity breakdown
    final rarityOwned = <String, int>{};
    final rarityTotal = <String, int>{};
    for (final card in sortedCatalog) {
      final rarity = card.rarity ?? 'Unknown';
      rarityTotal[rarity] = (rarityTotal[rarity] ?? 0) + 1;
      if (ownershipMap.containsKey(card.id)) {
        rarityOwned[rarity] = (rarityOwned[rarity] ?? 0) + 1;
      }
    }

    // Value
    double totalValue = 0;
    int totalOwned = 0;
    for (final entry in ownershipMap.entries) {
      for (final product in entry.value) {
        totalValue += (product.marketPrice ?? product.price) * product.quantity;
        totalOwned += product.quantity.toInt();
      }
    }

    final uniqueOwned = ownershipMap.length;
    final expansionCode = _findExpansionCode(expansion);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: StaggeredFadeSlide(
            index: 0,
            child: Row(
              children: [
                ScaleOnPress(
                  onTap: _goBack,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expansion,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          if (expansionCode != null) ...[
                            Text(
                              expansionCode,
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(
                              ' · ',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                          Text(
                            '$uniqueOwned / ${sortedCatalog.length} carte',
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
                      '€${totalValue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$totalOwned copie',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: StaggeredFadeSlide(
            index: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: sortedCatalog.isNotEmpty
                    ? (uniqueOwned / sortedCatalog.length).clamp(0.0, 1.0)
                    : 0,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Rarity breakdown chips
        if (rarityTotal.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: StaggeredFadeSlide(
              index: 2,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: rarityTotal.entries.map((entry) {
                    final rarity = entry.key;
                    final total = entry.value;
                    final owned = rarityOwned[rarity] ?? 0;
                    final rColor = _rarityColor(rarity);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: rColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: rColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: rColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$rarity $owned/$total',
                              style: TextStyle(
                                color: rColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),

        // Card grid
        Expanded(
          child: sortedCatalog.isEmpty
              ? _buildEmptyBinder(gameCards)
              : GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.55,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: sortedCatalog.length,
                  itemBuilder: (context, index) {
                    final card = sortedCatalog[index];
                    final owned = ownershipMap[card.id];
                    final isOwned = owned != null && owned.isNotEmpty;
                    final count = isOwned
                        ? owned.fold<int>(
                            0, (sum, p) => sum + p.quantity.toInt())
                        : 0;
                    return StaggeredFadeSlide(
                      index: (index ~/ 3) + 3,
                      child: _buildCardSlot(card, isOwned, count, color),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Empty binder: show owned cards that aren't in catalog
  Widget _buildEmptyBinder(List<Product> gameCards) {
    if (gameCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book,
              color: AppColors.textMuted.withValues(alpha: 0.4),
              size: 64,
            ),
            const SizedBox(height: 12),
            const Text(
              'Raccoglitore vuoto',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Questa espansione non è ancora nel catalogo',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    // Show owned cards in a simple list
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: gameCards.length,
      itemBuilder: (context, index) {
        final card = gameCards[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.all(10),
            glowColor: _rarityColor(card.cardRarity),
            child: Row(
              children: [
                if (card.cardImageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 36,
                      height: 50,
                      child: Image.network(
                        card.cardImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.surface,
                          child: const Icon(Icons.style,
                              color: AppColors.textMuted, size: 18),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    card.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'x${card.quantity.toInt()}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardSlot(
      CardBlueprint card, bool isOwned, int count, Color gameColor) {
    final rarColor = card.rarityColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isOwned
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.015),
        border: Border.all(
          color: isOwned
              ? rarColor.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.06),
          width: isOwned ? 1.5 : 1,
        ),
        boxShadow: isOwned
            ? [
                BoxShadow(
                  color: rarColor.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Card image or placeholder
            Positioned.fill(
              child: isOwned && card.imageUrl != null
                  ? Image.network(
                      card.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildCardPlaceholder(card, isOwned),
                    )
                  : _buildCardPlaceholder(card, isOwned),
            ),

            // Dimming overlay for unowned
            if (!isOwned)
              Positioned.fill(
                child: Container(
                  color: AppColors.background.withValues(alpha: 0.5),
                ),
              ),

            // Bottom info bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.background.withValues(alpha: 0.95),
                      AppColors.background.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (card.collectorNumber != null)
                          Text(
                            '#${card.collectorNumber}',
                            style: TextStyle(
                              color: isOwned
                                  ? rarColor
                                  : AppColors.textMuted
                                      .withValues(alpha: 0.5),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        const Spacer(),
                        if (isOwned && count > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: gameColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'x$count',
                              style: TextStyle(
                                color: gameColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      card.name,
                      style: TextStyle(
                        color: isOwned
                            ? Colors.white
                            : AppColors.textMuted
                                .withValues(alpha: 0.4),
                        fontSize: 9,
                        fontWeight:
                            isOwned ? FontWeight.w600 : FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Rarity dot (top-right)
            if (isOwned)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: rarColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: rarColor.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),

            // Lock icon for unowned
            if (!isOwned)
              Center(
                child: Icon(
                  Icons.lock_outline,
                  color: Colors.white.withValues(alpha: 0.08),
                  size: 28,
                ),
              ),

            // Market price badge for owned
            if (isOwned && card.marketPrice != null)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.accentGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    card.formattedPrice,
                    style: const TextStyle(
                      color: AppColors.accentGreen,
                      fontSize: 8,
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

  Widget _buildCardPlaceholder(CardBlueprint card, bool isOwned) {
    final rarColor = card.rarityColor;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOwned
              ? [
                  rarColor.withValues(alpha: 0.15),
                  rarColor.withValues(alpha: 0.05),
                ]
              : [
                  Colors.white.withValues(alpha: 0.03),
                  Colors.white.withValues(alpha: 0.01),
                ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.style,
          color: isOwned
              ? rarColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          size: 24,
        ),
      ),
    );
  }
}
