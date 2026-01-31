import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../models/sale.dart';
import '../models/purchase.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggeredFadeSlide(
            index: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Reports',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Panoramica completa acquisti e vendite',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Overview: Revenue, Spent, Profit, ROI ──
          StaggeredFadeSlide(index: 1, child: _buildOverviewSection(fs)),
          const SizedBox(height: 20),

          // ── Sales stats row ──
          StaggeredFadeSlide(index: 2, child: _buildSalesStatsRow(fs)),
          const SizedBox(height: 20),

          // ── Purchase stats row ──
          StaggeredFadeSlide(index: 3, child: _buildPurchaseStatsRow(fs)),
          const SizedBox(height: 20),

          // ── Profit breakdown ──
          StaggeredFadeSlide(index: 4, child: _buildProfitBreakdown(fs)),
          const SizedBox(height: 24),

          // ── Export section ──
          StaggeredFadeSlide(index: 5, child: _buildExportSection(context)),
          const SizedBox(height: 24),

          // ── All sales ──
          StaggeredFadeSlide(index: 6, child: _buildAllSales(fs)),
          const SizedBox(height: 24),

          // ── All purchases ──
          StaggeredFadeSlide(index: 7, child: _buildAllPurchases(fs)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  OVERVIEW — 4 main financial metrics
  // ════════════════════════════════════════════════════

  Widget _buildOverviewSection(FirestoreService fs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Overview Finanziaria', Icons.account_balance_outlined),
        const SizedBox(height: 12),
        // Row 1: Revenue + Spent
        Row(
          children: [
            Expanded(
              child: StreamBuilder<double>(
                stream: fs.getTotalRevenue(),
                builder: (context, snap) {
                  return _StatCard(
                    title: 'Ricavi Totali',
                    value: snap.data ?? 0,
                    prefix: '€',
                    icon: Icons.payments_outlined,
                    color: AppColors.accentGreen,
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StreamBuilder<double>(
                stream: fs.getTotalSpent(),
                builder: (context, snap) {
                  return _StatCard(
                    title: 'Totale Speso',
                    value: snap.data ?? 0,
                    prefix: '€',
                    icon: Icons.shopping_cart_outlined,
                    color: AppColors.accentRed,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Row 2: Net Profit + ROI
        Row(
          children: [
            Expanded(
              child: StreamBuilder<double>(
                stream: fs.getProfittoConsolidato(),
                builder: (context, snap) {
                  final profit = snap.data ?? 0;
                  return _StatCard(
                    title: 'Profitto Netto',
                    value: profit,
                    prefix: '€',
                    icon: Icons.trending_up,
                    color: profit >= 0 ? AppColors.accentGreen : AppColors.accentRed,
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StreamBuilder<double>(
                stream: fs.getROI(),
                builder: (context, snap) {
                  final roi = snap.data ?? 0;
                  return _StatCard(
                    title: 'ROI',
                    value: roi,
                    prefix: '',
                    suffix: '%',
                    decimals: 1,
                    icon: Icons.pie_chart_outline,
                    color: roi >= 0 ? AppColors.accentTeal : AppColors.accentRed,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════
  //  SALES STATS — count, avg profit, best sale, fees
  // ════════════════════════════════════════════════════

  Widget _buildSalesStatsRow(FirestoreService fs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Vendite', Icons.sell_outlined),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StreamBuilder<int>(
                stream: fs.getSalesCount(),
                builder: (context, snap) {
                  return _MiniStat(
                    label: 'N° Vendite',
                    value: '${snap.data ?? 0}',
                    color: AppColors.accentGreen,
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StreamBuilder<double>(
                stream: fs.getAverageProfitPerSale(),
                builder: (context, snap) {
                  return _MiniStat(
                    label: 'Media Profitto',
                    value: '€${(snap.data ?? 0).toStringAsFixed(1)}',
                    color: AppColors.accentPurple,
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StreamBuilder<double>(
                stream: fs.getTotalFeesPaid(),
                builder: (context, snap) {
                  return _MiniStat(
                    label: 'Totale Fee',
                    value: '€${(snap.data ?? 0).toStringAsFixed(0)}',
                    color: AppColors.accentOrange,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Best sale card
        StreamBuilder<Sale?>(
          stream: fs.getBestSale(),
          builder: (context, snap) {
            final best = snap.data;
            if (best == null) return const SizedBox.shrink();
            return GlassCard(
              padding: const EdgeInsets.all(14),
              glowColor: AppColors.accentGreen,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.emoji_events, color: AppColors.accentGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MIGLIOR VENDITA',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          best.productName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '+€${best.profit.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════
  //  PURCHASE STATS — count, total value, inventory
  // ════════════════════════════════════════════════════

  Widget _buildPurchaseStatsRow(FirestoreService fs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Acquisti', Icons.shopping_cart_outlined),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StreamBuilder<int>(
                stream: fs.getPurchasesCount(),
                builder: (context, snap) {
                  return _MiniStat(
                    label: 'N° Acquisti',
                    value: '${snap.data ?? 0}',
                    color: AppColors.accentBlue,
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StreamBuilder<double>(
                stream: fs.getTotalInventoryValue(),
                builder: (context, snap) {
                  return _MiniStat(
                    label: 'Valore Inventario',
                    value: '€${(snap.data ?? 0).toStringAsFixed(0)}',
                    color: AppColors.accentTeal,
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StreamBuilder<double>(
                stream: fs.getTotalInventoryQuantity(),
                builder: (context, snap) {
                  return _MiniStat(
                    label: 'Pezzi Totali',
                    value: (snap.data ?? 0).toStringAsFixed(0),
                    color: AppColors.accentPurple,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════
  //  PROFIT BREAKDOWN — fees vs net
  // ════════════════════════════════════════════════════

  Widget _buildProfitBreakdown(FirestoreService fs) {
    return StreamBuilder<List<Sale>>(
      stream: fs.getSales(),
      builder: (context, salesSnap) {
        return StreamBuilder<List<Purchase>>(
          stream: fs.getPurchases(),
          builder: (context, purchasesSnap) {
            final sales = salesSnap.data ?? [];
            final purchases = purchasesSnap.data ?? [];

            final totalRevenue = sales.fold<double>(0, (a, s) => a + s.salePrice);
            final totalCosts = purchases.fold<double>(0, (a, p) => a + p.totalCost);
            final totalFees = sales.fold<double>(0, (a, s) => a + s.fees);
            final netProfit = sales.fold<double>(0, (a, s) => a + s.profit);

            return GlassCard(
              padding: const EdgeInsets.all(20),
              glowColor: AppColors.accentPurple,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Breakdown Finanziario',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _BreakdownRow(label: 'Ricavi vendite', value: totalRevenue, color: AppColors.accentGreen, prefix: '+'),
                  const SizedBox(height: 8),
                  _BreakdownRow(label: 'Costi acquisto', value: totalCosts, color: AppColors.accentRed, prefix: '-'),
                  const SizedBox(height: 8),
                  _BreakdownRow(label: 'Commissioni pagate', value: totalFees, color: AppColors.accentOrange, prefix: '-'),
                  const SizedBox(height: 12),
                  Divider(color: Colors.white.withValues(alpha: 0.08)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PROFITTO NETTO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${netProfit >= 0 ? '+' : ''}€${netProfit.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: netProfit >= 0 ? AppColors.accentGreen : AppColors.accentRed,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (totalRevenue > 0) ...[
                    const SizedBox(height: 12),
                    // Visual profit bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 8,
                        child: Row(
                          children: [
                            if (totalCosts > 0)
                              Expanded(
                                flex: (totalCosts / totalRevenue * 100).round().clamp(1, 100),
                                child: Container(color: AppColors.accentRed.withValues(alpha: 0.6)),
                              ),
                            if (totalFees > 0)
                              Expanded(
                                flex: (totalFees / totalRevenue * 100).round().clamp(1, 100),
                                child: Container(color: AppColors.accentOrange.withValues(alpha: 0.6)),
                              ),
                            if (netProfit > 0)
                              Expanded(
                                flex: (netProfit / totalRevenue * 100).round().clamp(1, 100),
                                child: Container(color: AppColors.accentGreen.withValues(alpha: 0.6)),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _legendDot('Costi', AppColors.accentRed),
                        _legendDot('Fee', AppColors.accentOrange),
                        _legendDot('Profitto', AppColors.accentGreen),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }

  // ════════════════════════════════════════════════════
  //  EXPORT
  // ════════════════════════════════════════════════════

  Widget _buildExportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Esporta', Icons.download_outlined),
        const SizedBox(height: 12),
        _ExportCard(title: 'CSV Full History', icon: Icons.table_chart, color: AppColors.accentGreen),
        const SizedBox(height: 10),
        _ExportCard(title: 'PDF Tax Summary', icon: Icons.picture_as_pdf, color: AppColors.accentRed),
        const SizedBox(height: 10),
        _ExportCard(title: 'Monthly Sales Log', icon: Icons.calendar_month, color: AppColors.accentBlue),
      ],
    );
  }

  // ════════════════════════════════════════════════════
  //  ALL SALES
  // ════════════════════════════════════════════════════

  Widget _buildAllSales(FirestoreService fs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Storico Vendite', Icons.sell_outlined),
        const SizedBox(height: 12),
        StreamBuilder<List<Sale>>(
          stream: fs.getSales(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.accentBlue),
                ),
              );
            }
            final sales = snapshot.data ?? [];
            if (sales.isEmpty) {
              return GlassCard(
                padding: const EdgeInsets.all(24),
                child: const Center(
                  child: Text(
                    'Nessuna vendita registrata',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ),
              );
            }
            return Column(
              children: sales.map((sale) {
                final profit = sale.profit;
                final isPositive = profit >= 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: HoverLiftCard(
                    liftAmount: 2,
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      glowColor: isPositive ? AppColors.accentGreen : AppColors.accentRed,
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isPositive
                                    ? [
                                        AppColors.accentGreen.withValues(alpha: 0.15),
                                        AppColors.accentGreen.withValues(alpha: 0.05),
                                      ]
                                    : [
                                        AppColors.accentRed.withValues(alpha: 0.15),
                                        AppColors.accentRed.withValues(alpha: 0.05),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: (isPositive ? AppColors.accentGreen : AppColors.accentRed)
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            child: Icon(
                              isPositive ? Icons.trending_up : Icons.trending_down,
                              color: isPositive ? AppColors.accentGreen : AppColors.accentRed,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sale.productName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Vendita €${sale.salePrice.toStringAsFixed(0)} · Costo €${sale.purchasePrice.toStringAsFixed(0)}${sale.fees > 0 ? ' · Fee €${sale.fees.toStringAsFixed(0)}' : ''}',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isPositive ? '+' : ''}€${profit.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: isPositive ? AppColors.accentGreen : AppColors.accentRed,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '+€${sale.salePrice.toInt()}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════
  //  ALL PURCHASES
  // ════════════════════════════════════════════════════

  Widget _buildAllPurchases(FirestoreService fs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Storico Acquisti', Icons.shopping_cart_outlined),
        const SizedBox(height: 12),
        StreamBuilder<List<Purchase>>(
          stream: fs.getPurchases(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.accentBlue),
                ),
              );
            }
            final purchases = snapshot.data ?? [];
            if (purchases.isEmpty) {
              return GlassCard(
                padding: const EdgeInsets.all(24),
                child: const Center(
                  child: Text(
                    'Nessun acquisto registrato',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ),
              );
            }
            return Column(
              children: purchases.map((purchase) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: HoverLiftCard(
                    liftAmount: 2,
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      glowColor: AppColors.accentBlue,
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.accentBlue.withValues(alpha: 0.15),
                                  AppColors.accentBlue.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.accentBlue.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart,
                              color: AppColors.accentBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  purchase.productName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Qta: ${purchase.quantity.toInt()} · ${purchase.workspace}',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '-€${purchase.totalCost.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.accentRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════════════

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────
// Reusable stat card with count-up
// ──────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final double value;
  final String prefix;
  final String suffix;
  final int decimals;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.prefix,
    this.suffix = '',
    this.decimals = 0,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return HoverLiftCard(
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        glowColor: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: CountUpText(
                    prefix: prefix,
                    value: value,
                    decimals: decimals,
                    style: TextStyle(
                      color: color == AppColors.accentRed ? color : Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (suffix.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      suffix,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// Mini stat chip
// ──────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
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
// Breakdown row
// ──────────────────────────────────────────────────

class _BreakdownRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String prefix;

  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.color,
    required this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
        Text(
          '$prefix€${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────
// Export card
// ──────────────────────────────────────────────────

class _ExportCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _ExportCard({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  State<_ExportCard> createState() => _ExportCardState();
}

class _ExportCardState extends State<_ExportCard> {
  bool _tapped = false;

  void _onDownloadTap() {
    setState(() => _tapped = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _tapped = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return HoverLiftCard(
      liftAmount: 2,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        glowColor: widget.color,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.icon, color: widget.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ScaleOnPress(
              onTap: _onDownloadTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _tapped
                      ? AppColors.accentGreen.withValues(alpha: 0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _tapped
                        ? AppColors.accentGreen.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Icon(
                  _tapped ? Icons.check : Icons.download,
                  color: _tapped ? AppColors.accentGreen : AppColors.textMuted,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
