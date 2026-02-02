import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A single tutorial step definition.
class TutorialStep {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final String? imagePath; // Optional illustration
  final Widget? customContent; // For complex step content

  const TutorialStep({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.accentColor = AppColors.accentBlue,
    this.imagePath,
    this.customContent,
  });
}

/// Full-screen tutorial overlay with pages.
/// Easily skippable, remembers completion.
class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
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
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < widget.steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _finish() {
    _fadeController.reverse().then((_) {
      widget.onComplete();
    });
  }

  void _skip() {
    _fadeController.reverse().then((_) {
      widget.onSkip();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: AppColors.background.withValues(alpha: 0.97),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with skip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Step counter
                    Text(
                      '${_currentPage + 1} / ${widget.steps.length}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Skip button
                    GestureDetector(
                      onTap: _skip,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Salta',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.skip_next_rounded,
                                color: AppColors.textMuted, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildProgressBar(),
              ),
              const SizedBox(height: 8),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: widget.steps.length,
                  itemBuilder: (context, index) {
                    return _TutorialPage(
                      step: widget.steps[index],
                      isWide: isWide,
                    );
                  },
                ),
              ),

              // Bottom navigation
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    // Back button
                    if (_currentPage > 0)
                      GestureDetector(
                        onTap: _prevPage,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 22),
                        ),
                      )
                    else
                      const SizedBox(width: 50),
                    const Spacer(),
                    // Next / Finish button
                    GestureDetector(
                      onTap: _nextPage,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: _currentPage == widget.steps.length - 1
                              ? const LinearGradient(
                                  colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                                )
                              : AppColors.blueButtonGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (_currentPage == widget.steps.length - 1
                                      ? AppColors.accentGreen
                                      : AppColors.accentBlue)
                                  .withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentPage == widget.steps.length - 1
                                  ? 'Inizia!'
                                  : 'Avanti',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentPage == widget.steps.length - 1
                                  ? Icons.rocket_launch_rounded
                                  : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(widget.steps.length, (i) {
        final isActive = i <= _currentPage;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 3,
            margin: EdgeInsets.only(right: i < widget.steps.length - 1 ? 4 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isActive
                  ? widget.steps[_currentPage].accentColor
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
        );
      }),
    );
  }
}

/// Individual tutorial page content
class _TutorialPage extends StatelessWidget {
  final TutorialStep step;
  final bool isWide;

  const _TutorialPage({required this.step, required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 28,
        vertical: 20,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with glow
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: step.accentColor.withValues(alpha: 0.1),
              border: Border.all(
                color: step.accentColor.withValues(alpha: 0.25),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: step.accentColor.withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              step.icon,
              color: step.accentColor,
              size: isWide ? 56 : 44,
            ),
          ),
          const SizedBox(height: 36),

          // Title
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isWide ? 28 : 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              step.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: isWide ? 16 : 14,
                height: 1.6,
              ),
            ),
          ),

          // Custom content
          if (step.customContent != null) ...[
            const SizedBox(height: 28),
            step.customContent!,
          ],
        ],
      ),
    );
  }
}
