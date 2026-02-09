import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'shell/auth_gate.dart';
import 'screens/ebay_callback_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const VaultApp());
}

class VaultApp extends StatelessWidget {
  const VaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vault - Reselling Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '');
        // Handle eBay OAuth callback
        if (uri.path == '/ebay-callback') {
          final code = uri.queryParameters['code'];
          final error = uri.queryParameters['error'];
          return MaterialPageRoute(
            builder: (_) => EbayCallbackScreen(code: code, error: error),
          );
        }
        // Default route
        return MaterialPageRoute(builder: (_) => const AuthGate());
      },
      home: const AuthGate(),
    );
  }
}
