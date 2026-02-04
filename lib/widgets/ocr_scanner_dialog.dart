import 'dart:async';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/ocr_service.dart';
import '../models/card_blueprint.dart';

/// Full-screen continuous OCR scanner.
/// Scans cards one after another. Shows name + price on each hit.
/// Returns a List<String> of all scanned collector numbers on close.
class OcrScannerDialog extends StatefulWidget {
  final List<CardBlueprint> expansionCards;

  const OcrScannerDialog({super.key, this.expansionCards = const []});

  /// Open the scanner. Returns list of collector numbers found.
  static Future<List<String>> scan(BuildContext context,
      {List<CardBlueprint> expansionCards = const []}) async {
    final result = await Navigator.of(context).push<List<String>>(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) =>
            OcrScannerDialog(expansionCards: expansionCards),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
    return result ?? [];
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
  Timer? _scanTimer;
  bool _cameraReady = false;

  // Continuous mode state
  final List<String> _foundNumbers = [];
  final List<_FoundCard> _foundCards = [];
  _FoundCard? _lastFound; // currently displayed card banner
  Timer? _bannerTimer;

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
    _ocrService.initWorker();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

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

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    _startPeriodicScan();
  }

  void _startPeriodicScan() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(milliseconds: 3000), (_) {
      _performOcrScan();
    });
    _performOcrScan();
  }

  Future<void> _performOcrScan() async {
    if (_status == _ScanStatus.error) return;
    if (_status == _ScanStatus.processing) return;
    if (_status == _ScanStatus.found) return; // pause while showing result

    setState(() => _status = _ScanStatus.processing);

    try {
      final result = await _ocrService.captureAndRecognize(_containerId);
      if (!mounted) return;

      if (result.containsKey('error') &&
          result['error'] != 'Video not ready') {
        setState(() => _status = _ScanStatus.scanning);
        return;
      }

      final text = result['text'] as String? ?? '';
      final collectorNumber = _ocrService.extractCollectorNumber(text);

      if (collectorNumber != null) {
        // Try to match to a card in the expansion
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

        _ocrService.vibrate();
        _foundNumbers.add(collectorNumber);

        final found = _FoundCard(
          collectorNumber: collectorNumber,
          card: matched,
        );
        _foundCards.add(found);

        setState(() {
          _status = _ScanStatus.found;
          _lastFound = found;
        });

        // Show the banner for 2 seconds, then resume scanning
        _bannerTimer?.cancel();
        _bannerTimer = Timer(const Duration(milliseconds: 2000), () {
          if (mounted) {
            setState(() {
              _status = _ScanStatus.scanning;
              _lastFound = null;
            });
          }
        });
      } else {
        setState(() => _status = _ScanStatus.scanning);
      }
    } catch (e) {
      if (mounted) setState(() => _status = _ScanStatus.scanning);
    }
  }

  void _close() {
    Navigator.of(context).pop(_foundNumbers);
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _bannerTimer?.cancel();
    _ocrService.stopCamera(_containerId);
    super.dispose();
  }

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
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Inserisci Numero Carta',
                  style: TextStyle(color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Es. 001/165, SV049, TG01',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white, fontSize: 18,
                    fontFamily: 'monospace', letterSpacing: 2),
                decoration: InputDecoration(
                  hintText: 'Es. 001/165',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true, fillColor: AppColors.cardDark,
                  prefixIcon: const Icon(Icons.tag, color: AppColors.accentTeal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.06))),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.06))),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.accentTeal, width: 1.5)),
                ),
                onSubmitted: (value) {
                  final v = value.trim();
                  if (v.isNotEmpty) {
                    final extracted = _ocrService.extractCollectorNumber(v);
                    final num = extracted ?? v;
                    _foundNumbers.add(num);

                    CardBlueprint? matched;
                    if (widget.expansionCards.isNotEmpty) {
                      matched = widget.expansionCards.where((c) {
                        if (c.collectorNumber == null) return false;
                        if (c.collectorNumber == num) return true;
                        final cN = int.tryParse(c.collectorNumber!);
                        final oN = int.tryParse(num);
                        return cN != null && oN != null && cN == oN;
                      }).firstOrNull;
                    }

                    _foundCards.add(_FoundCard(
                        collectorNumber: num, card: matched));
                    Navigator.pop(ctx);
                    setState(() {});
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
                          borderRadius: BorderRadius.circular(12)),
                        child: const Center(child: Text('Annulla',
                            style: TextStyle(color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600))),
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
                          final num = extracted ?? v;
                          _foundNumbers.add(num);
                          _foundCards.add(_FoundCard(
                              collectorNumber: num, card: null));
                          Navigator.pop(ctx);
                          setState(() {});
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.accentTeal, Color(0xFF00897B)]),
                          borderRadius: BorderRadius.circular(12)),
                        child: const Center(child: Text('Aggiungi',
                            style: TextStyle(color: Colors.white,
                                fontWeight: FontWeight.bold))),
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
          // Camera feed
          if (_status == _ScanStatus.error)
            _buildErrorView()
          else
            Positioned.fill(
              child: HtmlElementView(viewType: _viewType),
            ),

          // Overlay
          if (_status != _ScanStatus.error)
            _CardScanOverlay(
              status: _status,
            ),

          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _circleButton(
                      icon: Icons.close,
                      onTap: _close,
                    ),
                    const Expanded(
                      child: Text('Scansiona Carte',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ),
                    // Scanned count badge
                    if (_foundCards.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_foundCards.length}',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      const SizedBox(width: 42),
                  ],
                ),
              ),
            ),
          ),

          // Found card banner (animated, appears when card detected)
          if (_lastFound != null)
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 56, left: 20, right: 20),
                  child: _buildFoundBanner(_lastFound!),
                ),
              ),
            ),

          // Bottom bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status indicator
                    _buildStatusPill(),
                    const SizedBox(height: 10),
                    // Found cards scroll strip
                    if (_foundCards.isNotEmpty) ...[
                      _buildFoundStrip(),
                      const SizedBox(height: 10),
                    ],
                    // Bottom buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _showManualEntry,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.keyboard,
                                      color: Colors.white70, size: 18),
                                  SizedBox(width: 6),
                                  Text('Manuale',
                                      style: TextStyle(color: Colors.white70,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: _close,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _foundCards.isNotEmpty
                                      ? [const Color(0xFF43A047),
                                         const Color(0xFF2E7D32)]
                                      : [Colors.white.withValues(alpha: 0.08),
                                         Colors.white.withValues(alpha: 0.08)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _foundCards.isNotEmpty
                                        ? Icons.check_circle
                                        : Icons.close,
                                    color: Colors.white,
                                    size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    _foundCards.isNotEmpty
                                        ? 'Fatto (${_foundCards.length})'
                                        : 'Chiudi',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                ],
                              ),
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
        ],
      ),
    );
  }

  Widget _buildFoundBanner(_FoundCard found) {
    final card = found.card;
    final hasCard = card != null;
    final price = card?.marketPrice != null
        ? card!.formattedPrice
        : null;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (_, value, child) => Transform.translate(
        offset: Offset(0, -20 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.accentGreen.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGreen.withValues(alpha: 0.4),
              blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: Row(
          children: [
            // Card image
            if (hasCard && card.imageUrl != null)
              Container(
                width: 36, height: 50,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(card.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.style, color: Colors.white54, size: 20)),
                ),
              )
            else
              Container(
                width: 36, height: 36,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.check,
                    color: Colors.white, size: 22),
              ),
            // Card info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasCard ? card.name : '#${found.collectorNumber}',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  if (hasCard) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text('#${found.collectorNumber}',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 11)),
                        if (card.rarity != null) ...[
                          const SizedBox(width: 6),
                          Text('• ${card.rarity}',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 11)),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Price
            if (price != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8)),
                child: Text(price,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill() {
    String text;
    Color color;

    switch (_status) {
      case _ScanStatus.init:
        text = 'Caricamento OCR...';
        color = AppColors.textMuted;
        break;
      case _ScanStatus.scanning:
        text = '📷 Inquadra una carta';
        color = AppColors.accentTeal;
        break;
      case _ScanStatus.processing:
        text = '⏳ Analisi...';
        color = AppColors.accentTeal;
        break;
      case _ScanStatus.found:
        text = '✅ Carta trovata!';
        color = AppColors.accentGreen;
        break;
      case _ScanStatus.error:
        text = 'Errore';
        color = AppColors.accentRed;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_status == _ScanStatus.processing)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(width: 12, height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: color)),
            ),
          Text(text,
              style: TextStyle(color: color, fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _removeFoundCard(int index) {
    setState(() {
      _foundCards.removeAt(index);
      _foundNumbers.removeAt(index);
    });
  }

  /// Horizontal scroll strip showing recently found cards (tap to remove)
  Widget _buildFoundStrip() {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _foundCards.length,
        reverse: true, // newest first
        itemBuilder: (_, i) {
          final realIndex = _foundCards.length - 1 - i;
          final found = _foundCards[realIndex];
          final card = found.card;
          return GestureDetector(
            onTap: () => _removeFoundCard(realIndex),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.accentGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (card?.imageUrl != null)
                    Container(
                      width: 28, height: 40,
                      margin: const EdgeInsets.only(right: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Image.network(card!.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink()),
                      ),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(
                          card?.name ?? '#${found.collectorNumber}',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 11, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (card?.marketPrice != null)
                        Text(card!.formattedPrice,
                            style: const TextStyle(
                                color: AppColors.accentGreen,
                                fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.close,
                      color: Colors.white.withValues(alpha: 0.4), size: 14),
                ],
              ),
            ),
          );
        },
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
                shape: BoxShape.circle),
              child: const Icon(Icons.videocam_off,
                  color: AppColors.accentRed, size: 48),
            ),
            const SizedBox(height: 24),
            const Text('Fotocamera non disponibile',
                style: TextStyle(color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(msg, textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary,
                    fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _showManualEntry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentTeal, Color(0xFF00897B)]),
                  borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.keyboard, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text('Inserisci Manualmente',
                        style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _FoundCard {
  final String collectorNumber;
  final CardBlueprint? card;
  const _FoundCard({required this.collectorNumber, this.card});
}

/// Dark overlay with card-shaped cutout.
class _CardScanOverlay extends StatelessWidget {
  final _ScanStatus status;
  const _CardScanOverlay({required this.status});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth * 0.72;
        final maxHeight = constraints.maxHeight * 0.50;
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
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.55),
                BlendMode.srcOut),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut)),
                  Positioned(
                    top: top, left: left,
                    child: Container(
                      width: cardWidth, height: cardHeight,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12)))),
                ],
              ),
            ),
            ..._corners(top, left, cardWidth, cardHeight, constraints),
            if (status == _ScanStatus.scanning ||
                status == _ScanStatus.processing)
              _ScanningLine(
                  top: top, left: left,
                  width: cardWidth, height: cardHeight),
          ],
        );
      },
    );
  }

  List<Widget> _corners(double top, double left, double w, double h,
      BoxConstraints c) {
    final color = status == _ScanStatus.found
        ? AppColors.accentGreen
        : status == _ScanStatus.processing
            ? AppColors.accentTeal
            : AppColors.accentBlue;
    return [
      Positioned(top: top - 2, left: left - 2,
          child: _corner(color, tl: true)),
      Positioned(top: top - 2, right: c.maxWidth - left - w - 2,
          child: _corner(color, tr: true)),
      Positioned(bottom: c.maxHeight - top - h - 2, left: left - 2,
          child: _corner(color, bl: true)),
      Positioned(bottom: c.maxHeight - top - h - 2,
          right: c.maxWidth - left - w - 2,
          child: _corner(color, br: true)),
    ];
  }

  Widget _corner(Color color, {bool tl = false, bool tr = false,
      bool bl = false, bool br = false}) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        border: Border(
          top: (tl || tr) ? BorderSide(color: color, width: 3)
              : BorderSide.none,
          bottom: (bl || br) ? BorderSide(color: color, width: 3)
              : BorderSide.none,
          left: (tl || bl) ? BorderSide(color: color, width: 3)
              : BorderSide.none,
          right: (tr || br) ? BorderSide(color: color, width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }
}

class _ScanningLine extends StatefulWidget {
  final double top, left, width, height;
  const _ScanningLine({required this.top, required this.left,
      required this.width, required this.height});
  @override
  State<_ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final y = widget.top + _c.value * (widget.height - 2);
        return Positioned(
          top: y, left: widget.left + 8,
          child: Container(
            width: widget.width - 16, height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                AppColors.accentTeal.withValues(alpha: 0.8),
                AppColors.accentTeal,
                AppColors.accentTeal.withValues(alpha: 0.8),
                Colors.transparent,
              ]),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentTeal.withValues(alpha: 0.4),
                  blurRadius: 8, spreadRadius: 2),
              ],
            ),
          ),
        );
      },
    );
  }
}
