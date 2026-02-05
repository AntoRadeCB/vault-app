import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../providers/profile_provider.dart';
import '../screens/dashboard_screen.dart';
import '../screens/collection_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/add_item_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/shipments_screen.dart';
import '../screens/tracking_detail_screen.dart';
import '../screens/add_sale_screen.dart';
import '../screens/edit_product_screen.dart';
import '../screens/open_product_screen.dart';
import '../screens/notifications_screen.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/coach_mark_overlay.dart';
import '../widgets/ocr_scanner_dialog.dart';
import '../services/firestore_service.dart';
import '../services/card_catalog_service.dart';
import '../models/product.dart';
import '../models/purchase.dart';
import '../models/card_blueprint.dart';

import 'navigation_state.dart';
import 'coach_steps_builder.dart';
import 'widgets/sidebar.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/desktop_top_bar.dart';
import 'widgets/mobile_top_bar.dart';
import 'widgets/profile_switcher.dart';
import 'widgets/demo_auth_prompt.dart';

class MainShell extends StatefulWidget {
  final bool isDemoMode;
  final VoidCallback? onAuthRequired;

  const MainShell({super.key, this.isDemoMode = false, this.onAuthRequired});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final NavigationController _nav = NavigationController();
  bool _showTutorial = false;
  bool _tutorialReady = false; // true once target widgets are verified

  // Firebase refs for tutorial persistence
  static final __firebaseAuth = FirebaseAuth.instance;
  static final __firestore = FirebaseFirestore.instance;

  // ─── GlobalKeys for interactive coach marks ──────
  final _keyDashboardNav = GlobalKey();
  final _keyCollectionNav = GlobalKey();
  final _keyInventoryNav = GlobalKey();
  final _keyShipmentsNav = GlobalKey();
  // _keyReportsNav removed (reports moved to settings)
  final _keySettingsNav = GlobalKey();
  final _keyFab = GlobalKey();
  final _keyNotifications = GlobalKey();
  // Desktop sidebar keys
  final _keySidebarDashboard = GlobalKey();
  final _keySidebarCollection = GlobalKey();
  final _keySidebarInventory = GlobalKey();
  final _keySidebarShipments = GlobalKey();
  // _keySidebarReports removed (reports moved to settings)
  final _keySidebarSettings = GlobalKey();

  @override
  void initState() {
    super.initState();
    _nav.addListener(_onNavChanged);
    _checkFirstLaunch();
  }

  @override
  void dispose() {
    _nav.removeListener(_onNavChanged);
    _nav.dispose();
    super.dispose();
  }

  void _onNavChanged() => setState(() {});

  Future<void> _checkFirstLaunch() async {
    // Check if tutorial was already completed (persisted in Firestore)
    try {
      final user = __firebaseAuth.currentUser;
      if (user != null) {
        final doc = await __firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data()?['tutorialComplete'] == true) {
          return; // Already done, don't show again
        }
      }
    } catch (_) {
      // If we can't check, still show the tutorial
    }

    // Wait for the UI to be fully rendered: poll until at least one
    // GlobalKey has a valid RenderObject (max ~5 seconds).
    for (int i = 0; i < 25; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      // Check if the bottom nav OR sidebar keys are mounted
      if (_keyDashboardNav.currentContext != null ||
          _keySidebarDashboard.currentContext != null) {
        // Give one more frame for everything to settle
        await Future.delayed(const Duration(milliseconds: 300));
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _showTutorial = true;
      _tutorialReady = true;
    });
  }

  void _dismissTutorial() {
    setState(() {
      _showTutorial = false;
      _tutorialReady = false;
    });
    // Persist completion so it won't show again
    _markTutorialComplete();
  }

  Future<void> _markTutorialComplete() async {
    try {
      final user = __firebaseAuth.currentUser;
      if (user != null) {
        await __firestore.collection('users').doc(user.uid).set(
          {'tutorialComplete': true},
          SetOptions(merge: true),
        );
      }
    } catch (_) {
      // Non-critical – worst case the tutorial shows once more
    }
  }

  // ─── Visible tabs based on profile ──────────────
  List<TabDef> _visibleTabs(BuildContext context) {
    final provider = ProfileProvider.maybeOf(context);
    if (provider == null || provider.profile == null) return allTabDefs;
    final enabled = provider.enabledTabs;
    return allTabDefs.where((t) => enabled.contains(t.id)).toList();
  }

  // ─── Coach-mark key resolvers ───────────────────
  GlobalKey _mobileNavKey(String id) {
    switch (id) {
      case 'dashboard':  return _keyDashboardNav;
      case 'collection': return _keyCollectionNav;
      case 'inventory':  return _keyInventoryNav;
      case 'shipments':  return _keyShipmentsNav;
      case 'reports':    return GlobalKey(); // legacy fallback
      case 'settings':   return _keySettingsNav;
      default:           return GlobalKey();
    }
  }

  GlobalKey _sidebarKey(String id) {
    switch (id) {
      case 'dashboard':  return _keySidebarDashboard;
      case 'collection': return _keySidebarCollection;
      case 'inventory':  return _keySidebarInventory;
      case 'shipments':  return _keySidebarShipments;
      case 'reports':    return GlobalKey(); // legacy fallback
      case 'settings':   return _keySidebarSettings;
      default:           return GlobalKey();
    }
  }

  // ─── Demo-mode guarded actions ──────────────────
  void _guardedAddItem() {
    if (_nav.guardAuth(widget.isDemoMode)) {
      showDemoAuthPrompt(context, onAuthRequired: widget.onAuthRequired ?? () {});
      return;
    }
    _nav.showAddItem();
  }

  void _guardedAddSale() {
    if (_nav.guardAuth(widget.isDemoMode)) {
      showDemoAuthPrompt(context, onAuthRequired: widget.onAuthRequired ?? () {});
      return;
    }
    _nav.showAddSale();
  }

  void _showSbustaSheet(BuildContext context) {
    final fs = FirestoreService();
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
            Row(
              children: [
                const Expanded(
                  child: Text('Sbusta', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddSealedProductDialog(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppColors.blueButtonGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text('Aggiungi', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Scegli un prodotto sigillato da aprire', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: StreamBuilder<List<Product>>(
                stream: fs.getProducts(),
                builder: (context, snap) {
                  final sealed = (snap.data ?? []).where((p) => p.canBeOpened && !p.isOpened).toList();
                  if (sealed.isEmpty) {
                    return const Center(
                      child: Text('Nessun prodotto sigillato', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                    );
                  }
                  return ListView.builder(
                    itemCount: sealed.length,
                    itemBuilder: (context, i) {
                      final p = sealed[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            _nav.showOpenProduct(p);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.cardDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.accentOrange.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.inventory_2, color: AppColors.accentOrange, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text('${p.kindLabel} • Qta: ${p.formattedQuantity}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAddSealedProductDialog(BuildContext parentContext) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    ProductKind selectedKind = ProductKind.boosterPack;

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
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
                const Text('Aggiungi Prodotto Sigillato', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Nome prodotto',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Prezzo €',
                          hintStyle: const TextStyle(color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.cardDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Quantità',
                          hintStyle: const TextStyle(color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.cardDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('TIPO', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [ProductKind.boosterPack, ProductKind.boosterBox, ProductKind.display, ProductKind.bundle].map((kind) {
                    final isSelected = kind == selectedKind;
                    final label = switch (kind) {
                      ProductKind.boosterPack => 'Busta',
                      ProductKind.boosterBox => 'Box',
                      ProductKind.display => 'Display',
                      ProductKind.bundle => 'Bundle',
                      _ => '',
                    };
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedKind = kind),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accentBlue.withValues(alpha: 0.15) : AppColors.cardDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? AppColors.accentBlue.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () async {
                    final name = nameController.text.trim();
                    final price = double.tryParse(priceController.text.trim()) ?? 0;
                    final quantity = double.tryParse(quantityController.text.trim()) ?? 1;
                    if (name.isEmpty) return;
                    Navigator.pop(ctx);
                    final fs = FirestoreService();
                    final product = Product(
                      name: name,
                      brand: 'CUSTOM',
                      quantity: quantity,
                      price: price,
                      status: ProductStatus.inInventory,
                      kind: selectedKind,
                    );
                    await fs.addProduct(product);
                    await fs.addPurchase(Purchase(
                      productName: name,
                      price: price,
                      quantity: quantity,
                      date: DateTime.now(),
                      workspace: 'default',
                    ));
                    if (mounted) {
                      _showSbustaSheet(parentContext);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: AppColors.blueButtonGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: AppColors.accentBlue.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Center(
                      child: Text('Aggiungi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openScanFromFab(BuildContext context) async {
    if (widget.isDemoMode) {
      widget.onAuthRequired?.call();
      return;
    }
    // Load all cards for expansion matching
    final catalogService = CardCatalogService();
    List<CardBlueprint> allCards = [];
    try {
      allCards = await catalogService.getAllCards();
    } catch (_) {}

    if (!mounted) return;
    final numbers = await OcrScannerDialog.scan(
      context,
      expansionCards: allCards,
    );
    if (!mounted || numbers.isEmpty) return;

    // For each scanned number, try to find and add the card
    final fs = FirestoreService();
    for (final num in numbers) {
      final match = allCards
          .where((c) =>
              c.collectorNumber != null &&
              c.collectorNumber!.replaceAll(RegExp(r'^0+'), '') ==
                  num.replaceAll(RegExp(r'^0+'), ''))
          .firstOrNull;
      if (match != null) {
        // Check if already owned
        final products = await fs.getProducts().first;
        final existing = products
            .where((p) => p.cardBlueprintId == match.id)
            .firstOrNull;
        if (existing != null && existing.id != null) {
          await fs.updateProduct(existing.id!, {'quantity': existing.quantity + 1});
        } else {
          await fs.addProduct(Product(
            name: match.name,
            brand: (match.game ?? 'unknown').toUpperCase(),
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

  void _handleProfileSwitch() {
    showProfileSwitcher(context, onSwitched: () {
      _nav.navigateTo(0);
    });
  }

  // ─── Current screen resolver ────────────────────
  Widget _getCurrentScreen(BuildContext context) {
    if (_nav.isShowingNotifications) {
      return NotificationsScreen(onBack: _nav.closeOverlay);
    }
    if (_nav.isShowingAddItem) {
      return AddItemScreen(onBack: _nav.closeOverlay);
    }
    if (_nav.isShowingAddSale) {
      return AddSaleScreen(onBack: _nav.closeOverlay);
    }
    if (_nav.editingProduct != null) {
      return EditProductScreen(
        product: _nav.editingProduct!,
        onBack: _nav.closeOverlay,
        onSaved: () {},
      );
    }
    if (_nav.openingProduct != null) {
      return OpenProductScreen(
        product: _nav.openingProduct!,
        onBack: _nav.closeOverlay,
        onDone: _nav.closeOverlay,
      );
    }
    if (_nav.trackingShipment != null) {
      return TrackingDetailScreen(
        shipment: _nav.trackingShipment!,
        onBack: _nav.closeOverlay,
      );
    }

    final tabs = _visibleTabs(context);
    final safeIndex =
        _nav.currentIndex < tabs.length ? _nav.currentIndex : 0;
    final tabId = tabs[safeIndex].id;

    switch (tabId) {
      case 'dashboard':
        return DashboardScreen(onAuthRequired: widget.onAuthRequired);
      case 'collection':
        return const CollectionScreen();
      case 'inventory':
        return InventoryScreen(
          onEditProduct: _nav.showEditProduct,
          onOpenProduct: _nav.showOpenProduct,
        );
      case 'shipments':
        return ShipmentsScreen(onTrackShipment: _nav.showTrackingDetail);
      case 'reports':
        return const ReportsScreen();
      case 'settings':
        return const SettingsScreen();
      default:
        return DashboardScreen(onAuthRequired: widget.onAuthRequired);
    }
  }

  // ─── Build ──────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          isWide ? _buildDesktopLayout(context) : _buildMobileLayout(context),
          if (_showTutorial && _tutorialReady)
            CoachMarkOverlay(
              steps: CoachStepsBuilder.build(
                context: context,
                isWide: isWide,
                visibleTabs: _visibleTabs(context),
                mobileNavKey: _mobileNavKey,
                sidebarKey: _sidebarKey,
                fabKey: _keyFab,
                notificationsKey: _keyNotifications,
              ),
              onComplete: _dismissTutorial,
              onSkip: _dismissTutorial,
            ),
        ],
      ),
      bottomNavigationBar: !isWide
          ? IgnorePointer(
              ignoring: _showTutorial,
              child: AppBottomNav(
                tabs: _visibleTabs(context),
                currentIndex: _nav.currentIndex,
                hasOverlay: _nav.hasOverlay,
                onTap: _nav.navigateTo,
                mobileNavKey: _mobileNavKey,
              ),
            )
          : null,
      floatingActionButton: !isWide
          ? IgnorePointer(
              ignoring: _showTutorial,
              child: AnimatedFab(
                key: _keyFab,
                onAdd: _guardedAddItem,
                onSbusta: () => _showSbustaSheet(context),
                onScan: () => _openScanFromFab(context),
              ),
            )
          : null,
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final provider = ProfileProvider.maybeOf(context);
    return Row(
      children: [
        AppSidebar(
          tabs: _visibleTabs(context),
          currentIndex: _nav.currentIndex,
          hasOverlay: _nav.hasOverlay,
          onTap: _nav.navigateTo,
          profile: provider?.profile,
          onProfileSwitch: _handleProfileSwitch,
          sidebarKey: _sidebarKey,
        ),
        Expanded(
          child: Column(
            children: [
              DesktopTopBar(
                showNotifications: _nav.isShowingNotifications,
                onAddItem: _guardedAddItem,
                onShowNotifications: _nav.showNotificationsScreen,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.02, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<String>(_nav.screenKey),
                    child: _getCurrentScreen(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final provider = ProfileProvider.maybeOf(context);
    return SafeArea(
      child: Column(
        children: [
          MobileTopBar(
            profile: provider?.profile,
            showNotifications: _nav.isShowingNotifications,
            onProfileSwitch: _handleProfileSwitch,
            onShowNotifications: _nav.showNotificationsScreen,
            notificationsKey: _keyNotifications,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: KeyedSubtree(
                key: ValueKey<String>(_nav.screenKey),
                child: _getCurrentScreen(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
