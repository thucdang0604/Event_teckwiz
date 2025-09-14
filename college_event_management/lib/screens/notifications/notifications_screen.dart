import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';

// Định nghĩa NotificationType nếu chưa có
enum NotificationType {
  eventCreated,
  eventUpdated,
  eventCancelled,
  registrationConfirmed,
  registrationRejected,
  eventReminder,
  chatMessage,
  unknown,
}

// Định nghĩa NotificationModel nếu chưa có
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.isRead,
    required this.type,
    this.data,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      final notificationProvider = context.read<NotificationProvider>();
      final user = authProvider.currentUser;
      if (user != null) {
        await notificationProvider.loadNotifications(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentUser?.role;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.25,
            ),
          ),
          backgroundColor: role == 'admin'
              ? AppColors.adminPrimary
              : AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: true,
          actions: [
            Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                if (provider.unreadCount > 0) {
                  return IconButton(
                    icon: const Icon(Icons.done_all),
                    onPressed: () => _showMarkAllReadDialog(context),
                    tooltip: 'Mark all as read',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () => _showClearAllDialog(context),
              tooltip: 'Clear all',
            ),
          ],
        ),
        body: Consumer<NotificationProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final notifications = provider.notifications;

            if (notifications.isEmpty) {
              return _buildEmptyState();
            }

            return Container(
              color: AppColors.surfaceVariant,
              child: RefreshIndicator(
                onRefresh: () async {
                  final authProvider = context.read<AuthProvider>();
                  final user = authProvider.currentUser;
                  if (user != null) {
                    await provider.loadNotifications(user.id);
                  }
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationItem(
                      notification as NotificationModel,
                      provider,
                    );
                  },
                ),
              ),
            );
          },
        ),
        // Xóa bottomNavigationBar vì AppBottomNavigationBar không tồn tại hoặc lỗi import
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your notifications will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationModel notification,
    NotificationProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: notification.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (!notification.isRead) {
            provider.markAsRead(notification.id);
          }
          _handleNotificationTap(notification);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(notification.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                              color: notification.isRead
                                  ? Colors.grey[700]
                                  : Colors.black,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimestamp(notification.timestamp),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case NotificationType.eventCreated:
        iconData = Icons.event_available;
        iconColor = Colors.green;
        break;
      case NotificationType.eventUpdated:
        iconData = Icons.event_note;
        iconColor = Colors.blue;
        break;
      case NotificationType.eventCancelled:
        iconData = Icons.event_busy;
        iconColor = Colors.red;
        break;
      case NotificationType.registrationConfirmed:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case NotificationType.registrationRejected:
        iconData = Icons.cancel;
        iconColor = Colors.red;
        break;
      case NotificationType.eventReminder:
        iconData = Icons.alarm;
        iconColor = Colors.orange;
        break;
      case NotificationType.chatMessage:
        iconData = Icons.chat;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return '${difference.inHours} hours ago';
      }
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('dd/MM/yyyy').format(timestamp);
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.eventCreated:
      case NotificationType.eventUpdated:
      case NotificationType.eventCancelled:
        if (notification.data != null &&
            notification.data!['eventId'] != null) {
          context.go('/event-detail/${notification.data!['eventId']}');
        }
        break;
      case NotificationType.registrationConfirmed:
      case NotificationType.registrationRejected:
        context.go('/profile');
        break;
      case NotificationType.chatMessage:
        if (notification.data != null &&
            notification.data!['eventId'] != null) {
          context.go('/event/${notification.data!['eventId']}/chat');
        }
        break;
      default:
        break;
    }
  }

  void _showMarkAllReadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mark All as Read'),
          content: const Text(
            'Are you sure you want to mark all notifications as read?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final authProvider = context.read<AuthProvider>();
                final notificationProvider = context
                    .read<NotificationProvider>();
                final user = authProvider.currentUser;
                if (user != null) {
                  await notificationProvider.markAllAsRead(user.id);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Notifications'),
          content: const Text(
            'Are you sure you want to delete all notifications? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final authProvider = context.read<AuthProvider>();
                final notificationProvider = context
                    .read<NotificationProvider>();
                final user = authProvider.currentUser;
                if (user != null) {
                  await notificationProvider.clearAll(user.id);
                }
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );
  }
}
