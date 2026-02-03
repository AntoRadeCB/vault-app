import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_widgets.dart';
import '../../providers/profile_provider.dart';

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
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
