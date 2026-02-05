import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/product.dart';
import '../models/card_blueprint.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/ocr_scanner_dialog.dart';
import '../services/firestore_service.dart';
import '../services/card_catalog_service.dart';
import '../services/demo_data_service.dart';

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
    try {
      final all = await _catalogService.getAllCards();
      // Only show single cards in collection (no boxes, packs, etc.)
      final cards = all.where((c) => c.kind == null || c.kind == 'singleCard').toList();
      if (mounted) setState(() { _catalog = cards; _catalogLoading = false; });
    } catch (_) {
      // If catalog fails (e.g. no auth), still show what we have
      if (mounted) setState(() { _catalogLoading = false; });
    }
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

  Future<void> _scanCard(BuildContext context, List<CardBlueprint> gameCatalog, Map<String, Product> pMap) async {
    final numbers = await OcrScannerDialog.scan(
      context,
      expansionCards: gameCatalog,
    );
    if (!mounted || numbers.isEmpty) return;

    for (final num in numbers) {
      // Look up the card in the current game's catalog
      final match = gameCatalog
          .where((c) =>
              c.collectorNumber != null &&
              c.collectorNumber!.replaceAll(RegExp(r'^0+'), '') ==
                  num.replaceAll(RegExp(r'^0+'), ''))
          .firstOrNull;
      if (match != null) {
        final existing = pMap[match.id];
        if (existing != null && existing.id != null) {
          // Increment quantity
          await widget.fs.updateProduct(existing.id!, {'quantity': existing.quantity + 1});
        } else {
          // Add new card
          await widget.fs.addProduct(Product(
            name: match.name,
            brand: widget.game.toUpperCase(),
            quantity: 1,
            price: match.marketPrice != null ? match.marketPrice!.cents / 100 : 0,
            status: ProductStatus.inInventory,
            kind: ProductKind.singleCard,
            cardBlueprintId: match.id,
            cardImageUrl: match.imageUrl,
            cardExpansion: match.expansionName,
            cardRarity: match.rarity,
            marketPrice: match.marketPrice != null ? match.marketPrice!.cents / 100 : null,
          ));
        }
      }
    }
  }

  /// Build map of blueprintId → Product, aggregating quantity from duplicates.
  /// Keeps the first product (for id/metadata) but sums quantities.
  Map<String, Product> _productMap() {
    final m = <String, Product>{};
    for (final p in widget.products) {
      if (p.brand.toLowerCase() == widget.game && p.cardBlueprintId != null) {
        final existing = m[p.cardBlueprintId!];
        if (existing != null) {
          // Aggregate: sum quantities and inventoryQty, keep first product's id
          m[p.cardBlueprintId!] = existing.copyWith(
            quantity: existing.quantity + p.quantity,
            inventoryQty: existing.inventoryQty + p.inventoryQty,
          );
        } else {
          m[p.cardBlueprintId!] = p;
        }
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
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt, color: _meta.color),
            tooltip: 'Scansiona carta',
            onPressed: () => _scanCard(context, gameCatalog, pMap),
          ),
        ],
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
class _CardGridView extends StatefulWidget {
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
  State<_CardGridView> createState() => _CardGridViewState();
}

class _CardGridViewState extends State<_CardGridView> {
  final Set<String> _selectedRarities = {};

  @override
  Widget build(BuildContext context) {
    // Sort by collector number
    final sorted = List<CardBlueprint>.from(widget.cards)
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
      if (widget.productMap.containsKey(c.id)) {
        rarityOwned[r] = (rarityOwned[r] ?? 0) + 1;
      }
    }

    // Filter by selected rarities
    final filtered = _selectedRarities.isEmpty
        ? sorted
        : sorted.where((c) => _selectedRarities.contains(c.rarity ?? 'unknown')).toList();

    // Stats (based on full list, not filtered)
    final owned = sorted.where((c) => widget.productMap.containsKey(c.id)).length;
    final totalValue = sorted.fold<double>(0, (s, c) {
      final p = widget.productMap[c.id];
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
                      style: TextStyle(color: widget.meta.color, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('€${totalValue.toStringAsFixed(2)}',
                      style: TextStyle(color: widget.meta.color, fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation(widget.meta.color),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 8),
              // Rarity chips — tappable toggles
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: rarityCount.entries.map((e) {
                    final ownedR = rarityOwned[e.key] ?? 0;
                    final isSelected = _selectedRarities.contains(e.key);
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedRarities.remove(e.key);
                            } else {
                              _selectedRarities.add(e.key);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? widget.meta.color.withValues(alpha: 0.2)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? widget.meta.color.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Text(
                            '${e.key}: $ownedR/${e.value}',
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? widget.meta.color : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ),
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
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final card = filtered[i];
              final product = widget.productMap[card.id];
              final isOwned = product != null;

              return _CardSlot(
                card: card,
                product: product,
                isOwned: isOwned,
                meta: widget.meta,
                game: widget.game,
                fs: widget.fs,
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
    if (FirestoreService.demoMode) {
      // In demo mode, update local list instead of Firestore
      if (isOwned && product != null) {
        final idx = DemoDataService.products.indexWhere((p) => p.id == product!.id);
        if (idx >= 0) {
          DemoDataService.products[idx] = DemoDataService.products[idx].copyWith(
            quantity: product!.quantity + 1,
          );
        }
      } else {
        final priceVal = card.marketPrice != null ? card.marketPrice!.cents / 100 : 0.0;
        DemoDataService.products.add(Product(
          id: 'demo-${card.id}',
          name: card.name,
          brand: game.toUpperCase(),
          quantity: 1,
          price: priceVal,
          status: ProductStatus.inInventory,
          kind: ProductKind.singleCard,
          cardBlueprintId: card.id,
          cardImageUrl: card.imageUrl,
          cardExpansion: card.expansionName,
          cardRarity: card.rarity,
          marketPrice: card.marketPrice != null ? card.marketPrice!.cents / 100 : null,
        ));
      }
      return;
    }
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

  void _onLongPress(BuildContext context) {
    if (!isOwned || product == null) return;
    _showCardOptionsSheet(context);
  }

  void _showCardOptionsSheet(BuildContext context) {
    final p = product!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Quantità: ${p.quantity.toInt()} • Inventario: ${p.inventoryQty.toInt()}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 20),
            // Move to inventory
            _OptionTile(
              icon: Icons.inventory_2_outlined,
              label: 'Sposta in inventario',
              color: AppColors.accentBlue,
              onTap: () {
                Navigator.pop(ctx);
                _showMoveToInventorySheet(context, p);
              },
            ),
            const SizedBox(height: 8),
            // Remove from collection
            _OptionTile(
              icon: Icons.remove_circle_outline,
              label: 'Rimuovi dalla collezione',
              color: AppColors.accentRed,
              onTap: () async {
                Navigator.pop(ctx);
                final newQty = p.quantity - 1;
                if (newQty <= 0) {
                  if (p.id != null) await fs.deleteProduct(p.id!);
                } else {
                  final newInv = p.inventoryQty > newQty ? newQty : p.inventoryQty;
                  await fs.updateProduct(p.id!, {
                    'quantity': newQty,
                    'inventoryQty': newInv,
                  });
                }
              },
            ),
            // Remove from inventory (only if inventoryQty > 0)
            if (p.inventoryQty > 0) ...[
              const SizedBox(height: 8),
              _OptionTile(
                icon: Icons.outbox_outlined,
                label: 'Rimuovi da inventario',
                color: AppColors.accentOrange,
                onTap: () async {
                  Navigator.pop(ctx);
                  final newInv = (p.inventoryQty - 1).clamp(0.0, p.quantity);
                  await fs.updateProduct(p.id!, {'inventoryQty': newInv});
                },
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showMoveToInventorySheet(BuildContext context, Product p) {
    final maxMove = (p.quantity - p.inventoryQty).clamp(0.0, p.quantity);
    if (maxMove <= 0) return;
    int moveCount = 1;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Sposta in inventario', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Max: ${maxMove.toInt()} copie disponibili', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () { if (moveCount > 1) setSheetState(() => moveCount--); },
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.remove, color: AppColors.textSecondary),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text('$moveCount', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  GestureDetector(
                    onTap: () { if (moveCount < maxMove.toInt()) setSheetState(() => moveCount++); },
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: AppColors.accentBlue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.add, color: AppColors.accentBlue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () async {
                  Navigator.pop(ctx);
                  final newInv = (p.inventoryQty + moveCount).clamp(0.0, p.quantity);
                  await fs.updateProduct(p.id!, {'inventoryQty': newInv});
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.blueButtonGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('Conferma', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
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
      onLongPress: () => _onLongPress(context),
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

            // Inventory badge (below count badge) — if inventoryQty > 0
            if (isOwned && product!.inventoryQty > 0)
              Positioned(
                top: product!.quantity > 1 ? 20 : 3, right: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.5), width: 0.5),
                  ),
                  child: Text(
                    '📦 ${product!.inventoryQty.toInt()}',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
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

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OptionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
