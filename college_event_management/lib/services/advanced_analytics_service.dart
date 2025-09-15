import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'unified_notification_service.dart';
import 'notification_service.dart';

class AdvancedAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UnifiedNotificationService _unifiedNotificationService =
      UnifiedNotificationService();

  static const String _analyticsCollection = 'advanced_analytics';
  static const String _userEngagementCollection = 'user_engagement';

  // Lưu analytics data
  Future<void> trackNotificationEvent({
    required String userId,
    required String eventType,
    required String notificationId,
    Map<String, dynamic>? properties,
  }) async {
    try {
      await _firestore.collection(_analyticsCollection).add({
        'userId': userId,
        'eventType': eventType,
        'notificationId': notificationId,
        'properties': properties ?? {},
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'date': DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD
        'hour': DateTime.now().hour,
        'dayOfWeek': DateTime.now().weekday,
      });
    } catch (e) {
      print('❌ Error tracking notification event: $e');
    }
  }

  // Lưu user engagement data
  Future<void> trackUserEngagement({
    required String userId,
    required String action,
    required String notificationId,
    Map<String, dynamic>? context,
  }) async {
    try {
      await _firestore.collection(_userEngagementCollection).add({
        'userId': userId,
        'action':
            action, // 'sent', 'delivered', 'opened', 'clicked', 'dismissed'
        'notificationId': notificationId,
        'context': context ?? {},
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'date': DateTime.now().toIso8601String().split('T')[0],
      });
    } catch (e) {
      print('❌ Error tracking user engagement: $e');
    }
  }

  // Lấy comprehensive analytics
  Future<Map<String, dynamic>> getComprehensiveAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    NotificationType? notificationType,
  }) async {
    try {
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      // Lấy basic stats
      final basicStats = await _getBasicStats(
        start,
        end,
        userId,
        notificationType,
      );

      // Lấy engagement metrics
      final engagementMetrics = await _getEngagementMetrics(
        start,
        end,
        userId,
        notificationType,
      );

      // Lấy funnel analysis
      final funnelAnalysis = await _getFunnelAnalysis(
        start,
        end,
        userId,
        notificationType,
      );

      // Lấy cohort analysis
      final cohortAnalysis = await _getCohortAnalysis(start, end);

      // Lấy retention analysis
      final retentionAnalysis = await _getRetentionAnalysis(start, end);

      // Lấy time-based analysis
      final timeAnalysis = await _getTimeBasedAnalysis(
        start,
        end,
        userId,
        notificationType,
      );

      // Lấy channel performance
      final channelPerformance = await _getChannelPerformance(
        start,
        end,
        userId,
        notificationType,
      );

      // Lấy user segmentation
      final userSegmentation = await _getUserSegmentation(start, end);

      return {
        'period': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
        'basicStats': basicStats,
        'engagementMetrics': engagementMetrics,
        'funnelAnalysis': funnelAnalysis,
        'cohortAnalysis': cohortAnalysis,
        'retentionAnalysis': retentionAnalysis,
        'timeAnalysis': timeAnalysis,
        'channelPerformance': channelPerformance,
        'userSegmentation': userSegmentation,
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error getting comprehensive analytics: $e');
      return {};
    }
  }

  // Basic stats
  Future<Map<String, dynamic>> _getBasicStats(
    DateTime start,
    DateTime end,
    String? userId,
    NotificationType? notificationType,
  ) async {
    try {
      Query query = _firestore.collection(_analyticsCollection);

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      query = query
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end));

      final snapshot = await query.get();

      int totalEvents = snapshot.docs.length;
      int sentEvents = snapshot.docs
          .where(
            (doc) =>
                (doc.data() as Map<String, dynamic>)['eventType'] == 'sent',
          )
          .length;
      int deliveredEvents = snapshot.docs
          .where(
            (doc) =>
                (doc.data() as Map<String, dynamic>)['eventType'] ==
                'delivered',
          )
          .length;
      int openedEvents = snapshot.docs
          .where(
            (doc) =>
                (doc.data() as Map<String, dynamic>)['eventType'] == 'opened',
          )
          .length;
      int clickedEvents = snapshot.docs
          .where(
            (doc) =>
                (doc.data() as Map<String, dynamic>)['eventType'] == 'clicked',
          )
          .length;

      return {
        'totalEvents': totalEvents,
        'sent': sentEvents,
        'delivered': deliveredEvents,
        'opened': openedEvents,
        'clicked': clickedEvents,
        'deliveryRate': sentEvents > 0
            ? (deliveredEvents / sentEvents * 100).toStringAsFixed(2)
            : '0.00',
        'openRate': deliveredEvents > 0
            ? (openedEvents / deliveredEvents * 100).toStringAsFixed(2)
            : '0.00',
        'clickRate': deliveredEvents > 0
            ? (clickedEvents / deliveredEvents * 100).toStringAsFixed(2)
            : '0.00',
        'clickThroughRate': openedEvents > 0
            ? (clickedEvents / openedEvents * 100).toStringAsFixed(2)
            : '0.00',
      };
    } catch (e) {
      print('❌ Error getting basic stats: $e');
      return {};
    }
  }

  // Engagement metrics
  Future<Map<String, dynamic>> _getEngagementMetrics(
    DateTime start,
    DateTime end,
    String? userId,
    NotificationType? notificationType,
  ) async {
    try {
      Query query = _firestore.collection(_userEngagementCollection);

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      query = query
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end));

      final snapshot = await query.get();

      Map<String, int> actionCounts = {};
      Map<String, List<int>> timeToAction = {};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final action = data['action'] as String;
        final timestamp = (data['timestamp'] as Timestamp).toDate();

        actionCounts[action] = (actionCounts[action] ?? 0) + 1;

        // Tính thời gian từ sent đến action
        if (action != 'sent') {
          // Tìm sent event gần nhất
          final sentTime = await _findSentTime(
            data['notificationId'] as String,
            userId,
          );
          if (sentTime != null) {
            final timeDiff = timestamp.difference(sentTime).inMinutes;
            timeToAction.putIfAbsent(action, () => []).add(timeDiff);
          }
        }
      }

      // Tính average time to action
      Map<String, double> avgTimeToAction = {};
      timeToAction.forEach((action, times) {
        if (times.isNotEmpty) {
          avgTimeToAction[action] =
              times.reduce((a, b) => a + b) / times.length;
        }
      });

      return {
        'actionCounts': actionCounts,
        'avgTimeToAction': avgTimeToAction,
        'totalEngagements': actionCounts.values.reduce((a, b) => a + b),
      };
    } catch (e) {
      print('❌ Error getting engagement metrics: $e');
      return {};
    }
  }

  // Funnel analysis
  Future<Map<String, dynamic>> _getFunnelAnalysis(
    DateTime start,
    DateTime end,
    String? userId,
    NotificationType? notificationType,
  ) async {
    try {
      // Lấy tất cả notifications trong khoảng thời gian
      final notifications = await _getNotificationsInPeriod(
        start,
        end,
        userId,
        notificationType,
      );

      Map<String, int> funnel = {
        'sent': 0,
        'delivered': 0,
        'opened': 0,
        'clicked': 0,
      };

      for (final notificationId in notifications) {
        final events = await _getNotificationEvents(notificationId);

        if (events.contains('sent')) funnel['sent'] = (funnel['sent'] ?? 0) + 1;
        if (events.contains('delivered'))
          funnel['delivered'] = (funnel['delivered'] ?? 0) + 1;
        if (events.contains('opened'))
          funnel['opened'] = (funnel['opened'] ?? 0) + 1;
        if (events.contains('clicked'))
          funnel['clicked'] = (funnel['clicked'] ?? 0) + 1;
      }

      // Tính conversion rates
      Map<String, double> conversionRates = {};
      final sent = funnel['sent'] ?? 0;
      final delivered = funnel['delivered'] ?? 0;
      final opened = funnel['opened'] ?? 0;
      final clicked = funnel['clicked'] ?? 0;

      conversionRates['deliveryRate'] = sent > 0
          ? (delivered / sent * 100)
          : 0.0;
      conversionRates['openRate'] = delivered > 0
          ? (opened / delivered * 100)
          : 0.0;
      conversionRates['clickRate'] = delivered > 0
          ? (clicked / delivered * 100)
          : 0.0;
      conversionRates['clickThroughRate'] = opened > 0
          ? (clicked / opened * 100)
          : 0.0;

      return {'funnel': funnel, 'conversionRates': conversionRates};
    } catch (e) {
      print('❌ Error getting funnel analysis: $e');
      return {};
    }
  }

  // Cohort analysis
  Future<Map<String, dynamic>> _getCohortAnalysis(
    DateTime start,
    DateTime end,
  ) async {
    try {
      // Lấy users theo tháng đăng ký
      final cohorts = <String, Map<String, dynamic>>{};

      for (int i = 0; i < 12; i++) {
        final cohortDate = DateTime(start.year, start.month - i, 1);
        final cohortKey =
            '${cohortDate.year}-${cohortDate.month.toString().padLeft(2, '0')}';

        // Lấy users trong cohort này
        final users = await _getUsersInCohort(cohortDate);

        // Tính retention cho từng tháng
        Map<String, double> retention = {};
        for (int j = 0; j < 12; j++) {
          final retentionDate = cohortDate.add(Duration(days: 30 * j));
          final activeUsers = await _getActiveUsersInPeriod(
            users,
            retentionDate,
            retentionDate.add(const Duration(days: 30)),
          );

          retention['month${j + 1}'] = users.isNotEmpty
              ? (activeUsers / users.length * 100)
              : 0.0;
        }

        cohorts[cohortKey] = {'size': users.length, 'retention': retention};
      }

      return {
        'cohorts': cohorts,
        'averageRetention': _calculateAverageRetention(cohorts),
      };
    } catch (e) {
      print('❌ Error getting cohort analysis: $e');
      return {};
    }
  }

  // Retention analysis
  Future<Map<String, dynamic>> _getRetentionAnalysis(
    DateTime start,
    DateTime end,
  ) async {
    try {
      // Lấy tất cả users
      final allUsers = await _getAllUsers();

      Map<String, double> retentionRates = {};

      // Tính retention cho các khoảng thời gian khác nhau
      final periods = [1, 3, 7, 14, 30]; // days

      for (final period in periods) {
        final periodStart = end.subtract(Duration(days: period));
        final activeUsers = await _getActiveUsersInPeriod(
          allUsers,
          periodStart,
          end,
        );

        retentionRates['${period}days'] = allUsers.isNotEmpty
            ? (activeUsers / allUsers.length * 100)
            : 0.0;
      }

      return {'retentionRates': retentionRates, 'totalUsers': allUsers.length};
    } catch (e) {
      print('❌ Error getting retention analysis: $e');
      return {};
    }
  }

  // Time-based analysis
  Future<Map<String, dynamic>> _getTimeBasedAnalysis(
    DateTime start,
    DateTime end,
    String? userId,
    NotificationType? notificationType,
  ) async {
    try {
      Query query = _firestore.collection(_analyticsCollection);

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      query = query
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end));

      final snapshot = await query.get();

      Map<int, int> hourlyDistribution = {};
      Map<int, int> dailyDistribution = {};
      Map<String, int> weeklyDistribution = {};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final hour = data['hour'] as int;
        final dayOfWeek = data['dayOfWeek'] as int;

        hourlyDistribution[hour] = (hourlyDistribution[hour] ?? 0) + 1;
        dailyDistribution[dayOfWeek] = (dailyDistribution[dayOfWeek] ?? 0) + 1;

        final dayName = _getDayName(dayOfWeek);
        weeklyDistribution[dayName] = (weeklyDistribution[dayName] ?? 0) + 1;
      }

      return {
        'hourlyDistribution': hourlyDistribution,
        'dailyDistribution': dailyDistribution,
        'weeklyDistribution': weeklyDistribution,
        'peakHour': _findPeakHour(hourlyDistribution),
        'peakDay': _findPeakDay(dailyDistribution),
      };
    } catch (e) {
      print('❌ Error getting time-based analysis: $e');
      return {};
    }
  }

  // Channel performance
  Future<Map<String, dynamic>> _getChannelPerformance(
    DateTime start,
    DateTime end,
    String? userId,
    NotificationType? notificationType,
  ) async {
    try {
      // Lấy notification logs từ unified service
      final stats = await _unifiedNotificationService.getNotificationStats(
        userId: userId,
        startDate: start,
        endDate: end,
      );

      final channelStats = stats['channelStats'] as Map<String, int>? ?? {};
      final typeStats = stats['typeStats'] as Map<String, int>? ?? {};

      // Tính performance metrics cho từng channel
      Map<String, Map<String, dynamic>> channelPerformance = {};

      for (final channel in ['push', 'email', 'email_scheduled']) {
        final count = channelStats[channel] ?? 0;
        final total = channelStats.values.reduce((a, b) => a + b);

        channelPerformance[channel] = {
          'count': count,
          'percentage': total > 0
              ? (count / total * 100).toStringAsFixed(2)
              : '0.00',
          'efficiency': _calculateChannelEfficiency(channel, start, end),
        };
      }

      return {
        'channelStats': channelStats,
        'typeStats': typeStats,
        'channelPerformance': channelPerformance,
        'totalNotifications': stats['totalSent'] ?? 0,
        'successRate': stats['successRate'] ?? '0.00',
      };
    } catch (e) {
      print('❌ Error getting channel performance: $e');
      return {};
    }
  }

  // User segmentation
  Future<Map<String, dynamic>> _getUserSegmentation(
    DateTime start,
    DateTime end,
  ) async {
    try {
      // Lấy tất cả users
      final allUsers = await _getAllUsers();

      Map<String, List<String>> segments = {
        'highEngagement': [],
        'mediumEngagement': [],
        'lowEngagement': [],
        'inactive': [],
      };

      for (final userId in allUsers) {
        final engagementScore = await _calculateUserEngagementScore(
          userId,
          start,
          end,
        );

        if (engagementScore >= 0.8) {
          segments['highEngagement']!.add(userId);
        } else if (engagementScore >= 0.5) {
          segments['mediumEngagement']!.add(userId);
        } else if (engagementScore >= 0.2) {
          segments['lowEngagement']!.add(userId);
        } else {
          segments['inactive']!.add(userId);
        }
      }

      return {
        'segments': segments,
        'segmentSizes': segments.map(
          (key, value) => MapEntry(key, value.length),
        ),
        'totalUsers': allUsers.length,
      };
    } catch (e) {
      print('❌ Error getting user segmentation: $e');
      return {};
    }
  }

  // Helper methods
  Future<DateTime?> _findSentTime(String notificationId, String? userId) async {
    try {
      Query query = _firestore
          .collection(_analyticsCollection)
          .where('notificationId', isEqualTo: notificationId)
          .where('eventType', isEqualTo: 'sent');

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      final snapshot = await query.limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        return ((snapshot.docs.first.data()
                    as Map<String, dynamic>)['timestamp']
                as Timestamp)
            .toDate();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> _getNotificationsInPeriod(
    DateTime start,
    DateTime end,
    String? userId,
    NotificationType? notificationType,
  ) async {
    // Implementation to get notification IDs in period
    return [];
  }

  Future<List<String>> _getNotificationEvents(String notificationId) async {
    // Implementation to get events for a notification
    return [];
  }

  Future<List<String>> _getUsersInCohort(DateTime cohortDate) async {
    // Implementation to get users in a cohort
    return [];
  }

  Future<int> _getActiveUsersInPeriod(
    List<String> users,
    DateTime start,
    DateTime end,
  ) async {
    // Implementation to get active users in period
    return 0;
  }

  Future<List<String>> _getAllUsers() async {
    // Implementation to get all users
    return [];
  }

  double _calculateAverageRetention(Map<String, Map<String, dynamic>> cohorts) {
    // Implementation to calculate average retention
    return 0.0;
  }

  String _getDayName(int dayOfWeek) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[dayOfWeek - 1];
  }

  int _findPeakHour(Map<int, int> hourlyDistribution) {
    if (hourlyDistribution.isEmpty) return 0;
    return hourlyDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  int _findPeakDay(Map<int, int> dailyDistribution) {
    if (dailyDistribution.isEmpty) return 1;
    return dailyDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  double _calculateChannelEfficiency(
    String channel,
    DateTime start,
    DateTime end,
  ) {
    // Implementation to calculate channel efficiency
    return 0.0;
  }

  Future<double> _calculateUserEngagementScore(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    // Implementation to calculate user engagement score
    return 0.0;
  }
}
