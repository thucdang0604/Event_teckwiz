import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );

    if (authProvider.currentUser != null) {
      notificationProvider.loadNotifications(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return TextButton(
                onPressed: () async {
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  if (authProvider.currentUser != null) {
                    await notificationProvider.markAllAsRead(
                      authProvider.currentUser!.id,
                    );
                  }
                },
                child: const Text(
                  'Đánh dấu tất cả đã đọc',
                  style: TextStyle(color: AppColors.white),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notificationProvider.notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: AppColors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có thông báo nào',
                    style: TextStyle(fontSize: 18, color: AppColors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadNotifications();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notificationProvider.notifications.length,
              itemBuilder: (context, index) {
                final notification = notificationProvider.notifications[index];
                return _buildNotificationCard(
                  notification,
                  notificationProvider,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
    NotificationProvider notificationProvider,
  ) {
    final bool isRead = notification['isRead'] ?? false;
    final String type = notification['type'] ?? '';
    final String title = notification['title'] ?? '';
    final String body = notification['body'] ?? '';
    final DateTime createdAt = (notification['createdAt'] as Timestamp)
        .toDate();

    IconData icon;
    Color iconColor;

    switch (type) {
      case 'registration_success':
        icon = Icons.check_circle;
        iconColor = AppColors.success;
        break;
      case 'payment_success':
        icon = Icons.payment;
        iconColor = AppColors.primary;
        break;
      case 'support_approval':
        icon = Icons.volunteer_activism;
        iconColor = AppColors.warning;
        break;
      case 'cancellation':
        icon = Icons.cancel;
        iconColor = AppColors.error;
        break;
      default:
        icon = Icons.notifications;
        iconColor = AppColors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 1 : 3,
      color: isRead ? AppColors.white : AppColors.primary.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            color: isRead ? AppColors.grey : AppColors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              body,
              style: TextStyle(
                color: isRead ? AppColors.grey : AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDateTime(createdAt),
              style: const TextStyle(fontSize: 12, color: AppColors.grey),
            ),
          ],
        ),
        trailing: isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () async {
          if (!isRead) {
            await notificationProvider.markAsRead(notification['id']);
          }

          // Có thể thêm navigation đến event detail nếu cần
          final String? eventId = notification['eventId'];
          if (eventId != null) {
            // Navigator.push(context, MaterialPageRoute(...));
          }
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
