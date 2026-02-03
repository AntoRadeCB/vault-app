import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

/// 4-step post-registration onboarding flow.
/// Shown once, after first login, when the user has no profiles yet.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final FirestoreService _fs = FirestoreService();
  int _currentPage = 0;

  // Onboarding state
  int _selectedPresetIndex = 0;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final preset = UserProfile.presets[_selectedPresetIndex];
      final budgetText = _budgetController.text.trim();
      final budget = budgetText.isNotEmpty ? double.tryParse(budgetText) : null;

      // Use custom name if provided, otherwise use category label
      final customName = _nameController.text.trim();
      final profileName = customName.isNotEmpty
          ? customName
          : UserProfile.categoryLabel(preset.type);

      final profileToSave = preset.copyWith(
        name: profileName,
        budgetMonthly: budget,
      );
      final ref = await _fs.addProfile(profileToSave);
      await _fs.setActiveProfile(ref.id);

      widget.onComplete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: AppColors.accentRed),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Progress dots
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final isActive = i == _currentPage;
                    final isPast = i < _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: isActive ? 28 : 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: isActive
                            ? AppColors.accentBlue
                            : isPast
                                ? AppColors.accentBlue.withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.15),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _buildWelcomePage(),
                    _buildProfilePickerPage(),
                    _buildBudgetPage(),
                    _buildReadyPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Page 1: Welcome ────────────────────────────
  Widget _buildWelcomePage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adapt spacing for small screens
        final isCompact = constraints.maxHeight < 600;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: isCompact ? 24 : 48),
                  Container(
                    width: isCompact ? 80 : 100,
                    height: isCompact ? 80 : 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.headerGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentBlue.withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(Icons.view_in_ar, color: Colors.white, size: isCompact ? 40 : 50),
                  ),
                  SizedBox(height: isCompact ? 28 : 40),
                  const Text(
                    'Benvenuto in CardVault!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Il tuo gestore per carte collezionabili.\n'
                    'Traccia la collezione, apri buste e\nmonitora il valore delle tue carte.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isCompact ? 32 : 48),
                  _buildNextButton('Iniziamo', onTap: _nextPage),
                  SizedBox(height: isCompact ? 24 : 48),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Page 2: Profile Name + Category ─────────────
  Widget _buildProfilePickerPage() {
    final presets = UserProfile.presets;
    final selectedPreset = presets[_selectedPresetIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Crea il tuo Profilo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scegli un nome e una categoria.\nPotrai modificarli in qualsiasi momento.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // ─── Name input ───
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: UserProfile.categoryLabel(selectedPreset.type),
                hintStyle: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.edit_outlined,
                  color: selectedPreset.color.withValues(alpha: 0.7),
                  size: 20,
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 40),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          const SizedBox(height: 20),

          // ─── Category label ───
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Categoria',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // ─── Category cards ───
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: presets.length,
              itemBuilder: (context, i) {
                final p = presets[i];
                final isSelected = _selectedPresetIndex == i;
                final categoryLabel = UserProfile.categoryLabel(p.type);
                final categoryHint = UserProfile.categoryHint(p.type);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ScaleOnPress(
                    onTap: () => setState(() => _selectedPresetIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? p.color.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? p.color.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.06),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: p.color.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  spreadRadius: -2,
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: p.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(p.icon, color: p.color, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  categoryLabel,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  categoryHint,
                                  style: TextStyle(
                                    color: isSelected
                                        ? p.color.withValues(alpha: 0.8)
                                        : AppColors.textMuted,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Icon(Icons.check_circle, color: p.color, size: 22),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              children: [
                _buildBackButton(onTap: _prevPage),
                const SizedBox(width: 12),
                Expanded(child: _buildNextButton('Continua', onTap: _nextPage)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Page 3: Budget ─────────────────────────────
  Widget _buildBudgetPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.savings_outlined, color: AppColors.accentGreen, size: 40),
          ),
          const SizedBox(height: 28),
          const Text(
            'Budget Mensile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Imposta un budget mensile per tenere\nsotto controllo le tue spese. Opzionale.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: TextField(
              controller: _budgetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '€0',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 32),
                border: InputBorder.none,
                prefixText: '€',
                prefixStyle: TextStyle(
                  color: AppColors.accentGreen,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              _buildBackButton(onTap: _prevPage),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNextButton(
                  _budgetController.text.trim().isEmpty ? 'Salta' : 'Continua',
                  onTap: _nextPage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Page 4: Ready ──────────────────────────────
  Widget _buildReadyPage() {
    final preset = UserProfile.presets[_selectedPresetIndex];
    final budgetText = _budgetController.text.trim();
    final hasBudget = budgetText.isNotEmpty && (double.tryParse(budgetText) ?? 0) > 0;

    final customName = _nameController.text.trim();
    final profileName = customName.isNotEmpty
        ? customName
        : UserProfile.categoryLabel(preset.type);
    final categoryLabel = UserProfile.categoryLabel(preset.type);

    // Build a human-readable tab list
    final tabNames = preset.enabledTabs.map((id) {
      switch (id) {
        case 'dashboard': return 'Dashboard';
        case 'inventory': return 'Inventario';
        case 'shipments': return 'Spedizioni';
        case 'reports': return 'Report';
        case 'settings': return 'Impostazioni';
        default: return id;
      }
    }).join(', ');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: preset.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: preset.color.withValues(alpha: 0.3)),
              ),
              child: Icon(preset.icon, color: preset.color, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pronto! 🚀',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ecco il riepilogo del tuo profilo',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            GlassCard(
              padding: const EdgeInsets.all(20),
              glowColor: preset.color,
              child: Column(
                children: [
                  _summaryRow('Nome', profileName, preset.icon, preset.color),
                  const SizedBox(height: 14),
                  _summaryRow(
                    'Categoria',
                    categoryLabel,
                    Icons.category_outlined,
                    preset.color,
                  ),
                  const SizedBox(height: 14),
                  _summaryRow(
                    'Tab attive',
                    tabNames,
                    Icons.tab,
                    AppColors.accentBlue,
                  ),
                  if (hasBudget) ...[
                    const SizedBox(height: 14),
                    _summaryRow(
                      'Budget',
                      '€$budgetText/mese',
                      Icons.savings_outlined,
                      AppColors.accentGreen,
                    ),
                  ],
                  if (!hasBudget) ...[
                    const SizedBox(height: 14),
                    _summaryRow(
                      'Budget',
                      'Non impostato',
                      Icons.savings_outlined,
                      AppColors.textMuted,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 36),
            Row(
              children: [
                _buildBackButton(onTap: _prevPage),
                const SizedBox(width: 12),
                Expanded(
                  child: ShimmerButton(
                    baseGradient: LinearGradient(
                      colors: [preset.color, preset.color.withValues(alpha: 0.7)],
                    ),
                    onTap: _saving ? null : _finish,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_saving)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else ...[
                            const Icon(Icons.rocket_launch, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Inizia!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton(String label, {VoidCallback? onTap}) {
    return ShimmerButton(
      baseGradient: AppColors.blueButtonGradient,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton({VoidCallback? onTap}) {
    return ScaleOnPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 20),
      ),
    );
  }
}
