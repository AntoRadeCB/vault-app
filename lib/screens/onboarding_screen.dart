import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';

// ═══════════════════════════════════════════════════
//  ONBOARDING — Post-registration profile setup
//  4 steps: Welcome → Features → Platforms → Level
// ═══════════════════════════════════════════════════

class _SelectableItem {
  final String id;
  final String label;
  final String emoji;
  final String description;
  final Color color;

  const _SelectableItem({
    required this.id,
    required this.label,
    required this.emoji,
    required this.description,
    required this.color,
  });
}

class _ExperienceLevel {
  final String id;
  final String label;
  final String emoji;
  final String description;
  final Color color;

  const _ExperienceLevel({
    required this.id,
    required this.label,
    required this.emoji,
    required this.description,
    required this.color,
  });
}

// ── Features (Step 2) ─────────────────────────────
const _features = [
  _SelectableItem(
    id: 'reselling',
    label: 'Rivendita',
    emoji: '💰',
    description: 'Compra e rivendi per profitto',
    color: AppColors.accentGreen,
  ),
  _SelectableItem(
    id: 'collecting',
    label: 'Collezionismo',
    emoji: '📦',
    description: 'Tieni traccia della tua collezione',
    color: AppColors.accentPurple,
  ),
  _SelectableItem(
    id: 'analytics',
    label: 'Report & Analisi',
    emoji: '📊',
    description: 'Statistiche e insight sui tuoi affari',
    color: AppColors.accentBlue,
  ),
  _SelectableItem(
    id: 'shipping',
    label: 'Tracking Spedizioni',
    emoji: '🚚',
    description: 'Monitora pacchi in entrata e uscita',
    color: AppColors.accentOrange,
  ),
  _SelectableItem(
    id: 'inventory',
    label: 'Gestione Inventario',
    emoji: '🗂️',
    description: 'Organizza il tuo magazzino',
    color: AppColors.accentTeal,
  ),
  _SelectableItem(
    id: 'pricing',
    label: 'Calcolo Profitti',
    emoji: '🧮',
    description: 'Margini, commissioni e guadagni netti',
    color: Color(0xFFE91E63),
  ),
];

// ── Platforms (Step 3) ────────────────────────────
const _platforms = [
  _SelectableItem(
    id: 'vinted',
    label: 'Vinted',
    emoji: '👗',
    description: 'Moda second-hand',
    color: Color(0xFF09B1BA),
  ),
  _SelectableItem(
    id: 'ebay',
    label: 'eBay',
    emoji: '🛒',
    description: 'Aste e compra subito',
    color: Color(0xFFE53238),
  ),
  _SelectableItem(
    id: 'cardmarket',
    label: 'Cardmarket',
    emoji: '🃏',
    description: 'TCG: Pokémon, Magic, Yu-Gi-Oh!',
    color: Color(0xFF1E3A5F),
  ),
  _SelectableItem(
    id: 'stockx',
    label: 'StockX',
    emoji: '📈',
    description: 'Sneakers, streetwear, elettronica',
    color: Color(0xFF006340),
  ),
  _SelectableItem(
    id: 'depop',
    label: 'Depop',
    emoji: '🔴',
    description: 'Moda vintage e streetwear',
    color: Color(0xFFFF2300),
  ),
  _SelectableItem(
    id: 'wallapop',
    label: 'Wallapop',
    emoji: '💬',
    description: 'Compravendita locale',
    color: Color(0xFF13C1AC),
  ),
  _SelectableItem(
    id: 'subito',
    label: 'Subito.it',
    emoji: '🇮🇹',
    description: 'Annunci in Italia',
    color: Color(0xFFFA4B00),
  ),
  _SelectableItem(
    id: 'grailed',
    label: 'Grailed',
    emoji: '🖤',
    description: 'Menswear & designer',
    color: Color(0xFF000000),
  ),
  _SelectableItem(
    id: 'goat',
    label: 'GOAT',
    emoji: '🐐',
    description: 'Sneakers autenticate',
    color: Color(0xFF121212),
  ),
  _SelectableItem(
    id: 'vestiaire',
    label: 'Vestiaire Collective',
    emoji: '💎',
    description: 'Luxury second-hand',
    color: Color(0xFF2D5F2D),
  ),
  _SelectableItem(
    id: 'facebook_mp',
    label: 'Facebook Marketplace',
    emoji: '🏪',
    description: 'Vendita locale e spedita',
    color: Color(0xFF1877F2),
  ),
  _SelectableItem(
    id: 'etsy',
    label: 'Etsy',
    emoji: '🎨',
    description: 'Artigianato e vintage',
    color: Color(0xFFF1641E),
  ),
  _SelectableItem(
    id: 'amazon',
    label: 'Amazon',
    emoji: '📦',
    description: 'FBA e reselling',
    color: Color(0xFFFF9900),
  ),
  _SelectableItem(
    id: 'zalando',
    label: 'Zalando Pre-owned',
    emoji: '🧡',
    description: 'Moda e scarpe',
    color: Color(0xFFFF6900),
  ),
  _SelectableItem(
    id: 'other',
    label: 'Altro',
    emoji: '➕',
    description: 'Piattaforma non in lista',
    color: AppColors.textMuted,
  ),
];

// ── Experience Levels (Step 4) ────────────────────
const _experienceLevels = [
  _ExperienceLevel(
    id: 'beginner',
    label: 'Principiante',
    emoji: '🌱',
    description: 'Ho appena iniziato o voglio provare',
    color: AppColors.accentGreen,
  ),
  _ExperienceLevel(
    id: 'intermediate',
    label: 'Intermedio',
    emoji: '📈',
    description: 'Ho già fatto qualche vendita',
    color: AppColors.accentBlue,
  ),
  _ExperienceLevel(
    id: 'expert',
    label: 'Esperto',
    emoji: '🚀',
    description: 'Faccio reselling regolarmente',
    color: AppColors.accentPurple,
  ),
];

// ═══════════════════════════════════════════════════
//  MAIN WIDGET
// ═══════════════════════════════════════════════════

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _firestoreService = FirestoreService();

  int _currentPage = 0;
  final int _totalPages = 4;
  final Set<String> _selectedFeatures = {};
  final Set<String> _selectedPlatforms = {};
  String? _selectedExperience;
  bool _saving = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
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

  bool get _canProceed {
    switch (_currentPage) {
      case 0:
        return true; // name is optional
      case 1:
        return _selectedFeatures.isNotEmpty;
      case 2:
        return _selectedPlatforms.isNotEmpty;
      case 3:
        return _selectedExperience != null;
      default:
        return false;
    }
  }

  Future<void> _finishOnboarding() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await _firestoreService.setUserProfile({
        'displayName': _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        'interests': _selectedFeatures.toList(),
        'platforms': _selectedPlatforms.toList(),
        'experienceLevel': _selectedExperience,
        'onboardingComplete': true,
        'onboardingCompletedAt': DateTime.now().toIso8601String(),
      });
      widget.onComplete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: AppColors.accentRed,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _buildWelcomePage(),
                    _buildGridPage(
                      title: 'Cosa ti interessa?',
                      subtitle: 'Seleziona le funzionalità che usi di più',
                      items: _features,
                      selected: _selectedFeatures,
                    ),
                    _buildGridPage(
                      title: 'Dove compri e vendi?',
                      subtitle: 'Seleziona le piattaforme che usi',
                      items: _platforms,
                      selected: _selectedPlatforms,
                    ),
                    _buildExperiencePage(),
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header with progress ──────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalPages, (i) {
              final isActive = i == _currentPage;
              final isPast = i < _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 32 : 10,
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: isActive || isPast
                      ? AppColors.blueButtonGradient
                      : null,
                  color: isActive || isPast ? null : AppColors.surface,
                  border: Border.all(
                    color: isActive
                        ? AppColors.accentBlue.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.accentBlue.withValues(alpha: 0.3),
                            blurRadius: 8,
                          )
                        ]
                      : [],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            '${_currentPage + 1} di $_totalPages',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Page 1: Welcome ───────────────────────────────
  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.headerGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentBlue.withValues(alpha: 0.4),
                        blurRadius: 32,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.view_in_ar,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Benvenuto in Vault! 🎉',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Personalizziamo la tua esperienza.\nCi vorranno solo 30 secondi.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: const Text(
                    'Come ti chiami?',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Il tuo nome o nickname (opzionale)',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 15),
                    prefixIcon: Icon(Icons.person_outline,
                        color: AppColors.textMuted, size: 22),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Reusable grid page (features / platforms) ─────
  Widget _buildGridPage({
    required String title,
    required String subtitle,
    required List<_SelectableItem> items,
    required Set<String> selected,
  }) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
        ),
        if (selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              '${selected.length} selezionat${selected.length == 1 ? 'o' : 'i'}',
              style: TextStyle(
                color: AppColors.accentBlue.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: GridView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.of(context).size.width > 500 ? 3 : 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: MediaQuery.of(context).size.width > 500
                      ? 1.15
                      : 1.05,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return _buildSelectableCard(items[index], selected);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectableCard(
      _SelectableItem item, Set<String> selected) {
    final isSelected = selected.contains(item.id);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selected.remove(item.id);
          } else {
            selected.add(item.id);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? item.color.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? item.color.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.06),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: item.color.withValues(alpha: 0.2),
                    blurRadius: 16,
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      item.description,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                        fontSize: 11,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Page 4: Experience ────────────────────────────
  Widget _buildExperiencePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Text(
                'Qual è il tuo livello?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Così possiamo adattare i suggerimenti',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ...List.generate(_experienceLevels.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildExperienceCard(_experienceLevels[index]),
                );
              }),
              const SizedBox(height: 32),
              // Summary chips
              if (_selectedFeatures.isNotEmpty || _selectedPlatforms.isNotEmpty)
                _buildSummary(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedFeatures.isNotEmpty) ...[
          const Text(
            'FUNZIONALITÀ',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedFeatures.map((id) {
              final item = _features.firstWhere((i) => i.id == id);
              return _buildChip(item);
            }).toList(),
          ),
          const SizedBox(height: 18),
        ],
        if (_selectedPlatforms.isNotEmpty) ...[
          const Text(
            'PIATTAFORME',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedPlatforms.map((id) {
              final item = _platforms.firstWhere((i) => i.id == id);
              return _buildChip(item);
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildChip(_SelectableItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: item.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            item.label,
            style: TextStyle(
              color: item.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard(_ExperienceLevel level) {
    final isSelected = _selectedExperience == level.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedExperience = level.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? level.color.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? level.color.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.06),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: level.color.withValues(alpha: 0.15),
                    blurRadius: 16,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Text(level.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.label,
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level.description,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.textSecondary
                          : AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? level.color : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? level.color
                      : AppColors.textMuted.withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: level.color.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ]
                    : [],
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom navigation bar ─────────────────────────
  Widget _buildBottomBar() {
    final isLastPage = _currentPage == _totalPages - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.04),
          ),
        ),
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            GestureDetector(
              onTap: _prevPage,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ),
            )
          else
            const SizedBox(width: 60),
          const Spacer(),
          GestureDetector(
            onTap: _canProceed ? _nextPage : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient:
                    _canProceed ? AppColors.blueButtonGradient : null,
                color: _canProceed ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _canProceed
                    ? [
                        BoxShadow(
                          color:
                              AppColors.accentBlue.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLastPage ? 'Iniziamo! 🚀' : 'Avanti',
                          style: TextStyle(
                            color: _canProceed
                                ? Colors.white
                                : AppColors.textMuted,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (!isLastPage) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: _canProceed
                                ? Colors.white
                                : AppColors.textMuted,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
