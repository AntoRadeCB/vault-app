import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/ebay_service.dart';

/// Handles the eBay OAuth callback.
/// Extracts the authorization code from the URL and exchanges it for tokens.
class EbayCallbackScreen extends StatefulWidget {
  final String? code;
  final String? error;

  const EbayCallbackScreen({super.key, this.code, this.error});

  @override
  State<EbayCallbackScreen> createState() => _EbayCallbackScreenState();
}

class _EbayCallbackScreenState extends State<EbayCallbackScreen> {
  String _status = 'loading'; // loading, success, error
  String _message = '';

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    if (widget.error != null) {
      setState(() {
        _status = 'error';
        _message = 'Autorizzazione rifiutata: ${widget.error}';
      });
      return;
    }

    if (widget.code == null || widget.code!.isEmpty) {
      setState(() {
        _status = 'error';
        _message = 'Nessun codice di autorizzazione ricevuto.';
      });
      return;
    }

    try {
      final ebayService = EbayService();
      await ebayService.connectEbay(widget.code!);
      setState(() {
        _status = 'success';
        _message = 'Account eBay collegato con successo!';
      });
      // Auto-close after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() {
        _status = 'error';
        _message = 'Errore: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_status == 'loading') ...[
                const CircularProgressIndicator(color: AppColors.accentBlue),
                const SizedBox(height: 24),
                const Text(
                  'Collegamento eBay in corso...',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
              if (_status == 'success') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: AppColors.accentGreen, size: 48),
                ),
                const SizedBox(height: 24),
                Text(
                  _message,
                  style: const TextStyle(color: AppColors.accentGreen, fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ritorno all\'app...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
              if (_status == 'error') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline, color: AppColors.accentRed, size: 48),
                ),
                const SizedBox(height: 24),
                Text(
                  _message,
                  style: const TextStyle(color: AppColors.accentRed, fontSize: 16, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Torna all\'app', style: TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
