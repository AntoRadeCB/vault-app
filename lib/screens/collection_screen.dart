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

    // Order: known games first, filter out unknown
    // In demo mode, only show Riftbound
    final gameKeys = <String>{};
    for (final m in _knownGames) {
      if (catalogByGame.containsKey(m.key)) {
        // In demo mode, hide games other than Riftbound
        if (FirestoreService.demoMode && m.key != 'riftbound') continue;
        gameKeys.add(m.key);
      }
    }
    // Don't add unknown/other games - only show known TCGs
    // for (final k in catalogByGame.keys) { ... }

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
                
                // Get a representative image from catalog cards
                final representativeImage = catCards
                    .where((c) => c.imageUrl != null && c.imageUrl!.isNotEmpty)
                    .take(1)
                    .map((c) => c.imageUrl!)
                    .firstOrNull;

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
                            // Game image or icon
                            Container(
                              width: 56, height: representativeImage != null ? 76 : 56,
                              decoration: BoxDecoration(
                                color: meta.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(representativeImage != null ? 10 : 14),
                                border: representativeImage != null
                                    ? Border.all(color: meta.color.withValues(alpha: 0.3), width: 1.5)
                                    : null,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: representativeImage != null
                                  ? Image.network(
                                      representativeImage,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(meta.icon, color: meta.color, size: 28),
                                    )
                                  : Icon(meta.icon, color: meta.color, size: 28),
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
        actions: const [],
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
  bool _selectionMode = false;
  final Set<String> _selectedCardIds = {};

  Future<void> _moveSelectedToInventory(List<CardBlueprint> allCards) async {
    if (_selectedCardIds.isEmpty) return;
    
    // For each selected card, increment inventoryQty
    for (final cardId in _selectedCardIds) {
      final product = widget.productMap[cardId];
      if (product != null && product.id != null) {
        final maxMove = (product.quantity - product.inventoryQty).clamp(0.0, product.quantity);
        if (maxMove > 0) {
          await widget.fs.updateProduct(product.id!, {
            'inventoryQty': product.inventoryQty + 1,
          });
        }
      }
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${_selectedCardIds.length} carte spostate in inventario'),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      setState(() {
        _selectionMode = false;
        _selectedCardIds.clear();
      });
    }
  }

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
        // Selection mode action bar
        if (_selectionMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: widget.meta.color.withValues(alpha: 0.15),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() {
                    _selectionMode = false;
                    _selectedCardIds.clear();
                  }),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_selectedCardIds.length} selezionate',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (_selectedCardIds.isNotEmpty)
                  GestureDetector(
                    onTap: () => _moveSelectedToInventory(sorted),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppColors.blueButtonGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text('Inventario', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        // Header with progress
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(
            children: [
              Row(
                children: [
                  // Progress info
                  Expanded(
                    child: Row(
                      children: [
                        Text('$owned',
                            style: TextStyle(color: widget.meta.color, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(' / ${sorted.length}',
                            style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500, fontSize: 14)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.meta.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '€${totalValue.toStringAsFixed(2)}',
                            style: TextStyle(color: widget.meta.color, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Select button (nicer design)
                  if (!_selectionMode)
                    GestureDetector(
                      onTap: () => setState(() => _selectionMode = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.meta.color.withValues(alpha: 0.15),
                              widget.meta.color.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: widget.meta.color.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, color: widget.meta.color, size: 15),
                            const SizedBox(width: 5),
                            Text('Seleziona', style: TextStyle(color: widget.meta.color, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // Subtle progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: widget.meta.color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(widget.meta.color.withValues(alpha: 0.6)),
                  minHeight: 3,
                ),
              ),
              const SizedBox(height: 6),
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
              final isSelected = _selectedCardIds.contains(card.id);

              return _CardSlot(
                card: card,
                product: product,
                isOwned: isOwned,
                meta: widget.meta,
                game: widget.game,
                fs: widget.fs,
                selectionMode: _selectionMode,
                isSelected: isSelected,
                // For card detail navigation
                allCards: filtered,
                cardIndex: i,
                productMap: widget.productMap,
                onSelectionToggle: _selectionMode && isOwned
                    ? () {
                        setState(() {
                          if (isSelected) {
                            _selectedCardIds.remove(card.id);
                          } else {
                            _selectedCardIds.add(card.id);
                          }
                        });
                      }
                    : null,
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
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;
  // For card detail navigation
  final List<CardBlueprint> allCards;
  final int cardIndex;
  final Map<String, Product> productMap;

  const _CardSlot({
    required this.card,
    required this.product,
    required this.isOwned,
    required this.meta,
    required this.game,
    required this.fs,
    this.selectionMode = false,
    this.isSelected = false,
    this.onSelectionToggle,
    required this.allCards,
    required this.cardIndex,
    required this.productMap,
  });

  // Open card detail overlay
  void _openCardDetail(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => _CardDetailOverlay(
        cards: allCards,
        initialIndex: cardIndex,
        productMap: productMap,
        meta: meta,
        game: game,
        fs: fs,
      ),
    );
  }

  // Quick add: increment quantity or add new card
  Future<void> _quickAdd(BuildContext context) async {
    // Haptic feedback
    try {
      // ignore: avoid_dynamic_calls
      // Vibration not available in web, just skip
    } catch (_) {}
    
    if (FirestoreService.demoMode) {
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
      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+1 ${card.name}'),
          backgroundColor: meta.color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    
    if (isOwned && product != null) {
      final newQty = product!.quantity + 1;
      await fs.updateProduct(product!.id!, {'quantity': newQty});
    } else {
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
    
    // Show feedback
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+1 ${card.name}'),
          backgroundColor: meta.color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
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
      onTap: selectionMode ? onSelectionToggle : () => _openCardDetail(context),
      onLongPress: selectionMode ? null : () => _quickAdd(context),
      onDoubleTap: selectionMode ? null : () => _quickAdd(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.surface,
          border: Border.all(
            color: isSelected 
                ? AppColors.accentBlue
                : isOwned 
                    ? meta.color.withValues(alpha: 0.3) 
                    : Colors.white.withValues(alpha: 0.05),
            width: isSelected ? 2.5 : (isOwned ? 1.5 : 0.5),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.accentBlue.withValues(alpha: 0.3), blurRadius: 8)]
              : null,
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

            // Selection checkbox (top-left when in selection mode)
            if (selectionMode && isOwned)
              Positioned(
                top: 4, left: 4,
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppColors.accentBlue 
                        : Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected 
                          ? AppColors.accentBlue 
                          : Colors.white.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
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

// ──────────────────────────────────────────────────
// Card Detail Overlay — Full screen card view
// ──────────────────────────────────────────────────
class _CardDetailOverlay extends StatefulWidget {
  final List<CardBlueprint> cards;
  final int initialIndex;
  final Map<String, Product> productMap;
  final _GameMeta meta;
  final String game;
  final FirestoreService fs;

  const _CardDetailOverlay({
    required this.cards,
    required this.initialIndex,
    required this.productMap,
    required this.meta,
    required this.game,
    required this.fs,
  });

  @override
  State<_CardDetailOverlay> createState() => _CardDetailOverlayState();
}

class _CardDetailOverlayState extends State<_CardDetailOverlay> {
  late int _currentIndex;
  late PageController _pageController;
  
  // Local product map that updates in demo mode
  late Map<String, Product> _liveProductMap;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _liveProductMap = Map.from(widget.productMap);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToCard(int index) {
    if (index < 0 || index >= widget.cards.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  CardBlueprint get _currentCard => widget.cards[_currentIndex];

  Future<void> _addCard(Product? currentProduct) async {
    final card = _currentCard;
    
    if (FirestoreService.demoMode) {
      if (currentProduct != null) {
        // Update existing
        final updated = currentProduct.copyWith(quantity: currentProduct.quantity + 1);
        final idx = DemoDataService.products.indexWhere((p) => p.id == currentProduct.id);
        if (idx >= 0) DemoDataService.products[idx] = updated;
        _liveProductMap[card.id] = updated;
      } else {
        // Add new
        final priceVal = card.marketPrice != null ? card.marketPrice!.cents / 100 : 0.0;
        final newProduct = Product(
          id: 'demo-${card.id}',
          name: card.name,
          brand: widget.game.toUpperCase(),
          quantity: 1,
          price: priceVal,
          status: ProductStatus.inInventory,
          kind: ProductKind.singleCard,
          cardBlueprintId: card.id,
          cardImageUrl: card.imageUrl,
          cardExpansion: card.expansionName,
          cardRarity: card.rarity,
          marketPrice: card.marketPrice != null ? card.marketPrice!.cents / 100 : null,
        );
        DemoDataService.products.add(newProduct);
        _liveProductMap[card.id] = newProduct;
      }
      setState(() {});
      return;
    }

    if (currentProduct != null) {
      await widget.fs.updateProduct(currentProduct.id!, {'quantity': currentProduct.quantity + 1});
    } else {
      await widget.fs.addProduct(Product(
        name: card.name,
        brand: widget.game.toUpperCase(),
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

  Future<void> _removeCard(Product? currentProduct) async {
    if (currentProduct == null) return;
    final card = _currentCard;

    if (FirestoreService.demoMode) {
      final idx = DemoDataService.products.indexWhere((p) => p.id == currentProduct.id);
      if (idx >= 0) {
        if (currentProduct.quantity <= 1) {
          DemoDataService.products.removeAt(idx);
          _liveProductMap.remove(card.id);
        } else {
          final updated = currentProduct.copyWith(quantity: currentProduct.quantity - 1);
          DemoDataService.products[idx] = updated;
          _liveProductMap[card.id] = updated;
        }
      }
      setState(() {});
      return;
    }

    final newQty = currentProduct.quantity - 1;
    if (newQty <= 0) {
      if (currentProduct.id != null) await widget.fs.deleteProduct(currentProduct.id!);
    } else {
      final newInv = currentProduct.inventoryQty > newQty ? newQty : currentProduct.inventoryQty;
      await widget.fs.updateProduct(currentProduct.id!, {
        'quantity': newQty,
        'inventoryQty': newInv,
      });
    }
  }

  void _showMoveToInventory(Product currentProduct) {
    final maxMove = (currentProduct.quantity - currentProduct.inventoryQty).clamp(0.0, currentProduct.quantity);
    if (maxMove <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tutte le copie sono già in inventario'),
          backgroundColor: AppColors.accentOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    
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
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Sposta in inventario', 
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Max: ${maxMove.toInt()} copie disponibili', 
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () { if (moveCount > 1) setSheetState(() => moveCount--); },
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
                    child: Text('$moveCount', 
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  ),
                  GestureDetector(
                    onTap: () { if (moveCount < maxMove.toInt()) setSheetState(() => moveCount++); },
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: widget.meta.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.add, color: widget.meta.color, size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () async {
                  Navigator.pop(ctx);
                  final newInv = (currentProduct.inventoryQty + moveCount).clamp(0.0, currentProduct.quantity);
                  if (FirestoreService.demoMode) {
                    final idx = DemoDataService.products.indexWhere((p) => p.id == currentProduct.id);
                    if (idx >= 0) {
                      final updated = currentProduct.copyWith(inventoryQty: newInv);
                      DemoDataService.products[idx] = updated;
                      _liveProductMap[_currentCard.id] = updated;
                    }
                    setState(() {});
                  } else {
                    await widget.fs.updateProduct(currentProduct.id!, {'inventoryQty': newInv});
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.blueButtonGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('Conferma', 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use StreamBuilder for Firestore, local state for demo
    if (FirestoreService.demoMode) {
      return _buildOverlay(_liveProductMap);
    }
    
    return StreamBuilder<List<Product>>(
      stream: widget.fs.getProducts(),
      builder: (ctx, snap) {
        final products = snap.data ?? [];
        final productMap = <String, Product>{};
        for (final p in products) {
          if (p.cardBlueprintId != null) {
            productMap[p.cardBlueprintId!] = p;
          }
        }
        return _buildOverlay(productMap);
      },
    );
  }

  Widget _buildOverlay(Map<String, Product> productMap) {
    final currentProduct = productMap[_currentCard.id];
    final hasProduct = currentProduct != null;
    final qty = hasProduct ? currentProduct.quantity : 0.0;
    final invQty = hasProduct ? currentProduct.inventoryQty : 0.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.7)),
          ),
          
          // Card PageView
          PageView.builder(
            controller: _pageController,
            itemCount: widget.cards.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (ctx, i) {
              final card = widget.cards[i];
              return _CardDetailPage(
                card: card,
                meta: widget.meta,
              );
            },
          ),
          
          // Close button (top-left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),
          
          // Card counter (top-right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_currentIndex + 1} / ${widget.cards.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          
          // Left arrow
          if (_currentIndex > 0)
            Positioned(
              left: 8,
              top: 0, bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _goToCard(_currentIndex - 1),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          
          // Right arrow
          if (_currentIndex < widget.cards.length - 1)
            Positioned(
              right: 8,
              top: 0, bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _goToCard(_currentIndex + 1),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          
          // Bottom action bar
          Positioned(
            left: 0, right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: widget.meta.color.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quantity controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Remove button
                      GestureDetector(
                        onTap: hasProduct ? () => _removeCard(currentProduct) : null,
                        child: Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: hasProduct 
                                ? AppColors.accentRed.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: hasProduct 
                                  ? AppColors.accentRed.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Icon(
                            Icons.remove,
                            color: hasProduct ? AppColors.accentRed : AppColors.textMuted,
                            size: 26,
                          ),
                        ),
                      ),
                      
                      // Quantity display
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          children: [
                            Text(
                              '${qty.toInt()}',
                              style: TextStyle(
                                color: hasProduct ? widget.meta.color : AppColors.textMuted,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (hasProduct && invQty > 0)
                              Text(
                                '📦 ${invQty.toInt()} in inventario',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                      
                      // Add button
                      GestureDetector(
                        onTap: () => _addCard(currentProduct),
                        child: Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.meta.color.withValues(alpha: 0.2),
                                widget.meta.color.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: widget.meta.color.withValues(alpha: 0.4)),
                          ),
                          child: Icon(Icons.add, color: widget.meta.color, size: 26),
                        ),
                      ),
                    ],
                  ),
                  
                  // Move to inventory button (only if owned)
                  if (hasProduct && qty > 0) ...[
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => _showMoveToInventory(currentProduct),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.25)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, color: AppColors.accentBlue, size: 18),
                            SizedBox(width: 8),
                            Text('Sposta in inventario',
                                style: TextStyle(color: AppColors.accentBlue, fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// Single card detail page (inside PageView)
// ──────────────────────────────────────────────────
class _CardDetailPage extends StatelessWidget {
  final CardBlueprint card;
  final _GameMeta meta;

  const _CardDetailPage({
    required this.card,
    required this.meta,
  });

  @override
  Widget build(BuildContext context) {
    final priceStr = card.marketPrice != null
        ? '€${(card.marketPrice!.cents / 100).toStringAsFixed(2)}'
        : null;

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 60), // Space for close button
          
          // Card image (large)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Hero(
                tag: 'card-${card.id}',
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: meta.color.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: card.imageUrl != null && card.imageUrl!.isNotEmpty
                      ? Image.network(
                          card.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Card info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  card.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (card.collectorNumber != null) ...[
                      Text(
                        '#${card.collectorNumber}',
                        style: TextStyle(color: meta.color, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (card.rarity != null) ...[
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: card.rarityColor,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: card.rarityColor.withValues(alpha: 0.5), blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        card.rarity!,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (priceStr != null)
                      Text(
                        priceStr,
                        style: const TextStyle(color: AppColors.accentGreen, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
                if (card.expansionName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    card.expansionName!,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 140), // Space for bottom action bar
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Icon(Icons.image_not_supported, color: AppColors.textMuted, size: 48),
      ),
    );
  }
}
