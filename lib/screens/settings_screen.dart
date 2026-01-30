import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = true;
  bool _notifications = true;
  bool _pushNotifications = false;
  bool _emailDigest = true;
  bool _autoBackup = false;

  String _userName = 'Vault User';
  String _userEmail = 'vault@reselling.pro';
  String _workspace = 'Reselling Vinted 2025';
  String _fontSize = 'Medium';
  int _accentIndex = 0;

  void _showEditDialog({
    required String title,
    required String currentValue,
    required ValueChanged<String> onSave,
    bool isPassword = false,
    String hint = '',
  }) {
    final controller = TextEditingController(text: isPassword ? '' : currentValue);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: hint.isNotEmpty ? hint : 'Inserisci $title',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
                  ),
                ),
              ),
              if (isPassword) ...[
                const SizedBox(height: 12),
                TextField(
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Conferma nuova password',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Annulla',
                            style: TextStyle(
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
                        _showSuccessSnackbar('$title aggiornato!');
                      },
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
                            'Salva',
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.accentBlue.withValues(alpha: 0.15)
                          : AppColors.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.accentBlue.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            opt,
                            style: TextStyle(
                              color: selected ? Colors.white : AppColors.textSecondary,
                              fontSize: 15,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle, color: AppColors.accentBlue, size: 20),
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
                child: const Center(
                  child: Text(
                    'Chiudi',
                    style: TextStyle(
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
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: AppColors.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            const Text(
              'Esporta Dati',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scegli il formato di esportazione',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 20),
            _exportOption(ctx, Icons.table_chart, 'CSV', 'Tutti i record in formato CSV', Colors.green),
            const SizedBox(height: 10),
            _exportOption(ctx, Icons.picture_as_pdf, 'PDF', 'Report formattato per stampa', Colors.red),
            const SizedBox(height: 10),
            _exportOption(ctx, Icons.code, 'JSON', 'Dati grezzi in formato JSON', Colors.orange),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _exportOption(BuildContext ctx, IconData icon, String title, String subtitle, Color color) {
    return ScaleOnPress(
      onTap: () {
        Navigator.pop(ctx);
        _showSuccessSnackbar('Esportazione $title avviata!');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.download, color: AppColors.textMuted, size: 20),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Sei sicuro di voler uscire dal tuo account?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showSuccessSnackbar('Logout effettuato');
            },
            child: const Text('Esci', style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.bold)),
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
            child: const Text(
              'Settings',
              style: TextStyle(
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
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.accentBlue.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Text(
                            'PRO PLAN',
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
                      title: 'Nome Utente',
                      currentValue: _userName,
                      onSave: (v) => setState(() => _userName = v),
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
                      child: const Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 20),
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
              title: 'Account',
              icon: Icons.person_outline,
              children: [
                _buildSettingsRow(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  subtitle: _userEmail,
                  onTap: () => _showEditDialog(
                    title: 'Email',
                    currentValue: _userEmail,
                    onSave: (v) => setState(() => _userEmail = v),
                  ),
                  trailing: _buildChevron(),
                ),
                _buildSettingsRow(
                  icon: Icons.lock_outline,
                  title: 'Password',
                  subtitle: 'Ultima modifica 30 giorni fa',
                  onTap: () => _showEditDialog(
                    title: 'Nuova Password',
                    currentValue: '',
                    isPassword: true,
                    hint: 'Inserisci nuova password',
                    onSave: (_) {},
                  ),
                  trailing: _buildChevron(),
                ),
                _buildSettingsRow(
                  icon: Icons.security,
                  title: '2FA Authentication',
                  subtitle: 'Abilitato',
                  onTap: () => _showInfoSheet(
                    'Autenticazione a 2 Fattori',
                    'La 2FA è attualmente abilitata sul tuo account.\n\nMetodo: App Authenticator\nUltimo accesso verificato: oggi\n\nPer disabilitare la 2FA, contatta il supporto.',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ON',
                      style: TextStyle(
                        color: AppColors.accentGreen,
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
              title: 'Workspace',
              icon: Icons.workspaces_outline,
              children: [
                _buildSettingsRow(
                  icon: Icons.store,
                  title: 'Workspace Attivo',
                  subtitle: _workspace,
                  onTap: () => _showSelectDialog(
                    title: 'Seleziona Workspace',
                    options: ['Reselling Vinted 2025', 'Reselling eBay', 'Reselling Depop', 'Crypto Portfolio'],
                    currentValue: _workspace,
                    onSelect: (v) => setState(() => _workspace = v),
                  ),
                  trailing: _buildChevron(),
                ),
                _buildSettingsRow(
                  icon: Icons.cloud_upload_outlined,
                  title: 'Auto Backup',
                  subtitle: 'Sincronizza dati su cloud',
                  trailing: _buildSwitch(_autoBackup, (v) => setState(() => _autoBackup = v)),
                ),
                _buildSettingsRow(
                  icon: Icons.download_outlined,
                  title: 'Esporta Tutti i Dati',
                  subtitle: 'CSV, PDF, JSON',
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
              title: 'Notifiche',
              icon: Icons.notifications_outlined,
              children: [
                _buildSettingsRow(
                  icon: Icons.notifications_active_outlined,
                  title: 'Notifiche In-App',
                  subtitle: 'Avvisi vendite e spedizioni',
                  trailing: _buildSwitch(_notifications, (v) => setState(() => _notifications = v)),
                ),
                _buildSettingsRow(
                  icon: Icons.phone_android,
                  title: 'Push Notifications',
                  subtitle: 'Ricevi su mobile',
                  trailing: _buildSwitch(_pushNotifications, (v) => setState(() => _pushNotifications = v)),
                ),
                _buildSettingsRow(
                  icon: Icons.mail_outline,
                  title: 'Email Digest',
                  subtitle: 'Report settimanale',
                  trailing: _buildSwitch(_emailDigest, (v) => setState(() => _emailDigest = v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Appearance section ──
          StaggeredFadeSlide(
            index: 5,
            child: _buildSection(
              title: 'Aspetto',
              icon: Icons.palette_outlined,
              children: [
                _buildSettingsRow(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  subtitle: 'Usa tema scuro',
                  trailing: _buildSwitch(_darkMode, (v) => setState(() => _darkMode = v)),
                ),
                _buildSettingsRow(
                  icon: Icons.text_fields,
                  title: 'Dimensione Font',
                  subtitle: _fontSize,
                  onTap: () => _showSelectDialog(
                    title: 'Dimensione Font',
                    options: ['Small', 'Medium', 'Large', 'Extra Large'],
                    currentValue: _fontSize,
                    onSelect: (v) => setState(() => _fontSize = v),
                  ),
                  trailing: _buildChevron(),
                ),
                _buildSettingsRow(
                  icon: Icons.color_lens_outlined,
                  title: 'Colore Accento',
                  subtitle: ['Blu-Viola', 'Verde', 'Arancione'][_accentIndex],
                  onTap: () {
                    final colors = ['Blu-Viola', 'Verde', 'Arancione'];
                    _showSelectDialog(
                      title: 'Colore Accento',
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
          ),
          const SizedBox(height: 20),

          // ── Info section ──
          StaggeredFadeSlide(
            index: 6,
            child: _buildSection(
              title: 'Info',
              icon: Icons.info_outline,
              children: [
                _buildSettingsRow(
                  icon: Icons.code,
                  title: 'Versione',
                  subtitle: 'Vault v1.0.0',
                ),
                _buildSettingsRow(
                  icon: Icons.description_outlined,
                  title: 'Termini di Servizio',
                  onTap: () => _showInfoSheet(
                    'Termini di Servizio',
                    'Vault Reselling Tracker — Termini di Servizio\n\nUtilizzando questa app accetti i seguenti termini:\n\n1. L\'app è fornita "così com\'è" senza garanzie.\n2. I dati inseriti sono di tua responsabilità.\n3. Non siamo responsabili per perdite derivanti dall\'uso dell\'app.\n4. I dati sono archiviati localmente sul dispositivo.\n5. Puoi esportare e cancellare i tuoi dati in qualsiasi momento.\n\nUltimo aggiornamento: Gennaio 2025',
                  ),
                  trailing: _buildChevron(),
                ),
                _buildSettingsRow(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => _showInfoSheet(
                    'Privacy Policy',
                    'La tua privacy è importante per noi.\n\n• Non raccogliamo dati personali senza consenso\n• I dati restano sul tuo dispositivo\n• Nessun tracciamento o analytics di terze parti\n• Puoi richiedere la cancellazione dei dati in qualsiasi momento\n• Non condividiamo informazioni con terzi\n\nPer domande: privacy@vault-app.com',
                  ),
                  trailing: _buildChevron(),
                ),
                _buildSettingsRow(
                  icon: Icons.bug_report_outlined,
                  title: 'Segnala un Bug',
                  onTap: () => _showEditDialog(
                    title: 'Segnala un Bug',
                    currentValue: '',
                    hint: 'Descrivi il problema...',
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
                  color: AppColors.accentRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.accentRed.withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: AppColors.accentRed, size: 20),
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
                      color: Colors.white.withValues(alpha: 0.04),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.accentBlue, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
      activeTrackColor: AppColors.accentBlue.withValues(alpha: 0.3),
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
        border: selected ? Border.all(color: Colors.white, width: 2) : null,
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
