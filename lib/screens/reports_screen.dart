import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../models/sale.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

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
                  'Export and analyze your activity',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildStatRow(firestoreService),
          const SizedBox(height: 28),
          StaggeredFadeSlide(index: 3, child: _buildExportSection(context)),
          const SizedBox(height: 28),
          StaggeredFadeSlide(
              index: 4,
              child: _buildRecentTransactions(firestoreService)),
        ],
      ),
    );
  }

  Widget _buildStatRow(FirestoreService firestoreService) {
    return Row(
      children: [
        Expanded(
          child: StaggeredFadeSlide(
            index: 1,
            child: HoverLiftCard(
              child: StreamBuilder<int>(
                stream: firestoreService.getSalesCount(),
                builder: (context, snapshot) {
                  return _AnimatedStatCard(
                    title: 'Sales Count',
                    value: (snapshot.data ?? 0).toDouble(),
                    prefix: '',
                    icon: Icons.receipt_long,
                    color: AppColors.accentBlue,
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StaggeredFadeSlide(
            index: 2,
            child: HoverLiftCard(
              child: StreamBuilder<double>(
                stream: firestoreService.getTotalFeesPaid(),
                builder: (context, snapshot) {
                  return _AnimatedStatCard(
                    title: 'Total Fees Paid',
                    value: snapshot.data ?? 0,
                    prefix: '€',
                    decimals: 2,
                    icon: Icons.money_off,
                    color: AppColors.accentRed,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Export History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        _ExportCard(
          title: 'CSV Full History',
          icon: Icons.table_chart,
          color: AppColors.accentGreen,
        ),
        const SizedBox(height: 10),
        _ExportCard(
          title: 'PDF Tax Summary',
          icon: Icons.picture_as_pdf,
          color: AppColors.accentRed,
        ),
        const SizedBox(height: 10),
        _ExportCard(
          title: 'Monthly Sales Log',
          icon: Icons.calendar_month,
          color: AppColors.accentBlue,
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(FirestoreService firestoreService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        StreamBuilder<List<Sale>>(
          stream: firestoreService.getSales(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child:
                      CircularProgressIndicator(color: AppColors.accentBlue),
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
              children: sales.take(10).map((sale) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TransactionCard(
                    name: sale.productName,
                    income: sale.salePrice,
                    expense: sale.purchasePrice,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────
// Animated stat card with count-up
// ──────────────────────────────────────────────────
class _AnimatedStatCard extends StatelessWidget {
  final String title;
  final double value;
  final String prefix;
  final int decimals;
  final IconData icon;
  final Color color;

  const _AnimatedStatCard({
    required this.title,
    required this.value,
    required this.prefix,
    this.decimals = 0,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
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
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          CountUpText(
            prefix: prefix,
            value: value,
            decimals: decimals,
            style: TextStyle(
              color: color == AppColors.accentRed ? color : Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────
// Export card with download tap feedback
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

class _ExportCardState extends State<_ExportCard>
    with SingleTickerProviderStateMixin {
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
                  color:
                      _tapped ? AppColors.accentGreen : AppColors.textMuted,
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

// ──────────────────────────────────────────────────
// Transaction card with green/red colors
// ──────────────────────────────────────────────────
class _TransactionCard extends StatelessWidget {
  final String name;
  final double income;
  final double? expense;

  const _TransactionCard({
    required this.name,
    required this.income,
    this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final hasIncome = income > 0;
    return HoverLiftCard(
      liftAmount: 2,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        glowColor: hasIncome ? AppColors.accentGreen : AppColors.accentBlue,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasIncome
                      ? [
                          AppColors.accentGreen.withValues(alpha: 0.15),
                          AppColors.accentGreen.withValues(alpha: 0.05),
                        ]
                      : [
                          AppColors.surface,
                          AppColors.surface,
                        ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasIncome
                      ? AppColors.accentGreen.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Icon(
                hasIncome ? Icons.trending_up : Icons.swap_horiz,
                color:
                    hasIncome ? AppColors.accentGreen : AppColors.textMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+€${income.toInt()}',
                  style: TextStyle(
                    color: hasIncome
                        ? AppColors.accentGreen
                        : AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (expense != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '-€${expense!.toInt()}',
                    style: const TextStyle(
                      color: AppColors.accentRed,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
