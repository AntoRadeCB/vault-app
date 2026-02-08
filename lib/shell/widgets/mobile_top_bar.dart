import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../../widgets/animated_widgets.dart';
import '../../services/firestore_service.dart';

/// Mobile top bar with profile icon, title, and notifications bell.
class MobileTopBar extends StatelessWidget {
  final UserProfile? profile;
  final bool showNotifications;
  final VoidCallback onProfileSwitch;
  final VoidCallback onShowNotifications;
  final GlobalKey notificationsKey;

  MobileTopBar({
    super.key,
    required this.profile,
    required this.showNotifications,
    required this.onProfileSwitch,
    required this.onShowNotifications,
    required this.notificationsKey,
  });

  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Profile + menu icon (tappable to open settings drawer)
          GestureDetector(
            onTap: onProfileSwitch,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu, color: AppColors.textMuted, size: 20),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: profile != null
                        ? LinearGradient(
                            colors: [
                              profile!.color,
                              profile!.color.withValues(alpha: 0.6),
                            ],
                          )
                        : AppColors.headerGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    profile?.icon ?? Icons.view_in_ar,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onProfileSwitch,
            child: Text(
              profile?.name ?? 'Vault',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const Spacer(),
          StreamBuilder<int>(
            stream: _firestoreService.getUnreadNotificationCount(),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return GestureDetector(
                key: notificationsKey,
                onTap: onShowNotifications,
                child: PulsingBadge(
                  count: count,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: showNotifications
                          ? AppColors.accentBlue.withValues(alpha: 0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: showNotifications
                            ? AppColors.accentBlue.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Icon(
                      showNotifications
                          ? Icons.notifications
                          : Icons.notifications_outlined,
                      color: showNotifications
                          ? AppColors.accentBlue
                          : AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
