import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/ocr_service.dart';
import '../models/card_blueprint.dart';

/// Mobile stub for OCR scanner.
/// Shows manual entry since camera OCR is web-only.
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

class _OcrScannerDialogState extends State<OcrScannerDialog> {
  final OcrService _ocrService = OcrService();
  final List<String> _foundNumbers = [];
  final List<_FoundCard> _foundCards = [];

  void _close() {
    Navigator.of(context).pop(_foundNumbers);
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
                            style: TextStyle(color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600))),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt,
                    color: AppColors.accentTeal, size: 48),
              ),
              const SizedBox(height: 24),
              const Text('Scanner OCR',
                  style: TextStyle(color: Colors.white, fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'Lo scanner con fotocamera è disponibile nella versione web.\nUsa l\'inserimento manuale per aggiungere carte.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary,
                    fontSize: 14, height: 1.5)),
              const SizedBox(height: 24),
              if (_foundCards.isNotEmpty) ...[
                Text('${_foundCards.length} carte aggiunte',
                    style: const TextStyle(color: AppColors.accentGreen,
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
              ],
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
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _close,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: _foundCards.isNotEmpty
                        ? AppColors.accentGreen
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    _foundCards.isNotEmpty ? 'Fatto ✓' : 'Chiudi',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoundCard {
  final String collectorNumber;
  final CardBlueprint? card;
  const _FoundCard({required this.collectorNumber, this.card});
}
