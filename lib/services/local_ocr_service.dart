import 'dart:js_interop';
import 'package:flutter/foundation.dart';

/// Service for local OCR using Tesseract.js
/// Reads collector number from card images without any API calls
class LocalOcrService {
  static final LocalOcrService _instance = LocalOcrService._internal();
  factory LocalOcrService() => _instance;
  LocalOcrService._internal();

  /// Capture frame and run local OCR to extract collector number
  Future<LocalOcrResult> recognizeCollectorNumber(String containerId) async {
    try {
      final resultJson = await _captureAndRecognizeLocal(containerId);
      final result = _parseJson(resultJson);
      
      if (result['error'] != null) {
        return LocalOcrResult(error: result['error'] as String);
      }
      
      return LocalOcrResult(
        rawText: result['rawText'] as String? ?? '',
        collectorNumber: result['collectorNumber'] as String?,
        confidence: (result['confidence'] as num?)?.toDouble() ?? 0,
      );
    } catch (e) {
      debugPrint('LocalOcrService error: $e');
      return LocalOcrResult(error: e.toString());
    }
  }

  Future<String> _captureAndRecognizeLocal(String containerId) async {
    final promise = _jsRecognizeLocal(containerId);
    final result = await promise.toDart;
    return result.toString();
  }

  Map<String, dynamic> _parseJson(String json) {
    // Simple JSON parser for our specific format
    final map = <String, dynamic>{};
    
    // Remove braces
    var content = json.trim();
    if (content.startsWith('{')) content = content.substring(1);
    if (content.endsWith('}')) content = content.substring(0, content.length - 1);
    
    // Parse key-value pairs (simplified)
    final regex = RegExp(r'"(\w+)":\s*(?:"([^"]*)"|([\d.]+)|null|(true|false))');
    for (final match in regex.allMatches(content)) {
      final key = match.group(1)!;
      if (match.group(2) != null) {
        map[key] = match.group(2);
      } else if (match.group(3) != null) {
        map[key] = num.tryParse(match.group(3)!) ?? match.group(3);
      } else if (match.group(4) != null) {
        map[key] = match.group(4) == 'true';
      } else {
        map[key] = null;
      }
    }
    
    return map;
  }
}

@JS('captureAndRecognizeLocal')
external JSPromise<JSString> _jsRecognizeLocal(String containerId);

class LocalOcrResult {
  final String? error;
  final String rawText;
  final String? collectorNumber;
  final double confidence;

  LocalOcrResult({
    this.error,
    this.rawText = '',
    this.collectorNumber,
    this.confidence = 0,
  });

  bool get hasError => error != null;
  bool get hasCollectorNumber => collectorNumber != null && collectorNumber!.isNotEmpty;
}
