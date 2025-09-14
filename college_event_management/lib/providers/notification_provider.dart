import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> loadNotifications(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _notificationService.getUserNotifications(userId);
      _unreadCount = await _notificationService.getUnreadNotificationCount(
        userId,
      );
    } catch (e) {
      print('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);

      // Cập nhật local state
      int index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _notifications[index]['isRead'] = true;
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        notifyListeners();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _notificationService.markAllNotificationsAsRead(userId);

      // Cập nhật local state
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  Future<void> sendRegistrationSuccessNotification({
    required String userId,
    required String eventTitle,
    required String eventId,
  }) async {
    await _notificationService.sendRegistrationSuccessNotification(
      userId: userId,
      eventTitle: eventTitle,
      eventId: eventId,
    );

    // Reload notifications để cập nhật UI
    await loadNotifications(userId);
  }

  Future<void> sendPaymentSuccessNotification({
    required String userId,
    required String eventTitle,
    required double amount,
    required String eventId,
  }) async {
    await _notificationService.sendPaymentSuccessNotification(
      userId: userId,
      eventTitle: eventTitle,
      amount: amount,
      eventId: eventId,
    );

    // Reload notifications để cập nhật UI
    await loadNotifications(userId);
  }

  Future<void> sendSupportApprovalNotification({
    required String userId,
    required String eventTitle,
    required String eventId,
  }) async {
    await _notificationService.sendSupportApprovalNotification(
      userId: userId,
      eventTitle: eventTitle,
      eventId: eventId,
    );

    // Reload notifications để cập nhật UI
    await loadNotifications(userId);
  }

  Future<void> sendCancellationNotification({
    required String userId,
    required String eventTitle,
    required String eventId,
    required bool isRefund,
    double? refundAmount,
  }) async {
    await _notificationService.sendCancellationNotification(
      userId: userId,
      eventTitle: eventTitle,
      eventId: eventId,
      isRefund: isRefund,
      refundAmount: refundAmount,
    );

    // Reload notifications để cập nhật UI
    await loadNotifications(userId);
  }
}
