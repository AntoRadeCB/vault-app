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
  /// The text may come from multiple zones separated by " | ".
  String? extractCollectorNumber(String ocrText) {
    if (ocrText.trim().isEmpty) return null;

    // Process each zone's text separately for better accuracy
    final zones = ocrText.split(' | ');
    for (final zone in zones) {
      final result = _extractFromZone(zone);
      if (result != null) return result;
    }
    // Try on the combined text as fallback
    return _extractFromZone(ocrText);
  }

  String? _extractFromZone(String rawText) {
    if (rawText.trim().isEmpty) return null;

    // Clean up OCR text: normalize whitespace, fix common OCR mistakes
    String text = rawText
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        // Common OCR misreads
        .replaceAll('O', '0')  // O → 0 in number context
        .replaceAll('o', '0')
        .replaceAll('l', '1')  // lowercase L → 1
        .replaceAll('I', '1')  // uppercase I → 1
        .replaceAll('S', '5')  // S → 5
        .replaceAll('B', '8')  // B → 8
        .trim();

    // Also keep original for prefix patterns (where letters matter)
    final origText = rawText
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Pattern 1: Prefix + number/total (e.g., SV049/SV100, TG01/TG30)
    // Use original text (letters needed)
    final prefixPattern =
        RegExp(r'([A-Za-z]{1,5}\d{1,4})\s*[/\\]\s*([A-Za-z]{1,5}\d{1,4})',
            caseSensitive: false);
    final prefixMatch = prefixPattern.firstMatch(origText);
    if (prefixMatch != null) {
      return prefixMatch.group(1)!.toUpperCase();
    }

    // Pattern 2: Simple number/total (e.g., 001/165, 49/100)
    // Use cleaned text (numbers corrected)
    final simplePattern = RegExp(r'(\d{1,4})\s*[/\\]\s*(\d{1,4})');
    for (final match in simplePattern.allMatches(text)) {
      final numStr = match.group(1)!;
      final totalStr = match.group(2)!;
      final num = int.tryParse(numStr);
      final total = int.tryParse(totalStr);
      if (num != null &&
          total != null &&
          num > 0 &&
          total >= 5 &&
          total <= 999 &&
          num <= total + 150) {
        // Pad to match catalog format (e.g., "1" → "001" if total is 3 digits)
        final digits = totalStr.length;
        return numStr.padLeft(digits, '0');
      }
    }

    // Also try on original text for number/total
    for (final match in simplePattern.allMatches(origText)) {
      final numStr = match.group(1)!;
      final totalStr = match.group(2)!;
      final num = int.tryParse(numStr);
      final total = int.tryParse(totalStr);
      if (num != null &&
          total != null &&
          num > 0 &&
          total >= 5 &&
          total <= 999 &&
          num <= total + 150) {
        final digits = totalStr.length;
        return numStr.padLeft(digits, '0');
      }
    }

    // Pattern 3: Hash + number (e.g., #001, #49)
    final hashPattern = RegExp(r'#\s*(\d{1,4})\b');
    final hashMatch = hashPattern.firstMatch(origText) ??
        hashPattern.firstMatch(text);
    if (hashMatch != null) {
      final num = int.tryParse(hashMatch.group(1)!);
      if (num != null && num > 0 && num <= 999) {
        return hashMatch.group(1)!;
      }
    }

    // Pattern 4: Set code + number (e.g., "MEW 001", "SIT 045")
    final setCodePattern = RegExp(r'\b([A-Z]{2,5})\s+(\d{2,4})\b');
    final setCodeMatch = setCodePattern.firstMatch(origText);
    if (setCodeMatch != null) {
      final num = int.tryParse(setCodeMatch.group(2)!);
      if (num != null && num > 0 && num <= 999) {
        return setCodeMatch.group(2)!;
      }
    }

    // Pattern 5: Standalone 2-4 digit number (last resort, only from bottom zones)
    final standalonePattern = RegExp(r'\b(\d{2,4})\b');
    final standaloneMatches = standalonePattern.allMatches(text).toList();
    if (standaloneMatches.isNotEmpty) {
      // Prefer 3-digit numbers (most common format)
      for (final m in standaloneMatches) {
        final s = m.group(1)!;
        final num = int.tryParse(s);
        if (num != null && num > 0 && num <= 500 && s.length == 3) {
          return s;
        }
      }
    }

    return null;
  }
}
