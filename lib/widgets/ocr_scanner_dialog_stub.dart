import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/ocr_service.dart';
import '../models/card_blueprint.dart';

/// Mobile OCR scanner with live camera preview.
/// Same UI as the web version — card overlay, scan button, found card strip.
class OcrScannerDialog extends StatefulWidget {
  final List<CardBlueprint> expansionCards;
  final String mode;

  const OcrScannerDialog({
    super.key,
    this.expansionCards = const [],
    this.mode = 'ocr',
  });

  static Future<List<String>> scan(BuildContext context,
      {List<CardBlueprint> expansionCards = const [],
      String mode = 'ocr'}) async {
    final result = await Navigator.of(context).push<List<String>>(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) =>
            OcrScannerDialog(expansionCards: expansionCards, mode: mode),
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

enum _ScanStatus { init, scanning, processing, found, error, scanError }

class _OcrScannerDialogState extends State<OcrScannerDialog> {
  final OcrService _ocrService = OcrService();

  CameraController? _cameraController;
  _ScanStatus _status = _ScanStatus.init;
  String? _errorMessage;
  bool _cameraReady = false;
  bool _isBusy = false;

  final List<String> _foundNumbers = [];
  final List<_FoundCard> _foundCards = [];
  _FoundCard? _lastFound;
  String? _lastError;
  Timer? _bannerTimer;
  final Set<String> _recentlyFound = {};

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _status = _ScanStatus.error;
          _errorMessage = 'Nessuna fotocamera disponibile';
        });
        return;
      }

      // Prefer back camera
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _cameraReady = true;
        _status = _ScanStatus.scanning;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = _ScanStatus.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _performOcrScan() async {
    if (_isBusy || !_cameraReady || _cameraController == null) return;

    _isBusy = true;
    setState(() => _status = _ScanStatus.processing);

    try {
      // Capture photo
      final xFile = await _cameraController!.takePicture();
      final bytes = await File(xFile.path).readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // Clean up temp file
      try { await File(xFile.path).delete(); } catch (_) {}

      // Build context JSON
      String? contextJson;
      if (widget.mode == 'premium' && widget.expansionCards.isNotEmpty) {
        final cardList = widget.expansionCards.map((c) {
          final num = c.collectorNumber ?? '?';
          final parts = [num, c.name];
          if (c.rarity != null) parts.add(c.rarity!);
          if (c.version != null && c.version!.isNotEmpty) parts.add(c.version!);
          return parts.join('|');
        }).toList();
        final expName = widget.expansionCards.first.expansionName;
        contextJson = jsonEncode({
          'mode': 'premium',
          if (expName != null) 'expansion': expName,
          'cards': cardList,
        });
      } else {
        contextJson = jsonEncode({'mode': widget.mode});
      }

      // Call Cloud Function
      final result = await _ocrService.recognizeFromBase64(base64Image, contextJson: contextJson);
      if (!mounted) return;

      if (result.containsKey('error')) {
        final err = result['error'] as String? ?? 'Errore sconosciuto';
        _showErrorBanner(err);
        setState(() => _status = _ScanStatus.scanning);
        return;
      }

      // Process AI response
      final aiCards = result['cards'] as List? ?? [];
      final fullResponse = result['aiResult'] is Map
          ? (result['aiResult'] as Map)['fullResponse'] as String? ?? ''
          : '';

      int matchedCount = 0;
      int failedCount = 0;
      String? lastFailedName;

      if (aiCards.isNotEmpty || (result['cardName'] as String? ?? '').isNotEmpty) {
        final lines = fullResponse.isNotEmpty
            ? fullResponse.split('\n').where((l) => l.trim().isNotEmpty && l.trim() != 'NONE').toList()
            : [(result['cardName'] as String? ?? '')];

        for (final line in lines) {
          if (line.isEmpty || line == 'NONE') continue;
          final matched = _processFoundCardByName(line);
          if (matched) {
            matchedCount++;
          } else {
            failedCount++;
            lastFailedName = line;
          }
        }

        if (matchedCount == 0 && failedCount == 0) {
          _showErrorBanner('📷 Carta non riconosciuta, riprova');
        } else if (failedCount > 0 && matchedCount == 0) {
          _showErrorBanner('⚠️ "${lastFailedName ?? 'carta'}" non trovata nell\'espansione');
        }
      } else {
        _showErrorBanner('📷 Nessuna carta riconosciuta, riprova');
      }

      if (matchedCount == 0) {
        setState(() => _status = _ScanStatus.scanning);
      }
    } catch (e) {
      if (mounted) {
        _showErrorBanner(e.toString());
        setState(() => _status = _ScanStatus.scanning);
      }
    } finally {
      _isBusy = false;
    }
  }

  bool _processFoundCardByName(String aiCardName) {
    final dedupeKey = aiCardName.toLowerCase().trim();
    if (_recentlyFound.contains(dedupeKey)) return true;
    _recentlyFound.add(dedupeKey);
    Future.delayed(const Duration(seconds: 10), () {
      _recentlyFound.remove(dedupeKey);
    });

    String? aiCollectorNum;
    String aiName = aiCardName.trim();

    final pipeIdx = aiName.indexOf('|');
    if (pipeIdx > 0) {
      final firstPart = aiName.substring(0, pipeIdx).trim();
      final secondPart = aiName.substring(pipeIdx + 1).trim();
      var cleaned = firstPart
          .replaceAll(RegExp(r'^[A-Za-z]{2,}[\s.\-_]*'), '')
          .replaceAll(RegExp(r'/\d+$'), '')
          .trim();
      if (cleaned.contains(RegExp(r'\d'))) {
        aiCollectorNum = cleaned;
        aiName = secondPart;
      }
    }

    CardBlueprint? matched;
    final aiNameLower = aiName.toLowerCase().trim();

    if (widget.expansionCards.isNotEmpty) {
      if (aiCollectorNum != null) {
        final aiNum = int.tryParse(aiCollectorNum.replaceAll(RegExp(r'[^0-9]'), ''));
        final aiSuffix = aiCollectorNum.replaceAll(RegExp(r'^[0-9]+'), '');
        matched = widget.expansionCards.where((c) {
          if (c.collectorNumber == null) return false;
          final cn = c.collectorNumber!;
          if (cn == aiCollectorNum) return true;
          final cardNum = int.tryParse(cn.replaceAll(RegExp(r'[^0-9]'), ''));
          final cardSuffix = cn.replaceAll(RegExp(r'^[0-9]+'), '');
          return aiNum != null && cardNum != null && aiNum == cardNum && aiSuffix == cardSuffix;
        }).firstOrNull;
      }

      if (matched == null) {
        matched = widget.expansionCards
            .where((c) => c.name.toLowerCase() == aiNameLower)
            .firstOrNull;
      }

      if (matched == null) {
        matched = widget.expansionCards.where((c) =>
            c.name.toLowerCase().contains(aiNameLower) ||
            aiNameLower.contains(c.name.toLowerCase())).firstOrNull;
      }

      if (matched == null) {
        final aiWords = aiNameLower.split(RegExp(r'[\s\-_]+')).where((w) => w.length > 1).toSet();
        int bestScore = 0;
        for (final c in widget.expansionCards) {
          final cardWords = c.name.toLowerCase().split(RegExp(r'[\s\-_]+')).where((w) => w.length > 1).toSet();
          final overlap = aiWords.intersection(cardWords).length;
          if (overlap > bestScore && overlap >= 1) {
            bestScore = overlap;
            matched = c;
          }
        }
      }

      if (matched == null) return false;
    }

    _ocrService.vibrate();
    final collectorNumber = matched?.collectorNumber ?? aiCardName;
    _foundNumbers.add(collectorNumber);

    final found = _FoundCard(collectorNumber: collectorNumber, card: matched);
    _foundCards.add(found);

    setState(() {
      _status = _ScanStatus.found;
      _lastFound = found;
      _lastError = null;
    });

    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) setState(() { _status = _ScanStatus.scanning; _lastFound = null; });
    });
    return true;
  }

  void _showErrorBanner(String error) {
    setState(() {
      _status = _ScanStatus.scanError;
      _lastError = error;
      _lastFound = null;
    });
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) setState(() { _status = _ScanStatus.scanning; _lastError = null; });
    });
  }

  void _close() {
    Navigator.of(context).pop(_foundNumbers);
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _cameraController?.dispose();
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
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Es. 001/165, SV049, TG01',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontFamily: 'monospace', letterSpacing: 2),
                decoration: InputDecoration(
                  hintText: 'Es. 001/165',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true, fillColor: AppColors.cardDark,
                  prefixIcon: const Icon(Icons.tag, color: AppColors.accentTeal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accentTeal, width: 1.5)),
                ),
                onSubmitted: (value) => _addManual(ctx, value),
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
                            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _addManual(ctx, textController.text),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.accentTeal, Color(0xFF00897B)]),
                          borderRadius: BorderRadius.circular(12)),
                        child: const Center(child: Text('Aggiungi',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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

  void _addManual(BuildContext ctx, String value) {
    final v = value.trim();
    if (v.isEmpty) return;
    final extracted = _ocrService.extractCollectorNumber(v);
    final num = extracted ?? v;

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

    setState(() {
      _foundNumbers.add(num);
      _foundCards.add(_FoundCard(collectorNumber: num, card: matched));
    });
    Navigator.pop(ctx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview or error
          if (_status == _ScanStatus.error)
            _buildErrorView()
          else if (_cameraReady && _cameraController != null)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? 1920,
                  height: _cameraController!.value.previewSize?.width ?? 1080,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: AppColors.accentTeal)),

          // Card overlay
          if (_status != _ScanStatus.error && _cameraReady)
            _CardScanOverlay(status: _status),

          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _circleButton(icon: Icons.close, onTap: _close),
                    Expanded(
                      child: Text(
                        widget.expansionCards.isEmpty
                            ? 'Scansiona Carte'
                            : 'Scansiona (${widget.expansionCards.length} carte)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (_foundCards.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${_foundCards.length}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      )
                    else
                      const SizedBox(width: 42),
                  ],
                ),
              ),
            ),
          ),

          // Found card banner
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

          // Error banner
          if (_lastError != null)
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 56, left: 20, right: 20),
                  child: _buildErrorBanner(_lastError!),
                ),
              ),
            ),

          // Bottom bar
          if (_status != _ScanStatus.error)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_foundCards.isNotEmpty) ...[
                        _buildFoundStrip(),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Manual entry
                          GestureDetector(
                            onTap: _showManualEntry,
                            child: Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: const Icon(Icons.keyboard, color: Colors.white70, size: 22),
                            ),
                          ),
                          // Big scan button
                          GestureDetector(
                            onTap: (_isBusy || !_cameraReady) ? null : _performOcrScan,
                            child: Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isBusy ? Colors.orange : Colors.white,
                                ),
                                child: _isBusy
                                    ? const Padding(
                                        padding: EdgeInsets.all(18),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.camera_alt, color: Colors.black87, size: 30),
                              ),
                            ),
                          ),
                          // Done / Close
                          GestureDetector(
                            onTap: _close,
                            child: Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: _foundCards.isNotEmpty
                                    ? AppColors.accentGreen.withValues(alpha: 0.9)
                                    : Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: _foundCards.isNotEmpty
                                  ? Center(
                                      child: Text('${_foundCards.length}✓',
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                    )
                                  : const Icon(Icons.close, color: Colors.white70, size: 22),
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
    final price = card?.marketPrice != null ? card!.formattedPrice : null;
    final foundIndex = _foundCards.indexOf(found);
    final hasVariants = hasCard && _getVariantsFor(card).isNotEmpty;

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
            BoxShadow(color: AppColors.accentGreen.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: Row(
          children: [
            if (hasCard && card.imageUrl != null)
              Container(
                width: 36, height: 50,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(card.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.style, color: Colors.white54, size: 20)),
                ),
              )
            else
              Container(
                width: 36, height: 36,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.check, color: Colors.white, size: 22),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(hasCard ? card.name : '#${found.collectorNumber}',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (hasCard) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      Text('#${found.collectorNumber}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
                      if (card.rarity != null) ...[
                        const SizedBox(width: 6),
                        Text('• ${card.rarity}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                      ],
                    ]),
                  ],
                ],
              ),
            ),
            if (price != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(price,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            if (hasVariants && foundIndex >= 0) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showVariantPicker(foundIndex),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.swap_horiz, color: Colors.white, size: 18),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    String shortError = error;
    if (shortError.length > 80) shortError = '${shortError.substring(0, 77)}...';

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
          color: AppColors.accentRed.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppColors.accentRed.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.error_outline, color: Colors.white, size: 22),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Errore scansione',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(shortError,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildFoundStrip() {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _foundCards.length,
        reverse: true,
        itemBuilder: (_, i) {
          final realIndex = _foundCards.length - 1 - i;
          final found = _foundCards[realIndex];
          final card = found.card;
          final hasVariants = card != null && _getVariantsFor(card).isNotEmpty;
          return GestureDetector(
            onTap: hasVariants
                ? () => _showVariantPicker(realIndex)
                : () => _removeFoundCard(realIndex),
            onLongPress: () => _removeFoundCard(realIndex),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.3)),
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
                        child: Image.network(card!.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                      ),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(card?.name ?? '#${found.collectorNumber}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        if (card?.marketPrice != null)
                          Text(card!.formattedPrice,
                              style: const TextStyle(
                                  color: AppColors.accentGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                        if (card?.version != null && card!.version!.isNotEmpty) ...[
                          if (card.marketPrice != null) const SizedBox(width: 4),
                          Text(card.version!,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 9)),
                        ],
                      ]),
                    ],
                  ),
                  const SizedBox(width: 4),
                  hasVariants
                      ? Icon(Icons.swap_horiz, color: AppColors.accentBlue.withValues(alpha: 0.8), size: 16)
                      : Icon(Icons.close, color: Colors.white.withValues(alpha: 0.4), size: 14),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _removeFoundCard(int index) {
    setState(() {
      _foundCards.removeAt(index);
      _foundNumbers.removeAt(index);
    });
  }

  List<CardBlueprint> _getVariantsFor(CardBlueprint card) {
    return widget.expansionCards.where((c) => c.name == card.name && c.id != card.id).toList();
  }

  void _swapFoundCard(int index, CardBlueprint newCard) {
    setState(() {
      _foundCards[index] = _FoundCard(
        collectorNumber: newCard.collectorNumber ?? _foundCards[index].collectorNumber,
        card: newCard,
      );
      _foundNumbers[index] = newCard.collectorNumber ?? _foundNumbers[index];
      if (_lastFound?.card?.id == _foundCards[index].card?.id || index == _foundCards.length - 1) {
        _lastFound = _foundCards[index];
      }
    });
  }

  void _showVariantPicker(int index) {
    final found = _foundCards[index];
    final card = found.card;
    if (card == null) return;
    final variants = _getVariantsFor(card);
    if (variants.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.5),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Varianti di ${card.name}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildVariantTile(card, isCurrent: true, onTap: () => Navigator.pop(ctx)),
                  const Divider(color: Colors.white12, height: 1),
                  ...variants.map((v) => _buildVariantTile(v, isCurrent: false, onTap: () {
                    Navigator.pop(ctx);
                    _swapFoundCard(index, v);
                  })),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantTile(CardBlueprint card, {required bool isCurrent, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 40, height: 56,
          child: card.imageUrl != null
              ? Image.network(card.imageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      color: card.rarityColor.withValues(alpha: 0.15),
                      child: Icon(Icons.style, color: card.rarityColor, size: 18)))
              : Container(
                  color: card.rarityColor.withValues(alpha: 0.15),
                  child: Icon(Icons.style, color: card.rarityColor, size: 18)),
        ),
      ),
      title: Text('#${card.collectorNumber ?? '?'} — ${card.name}',
          style: TextStyle(
              color: isCurrent ? AppColors.accentGreen : Colors.white,
              fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(
        [if (card.rarity != null) card.rarity!, if (card.version != null && card.version!.isNotEmpty) card.version!]
            .join(' · '),
        style: TextStyle(
            color: isCurrent ? AppColors.accentGreen.withValues(alpha: 0.7) : AppColors.textMuted, fontSize: 11),
      ),
      trailing: isCurrent
          ? const Icon(Icons.check_circle, color: AppColors.accentGreen, size: 20)
          : Icon(Icons.swap_horiz, color: Colors.white.withValues(alpha: 0.4), size: 20),
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
                  color: AppColors.accentRed.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.videocam_off, color: AppColors.accentRed, size: 48),
            ),
            const SizedBox(height: 24),
            const Text('Fotocamera non disponibile',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _showManualEntry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.accentTeal, Color(0xFF00897B)]),
                    borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.keyboard, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text('Inserisci Manualmente',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
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

/// Dark overlay with card-shaped cutout — same as web version.
class _CardScanOverlay extends StatelessWidget {
  final _ScanStatus status;
  const _CardScanOverlay({required this.status});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const cardRatio = 0.714;
        final areaHeight = constraints.maxHeight * 0.60;
        final areaWidth = (areaHeight * cardRatio).clamp(0.0, constraints.maxWidth * 0.75);
        final top = (constraints.maxHeight - areaHeight) / 2 - 20;
        final left = (constraints.maxWidth - areaWidth) / 2;

        return Stack(
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.45), BlendMode.srcOut),
              child: Stack(children: [
                Container(
                    decoration: const BoxDecoration(color: Colors.black, backgroundBlendMode: BlendMode.dstOut)),
                Positioned(
                  top: top, left: left,
                  child: Container(
                      width: areaWidth, height: areaHeight,
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16))),
                ),
              ]),
            ),
            ..._corners(top, left, areaWidth, areaHeight, constraints),
          ],
        );
      },
    );
  }

  List<Widget> _corners(double top, double left, double w, double h, BoxConstraints c) {
    final color = status == _ScanStatus.found
        ? AppColors.accentGreen
        : status == _ScanStatus.processing
            ? AppColors.accentTeal
            : status == _ScanStatus.scanError
                ? AppColors.accentRed
                : AppColors.accentBlue;
    return [
      Positioned(top: top - 2, left: left - 2, child: _corner(color, tl: true)),
      Positioned(top: top - 2, right: c.maxWidth - left - w - 2, child: _corner(color, tr: true)),
      Positioned(bottom: c.maxHeight - top - h - 2, left: left - 2, child: _corner(color, bl: true)),
      Positioned(
          bottom: c.maxHeight - top - h - 2, right: c.maxWidth - left - w - 2, child: _corner(color, br: true)),
    ];
  }

  Widget _corner(Color color, {bool tl = false, bool tr = false, bool bl = false, bool br = false}) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        border: Border(
          top: (tl || tr) ? BorderSide(color: color, width: 3) : BorderSide.none,
          bottom: (bl || br) ? BorderSide(color: color, width: 3) : BorderSide.none,
          left: (tl || bl) ? BorderSide(color: color, width: 3) : BorderSide.none,
          right: (tr || br) ? BorderSide(color: color, width: 3) : BorderSide.none,
        ),
      ),
    );
  }
}
