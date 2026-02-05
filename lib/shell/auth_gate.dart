import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../screens/auth_screen.dart';
import '../screens/onboarding_screen.dart';
import '../providers/profile_provider.dart';
import '../services/firestore_service.dart';
import '../services/demo_data_service.dart';
import 'main_shell.dart';

/// AuthGate: loads app immediately in demo mode.
/// If user is logged in → Firestore data + onboarding check.
/// If not logged in → demo mode with sample data, no auth required.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showAuth = false;

  void _requestAuth() {
    setState(() => _showAuth = true);
  }

  void _dismissAuth() {
    setState(() => _showAuth = false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isLoggedIn = user != null;

        if (isLoggedIn) {
          // Logged in → check onboarding, then full app with Firestore
          return _OnboardingGate(key: ValueKey(user.uid));
        }

        // Demo mode: show app immediately with sample data
        // Pass auth callback so screens can request login when needed
        return DemoModeWrapper(
          onAuthRequired: _requestAuth,
          showAuth: _showAuth,
          onAuthDismiss: _dismissAuth,
        );
      },
    );
  }
}

/// Wraps MainShell in demo mode with an auth overlay when needed.
class DemoModeWrapper extends StatefulWidget {
  final VoidCallback onAuthRequired;
  final bool showAuth;
  final VoidCallback onAuthDismiss;

  const DemoModeWrapper({
    super.key,
    required this.onAuthRequired,
    required this.showAuth,
    required this.onAuthDismiss,
  });

  @override
  State<DemoModeWrapper> createState() => _DemoModeWrapperState();
}

class _DemoModeWrapperState extends State<DemoModeWrapper> {
  bool _demoReady = false;

  @override
  void initState() {
    super.initState();
    FirestoreService.demoMode = true;
    _initDemo();
  }

  Future<void> _initDemo() async {
    await DemoDataService.init();
    if (mounted) setState(() => _demoReady = true);
  }

  @override
  void dispose() {
    FirestoreService.demoMode = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_demoReady) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentBlue),
        ),
      );
    }

    return Stack(
      children: [
        ProfileProviderWrapper(
          child: MainShell(isDemoMode: true, onAuthRequired: widget.onAuthRequired),
        ),
        if (widget.showAuth)
          AuthScreen(onBack: widget.onAuthDismiss),
      ],
    );
  }
}

/// Checks if the user has profiles. If not → onboarding. Else → MainShell.
class _OnboardingGate extends StatefulWidget {
  const _OnboardingGate({super.key});

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  final FirestoreService _fs = FirestoreService();
  bool _checking = true;
  bool _needsOnboarding = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final has = await _fs.hasProfiles();
      if (mounted) {
        setState(() {
          _needsOnboarding = !has;
          _checking = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _onOnboardingComplete() {
    setState(() => _needsOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentBlue),
        ),
      );
    }
    if (_needsOnboarding) {
      return OnboardingScreen(onComplete: _onOnboardingComplete);
    }
    return const ProfileProviderWrapper(
      child: MainShell(),
    );
  }
}
