import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// Mobile OCR service — uses HTTP to call the same Cloud Functions as web.
/// Camera is managed directly by the dialog via CameraController.
class OcrService {
  static final OcrService _instance = OcrService._();
  factory OcrService() => _instance;
  OcrService._();

  Future<void> initWorker() async {}

  Future<Map<String, dynamic>> startCamera(String containerId) async {
    // On mobile, camera is managed by CameraController in the dialog
    return {'success': true};
  }

  Future<Map<String, dynamic>> captureAndRecognize(String containerId, {String? contextJson}) async {
    return {'error': 'Use recognizeFromBase64 on mobile'};
  }

  /// Mobile-specific: send a base64 JPEG to the OCR Cloud Function.
  Future<Map<String, dynamic>> recognizeFromBase64(String base64Image, {String? contextJson}) async {
    Map<String, dynamic> scanContext = {};
    try {
      if (contextJson != null) scanContext = jsonDecode(contextJson);
    } catch (_) {}

    final isPremium = scanContext['mode'] == 'premium';
    final apiUrl = isPremium
        ? 'https://scancard-orjhcexzoa-ew.a.run.app'
        : 'https://scancardocr-orjhcexzoa-ew.a.run.app';

    try {
      final body = <String, dynamic>{
        'image': base64Image.startsWith('data:')
            ? base64Image
            : 'data:image/jpeg;base64,$base64Image',
      };

      if (isPremium) {
        if (scanContext['expansion'] != null) body['expansion'] = scanContext['expansion'];
        if (scanContext['cards'] != null) body['cards'] = scanContext['cards'];
      }

      final resp = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (resp.statusCode != 200) {
        return {'error': 'API ${resp.statusCode}: ${resp.body}', 'text': '', 'confidence': 0};
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      if (data['found'] == true && data['cardName'] != null) {
        return {
          'text': data['cardName'],
          'cardName': data['cardName'],
          'extraInfo': data['extraInfo'],
          'confidence': 95,
          'aiResult': data,
          'cards': data['cards'] ?? [data],
        };
      } else {
        return {'text': '', 'confidence': 0, 'cards': []};
      }
    } catch (e) {
      return {'error': e.toString(), 'text': '', 'confidence': 0};
    }
  }

  void stopCamera(String containerId) {}

  Object createContainer(String id) => Object();

  void vibrate([int ms = 200]) {
    HapticFeedback.mediumImpact();
  }

  /// Extract collector number from AI vision response or OCR text.
  String? extractCollectorNumber(String text) {
    if (text.trim().isEmpty) return null;
    final parts = text.split('|');
    var numPart = parts[0].trim();
    if (numPart.isEmpty || numPart == 'NONE') return null;
    final setPrefixMatch =
        RegExp(r'^[A-Za-z]{2,}[\.\s\-_]*(\d+.*)$').firstMatch(numPart);
    if (setPrefixMatch != null) numPart = setPrefixMatch.group(1)!.trim();
    final slashMatch =
        RegExp(r'^([A-Za-z]*\d+)\s*[/\\]').firstMatch(numPart);
    if (slashMatch != null) return slashMatch.group(1)!;
    final codeMatch = RegExp(r'^([A-Za-z]*\d+)$').firstMatch(numPart);
    if (codeMatch != null) return codeMatch.group(1)!;
    if (RegExp(r'\d').hasMatch(numPart)) return numPart;
    return null;
  }
}
