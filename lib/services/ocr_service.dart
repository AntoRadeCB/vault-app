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

  /// Extract collector number from AI vision response or OCR text.
  /// AI format: "001/165|Card Name" or "001/165" or just "042"
  String? extractCollectorNumber(String text) {
    if (text.trim().isEmpty) return null;

    // AI returns "NUMBER|NAME" — take the number part
    final parts = text.split('|');
    var numPart = parts[0].trim();

    if (numPart.isEmpty || numPart == 'NONE') return null;

    // Strip set code prefix like "SFD. 196" → "196", "SV8. 042" → "042"
    // Pattern: LETTERS + optional punctuation + space + actual number
    final setPrefixMatch = RegExp(r'^[A-Za-z]+[\.\s]+(\d+.*)$').firstMatch(numPart);
    if (setPrefixMatch != null) {
      numPart = setPrefixMatch.group(1)!.trim();
    }

    // Extract just the collector number (before the slash if present)
    // e.g., "001/165" → "001", "SV049/SV100" → "SV049"
    final slashMatch = RegExp(r'^([A-Za-z]*\d+)\s*[/\\]').firstMatch(numPart);
    if (slashMatch != null) {
      return slashMatch.group(1)!;
    }

    // Just a number or code (e.g., "042", "SV049")
    final codeMatch = RegExp(r'^([A-Za-z]*\d+)$').firstMatch(numPart);
    if (codeMatch != null) {
      return codeMatch.group(1)!;
    }

    // Fallback: return as-is if it looks like a number
    if (RegExp(r'\d').hasMatch(numPart)) {
      return numPart;
    }

    return null;
  }
}
