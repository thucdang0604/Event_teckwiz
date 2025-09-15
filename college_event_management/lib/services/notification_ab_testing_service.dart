import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'unified_notification_service.dart';
import 'notification_service.dart';

enum ABTestStatus { draft, running, paused, completed, cancelled }

enum ABTestVariant { control, variantA, variantB, variantC }

class ABTestConfig {
  final String id;
  final String name;
  final String description;
  final NotificationType notificationType;
  final Map<String, dynamic> controlConfig;
  final Map<String, dynamic> variantAConfig;
  final Map<String, dynamic>? variantBConfig;
  final Map<String, dynamic>? variantCConfig;
  final double trafficSplit; // 0.0 to 1.0
  final DateTime startDate;
  final DateTime endDate;
  final ABTestStatus status;
  final List<String> targetUserIds;
  final String? targetSegment;
  final Map<String, dynamic> metrics;

  ABTestConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.notificationType,
    required this.controlConfig,
    required this.variantAConfig,
    this.variantBConfig,
    this.variantCConfig,
    this.trafficSplit = 0.5,
    required this.startDate,
    required this.endDate,
    this.status = ABTestStatus.draft,
    this.targetUserIds = const [],
    this.targetSegment,
    this.metrics = const {},
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'notificationType': notificationType.name,
      'controlConfig': controlConfig,
      'variantAConfig': variantAConfig,
      'variantBConfig': variantBConfig,
      'variantCConfig': variantCConfig,
      'trafficSplit': trafficSplit,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status.name,
      'targetUserIds': targetUserIds,
      'targetSegment': targetSegment,
      'metrics': metrics,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  factory ABTestConfig.fromFirestore(Map<String, dynamic> data) {
    return ABTestConfig(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      notificationType: NotificationType.values.firstWhere(
        (e) => e.name == data['notificationType'],
        orElse: () => NotificationType.systemAnnouncement,
      ),
      controlConfig: Map<String, dynamic>.from(data['controlConfig'] ?? {}),
      variantAConfig: Map<String, dynamic>.from(data['variantAConfig'] ?? {}),
      variantBConfig: data['variantBConfig'] != null
          ? Map<String, dynamic>.from(data['variantBConfig'])
          : null,
      variantCConfig: data['variantCConfig'] != null
          ? Map<String, dynamic>.from(data['variantCConfig'])
          : null,
      trafficSplit: (data['trafficSplit'] ?? 0.5).toDouble(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      status: ABTestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ABTestStatus.draft,
      ),
      targetUserIds: List<String>.from(data['targetUserIds'] ?? []),
      targetSegment: data['targetSegment'],
      metrics: Map<String, dynamic>.from(data['metrics'] ?? {}),
    );
  }
}

class ABTestResult {
  final String testId;
  final ABTestVariant variant;
  final String userId;
  final bool sent;
  final bool opened;
  final bool clicked;
  final DateTime sentAt;
  final DateTime? openedAt;
  final DateTime? clickedAt;
  final Map<String, dynamic> metadata;

  ABTestResult({
    required this.testId,
    required this.variant,
    required this.userId,
    required this.sent,
    this.opened = false,
    this.clicked = false,
    required this.sentAt,
    this.openedAt,
    this.clickedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toFirestore() {
    return {
      'testId': testId,
      'variant': variant.name,
      'userId': userId,
      'sent': sent,
      'opened': opened,
      'clicked': clicked,
      'sentAt': Timestamp.fromDate(sentAt),
      'openedAt': openedAt != null ? Timestamp.fromDate(openedAt!) : null,
      'clickedAt': clickedAt != null ? Timestamp.fromDate(clickedAt!) : null,
      'metadata': metadata,
    };
  }

  factory ABTestResult.fromFirestore(Map<String, dynamic> data) {
    return ABTestResult(
      testId: data['testId'] ?? '',
      variant: ABTestVariant.values.firstWhere(
        (e) => e.name == data['variant'],
        orElse: () => ABTestVariant.control,
      ),
      userId: data['userId'] ?? '',
      sent: data['sent'] ?? false,
      opened: data['opened'] ?? false,
      clicked: data['clicked'] ?? false,
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      openedAt: data['openedAt'] != null
          ? (data['openedAt'] as Timestamp).toDate()
          : null,
      clickedAt: data['clickedAt'] != null
          ? (data['clickedAt'] as Timestamp).toDate()
          : null,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }
}

class NotificationABTestingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UnifiedNotificationService _unifiedNotificationService =
      UnifiedNotificationService();
  final Random _random = Random();

  static const String _testsCollection = 'ab_tests';
  static const String _resultsCollection = 'ab_test_results';

  // Tạo A/B test mới
  Future<String> createABTest(ABTestConfig config) async {
    try {
      await _firestore
          .collection(_testsCollection)
          .doc(config.id)
          .set(config.toFirestore());

      print('✅ A/B test created: ${config.name}');
      return config.id;
    } catch (e) {
      print('❌ Error creating A/B test: $e');
      throw Exception('Failed to create A/B test: $e');
    }
  }

  // Bắt đầu A/B test
  Future<void> startABTest(String testId) async {
    try {
      await _firestore.collection(_testsCollection).doc(testId).update({
        'status': ABTestStatus.running.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('🚀 A/B test started: $testId');
    } catch (e) {
      print('❌ Error starting A/B test: $e');
      throw Exception('Failed to start A/B test: $e');
    }
  }

  // Dừng A/B test
  Future<void> stopABTest(String testId) async {
    try {
      await _firestore.collection(_testsCollection).doc(testId).update({
        'status': ABTestStatus.completed.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('⏹️ A/B test stopped: $testId');
    } catch (e) {
      print('❌ Error stopping A/B test: $e');
      throw Exception('Failed to stop A/B test: $e');
    }
  }

  // Gửi notification với A/B testing
  Future<Map<String, int>> sendNotificationWithABTest({
    required String testId,
    required List<String> userIds,
    required String baseTitle,
    required String baseBody,
    required NotificationType type,
    Map<String, dynamic>? baseData,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    try {
      final test = await getABTest(testId);
      if (test == null) {
        throw Exception('A/B test not found: $testId');
      }

      if (test.status != ABTestStatus.running) {
        throw Exception('A/B test is not running: ${test.status}');
      }

      Map<String, int> results = {
        'control': 0,
        'variantA': 0,
        'variantB': 0,
        'variantC': 0,
        'total': 0,
      };

      for (final userId in userIds) {
        // Xác định variant cho user
        final variant = _assignUserToVariant(testId, userId, test.trafficSplit);

        // Lấy config cho variant
        final config = _getVariantConfig(test, variant);

        // Tạo notification với config của variant
        final notificationData = _createNotificationFromConfig(
          baseTitle,
          baseBody,
          baseData,
          config,
        );

        // Gửi notification
        final success = await _unifiedNotificationService
            .sendUnifiedNotification(
              userId: userId,
              title: notificationData['title'] as String,
              body: notificationData['body'] as String,
              type: type,
              data: notificationData['data'] as Map<String, dynamic>?,
              priority: priority,
            );

        // Lưu kết quả
        await _saveABTestResult(
          testId: testId,
          variant: variant,
          userId: userId,
          sent: success,
          metadata: {
            'originalTitle': baseTitle,
            'originalBody': baseBody,
            'variantConfig': config,
          },
        );

        // Cập nhật kết quả
        results[variant.name] = (results[variant.name] ?? 0) + 1;
        results['total'] = (results['total'] ?? 0) + 1;
      }

      print('📊 A/B test notification sent: $results');
      return results;
    } catch (e) {
      print('❌ Error sending A/B test notification: $e');
      throw Exception('Failed to send A/B test notification: $e');
    }
  }

  // Xác định variant cho user
  ABTestVariant _assignUserToVariant(
    String testId,
    String userId,
    double trafficSplit,
  ) {
    // Kiểm tra xem user đã được assign chưa
    // Trong thực tế, nên lưu assignment vào database để đảm bảo consistency

    final randomValue = _random.nextDouble();

    if (randomValue < trafficSplit) {
      return ABTestVariant.variantA;
    } else {
      return ABTestVariant.control;
    }
  }

  // Lấy config cho variant
  Map<String, dynamic> _getVariantConfig(
    ABTestConfig test,
    ABTestVariant variant,
  ) {
    switch (variant) {
      case ABTestVariant.control:
        return test.controlConfig;
      case ABTestVariant.variantA:
        return test.variantAConfig;
      case ABTestVariant.variantB:
        return test.variantBConfig ?? test.controlConfig;
      case ABTestVariant.variantC:
        return test.variantCConfig ?? test.controlConfig;
    }
  }

  // Tạo notification từ config
  Map<String, dynamic> _createNotificationFromConfig(
    String baseTitle,
    String baseBody,
    Map<String, dynamic>? baseData,
    Map<String, dynamic> config,
  ) {
    String title = baseTitle;
    String body = baseBody;
    Map<String, dynamic> data = Map<String, dynamic>.from(baseData ?? {});

    // Áp dụng customizations từ config
    if (config['title'] != null) {
      title = _interpolateString(config['title'] as String, data);
    }

    if (config['body'] != null) {
      body = _interpolateString(config['body'] as String, data);
    }

    if (config['data'] != null) {
      data.addAll(Map<String, dynamic>.from(config['data']));
    }

    return {'title': title, 'body': body, 'data': data};
  }

  // Interpolate string với variables
  String _interpolateString(String template, Map<String, dynamic> variables) {
    String result = template;

    variables.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value.toString());
    });

    return result;
  }

  // Lưu kết quả A/B test
  Future<void> _saveABTestResult({
    required String testId,
    required ABTestVariant variant,
    required String userId,
    required bool sent,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final result = ABTestResult(
        testId: testId,
        variant: variant,
        userId: userId,
        sent: sent,
        sentAt: DateTime.now(),
        metadata: metadata,
      );

      await _firestore.collection(_resultsCollection).add(result.toFirestore());
    } catch (e) {
      print('❌ Error saving A/B test result: $e');
    }
  }

  // Cập nhật kết quả (opened, clicked)
  Future<void> updateABTestResult({
    required String testId,
    required String userId,
    bool? opened,
    bool? clicked,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final query = await _firestore
          .collection(_resultsCollection)
          .where('testId', isEqualTo: testId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();

        Map<String, dynamic> updates = {
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        };

        if (opened != null) {
          updates['opened'] = opened;
          if (opened) {
            updates['openedAt'] = Timestamp.fromDate(DateTime.now());
          }
        }

        if (clicked != null) {
          updates['clicked'] = clicked;
          if (clicked) {
            updates['clickedAt'] = Timestamp.fromDate(DateTime.now());
          }
        }

        if (metadata != null) {
          final currentMetadata = Map<String, dynamic>.from(
            data['metadata'] ?? {},
          );
          currentMetadata.addAll(metadata);
          updates['metadata'] = currentMetadata;
        }

        await doc.reference.update(updates);
      }
    } catch (e) {
      print('❌ Error updating A/B test result: $e');
    }
  }

  // Lấy A/B test
  Future<ABTestConfig?> getABTest(String testId) async {
    try {
      final doc = await _firestore
          .collection(_testsCollection)
          .doc(testId)
          .get();

      if (doc.exists) {
        return ABTestConfig.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error getting A/B test: $e');
      return null;
    }
  }

  // Lấy danh sách A/B tests
  Future<List<ABTestConfig>> getABTests({
    ABTestStatus? status,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(_testsCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map(
            (doc) =>
                ABTestConfig.fromFirestore(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('❌ Error getting A/B tests: $e');
      return [];
    }
  }

  // Lấy kết quả A/B test
  Future<Map<String, dynamic>> getABTestResults(String testId) async {
    try {
      final snapshot = await _firestore
          .collection(_resultsCollection)
          .where('testId', isEqualTo: testId)
          .get();

      Map<String, List<ABTestResult>> resultsByVariant = {};

      for (final doc in snapshot.docs) {
        final result = ABTestResult.fromFirestore(doc.data());
        resultsByVariant.putIfAbsent(result.variant.name, () => []).add(result);
      }

      Map<String, dynamic> summary = {};

      resultsByVariant.forEach((variant, results) {
        final totalSent = results.length;
        final totalOpened = results.where((r) => r.opened).length;
        final totalClicked = results.where((r) => r.clicked).length;

        summary[variant] = {
          'totalSent': totalSent,
          'totalOpened': totalOpened,
          'totalClicked': totalClicked,
          'openRate': totalSent > 0
              ? (totalOpened / totalSent * 100).toStringAsFixed(2)
              : '0.00',
          'clickRate': totalSent > 0
              ? (totalClicked / totalSent * 100).toStringAsFixed(2)
              : '0.00',
          'clickThroughRate': totalOpened > 0
              ? (totalClicked / totalOpened * 100).toStringAsFixed(2)
              : '0.00',
        };
      });

      return summary;
    } catch (e) {
      print('❌ Error getting A/B test results: $e');
      return {};
    }
  }

  // Phân tích thống kê A/B test
  Future<Map<String, dynamic>> analyzeABTest(String testId) async {
    try {
      final results = await getABTestResults(testId);

      if (results.isEmpty) {
        return {'error': 'No results found'};
      }

      // So sánh control vs variants
      final controlData = results['control'] as Map<String, dynamic>?;
      final variantAData = results['variantA'] as Map<String, dynamic>?;

      if (controlData == null || variantAData == null) {
        return {'error': 'Insufficient data for analysis'};
      }

      final controlOpenRate = double.parse(controlData['openRate'] as String);
      final variantAOpenRate = double.parse(variantAData['openRate'] as String);

      final controlClickRate = double.parse(controlData['clickRate'] as String);
      final variantAClickRate = double.parse(
        variantAData['clickRate'] as String,
      );

      // Tính statistical significance (simplified)
      final openRateImprovement =
          ((variantAOpenRate - controlOpenRate) / controlOpenRate * 100);
      final clickRateImprovement =
          ((variantAClickRate - controlClickRate) / controlClickRate * 100);

      return {
        'testId': testId,
        'analysis': {
          'openRateImprovement': openRateImprovement.toStringAsFixed(2),
          'clickRateImprovement': clickRateImprovement.toStringAsFixed(2),
          'winner': variantAOpenRate > controlOpenRate ? 'variantA' : 'control',
          'confidence': _calculateConfidence(controlData, variantAData),
        },
        'results': results,
      };
    } catch (e) {
      print('❌ Error analyzing A/B test: $e');
      return {'error': 'Analysis failed: $e'};
    }
  }

  // Tính confidence level (simplified)
  String _calculateConfidence(
    Map<String, dynamic> control,
    Map<String, dynamic> variant,
  ) {
    // Simplified confidence calculation
    // In real implementation, use proper statistical tests
    final controlSample = control['totalSent'] as int;
    final variantSample = variant['totalSent'] as int;

    if (controlSample < 30 || variantSample < 30) {
      return 'Low';
    } else if (controlSample < 100 || variantSample < 100) {
      return 'Medium';
    } else {
      return 'High';
    }
  }
}
