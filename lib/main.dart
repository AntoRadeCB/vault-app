import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'shell/auth_gate.dart';
import 'screens/ebay_callback_screen.dart';

/// Check if current URL is an eBay OAuth callback and extract params.
({String? code, String? error, bool isCallback}) _checkEbayCallback() {
  try {
    final href = web.window.location.href;
    final uri = Uri.parse(href);
    if (uri.path.contains('ebay-callback')) {
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];
      // Clean the URL so refreshing doesn't re-trigger
      web.window.history.replaceState(''.toJS, '/', '/');

      return (code: code, error: error, isCallback: true);
    }
  } catch (_) {}
  return (code: null, error: null, isCallback: false);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final callback = _checkEbayCallback();
  runApp(VaultApp(ebayCallback: callback.isCallback ? callback : null));
}

class VaultApp extends StatelessWidget {
  final ({String? code, String? error, bool isCallback})? ebayCallback;

  const VaultApp({super.key, this.ebayCallback});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vault - Reselling Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ebayCallback != null
          ? EbayCallbackScreen(
              code: ebayCallback!.code,
              error: ebayCallback!.error,
            )
          : const AuthGate(),
    );
  }
}
