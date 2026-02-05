import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/product.dart';
import '../models/card_blueprint.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../services/card_catalog_service.dart';

// ──────────────────────────────────────────────────
// Game metadata
// ──────────────────────────────────────────────────
class _GameMeta {
  final String key; // lowercase
  final String label;
  final Color color;
  final IconData icon;
  const _GameMeta(this.key, this.label, this.color, this.icon);
}

const List<_GameMeta> _knownGames = [
  _GameMeta('riftbound', 'RIFTBOUND', Color(0xFF667eea), Icons.bolt),
  _GameMeta('pokemon', 'POKÉMON', Color(0xFFFFCB05), Icons.catching_pokemon),
  _GameMeta('mtg', 'MTG', Color(0xFF764ba2), Icons.auto_awesome),
  _GameMeta('yugioh', 'YU-GI-OH', Color(0xFFE53935), Icons.flash_on),
  _GameMeta('one-piece', 'ONE PIECE', Color(0xFFFF7043), Icons.sailing),
];

_GameMeta _metaFor(String gameKey) {
  final k = gameKey.toLowerCase().trim();
  return _knownGames.firstWhere(
    (m) => m.key == k,
    orElse: () => _GameMeta(k, k.toUpperCase(), AppColors.accentBlue, Icons.style),
  );
}

// ──────────────────────────────────────────────────
// Main screen
// ──────────────────────────────────────────────────
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});
  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final FirestoreService _fs = FirestoreService();
  final CardCatalogService _catalogService = CardCatalogService();

  List<CardBlueprint> _catalog = [];
  bool _catalogLoading = true;
  String? _selectedGame; // null = game selection

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final cards = await _catalogService.getAllCards();
    if (mounted) setState(() { _catalog = cards; _catalogLoading = false; });
  }

  // Normalize game key from catalog
  String _normalizeGame(String? g) => (g ?? 'unknown').toLowerCase().trim();

  @override
  Widget build(BuildContext context) {
    if (_catalogLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<List<Product>>(
      stream: _fs.getProducts(),
      builder: (ctx, snap) {
        final products = (snap.data ?? [])
            .where((p) => p.kind == ProductKind.singleCard)
            .toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _selectedGame == null
                ? _GameSelectionView(
                    key: const ValueKey('games'),
                    catalog: _catalog,
                    products: products,
                    onSelect: (g) => setState(() => _selectedGame = g),
                    normalizeGame: _normalizeGame,
                  )
                : _GameExpansionView(
                    key: ValueKey('game-$_selectedGame'),
                    game: _selectedGame!,
                    catalog: _catalog,
                    products: products,
                    fs: _fs,
                    normalizeGame: _normalizeGame,
                    onBack: () => setState(() => _selectedGame = null),
                  ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────
// Level 1 — Game Selection
// ──────────────────────────────────────────────────
class _GameSelectionView extends StatelessWidget {
  final List<CardBlueprint> catalog;
  final List<Product> products;
  final ValueChanged<String> onSelect;
  final String Function(String?) normalizeGame;

  const _GameSelectionView({
    super.key,
    required this.catalog,
    required this.products,
    required this.onSelect,
    required this.normalizeGame,
  });

  @override
  Widget build(BuildContext context) {
    // Group catalog by game
    final Map<String, List<CardBlueprint>> catalogByGame = {};
    for (final c in catalog) {
      final g = normalizeGame(c.game);
      catalogByGame.putIfAbsent(g, () => []).add(c);
    }

    // Group products by game (brand is uppercase)
    final Map<String, List<Product>> productsByGame = {};
    for (final p in products) {
      final g = p.brand.toLowerCase().trim();
      productsByGame.putIfAbsent(g, () => []).add(p);
    }

    // Order: known games first, then any others
    final gameKeys = <String>{};
    for (final m in _knownGames) {
      if (catalogByGame.containsKey(m.key)) gameKeys.add(m.key);
    }
    for (final k in catalogByGame.keys) {
      gameKeys.add(k);
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.background,
          title: const Text('Collezione',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 24)),
          centerTitle: false,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final game = gameKeys.elementAt(i);
                final meta = _metaFor(game);
                final catCards = catalogByGame[game] ?? [];
                final owned = productsByGame[game] ?? [];
                final uniqueOwned = owned.map((p) => p.cardBlueprintId).toSet().length;
                final totalCopies = owned.fold<double>(0, (s, p) => s + p.quantity);
                final totalValue = owned.fold<double>(0, (s, p) => s + (p.marketPrice ?? 0) * p.quantity);
                final progress = catCards.isEmpty ? 0.0 : uniqueOwned / catCards.length;

                return StaggeredFadeSlide(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ScaleOnPress(
                      onTap: () => onSelect(game),
                      child: GlassCard(
                        glowColor: meta.color,
                        child: Row(
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                color: meta.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(meta.icon, color: meta.color, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(meta.label,
                                      style: TextStyle(
                                          color: meta.color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$uniqueOwned / ${catCards.length} carte  •  ${totalCopies.toInt()} copie  •  €${totalValue.toStringAsFixed(2)}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                                      valueColor: AlwaysStoppedAnimation(meta.color),
                                      minHeight: 5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: gameKeys.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────
// Level 2 — Expansion Tabs
// ──────────────────────────────────────────────────
class _GameExpansionView extends StatefulWidget {
  final String game;
  final List<CardBlueprint> catalog;
  final List<Product> products;
  final FirestoreService fs;
  final String Function(String?) normalizeGame;
  final VoidCallback onBack;

  const _GameExpansionView({
    super.key,
    required this.game,
    required this.catalog,
    required this.products,
    required this.fs,
    required this.normalizeGame,
    required this.onBack,
  });

  @override
  State<_GameExpansionView> createState() => _GameExpansionViewState();
}

class _GameExpansionViewState extends State<_GameExpansionView>
    with TickerProviderStateMixin {
  TabController? _tabController;
  late _GameMeta _meta;

  // Big expansions get their own tab, small ones go in "Altro"
  List<_ExpansionData> _bigExpansions = [];
  List<_ExpansionData> _smallExpansions = [];

  // For "Altro" sub-navigation
  String? _altroSelectedExpansion;

  @override
  void initState() {
    super.initState();
    _meta = _metaFor(widget.game);
    _buildTabs();
  }

  @override
  void didUpdateWidget(covariant _GameExpansionView old) {
    super.didUpdateWidget(old);
    if (old.game != widget.game || old.catalog.length != widget.catalog.length) {
      _buildTabs();
    }
  }

  void _buildTabs() {
    final gameCatalog = widget.catalog
        .where((c) => widget.normalizeGame(c.game) == widget.game)
        .toList();

    // Group by expansion
    final Map<String, List<CardBlueprint>> byExp = {};
    for (final c in gameCatalog) {
      final exp = c.expansionName ?? 'Sconosciuta';
      byExp.putIfAbsent(exp, () => []).add(c);
    }

    _bigExpansions = [];
    _smallExpansions = [];
    for (final e in byExp.entries) {
      final data = _ExpansionData(e.key, e.value);
      if (e.value.length >= 100) {
        _bigExpansions.add(data);
      } else {
        _smallExpansions.add(data);
      }
    }

    // Sort alphabetically
    _bigExpansions.sort((a, b) => a.name.compareTo(b.name));
    _smallExpansions.sort((a, b) => a.name.compareTo(b.name));

    final tabCount = _bigExpansions.length + (_smallExpansions.isNotEmpty ? 1 : 0);
    _tabController?.dispose();
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Map<String, Product> _productMap() {
    final m = <String, Product>{};
    for (final p in widget.products) {
      if (p.brand.toLowerCase() == widget.game && p.cardBlueprintId != null) {
        m[p.cardBlueprintId!] = p;
      }
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final pMap = _productMap();

    // Calculate game-level stats
    final gameCatalog = widget.catalog
        .where((c) => widget.normalizeGame(c.game) == widget.game)
        .toList();
    final gameProducts = widget.products
        .where((p) => p.brand.toLowerCase() == widget.game)
        .toList();
    final uniqueOwned = gameProducts.map((p) => p.cardBlueprintId).toSet().length;
    final totalValue = gameProducts.fold<double>(0, (s, p) => s + (p.marketPrice ?? 0) * p.quantity);

    if (_tabController == null || _tabController!.length == 0) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: widget.onBack),
          title: Text(_meta.label, style: TextStyle(color: _meta.color, fontWeight: FontWeight.bold)),
        ),
        body: const Center(child: Text('Nessuna espansione trovata', style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (_altroSelectedExpansion != null) {
              setState(() => _altroSelectedExpansion = null);
            } else {
              widget.onBack();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_meta.label, style: TextStyle(color: _meta.color, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              '$uniqueOwned / ${gameCatalog.length} carte  •  €${totalValue.toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: _meta.color,
            indicatorWeight: 3,
            labelColor: _meta.color,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final exp in _bigExpansions)
                Tab(text: exp.name),
              if (_smallExpansions.isNotEmpty)
                const Tab(text: 'Altro'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          for (final exp in _bigExpansions)
            _CardGridView(
              cards: exp.cards,
              productMap: pMap,
              fs: widget.fs,
              game: widget.game,
              meta: _meta,
            ),
          if (_smallExpansions.isNotEmpty)
            _AltroTab(
              expansions: _smallExpansions,
              productMap: pMap,
              fs: widget.fs,
              game: widget.game,
              meta: _meta,
              selectedExpansion: _altroSelectedExpansion,
              onSelectExpansion: (e) => setState(() => _altroSelectedExpansion = e),
            ),
        ],
      ),
    );
  }
}

class _ExpansionData {
  final String name;
  final List<CardBlueprint> cards;
  const _ExpansionData(this.name, this.cards);
}

// ──────────────────────────────────────────────────
// "Altro" tab — list of small expansions
// ──────────────────────────────────────────────────
class _AltroTab extends StatelessWidget {
  final List<_ExpansionData> expansions;
  final Map<String, Product> productMap;
  final FirestoreService fs;
  final String game;
  final _GameMeta meta;
  final String? selectedExpansion;
  final ValueChanged<String?> onSelectExpansion;

  const _AltroTab({
    required this.expansions,
    required this.productMap,
    required this.fs,
    required this.game,
    required this.meta,
    required this.selectedExpansion,
    required this.onSelectExpansion,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedExpansion != null) {
      final exp = expansions.firstWhere(
        (e) => e.name == selectedExpansion,
        orElse: () => expansions.first,
      );
      return Column(
        children: [
          // Back header
          InkWell(
            onTap: () => onSelectExpansion(null),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.surface,
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios, size: 16, color: meta.color),
                  const SizedBox(width: 8),
                  Text(exp.name,
                      style: TextStyle(color: meta.color, fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
            ),
          ),
          Expanded(
            child: _CardGridView(
              cards: exp.cards,
              productMap: productMap,
              fs: fs,
              game: game,
              meta: meta,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: expansions.length,
      itemBuilder: (ctx, i) {
        final exp = expansions[i];
        final owned = exp.cards.where((c) => productMap.containsKey(c.id)).length;
        final progress = exp.cards.isEmpty ? 0.0 : owned / exp.cards.length;

        return StaggeredFadeSlide(
          index: i,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ScaleOnPress(
              onTap: () => onSelectExpansion(exp.name),
              child: GlassCard(
                glowColor: meta.color,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: meta.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${exp.cards.length}',
                          style: TextStyle(color: meta.color, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(exp.name,
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('$owned / ${exp.cards.length} carte',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white.withValues(alpha: 0.06),
                              valueColor: AlwaysStoppedAnimation(meta.color),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────
// Level 3 — Card Grid
// ──────────────────────────────────────────────────
class _CardGridView extends StatelessWidget {
  final List<CardBlueprint> cards;
  final Map<String, Product> productMap;
  final FirestoreService fs;
  final String game;
  final _GameMeta meta;

  const _CardGridView({
    required this.cards,
    required this.productMap,
    required this.fs,
    required this.game,
    required this.meta,
  });

  @override
  Widget build(BuildContext context) {
    // Sort by collector number
    final sorted = List<CardBlueprint>.from(cards)
      ..sort((a, b) {
        final an = a.collectorNumber ?? '';
        final bn = b.collectorNumber ?? '';
        final ai = int.tryParse(an);
        final bi = int.tryParse(bn);
        if (ai != null && bi != null) return ai.compareTo(bi);
        return an.compareTo(bn);
      });

    // Rarity breakdown
    final Map<String, int> rarityCount = {};
    final Map<String, int> rarityOwned = {};
    for (final c in sorted) {
      final r = c.rarity ?? 'unknown';
      rarityCount[r] = (rarityCount[r] ?? 0) + 1;
      if (productMap.containsKey(c.id)) {
        rarityOwned[r] = (rarityOwned[r] ?? 0) + 1;
      }
    }

    // Stats
    final owned = sorted.where((c) => productMap.containsKey(c.id)).length;
    final totalValue = sorted.fold<double>(0, (s, c) {
      final p = productMap[c.id];
      if (p == null) return s;
      return s + (p.marketPrice ?? 0) * p.quantity;
    });
    final progress = sorted.isEmpty ? 0.0 : owned / sorted.length;

    return Column(
      children: [
        // Header with progress
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$owned / ${sorted.length}',
                      style: TextStyle(color: meta.color, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('€${totalValue.toStringAsFixed(2)}',
                      style: TextStyle(color: meta.color, fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation(meta.color),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 8),
              // Rarity chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: rarityCount.entries.map((e) {
                    final ownedR = rarityOwned[e.key] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          '${e.key}: $ownedR/${e.value}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                        backgroundColor: AppColors.surface,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                        padding: EdgeInsets.zero,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        // Card grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 80),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.68,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: sorted.length,
            itemBuilder: (ctx, i) {
              final card = sorted[i];
              final product = productMap[card.id];
              final isOwned = product != null;

              return _CardSlot(
                card: card,
                product: product,
                isOwned: isOwned,
                meta: meta,
                game: game,
                fs: fs,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────
// Individual card slot
// ──────────────────────────────────────────────────
class _CardSlot extends StatelessWidget {
  final CardBlueprint card;
  final Product? product;
  final bool isOwned;
  final _GameMeta meta;
  final String game;
  final FirestoreService fs;

  const _CardSlot({
    required this.card,
    required this.product,
    required this.isOwned,
    required this.meta,
    required this.game,
    required this.fs,
  });

  Future<void> _onTap() async {
    if (isOwned && product != null) {
      // Increment
      final newQty = product!.quantity + 1;
      await fs.updateProduct(product!.id!, {'quantity': newQty});
    } else {
      // Add new
      await fs.addProduct(Product(
        name: card.name,
        brand: game.toUpperCase(),
        quantity: 1,
        price: card.marketPrice != null ? card.marketPrice!.cents / 100 : 0,
        status: ProductStatus.inInventory,
        kind: ProductKind.singleCard,
        cardBlueprintId: card.id,
        cardImageUrl: card.imageUrl,
        cardExpansion: card.expansionName,
        cardRarity: card.rarity,
        marketPrice: card.marketPrice != null ? card.marketPrice!.cents / 100 : null,
      ));
    }
  }

  Future<void> _onLongPress() async {
    if (isOwned && product != null) {
      await fs.decrementProductQuantity(product!.id!, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final priceStr = card.marketPrice != null
        ? '€${(card.marketPrice!.cents / 100).toStringAsFixed(2)}'
        : null;

    Widget imageWidget;
    if (card.imageUrl != null && card.imageUrl!.isNotEmpty) {
      imageWidget = Image.network(
        card.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else {
      imageWidget = _placeholder();
    }

    // Grey out if not owned
    if (!isOwned) {
      imageWidget = ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
        child: Opacity(opacity: 0.45, child: imageWidget),
      );
    }

    return GestureDetector(
      onTap: _onTap,
      onLongPress: _onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.surface,
          border: Border.all(
            color: isOwned ? meta.color.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
            width: isOwned ? 1.5 : 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Card image
            imageWidget,

            // Rarity dot (top-left)
            if (card.rarity != null)
              Positioned(
                top: 4, left: 4,
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: card.rarityColor,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: card.rarityColor.withValues(alpha: 0.6), blurRadius: 4)],
                  ),
                ),
              ),

            // Count badge (top-right) — only if owned and qty > 1
            if (isOwned && product!.quantity > 1)
              Positioned(
                top: 3, right: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: meta.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'x${product!.quantity.toInt()}',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            // Price (bottom)
            if (priceStr != null)
              Positioned(
                bottom: 2, right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    priceStr,
                    style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w500),
                  ),
                ),
              ),

            // Collector number (bottom-left) for missing cards
            if (!isOwned)
              Positioned(
                bottom: 2, left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    card.collectorNumber ?? '',
                    style: const TextStyle(color: Colors.white54, fontSize: 8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            card.name,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
          ),
        ),
      ),
    );
  }
}
