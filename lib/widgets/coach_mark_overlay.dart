import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A single step in the interactive tutorial.
class CoachStep {
  final String id;
  final GlobalKey targetKey;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final TooltipPosition preferredPosition;

  const CoachStep({
    required this.id,
    required this.targetKey,
    required this.title,
    required this.description,
    required this.icon,
    this.accentColor = AppColors.accentBlue,
    this.preferredPosition = TooltipPosition.auto,
  });
}

enum TooltipPosition { auto, above, below, left, right }

/// Interactive coach-mark overlay that spotlights real UI elements
/// one at a time with animated transitions.
class CoachMarkOverlay extends StatefulWidget {
  final List<CoachStep> steps;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const CoachMarkOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<CoachMarkOverlay>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _fadeController;
  late AnimationController _spotlightController;
  late Animation<double> _fadeAnim;
  late Animation<double> _spotlightAnim;
  late Animation<double> _pulseAnim;

  // Target rect for current step
  Rect _targetRect = Rect.zero;
  Rect _prevTargetRect = Rect.zero;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _spotlightController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _spotlightAnim = CurvedAnimation(
      parent: _spotlightController,
      curve: Curves.easeOutCubic,
    );
    _pulseAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _spotlightController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
    ));

    // Start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTargetRect();
      _fadeController.forward();
      _spotlightController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _spotlightController.dispose();
    super.dispose();
  }

  void _updateTargetRect() {
    if (_currentStep >= widget.steps.length) return;
    final key = widget.steps[_currentStep].targetKey;
    final renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final position = renderBox.localToGlobal(Offset.zero);
      setState(() {
        _prevTargetRect = _targetRect;
        _targetRect = Rect.fromLTWH(
          position.dx,
          position.dy,
          renderBox.size.width,
          renderBox.size.height,
        );
      });
    }
  }

  void _goToStep(int index) {
    if (index < 0 || index >= widget.steps.length) return;
    _prevTargetRect = _targetRect;
    _spotlightController.reset();
    setState(() => _currentStep = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTargetRect();
      _spotlightController.forward();
    });
  }

  void _next() {
    if (_currentStep < widget.steps.length - 1) {
      _goToStep(_currentStep + 1);
    } else {
      _finish();
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  void _finish() {
    _fadeController.reverse().then((_) => widget.onComplete());
  }

  void _skip() {
    _fadeController.reverse().then((_) => widget.onSkip());
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final screenSize = MediaQuery.of(context).size;
    final isLast = _currentStep == widget.steps.length - 1;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _spotlightAnim,
          builder: (context, _) {
            // Interpolate between previous and current target
            final t = _spotlightAnim.value;
            final rect = _prevTargetRect == Rect.zero
                ? _targetRect
                : Rect.lerp(_prevTargetRect, _targetRect, t) ?? _targetRect;

            return Stack(
              children: [
                // Dark overlay with spotlight hole
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SpotlightPainter(
                      targetRect: rect,
                      padding: 8.0,
                      borderRadius: 14.0,
                      overlayColor:
                          Colors.black.withValues(alpha: 0.82),
                      pulseScale: _pulseAnim.value,
                      accentColor: step.accentColor,
                    ),
                  ),
                ),

                // Tap on dark area = next
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _next,
                  ),
                ),

                // Tooltip card
                _buildTooltip(context, step, rect, screenSize, isLast),

                // Step indicator + Skip (top)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 20,
                  right: 20,
                  child: Row(
                    children: [
                      // Progress dots
                      Row(
                        children: List.generate(widget.steps.length, (i) {
                          final isActive = i == _currentStep;
                          final isPast = i < _currentStep;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: isActive ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: isActive
                                  ? step.accentColor
                                  : isPast
                                      ? step.accentColor
                                          .withValues(alpha: 0.4)
                                      : Colors.white
                                          .withValues(alpha: 0.15),
                            ),
                          );
                        }),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _skip,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: const Text(
                            'Salta',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTooltip(BuildContext context, CoachStep step, Rect targetRect,
      Size screenSize, bool isLast) {
    // Determine tooltip placement
    const tooltipWidth = 300.0;
    const tooltipMargin = 16.0;
    const arrowSize = 10.0;

    final spaceAbove = targetRect.top;
    final spaceBelow = screenSize.height - targetRect.bottom;
    final spaceLeft = targetRect.left;
    final spaceRight = screenSize.width - targetRect.right;

    TooltipPosition pos = step.preferredPosition;
    if (pos == TooltipPosition.auto) {
      // Choose the side with most space
      final maxSpace = [spaceAbove, spaceBelow, spaceLeft, spaceRight]
          .reduce(max);
      if (maxSpace == spaceBelow && spaceBelow > 200) {
        pos = TooltipPosition.below;
      } else if (maxSpace == spaceAbove && spaceAbove > 200) {
        pos = TooltipPosition.above;
      } else if (maxSpace == spaceRight && spaceRight > tooltipWidth + 40) {
        pos = TooltipPosition.right;
      } else if (maxSpace == spaceLeft && spaceLeft > tooltipWidth + 40) {
        pos = TooltipPosition.left;
      } else {
        pos = spaceBelow >= spaceAbove
            ? TooltipPosition.below
            : TooltipPosition.above;
      }
    }

    double left, top;

    switch (pos) {
      case TooltipPosition.below:
        left = (targetRect.center.dx - tooltipWidth / 2)
            .clamp(tooltipMargin, screenSize.width - tooltipWidth - tooltipMargin);
        top = targetRect.bottom + arrowSize + 8;
        break;
      case TooltipPosition.above:
        left = (targetRect.center.dx - tooltipWidth / 2)
            .clamp(tooltipMargin, screenSize.width - tooltipWidth - tooltipMargin);
        // We'll calculate height below; for now estimate
        top = targetRect.top - 180 - arrowSize;
        if (top < tooltipMargin) top = tooltipMargin;
        break;
      case TooltipPosition.right:
        left = targetRect.right + arrowSize + 8;
        top = (targetRect.center.dy - 80)
            .clamp(tooltipMargin, screenSize.height - 200);
        break;
      case TooltipPosition.left:
        left = targetRect.left - tooltipWidth - arrowSize - 8;
        if (left < tooltipMargin) left = tooltipMargin;
        top = (targetRect.center.dy - 80)
            .clamp(tooltipMargin, screenSize.height - 200);
        break;
      default:
        left = tooltipMargin;
        top = targetRect.bottom + arrowSize + 8;
    }

    return Positioned(
      left: left,
      top: top,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _spotlightAnim.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - _spotlightAnim.value)),
          child: Container(
            width: tooltipWidth,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: step.accentColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: step.accentColor.withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon + Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: step.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        step.icon,
                        color: step.accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  step.description,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                // Navigation buttons
                Row(
                  children: [
                    if (_currentStep > 0)
                      GestureDetector(
                        onTap: _prev,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white70, size: 18),
                        ),
                      ),
                    const Spacer(),
                    // Step counter
                    Text(
                      '${_currentStep + 1}/${widget.steps.length}',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _next,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isLast
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF43A047),
                                    Color(0xFF2E7D32)
                                  ],
                                )
                              : AppColors.blueButtonGradient,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: (isLast
                                      ? AppColors.accentGreen
                                      : AppColors.accentBlue)
                                  .withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLast ? 'Inizia!' : 'Avanti',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              isLast
                                  ? Icons.rocket_launch_rounded
                                  : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter that draws a dark overlay with a rounded-rect
/// spotlight hole, glowing border, and subtle pulse.
class _SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final double padding;
  final double borderRadius;
  final Color overlayColor;
  final double pulseScale;
  final Color accentColor;

  _SpotlightPainter({
    required this.targetRect,
    required this.padding,
    required this.borderRadius,
    required this.overlayColor,
    required this.pulseScale,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (targetRect == Rect.zero) {
      // No target yet, just paint the overlay
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = overlayColor,
      );
      return;
    }

    // Padded target rect with pulse
    final scaledPadding = padding * pulseScale;
    final holeRect = Rect.fromLTRB(
      targetRect.left - scaledPadding,
      targetRect.top - scaledPadding,
      targetRect.right + scaledPadding,
      targetRect.bottom + scaledPadding,
    );

    final rrect = RRect.fromRectAndRadius(
      holeRect,
      Radius.circular(borderRadius),
    );

    // Draw overlay with hole
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, Paint()..color = overlayColor);

    // Draw glow ring around the hole
    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(rrect, glowPaint);

    // Sharper border
    final borderPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.pulseScale != pulseScale ||
        oldDelegate.accentColor != accentColor;
  }
}
