import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/ebay_service.dart';
import '../models/ebay_listing.dart';

/// Checks if a product has active marketplace listings before allowing quantity reduction.
/// Only blocks when the remaining quantity would go below the actually listed quantity.
class InventoryGuard {
  static final EbayService _ebay = EbayService();

  /// Get total listed quantity for a product across all non-ended listings
  static Future<int> _getListedQty(String productId) async {
    try {
      final listings = await _ebay.getListings();
      int total = 0;
      for (final l in listings) {
        if (l.productId == productId && l.status != 'ended') {
          total += l.quantity;
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Check if reducing quantity is safe. Shows dialog if blocked.
  /// [productId] - Firestore product ID
  /// [currentQty] - current total quantity  
  /// [newQty] - desired new quantity
  /// [inventoryQty] - current inventory (selling pool) quantity
  static Future<bool> canReduceQuantity({
    required BuildContext context,
    required String productId,
    required double currentQty,
    required double newQty,
    required double inventoryQty,
  }) async {
    final listedQty = await _getListedQty(productId);
    
    debugPrint('[InventoryGuard] productId=$productId newQty=$newQty invQty=$inventoryQty listedQty=$listedQty');

    // If nothing is actually listed on any marketplace, allow
    if (listedQty <= 0) return true;

    // If remaining quantity stays >= listed quantity, allow
    if (newQty >= listedQty) return true;

    // Would go below listed quantity — block
    if (!context.mounted) return false;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accentOrange.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.storefront, color: AppColors.accentOrange, size: 28),
        ),
        title: const Text('Oggetto in vendita',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text(
          'Hai $listedQty ${listedQty == 1 ? "copia in vendita" : "copie in vendita"} su eBay.\n\nChiudi prima le inserzioni dal Marketplace per poter ridurre la quantità.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ho capito',
                style: TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return false;
  }

  /// Quick check — for delete operations (quantity going to 0)
  static Future<bool> canDelete({
    required BuildContext context,
    required String productId,
    required double inventoryQty,
  }) async {
    return canReduceQuantity(
      context: context,
      productId: productId,
      currentQty: 1,
      newQty: 0,
      inventoryQty: inventoryQty,
    );
  }
}
