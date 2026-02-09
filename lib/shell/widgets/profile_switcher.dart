import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_widgets.dart';
import '../../providers/profile_provider.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';

/// Shows a bottom sheet allowing the user to switch between profiles.
///
/// [onSwitched] is called after the sheet is dismissed and the profile
/// has been switched (use this to reset the navigation index, etc.).
void showProfileSwitcher(
  BuildContext context, {
  required VoidCallback onSwitched,
}) {
  final provider = ProfileProvider.of(context);
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
            'Seleziona Profilo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...provider.profiles.map((p) {
            final isActive = p.id == provider.profile?.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ScaleOnPress(
                onTap: () {
                  provider.switchProfile(p.id);
                  Navigator.pop(ctx);
                  onSwitched();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isActive
                        ? p.color.withValues(alpha: 0.15)
                        : AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? p.color.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(p.icon, color: p.color, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p.name,
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 15,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (isActive)
                        Icon(Icons.check_circle, color: p.color, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
          // ── Add new profile button ──
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ScaleOnPress(
              onTap: () {
                Navigator.pop(ctx);
                _showNewProfileSheet(context, onSwitched: onSwitched);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: AppColors.accentBlue, size: 22),
                    const SizedBox(width: 12),
                    Text('Nuovo profilo', style: TextStyle(color: AppColors.accentBlue, fontSize: 15, fontWeight: FontWeight.w500)),
                  ],
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

void _showNewProfileSheet(BuildContext context, {required VoidCallback onSwitched}) {
  final fs = FirestoreService();
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
            child: ScaleOnPress(
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final doc = await fs.addProfile(preset);
                  fs.setActiveProfile(doc.id);
                  onSwitched();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Profilo "${preset.name}" creato!', style: const TextStyle(fontWeight: FontWeight.w600)),
                      backgroundColor: AppColors.accentGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ));
                  }
                } catch (_) {}
              },
              child: Container(
                width: double.infinity,
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
