import 'dart:convert';
import 'dart:js_interop';

@JS('initOcrWorker')
external JSPromise<JSAny?> _jsInitOcrWorker();

@JS('startOcrCamera')
external JSPromise<JSAny?> _jsStartOcrCamera(JSString containerId);

@JS('captureAndRecognize')
external JSPromise<JSAny?> _jsCaptureAndRecognize(JSString containerId);

@JS('stopOcrCamera')
external void _jsStopOcrCamera(JSString containerId);

@JS('createOcrContainer')
external JSObject _jsCreateOcrContainer(JSString id);

@JS('vibrateDevice')
external void _jsVibrateDevice(JSNumber ms);

/// Service for OCR-based card collector number recognition.
/// Uses Tesseract.js via JS bridge for client-side OCR.
class OcrService {
  static final OcrService _instance = OcrService._();
  factory OcrService() => _instance;
  OcrService._();

  bool _workerInitialized = false;

  /// Initialize the Tesseract.js worker (loads ~2MB model on first use).
  Future<void> initWorker() async {
    if (_workerInitialized) return;
    try {
      await _jsInitOcrWorker().toDart;
      _workerInitialized = true;
    } catch (e) {
      // Worker init failed, will retry on next call
    }
  }

  /// Start camera feed in the given container element.
  Future<Map<String, dynamic>> startCamera(String containerId) async {
    try {
      final result = await _jsStartOcrCamera(containerId.toJS).toDart;
      if (result == null) return {'error': 'No response'};
      return jsonDecode((result as JSString).toDart) as Map<String, dynamic>;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Capture current video frame and run OCR on it.
  Future<Map<String, dynamic>> captureAndRecognize(String containerId) async {
    try {
      final result = await _jsCaptureAndRecognize(containerId.toJS).toDart;
      if (result == null) return {'error': 'No response'};
      return jsonDecode((result as JSString).toDart) as Map<String, dynamic>;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Stop camera and release resources.
  void stopCamera(String containerId) {
    try {
      _jsStopOcrCamera(containerId.toJS);
    } catch (_) {}
  }

  /// Create a DOM container element for the camera view.
  Object createContainer(String id) {
    return _jsCreateOcrContainer(id.toJS);
  }

  /// Trigger device vibration (if supported).
  void vibrate([int ms = 200]) {
    try {
      _jsVibrateDevice(ms.toJS);
    } catch (_) {}
  }

  /// Extract collector number from OCR text using various TCG patterns.
  ///
  /// Supports formats:
  /// - `001/165` (number/total)
  /// - `SV049/SV100` (prefix + number/total)
  /// - `TG01/TG30` (prefix + number/total)
  /// - Various TCG collector number formats
  String? extractCollectorNumber(String ocrText) {
    if (ocrText.trim().isEmpty) return null;

    // Clean up OCR text: normalize whitespace
    final text = ocrText.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ');

    // Pattern 1: Prefix + number/total (e.g., SV049/SV100, TG01/TG30, SWSH049/SWSH100)
    final prefixPattern =
        RegExp(r'\b([A-Z]{1,5}\d{1,4})\s*/\s*([A-Z]{1,5}\d{1,4})\b');
    final prefixMatch = prefixPattern.firstMatch(text);
    if (prefixMatch != null) {
      return prefixMatch.group(1);
    }

    // Pattern 2: Simple number/total (e.g., 001/165, 49/100)
    final simplePattern = RegExp(r'\b(\d{1,4})\s*/\s*(\d{1,4})\b');
    for (final match in simplePattern.allMatches(text)) {
      final num = int.tryParse(match.group(1)!);
      final total = int.tryParse(match.group(2)!);
      // Sanity check: number should be <= total+50 (secret rares exceed total),
      // total should be reasonable for a card set
      if (num != null &&
          total != null &&
          num > 0 &&
          total >= 10 &&
          total <= 999 &&
          num <= total + 100) {
        return match.group(1)!;
      }
    }

    // Pattern 3: Hash + number pattern (e.g., #001, #49)
    final hashPattern = RegExp(r'#\s*(\d{1,4})\b');
    final hashMatch = hashPattern.firstMatch(text);
    if (hashMatch != null) {
      final num = int.tryParse(hashMatch.group(1)!);
      if (num != null && num > 0 && num <= 999) {
        return hashMatch.group(1)!;
      }
    }

    // Pattern 4: Pokémon-style with set code (e.g., "MEW 001")
    final setCodePattern = RegExp(r'\b([A-Z]{2,5})\s+(\d{2,4})\b');
    final setCodeMatch = setCodePattern.firstMatch(text);
    if (setCodeMatch != null) {
      final num = int.tryParse(setCodeMatch.group(2)!);
      if (num != null && num > 0 && num <= 999) {
        return setCodeMatch.group(2)!;
      }
    }

    return null;
  }
}
