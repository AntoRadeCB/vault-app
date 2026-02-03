import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/shipment.dart';

/// Centralised navigation state for the MainShell.
///
/// Manages which screen/overlay is currently visible and provides
/// typed methods for each transition.  Extends [ChangeNotifier] so
/// widgets can rebuild via [ListenableBuilder] when the state changes.
class NavigationController extends ChangeNotifier {
  int _currentIndex = 0;
  bool _showAddItem = false;
  bool _showAddSale = false;
  bool _showNotifications = false;
  Product? _editingProduct;
  Shipment? _trackingShipment;

  // ─── Getters ────────────────────────────────────
  int get currentIndex => _currentIndex;
  bool get isShowingAddItem => _showAddItem;
  bool get isShowingAddSale => _showAddSale;
  bool get isShowingNotifications => _showNotifications;
  Product? get editingProduct => _editingProduct;
  Shipment? get trackingShipment => _trackingShipment;

  /// Whether any overlay screen (add item, add sale, etc.) is visible.
  bool get hasOverlay =>
      isShowingAddItem ||
      isShowingAddSale ||
      isShowingNotifications ||
      _editingProduct != null ||
      _trackingShipment != null;

  /// A unique key describing the current visible screen,
  /// used as the [ValueKey] for [AnimatedSwitcher].
  String get screenKey {
    if (isShowingNotifications) return 'notifications';
    if (isShowingAddItem) return 'add';
    if (isShowingAddSale) return 'sale';
    if (_editingProduct != null) return 'edit-${_editingProduct!.id}';
    if (_trackingShipment != null) {
      return 'track-${_trackingShipment!.trackingCode}';
    }
    return '$_currentIndex';
  }

  // ─── Actions ────────────────────────────────────

  void navigateTo(int index) {
    _currentIndex = index;
    _clearOverlays();
    notifyListeners();
  }

  void showAddItem() {
    _clearOverlays();
    _showAddItem = true;
    notifyListeners();
  }

  void showAddSale() {
    _clearOverlays();
    _showAddSale = true;
    notifyListeners();
  }

  void showEditProduct(Product product) {
    _clearOverlays();
    _editingProduct = product;
    notifyListeners();
  }

  void showTrackingDetail(Shipment shipment) {
    _clearOverlays();
    _trackingShipment = shipment;
    notifyListeners();
  }

  void showNotificationsScreen() {
    _clearOverlays();
    _showNotifications = true;
    notifyListeners();
  }

  void closeOverlay() {
    _clearOverlays();
    notifyListeners();
  }

  /// Returns `true` (blocked) if demo mode – the caller should show
  /// the auth prompt instead. Returns `false` if the action is allowed.
  bool guardAuth(bool isDemoMode) => isDemoMode;

  // ─── Internal ───────────────────────────────────

  void _clearOverlays() {
    _showAddItem = false;
    _showAddSale = false;
    _showNotifications = false;
    _editingProduct = null;
    _trackingShipment = null;
  }
}
