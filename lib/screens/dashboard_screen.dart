import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';
import '../models/product.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback? onNewPurchase;
  final FirestoreService _firestoreService = FirestoreService();

  DashboardScreen({super.key, this.onNewPurchase});

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StaggeredFadeSlide(index: 0, child: _buildHeader()),
            const SizedBox(height: 24),
            _buildStatCards(),
            const SizedBox(height: 24),
            StaggeredFadeSlide(index: 5, child: _buildActionButtons(context)),
            const SizedBox(height: 24),
            StaggeredFadeSlide(index: 6, child: _buildOperationalStatus()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      glowColor: AppColors.accentPurple,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reselling Vinted 2025',
                  style: TextStyle(
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
                    const Text(
                      'ONLINE',
                      style: TextStyle(
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
          PulsingBadge(
            count: 3,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return StreamBuilder<List<Product>>(
      stream: _firestoreService.getProducts(),
      builder: (context, productSnap) {
        // Calculate stats from products
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
              _StatData('Capitale Immobilizzato', capitaleImmobilizzato, '€',
                  Icons.lock_outline, AppColors.accentBlue),
              _StatData('Ordini in Arrivo', ordiniInArrivo, '€',
                  Icons.local_shipping_outlined, AppColors.accentTeal),
              _StatData('Capitale Spedito', capitaleSpedito, '€',
                  Icons.send_outlined, AppColors.accentOrange),
              _StatData('Profitto Consolidato', profitto, '€',
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

  Widget _buildActionButtons(BuildContext context) {
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
                children: const [
                  Icon(Icons.add_shopping_cart, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Nuovo Acquisto',
                    style: TextStyle(
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
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.sell_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Registra Vendita',
                    style: TextStyle(
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

  Widget _buildOperationalStatus() {
    return StreamBuilder<List<Product>>(
      stream: _firestoreService.getProducts(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        final shippedCount =
            products.where((p) => p.status == ProductStatus.shipped).length;
        final lowStock = products.where((p) => p.quantity <= 1).toList();

        return GlassCard(
          padding: const EdgeInsets.all(20),
          glowColor: AppColors.accentBlue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Stato Operativo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (shippedCount > 0)
                _buildStatusItem(
                    '$shippedCount Spedizioni in transito', AppColors.accentBlue),
              if (shippedCount > 0) const SizedBox(height: 12),
              if (lowStock.isNotEmpty)
                _buildStatusItem(
                    'Stock basso: ${lowStock.first.name}', AppColors.accentOrange),
              if (shippedCount == 0 && lowStock.isEmpty)
                _buildStatusItem(
                    'Nessun avviso attivo', AppColors.accentGreen),
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

class _StatData {
  final String title;
  final double value;
  final String prefix;
  final IconData icon;
  final Color color;

  _StatData(this.title, this.value, this.prefix, this.icon, this.color);
}
