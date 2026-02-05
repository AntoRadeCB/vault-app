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
  final _keyReportsNav = GlobalKey();
  final _keySettingsNav = GlobalKey();
  final _keyFab = GlobalKey();
  final _keyNotifications = GlobalKey();
  // Desktop sidebar keys
  final _keySidebarDashboard = GlobalKey();
  final _keySidebarCollection = GlobalKey();
  final _keySidebarInventory = GlobalKey();
  final _keySidebarShipments = GlobalKey();
  final _keySidebarReports = GlobalKey();
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
      case 'reports':    return _keyReportsNav;
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
      case 'reports':    return _keySidebarReports;
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
        return DashboardScreen(
          onNewPurchase: _guardedAddItem,
          onNewSale: _guardedAddSale,
        );
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
        return DashboardScreen(
          onNewPurchase: _guardedAddItem,
          onNewSale: _guardedAddSale,
        );
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
              child: AnimatedFab(key: _keyFab, onTap: _guardedAddItem),
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
