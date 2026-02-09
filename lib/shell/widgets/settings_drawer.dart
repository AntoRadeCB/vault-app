import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/ebay_service.dart';
import '../../providers/profile_provider.dart';
import '../../models/user_profile.dart';
import '../../screens/reports_screen.dart';

/// Shows the settings drawer as an overlay from the left.
void showSettingsDrawer(BuildContext context, {VoidCallback? onProfileSwitched}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Settings',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => _SettingsDrawerOverlay(
      onProfileSwitched: onProfileSwitched,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return SlideTransition(position: slide, child: child);
    },
  );
}

class _SettingsDrawerOverlay extends StatefulWidget {
  final VoidCallback? onProfileSwitched;
  const _SettingsDrawerOverlay({this.onProfileSwitched});

  @override
  State<_SettingsDrawerOverlay> createState() => _SettingsDrawerOverlayState();
}

class _SettingsDrawerOverlayState extends State<_SettingsDrawerOverlay> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final EbayService _ebayService = EbayService();

  bool _showProfiles = false;

  // eBay state
  bool _ebayConnected = false;
  String? _ebayUserId;
  bool _ebayLoading = true;

  User? get _user => _authService.currentUser;
  String get _userName => _user?.displayName ?? 'Vault User';
  String get _userEmail => _user?.email ?? 'vault@cardvault.app';

  @override
  void initState() {
    super.initState();
    _checkEbayConnection();
  }

  Future<void> _checkEbayConnection() async {
    try {
      final status = await _ebayService.getConnectionStatus();
      if (mounted) {
        setState(() {
          _ebayConnected = status['connected'] == true;
          _ebayUserId = status['ebayUserId'];
          _ebayLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _ebayLoading = false);
    }
  }

  void _close() => Navigator.of(context).pop();

  void _showSnackbar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Account actions ────────────────────────────
  void _resetPassword() async {
    try {
      await _authService.resetPassword(_userEmail);
      if (!mounted) return;
      _showSnackbar('Email di reset inviata a $_userEmail');
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Errore: $e');
    }
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Elimina Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Sei sicuro? Questa azione è irreversibile.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla', style: TextStyle(color: AppColors.textMuted))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _user?.delete();
              } catch (_) {
                if (mounted) _showSnackbar('Riaccedi prima di eliminare l\'account');
              }
            },
            child: const Text('Elimina', style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── eBay actions ───────────────────────────────
  Future<void> _connectEbay() async {
    try {
      final url = await _ebayService.getAuthUrl();
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (!mounted) return;
      final code = await _showCodeDialog();
      if (code != null && code.isNotEmpty) {
        await _ebayService.connectEbay(code);
        await _checkEbayConnection();
      }
    } catch (e) {
      if (mounted) _showSnackbar('Errore: $e');
    }
  }

  Future<String?> _showCodeDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Codice di autorizzazione', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Dopo aver autorizzato su eBay, incolla qui il codice dalla URL di callback.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 16),
            TextField(controller: controller, style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(hintText: 'Codice...')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Connetti'),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnectEbay() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Disconnetti eBay', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Vuoi disconnettere il tuo account eBay?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disconnetti'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _ebayService.disconnectEbay();
      await _checkEbayConnection();
    }
  }

  void _showNewProfileSheet() {
    final presets = UserProfile.presets;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Nuovo Profilo', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Scegli il tipo di gioco', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            ...presets.map((preset) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final doc = await _firestoreService.addProfile(preset);
                    _firestoreService.setActiveProfile(doc.id);
                    setState(() => _showProfiles = false);
                    widget.onProfileSwitched?.call();
                    if (mounted) _showSnackbar('Profilo "${preset.name}" creato!');
                  } catch (e) {
                    if (mounted) _showSnackbar('Errore: $e');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: preset.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: preset.color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(preset.icon, color: preset.color, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(preset.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(UserProfile.categoryHint(preset.type), style: const TextStyle(color: AppColors.textMuted, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: preset.color.withValues(alpha: 0.5), size: 14),
                    ],
                  ),
                ),
              ),
            )),
            const SizedBox(height: 8),
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
        content: const Text('Sei sicuro di voler uscire?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla', style: TextStyle(color: AppColors.textMuted))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _close();
              await _authService.signOut();
            },
            child: const Text('Esci', style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog({required String title, required String currentValue, required ValueChanged<String> onSave, bool isPassword = false}) {
    final controller = TextEditingController(text: isPassword ? '' : currentValue);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                obscureText: isPassword,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Inserisci $title',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true, fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5)),
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: ScaleOnPress(onTap: () => Navigator.pop(ctx), child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('Annulla', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 15))),
                ))),
                const SizedBox(width: 12),
                Expanded(child: ScaleOnPress(onTap: () { if (controller.text.isNotEmpty) onSave(controller.text); Navigator.pop(ctx); }, child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(gradient: AppColors.blueButtonGradient, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('Salva', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                ))),
              ]),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = (screenWidth * 0.85).clamp(0.0, 360.0);
    final provider = ProfileProvider.maybeOf(context);
    final profiles = provider?.profiles ?? [];
    final activeProfile = provider?.profile;
    final autoInventory = activeProfile?.autoInventory ?? false;

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: drawerWidth,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.95),
              border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // ── Header ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            gradient: activeProfile != null
                                ? LinearGradient(colors: [activeProfile.color, activeProfile.color.withValues(alpha: 0.6)])
                                : AppColors.headerGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(activeProfile?.icon ?? Icons.person, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(activeProfile?.name ?? 'Vault', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _close,
                          icon: const Icon(Icons.close, color: AppColors.textMuted, size: 22),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Profile switcher toggle ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => setState(() => _showProfiles = !_showProfiles),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.swap_horiz, color: AppColors.accentBlue, size: 18),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('Cambia profilo', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500))),
                            AnimatedRotation(
                              turns: _showProfiles ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Profile list ──
                  AnimatedCrossFade(
                    firstChild: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Column(
                        children: [
                          ...profiles.map((p) {
                            final isActive = p.id == activeProfile?.id;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: GestureDetector(
                                onTap: () {
                                  provider?.switchProfile(p.id);
                                  setState(() => _showProfiles = false);
                                  widget.onProfileSwitched?.call();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isActive ? p.color.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: isActive ? p.color.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.04)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(p.icon, color: p.color, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(p.name, style: TextStyle(color: isActive ? Colors.white : AppColors.textSecondary, fontSize: 13, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400))),
                                      if (isActive) Icon(Icons.check_circle, color: p.color, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          // ── Add new profile button ──
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: GestureDetector(
                              onTap: () => _showNewProfileSheet(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.2), style: BorderStyle.solid),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.add_circle_outline, color: AppColors.accentBlue, size: 18),
                                    const SizedBox(width: 10),
                                    Text('Nuovo profilo', style: TextStyle(color: AppColors.accentBlue, fontSize: 13, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    secondChild: const SizedBox.shrink(),
                    crossFadeState: _showProfiles ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 250),
                  ),

                  const SizedBox(height: 4),
                  Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),

                  // ── Scrollable settings ──
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        // ═══ ACCOUNT ═══
                        _sectionHeader('Account', Icons.person_outline, AppColors.accentBlue),
                        const SizedBox(height: 8),
                        _settingTile(Icons.email_outlined, 'Email', _userEmail, onTap: () {
                          _showEditDialog(title: 'Email', currentValue: _userEmail, onSave: (v) async {
                            try { await _authService.updateEmail(v); if (mounted) _showSnackbar('Email di verifica inviata'); } catch (e) { if (mounted) _showSnackbar('Errore: $e'); }
                          });
                        }),
                        _settingTile(Icons.lock_outline, 'Password', 'Reset via email', onTap: _resetPassword),
                        _settingTile(Icons.delete_outline, 'Elimina account', 'Azione irreversibile', onTap: _deleteAccount, iconColor: AppColors.accentRed),
                        const SizedBox(height: 16),

                        // ═══ PROFILO ═══
                        if (activeProfile != null) ...[
                          _sectionHeader('Profilo', Icons.account_circle_outlined, activeProfile.color),
                          const SizedBox(height: 8),
                          _settingTile(activeProfile.icon, 'Nome', activeProfile.name, iconColor: activeProfile.color, onTap: () {
                            _showEditDialog(title: 'Nome Profilo', currentValue: activeProfile.name, onSave: (v) {
                              _firestoreService.updateProfile(activeProfile.id, {'name': v});
                              _showSnackbar('Nome aggiornato');
                            });
                          }),
                          _settingTile(Icons.category_outlined, 'Tipo', UserProfile.categoryLabel(activeProfile.type), iconColor: activeProfile.color),
                          _settingTile(Icons.savings_outlined, 'Budget', activeProfile.hasBudget ? '€${activeProfile.budgetMonthly!.toStringAsFixed(0)}/mese' : 'Non impostato', iconColor: AppColors.accentGreen, onTap: () => _showBudgetEditor(activeProfile)),
                          _settingTile(Icons.copy_all, 'Copie collezione', '${activeProfile.collectionTarget}', iconColor: AppColors.accentTeal, trailing: _buildStepper(activeProfile)),
                          _settingTile(Icons.bar_chart, 'Report', 'Statistiche e grafici', iconColor: AppColors.accentPurple, onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => Scaffold(
                                backgroundColor: AppColors.background,
                                appBar: AppBar(backgroundColor: AppColors.background, leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => Navigator.of(context).pop()), title: const Text('Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                body: const ReportsScreen(),
                              ),
                            ));
                          }),
                          const SizedBox(height: 16),
                        ],

                        // ═══ PREFERENZE ═══
                        _sectionHeader('Preferenze', Icons.tune_outlined, AppColors.accentOrange),
                        const SizedBox(height: 8),
                        _settingTile(Icons.notifications_active_outlined, 'Notifiche', 'Avvisi vendite e spedizioni', iconColor: AppColors.accentOrange),
                        _settingTile(Icons.dark_mode_outlined, 'Tema scuro', 'Attivo', iconColor: AppColors.accentPurple),
                        const SizedBox(height: 16),

                        // ═══ MARKETPLACE ═══
                        _sectionHeader('Marketplace', Icons.storefront, AppColors.accentGreen),
                        const SizedBox(height: 8),
                        // eBay connection
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.store, color: Color(0xFFE53238), size: 18),
                                  const SizedBox(width: 8),
                                  const Text('eBay', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                  const Spacer(),
                                  if (_ebayLoading)
                                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentBlue))
                                  else ...[
                                    Container(width: 8, height: 8, decoration: BoxDecoration(color: _ebayConnected ? AppColors.accentGreen : AppColors.accentRed, shape: BoxShape.circle)),
                                    const SizedBox(width: 6),
                                    Text(_ebayConnected ? 'Connesso' : 'Non connesso', style: TextStyle(color: _ebayConnected ? AppColors.accentGreen : AppColors.textMuted, fontSize: 11)),
                                  ],
                                ],
                              ),
                              if (_ebayConnected && _ebayUserId != null) ...[
                                const SizedBox(height: 6),
                                Text(_ebayUserId!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                              ],
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _ebayConnected ? _disconnectEbay : _connectEbay,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _ebayConnected ? AppColors.accentRed.withValues(alpha: 0.1) : AppColors.accentBlue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: (_ebayConnected ? AppColors.accentRed : AppColors.accentBlue).withValues(alpha: 0.2)),
                                  ),
                                  child: Center(child: Text(
                                    _ebayConnected ? 'Disconnetti' : 'Connetti eBay',
                                    style: TextStyle(color: _ebayConnected ? AppColors.accentRed : AppColors.accentBlue, fontSize: 12, fontWeight: FontWeight.w600),
                                  )),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Auto-inventory
                        if (activeProfile != null)
                          _settingTileWithSwitch(Icons.inventory_2_outlined, 'Auto-inventario', 'Sposta eccesso in vendita', autoInventory, (v) {
                            _firestoreService.updateProfile(activeProfile.id, {'autoInventory': v});
                          }),
                        const SizedBox(height: 8),
                        // Shipping defaults
                        _infoCard('Spedizione', [
                          _kvRow('Servizio', 'Posta Ordinaria'),
                          _kvRow('Costo', '€2.50'),
                          _kvRow('Gestione', '1-2 giorni'),
                        ]),
                        const SizedBox(height: 8),
                        _infoCard('Reso', [
                          _kvRow('Accetta resi', 'Sì'),
                          _kvRow('Entro', '30 giorni'),
                          _kvRow('Spedizione', 'Acquirente'),
                        ]),
                        const SizedBox(height: 8),
                        _infoCard('Pagamento', [
                          _kvRow('Metodo', 'Gestiti eBay'),
                        ]),
                        const SizedBox(height: 16),

                        // ═══ INFO ═══
                        _sectionHeader('Info', Icons.info_outline, AppColors.textMuted),
                        const SizedBox(height: 8),
                        _settingTile(Icons.code, 'Versione', 'Vault v1.0.0'),
                        _settingTile(Icons.bug_report_outlined, 'Segnala bug', 'Invia feedback', onTap: () {
                          _showEditDialog(title: 'Segnala un problema', currentValue: '', onSave: (text) async {
                            try {
                              await _firestoreService.submitFeedback(text);
                              if (mounted) _showSnackbar('Grazie per il feedback!');
                            } catch (e) {
                              if (mounted) _showSnackbar('Errore: $e');
                            }
                          });
                        }),
                        const SizedBox(height: 16),

                        // ═══ LOGOUT ═══
                        GestureDetector(
                          onTap: _showLogoutDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.accentRed.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.2)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout, color: AppColors.accentRed, size: 18),
                                SizedBox(width: 8),
                                Text('Logout', style: TextStyle(color: AppColors.accentRed, fontSize: 14, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  // ─── Helper widgets ─────────────────────────────

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Text(title.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
      ],
    );
  }

  Widget _settingTile(IconData icon, String title, String subtitle, {VoidCallback? onTap, Color? iconColor, Widget? trailing}) {
    final color = iconColor ?? AppColors.accentBlue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(7)),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (trailing != null) trailing
              else if (onTap != null) const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingTileWithSwitch(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.accentGreen.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(7)),
            child: Icon(icon, color: AppColors.accentGreen, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(value: value, onChanged: onChanged, activeColor: AppColors.accentGreen, activeTrackColor: AppColors.accentGreen.withValues(alpha: 0.3), inactiveThumbColor: AppColors.textMuted, inactiveTrackColor: AppColors.surface),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...rows,
        ],
      ),
    );
  }

  Widget _kvRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStepper(UserProfile profile) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            final v = (profile.collectionTarget - 1).clamp(1, 10);
            _firestoreService.updateProfile(profile.id, {'collectionTarget': v});
          },
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.remove, color: AppColors.textSecondary, size: 14),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('${profile.collectionTarget}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        GestureDetector(
          onTap: () {
            final v = (profile.collectionTarget + 1).clamp(1, 10);
            _firestoreService.updateProfile(profile.id, {'collectionTarget': v});
          },
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: AppColors.accentBlue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.add, color: AppColors.accentBlue, size: 14),
          ),
        ),
      ],
    );
  }

  void _showBudgetEditor(UserProfile profile) {
    final controller = TextEditingController(text: profile.budgetMonthly?.toStringAsFixed(0) ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Budget Mensile', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Lascia vuoto per disabilitare.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '€0', hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixText: '€ ', prefixStyle: const TextStyle(color: AppColors.accentGreen, fontSize: 24, fontWeight: FontWeight.bold),
                  filled: true, fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: GestureDetector(onTap: () => Navigator.pop(ctx), child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('Annulla', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
                ))),
                const SizedBox(width: 12),
                Expanded(child: GestureDetector(onTap: () {
                  final value = double.tryParse(controller.text.trim());
                  _firestoreService.updateProfile(profile.id, {'budgetMonthly': value});
                  Navigator.pop(ctx);
                  _showSnackbar(value != null ? 'Budget: €${value.toStringAsFixed(0)}' : 'Budget rimosso');
                }, child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF2E7D32)]), borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('Salva', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ))),
              ]),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
