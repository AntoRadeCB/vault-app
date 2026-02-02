import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../services/firestore_service.dart';

// ═══════════════════════════════════════════════════
//  ONBOARDING — Post-registration profile setup
// ═══════════════════════════════════════════════════

class _Interest {
  final String id;
  final String label;
  final String emoji;
  final String description;
  final Color color;

  const _Interest({
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

const _interests = [
  _Interest(
    id: 'reselling',
    label: 'Rivendita',
    emoji: '💰',
    description: 'Compra e rivendi per profitto',
    color: AppColors.accentGreen,
  ),
  _Interest(
    id: 'collecting',
    label: 'Collezionismo',
    emoji: '📦',
    description: 'Tieni traccia della tua collezione',
    color: AppColors.accentPurple,
  ),
  _Interest(
    id: 'analytics',
    label: 'Report & Analisi',
    emoji: '📊',
    description: 'Statistiche e insight sui tuoi affari',
    color: AppColors.accentBlue,
  ),
  _Interest(
    id: 'shipping',
    label: 'Tracking Spedizioni',
    emoji: '🚚',
    description: 'Monitora pacchi in entrata e uscita',
    color: AppColors.accentOrange,
  ),
  _Interest(
    id: 'sneakers',
    label: 'Sneakers & Streetwear',
    emoji: '👟',
    description: 'Nike, Jordan, Adidas, Supreme...',
    color: Color(0xFFE91E63),
  ),
  _Interest(
    id: 'luxury',
    label: 'Luxury & Designer',
    emoji: '💎',
    description: 'Gucci, LV, Balenciaga, Prada...',
    color: Color(0xFFFFD700),
  ),
  _Interest(
    id: 'tech',
    label: 'Tech & Elettronica',
    emoji: '🎮',
    description: 'Console, smartphone, gadget...',
    color: AppColors.accentTeal,
  ),
  _Interest(
    id: 'vintage',
    label: 'Vintage & Second-hand',
    emoji: '🏷️',
    description: 'Pezzi unici e occasioni vintage',
    color: Color(0xFF8D6E63),
  ),
];

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
  final int _totalPages = 3;
  final Set<String> _selectedInterests = {};
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
        return _selectedInterests.isNotEmpty;
      case 2:
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
        'interests': _selectedInterests.toList(),
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
                    _buildInterestsPage(),
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
          // Progress dots
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
          // Step counter
          Text(
            '${_currentPage + 1} di $_totalPages',
            style: TextStyle(
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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          minHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Animated logo
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
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
            Text(
              'Personalizziamo la tua esperienza.\nCi vorranno solo 30 secondi.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Name field
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
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
                decoration: InputDecoration(
                  hintText: 'Il tuo nome o nickname (opzionale)',
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 15),
                  prefixIcon: Icon(Icons.person_outline,
                      color: AppColors.textMuted, size: 22),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─── Page 2: Interests ─────────────────────────────
  Widget _buildInterestsPage() {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Cosa ti interessa?',
            style: TextStyle(
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
          'Seleziona tutto ciò che fa per te',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: GridView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.of(context).size.width > 500 ? 3 : 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: _interests.length,
                itemBuilder: (context, index) {
                  return _buildInterestCard(_interests[index]);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestCard(_Interest interest) {
    final isSelected = _selectedInterests.contains(interest.id);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedInterests.remove(interest.id);
          } else {
            _selectedInterests.add(interest.id);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? interest.color.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? interest.color.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.06),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: interest.color.withValues(alpha: 0.2),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            // Checkmark
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: interest.color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    interest.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    interest.label,
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
                      interest.description,
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

  // ─── Page 3: Experience ────────────────────────────
  Widget _buildExperiencePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
            Text(
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
            // Summary of selections
            if (_selectedInterests.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'I tuoi interessi',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedInterests.map((id) {
                  final interest = _interests.firstWhere((i) => i.id == id);
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: interest.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: interest.color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(interest.emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          interest.label,
                          style: TextStyle(
                            color: interest.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
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
            Text(
              level.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
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
            // Radio indicator
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
          // Back button
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
            const SizedBox(width: 60), // placeholder to keep layout balanced
          const Spacer(),
          // Next / Finish button
          GestureDetector(
            onTap: _canProceed ? _nextPage : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: _canProceed
                    ? AppColors.blueButtonGradient
                    : null,
                color: _canProceed ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _canProceed
                    ? [
                        BoxShadow(
                          color: AppColors.accentBlue.withValues(alpha: 0.3),
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
