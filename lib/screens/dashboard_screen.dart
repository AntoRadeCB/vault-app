import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../services/card_catalog_service.dart';
import '../providers/profile_provider.dart';
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
            // 1. Profile + Budget card
            StaggeredFadeSlide(index: 0, child: _buildProfileCard(context)),
            const SizedBox(height: 20),
            // 2. Action buttons
            StaggeredFadeSlide(index: 1, child: _buildActionButtons(context)),
            const SizedBox(height: 20),
            // 3. Inventory Value card
            StaggeredFadeSlide(index: 2, child: _buildInventoryValueCard(context)),
            const SizedBox(height: 16),
            // 4. Quick stats row
            _buildQuickStats(context),
            const SizedBox(height: 24),
            // 5. Recent Activity (unified)
            StaggeredFadeSlide(index: 4, child: _buildRecentActivity(context)),
            const SizedBox(height: 24),
            // 6. Operational Status
            StaggeredFadeSlide(index: 5, child: _buildOperationalStatus(context)),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  PROFILE + BUDGET CARD
  // ════════════════════════════════════════════════════

  Widget _buildProfileCard(BuildContext context) {
    final profile = ProfileProvider.maybeOf(context)?.profile;
    final profileColor = profile?.color ?? AppColors.accentBlue;
    final hasBudget = profile?.hasBudget ?? false;

    if (!hasBudget) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        glowColor: profileColor,
        child: Row(
          children: [_buildProfileHeader(context, profile, profileColor)],
        ),
      );
    }

    // With budget: use StreamBuilder for real-time budget spent
    return StreamBuilder<double>(
      stream: _firestoreService.getBudgetSpentThisMonth(),
      builder: (context, budgetSnap) {
        final spent = budgetSnap.data ?? 0;
        final monthly = profile!.budgetMonthly!;
        final remaining = (monthly - spent).clamp(0.0, monthly);
        // Inverted: 1.0 = full budget available, 0.0 = all spent
        final remainingRatio = (remaining / monthly).clamp(0.0, 1.0);
        final spentRatio = (spent / monthly).clamp(0.0, 1.5);

        return GlassCard(
          padding: const EdgeInsets.all(20),
          glowColor: profileColor,
          child: Column(
            children: [
              Row(
                children: [
                  _buildProfileHeader(context, profile, profileColor),
                  // Budget circular indicator (shows remaining %)
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: CustomPaint(
                      painter: _BudgetCirclePainter(
                        progress: remainingRatio,
                        color: _budgetColor(spentRatio),
                        trackColor: Colors.white.withValues(alpha: 0.06),
                      ),
                      child: Center(
                        child: Text(
                          '€${remaining.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: _budgetColor(spentRatio),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Bar: full = all budget available, empties as you spend
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: remainingRatio,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  color: _budgetColor(spentRatio),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Disponibile: €${remaining.toStringAsFixed(0)} / €${monthly.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    spentRatio >= 1.0
                        ? 'Budget esaurito!'
                        : 'Spesi €${spent.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: spentRatio >= 1.0
                          ? AppColors.accentRed
                          : AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Profile icon + name + item count (reusable in both budget/no-budget layouts)
  Widget _buildProfileHeader(BuildContext context, dynamic profile, Color profileColor) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: profileColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: profileColor.withValues(alpha: 0.3)),
            ),
            child: Icon(
              profile?.icon ?? Icons.inventory_2,
              color: profileColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.name ?? 'Vault',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                StreamBuilder<int>(
                  stream: _firestoreService.getInventoryItemCount(),
                  builder: (context, snap) {
                    final count = snap.data ?? 0;
                    return Row(
                      children: [
                        const PulsingDot(color: AppColors.accentGreen, size: 8),
                        const SizedBox(width: 8),
                        Text(
                          '$count articoli in inventario',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _budgetColor(double progress) {
    if (progress < 0.7) return AppColors.accentGreen;
    if (progress < 0.9) return AppColors.accentOrange;
    return AppColors.accentRed;
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
  //  VALORE INVENTARIO — always visible
  // ════════════════════════════════════════════════════

  Widget _buildInventoryValueCard(BuildContext context) {
    final catalogService = CardCatalogService();

    return StreamBuilder<List<Product>>(
      stream: _firestoreService.getProducts(),
      builder: (context, productSnap) {
        final products = productSnap.data ?? [];
        final cardProducts = products.where((p) => p.isCard).toList();

        if (cardProducts.isNotEmpty) {
          return _buildCardMarketValueContent(catalogService, cardProducts);
        } else {
          return _buildTotalInventoryContent(products);
        }
      },
    );
  }

  /// Card market value (when card products exist)
  Widget _buildCardMarketValueContent(
      CardCatalogService catalogService, List<Product> cardProducts) {
    final totalPaidCost = cardProducts.fold<double>(
        0, (sum, p) => sum + (p.price * p.quantity));
    final totalMarketValue = cardProducts.fold<double>(
        0, (sum, p) => sum + ((p.marketPrice ?? p.price) * p.quantity));

    return FutureBuilder<List<CardBlueprint>>(
      future: _getUpdatedPrices(catalogService, cardProducts),
      builder: (context, priceSnap) {
        double liveMarketValue = totalMarketValue;
        if (priceSnap.hasData && priceSnap.data!.isNotEmpty) {
          final priceMap = <String, double>{};
          for (final card in priceSnap.data!) {
            if (card.marketPrice != null) {
              priceMap[card.id] = card.marketPrice!.cents / 100;
            }
          }
          liveMarketValue = cardProducts.fold<double>(0, (sum, p) {
            final livePrice =
                priceMap[p.cardBlueprintId] ?? p.marketPrice ?? p.price;
            return sum + (livePrice * p.quantity);
          });
        }

        final livePnl = liveMarketValue - totalPaidCost;
        final livePnlPercent =
            totalPaidCost > 0 ? (livePnl / totalPaidCost) * 100 : 0;
        final liveIsPositive = livePnl >= 0;

        return GlassCard(
          padding: const EdgeInsets.all(16),
          glowColor:
              liveIsPositive ? AppColors.accentGreen : AppColors.accentRed,
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
                    child: const Icon(Icons.trending_up,
                        color: Color(0xFFFFD700), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VALORE INVENTARIO',
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (liveIsPositive
                              ? AppColors.accentGreen
                              : AppColors.accentRed)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (liveIsPositive
                                ? AppColors.accentGreen
                                : AppColors.accentRed)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          liveIsPositive
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: liveIsPositive
                              ? AppColors.accentGreen
                              : AppColors.accentRed,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${livePnlPercent.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: liveIsPositive
                                ? AppColors.accentGreen
                                : AppColors.accentRed,
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
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
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
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
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
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          '${liveIsPositive ? "+" : ""}€${livePnl.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: liveIsPositive
                                ? AppColors.accentGreen
                                : AppColors.accentRed,
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
  }

  /// Total inventory value (when no card products exist)
  Widget _buildTotalInventoryContent(List<Product> products) {
    final totalValue =
        products.fold<double>(0, (sum, p) => sum + (p.price * p.quantity));

    return GlassCard(
      padding: const EdgeInsets.all(16),
      glowColor: AppColors.accentBlue,
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
                child: const Icon(Icons.inventory_2,
                    color: Color(0xFFFFD700), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VALORE INVENTARIO',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${products.length} prodotti totali',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '€${totalValue.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
      index: 3,
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
  //  ATTIVITÀ RECENTE — unified sales + purchases
  // ════════════════════════════════════════════════════

  Widget _buildRecentActivity(BuildContext context) {
    return StreamBuilder<List<Sale>>(
      stream: _firestoreService.getSales(),
      builder: (context, salesSnap) {
        return StreamBuilder<List<Purchase>>(
          stream: _firestoreService.getPurchases(),
          builder: (context, purchasesSnap) {
            final sales = salesSnap.data ?? [];
            final purchases = purchasesSnap.data ?? [];

            // Build unified activity list
            final activities = <_ActivityItem>[];
            for (final sale in sales) {
              activities.add(_ActivityItem(
                name: sale.productName,
                amount: sale.profit,
                date: sale.date,
                isSale: true,
              ));
            }
            for (final purchase in purchases) {
              activities.add(_ActivityItem(
                name: purchase.productName,
                amount: purchase.totalCost,
                date: purchase.date,
                isSale: false,
              ));
            }
            activities.sort((a, b) => b.date.compareTo(a.date));
            final recent = activities.take(8).toList();

            return GlassCard(
              padding: const EdgeInsets.all(20),
              glowColor: AppColors.accentPurple,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history,
                          color: AppColors.accentPurple, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Attività Recente',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              AppColors.accentPurple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${activities.length} totali',
                          style: const TextStyle(
                            color: AppColors.accentPurple,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (recent.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'Nessuna attività registrata',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    ...recent.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildActivityRow(item),
                        )),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActivityRow(_ActivityItem item) {
    final isSale = item.isSale;
    final color = isSale ? AppColors.accentGreen : AppColors.accentBlue;
    final icon = isSale ? Icons.arrow_upward : Icons.shopping_cart;

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
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
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
                  _formatDate(item.date),
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            isSale
                ? '+€${item.amount.toStringAsFixed(2)}'
                : '-€${item.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isSale ? AppColors.accentGreen : AppColors.accentRed,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Oggi';
    if (diff.inDays == 1) return 'Ieri';
    if (diff.inDays < 7) return '${diff.inDays}g fa';
    return '${date.day}/${date.month}/${date.year}';
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
                _buildStatusItem(l.lowStockProduct(lowStock.first.name),
                    AppColors.accentOrange),
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

class _ActivityItem {
  final String name;
  final double amount;
  final DateTime date;
  final bool isSale;

  _ActivityItem({
    required this.name,
    required this.amount,
    required this.date,
    required this.isSale,
  });
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

// ──────────────────────────────────────────────────
// Custom painter for the budget circular indicator
// ──────────────────────────────────────────────────
class _BudgetCirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _BudgetCirclePainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    const strokeWidth = 5.0;
    const startAngle = -math.pi / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    // Glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * progress,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BudgetCirclePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
