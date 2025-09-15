import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';
import 'email_service.dart';
import 'email_scheduler_service.dart';

enum NotificationChannel { push, email, both, none }

enum NotificationPriority { low, normal, high, urgent }

class NotificationPreferences {
  final String userId;
  final Map<NotificationType, NotificationChannel> channelPreferences;
  final Map<NotificationType, bool> enabledTypes;
  final bool emailEnabled;
  final bool pushEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final List<String> preferredLanguages;

  NotificationPreferences({
    required this.userId,
    required this.channelPreferences,
    required this.enabledTypes,
    this.emailEnabled = true,
    this.pushEnabled = true,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.preferredLanguages = const ['vi'],
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'channelPreferences': channelPreferences.map(
        (key, value) => MapEntry(key.name, value.name),
      ),
      'enabledTypes': enabledTypes.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'emailEnabled': emailEnabled,
      'pushEnabled': pushEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'preferredLanguages': preferredLanguages,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  factory NotificationPreferences.fromFirestore(Map<String, dynamic> data) {
    return NotificationPreferences(
      userId: data['userId'] ?? '',
      channelPreferences:
          (data['channelPreferences'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              NotificationType.values.firstWhere(
                (e) => e.name == key,
                orElse: () => NotificationType.systemAnnouncement,
              ),
              NotificationChannel.values.firstWhere(
                (e) => e.name == value,
                orElse: () => NotificationChannel.both,
              ),
            ),
          ) ??
          _getDefaultChannelPreferences(),
      enabledTypes:
          (data['enabledTypes'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              NotificationType.values.firstWhere(
                (e) => e.name == key,
                orElse: () => NotificationType.systemAnnouncement,
              ),
              value as bool,
            ),
          ) ??
          _getDefaultEnabledTypes(),
      emailEnabled: data['emailEnabled'] ?? true,
      pushEnabled: data['pushEnabled'] ?? true,
      quietHoursStart: data['quietHoursStart'],
      quietHoursEnd: data['quietHoursEnd'],
      preferredLanguages: List<String>.from(
        data['preferredLanguages'] ?? ['vi'],
      ),
    );
  }

  static Map<NotificationType, NotificationChannel>
  _getDefaultChannelPreferences() {
    return {
      NotificationType.eventCreated: NotificationChannel.both,
      NotificationType.eventUpdated: NotificationChannel.both,
      NotificationType.eventCancelled: NotificationChannel.both,
      NotificationType.registrationConfirmed: NotificationChannel.both,
      NotificationType.registrationCancelled: NotificationChannel.both,
      NotificationType.eventReminder: NotificationChannel.push,
      NotificationType.systemAnnouncement: NotificationChannel.both,
      NotificationType.chatMessage: NotificationChannel.push,
    };
  }

  static Map<NotificationType, bool> _getDefaultEnabledTypes() {
    return {for (var type in NotificationType.values) type: true};
  }
}

class UnifiedNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EmailService _emailService = EmailService.instance;
  final EmailSchedulerService _emailScheduler = EmailSchedulerService();

  static const String _preferencesCollection = 'notification_preferences';
  static const String _notificationLogsCollection = 'notification_logs';

  // Gửi thông báo thống nhất
  Future<bool> sendUnifiedNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
    DateTime? scheduledTime,
  }) async {
    try {
      // Lấy preferences của user
      final preferences = await getUserPreferences(userId);

      if (preferences == null) {
        print('❌ No preferences found for user: $userId');
        return false;
      }

      // Kiểm tra xem loại thông báo có được bật không
      if (!(preferences.enabledTypes[type] ?? false)) {
        print('📵 Notification type $type is disabled for user: $userId');
        return true; // Không phải lỗi, chỉ là user đã tắt
      }

      // Kiểm tra quiet hours
      if (_isInQuietHours(preferences)) {
        print('🌙 User is in quiet hours, scheduling for later');
        await _scheduleForLater(userId, title, body, type, data, preferences);
        return true;
      }

      // Lấy channel preference cho loại thông báo này
      final channel =
          preferences.channelPreferences[type] ?? NotificationChannel.both;

      bool success = true;
      List<String> sentChannels = [];

      // Gửi push notification nếu được phép
      if ((channel == NotificationChannel.push ||
              channel == NotificationChannel.both) &&
          preferences.pushEnabled) {
        try {
          await NotificationService.sendNotificationToUser(
            userId: userId,
            title: title,
            body: body,
            type: type,
            data: data,
          );
          sentChannels.add('push');
          print('✅ Push notification sent to user: $userId');
        } catch (e) {
          print('❌ Error sending push notification: $e');
          success = false;
        }
      }

      // Gửi email nếu được phép
      if ((channel == NotificationChannel.email ||
              channel == NotificationChannel.both) &&
          preferences.emailEnabled) {
        try {
          // Lấy email của user
          final userEmail = await _getUserEmail(userId);
          if (userEmail != null) {
            final emailType = _mapNotificationTypeToEmailType(type);
            if (emailType != null) {
              if (scheduledTime != null) {
                await _emailScheduler.scheduleEmail(
                  eventId: data?['eventId'] ?? 'general',
                  userEmail: userEmail,
                  emailType: emailType,
                  data: _prepareEmailData(title, body, data),
                  scheduledTime: scheduledTime,
                );
                sentChannels.add('email_scheduled');
                print('📅 Email scheduled for user: $userId');
              } else {
                final emailSuccess = await _emailService.sendEmail(
                  to: userEmail,
                  type: emailType,
                  data: _prepareEmailData(title, body, data),
                );
                if (emailSuccess) {
                  sentChannels.add('email');
                  print('✅ Email sent to user: $userId');
                } else {
                  success = false;
                }
              }
            }
          }
        } catch (e) {
          print('❌ Error sending email: $e');
          success = false;
        }
      }

      // Log notification
      await _logNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        channels: sentChannels,
        success: success,
        priority: priority,
      );

      return success;
    } catch (e) {
      print('❌ Error sending unified notification: $e');
      return false;
    }
  }

  // Gửi thông báo hàng loạt
  Future<Map<String, int>> sendBulkNotification({
    required List<String> userIds,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
    DateTime? scheduledTime,
  }) async {
    int successCount = 0;
    int failCount = 0;

    for (final userId in userIds) {
      try {
        final success = await sendUnifiedNotification(
          userId: userId,
          title: title,
          body: body,
          type: type,
          data: data,
          priority: priority,
          scheduledTime: scheduledTime,
        );

        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        print('❌ Error sending notification to $userId: $e');
        failCount++;
      }
    }

    print(
      '📊 Bulk notification results: $successCount success, $failCount failed',
    );
    return {'success': successCount, 'failed': failCount};
  }

  // Lưu preferences của user
  Future<void> saveUserPreferences(NotificationPreferences preferences) async {
    try {
      await _firestore
          .collection(_preferencesCollection)
          .doc(preferences.userId)
          .set(preferences.toFirestore());
      print('✅ Preferences saved for user: ${preferences.userId}');
    } catch (e) {
      print('❌ Error saving preferences: $e');
    }
  }

  // Lấy preferences của user
  Future<NotificationPreferences?> getUserPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection(_preferencesCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return NotificationPreferences.fromFirestore(doc.data()!);
      } else {
        // Tạo preferences mặc định
        final defaultPreferences = NotificationPreferences(
          userId: userId,
          channelPreferences:
              NotificationPreferences._getDefaultChannelPreferences(),
          enabledTypes: NotificationPreferences._getDefaultEnabledTypes(),
        );
        await saveUserPreferences(defaultPreferences);
        return defaultPreferences;
      }
    } catch (e) {
      print('❌ Error getting user preferences: $e');
      return null;
    }
  }

  // Lấy email của user
  Future<String?> _getUserEmail(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        return doc.data()?['email'] as String?;
      }
      return null;
    } catch (e) {
      print('❌ Error getting user email: $e');
      return null;
    }
  }

  // Kiểm tra quiet hours
  bool _isInQuietHours(NotificationPreferences preferences) {
    if (preferences.quietHoursStart == null ||
        preferences.quietHoursEnd == null) {
      return false;
    }

    final now = DateTime.now();
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return currentTime.compareTo(preferences.quietHoursStart!) >= 0 &&
        currentTime.compareTo(preferences.quietHoursEnd!) <= 0;
  }

  // Lên lịch gửi sau
  Future<void> _scheduleForLater(
    String userId,
    String title,
    String body,
    NotificationType type,
    Map<String, dynamic>? data,
    NotificationPreferences preferences,
  ) async {
    // Lên lịch gửi sau 1 giờ
    final scheduledTime = DateTime.now().add(const Duration(hours: 1));

    await sendUnifiedNotification(
      userId: userId,
      title: title,
      body: body,
      type: type,
      data: data,
      scheduledTime: scheduledTime,
    );
  }

  // Map NotificationType sang EmailType
  EmailType? _mapNotificationTypeToEmailType(NotificationType type) {
    switch (type) {
      case NotificationType.eventCreated:
        return EmailType.eventRegistration;
      case NotificationType.eventUpdated:
        return EmailType.eventUpdate;
      case NotificationType.eventCancelled:
        return EmailType.eventCancellation;
      case NotificationType.registrationConfirmed:
        return EmailType.registrationApproval;
      case NotificationType.registrationCancelled:
        return EmailType.registrationRejection;
      case NotificationType.eventReminder:
        return EmailType.eventReminder;
      case NotificationType.systemAnnouncement:
        return EmailType.bulkAnnouncement;
      case NotificationType.chatMessage:
        return null; // Không gửi email cho chat
      case NotificationType.registrationRejected:
        return EmailType.registrationRejection;
      case NotificationType.certificateIssued:
        return EmailType.certificateIssued;
    }
  }

  // Chuẩn bị data cho email
  Map<String, dynamic> _prepareEmailData(
    String title,
    String body,
    Map<String, dynamic>? data,
  ) {
    return {'title': title, 'message': body, if (data != null) ...data};
  }

  // Log notification
  Future<void> _logNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    required List<String> channels,
    required bool success,
    required NotificationPriority priority,
  }) async {
    try {
      await _firestore.collection(_notificationLogsCollection).add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'channels': channels,
        'success': success,
        'priority': priority.name,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('❌ Error logging notification: $e');
    }
  }

  // Lấy thống kê thông báo
  Future<Map<String, dynamic>> getNotificationStats({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection(_notificationLogsCollection);

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      if (startDate != null) {
        query = query.where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      final snapshot = await query.get();
      int totalSent = snapshot.docs.length;
      int successCount = snapshot.docs
          .where(
            (doc) => (doc.data() as Map<String, dynamic>?)?['success'] == true,
          )
          .length;
      int failCount = totalSent - successCount;
      Map<String, int> typeStats = {};
      Map<String, int> channelStats = {};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};

        // Thống kê theo loại
        final type = data['type'] as String;
        typeStats[type] = (typeStats[type] ?? 0) + 1;

        // Thống kê theo channel
        final channels = List<String>.from(data['channels'] ?? []);
        for (final channel in channels) {
          channelStats[channel] = (channelStats[channel] ?? 0) + 1;
        }
      }

      return {
        'totalSent': totalSent,
        'successCount': successCount,
        'failCount': failCount,
        'successRate': totalSent > 0
            ? (successCount / totalSent * 100).toStringAsFixed(2)
            : '0.00',
        'typeStats': typeStats,
        'channelStats': channelStats,
      };
    } catch (e) {
      print('❌ Error getting notification stats: $e');
      return {};
    }
  }

  // Lấy lịch sử thông báo của user
  Future<List<Map<String, dynamic>>> getUserNotificationHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_notificationLogsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      print('❌ Error getting user notification history: $e');
      return [];
    }
  }
}
