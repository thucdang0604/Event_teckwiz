import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'unified_notification_service.dart';
import 'notification_service.dart';

class ScheduledPushNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UnifiedNotificationService _unifiedNotificationService =
      UnifiedNotificationService();

  static const String _scheduledPushCollection = 'scheduled_push_notifications';
  static const String _pushLogsCollection = 'push_notification_logs';

  Timer? _schedulerTimer;
  static const Duration _checkInterval = Duration(minutes: 1);

  // Khởi tạo scheduler
  void initialize() {
    _startScheduler();
    print('📅 Scheduled push notification service initialized');
  }

  // Bắt đầu scheduler
  void _startScheduler() {
    _schedulerTimer?.cancel();
    _schedulerTimer = Timer.periodic(_checkInterval, (timer) {
      _processScheduledNotifications();
    });
  }

  // Dừng scheduler
  void stop() {
    _schedulerTimer?.cancel();
    print('⏹️ Scheduled push notification service stopped');
  }

  // Lên lịch push notification
  Future<String> schedulePushNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    required DateTime scheduledTime,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
    String? timezone,
    bool repeat = false,
    Duration? repeatInterval,
    DateTime? repeatUntil,
  }) async {
    try {
      final docRef = await _firestore.collection(_scheduledPushCollection).add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'scheduledTime': Timestamp.fromDate(scheduledTime),
        'data': data ?? {},
        'priority': priority.name,
        'timezone': timezone ?? 'UTC',
        'repeat': repeat,
        'repeatInterval': repeatInterval?.inSeconds,
        'repeatUntil': repeatUntil != null
            ? Timestamp.fromDate(repeatUntil)
            : null,
        'status': 'scheduled',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print(
        '📅 Push notification scheduled: ${docRef.id} for ${scheduledTime.toIso8601String()}',
      );
      return docRef.id;
    } catch (e) {
      print('❌ Error scheduling push notification: $e');
      throw Exception('Failed to schedule push notification: $e');
    }
  }

  // Lên lịch push notification cho sự kiện
  Future<String> scheduleEventReminder({
    required String userId,
    required String eventId,
    required String eventTitle,
    required DateTime eventStartTime,
    required Duration reminderBefore,
    String? customMessage,
  }) async {
    try {
      final scheduledTime = eventStartTime.subtract(reminderBefore);

      // Kiểm tra xem thời gian lên lịch có trong tương lai không
      if (scheduledTime.isBefore(DateTime.now())) {
        throw Exception('Scheduled time is in the past');
      }

      String title = 'Nhắc nhở sự kiện';
      String body =
          customMessage ??
          'Sự kiện "$eventTitle" sẽ diễn ra trong ${_formatDuration(reminderBefore)}';

      return await schedulePushNotification(
        userId: userId,
        title: title,
        body: body,
        type: NotificationType.eventReminder,
        scheduledTime: scheduledTime,
        data: {
          'eventId': eventId,
          'eventTitle': eventTitle,
          'eventStartTime': eventStartTime.toIso8601String(),
          'reminderType': _getReminderType(reminderBefore),
        },
        priority: NotificationPriority.normal,
      );
    } catch (e) {
      print('❌ Error scheduling event reminder: $e');
      throw Exception('Failed to schedule event reminder: $e');
    }
  }

  // Lên lịch push notification định kỳ
  Future<String> scheduleRecurringNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    required DateTime startTime,
    required Duration interval,
    DateTime? endTime,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    try {
      return await schedulePushNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        scheduledTime: startTime,
        data: data,
        priority: priority,
        repeat: true,
        repeatInterval: interval,
        repeatUntil: endTime,
      );
    } catch (e) {
      print('❌ Error scheduling recurring notification: $e');
      throw Exception('Failed to schedule recurring notification: $e');
    }
  }

  // Lên lịch push notification cho nhiều users
  Future<List<String>> scheduleBulkPushNotification({
    required List<String> userIds,
    required String title,
    required String body,
    required NotificationType type,
    required DateTime scheduledTime,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
    int batchSize = 100,
  }) async {
    try {
      List<String> scheduledIds = [];

      // Chia thành batches để tránh timeout
      for (int i = 0; i < userIds.length; i += batchSize) {
        final batch = userIds.skip(i).take(batchSize).toList();

        final batchRef = _firestore.batch();
        final scheduledIdsBatch = <String>[];

        for (final userId in batch) {
          final docRef = _firestore.collection(_scheduledPushCollection).doc();
          scheduledIdsBatch.add(docRef.id);

          batchRef.set(docRef, {
            'userId': userId,
            'title': title,
            'body': body,
            'type': type.name,
            'scheduledTime': Timestamp.fromDate(scheduledTime),
            'data': data ?? {},
            'priority': priority.name,
            'status': 'scheduled',
            'createdAt': Timestamp.fromDate(DateTime.now()),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        }

        await batchRef.commit();
        scheduledIds.addAll(scheduledIdsBatch);
      }

      print(
        '📅 Bulk push notification scheduled: ${scheduledIds.length} notifications',
      );
      return scheduledIds;
    } catch (e) {
      print('❌ Error scheduling bulk push notification: $e');
      throw Exception('Failed to schedule bulk push notification: $e');
    }
  }

  // Xử lý scheduled notifications
  Future<void> _processScheduledNotifications() async {
    try {
      final now = DateTime.now();
      final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

      final snapshot = await _firestore
          .collection(_scheduledPushCollection)
          .where('status', isEqualTo: 'scheduled')
          .where('scheduledTime', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where(
            'scheduledTime',
            isGreaterThan: Timestamp.fromDate(oneMinuteAgo),
          )
          .get();

      print('📅 Processing ${snapshot.docs.length} scheduled notifications');

      for (final doc in snapshot.docs) {
        await _processScheduledNotification(doc);
      }
    } catch (e) {
      print('❌ Error processing scheduled notifications: $e');
    }
  }

  // Xử lý một scheduled notification
  Future<void> _processScheduledNotification(QueryDocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final notificationId = doc.id;

      // Cập nhật status thành processing
      await doc.reference.update({
        'status': 'processing',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Gửi notification
      final success = await _unifiedNotificationService.sendUnifiedNotification(
        userId: data['userId'] as String,
        title: data['title'] as String,
        body: data['body'] as String,
        type: NotificationType.values.firstWhere(
          (e) => e.name == data['type'],
          orElse: () => NotificationType.systemAnnouncement,
        ),
        data: Map<String, dynamic>.from(data['data'] ?? {}),
        priority: NotificationPriority.values.firstWhere(
          (e) => e.name == data['priority'],
          orElse: () => NotificationPriority.normal,
        ),
      );

      // Lưu log
      await _logPushNotification(
        notificationId: notificationId,
        userId: data['userId'] as String,
        success: success,
        scheduledTime: (data['scheduledTime'] as Timestamp).toDate(),
        sentTime: DateTime.now(),
      );

      // Xử lý repeat
      if (data['repeat'] == true) {
        await _handleRepeatNotification(doc, data);
      } else {
        // Đánh dấu là completed
        await doc.reference.update({
          'status': success ? 'completed' : 'failed',
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      print('✅ Scheduled notification processed: $notificationId');
    } catch (e) {
      print('❌ Error processing scheduled notification: $e');
      await doc.reference.update({
        'status': 'failed',
        'error': e.toString(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
  }

  // Xử lý repeat notification
  Future<void> _handleRepeatNotification(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) async {
    try {
      final repeatInterval = data['repeatInterval'] as int?;
      final repeatUntil = data['repeatUntil'] as Timestamp?;

      if (repeatInterval == null) return;

      final nextScheduledTime = DateTime.now().add(
        Duration(seconds: repeatInterval),
      );

      // Kiểm tra xem có cần dừng repeat không
      if (repeatUntil != null &&
          nextScheduledTime.isAfter(repeatUntil.toDate())) {
        await doc.reference.update({
          'status': 'completed',
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
        return;
      }

      // Cập nhật thời gian lên lịch tiếp theo
      await doc.reference.update({
        'scheduledTime': Timestamp.fromDate(nextScheduledTime),
        'status': 'scheduled',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print(
        '🔄 Repeat notification scheduled for: ${nextScheduledTime.toIso8601String()}',
      );
    } catch (e) {
      print('❌ Error handling repeat notification: $e');
    }
  }

  // Lưu log push notification
  Future<void> _logPushNotification({
    required String notificationId,
    required String userId,
    required bool success,
    required DateTime scheduledTime,
    required DateTime sentTime,
  }) async {
    try {
      await _firestore.collection(_pushLogsCollection).add({
        'notificationId': notificationId,
        'userId': userId,
        'success': success,
        'scheduledTime': Timestamp.fromDate(scheduledTime),
        'sentTime': Timestamp.fromDate(sentTime),
        'delay': sentTime.difference(scheduledTime).inSeconds,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('❌ Error logging push notification: $e');
    }
  }

  // Hủy scheduled notification
  Future<void> cancelScheduledNotification(String notificationId) async {
    try {
      await _firestore
          .collection(_scheduledPushCollection)
          .doc(notificationId)
          .update({
            'status': 'cancelled',
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      print('❌ Scheduled notification cancelled: $notificationId');
    } catch (e) {
      print('❌ Error cancelling scheduled notification: $e');
      throw Exception('Failed to cancel scheduled notification: $e');
    }
  }

  // Lấy scheduled notifications của user
  Future<List<Map<String, dynamic>>> getUserScheduledNotifications(
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_scheduledPushCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('scheduledTime', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      print('❌ Error getting user scheduled notifications: $e');
      return [];
    }
  }

  // Lấy scheduled notifications theo status
  Future<List<Map<String, dynamic>>> getScheduledNotificationsByStatus(
    String status,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_scheduledPushCollection)
          .where('status', isEqualTo: status)
          .orderBy('scheduledTime', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      print('❌ Error getting scheduled notifications by status: $e');
      return [];
    }
  }

  // Lấy push notification statistics
  Future<Map<String, dynamic>> getPushNotificationStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      Query query = _firestore
          .collection(_pushLogsCollection)
          .where('sentTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('sentTime', isLessThanOrEqualTo: Timestamp.fromDate(end));

      final snapshot = await query.get();

      int totalSent = snapshot.docs.length;
      int successful = snapshot.docs
          .where(
            (doc) => (doc.data() as Map<String, dynamic>)['success'] == true,
          )
          .length;
      int failed = totalSent - successful;

      // Tính average delay
      double avgDelay = 0.0;
      if (totalSent > 0) {
        final totalDelay = snapshot.docs
            .map((doc) => (doc.data() as Map<String, dynamic>)['delay'] as int)
            .reduce((a, b) => a + b);
        avgDelay = totalDelay / totalSent;
      }

      return {
        'totalSent': totalSent,
        'successful': successful,
        'failed': failed,
        'successRate': totalSent > 0
            ? (successful / totalSent * 100).toStringAsFixed(2)
            : '0.00',
        'averageDelay': avgDelay.toStringAsFixed(2),
        'period': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      };
    } catch (e) {
      print('❌ Error getting push notification stats: $e');
      return {};
    }
  }

  // Helper methods
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} ngày';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} giờ';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} phút';
    } else {
      return '${duration.inSeconds} giây';
    }
  }

  String _getReminderType(Duration duration) {
    if (duration.inDays >= 1) {
      return '${duration.inDays}d';
    } else if (duration.inHours >= 1) {
      return '${duration.inHours}h';
    } else if (duration.inMinutes >= 1) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  // Cleanup old logs
  Future<void> cleanupOldLogs({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final snapshot = await _firestore
          .collection(_pushLogsCollection)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print(
        '🗑️ Cleaned up ${snapshot.docs.length} old push notification logs',
      );
    } catch (e) {
      print('❌ Error cleaning up old logs: $e');
    }
  }
}
