import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../models/app_notification.dart';
import '../services/firestore_service.dart';
import '../l10n/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const NotificationsScreen({super.key, this.onBack});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirestoreService _fs = FirestoreService();

  void _markAsRead(AppNotification notif) {
    if (notif.id != null && !notif.read) {
      _fs.markNotificationRead(notif.id!);
    }
  }

  void _markAllAsRead(List<AppNotification> notifications) {
    for (final n in notifications) {
      if (n.id != null && !n.read) {
        _fs.markNotificationRead(n.id!);
      }
    }
  }

  void _deleteNotification(AppNotification notif) {
    if (notif.id != null) {
      _fs.deleteNotification(notif.id!);
    }
  }

  void _clearAll() {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.deleteAll,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          l.deleteAllNotifications,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel,
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _fs.clearAllNotifications();
            },
            child: Text(l.delete,
                style: const TextStyle(
                    color: AppColors.accentRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: StaggeredFadeSlide(
            index: 0,
            child: Row(
              children: [
                if (widget.onBack != null) ...[
                  ScaleOnPress(
                    onTap: widget.onBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                Text(
                  l.notifications,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 12),
                StreamBuilder<int>(
                  stream: _fs.getUnreadNotificationCount(),
                  builder: (context, snap) {
                    final count = snap.data ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accentRed.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        l.nUnread(count),
                        style: const TextStyle(
                          color: AppColors.accentRed,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    );
                  },
                ),
                const Spacer(),
                // Mark all as read
                StreamBuilder<List<AppNotification>>(
                  stream: _fs.getNotifications(),
                  builder: (context, snap) {
                    final notifications = snap.data ?? [];
                    final hasUnread = notifications.any((n) => !n.read);
                    if (!hasUnread) return const SizedBox.shrink();
                    return ScaleOnPress(
                      onTap: () => _markAllAsRead(notifications),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color:
                                  AppColors.accentBlue.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          l.markAllRead,
                          style: const TextStyle(
                            color: AppColors.accentBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                ScaleOnPress(
                  onTap: _clearAll,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.accentRed.withValues(alpha: 0.15)),
                    ),
                    child: const Icon(Icons.delete_sweep,
                        color: AppColors.accentRed, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // List
        Expanded(
          child: StreamBuilder<List<AppNotification>>(
            stream: _fs.getNotifications(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.accentBlue),
                );
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                          size: 64),
                      const SizedBox(height: 16),
                      Text(
                        l.noNotifications,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.notificationsWillAppearHere,
                        style:
                            const TextStyle(color: AppColors.textMuted, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  return StaggeredFadeSlide(
                    index: index + 1,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _NotificationCard(
                        notification: notifications[index],
                        onTap: () => _markAsRead(notifications[index]),
                        onDismiss: () =>
                            _deleteNotification(notifications[index]),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  Color get _typeColor {
    switch (notification.type) {
      case NotificationType.shipmentUpdate:
        return AppColors.accentBlue;
      case NotificationType.sale:
        return AppColors.accentGreen;
      case NotificationType.lowStock:
        return AppColors.accentOrange;
      case NotificationType.system:
        return AppColors.accentPurple;
    }
  }

  IconData get _typeIcon {
    switch (notification.type) {
      case NotificationType.shipmentUpdate:
        return Icons.local_shipping;
      case NotificationType.sale:
        return Icons.sell;
      case NotificationType.lowStock:
        return Icons.warning_amber;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final typeLabel = _localizedTypeLabel(l);
    return Dismissible(
      key: Key(notification.id ?? notification.createdAt.toIso8601String()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.accentRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: AppColors.accentRed, size: 24),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          glowColor: notification.read ? AppColors.textMuted : _typeColor,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _typeColor.withValues(
                      alpha: notification.read ? 0.06 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _typeIcon,
                  color: notification.read
                      ? _typeColor.withValues(alpha: 0.5)
                      : _typeColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _typeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(
                              color: _typeColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatTime(notification.createdAt, l),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.title,
                      style: TextStyle(
                        color: notification.read
                            ? AppColors.textSecondary
                            : Colors.white,
                        fontWeight: notification.read
                            ? FontWeight.w400
                            : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: notification.read
                            ? AppColors.textMuted
                            : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!notification.read) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: _typeColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _typeColor.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _localizedTypeLabel(AppLocalizations l) {
    switch (notification.type) {
      case NotificationType.shipmentUpdate:
        return l.shipmentType;
      case NotificationType.sale:
        return l.saleType;
      case NotificationType.lowStock:
        return l.lowStockType;
      case NotificationType.system:
        return l.systemType;
    }
  }

  String _formatTime(DateTime date, AppLocalizations l) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return l.now;
    if (diff.inMinutes < 60) return l.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return l.daysAgo(diff.inDays);
    return '${date.day}/${date.month}/${date.year}';
  }
}
