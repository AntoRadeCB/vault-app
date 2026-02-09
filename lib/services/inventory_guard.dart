import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/ebay_service.dart';

/// Checks if a product has active eBay listings before allowing quantity reduction.
/// Returns true if the operation can proceed, false if blocked.
class InventoryGuard {
  static final EbayService _ebay = EbayService();

  /// Check if reducing quantity is safe. Shows dialog if blocked.
  /// [productId] - Firestore product ID
  /// [currentQty] - current total quantity
  /// [newQty] - desired new quantity
  /// [inventoryQty] - current inventory (selling) quantity
  static Future<bool> canReduceQuantity({
    required BuildContext context,
    required String productId,
    required double currentQty,
    required double newQty,
    required double inventoryQty,
  }) async {
    // If not reducing below inventory qty, always allow
    if (newQty >= inventoryQty) return true;

    // If no inventory qty, always allow
    if (inventoryQty <= 0) return true;

    // Check for active eBay listings
    try {
      final listing = await _ebay.getListingForProduct(productId);
      if (listing != null && listing.status == 'active') {
        if (!context.mounted) return false;
        // Has active listing — block
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
            title: const Text('Inserzione attiva su eBay',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
            content: const Text(
              'Questa carta è in vendita su eBay. Chiudi prima l\'inserzione dal Marketplace per poterla rimuovere.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
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
    } catch (_) {
      // If check fails, allow the operation (don't block on network error)
    }

    return true;
  }

  /// Quick check — for delete operations (quantity going to 0)
  static Future<bool> canDelete({
    required BuildContext context,
    required String productId,
    required double inventoryQty,
  }) async {
    if (inventoryQty <= 0) return true;
    return canReduceQuantity(
      context: context,
      productId: productId,
      currentQty: 1,
      newQty: 0,
      inventoryQty: inventoryQty,
    );
  }
}
