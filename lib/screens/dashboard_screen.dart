import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../services/card_catalog_service.dart';
import '../models/product.dart';
import '../models/card_blueprint.dart';
import '../models/sale.dart';
import '../models/purchase.dart';
import '../l10n/app_localizations.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback? onNewPurchase;
  final VoidCallback? onNewSale;
  final FirestoreService _firestoreService = FirestoreService();

  DashboardScreen({super.key, this.onNewPurchase, this.onNewSale});

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StaggeredFadeSlide(index: 0, child: _buildHeader(context)),
            const SizedBox(height: 24),
            _buildMainStatCards(context),
            const SizedBox(height: 12),
            StaggeredFadeSlide(index: 5, child: _buildMarketValueCard(context)),
            const SizedBox(height: 16),
            _buildQuickStats(context),
            const SizedBox(height: 24),
            StaggeredFadeSlide(index: 7, child: _buildActionButtons(context)),
            const SizedBox(height: 24),
            StaggeredFadeSlide(index: 8, child: _buildRecentSales(context)),
            const SizedBox(height: 24),
            StaggeredFadeSlide(index: 9, child: _buildRecentPurchases(context)),
            const SizedBox(height: 24),
            StaggeredFadeSlide(index: 10, child: _buildOperationalStatus(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GlassCard(
      padding: const EdgeInsets.all(20),
      glowColor: AppColors.accentPurple,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.resellingVinted2025,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const PulsingDot(color: AppColors.accentGreen, size: 8),
                    const SizedBox(width: 8),
                    Text(
                      l.online,
                      style: const TextStyle(
                        color: AppColors.accentGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Live inventory count badge
          StreamBuilder<int>(
            stream: _firestoreService.getInventoryItemCount(),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accentBlue.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inventory_2, color: AppColors.accentBlue, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      l.nItems(count),
                      style: const TextStyle(
                        color: AppColors.accentBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  MAIN 4 STAT CARDS — all from Firestore real-time
  // ════════════════════════════════════════════════════

  Widget _buildMainStatCards(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return StreamBuilder<List<Product>>(
      stream: _firestoreService.getProducts(),
      builder: (context, productSnap) {
        final products = productSnap.data ?? [];
        final capitaleImmobilizzato = products
            .where((p) => p.status == ProductStatus.inInventory)
            .fold<double>(0, (sum, p) => sum + (p.price * p.quantity));
        final ordiniInArrivo = products
            .where((p) => p.status == ProductStatus.shipped)
            .fold<double>(0, (sum, p) => sum + (p.price * p.quantity));
        final capitaleSpedito = products
            .where((p) => p.status == ProductStatus.listed)
            .fold<double>(0, (sum, p) => sum + (p.price * p.quantity));

        return StreamBuilder<double>(
          stream: _firestoreService.getProfittoConsolidato(),
          builder: (context, profitSnap) {
            final profitto = profitSnap.data ?? 0;

            final cards = [
              _StatData(l.capitaleImmobilizzato, capitaleImmobilizzato, '€',
                  Icons.lock_outline, AppColors.accentBlue),
              _StatData(l.ordiniInArrivo, ordiniInArrivo, '€',
                  Icons.local_shipping_outlined, AppColors.accentTeal),
              _StatData(l.capitaleSpedito, capitaleSpedito, '€',
                  Icons.send_outlined, AppColors.accentOrange),
              _StatData(l.profittoConsolidato, profitto, '€',
                  Icons.trending_up, AppColors.accentGreen),
            ];

            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: List.generate(cards.length, (i) {
                final c = cards[i];
                return StaggeredFadeSlide(
                  index: i + 1,
                  child: HoverLiftCard(
                    child: GlassCard(
                      glowColor: c.color,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(c.icon, color: c.color, size: 14),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  c.title.toUpperCase(),
                                  style: TextStyle(
                                    color: c.color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          CountUpText(
                            prefix: c.prefix,
                            value: c.value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }

  // ════════════════════════════════════════════════════
  //  MARKET VALUE CARD — live card market prices
  // ════════════════════════════════════════════════════

  Widget _buildMarketValueCard(BuildContext context) {
    final catalogService = CardCatalogService();

    return StreamBuilder<List<Product>>(
      stream: _firestoreService.getProducts(),
      builder: (context, productSnap) {
        final products = productSnap.data ?? [];
        final cardProducts = products.where((p) => p.isCard).toList();

        if (cardProducts.isEmpty) return const SizedBox.shrink();

        // Calculate totals
        final totalPaidCost = cardProducts.fold<double>(
            0, (sum, p) => sum + (p.price * p.quantity));
        final totalMarketValue = cardProducts.fold<double>(
            0, (sum, p) => sum + ((p.marketPrice ?? p.price) * p.quantity));
        final pnl = totalMarketValue - totalPaidCost;
        final pnlPercent = totalPaidCost > 0 ? (pnl / totalPaidCost) * 100 : 0;
        final isPositive = pnl >= 0;

        return FutureBuilder<List<CardBlueprint>>(
          future: _getUpdatedPrices(catalogService, cardProducts),
          builder: (context, priceSnap) {
            // If fresh prices loaded, recalculate
            double liveMarketValue = totalMarketValue;
            if (priceSnap.hasData && priceSnap.data!.isNotEmpty) {
              final priceMap = <String, double>{};
              for (final card in priceSnap.data!) {
                if (card.marketPrice != null) {
                  priceMap[card.id] = card.marketPrice!.cents / 100;
                }
              }
              liveMarketValue = cardProducts.fold<double>(0, (sum, p) {
                final livePrice = priceMap[p.cardBlueprintId] ?? p.marketPrice ?? p.price;
                return sum + (livePrice * p.quantity);
              });
            }

            final livePnl = liveMarketValue - totalPaidCost;
            final livePnlPercent = totalPaidCost > 0
                ? (livePnl / totalPaidCost) * 100 : 0;
            final liveIsPositive = livePnl >= 0;

            return GlassCard(
              padding: const EdgeInsets.all(16),
              glowColor: liveIsPositive ? AppColors.accentGreen : AppColors.accentRed,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.trending_up, color: Color(0xFFFFD700), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VALORE DI MERCATO CARTE',
                              style: TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${cardProducts.length} carte in inventario',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // P&L badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (liveIsPositive ? AppColors.accentGreen : AppColors.accentRed)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (liveIsPositive ? AppColors.accentGreen : AppColors.accentRed)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              liveIsPositive ? Icons.arrow_upward : Icons.arrow_downward,
                              color: liveIsPositive ? AppColors.accentGreen : AppColors.accentRed,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${livePnlPercent.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: liveIsPositive ? AppColors.accentGreen : AppColors.accentRed,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Valore Mercato',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(
                              '€${liveMarketValue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Costo Acquisto',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(
                              '€${totalPaidCost.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('P&L',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(
                              '${liveIsPositive ? "+" : ""}€${livePnl.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: liveIsPositive ? AppColors.accentGreen : AppColors.accentRed,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<CardBlueprint>> _getUpdatedPrices(
      CardCatalogService catalog, List<Product> cardProducts) async {
    try {
      final cards = await catalog.getAllCards();
      final ids = cardProducts
          .where((p) => p.cardBlueprintId != null)
          .map((p) => p.cardBlueprintId!)
          .toSet();
      return cards.where((c) => ids.contains(c.id)).toList();
    } catch (_) {
      return [];
    }
  }

  // ════════════════════════════════════════════════════
  //  QUICK STATS ROW — acquisti, vendite, ROI
  // ════════════════════════════════════════════════════

  Widget _buildQuickStats(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return StaggeredFadeSlide(
      index: 5,
      child: Row(
        children: [
          Expanded(
            child: StreamBuilder<double>(
              stream: _firestoreService.getTotalSpent(),
              builder: (context, snap) {
                return _QuickStatChip(
                  label: l.totalSpent,
                  value: '€${(snap.data ?? 0).toStringAsFixed(0)}',
                  icon: Icons.shopping_cart_outlined,
                  color: AppColors.accentRed,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StreamBuilder<double>(
              stream: _firestoreService.getTotalRevenue(),
              builder: (context, snap) {
                return _QuickStatChip(
                  label: l.totalRevenue,
                  value: '€${(snap.data ?? 0).toStringAsFixed(0)}',
                  icon: Icons.payments_outlined,
                  color: AppColors.accentGreen,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StreamBuilder<double>(
              stream: _firestoreService.getAverageProfitPerSale(),
              builder: (context, snap) {
                final avg = snap.data ?? 0;
                return _QuickStatChip(
                  label: l.avgProfit,
                  value: '€${avg.toStringAsFixed(1)}',
                  icon: Icons.analytics_outlined,
                  color: AppColors.accentPurple,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  ACTION BUTTONS
  // ════════════════════════════════════════════════════

  Widget _buildActionButtons(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: ShimmerButton(
            baseGradient: AppColors.blueButtonGradient,
            onTap: () => onNewPurchase?.call(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_shopping_cart, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l.newPurchase,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ShimmerButton(
            baseGradient: const LinearGradient(
              colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
            ),
            onTap: () => onNewSale?.call(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sell_outlined, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l.registerSale,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════
  //  RECENT SALES — live from Firestore
  // ════════════════════════════════════════════════════

  Widget _buildRecentSales(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return StreamBuilder<List<Sale>>(
      stream: _firestoreService.getSales(),
      builder: (context, snapshot) {
        final sales = snapshot.data ?? [];
        return GlassCard(
          padding: const EdgeInsets.all(20),
          glowColor: AppColors.accentGreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sell, color: AppColors.accentGreen, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    l.recentSales,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l.nTotal(sales.length),
                      style: const TextStyle(
                        color: AppColors.accentGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (sales.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      l.noSalesRegistered,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    ),
                  ),
                )
              else
                ...sales.take(5).map((sale) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SaleRow(sale: sale),
                    )),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════
  //  RECENT PURCHASES — live from Firestore
  // ════════════════════════════════════════════════════

  Widget _buildRecentPurchases(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return StreamBuilder<List<Purchase>>(
      stream: _firestoreService.getPurchases(),
      builder: (context, snapshot) {
        final purchases = snapshot.data ?? [];
        return GlassCard(
          padding: const EdgeInsets.all(20),
          glowColor: AppColors.accentBlue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_cart, color: AppColors.accentBlue, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    l.recentPurchases,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l.nTotal(purchases.length),
                      style: const TextStyle(
                        color: AppColors.accentBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (purchases.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      l.noPurchasesRegistered,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    ),
                  ),
                )
              else
                ...purchases.take(5).map((purchase) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PurchaseRow(purchase: purchase),
                    )),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════
  //  OPERATIONAL STATUS
  // ════════════════════════════════════════════════════

  Widget _buildOperationalStatus(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return StreamBuilder<List<Product>>(
      stream: _firestoreService.getProducts(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        final shippedCount =
            products.where((p) => p.status == ProductStatus.shipped).length;
        final listedCount =
            products.where((p) => p.status == ProductStatus.listed).length;
        final lowStock = products.where((p) => p.quantity <= 1).toList();

        return GlassCard(
          padding: const EdgeInsets.all(20),
          glowColor: AppColors.accentBlue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.operationalStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (shippedCount > 0)
                _buildStatusItem(
                    l.nShipmentsInTransit(shippedCount), AppColors.accentBlue),
              if (shippedCount > 0) const SizedBox(height: 12),
              if (listedCount > 0)
                _buildStatusItem(
                    l.nProductsOnSale(listedCount), AppColors.accentOrange),
              if (listedCount > 0) const SizedBox(height: 12),
              if (lowStock.isNotEmpty)
                _buildStatusItem(
                    l.lowStockProduct(lowStock.first.name), AppColors.accentOrange),
              if (lowStock.isNotEmpty) const SizedBox(height: 12),
              if (shippedCount == 0 && listedCount == 0 && lowStock.isEmpty)
                _buildStatusItem(l.noActiveAlerts, AppColors.accentGreen),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusItem(String text, Color dotColor) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: dotColor.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────
// Helper models & widgets
// ──────────────────────────────────────────────────

class _StatData {
  final String title;
  final double value;
  final String prefix;
  final IconData icon;
  final Color color;

  _StatData(this.title, this.value, this.prefix, this.icon, this.color);
}

class _QuickStatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _QuickStatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  final Sale sale;
  const _SaleRow({required this.sale});

  @override
  Widget build(BuildContext context) {
    final profit = sale.profit;
    final isPositive = profit >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isPositive ? AppColors.accentGreen : AppColors.accentRed)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              color: isPositive ? AppColors.accentGreen : AppColors.accentRed,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.productName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Venduto a €${sale.salePrice.toStringAsFixed(0)} · Costo €${sale.purchasePrice.toStringAsFixed(0)}${sale.fees > 0 ? ' · Fee €${sale.fees.toStringAsFixed(0)}' : ''}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}€${profit.toStringAsFixed(2)}',
            style: TextStyle(
              color: isPositive ? AppColors.accentGreen : AppColors.accentRed,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseRow extends StatelessWidget {
  final Purchase purchase;
  const _PurchaseRow({required this.purchase});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.add_shopping_cart,
              color: AppColors.accentBlue,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purchase.productName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Qta: ${purchase.quantity.toInt()} · ${purchase.workspace}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '-€${purchase.totalCost.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.accentRed,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
