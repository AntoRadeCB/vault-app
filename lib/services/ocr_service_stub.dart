import 'dart:convert';

/// Stub OCR service for non-web platforms.
/// Camera features are not available — only collector number parsing works.
class OcrService {
  static final OcrService _instance = OcrService._();
  factory OcrService() => _instance;
  OcrService._();

  Future<void> initWorker() async {}

  Future<Map<String, dynamic>> startCamera(String containerId) async {
    return {'error': 'Camera OCR non disponibile su questa piattaforma. Usa l\'inserimento manuale.'};
  }

  Future<Map<String, dynamic>> captureAndRecognize(String containerId, {String? contextJson}) async {
    return {'error': 'OCR non disponibile su questa piattaforma'};
  }

  void stopCamera(String containerId) {}

  Object createContainer(String id) => Object();

  void vibrate([int ms = 200]) {}

  String? extractCollectorNumber(String text) {
    if (text.trim().isEmpty) return null;
    final parts = text.split('|');
    var numPart = parts[0].trim();
    if (numPart.isEmpty || numPart == 'NONE') return null;
    final setPrefixMatch = RegExp(r'^[A-Za-z]{2,}[\.\s\-_]*(\d+.*)$').firstMatch(numPart);
    if (setPrefixMatch != null) numPart = setPrefixMatch.group(1)!.trim();
    final slashMatch = RegExp(r'^([A-Za-z]*\d+)\s*[/\\]').firstMatch(numPart);
    if (slashMatch != null) return slashMatch.group(1)!;
    final codeMatch = RegExp(r'^([A-Za-z]*\d+)$').firstMatch(numPart);
    if (codeMatch != null) return codeMatch.group(1)!;
    if (RegExp(r'\d').hasMatch(numPart)) return numPart;
    return null;
  }
}
