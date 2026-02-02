import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/add_item_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shipments_screen.dart';
import 'screens/tracking_detail_screen.dart';
import 'screens/add_sale_screen.dart';
import 'screens/edit_product_screen.dart';
import 'widgets/animated_widgets.dart';
import 'models/product.dart';
import 'models/shipment.dart';
import 'services/firestore_service.dart';
import 'screens/notifications_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

/// AuthGate: checks auth state and onboarding completion
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _onboardingDone = true; // assume done until proven otherwise

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

        final user = snapshot.data;

        // No user → demo mode, show main shell
        if (user == null) {
          return const MainShell(key: ValueKey('demo'));
        }

        // User logged in → check if onboarding is complete
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, profileSnap) {
            // While loading profile, show a brief loading indicator
            if (profileSnap.connectionState == ConnectionState.waiting &&
                !profileSnap.hasData) {
              return const Scaffold(
                backgroundColor: AppColors.background,
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.accentBlue),
                ),
              );
            }

            final data = profileSnap.data?.data() as Map<String, dynamic>?;
            final onboardingComplete = data?['onboardingComplete'] == true;

            if (!onboardingComplete) {
              return OnboardingScreen(
                onComplete: () {
                  // The StreamBuilder will automatically pick up the change
                  // from Firestore when onboardingComplete is set to true
                },
              );
            }

            return MainShell(key: ValueKey(user.uid));
          },
        );
      },
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
  bool _showAuthOverlay = false;
  Product? _editingProduct;
  Shipment? _trackingShipment;
  final _searchController = TextEditingController();
  bool _searchFocused = false;
  final FirestoreService _firestoreService = FirestoreService();
  bool _demoBannerDismissed = false;

  bool get _isLoggedIn => FirebaseAuth.instance.currentUser != null;

  void _navigateTo(int index) {
    setState(() {
      _currentIndex = index;
      _showAddItem = false;
      _showAddSale = false;
      _showNotifications = false;
      _showAuthOverlay = false;
      _editingProduct = null;
      _trackingShipment = null;
    });
  }

  void _showAddItemScreen() {
    if (!_isLoggedIn) {
      _showDemoSnackbar();
      return;
    }
    setState(() {
      _showAddItem = true;
      _showAddSale = false;
      _showNotifications = false;
      _showAuthOverlay = false;
      _editingProduct = null;
      _trackingShipment = null;
    });
  }

  void _showAddSaleScreen() {
    if (!_isLoggedIn) {
      _showDemoSnackbar();
      return;
    }
    setState(() {
      _showAddSale = true;
      _showAddItem = false;
      _showNotifications = false;
      _showAuthOverlay = false;
      _editingProduct = null;
      _trackingShipment = null;
    });
  }

  void _showEditProductScreen(Product product) {
    if (!_isLoggedIn) {
      _showDemoSnackbar();
      return;
    }
    setState(() {
      _editingProduct = product;
      _showAddItem = false;
      _showAddSale = false;
      _showNotifications = false;
      _showAuthOverlay = false;
      _trackingShipment = null;
    });
  }

  void _showTrackingDetail(Shipment shipment) {
    setState(() {
      _trackingShipment = shipment;
      _showAddItem = false;
      _showAddSale = false;
      _showNotifications = false;
      _showAuthOverlay = false;
      _editingProduct = null;
    });
  }

  void _showNotificationsScreen() {
    setState(() {
      _showNotifications = true;
      _showAddItem = false;
      _showAddSale = false;
      _showAuthOverlay = false;
      _editingProduct = null;
      _trackingShipment = null;
    });
  }

  void _openAuthOverlay() {
    setState(() {
      _showAuthOverlay = true;
      _showAddItem = false;
      _showAddSale = false;
      _showNotifications = false;
      _editingProduct = null;
      _trackingShipment = null;
    });
  }

  void _closeOverlay() {
    setState(() {
      _showAddItem = false;
      _showAddSale = false;
      _showNotifications = false;
      _showAuthOverlay = false;
      _editingProduct = null;
      _trackingShipment = null;
    });
  }

  void _showDemoSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Accedi per salvare le modifiche',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                _openAuthOverlay();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Accedi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.accentOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _getCurrentScreen() {
    if (_showAuthOverlay) {
      return AuthScreen(
        onBack: _closeOverlay,
      );
    }
    if (_showNotifications) {
      return NotificationsScreen(
        onBack: _closeOverlay,
      );
    }
    if (_showAddItem) {
      return AddItemScreen(
        onBack: _closeOverlay,
      );
    }
    if (_showAddSale) {
      return AddSaleScreen(
        onBack: _closeOverlay,
      );
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
    switch (_currentIndex) {
      case 0:
        return DashboardScreen(
          onNewPurchase: _showAddItemScreen,
          onNewSale: _showAddSaleScreen,
        );
      case 1:
        return InventoryScreen(
          onEditProduct: _showEditProductScreen,
        );
      case 2:
        return ShipmentsScreen(
          onTrackShipment: _showTrackingDetail,
        );
      case 3:
        return const ReportsScreen();
      case 4:
        return SettingsScreen(
          onOpenAuth: _openAuthOverlay,
        );
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

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isWide ? _buildDesktopLayout() : _buildMobileLayout(),
      bottomNavigationBar: isWide ? null : _buildBottomNav(),
      floatingActionButton: isWide
          ? null
          : AnimatedFab(onTap: _showAddItemScreen),
    );
  }

  // ─── Demo Banner ───────────────────────────────────
  Widget _buildDemoBanner() {
    if (_isLoggedIn || _demoBannerDismissed) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentOrange.withValues(alpha: 0.15),
            AppColors.accentOrange.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Modalità Demo — Accedi per salvare i tuoi dati',
              style: TextStyle(
                color: AppColors.accentOrange.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _openAuthOverlay,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentOrange.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Text(
                'Accedi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => _demoBannerDismissed = true),
            child: Icon(
              Icons.close,
              color: AppColors.accentOrange.withValues(alpha: 0.5),
              size: 18,
            ),
          ),
        ],
      ),
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
              _buildDemoBanner(),
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
                    child: _getCurrentScreen(),
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
    if (_showAuthOverlay) return 'auth';
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
          _buildDemoBanner(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: KeyedSubtree(
                key: ValueKey<String>(_screenKey),
                child: _getCurrentScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.view_in_ar,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Vault',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          StreamBuilder<int>(
            stream: _firestoreService.getUnreadNotificationCount(),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return GestureDetector(
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
    final l = AppLocalizations.of(context)!;
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
          const SizedBox(height: 32),
          _SidebarItem(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            label: l.dashboard,
            isSelected: _currentIndex == 0 && !_showAddItem && !_showAuthOverlay,
            onTap: () => _navigateTo(0),
          ),
          _SidebarItem(
            icon: Icons.inventory_2_outlined,
            selectedIcon: Icons.inventory_2,
            label: l.inventory,
            isSelected: _currentIndex == 1 && !_showAddItem && !_showAuthOverlay,
            onTap: () => _navigateTo(1),
          ),
          _SidebarItem(
            icon: Icons.local_shipping_outlined,
            selectedIcon: Icons.local_shipping,
            label: l.shipments,
            isSelected: _currentIndex == 2 && !_showAddItem && !_showAuthOverlay,
            onTap: () => _navigateTo(2),
          ),
          _SidebarItem(
            icon: Icons.bar_chart_outlined,
            selectedIcon: Icons.bar_chart,
            label: l.reports,
            isSelected: _currentIndex == 3 && !_showAddItem && !_showAuthOverlay,
            onTap: () => _navigateTo(3),
          ),
          _SidebarItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: l.settings,
            isSelected: _currentIndex == 4 && !_showAddItem && !_showAuthOverlay,
            onTap: () => _navigateTo(4),
          ),
          const Spacer(),
          // System Online
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isLoggedIn
                    ? AppColors.accentGreen.withValues(alpha: 0.08)
                    : AppColors.accentOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isLoggedIn
                      ? AppColors.accentGreen.withValues(alpha: 0.15)
                      : AppColors.accentOrange.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  PulsingDot(
                    color: _isLoggedIn ? AppColors.accentGreen : AppColors.accentOrange,
                    size: 8,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isLoggedIn ? l.systemOnline : 'Demo Mode',
                      style: TextStyle(
                        color: _isLoggedIn ? AppColors.accentGreen : AppColors.accentOrange,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
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
    final l = AppLocalizations.of(context)!;
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
            children: [
              _buildNavItem(Icons.dashboard_outlined, Icons.dashboard, l.home, 0),
              _buildNavItem(Icons.inventory_2_outlined, Icons.inventory_2, l.inventory, 1),
              _buildNavItem(Icons.local_shipping_outlined, Icons.local_shipping, l.shipments, 2),
              _buildNavItem(Icons.bar_chart_outlined, Icons.bar_chart, l.reports, 3),
              _buildNavItem(Icons.settings_outlined, Icons.settings, l.settings, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData selectedIcon, String label, int index) {
    final isSelected = _currentIndex == index && !_showAddItem && !_showAuthOverlay;
    return GestureDetector(
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
// Sidebar item with hover effect
// ──────────────────────────────────────────────────
class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
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
