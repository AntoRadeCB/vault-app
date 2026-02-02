import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/profile.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onOpenAuth;
  final Profile? activeProfile;
  final VoidCallback? onProfileChanged;
  final VoidCallback? onNewProfile;
  final VoidCallback? onSwitchProfile;

  const SettingsScreen({
    super.key,
    this.onOpenAuth,
    this.activeProfile,
    this.onProfileChanged,
    this.onNewProfile,
    this.onSwitchProfile,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _darkMode = true;
  bool _notifications = true;
  bool _pushNotifications = false;
  bool _emailDigest = true;
  bool _autoBackup = false;

  String _fontSize = 'Medium';
  int _accentIndex = 0;

  bool _accountExpanded = false;
  bool _profileExpanded = false;

  User? get _user => _authService.currentUser;
  String get _userName => _user?.displayName ?? 'Vault User';
  String get _userEmail => _user?.email ?? 'vault@reselling.pro';

  Profile? get _profile => widget.activeProfile;

  // Feature toggle helpers
  bool _featureEnabled(String feature) =>
      _profile?.features.contains(feature) ?? true;

  Future<void> _toggleFeature(String feature, bool enabled) async {
    if (_profile == null || _profile!.id == null) return;
    final features = List<String>.from(_profile!.features);
    if (enabled) {
      if (!features.contains(feature)) features.add(feature);
    } else {
      features.remove(feature);
    }
    try {
      await _firestoreService.updateProfile(
          _profile!.id!, {'features': features});
      widget.onProfileChanged?.call();
    } catch (e) {
      if (mounted) {
        _showSuccessSnackbar('Errore: $e');
      }
    }
  }

  void _showEditDialog({
    required String title,
    required String currentValue,
    required ValueChanged<String> onSave,
    bool isPassword = false,
    String hint = '',
  }) {
    final controller =
        TextEditingController(text: isPassword ? '' : currentValue);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                obscureText: isPassword,
                autofocus: true,
                style:
                    const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText:
                      hint.isNotEmpty ? hint : 'Inserisci $title',
                  hintStyle:
                      const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color:
                            Colors.white.withValues(alpha: 0.06)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color:
                            Colors.white.withValues(alpha: 0.06)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.accentBlue, width: 1.5),
                  ),
                ),
              ),
              if (isPassword) ...[
                const SizedBox(height: 12),
                TextField(
                  obscureText: true,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Conferma nuova password',
                    hintStyle:
                        const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.white
                              .withValues(alpha: 0.06)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.white
                              .withValues(alpha: 0.06)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.accentBlue, width: 1.5),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ScaleOnPress(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color:
                              Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)!.cancel,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ScaleOnPress(
                      onTap: () {
                        if (controller.text.isNotEmpty) {
                          onSave(controller.text);
                        }
                        Navigator.pop(ctx);
                        _showSuccessSnackbar(AppLocalizations.of(context)!.fieldUpdated(title));
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: AppColors.blueButtonGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentBlue
                                  .withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)!.save,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showSelectDialog({
    required String title,
    required List<String> options,
    required String currentValue,
    required ValueChanged<String> onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...options.map((opt) {
              final selected = opt == currentValue;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ScaleOnPress(
                  onTap: () {
                    onSelect(opt);
                    Navigator.pop(ctx);
                    _showSuccessSnackbar('$title: $opt');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.accentBlue
                              .withValues(alpha: 0.15)
                          : AppColors.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.accentBlue
                                .withValues(alpha: 0.4)
                            : Colors.white
                                .withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            opt,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 15,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle,
                              color: AppColors.accentBlue, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showInfoSheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            ScaleOnPress(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.blueButtonGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.close,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check,
                  color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style:
                      const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        backgroundColor: AppColors.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showExportDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.exportData,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.chooseExportFormat,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 20),
            _exportOption(ctx, Icons.table_chart, 'CSV',
                AppLocalizations.of(context)!.allRecordsCsv, Colors.green),
            const SizedBox(height: 10),
            _exportOption(ctx, Icons.picture_as_pdf, 'PDF',
                AppLocalizations.of(context)!.formattedReport, Colors.red),
            const SizedBox(height: 10),
            _exportOption(ctx, Icons.code, 'JSON',
                AppLocalizations.of(context)!.rawDataJson, Colors.orange),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _exportOption(BuildContext ctx, IconData icon, String title,
      String subtitle, Color color) {
    return ScaleOnPress(
      onTap: () {
        Navigator.pop(ctx);
        _showSuccessSnackbar(AppLocalizations.of(context)!.exportStarted(title));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.download,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context)!.logout,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          AppLocalizations.of(context)!.confirmLogout,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.signOut();
            },
            child: Text(AppLocalizations.of(context)!.exit,
                style: const TextStyle(
                    color: AppColors.accentRed,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  bool get _isLoggedIn => _authService.currentUser != null;

  Widget _buildLoginPrompt() {
    if (_isLoggedIn) return const SizedBox.shrink();
    return StaggeredFadeSlide(
      index: 1,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        glowColor: AppColors.accentOrange,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentOrange.withValues(alpha: 0.3),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.person_outline, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Stai usando la modalità demo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Accedi o registrati per salvare i tuoi dati e sincronizzarli su tutti i dispositivi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ScaleOnPress(
                    onTap: widget.onOpenAuth,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppColors.blueButtonGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentBlue.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Accedi / Registrati',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggeredFadeSlide(
            index: 0,
            child: Text(
              l.settings,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Login prompt (demo mode) ──
          _buildLoginPrompt(),
          if (!_isLoggedIn) const SizedBox(height: 20),

          // ═══════════════════════════════════════════
          //  ACCOUNT CARD — sempre in cima
          // ═══════════════════════════════════════════
          StaggeredFadeSlide(
            index: 1,
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              glowColor: AppColors.accentPurple,
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppColors.headerGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentBlue.withValues(alpha: 0.3),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'V',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userEmail,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                        if (_profile != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accentPurple.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.accentPurple.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              '${Profile.categoryShortLabel(_profile!.category)} · ${_profile!.name}',
                              style: const TextStyle(
                                color: AppColors.accentPurple,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ScaleOnPress(
                    onTap: () => _showEditDialog(
                      title: l.userName,
                      currentValue: _userName,
                      onSave: (v) async {
                        await _authService.updateDisplayName(v);
                        setState(() {});
                      },
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: const Icon(Icons.edit_outlined,
                          color: AppColors.textMuted, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ═══════════════════════════════════════════
          //  1. IMPOSTAZIONI ACCOUNT (collapsible)
          // ═══════════════════════════════════════════
          StaggeredFadeSlide(
            index: 2,
            child: _buildCollapsibleButton(
              icon: Icons.manage_accounts_outlined,
              title: 'Impostazioni Account',
              subtitle: 'Email, password, aspetto, notifiche',
              color: AppColors.accentTeal,
              isExpanded: _accountExpanded,
              onTap: () => setState(() {
                _accountExpanded = !_accountExpanded;
                if (_accountExpanded) _profileExpanded = false;
              }),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  // ── Account ──
                  _buildSection(
                    title: l.account,
                    icon: Icons.person_outline,
                    children: [
                      _buildSettingsRow(
                        icon: Icons.email_outlined,
                        title: l.email,
                        subtitle: _userEmail,
                        onTap: () => _showEditDialog(
                          title: 'Email',
                          currentValue: _userEmail,
                          onSave: (v) async {
                            try {
                              await _authService.updateEmail(v);
                              _showSuccessSnackbar(l.verificationSent);
                            } catch (e) {
                              _showSuccessSnackbar(l.error('$e'));
                            }
                          },
                        ),
                        trailing: _buildChevron(),
                      ),
                      _buildSettingsRow(
                        icon: Icons.lock_outline,
                        title: l.password,
                        subtitle: l.resetViaEmail,
                        onTap: () async {
                          try {
                            await _authService.resetPassword(_userEmail);
                            _showSuccessSnackbar(l.resetEmailSent(_userEmail));
                          } catch (e) {
                            _showSuccessSnackbar(l.error('$e'));
                          }
                        },
                        trailing: _buildChevron(),
                      ),
                      _buildSettingsRow(
                        icon: Icons.security,
                        title: l.twoFactorAuth,
                        subtitle: l.notAvailable,
                        onTap: () => _showInfoSheet(l.twoFactorTitle, l.twoFactorDescription),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.textMuted.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('N/A',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Dati & Backup ──
                  _buildSection(
                    title: 'DATI & BACKUP',
                    icon: Icons.cloud_outlined,
                    children: [
                      _buildSettingsRow(
                        icon: Icons.cloud_upload_outlined,
                        title: l.autoBackup,
                        subtitle: l.syncDataCloud,
                        trailing: _buildSwitch(_autoBackup, (v) => setState(() => _autoBackup = v)),
                      ),
                      _buildSettingsRow(
                        icon: Icons.download_outlined,
                        title: l.exportAllData,
                        subtitle: l.csvPdfJson,
                        onTap: _showExportDialog,
                        trailing: _buildChevron(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Notifiche ──
                  _buildSection(
                    title: l.notifications,
                    icon: Icons.notifications_outlined,
                    children: [
                      _buildSettingsRow(
                        icon: Icons.notifications_active_outlined,
                        title: l.notificationsInApp,
                        subtitle: l.salesShipmentAlerts,
                        trailing: _buildSwitch(_notifications, (v) => setState(() => _notifications = v)),
                      ),
                      _buildSettingsRow(
                        icon: Icons.phone_android,
                        title: l.pushNotifications,
                        subtitle: l.receiveOnMobile,
                        trailing: _buildSwitch(_pushNotifications, (v) => setState(() => _pushNotifications = v)),
                      ),
                      _buildSettingsRow(
                        icon: Icons.mail_outline,
                        title: l.emailDigest,
                        subtitle: l.weeklyReport,
                        trailing: _buildSwitch(_emailDigest, (v) => setState(() => _emailDigest = v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Aspetto ──
                  _buildSection(
                    title: l.appearance,
                    icon: Icons.palette_outlined,
                    children: [
                      _buildSettingsRow(
                        icon: Icons.dark_mode_outlined,
                        title: l.darkMode,
                        subtitle: l.useDarkTheme,
                        trailing: _buildSwitch(_darkMode, (v) => setState(() => _darkMode = v)),
                      ),
                      _buildSettingsRow(
                        icon: Icons.text_fields,
                        title: l.fontSize,
                        subtitle: _fontSize,
                        onTap: () => _showSelectDialog(
                          title: l.fontSize,
                          options: [l.small, l.medium, l.large, l.extraLarge],
                          currentValue: _fontSize,
                          onSelect: (v) => setState(() => _fontSize = v),
                        ),
                        trailing: _buildChevron(),
                      ),
                      _buildSettingsRow(
                        icon: Icons.color_lens_outlined,
                        title: l.accentColor,
                        subtitle: [l.blueViolet, l.green, l.orange][_accentIndex],
                        onTap: () {
                          final colors = [l.blueViolet, l.green, l.orange];
                          _showSelectDialog(
                            title: l.accentColor,
                            options: colors,
                            currentValue: colors[_accentIndex],
                            onSelect: (v) => setState(() => _accentIndex = colors.indexOf(v)),
                          );
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _colorDot(AppColors.accentBlue, 0),
                            const SizedBox(width: 4),
                            _colorDot(AppColors.accentGreen, 1),
                            const SizedBox(width: 4),
                            _colorDot(AppColors.accentOrange, 2),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Info ──
                  _buildSection(
                    title: l.info,
                    icon: Icons.info_outline,
                    children: [
                      _buildSettingsRow(icon: Icons.code, title: l.version, subtitle: 'Vault v1.0.0'),
                      _buildSettingsRow(
                        icon: Icons.description_outlined,
                        title: l.termsOfService,
                        onTap: () => _showInfoSheet(l.termsOfService, l.termsContent),
                        trailing: _buildChevron(),
                      ),
                      _buildSettingsRow(
                        icon: Icons.privacy_tip_outlined,
                        title: l.privacyPolicy,
                        onTap: () => _showInfoSheet(l.privacyPolicy, l.privacyContent),
                        trailing: _buildChevron(),
                      ),
                      _buildSettingsRow(
                        icon: Icons.bug_report_outlined,
                        title: l.reportBug,
                        onTap: () => _showEditDialog(title: l.reportBug, currentValue: '', hint: l.describeProblem, onSave: (_) {}),
                        trailing: _buildChevron(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            crossFadeState: _accountExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeOutCubic,
          ),
          const SizedBox(height: 16),

          // ═══════════════════════════════════════════
          //  2. IMPOSTAZIONI PROFILO (collapsible)
          // ═══════════════════════════════════════════
          if (_profile != null) ...[
            StaggeredFadeSlide(
              index: 3,
              child: _buildCollapsibleButton(
                icon: Icons.dashboard_customize_outlined,
                title: 'Impostazioni Profilo',
                subtitle: '${_profile!.name} · ${Profile.categoryShortLabel(_profile!.category)}',
                color: AppColors.accentBlue,
                gradient: AppColors.blueButtonGradient,
                isExpanded: _profileExpanded,
                onTap: () => setState(() {
                  _profileExpanded = !_profileExpanded;
                  if (_profileExpanded) _accountExpanded = false;
                }),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  children: [
                    // ── Profilo ──
                    _buildSection(
                      title: 'PROFILO',
                      icon: Icons.account_circle_outlined,
                      children: [
                        _buildSettingsRow(
                          icon: Icons.badge_outlined,
                          title: 'Nome profilo',
                          subtitle: _profile!.name,
                          onTap: () => _showEditDialog(
                            title: 'Nome profilo',
                            currentValue: _profile!.name,
                            onSave: (v) async {
                              if (_profile!.id == null) return;
                              try {
                                await _firestoreService.updateProfile(_profile!.id!, {'name': v});
                                widget.onProfileChanged?.call();
                              } catch (e) {
                                _showSuccessSnackbar('Errore: $e');
                              }
                            },
                          ),
                          trailing: _buildChevron(),
                        ),
                        _buildSettingsRow(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Budget',
                          subtitle: _profile!.budget > 0
                              ? '€${_profile!.budget.toStringAsFixed(0)}'
                              : 'Non impostato',
                          onTap: () => _showEditDialog(
                            title: 'Budget',
                            currentValue: _profile!.budget > 0 ? _profile!.budget.toStringAsFixed(0) : '',
                            hint: 'Es. 500 — il tuo capitale massimo',
                            onSave: (v) async {
                              if (_profile!.id == null) return;
                              final budgetVal = double.tryParse(v) ?? 0.0;
                              try {
                                await _firestoreService.updateProfile(_profile!.id!, {'budget': budgetVal});
                                widget.onProfileChanged?.call();
                              } catch (e) {
                                _showSuccessSnackbar('Errore: $e');
                              }
                            },
                          ),
                          trailing: _buildChevron(),
                        ),
                        _buildSettingsRow(
                          icon: Icons.category_outlined,
                          title: 'Categoria',
                          subtitle: Profile.categoryLabel(_profile!.category),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentPurple.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              Profile.categoryShortLabel(_profile!.category),
                              style: const TextStyle(color: AppColors.accentPurple, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        _buildSettingsRow(
                          icon: Icons.swap_horiz,
                          title: 'Cambia profilo',
                          subtitle: 'Passa a un altro profilo',
                          onTap: widget.onSwitchProfile,
                          trailing: _buildChevron(),
                        ),
                        _buildSettingsRow(
                          icon: Icons.add_circle_outline,
                          title: 'Nuovo profilo',
                          subtitle: 'Crea un nuovo spazio di lavoro',
                          onTap: widget.onNewProfile,
                          trailing: _buildChevron(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Funzionalità ──
                    _buildSection(
                      title: 'FUNZIONALITÀ',
                      icon: Icons.tune,
                      children: [
                        _buildSettingsRow(
                          icon: Icons.monetization_on_outlined,
                          title: 'Rivendita',
                          subtitle: 'Compra e rivendi per profitto',
                          trailing: _buildSwitch(_featureEnabled('reselling'), (v) => _toggleFeature('reselling', v)),
                        ),
                        _buildSettingsRow(
                          icon: Icons.collections_bookmark_outlined,
                          title: 'Collezionismo',
                          subtitle: 'Tieni traccia della tua collezione',
                          trailing: _buildSwitch(_featureEnabled('collecting'), (v) => _toggleFeature('collecting', v)),
                        ),
                        _buildSettingsRow(
                          icon: Icons.bar_chart_outlined,
                          title: 'Report & Analisi',
                          subtitle: 'Statistiche e insight',
                          trailing: _buildSwitch(_featureEnabled('analytics'), (v) => _toggleFeature('analytics', v)),
                        ),
                        _buildSettingsRow(
                          icon: Icons.local_shipping_outlined,
                          title: 'Tracking Spedizioni',
                          subtitle: 'Monitora pacchi in entrata e uscita',
                          trailing: _buildSwitch(_featureEnabled('shipping'), (v) => _toggleFeature('shipping', v)),
                        ),
                        _buildSettingsRow(
                          icon: Icons.inventory_2_outlined,
                          title: 'Gestione Inventario',
                          subtitle: 'Organizza il tuo magazzino',
                          trailing: _buildSwitch(_featureEnabled('inventory'), (v) => _toggleFeature('inventory', v)),
                        ),
                        _buildSettingsRow(
                          icon: Icons.calculate_outlined,
                          title: 'Calcolo Profitti',
                          subtitle: 'Margini, commissioni e guadagni netti',
                          trailing: _buildSwitch(_featureEnabled('pricing'), (v) => _toggleFeature('pricing', v)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              crossFadeState: _profileExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
              sizeCurve: Curves.easeOutCubic,
            ),
            const SizedBox(height: 16),
          ],

          // ── Logout ──
          if (_isLoggedIn) ...[
            const SizedBox(height: 12),
            StaggeredFadeSlide(
              index: 4,
              child: ScaleOnPress(
                onTap: _showLogoutDialog,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.25)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: AppColors.accentRed, size: 20),
                      SizedBox(width: 8),
                      Text('Logout', style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.w600, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCollapsibleButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    LinearGradient? gradient,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isExpanded
              ? color.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded
                ? color.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.06),
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: isExpanded
              ? [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 16)]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: gradient,
                color: gradient == null ? color.withValues(alpha: 0.15) : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: gradient != null ? Colors.white : color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isExpanded ? Colors.white : AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isExpanded ? color : AppColors.textMuted,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.textMuted, size: 18),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: List.generate(children.length, (i) {
              return Column(
                children: [
                  if (i > 0)
                    Divider(
                      height: 1,
                      color:
                          Colors.white.withValues(alpha: 0.04),
                      indent: 52,
                    ),
                  children[i],
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ScaleOnPress(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentBlue
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  color: AppColors.accentBlue, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(bool value, ValueChanged<bool> onChanged) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.accentBlue,
      activeTrackColor:
          AppColors.accentBlue.withValues(alpha: 0.3),
      inactiveThumbColor: AppColors.textMuted,
      inactiveTrackColor: AppColors.surface,
    );
  }

  Widget _buildChevron() {
    return const Icon(
      Icons.chevron_right,
      color: AppColors.textMuted,
      size: 20,
    );
  }

  Widget _colorDot(Color color, int index) {
    final selected = _accentIndex == index;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: selected
            ? Border.all(color: Colors.white, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}
