import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/core/theme/dynamic_colors.dart';
import 'package:expense_tracker/core/di/injection_container.dart';
import 'package:expense_tracker/features/notifications/data/models/app_notification_model.dart';
import 'package:expense_tracker/services/database_helper.dart';
import 'package:expense_tracker/services/notification_service.dart';

class NotificationSheet extends StatelessWidget {
  final String? userEmail;

  const NotificationSheet({
    super.key,
    this.userEmail,
  });

  static Future<void> show(BuildContext context, {String? userEmail}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationSheet(userEmail: userEmail),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24 && dt.day == now.day) {
      return DateFormat('h:mm a').format(dt);
    } else if (diff.inDays < 2 && now.day - dt.day == 1) {
      return 'Yesterday at ${DateFormat('h:mm a').format(dt)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(dt);
    }
  }

  Widget _getNotificationIcon(NotificationType type) {
    IconData icon;
    List<Color> gradientColors;

    switch (type) {
      case NotificationType.bill:
        icon = Icons.receipt_long_rounded;
        gradientColors = [const Color(0xFFFF9500), const Color(0xFFFF5E00)];
        break;
      case NotificationType.budget:
        icon = Icons.account_balance_wallet_rounded;
        gradientColors = [const Color(0xFFFF3B30), const Color(0xFFFF2D55)];
        break;
      case NotificationType.goal:
        icon = Icons.emoji_events_rounded;
        gradientColors = [AppColors.primary, AppColors.secondary];
        break;
      case NotificationType.reminder:
        icon = Icons.alarm_rounded;
        gradientColors = [const Color(0xFF007AFF), const Color(0xFF5856D6)];
        break;
      case NotificationType.system:
        icon = Icons.notifications_active_rounded;
        gradientColors = [const Color(0xFFAF52DE), const Color(0xFF5856D6)];
        break;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 25,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          ValueListenableBuilder<List<AppNotificationModel>>(
            valueListenable: sl<DatabaseHelper>().notificationsNotifier,
            builder: (context, notifications, _) {
              final unreadCount = notifications.where((n) => !n.isRead).length;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      'Notifications',
                      style: AppTextStyles.heading2.copyWith(
                        color: c.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.expenseRed,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unreadCount New',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: c.textSecondary),
                      color: c.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (value) async {
                        if (value == 'test_notif') {
                          await NotificationService().showBudgetAlertNotification(
                            title: '🔔 Test Notification',
                            body: 'Notifications are working perfectly on your device!',
                            userEmail: userEmail ?? '',
                          );
                        } else if (value == 'mark_read') {
                          await sl<DatabaseHelper>()
                              .markAllNotificationsAsRead(userEmail);
                        } else if (value == 'clear_all') {
                          await sl<DatabaseHelper>()
                              .clearAllNotifications(userEmail);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'test_notif',
                          child: Row(
                            children: [
                              Icon(Icons.notifications_active_outlined,
                                  size: 18, color: c.primary),
                              const SizedBox(width: 10),
                              Text('Send test notification',
                                  style: TextStyle(color: c.textPrimary)),
                            ],
                          ),
                        ),
                        if (unreadCount > 0)
                          PopupMenuItem(
                            value: 'mark_read',
                            child: Row(
                              children: [
                                Icon(Icons.done_all,
                                    size: 18, color: c.primary),
                                const SizedBox(width: 10),
                                Text('Mark all as read',
                                    style: TextStyle(color: c.textPrimary)),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'clear_all',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 18, color: AppColors.expenseRed),
                              const SizedBox(width: 10),
                              Text('Clear all',
                                  style:
                                      TextStyle(color: AppColors.expenseRed)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Divider(color: c.divider, height: 1),

          // Notifications List
          Expanded(
            child: ValueListenableBuilder<List<AppNotificationModel>>(
              valueListenable: sl<DatabaseHelper>().notificationsNotifier,
              builder: (context, notifications, _) {
                if (notifications.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: c.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_none_rounded,
                              size: 48,
                              color: c.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Notifications',
                            style: AppTextStyles.heading2.copyWith(
                              color: c.textPrimary,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You\'re all caught up! Check back later for bill reminders, budget limits, and goal progress.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: c.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final bottomPadding = MediaQuery.of(context).padding.bottom + 32;

                return ListView.separated(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: bottomPadding,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          await sl<DatabaseHelper>()
                              .markNotificationAsRead(item.id, userEmail);
                          if (item.actionRoute != null &&
                              item.actionRoute!.isNotEmpty &&
                              context.mounted) {
                            Navigator.of(context).pop();
                            context.push(item.actionRoute!);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: item.isRead
                                ? c.card.withOpacity(0.6)
                                : c.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: item.isRead
                                  ? c.border.withOpacity(0.5)
                                  : c.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _getNotificationIcon(item.type),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                              color: c.textPrimary,
                                              fontWeight: item.isRead
                                                  ? FontWeight.w600
                                                  : FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        if (!item.isRead) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppColors.expenseRed,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.description,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: c.textSecondary,
                                        fontSize: 13,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _formatTimestamp(item.timestamp),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: c.textSecondary.withOpacity(0.7),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
