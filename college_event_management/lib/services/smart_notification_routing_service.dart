import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'unified_notification_service.dart';
import 'notification_service.dart';

class SmartNotificationRoutingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UnifiedNotificationService _unifiedNotificationService =
      UnifiedNotificationService();

  static const String _userBehaviorCollection = 'user_notification_behavior';

  // Smart routing dựa trên hành vi user
  Future<bool> sendSmartNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    try {
      // Phân tích hành vi user
      final userBehavior = await _analyzeUserBehavior(userId);

      // Xác định channel tối ưu
      _determineOptimalChannel(
        userBehavior,
        type,
        priority,
      );

      // Xác định thời gian tối ưu
      final optimalTime = _determineOptimalTime(userBehavior, type);

      // Gửi notification với cài đặt tối ưu
      return await _unifiedNotificationService.sendUnifiedNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
        priority: priority,
        scheduledTime: optimalTime,
      );
    } catch (e) {
      print('❌ Error in smart notification routing: $e');
      // Fallback to default notification
      return await _unifiedNotificationService.sendUnifiedNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
        priority: priority,
      );
    }
  }

  // Phân tích hành vi user
  Future<Map<String, dynamic>> _analyzeUserBehavior(String userId) async {
    try {
      // Lấy lịch sử thông báo của user
      final notificationHistory = await _unifiedNotificationService
          .getUserNotificationHistory(userId, limit: 100);

      // Lấy preferences của user
      final preferences = await _unifiedNotificationService.getUserPreferences(
        userId,
      );

      // Phân tích patterns
      final patterns = _analyzeNotificationPatterns(notificationHistory);

      // Xác định active hours
      final activeHours = _determineActiveHours(notificationHistory);

      // Xác định preferred channels
      final preferredChannels = _determinePreferredChannels(
        notificationHistory,
        preferences,
      );

      return {
        'patterns': patterns,
        'activeHours': activeHours,
        'preferredChannels': preferredChannels,
        'responseRate': _calculateResponseRate(notificationHistory),
        'engagementScore': _calculateEngagementScore(notificationHistory),
      };
    } catch (e) {
      print('❌ Error analyzing user behavior: $e');
      return {};
    }
  }

  // Phân tích patterns trong lịch sử thông báo
  Map<String, dynamic> _analyzeNotificationPatterns(
    List<Map<String, dynamic>> history,
  ) {
    if (history.isEmpty) return {};

    Map<String, int> typeFrequency = {};
    Map<String, int> channelFrequency = {};
    Map<int, int> hourFrequency = {};
    Map<String, int> dayFrequency = {};

    for (final notification in history) {
      // Thống kê theo loại
      final type = notification['type'] as String? ?? 'unknown';
      typeFrequency[type] = (typeFrequency[type] ?? 0) + 1;

      // Thống kê theo channel
      final channels = List<String>.from(notification['channels'] ?? []);
      for (final channel in channels) {
        channelFrequency[channel] = (channelFrequency[channel] ?? 0) + 1;
      }

      // Thống kê theo giờ
      final timestamp = notification['timestamp'] as Timestamp?;
      if (timestamp != null) {
        final dateTime = timestamp.toDate();
        hourFrequency[dateTime.hour] = (hourFrequency[dateTime.hour] ?? 0) + 1;
        dayFrequency[dateTime.weekday.toString()] =
            (dayFrequency[dateTime.weekday.toString()] ?? 0) + 1;
      }
    }

    return {
      'typeFrequency': typeFrequency,
      'channelFrequency': channelFrequency,
      'hourFrequency': hourFrequency,
      'dayFrequency': dayFrequency,
    };
  }

  // Xác định giờ hoạt động của user
  Map<String, dynamic> _determineActiveHours(
    List<Map<String, dynamic>> history,
  ) {
    if (history.isEmpty) {
      return {
        'peakHours': [9, 14, 19], // Default peak hours
        'quietHours': [22, 23, 0, 1, 2, 3, 4, 5, 6, 7],
        'weekendActive': true,
      };
    }

    final patterns = _analyzeNotificationPatterns(history);
    final hourFrequency = patterns['hourFrequency'] as Map<int, int>? ?? {};
    final dayFrequency = patterns['dayFrequency'] as Map<String, int>? ?? {};

    // Tìm giờ có tần suất cao nhất
    final sortedHours = hourFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final peakHours = sortedHours.take(3).map((e) => e.key).toList();

    // Tìm giờ có tần suất thấp nhất (quiet hours)
    final quietHours = sortedHours.reversed.take(8).map((e) => e.key).toList();

    // Kiểm tra hoạt động cuối tuần
    final weekendActivity = (dayFrequency['6'] ?? 0) + (dayFrequency['7'] ?? 0);
    final weekdayActivity =
        (dayFrequency['1'] ?? 0) +
        (dayFrequency['2'] ?? 0) +
        (dayFrequency['3'] ?? 0) +
        (dayFrequency['4'] ?? 0) +
        (dayFrequency['5'] ?? 0);

    return {
      'peakHours': peakHours.isNotEmpty ? peakHours : [9, 14, 19],
      'quietHours': quietHours.isNotEmpty
          ? quietHours
          : [22, 23, 0, 1, 2, 3, 4, 5, 6, 7],
      'weekendActive': weekendActivity > weekdayActivity * 0.3,
    };
  }

  // Xác định kênh ưa thích
  Map<NotificationType, NotificationChannel> _determinePreferredChannels(
    List<Map<String, dynamic>> history,
    NotificationPreferences? preferences,
  ) {
    if (preferences != null) {
      return preferences.channelPreferences;
    }

    // Phân tích từ lịch sử
    final patterns = _analyzeNotificationPatterns(history);
    final channelFrequency =
        patterns['channelFrequency'] as Map<String, int>? ?? {};

    Map<NotificationType, NotificationChannel> preferredChannels = {};

    for (final type in NotificationType.values) {
      // Mặc định dựa trên loại thông báo
      NotificationChannel defaultChannel = NotificationChannel.both;

      switch (type) {
        case NotificationType.eventReminder:
          defaultChannel = NotificationChannel.push;
          break;
        case NotificationType.chatMessage:
          defaultChannel = NotificationChannel.push;
          break;
        case NotificationType.systemAnnouncement:
          defaultChannel = NotificationChannel.email;
          break;
        default:
          defaultChannel = NotificationChannel.both;
      }

      // Ưu tiên kênh có tần suất cao nhất
      if (channelFrequency.isNotEmpty) {
        final sortedChannels = channelFrequency.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final topChannel = sortedChannels.first.key;
        switch (topChannel) {
          case 'push':
            defaultChannel = NotificationChannel.push;
            break;
          case 'email':
            defaultChannel = NotificationChannel.email;
            break;
          case 'email_scheduled':
            defaultChannel = NotificationChannel.email;
            break;
        }
      }

      preferredChannels[type] = defaultChannel;
    }

    return preferredChannels;
  }

  // Xác định kênh tối ưu
  NotificationChannel _determineOptimalChannel(
    Map<String, dynamic> userBehavior,
    NotificationType type,
    NotificationPriority priority,
  ) {
    final preferredChannels =
        userBehavior['preferredChannels']
            as Map<NotificationType, NotificationChannel>? ??
        {};

    // Ưu tiên kênh dựa trên loại thông báo và priority
    if (priority == NotificationPriority.urgent) {
      return NotificationChannel.both;
    }

    if (type == NotificationType.eventReminder ||
        type == NotificationType.chatMessage) {
      return NotificationChannel.push;
    }

    if (type == NotificationType.systemAnnouncement) {
      return NotificationChannel.email;
    }

    // Sử dụng preference của user
    return preferredChannels[type] ?? NotificationChannel.both;
  }

  // Xác định thời gian tối ưu
  DateTime? _determineOptimalTime(
    Map<String, dynamic> userBehavior,
    NotificationType type,
  ) {
    final activeHours =
        userBehavior['activeHours'] as Map<String, dynamic>? ?? {};
    final peakHours = activeHours['peakHours'] as List<dynamic>? ?? [9, 14, 19];
    final quietHours =
        activeHours['quietHours'] as List<dynamic>? ??
        [22, 23, 0, 1, 2, 3, 4, 5, 6, 7];

    final now = DateTime.now();
    final currentHour = now.hour;

    // Kiểm tra xem có trong quiet hours không
    if (quietHours.contains(currentHour)) {
      // Lên lịch gửi vào giờ peak tiếp theo
      final nextPeakHour = _findNextPeakHour(currentHour, peakHours);
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        nextPeakHour,
      );

      // Nếu giờ peak đã qua trong ngày, lên lịch cho ngày mai
      if (scheduledTime.isBefore(now)) {
        return scheduledTime.add(const Duration(days: 1));
      }

      return scheduledTime;
    }

    // Nếu không trong quiet hours, gửi ngay
    return null;
  }

  // Tìm giờ peak tiếp theo
  int _findNextPeakHour(int currentHour, List<dynamic> peakHours) {
    final peakHoursInt = peakHours.map((e) => e as int).toList()..sort();

    for (final hour in peakHoursInt) {
      if (hour > currentHour) {
        return hour;
      }
    }

    // Nếu không tìm thấy, trả về giờ peak đầu tiên
    return peakHoursInt.first;
  }

  // Tính tỷ lệ phản hồi
  double _calculateResponseRate(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return 0.0;

    int totalNotifications = history.length;
    int successfulNotifications = history
        .where((n) => n['success'] == true)
        .length;

    return successfulNotifications / totalNotifications;
  }

  // Tính điểm engagement
  double _calculateEngagementScore(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return 0.5;

    final patterns = _analyzeNotificationPatterns(history);
    final typeFrequency = patterns['typeFrequency'] as Map<String, int>? ?? {};
    final channelFrequency =
        patterns['channelFrequency'] as Map<String, int>? ?? {};

    // Tính điểm dựa trên tần suất và đa dạng
    double frequencyScore =
        typeFrequency.values.reduce((a, b) => a + b) / 100.0;
    double diversityScore =
        typeFrequency.length / NotificationType.values.length;
    double channelDiversityScore =
        channelFrequency.length / 3.0; // 3 channels: push, email, both

    return (frequencyScore + diversityScore + channelDiversityScore) / 3.0;
  }

  // Gửi thông báo thông minh hàng loạt
  Future<Map<String, int>> sendSmartBulkNotification({
    required List<String> userIds,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    int successCount = 0;
    int failCount = 0;

    for (final userId in userIds) {
      try {
        final success = await sendSmartNotification(
          userId: userId,
          title: title,
          body: body,
          type: type,
          data: data,
          priority: priority,
        );

        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        print('❌ Error sending smart notification to $userId: $e');
        failCount++;
      }
    }

    print(
      '📊 Smart bulk notification results: $successCount success, $failCount failed',
    );
    return {'success': successCount, 'failed': failCount};
  }

  // Cập nhật user behavior
  Future<void> updateUserBehavior(
    String userId,
    Map<String, dynamic> behaviorData,
  ) async {
    try {
      await _firestore.collection(_userBehaviorCollection).doc(userId).set({
        'userId': userId,
        'behaviorData': behaviorData,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('❌ Error updating user behavior: $e');
    }
  }

  // Lấy thống kê smart routing
  Future<Map<String, dynamic>> getSmartRoutingStats() async {
    try {
      final snapshot = await _firestore
          .collection(_userBehaviorCollection)
          .get();

      int totalUsers = snapshot.docs.length;
      double avgEngagementScore = 0.0;
      Map<String, int> channelPreferences = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final behaviorData =
            data['behaviorData'] as Map<String, dynamic>? ?? {};
        final engagementScore =
            behaviorData['engagementScore'] as double? ?? 0.0;
        avgEngagementScore += engagementScore;

        final preferredChannels =
            behaviorData['preferredChannels'] as Map<String, dynamic>? ?? {};
        for (final channel in preferredChannels.values) {
          final channelName = channel.toString();
          channelPreferences[channelName] =
              (channelPreferences[channelName] ?? 0) + 1;
        }
      }

      if (totalUsers > 0) {
        avgEngagementScore /= totalUsers;
      }

      return {
        'totalUsers': totalUsers,
        'avgEngagementScore': avgEngagementScore.toStringAsFixed(2),
        'channelPreferences': channelPreferences,
      };
    } catch (e) {
      print('❌ Error getting smart routing stats: $e');
      return {};
    }
  }
}
