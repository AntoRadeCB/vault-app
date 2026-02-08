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
  final FirestoreService _firestoreService = FirestoreService();
  final VoidCallback? onAuthRequired;
  BuildContext? _contextRef;

  DashboardScreen({super.key, this.onAuthRequired});

  @override
  Widget build(BuildContext context) {
    _contextRef = context;
    return AuroraBackground(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Demo mode banner
            if (FirestoreService.demoMode) ...[
              GestureDetector(
                onTap: () => onAuthRequired?.call(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Modalità Demo — Registrati per salvare i dati',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
                    ],
                  ),
                ),
              ),
            ],

            // 1. Portfolio Hero Card
            StaggeredFadeSlide(index: 0, child: _buildPortfolioHero(context)),
            const SizedBox(height: 16),

            // 2. Quick Stats Row
            _buildQuickStats(context),
            const SizedBox(height: 16),

            // 3. Sealed vs Opened
            StaggeredFadeSlide(index: 2, child: _buildSealedVsOpenedStat(context)),
            const SizedBox(height: 20),

            // 4. Top Cards Preview
            StaggeredFadeSlide(index: 3, child: _buildTopCardsPreview(context)),
            const SizedBox(height: 20),

            // 5. Recent Activity
            StaggeredFadeSlide(index: 4, child: _buildRecentActivity(context)),
            const SizedBox(height: 20),

            // 6. Operational Status
            StaggeredFadeSlide(index: 5, child: _buildOperationalStatus(context)),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  PORTFOLIO HERO — the wow card
  // ════════════════════════════════════════════════════

  Widget _buildPortfolioHero(BuildContext context) {
    final profile = ProfileProvider.maybeOf(context)?.profile;
    final profileColor = profile?.color ?? AppColors.accentBlue;
    final hasBudget = profile?.hasBudget ?? false;
    final catalogService = CardCatalogService();

    return StreamBuilder<List<Product>>(
      stream: _firestoreService.getProducts(),
      builder: (context, productSnap) {
        _contextRef = context;
        final products = productSnap.data ?? [];
        final cardProducts = products.where((p) => p.isCard).toList();
        final nonCardValue = products
            .where((p) => p.kind != ProductKind.singleCard)
            .fold<double>(0, (sum, p) => sum + (p.price * p.quantity));

        // Calculate values
        double totalMarketValue = 0;
        double totalPaidCost = 0;
        double inventoryValue = 0;

        if (cardProducts.isNotEmpty) {
          totalPaidCost = cardProducts.fold<double>(0, (sum, p) => sum + (p.price * p.quantity));
          totalMarketValue = cardProducts.fold<double>(0, (sum, p) => sum + ((p.marketPrice ?? p.price) * p.quantity));
          inventoryValue = cardProducts.fold<double>(0, (sum, p) {
            if (p.inventoryQty <= 0) return sum;
            final sellPrice = p.sellPrice ?? p.marketPrice ?? p.price;
            return sum + (sellPrice * p.inventoryQty);
          }) + nonCardValue;
        } else {
          totalMarketValue = products.fold<double>(0, (sum, p) => sum + (p.price * p.quantity));
          totalPaidCost = totalMarketValue;
          inventoryValue = nonCardValue;
        }

        final pnl = totalMarketValue - totalPaidCost;
        final pnlPercent = totalPaidCost > 0 ? (pnl / totalPaidCost) * 100 : 0.0;
        final isPositive = pnl >= 0;
        final pnlColor = isPositive ? AppColors.accentGreen : AppColors.accentRed;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1a1a35),
                const Color(0xFF0f1528),
              ],
            ),
            border: Border.all(
              color: profileColor.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: profileColor.withValues(alpha: 0.08),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Subtle gradient accent in corner
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          profileColor.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row: profile + P&L badge
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: profileColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: profileColor.withValues(alpha: 0.25)),
                            ),
                            child: Icon(
                              profile?.icon ?? Icons.inventory_2,
                              color: profileColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile?.name ?? 'Vault',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const PulsingDot(color: AppColors.accentGreen, size: 6),
                                    const SizedBox(width: 6),
                                    StreamBuilder<int>(
                                      stream: _firestoreService.getInventoryItemCount(),
                                      builder: (context, snap) {
                                        final count = snap.data ?? 0;
                                        return Text(
                                          '$count carte',
                                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (cardProducts.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: pnlColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: pnlColor.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPositive ? Icons.trending_up : Icons.trending_down,
                                    color: pnlColor,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${isPositive ? "+" : ""}${pnlPercent.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: pnlColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Main value
                      const Text(
                        'VALORE COLLEZIONE',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '€${totalMarketValue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          height: 1,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Divider
                      Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),

                      const SizedBox(height: 16),

                      // Bottom stats row
                      Row(
                        children: [
                          _buildHeroStat(
                            'Investito',
                            '€${totalPaidCost.toStringAsFixed(0)}',
                            AppColors.textSecondary,
                          ),
                          _buildHeroDivider(),
                          _buildHeroStat(
                            'Inventario',
                            '€${inventoryValue.toStringAsFixed(0)}',
                            AppColors.accentTeal,
                          ),
                          _buildHeroDivider(),
                          _buildHeroStat(
                            'P&L',
                            '${isPositive ? "+" : ""}€${pnl.toStringAsFixed(0)}',
                            pnlColor,
                          ),
                        ],
                      ),

                      // Budget bar (if enabled)
                      if (hasBudget) ...[
                        const SizedBox(height: 16),
                        _buildBudgetSection(context, profile!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroDivider() {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white.withValues(alpha: 0.06),
    );
  }

  Widget _buildBudgetSection(BuildContext context, dynamic profile) {
    return StreamBuilder<double>(
      stream: _firestoreService.getBudgetSpentThisMonth(),
      builder: (context, budgetSnap) {
        final spent = budgetSnap.data ?? 0;
        final monthly = profile.budgetMonthly!;
        final remaining = (monthly - spent).clamp(0.0, monthly);
        final spentRatio = (spent / monthly).clamp(0.0, 1.5);
        final remainingRatio = (remaining / monthly).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.savings_outlined, color: _budgetColor(spentRatio), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Budget mensile',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Text(
                    '€${remaining.toStringAsFixed(0)} / €${monthly.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: _budgetColor(spentRatio),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: remainingRatio,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  color: _budgetColor(spentRatio),
                  minHeight: 3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _budgetColor(double progress) {
    if (progress < 0.7) return AppColors.accentGreen;
    if (progress < 0.9) return AppColors.accentOrange;
    return AppColors.accentRed;
  }

  // ════════════════════════════════════════════════════
  //  QUICK STATS
  // ════════════════════════════════════════════════════

  Widget _buildQuickStats(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return StaggeredFadeSlide(
      index: 1,
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
  //  SEALED vs OPENED
  // ════════════════════════════════════════════════════

  Widget _buildSealedVsOpenedStat(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: _firestoreService.getProducts(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        final sealable = products.where((p) => p.kind != ProductKind.singleCard).toList();
        if (sealable.isEmpty) return const SizedBox.shrink();

        final sealed = sealable.where((p) => !p.isOpened).length;
        final opened = sealable.where((p) => p.isOpened).length;
        final total = sealed + opened;
        final sealedRatio = total > 0 ? sealed / total : 0.5;

        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.lock, color: AppColors.accentOrange, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          '$sealed sigillati',
                          style: const TextStyle(color: AppColors.accentOrange, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(Icons.inventory_2, color: AppColors.accentGreen, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          '$opened aperti',
                          style: const TextStyle(color: AppColors.accentGreen, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 4,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (sealedRatio * 100).round().clamp(1, 99),
                        child: Container(color: AppColors.accentOrange.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: ((1 - sealedRatio) * 100).round().clamp(1, 99),
                        child: Container(color: AppColors.accentGreen.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════
  //  TOP CARDS PREVIEW — horizontal scroll of most valuable
  // ════════════════════════════════════════════════════

  Widget _buildTopCardsPreview(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: _firestoreService.getProducts(),
      builder: (context, snap) {
        final products = (snap.data ?? [])
            .where((p) => p.isCard && p.cardImageUrl != null)
            .toList();
        if (products.isEmpty) return const SizedBox.shrink();

        // Sort by market value descending
        products.sort((a, b) =>
            ((b.marketPrice ?? b.price) * b.quantity)
                .compareTo((a.marketPrice ?? a.price) * a.quantity));
        final topCards = products.take(8).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.diamond_outlined, color: Color(0xFFFFD700), size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Carte di Valore',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${products.length} carte',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 165,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: topCards.length,
                itemBuilder: (context, i) {
                  final card = topCards[i];
                  final value = (card.marketPrice ?? card.price) * card.quantity;
                  return Padding(
                    padding: EdgeInsets.only(right: i < topCards.length - 1 ? 10 : 0),
                    child: _buildTopCardItem(card, value),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopCardItem(Product card, double value) {
    Color getRarityColor(String? rarity) {
      switch (rarity?.toLowerCase()) {
        case 'common': return const Color(0xFF9E9E9E);
        case 'uncommon': return const Color(0xFF4CAF50);
        case 'rare': return const Color(0xFF2196F3);
        case 'epic': return const Color(0xFFAB47BC);
        case 'alternate art': return const Color(0xFFFFD700);
        case 'promo': return const Color(0xFFFF6B35);
        case 'showcase': return const Color(0xFFE91E63);
        default: return AppColors.accentBlue;
      }
    }

    final rarityColor = getRarityColor(card.cardRarity);

    return Container(
      width: 105,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: rarityColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          // Card image
          Container(
            height: 105,
            width: 105,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              child: Image.network(
                card.cardImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: rarityColor.withValues(alpha: 0.08),
                  child: Icon(Icons.style, color: rarityColor.withValues(alpha: 0.4), size: 28),
                ),
              ),
            ),
          ),
          // Value label
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    card.name,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '€${value.toStringAsFixed(2)}',
                    style: TextStyle(color: rarityColor, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  RECENT ACTIVITY
  // ════════════════════════════════════════════════════

  Widget _buildRecentActivity(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: _firestoreService.getProducts(),
      builder: (context, productsSnap) {
        final imageMap = <String, String>{};
        for (final p in productsSnap.data ?? []) {
          final imgUrl = p.displayImageUrl;
          if (imgUrl.isNotEmpty) {
            imageMap[p.name.toLowerCase()] = imgUrl;
          }
        }

        return StreamBuilder<List<Sale>>(
          stream: _firestoreService.getSales(),
          builder: (context, salesSnap) {
            return StreamBuilder<List<Purchase>>(
              stream: _firestoreService.getPurchases(),
              builder: (context, purchasesSnap) {
                final sales = salesSnap.data ?? [];
                final purchases = purchasesSnap.data ?? [];

                final activities = <_ActivityItem>[];
                for (final sale in sales) {
                  activities.add(_ActivityItem(
                    name: sale.productName,
                    amount: sale.profit,
                    date: sale.date,
                    isSale: true,
                    imageUrl: imageMap[sale.productName.toLowerCase()],
                  ));
                }
                for (final purchase in purchases) {
                  activities.add(_ActivityItem(
                    name: purchase.productName,
                    amount: purchase.totalCost,
                    date: purchase.date,
                    isSale: false,
                    imageUrl: imageMap[purchase.productName.toLowerCase()],
                  ));
                }
                activities.sort((a, b) => b.date.compareTo(a.date));
                final recent = activities.take(6).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.history, color: AppColors.accentPurple, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'Attività Recente',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          if (activities.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accentPurple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${activities.length}',
                                style: const TextStyle(color: AppColors.accentPurple, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (recent.isEmpty)
                      GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_outlined, color: AppColors.textMuted.withValues(alpha: 0.4), size: 36),
                              const SizedBox(height: 12),
                              const Text(
                                'Nessuna attività registrata',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Le tue vendite e acquisti appariranno qui',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...recent.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _buildActivityRow(item),
                          )),
                  ],
                );
              },
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
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: hasImage ? 38 : 34,
            height: hasImage ? 50 : 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(hasImage ? 6 : 8),
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(icon, color: color, size: 16),
                    ),
                  )
                : Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(item.date),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
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
              fontWeight: FontWeight.w700,
              fontSize: 13,
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
        final shippedCount = products.where((p) => p.status == ProductStatus.shipped).length;
        final listedCount = products.where((p) => p.status == ProductStatus.listed).length;
        final lowStock = products.where((p) => p.quantity <= 1).toList();

        final hasAlerts = shippedCount > 0 || listedCount > 0 || lowStock.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Row(
                children: [
                  Icon(
                    hasAlerts ? Icons.notifications_active_outlined : Icons.check_circle_outline,
                    color: hasAlerts ? AppColors.accentOrange : AppColors.accentGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.operationalStatus,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            GlassCard(
              padding: const EdgeInsets.all(16),
              glowColor: hasAlerts ? AppColors.accentOrange : AppColors.accentGreen,
              child: Column(
                children: [
                  if (shippedCount > 0)
                    _buildStatusItem(l.nShipmentsInTransit(shippedCount), AppColors.accentBlue, Icons.local_shipping_outlined),
                  if (shippedCount > 0 && (listedCount > 0 || lowStock.isNotEmpty))
                    const SizedBox(height: 10),
                  if (listedCount > 0)
                    _buildStatusItem(l.nProductsOnSale(listedCount), AppColors.accentOrange, Icons.storefront_outlined),
                  if (listedCount > 0 && lowStock.isNotEmpty)
                    const SizedBox(height: 10),
                  if (lowStock.isNotEmpty)
                    _buildStatusItem(l.lowStockProduct(lowStock.first.name), AppColors.accentOrange, Icons.warning_amber_outlined),
                  if (!hasAlerts)
                    _buildStatusItem(l.noActiveAlerts, AppColors.accentGreen, Icons.check_circle_outline),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusItem(String text, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
      ],
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
}

// ──────────────────────────────────────────────────
// Helper models & widgets
// ──────────────────────────────────────────────────

class _ActivityItem {
  final String name;
  final double amount;
  final DateTime date;
  final bool isSale;
  final String? imageUrl;

  _ActivityItem({
    required this.name,
    required this.amount,
    required this.date,
    required this.isSale,
    this.imageUrl,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w600),
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

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

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
