import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/animated_widgets.dart';
import '../l10n/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();

  // Login controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Register controllers
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmController = TextEditingController();

  bool _loginLoading = false;
  bool _registerLoading = false;
  bool _obscureLogin = true;
  bool _obscureRegister = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        backgroundColor: AppColors.accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _firebaseErrorMessage(FirebaseAuthException e) {
    final l = AppLocalizations.of(context)!;
    switch (e.code) {
      case 'user-not-found':
        return l.userNotFound;
      case 'wrong-password':
        return l.wrongPassword;
      case 'invalid-email':
        return l.invalidEmail;
      case 'user-disabled':
        return l.accountDisabled;
      case 'email-already-in-use':
        return l.emailAlreadyInUse;
      case 'weak-password':
        return l.weakPassword;
      case 'invalid-credential':
        return l.invalidCredential;
      default:
        return e.message ?? l.unknownError;
    }
  }

  Future<void> _handleLogin() async {
    final l = AppLocalizations.of(context)!;
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError(l.enterEmailAndPassword);
      return;
    }

    setState(() => _loginLoading = true);
    try {
      await _authService.signIn(email: email, password: password);
      // Auth state listener in main.dart will redirect
    } on FirebaseAuthException catch (e) {
      _showError(_firebaseErrorMessage(e));
    } catch (e) {
      _showError('Errore: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loginLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    final l = AppLocalizations.of(context)!;
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text.trim();
    final confirm = _registerConfirmController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError(l.enterEmailAndPassword);
      return;
    }
    if (password != confirm) {
      _showError(l.passwordsDoNotMatch);
      return;
    }
    if (password.length < 6) {
      _showError(l.passwordMinLength);
      return;
    }

    setState(() => _registerLoading = true);
    try {
      await _authService.register(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      _showError(_firebaseErrorMessage(e));
    } catch (e) {
      _showError('Errore: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _registerLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                StaggeredFadeSlide(
                  index: 0,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.headerGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.accentBlue.withValues(alpha: 0.4),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.view_in_ar,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Vault',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Reselling Tracker',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Tab bar
                StaggeredFadeSlide(
                  index: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        gradient: AppColors.blueButtonGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.accentBlue.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textMuted,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(text: l.login),
                        Tab(text: l.register),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Tab content
                StaggeredFadeSlide(
                  index: 2,
                  child: SizedBox(
                    height: 340,
                    child: TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildLoginForm(),
                        _buildRegisterForm(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        _buildTextField(
          controller: _loginEmailController,
          hint: l.email,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _loginPasswordController,
          hint: l.password,
          icon: Icons.lock_outline,
          obscure: _obscureLogin,
          toggleObscure: () =>
              setState(() => _obscureLogin = !_obscureLogin),
        ),
        const SizedBox(height: 28),
        _buildSubmitButton(
          label: l.login,
          loading: _loginLoading,
          onTap: _handleLogin,
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        _buildTextField(
          controller: _registerEmailController,
          hint: l.email,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _registerPasswordController,
          hint: l.password,
          icon: Icons.lock_outline,
          obscure: _obscureRegister,
          toggleObscure: () =>
              setState(() => _obscureRegister = !_obscureRegister),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _registerConfirmController,
          hint: l.confirmPassword,
          icon: Icons.lock_outline,
          obscure: _obscureConfirm,
          toggleObscure: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
        ),
        const SizedBox(height: 28),
        _buildSubmitButton(
          label: l.createAccount,
          loading: _registerLoading,
          onTap: _handleRegister,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    VoidCallback? toggleObscure,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
          suffixIcon: toggleObscure != null
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: toggleObscure,
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.accentBlue, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton({
    required String label,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return ShimmerButton(
      baseGradient: AppColors.blueButtonGradient,
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
