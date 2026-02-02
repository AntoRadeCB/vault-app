import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/add_item_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shipments_screen.dart';
import 'screens/tracking_detail_screen.dart';
import 'screens/add_sale_screen.dart';
import 'screens/edit_product_screen.dart';
import 'screens/onboarding_screen.dart';
import 'widgets/animated_widgets.dart';
import 'widgets/tutorial_overlay.dart';
import 'widgets/coach_mark_overlay.dart';
import 'models/product.dart';
import 'models/shipment.dart';
import 'models/user_profile.dart';
import 'services/firestore_service.dart';
import 'services/profile_provider.dart';
import 'screens/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const VaultApp());
}

class VaultApp extends StatelessWidget {
  const VaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vault - Reselling Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AuthGate(),
    );
  }
}

/// AuthGate: shows AuthScreen if not logged in, checks onboarding, then MainShell
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.accentBlue),
            ),
          );
        }
        if (snapshot.hasData) {
          return const _OnboardingGate();
        }
        return const AuthScreen();
      },
    );
  }
}

/// Checks if the user has profiles. If not → onboarding. Else → MainShell.
class _OnboardingGate extends StatefulWidget {
  const _OnboardingGate();

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  final FirestoreService _fs = FirestoreService();
  bool _checking = true;
  bool _needsOnboarding = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final isAnon = FirebaseAuth.instance.currentUser?.isAnonymous ?? false;
      final has = await _fs.hasProfiles();

      if (!has && isAnon) {
        // Demo mode: auto-create default profiles + sample data
        await _fs.initDefaultProfiles();
        await _fs.seedDemoData();
        if (mounted) {
          setState(() {
            _needsOnboarding = false;
            _checking = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _needsOnboarding = !has;
          _checking = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _onOnboardingComplete() {
    setState(() => _needsOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentBlue),
        ),
      );
    }
    if (_needsOnboarding) {
      return OnboardingScreen(onComplete: _onOnboardingComplete);
    }
    return ProfileProviderWrapper(
      child: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  bool _showAddItem = false;
  bool _showAddSale = false;
  bool _showNotifications = false;
  bool _showTutorial = false;
  Product? _editingProduct;
  Shipment? _trackingShipment;
  final _searchController = TextEditingController();
  bool _searchFocused = false;
  final FirestoreService _firestoreService = FirestoreService();

  // GlobalKeys for interactive coach marks
  final _keyDashboardNav = GlobalKey();
  final _keyInventoryNav = GlobalKey();
  final _keyShipmentsNav = GlobalKey();
  final _keyReportsNav = GlobalKey();
  final _keySettingsNav = GlobalKey();
  final _keyFab = GlobalKey();
  final _keyNotifications = GlobalKey();
  // Desktop sidebar keys
  final _keySidebarDashboard = GlobalKey();
  final _keySidebarInventory = GlobalKey();
  final _keySidebarShipments = GlobalKey();
  final _keySidebarReports = GlobalKey();
  final _keySidebarSettings = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _showTutorial = true);
    }
  }

  void _dismissTutorial() {
    setState(() => _showTutorial = false);
  }

  // ─── Tab definition with identifiers ────────────
  static const _allTabDefs = <_TabDef>[
    _TabDef(id: 'dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard),
    _TabDef(id: 'inventory', icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2),
    _TabDef(id: 'shipments', icon: Icons.local_shipping_outlined, selectedIcon: Icons.local_shipping),
    _TabDef(id: 'reports', icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart),
    _TabDef(id: 'settings', icon: Icons.settings_outlined, selectedIcon: Icons.settings),
  ];

  /// Returns the filtered list of tab definitions based on active profile.
  List<_TabDef> _visibleTabs(BuildContext context) {
    final provider = ProfileProvider.maybeOf(context);
    if (provider == null || provider.profile == null) return _allTabDefs;
    final enabled = provider.enabledTabs;
    return _allTabDefs.where((t) => enabled.contains(t.id)).toList();
  }

  /// Returns the label for a tab id.
  String _tabLabel(BuildContext context, String id) {
    final l = AppLocalizations.of(context)!;
    switch (id) {
      case 'dashboard':
        return l.home;
      case 'inventory':
        return l.inventory;
      case 'shipments':
        return l.shipments;
      case 'reports':
        return l.reports;
      case 'settings':
        return l.settings;
      default:
        return id;
    }
  }

  /// Map tab id to its GlobalKey for mobile nav coach marks.
  GlobalKey _mobileNavKey(String id) {
    switch (id) {
      case 'dashboard':
        return _keyDashboardNav;
      case 'inventory':
        return _keyInventoryNav;
      case 'shipments':
        return _keyShipmentsNav;
      case 'reports':
        return _keyReportsNav;
      case 'settings':
        return _keySettingsNav;
      default:
        return GlobalKey();
    }
  }

  /// Map tab id to its GlobalKey for sidebar coach marks.
  GlobalKey _sidebarKey(String id) {
    switch (id) {
      case 'dashboard':
        return _keySidebarDashboard;
      case 'inventory':
        return _keySidebarInventory;
      case 'shipments':
        return _keySidebarShipments;
      case 'reports':
        return _keySidebarReports;
      case 'settings':
        return _keySidebarSettings;
      default:
        return GlobalKey();
    }
  }

  /// Coach-mark accent color per tab id.
  Color _tabAccent(String id) {
    switch (id) {
      case 'dashboard':
        return AppColors.accentBlue;
      case 'inventory':
        return AppColors.accentPurple;
      case 'shipments':
        return AppColors.accentTeal;
      case 'reports':
        return AppColors.accentOrange;
      case 'settings':
        return AppColors.textMuted;
      default:
        return AppColors.accentBlue;
    }
  }

  /// Coach step descriptions (Italian).
  String _tabCoachDesc(String id) {
    switch (id) {
      case 'dashboard':
        return 'Il tuo centro di controllo. Qui vedi il riepilogo completo: '
            'budget, acquisti recenti e andamento.';
      case 'inventory':
        return 'Tutti i tuoi articoli in un posto. Aggiungi acquisti, '
            'gestisci lo stock e tieni traccia dei costi.';
      case 'shipments':
        return 'Traccia ogni pacco automaticamente. Inserisci il tracking '
            'e Vault monitora corriere, stato e notifiche.';
      case 'reports':
        return 'Grafici e statistiche su profitti, vendite e andamento. '
            'Filtra per periodo e vedi come va il business.';
      case 'settings':
        return 'Cambia profilo, lingua, gestisci il tuo account e '
            "personalizza l'app come preferisci.";
      default:
        return '';
    }
  }

  /// Build interactive coach-mark steps targeting real UI elements.
  /// Only includes steps for visible tabs.
  List<CoachStep> _buildCoachSteps(bool isWide) {
    final tabs = _visibleTabs(context);
    final steps = <CoachStep>[];

    for (final tab in tabs) {
      steps.add(CoachStep(
        id: tab.id,
        targetKey: isWide ? _sidebarKey(tab.id) : _mobileNavKey(tab.id),
        title: _tabLabel(context, tab.id),
        description: _tabCoachDesc(tab.id),
        icon: tab.selectedIcon,
        accentColor: _tabAccent(tab.id),
      ));

      // Insert FAB + Notifications steps after inventory in mobile
      if (!isWide && tab.id == 'inventory') {
        steps.add(CoachStep(
          id: 'fab',
          targetKey: _keyFab,
          title: 'Aggiungi Nuovo',
          description:
              'Tocca qui per aggiungere un nuovo articolo al tuo '
              'inventario in modo rapido.',
          icon: Icons.add_circle,
          accentColor: AppColors.accentBlue,
          preferredPosition: TooltipPosition.above,
        ));
      }
    }

    // Add notifications step for mobile (after shipments or at end)
    if (!isWide) {
      steps.add(CoachStep(
        id: 'notifications',
        targetKey: _keyNotifications,
        title: 'Notifiche',
        description:
            'Aggiornamenti sulle spedizioni e avvisi importanti. '
            'Il badge mostra quante ne hai da leggere.',
        icon: Icons.notifications,
        accentColor: AppColors.accentOrange,
        preferredPosition: TooltipPosition.below,
      ));
    }

    return steps;
  }

  void _navigateTo(int index) {
    setState(() {
      _currentIndex = index;
      _showAddItem = false;
      _showAddSale = false;
      _showNotifications = false;
      _editingProduct = null;
      _trackingShipment = null;
    });
  }

  void _showAddItemScreen() {
    setState(() {
      _showAddItem = true;
      _showAddSale = false;
      _showNotifications = false;
      _editingProduct = null;
      _trackingShipment = null;
    });
  }

  void _showAddSaleScreen() {
    setState(() {
      _showAddSale = true;
      _showAddItem = false;
      _showNotifications = false;
      _editingProduct = null;
      _trackingShipment = null;
    });
  }

  void _showEditProductScreen(Product product) {
    setState(() {
      _editingProduct = product;
      _showAddItem = false;
      _showAddSale = false;
      _showNotifications = false;
      _trackingShipment = null;
    });
  }

  void _showTrackingDetail(Shipment shipment) {
    setState(() {
      _trackingShipment = shipment;
      _showAddItem = false;
      _showAddSale = false;
      _showNotifications = false;
      _editingProduct = null;
    });
  }

  void _showNotificationsScreen() {
    setState(() {
      _showNotifications = true;
      _showAddItem = false;
      _showAddSale = false;
      _editingProduct = null;
      _trackingShipment = null;
    });
  }

  void _closeOverlay() {
    setState(() {
      _showAddItem = false;
      _showAddSale = false;
      _showNotifications = false;
      _editingProduct = null;
      _trackingShipment = null;
    });
  }

  Widget _getCurrentScreen(BuildContext context) {
    if (_showNotifications) {
      return NotificationsScreen(onBack: _closeOverlay);
    }
    if (_showAddItem) {
      return AddItemScreen(onBack: _closeOverlay);
    }
    if (_showAddSale) {
      return AddSaleScreen(onBack: _closeOverlay);
    }
    if (_editingProduct != null) {
      return EditProductScreen(
        product: _editingProduct!,
        onBack: _closeOverlay,
        onSaved: () {},
      );
    }
    if (_trackingShipment != null) {
      return TrackingDetailScreen(
        shipment: _trackingShipment!,
        onBack: _closeOverlay,
      );
    }

    final tabs = _visibleTabs(context);
    final safeIndex = _currentIndex < tabs.length ? _currentIndex : 0;
    final tabId = tabs[safeIndex].id;

    switch (tabId) {
      case 'dashboard':
        return DashboardScreen(
          onNewPurchase: _showAddItemScreen,
          onNewSale: _showAddSaleScreen,
        );
      case 'inventory':
        return InventoryScreen(onEditProduct: _showEditProductScreen);
      case 'shipments':
        return ShipmentsScreen(onTrackShipment: _showTrackingDetail);
      case 'reports':
        return const ReportsScreen();
      case 'settings':
        return const SettingsScreen();
      default:
        return DashboardScreen(
          onNewPurchase: _showAddItemScreen,
          onNewSale: _showAddSaleScreen,
        );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Show profile switcher bottom sheet.
  void _showProfileSwitcher(BuildContext context) {
    final provider = ProfileProvider.of(context);
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Seleziona Profilo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...provider.profiles.map((p) {
              final isActive = p.id == provider.profile?.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ScaleOnPress(
                  onTap: () {
                    provider.switchProfile(p.id);
                    Navigator.pop(ctx);
                    setState(() => _currentIndex = 0);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isActive
                          ? p.color.withValues(alpha: 0.15)
                          : AppColors.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? p.color.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(p.icon, color: p.color, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            p.name,
                            style: TextStyle(
                              color: isActive ? Colors.white : AppColors.textSecondary,
                              fontSize: 15,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isActive)
                          Icon(Icons.check_circle, color: p.color, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          isWide ? _buildDesktopLayout() : _buildMobileLayout(),
          // Interactive coach-mark tutorial
          if (_showTutorial)
            CoachMarkOverlay(
              steps: _buildCoachSteps(isWide),
              onComplete: _dismissTutorial,
              onSkip: _dismissTutorial,
            ),
        ],
      ),
      bottomNavigationBar: (!_showTutorial && !isWide) ? _buildBottomNav() : null,
      floatingActionButton: (!_showTutorial && !isWide)
          ? AnimatedFab(key: _keyFab, onTap: _showAddItemScreen)
          : null,
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        _buildSidebar(),
        Expanded(
          child: Column(
            children: [
              _buildDesktopTopBar(),
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
                    key: ValueKey<String>(_screenKey),
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

  String get _screenKey {
    if (_showNotifications) return 'notifications';
    if (_showAddItem) return 'add';
    if (_showAddSale) return 'sale';
    if (_editingProduct != null) return 'edit-${_editingProduct!.id}';
    if (_trackingShipment != null) return 'track-${_trackingShipment!.trackingCode}';
    return '$_currentIndex';
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Column(
        children: [
          _buildMobileTopBar(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: KeyedSubtree(
                key: ValueKey<String>(_screenKey),
                child: _getCurrentScreen(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTopBar() {
    final provider = ProfileProvider.maybeOf(context);
    final profile = provider?.profile;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Profile icon (tappable to switch)
          GestureDetector(
            onTap: () => _showProfileSwitcher(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: profile != null
                    ? LinearGradient(
                        colors: [
                          profile.color,
                          profile.color.withValues(alpha: 0.6),
                        ],
                      )
                    : AppColors.headerGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                profile?.icon ?? Icons.view_in_ar,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _showProfileSwitcher(context),
            child: Text(
              profile?.name ?? 'Vault',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const Spacer(),
          StreamBuilder<int>(
            stream: _firestoreService.getUnreadNotificationCount(),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return GestureDetector(
                key: _keyNotifications,
                onTap: _showNotificationsScreen,
                child: PulsingBadge(
                  count: count,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _showNotifications
                          ? AppColors.accentBlue.withValues(alpha: 0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _showNotifications
                            ? AppColors.accentBlue.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Icon(
                      _showNotifications
                          ? Icons.notifications
                          : Icons.notifications_outlined,
                      color: _showNotifications
                          ? AppColors.accentBlue
                          : AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final tabs = _visibleTabs(context);
    final provider = ProfileProvider.maybeOf(context);
    final profile = provider?.profile;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.navBar,
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.04),
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.headerGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentBlue.withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.view_in_ar,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Vault',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Profile selector in sidebar ──
          if (profile != null && provider != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GestureDetector(
                onTap: () => _showProfileSwitcher(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: profile.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: profile.color.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(profile.icon, color: profile.color, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          profile.name,
                          style: TextStyle(
                            color: profile.color,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.unfold_more,
                        color: profile.color.withValues(alpha: 0.6),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),

          // ── Tab items filtered by profile ──
          ...List.generate(tabs.length, (i) {
            final tab = tabs[i];
            return _SidebarItem(
              key: _sidebarKey(tab.id),
              icon: tab.icon,
              selectedIcon: tab.selectedIcon,
              label: _tabLabel(context, tab.id),
              isSelected: _currentIndex == i && !_showAddItem,
              onTap: () => _navigateTo(i),
            );
          }),

          const Spacer(),
          // System Online
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.accentGreen.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  const PulsingDot(color: AppColors.accentGreen, size: 8),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(context)!.systemOnline,
                    style: const TextStyle(
                      color: AppColors.accentGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDesktopTopBar() {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.04),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Focus(
              onFocusChange: (f) => setState(() => _searchFocused = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _searchFocused
                        ? AppColors.accentBlue.withValues(alpha: 0.5)
                        : Colors.transparent,
                  ),
                  boxShadow: _searchFocused
                      ? [
                          BoxShadow(
                            color: AppColors.accentBlue.withValues(alpha: 0.12),
                            blurRadius: 12,
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: _searchFocused ? AppColors.accentBlue : AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: l.searchItemsReports,
                          hintStyle: TextStyle(color: AppColors.textMuted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '⌘K',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ScaleOnPress(
            onTap: _showAddItemScreen,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.blueButtonGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentBlue.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    l.newItem,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          StreamBuilder<int>(
            stream: _firestoreService.getUnreadNotificationCount(),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return ScaleOnPress(
                onTap: _showNotificationsScreen,
                child: PulsingBadge(
                  count: count,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _showNotifications
                          ? AppColors.accentBlue.withValues(alpha: 0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _showNotifications
                            ? AppColors.accentBlue.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Icon(
                      _showNotifications
                          ? Icons.notifications
                          : Icons.notifications_outlined,
                      color: _showNotifications
                          ? AppColors.accentBlue
                          : AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final tabs = _visibleTabs(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBar,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              return _buildNavItem(
                tab.icon,
                tab.selectedIcon,
                _tabLabel(context, tab.id),
                i,
                key: _mobileNavKey(tab.id),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData selectedIcon, String label, int index, {GlobalKey? key}) {
    final isSelected = _currentIndex == index && !_showAddItem;
    return GestureDetector(
      key: key,
      onTap: () => _navigateTo(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentBlue.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? AppColors.accentBlue : AppColors.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.accentBlue : AppColors.textMuted,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// Tab definition helper
// ──────────────────────────────────────────────────
class _TabDef {
  final String id;
  final IconData icon;
  final IconData selectedIcon;

  const _TabDef({required this.id, required this.icon, required this.selectedIcon});
}

// ──────────────────────────────────────────────────
// Sidebar item with hover effect
// ──────────────────────────────────────────────────
class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected;
    final isHighlighted = isActive || _hovering;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.accentBlue.withValues(alpha: 0.15)
                : _hovering
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? Border.all(
                    color: AppColors.accentBlue.withValues(alpha: 0.2),
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                isActive ? widget.selectedIcon : widget.icon,
                color: isHighlighted ? AppColors.accentBlue : AppColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  color: isHighlighted ? Colors.white : AppColors.textSecondary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
