import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();

  bool _darkMode = true;
  bool _notifications = true;
  bool _pushNotifications = false;
  bool _emailDigest = true;
  bool _autoBackup = false;

  String _workspace = 'Reselling Vinted 2025';
  String _fontSize = 'Medium';
  int _accentIndex = 0;

  User? get _user => _authService.currentUser;
  String get _userName => _user?.displayName ?? 'Vault User';
  String get _userEmail => _user?.email ?? 'vault@reselling.pro';

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
            Text(text,
                style:
                    const TextStyle(fontWeight: FontWeight.w600)),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggeredFadeSlide(
            index: 0,
            child: Text(
              AppLocalizations.of(context)!.settings,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Profile card ──
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
                          color: AppColors.accentBlue
                              .withValues(alpha: 0.3),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _userName.isNotEmpty
                            ? _userName[0].toUpperCase()
                            : 'V',
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
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
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
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue
                                .withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.accentBlue
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.proPlan,
                            style: TextStyle(
                              color: AppColors.accentBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ScaleOnPress(
                    onTap: () => _showEditDialog(
                      title: AppLocalizations.of(context)!.userName,
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
                          color: Colors.white
                              .withValues(alpha: 0.06),
                        ),
                      ),
                      child: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.textMuted,
                          size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Account section ──
          StaggeredFadeSlide(
            index: 2,
            child: _buildSection(
              title: AppLocalizations.of(context)!.account,
              icon: Icons.person_outline,
              children: [
                _buildSettingsRow(
                  icon: Icons.email_outlined,
                  title: AppLocalizations.of(context)!.email,
                  subtitle: _userEmail,
                  onTap: () => _showEditDialog(
                    title: 'Email',
                    currentValue: _userEmail,
                    onSave: (v) async {
                      try {
                        await _authService.updateEmail(v);
                        _showSuccessSnackbar(
                            AppLocalizations.of(context)!.verificationSent);
                      } catch (e) {
                        _showSuccessSnackbar(AppLocalizations.of(context)!.error('$e'));
                      }
                    },
                  ),
                  trailing: _buildChevron(),
                ),
                _buildSettingsRow(
                  icon: Icons.lock_outline,
                  title: AppLocalizations.of(context)!.password,
                  subtitle: AppLocalizations.of(context)!.resetViaEmail,
                  onTap: () async {
                    try {
                      await _authService
                          .resetPassword(_userEmail);
                      _showSuccessSnackbar(
                          AppLocalizations.of(context)!.resetEmailSent(_userEmail));
                    } catch (e) {
                      _showSuccessSnackbar(AppLocalizations.of(context)!.error('$e'));
                    }
                  },
                  trailing: _buildChevron(),
                ),
                _buildSettingsRow(
                  icon: Icons.security,
                  title: AppLocalizations.of(context)!.twoFactorAuth,
                  subtitle: AppLocalizations.of(context)!.notAvailable,
                  onTap: () => _showInfoSheet(
                    AppLocalizations.of(context)!.twoFactorTitle,
                    AppLocalizations.of(context)!.twoFactorDescription,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.textMuted
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'N/A',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Workspace section ──
          StaggeredFadeSlide(
            index: 3,
            child: _buildSection(
              title: AppLocalizations.of(context)!.workspace,
              icon: Icons.workspaces_outline,
              children: [
                _buildSettingsRow(
                  icon: Icons.store,
                  title: AppLocalizations.of(context)!.workspaceActive,
                  subtitle: _workspace,
                  onTap: () => _showSelectDialog(
                    title: AppLocalizations.of(context)!.selectWorkspace,
                    options: [
                      'Reselling Vinted 2025',
                      'Reselling eBay',
                      'Reselling Depop',
                      'Crypto Portfolio'
                    ],
                    currentValue: _workspace,
                    onSelect: (v) =>
                        setState(() => _workspace = v),
                  ),
                  trailing: _buildChevron(),
                ),
                _buildSettingsRow(
                  icon: Icons.cloud_upload_outlined,
                  title: AppLocalizations.of(context)!.autoBackup,
                  subtitle: AppLocalizations.of(context)!.syncDataCloud,
                  trailing: _buildSwitch(_autoBackup,
                      (v) => setState(() => _autoBackup = v)),
                ),
                _buildSettingsRow(
                  icon: Icons.download_outlined,
                  title: AppLocalizations.of(context)!.exportAllData,
                  subtitle: AppLocalizations.of(context)!.csvPdfJson,
                  onTap: _showExportDialog,
                  trailing: _buildChevron(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Notifications section ──
          StaggeredFadeSlide(
            index: 4,
            child: _buildSection(
              title: AppLocalizations.of(context)!.notifications,
              icon: Icons.notifications_outlined,
              children: [
                _buildSettingsRow(
                  icon: Icons.notifications_active_outlined,
                  title: AppLocalizations.of(context)!.notificationsInApp,
                  subtitle: AppLocalizations.of(context)!.salesShipmentAlerts,
                  trailing: _buildSwitch(_notifications,
                      (v) => setState(() => _notifications = v)),
                ),
                _buildSettingsRow(
                  icon: Icons.phone_android,
                  title: AppLocalizations.of(context)!.pushNotifications,
                  subtitle: AppLocalizations.of(context)!.receiveOnMobile,
                  trailing: _buildSwitch(
                      _pushNotifications,
                      (v) => setState(
                          () => _pushNotifications = v)),
                ),
                _buildSettingsRow(
                  icon: Icons.mail_outline,
                  title: AppLocalizations.of(context)!.emailDigest,
                  subtitle: AppLocalizations.of(context)!.weeklyReport,
                  trailing: _buildSwitch(_emailDigest,
                      (v) => setState(() => _emailDigest = v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Appearance section ──
          StaggeredFadeSlide(
            index: 5,
            child: _buildSection(
              title: AppLocalizations.of(context)!.appearance,
              icon: Icons.palette_outlined,
              children: [
                _buildSettingsRow(
                  icon: Icons.dark_mode_outlined,
                  title: AppLocalizations.of(context)!.darkMode,
                  subtitle: AppLocalizations.of(context)!.useDarkTheme,
                  trailing: _buildSwitch(_darkMode,
                      (v) => setState(() => _darkMode = v)),
                ),
                _buildSettingsRow(
                  icon: Icons.text_fields,
                  title: AppLocalizations.of(context)!.fontSize,
                  subtitle: _fontSize,
                  onTap: () => _showSelectDialog(
                    title: AppLocalizations.of(context)!.fontSize,
                    options: [
                      AppLocalizations.of(context)!.small,
                      AppLocalizations.of(context)!.medium,
                      AppLocalizations.of(context)!.large,
                      AppLocalizations.of(context)!.extraLarge,
                    ],
                    currentValue: _fontSize,
                    onSelect: (v) =>
                        setState(() => _fontSize = v),
                  ),
                  trailing: _buildChevron(),
                ),
                _buildSettingsRow(
                  icon: Icons.color_lens_outlined,
                  title: AppLocalizations.of(context)!.accentColor,
                  subtitle: [
                    AppLocalizations.of(context)!.blueViolet,
                    AppLocalizations.of(context)!.green,
                    AppLocalizations.of(context)!.orange,
                  ][_accentIndex],
                  onTap: () {
                    final colors = [
                      AppLocalizations.of(context)!.blueViolet,
                      AppLocalizations.of(context)!.green,
                      AppLocalizations.of(context)!.orange,
                    ];
                    _showSelectDialog(
                      title: AppLocalizations.of(context)!.accentColor,
                      options: colors,
                      currentValue: colors[_accentIndex],
                      onSelect: (v) => setState(
                          () => _accentIndex = colors.indexOf(v)),
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
          ),
          const SizedBox(height: 20),

          // ── Info section ──
          StaggeredFadeSlide(
            index: 6,
            child: _buildSection(
              title: AppLocalizations.of(context)!.info,
              icon: Icons.info_outline,
              children: [
                _buildSettingsRow(
                  icon: Icons.code,
                  title: AppLocalizations.of(context)!.version,
                  subtitle: 'Vault v1.0.0',
                ),
                _buildSettingsRow(
                  icon: Icons.description_outlined,
                  title: AppLocalizations.of(context)!.termsOfService,
                  onTap: () => _showInfoSheet(
                    AppLocalizations.of(context)!.termsOfService,
                    AppLocalizations.of(context)!.termsContent,
                  ),
                  trailing: _buildChevron(),
                ),
                _buildSettingsRow(
                  icon: Icons.privacy_tip_outlined,
                  title: AppLocalizations.of(context)!.privacyPolicy,
                  onTap: () => _showInfoSheet(
                    AppLocalizations.of(context)!.privacyPolicy,
                    AppLocalizations.of(context)!.privacyContent,
                  ),
                  trailing: _buildChevron(),
                ),
                _buildSettingsRow(
                  icon: Icons.bug_report_outlined,
                  title: AppLocalizations.of(context)!.reportBug,
                  onTap: () => _showEditDialog(
                    title: AppLocalizations.of(context)!.reportBug,
                    currentValue: '',
                    hint: AppLocalizations.of(context)!.describeProblem,
                    onSave: (_) {},
                  ),
                  trailing: _buildChevron(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Logout button ──
          StaggeredFadeSlide(
            index: 7,
            child: ScaleOnPress(
              onTap: _showLogoutDialog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color:
                      AppColors.accentRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.accentRed
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout,
                        color: AppColors.accentRed, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: AppColors.accentRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
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
