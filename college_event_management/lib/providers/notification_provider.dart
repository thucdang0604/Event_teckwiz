import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {


  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _currentUserId;
  String? _currentUserRole; // 'admin', 'organizer', 'student', ...

  List<NotificationModel> get notifications => _notifications;
  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;

  NotificationProvider() {
    // Set up callback for when notifications are updated
    NotificationService.setNotificationUpdateCallback(_onNotificationsUpdated);
    _loadNotifications();
  }

  // Call this when auth user changes
  void setUser(String? userId, String? role) {
    final changed = _currentUserId != userId || _currentUserRole != role;
    _currentUserId = userId;
    _currentUserRole = role;
    if (changed) {
      _loadNotifications();
    }
  }

  void _onNotificationsUpdated() {
    // Reload notifications when they are updated
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {

    _isLoading = true;
    notifyListeners();

    try {

      // Ensure notification history is loaded before getting it
      await NotificationService.loadNotificationHistory();

      final all = NotificationService.getNotificationHistory();
      _notifications = all.where(_filterForCurrentUser).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error loading notifications: $e');
    }
  }

  bool _filterForCurrentUser(NotificationModel notification) {
    final data = notification.data;
    final targetRole = data != null ? data['targetRole'] as String? : null;
    final targetUserId = data != null ? data['targetUserId'] as String? : null;

    // Admin: see admin-targeted or general broadcast (no specific target)
    if (_currentUserRole == 'admin') {
      if (targetUserId != null) return false; // user-specific
      if (targetRole == null || targetRole == 'admin') return true;
      return false;
    }

    // Non-admin: see notifications targeted to this user, or general that are not admin-only
    if (targetUserId != null) return targetUserId == _currentUserId;
    if (targetRole == 'admin') return false; // exclude admin-only
    return true; // general broadcast
  }

  Future<void> markAsRead(String notificationId) async {
    await NotificationService.markNotificationAsRead(notificationId);
    await _loadNotifications();
  }

  Future<void> markAllAsRead() async {
    for (final notification in unreadNotifications) {
      await NotificationService.markNotificationAsRead(notification.id);
    }
    await _loadNotifications();
  }

  Future<void> clearAllNotifications() async {
    await NotificationService.clearNotificationHistory();
    await _loadNotifications();
  }

  void refreshNotifications() {
    _loadNotifications();
  }

  // Method to manually trigger notification refresh after adding new notifications
  Future<void> forceRefresh() async {
    await _loadNotifications();
  }
}
