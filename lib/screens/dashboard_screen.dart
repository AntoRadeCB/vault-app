import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/purchase.dart';
import '../models/profile.dart';
import '../l10n/app_localizations.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback? onNewPurchase;
  final VoidCallback? onNewSale;
  final Profile? activeProfile;
  final FirestoreService _firestoreService = FirestoreService();

  DashboardScreen({
    super.key,
    this.onNewPurchase,
    this.onNewSale,
    this.activeProfile,
  });

  // ─── Profile-specific theming ─────────────────────
  Color get _accentColor {
    switch (activeProfile?.category) {
      case 'cards':
        return const Color(0xFF7C4DFF); // blue-purple
      case 'sneakers':
        return AppColors.accentTeal; // green-teal
      case 'luxury':
        return const Color(0xFFFFD700); // gold
      default:
        return AppColors.accentBlue; // default blue-purple
    }
  }

  String get _profileEmoji {
    switch (activeProfile?.category) {
      case 'cards':
        return '🃏';
      case 'sneakers':
        return '👟';
      case 'luxury':
        return '💎';
      case 'vintage':
        return '👗';
      case 'tech':
        return '🎮';
      default:
        return '🛒';
    }
  }

  bool get _hasBudget => (activeProfile?.budget ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StaggeredFadeSlide(index: 0, child: _buildProfileHeader(context)),
            const SizedBox(height: 20),
            StaggeredFadeSlide(index: 1, child: _buildActionButtons(context)),
            const SizedBox(height: 20),
            _hasBudget
                ? _buildBudgetStatCards(context)
                : _buildClassicStatCards(context),
            const SizedBox(height: 16),
            StaggeredFadeSlide(index: 5, child: _buildQuickStats(context)),
            const SizedBox(height: 24),
            StaggeredFadeSlide(index: 6, child: _buildRecentActivity(context)),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  PROFILE HEADER
  // ════════════════════════════════════════════════════

  Widget _buildProfileHeader(BuildContext context) {
    final profileName = activeProfile?.name ?? 'Vault';
    final categoryLabel = activeProfile != null
        ? Profile.categoryShortLabel(activeProfile!.category)
        : '';

    return GlassCard(
      padding: const EdgeInsets.all(20),
      glowColor: _accentColor,
      child: Column(
        children: [
          Row(
            children: [
              // Profile emoji badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _accentColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Center(
                  child: Text(
                    _profileEmoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profileName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (categoryLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        categoryLabel,
                        style: TextStyle(
                          color: _accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Inventory count badge
              StreamBuilder<int>(
                stream: _firestoreService.getInventoryItemCount(),
                builder: (context, snap) {
                  final count = snap.data ?? 0;
                  final l = AppLocalizations.of(context)!;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _accentColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2,
                            color: _accentColor, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          l.nItems(count),
                          style: TextStyle(
                            color: _accentColor,
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
          // Budget progress bar (only if budget is set)
          if (_hasBudget) ...[
            const SizedBox(height: 16),
            StreamBuilder<Map<String, double>>(
              stream: _firestoreService
                  .getBudgetStats(activeProfile!.budget),
              builder: (context, snap) {
                final stats = snap.data ??
                    {
                      'budget': activeProfile!.budget,
                      'ricavi': 0.0,
                      'maxBudget': activeProfile!.budget,
                    };
                final current = stats['budget']!;
                final max = stats['maxBudget']!;
                final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Budget: €${current.toStringAsFixed(0)} / €${max.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(ratio * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 8,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ratio > 0.5
                              ? _accentColor
                              : ratio > 0.2
                                  ? AppColors.accentOrange
                                  : AppColors.accentRed,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
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
                  const Icon(Icons.add_shopping_cart,
                      color: Colors.white, size: 20),
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
                  const Icon(Icons.sell_outlined,
                      color: Colors.white, size: 20),
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
  //  BUDGET STAT CARDS (when budget is set)
  // ════════════════════════════════════════════════════

  Widget _buildBudgetStatCards(BuildContext context) {
    return StreamBuilder<Map<String, double>>(
      stream: _firestoreService.getBudgetStats(activeProfile!.budget),
      builder: (context, budgetSnap) {
        final stats = budgetSnap.data ??
            {
              'budget': activeProfile!.budget,
              'ricavi': 0.0,
              'maxBudget': activeProfile!.budget,
            };
        final currentBudget = stats['budget']!;
        final maxBudget = stats['maxBudget']!;
        final ricavi = stats['ricavi']!;
        final budgetRatio =
            maxBudget > 0 ? (currentBudget / maxBudget).clamp(0.0, 1.0) : 0.0;

        return StreamBuilder<double>(
          stream: _firestoreService.getCapitaleImmobilizzato(),
          builder: (context, capSnap) {
            final capitale = capSnap.data ?? 0.0;

            final cards = [
              _BudgetStatData(
                '💰',
                'Budget Disponibile',
                '€${currentBudget.toStringAsFixed(0)}',
                'su €${maxBudget.toStringAsFixed(0)}',
                _accentColor,
                budgetRatio,
              ),
              _BudgetStatData(
                '📦',
                'Capitale Immobilizzato',
                '€${capitale.toStringAsFixed(0)}',
                'in inventario',
                AppColors.accentOrange,
                null,
              ),
              _BudgetStatData(
                '📈',
                'Totale Ricavi',
                '€${ricavi.toStringAsFixed(0)}',
                'guadagno netto',
                AppColors.accentGreen,
                null,
              ),
            ];

            return Column(
              children: List.generate(cards.length, (i) {
                final c = cards[i];
                return StaggeredFadeSlide(
                  index: i + 2,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: i < cards.length - 1 ? 10 : 0),
                    child: HoverLiftCard(
                      child: GlassCard(
                        glowColor: c.color,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Text(c.emoji,
                                style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.title.toUpperCase(),
                                    style: TextStyle(
                                      color: c.color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    c.value,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    c.subtitle,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (c.progress != null) ...[
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: c.progress,
                                      strokeWidth: 4,
                                      backgroundColor: Colors.white
                                          .withValues(alpha: 0.06),
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        c.progress! > 0.5
                                            ? c.color
                                            : c.progress! > 0.2
                                                ? AppColors.accentOrange
                                                : AppColors.accentRed,
                                      ),
                                    ),
                                    Text(
                                      '${(c.progress! * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        color: c.color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
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
  //  CLASSIC STAT CARDS (when no budget set)
  // ════════════════════════════════════════════════════

  Widget _buildClassicStatCards(BuildContext context) {
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

        return StreamBuilder<double>(
          stream: _firestoreService.getProfittoConsolidato(),
          builder: (context, profitSnap) {
            final profitto = profitSnap.data ?? 0;

            final cards = [
              _StatData(l.capitaleImmobilizzato, capitaleImmobilizzato, '€',
                  Icons.lock_outline, AppColors.accentBlue),
              _StatData(l.ordiniInArrivo, ordiniInArrivo, '€',
                  Icons.local_shipping_outlined, AppColors.accentTeal),
              _StatData(l.profittoConsolidato, profitto, '€',
                  Icons.trending_up, AppColors.accentGreen),
            ];

            return Column(
              children: List.generate(cards.length, (i) {
                final c = cards[i];
                return StaggeredFadeSlide(
                  index: i + 2,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: i < cards.length - 1 ? 10 : 0),
                    child: HoverLiftCard(
                      child: GlassCard(
                        glowColor: c.color,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: c.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(c.icon, color: c.color, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.title.toUpperCase(),
                                    style: TextStyle(
                                      color: c.color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  CountUpText(
                                    prefix: c.prefix,
                                    value: c.value,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
  //  QUICK STATS ROW
  // ════════════════════════════════════════════════════

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<double>(
            stream: _firestoreService.getTotalSpent(),
            builder: (context, snap) {
              return _QuickStatChip(
                label: 'Totale Speso',
                value: '€${(snap.data ?? 0).toStringAsFixed(0)}',
                icon: Icons.shopping_cart_outlined,
                color: AppColors.accentRed,
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StreamBuilder<int>(
            stream: _firestoreService.getSalesCount(),
            builder: (context, snap) {
              return _QuickStatChip(
                label: 'N° Vendite',
                value: '${snap.data ?? 0}',
                icon: Icons.sell_outlined,
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
                label: 'Media Profitto',
                value: '€${avg.toStringAsFixed(1)}',
                icon: Icons.analytics_outlined,
                color: AppColors.accentPurple,
              );
            },
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════
  //  RECENT ACTIVITY — combined timeline
  // ════════════════════════════════════════════════════

  Widget _buildRecentActivity(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _firestoreService.getCombinedSalesPurchases(),
      builder: (context, snapshot) {
        final sales = (snapshot.data?['sales'] as List<Sale>?) ?? [];
        final purchases =
            (snapshot.data?['purchases'] as List<Purchase>?) ?? [];

        // Merge into a single timeline
        final List<_ActivityItem> items = [];
        for (final s in sales) {
          items.add(_ActivityItem(
            type: _ActivityType.sale,
            name: s.productName,
            amount: s.salePrice,
            profit: s.profit,
            date: s.date,
          ));
        }
        for (final p in purchases) {
          items.add(_ActivityItem(
            type: _ActivityType.purchase,
            name: p.productName,
            amount: p.totalCost,
            profit: null,
            date: p.date,
          ));
        }
        items.sort((a, b) => b.date.compareTo(a.date));
        final recent = items.take(8).toList();

        return GlassCard(
          padding: const EdgeInsets.all(20),
          glowColor: _accentColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: _accentColor, size: 18),
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
                      color: _accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${sales.length + purchases.length} totali',
                      style: TextStyle(
                        color: _accentColor,
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
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ActivityRow(item: item),
                    )),
            ],
          ),
        );
      },
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

class _BudgetStatData {
  final String emoji;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final double? progress;

  _BudgetStatData(
      this.emoji, this.title, this.value, this.subtitle, this.color, this.progress);
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

enum _ActivityType { sale, purchase }

class _ActivityItem {
  final _ActivityType type;
  final String name;
  final double amount;
  final double? profit;
  final DateTime date;

  _ActivityItem({
    required this.type,
    required this.name,
    required this.amount,
    required this.profit,
    required this.date,
  });
}

class _ActivityRow extends StatelessWidget {
  final _ActivityItem item;
  const _ActivityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final isSale = item.type == _ActivityType.sale;
    final iconData =
        isSale ? Icons.sell_outlined : Icons.add_shopping_cart;
    final iconColor =
        isSale ? AppColors.accentGreen : AppColors.accentBlue;

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
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(iconData, color: iconColor, size: 18),
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
                  isSale
                      ? 'Venduto a €${item.amount.toStringAsFixed(0)}'
                      : 'Acquistato a €${item.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isSale && item.profit != null)
            Text(
              '${item.profit! >= 0 ? '+' : ''}€${item.profit!.toStringAsFixed(2)}',
              style: TextStyle(
                color: item.profit! >= 0
                    ? AppColors.accentGreen
                    : AppColors.accentRed,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            )
          else
            Text(
              '-€${item.amount.toStringAsFixed(0)}',
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
