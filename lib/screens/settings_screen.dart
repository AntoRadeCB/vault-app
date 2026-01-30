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
                    child: const Center(
                      child: Text(
                        'V',
                        style: TextStyle(
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
                        const Text(
                          'Vault User',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'vault@reselling.pro',
                          style: TextStyle(
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
                    onTap: () {},
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
                  subtitle: 'vault@reselling.pro',
                ),
                _buildSettingsRow(
                  icon: Icons.lock_outline,
                  title: 'Password',
                  subtitle: 'Last changed 30 days ago',
                  trailing: _buildChevron(),
                ),
                _buildSettingsRow(
                  icon: Icons.security,
                  title: '2FA Authentication',
                  subtitle: 'Enabled',
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
                  title: 'Active Workspace',
                  subtitle: 'Reselling Vinted 2025',
                  trailing: _buildChevron(),
                ),
                _buildSettingsRow(
                  icon: Icons.cloud_upload_outlined,
                  title: 'Auto Backup',
                  subtitle: 'Sync data to cloud',
                  trailing: _buildSwitch(_autoBackup, (v) => setState(() => _autoBackup = v)),
                ),
                _buildSettingsRow(
                  icon: Icons.download_outlined,
                  title: 'Export All Data',
                  subtitle: 'CSV, PDF formats',
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
                  subtitle: 'Receive on mobile',
                  trailing: _buildSwitch(_pushNotifications, (v) => setState(() => _pushNotifications = v)),
                ),
                _buildSettingsRow(
                  icon: Icons.mail_outline,
                  title: 'Email Digest',
                  subtitle: 'Weekly summary report',
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
                  subtitle: 'Use dark theme',
                  trailing: _buildSwitch(_darkMode, (v) => setState(() => _darkMode = v)),
                ),
                _buildSettingsRow(
                  icon: Icons.text_fields,
                  title: 'Font Size',
                  subtitle: 'Medium',
                  trailing: _buildChevron(),
                ),
                _buildSettingsRow(
                  icon: Icons.color_lens_outlined,
                  title: 'Accent Color',
                  subtitle: 'Blue-Purple',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _colorDot(AppColors.accentBlue),
                      const SizedBox(width: 4),
                      _colorDot(AppColors.accentPurple),
                      const SizedBox(width: 4),
                      _colorDot(AppColors.accentTeal),
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
                  title: 'Version',
                  subtitle: 'Vault v1.0.0',
                ),
                _buildSettingsRow(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  trailing: _buildChevron(),
                ),
                _buildSettingsRow(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  trailing: _buildChevron(),
                ),
                _buildSettingsRow(
                  icon: Icons.bug_report_outlined,
                  title: 'Report a Bug',
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
              onTap: () {},
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
  }) {
    return Padding(
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

  Widget _colorDot(Color color) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
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
