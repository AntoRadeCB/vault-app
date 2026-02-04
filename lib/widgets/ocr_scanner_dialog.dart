import 'dart:async';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/ocr_service.dart';
import '../models/card_blueprint.dart';

/// Full-screen OCR scanner for reading collector numbers from cards.
/// Returns the detected collector number string via Navigator.pop.
class OcrScannerDialog extends StatefulWidget {
  final List<CardBlueprint> expansionCards;

  const OcrScannerDialog({super.key, this.expansionCards = const []});

  /// Show the OCR scanner and return the detected collector number, or null if cancelled.
  static Future<String?> scan(BuildContext context,
      {List<CardBlueprint> expansionCards = const []}) {
    return Navigator.of(context).push<String>(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) =>
            OcrScannerDialog(expansionCards: expansionCards),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  State<OcrScannerDialog> createState() => _OcrScannerDialogState();
}

enum _ScanStatus { init, scanning, processing, found, error }

class _OcrScannerDialogState extends State<OcrScannerDialog> {
  final OcrService _ocrService = OcrService();

  late final String _viewType;
  late final String _containerId;

  _ScanStatus _status = _ScanStatus.init;
  String? _errorMessage;
  String? _foundNumber;
  CardBlueprint? _matchedCard;
  Timer? _scanTimer;
  bool _cameraReady = false;

  @override
  void initState() {
    super.initState();
    final ts = DateTime.now().millisecondsSinceEpoch;
    _viewType = 'ocr-camera-$ts';
    _containerId = 'ocr-container-$ts';
    _registerViewFactory();
    _initializeScanner();
  }

  void _registerViewFactory() {
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId, {Object? params}) {
        return _ocrService.createContainer(_containerId);
      },
    );
  }

  Future<void> _initializeScanner() async {
    // Start initializing OCR worker in background
    _ocrService.initWorker();

    // Small delay to let the HtmlElementView render and DOM element appear
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Start camera
    final result = await _ocrService.startCamera(_containerId);
    if (!mounted) return;

    if (result.containsKey('error')) {
      setState(() {
        _status = _ScanStatus.error;
        _errorMessage = result['error'] as String?;
      });
      return;
    }

    setState(() {
      _cameraReady = true;
      _status = _ScanStatus.scanning;
    });

    // Wait a bit for camera to warm up, then start periodic OCR
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    _startPeriodicScan();
  }

  void _startPeriodicScan() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _performOcrScan();
    });
    // Also do an immediate first scan
    _performOcrScan();
  }

  Future<void> _performOcrScan() async {
    if (_status == _ScanStatus.found || _status == _ScanStatus.error) return;
    if (_status == _ScanStatus.processing) return; // Already processing

    setState(() => _status = _ScanStatus.processing);

    try {
      final result = await _ocrService.captureAndRecognize(_containerId);

      if (!mounted) return;

      if (result.containsKey('error') &&
          result['error'] != 'Video not ready') {
        // Non-critical error, keep scanning
        setState(() => _status = _ScanStatus.scanning);
        return;
      }

      final text = result['text'] as String? ?? '';
      final collectorNumber = _ocrService.extractCollectorNumber(text);

      if (collectorNumber != null) {
        _scanTimer?.cancel();
        _ocrService.vibrate();

        // Try to match against expansion cards
        CardBlueprint? matched;
        if (widget.expansionCards.isNotEmpty) {
          matched = widget.expansionCards.where((c) {
            if (c.collectorNumber == null) return false;
            if (c.collectorNumber == collectorNumber) return true;
            if (c.collectorNumber!.toLowerCase() ==
                collectorNumber.toLowerCase()) return true;
            final cNum = int.tryParse(c.collectorNumber!);
            final oNum = int.tryParse(collectorNumber);
            return cNum != null && oNum != null && cNum == oNum;
          }).firstOrNull;
        }

        setState(() {
          _status = _ScanStatus.found;
          _foundNumber = collectorNumber;
          _matchedCard = matched;
        });

        // Auto-return after delay (longer if showing card info)
        await Future.delayed(Duration(milliseconds: matched != null ? 1200 : 600));
        if (mounted) {
          Navigator.of(context).pop(_foundNumber);
        }
      } else {
        setState(() => _status = _ScanStatus.scanning);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = _ScanStatus.scanning);
      }
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _ocrService.stopCamera(_containerId);
    super.dispose();
  }

  /// Manual entry fallback
  void _showManualEntry() {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Inserisci Numero Carta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Es. 001, SV049, TG01',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  hintText: 'Es. 001/165',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.cardDark,
                  prefixIcon: const Icon(Icons.tag,
                      color: AppColors.accentTeal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.accentTeal, width: 1.5),
                  ),
                ),
                onSubmitted: (value) {
                  final v = value.trim();
                  if (v.isNotEmpty) {
                    // Try to extract just the collector number from manual input
                    final extracted = _ocrService.extractCollectorNumber(v);
                    Navigator.pop(ctx);
                    Navigator.of(context).pop(extracted ?? v);
                  }
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Annulla',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final v = textController.text.trim();
                        if (v.isNotEmpty) {
                          final extracted =
                              _ocrService.extractCollectorNumber(v);
                          Navigator.pop(ctx);
                          Navigator.of(context).pop(extracted ?? v);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.accentTeal, Color(0xFF00897B)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Conferma',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera feed or error
          if (_status == _ScanStatus.error)
            _buildErrorView()
          else
            Positioned.fill(
              child: HtmlElementView(viewType: _viewType),
            ),

          // Dark overlay with card-shaped cutout (only when camera is working)
          if (_status != _ScanStatus.error)
            _CardScanOverlay(
              status: _status,
              foundNumber: _foundNumber,
            ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _circleButton(
                      icon: Icons.close,
                      onTap: () => Navigator.of(context).pop(null),
                    ),
                    const Expanded(
                      child: Text(
                        'Scansiona Carta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Spacer to balance the close button
                    const SizedBox(width: 42),
                  ],
                ),
              ),
            ),
          ),

          // Bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status card
                    _buildStatusCard(),
                    const SizedBox(height: 12),
                    // Manual entry button
                    GestureDetector(
                      onTap: _showManualEntry,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.keyboard,
                                color: Colors.white70, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Inserisci manualmente',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    IconData icon;
    String text;
    Color bgColor;
    Color borderColor;

    switch (_status) {
      case _ScanStatus.init:
        icon = Icons.hourglass_top;
        text = 'Caricamento OCR...';
        bgColor = AppColors.surface.withValues(alpha: 0.9);
        borderColor = Colors.white.withValues(alpha: 0.1);
        break;
      case _ScanStatus.scanning:
        icon = Icons.document_scanner;
        text = 'Inquadra la carta...';
        bgColor = AppColors.surface.withValues(alpha: 0.9);
        borderColor = AppColors.accentTeal.withValues(alpha: 0.3);
        break;
      case _ScanStatus.processing:
        icon = Icons.auto_awesome;
        text = 'Analisi in corso...';
        bgColor = AppColors.accentTeal.withValues(alpha: 0.15);
        borderColor = AppColors.accentTeal.withValues(alpha: 0.4);
        break;
      case _ScanStatus.found:
        icon = Icons.check_circle;
        if (_matchedCard != null) {
          final price = _matchedCard!.marketPrice != null
              ? ' — ${_matchedCard!.formattedPrice}'
              : '';
          text = '${_matchedCard!.name}$price';
        } else {
          text = 'Trovato: #$_foundNumber ✓';
        }
        bgColor = AppColors.accentGreen.withValues(alpha: 0.9);
        borderColor = AppColors.accentGreen.withValues(alpha: 0.5);
        break;
      case _ScanStatus.error:
        icon = Icons.error_outline;
        text = 'Errore';
        bgColor = AppColors.accentRed.withValues(alpha: 0.15);
        borderColor = AppColors.accentRed.withValues(alpha: 0.3);
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_status == _ScanStatus.processing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accentTeal,
              ),
            )
          else
            Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    final msg = _errorMessage ?? 'Errore sconosciuto';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.videocam_off,
                color: AppColors.accentRed,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Fotocamera non disponibile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _showManualEntry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentTeal, Color(0xFF00897B)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.keyboard, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Inserisci Manualmente',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

/// Draws a dark overlay with a card-shaped (portrait rectangle) transparent window.
class _CardScanOverlay extends StatelessWidget {
  final _ScanStatus status;
  final String? foundNumber;

  const _CardScanOverlay({
    required this.status,
    this.foundNumber,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Card ratio: 63mm x 88mm ≈ 2.5:3.5 ≈ 5:7
        final maxWidth = constraints.maxWidth * 0.72;
        final maxHeight = constraints.maxHeight * 0.55;
        // Calculate card dimensions maintaining 5:7 ratio
        double cardWidth = maxWidth;
        double cardHeight = cardWidth * (7 / 5);
        if (cardHeight > maxHeight) {
          cardHeight = maxHeight;
          cardWidth = cardHeight * (5 / 7);
        }

        final top = (constraints.maxHeight - cardHeight) / 2;
        final left = (constraints.maxWidth - cardWidth) / 2;

        return Stack(
          children: [
            // Dark overlay with cutout
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.6),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    top: top,
                    left: left,
                    child: Container(
                      width: cardWidth,
                      height: cardHeight,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Corner markers
            ..._buildCorners(top, left, cardWidth, cardHeight, constraints),

            // Scanning line animation (when scanning/processing)
            if (status == _ScanStatus.scanning ||
                status == _ScanStatus.processing)
              _ScanningLine(
                top: top,
                left: left,
                width: cardWidth,
                height: cardHeight,
              ),
          ],
        );
      },
    );
  }

  List<Widget> _buildCorners(double top, double left, double cardWidth,
      double cardHeight, BoxConstraints constraints) {
    final color = status == _ScanStatus.found
        ? AppColors.accentGreen
        : status == _ScanStatus.processing
            ? AppColors.accentTeal
            : AppColors.accentBlue;

    return [
      // Top-left
      Positioned(
        top: top - 2,
        left: left - 2,
        child: _corner(color, topLeft: true),
      ),
      // Top-right
      Positioned(
        top: top - 2,
        right: constraints.maxWidth - left - cardWidth - 2,
        child: _corner(color, topRight: true),
      ),
      // Bottom-left
      Positioned(
        bottom: constraints.maxHeight - top - cardHeight - 2,
        left: left - 2,
        child: _corner(color, bottomLeft: true),
      ),
      // Bottom-right
      Positioned(
        bottom: constraints.maxHeight - top - cardHeight - 2,
        right: constraints.maxWidth - left - cardWidth - 2,
        child: _corner(color, bottomRight: true),
      ),
    ];
  }

  Widget _corner(Color color,
      {bool topLeft = false,
      bool topRight = false,
      bool bottomLeft = false,
      bool bottomRight = false}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border(
          top: (topLeft || topRight)
              ? BorderSide(color: color, width: 3)
              : BorderSide.none,
          bottom: (bottomLeft || bottomRight)
              ? BorderSide(color: color, width: 3)
              : BorderSide.none,
          left: (topLeft || bottomLeft)
              ? BorderSide(color: color, width: 3)
              : BorderSide.none,
          right: (topRight || bottomRight)
              ? BorderSide(color: color, width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }
}

/// Animated scanning line that moves vertically within the card frame.
class _ScanningLine extends StatefulWidget {
  final double top;
  final double left;
  final double width;
  final double height;

  const _ScanningLine({
    required this.top,
    required this.left,
    required this.width,
    required this.height,
  });

  @override
  State<_ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final lineY =
            widget.top + _controller.value * (widget.height - 2);
        return Positioned(
          top: lineY,
          left: widget.left + 8,
          child: Container(
            width: widget.width - 16,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.accentTeal.withValues(alpha: 0.8),
                  AppColors.accentTeal,
                  AppColors.accentTeal.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentTeal.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
