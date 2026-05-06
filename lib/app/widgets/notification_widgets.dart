/// Notification Widgets
/// Reusable widgets for displaying notifications throughout the app

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';

/// Notification Badge Widget
/// Shows unread notification count
class NotificationBadge extends StatelessWidget {
  final Widget child;
  final bool showBadge;
  final int badgeCount;

  const NotificationBadge({
    super.key,
    required this.child,
    this.showBadge = true,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        final unreadCount = notificationProvider.unreadCount;
        
        if (!showBadge || unreadCount == 0) {
          return child;
        }

        return Stack(
          children: [
            child,
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Notification Item Widget
/// Displays individual notification
class NotificationItem extends StatelessWidget {
  final PushNotification notification;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.grey[100]
              : Color(notification.getNotificationColor()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead ? Colors.grey[300]! : Colors.transparent,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getNotificationIcon(),
                color: notification.isRead ? Colors.grey : Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Notification Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: notification.isRead
                                ? Colors.grey[700]
                                : Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onDelete != null)
                        GestureDetector(
                          onTap: onDelete,
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: notification.isRead
                                ? Colors.grey
                                : Colors.white70,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: notification.isRead
                          ? Colors.grey[600]
                          : Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(notification.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: notification.isRead
                          ? Colors.grey[500]
                          : Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case NotificationType.paymentReceived:
        return Icons.call_received;
      case NotificationType.paymentSent:
        return Icons.call_made;
      case NotificationType.transactionAlert:
        return Icons.notification_important;
      case NotificationType.securityAlert:
        return Icons.security;
      case NotificationType.offerPromotion:
        return Icons.local_offer;
      case NotificationType.walletTopup:
        return Icons.account_balance_wallet;
      case NotificationType.requestMoney:
        return Icons.request_quote;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

/// Notification List Widget
/// Displays all notifications
class NotificationList extends StatelessWidget {
  final bool showOnlyUnread;

  const NotificationList({
    super.key,
    this.showOnlyUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        final notifications = showOnlyUnread
            ? notificationProvider.getUnreadNotifications()
            : notificationProvider.notifications;

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  showOnlyUnread
                      ? 'No unread notifications'
                      : 'No notifications',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return NotificationItem(
              notification: notification,
              onTap: () {
                notificationProvider.markAsRead(notification.messageId ?? '');
              },
              onDelete: () {
                notificationProvider.deleteNotification(
                  notification.messageId ?? '',
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Notification History Dialog
/// Shows all notifications in a dialog
class NotificationHistoryDialog extends StatelessWidget {
  const NotificationHistoryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          // Notifications List
          Flexible(
            child: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.6,
              child: const NotificationList(),
            ),
          ),
          // Footer Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Consumer<NotificationProvider>(
              builder: (context, notificationProvider, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: notificationProvider.hasUnreadNotifications
                          ? () {
                              notificationProvider.markAllAsRead();
                              Navigator.pop(context);
                            }
                          : null,
                      icon: const Icon(Icons.done_all),
                      label: const Text('Mark All Read'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: notificationProvider.notifications.isNotEmpty
                          ? () {
                              notificationProvider.deleteAllNotifications();
                              Navigator.pop(context);
                            }
                          : null,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Clear All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Notification Center Screen
/// Full screen notification management
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  bool _showOnlyUnread = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, _) {
              return PopupMenuButton(
                onSelected: (value) {
                  if (value == 'clear') {
                    _showClearConfirmation(context, notificationProvider);
                  } else if (value == 'mark_read') {
                    notificationProvider.markAllAsRead();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'mark_read',
                    child: Text('Mark All as Read'),
                  ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: Text('Clear All'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _showOnlyUnread = false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: !_showOnlyUnread
                            ? const Color(0xFF2196F3)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'All',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !_showOnlyUnread ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _showOnlyUnread = true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _showOnlyUnread
                            ? const Color(0xFF2196F3)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Unread',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _showOnlyUnread ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Notifications List
          Expanded(
            child: NotificationList(showOnlyUnread: _showOnlyUnread),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation(
    BuildContext context,
    NotificationProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text(
            'This action cannot be undone. All notifications will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteAllNotifications();
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
