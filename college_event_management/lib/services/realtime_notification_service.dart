import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'unified_notification_service.dart';
import 'notification_service.dart';

class RealtimeNotificationService {
  static RealtimeNotificationService? _instance;
  static RealtimeNotificationService get instance =>
      _instance ??= RealtimeNotificationService._();

  RealtimeNotificationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UnifiedNotificationService _unifiedNotificationService =
      UnifiedNotificationService();

  StreamController<Map<String, dynamic>>? _notificationController;
  StreamController<Map<String, dynamic>>? _analyticsController;

  bool _isConnected = false;
  String? _currentUserId;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  static const String _notificationsCollection = 'realtime_notifications';
  static const int _heartbeatInterval = 30; // seconds
  static const int _reconnectInterval = 5; // seconds

  // Streams
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController?.stream ?? const Stream.empty();
  Stream<Map<String, dynamic>> get analyticsStream =>
      _analyticsController?.stream ?? const Stream.empty();

  // Kết nối WebSocket
  Future<void> connect(String userId) async {
    if (_isConnected && _currentUserId == userId) return;

    _currentUserId = userId;
    await _disconnect();

    try {
      // Khởi tạo controllers
      _notificationController =
          StreamController<Map<String, dynamic>>.broadcast();
      _analyticsController = StreamController<Map<String, dynamic>>.broadcast();

      // Simulate WebSocket connection (in real implementation, use actual WebSocket)
      // _channel = IOWebSocketChannel.connect('ws://localhost:8080/ws');

      _isConnected = true;
      print('🔌 Connected to realtime notification service');

      // Gửi authentication message
      await _sendMessage({
        'type': 'auth',
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Bắt đầu heartbeat
      _startHeartbeat();
    } catch (e) {
      print('❌ Error connecting to realtime service: $e');
      _scheduleReconnect();
    }
  }

  // Ngắt kết nối
  Future<void> disconnect() async {
    _currentUserId = null;
    await _disconnect();
  }

  Future<void> _disconnect() async {
    _isConnected = false;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();

    // await _channel?.sink.close();
    // _channel = null;

    await _notificationController?.close();
    await _analyticsController?.close();
    _notificationController = null;
    _analyticsController = null;

    print('🔌 Disconnected from realtime notification service');
  }


  // Lên lịch kết nối lại
  void _scheduleReconnect() {
    if (_currentUserId == null) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _reconnectInterval), () {
      if (_currentUserId != null) {
        connect(_currentUserId!);
      }
    });
  }

  // Bắt đầu heartbeat
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      Duration(seconds: _heartbeatInterval),
      (timer) => _sendHeartbeat(),
    );
  }

  // Gửi heartbeat
  Future<void> _sendHeartbeat() async {
    if (!_isConnected) return;

    try {
      await _sendMessage({
        'type': 'ping',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Error sending heartbeat: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  // Gửi message
  Future<void> _sendMessage(Map<String, dynamic> message) async {
    // if (_channel == null) return;

    try {
      // _channel!.sink.add(jsonEncode(message));
      print('📡 Simulated message sent: ${jsonEncode(message)}');
    } catch (e) {
      print('❌ Error sending message: $e');
    }
  }


  // Gửi notification real-time
  Future<void> sendRealtimeNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    try {
      // Gửi qua unified notification service
      await _unifiedNotificationService.sendUnifiedNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
        priority: priority,
      );

      // Gửi real-time update
      await _sendMessage({
        'type': 'notification',
        'action': 'new',
        'userId': userId,
        'title': title,
        'body': body,
        'notificationType': type.name,
        'priority': priority.name,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });

      print('📡 Realtime notification sent to: $userId');
    } catch (e) {
      print('❌ Error sending realtime notification: $e');
    }
  }

  // Gửi analytics update real-time
  Future<void> sendAnalyticsUpdate({
    required String userId,
    required Map<String, dynamic> analyticsData,
  }) async {
    try {
      await _sendMessage({
        'type': 'analytics',
        'userId': userId,
        'data': analyticsData,
        'timestamp': DateTime.now().toIso8601String(),
      });

      print('📊 Analytics update sent for: $userId');
    } catch (e) {
      print('❌ Error sending analytics update: $e');
    }
  }

  // Lấy cached notifications
  Future<List<Map<String, dynamic>>> getCachedNotifications({
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('cachedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, ...data['data'] as Map<String, dynamic>};
      }).toList();
    } catch (e) {
      print('❌ Error getting cached notifications: $e');
      return [];
    }
  }

  // Xóa cached notifications cũ
  Future<void> clearOldCachedNotifications({int daysOld = 7}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .where('cachedAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('🗑️ Cleared ${snapshot.docs.length} old cached notifications');
    } catch (e) {
      print('❌ Error clearing old notifications: $e');
    }
  }

  // Kiểm tra trạng thái kết nối
  bool get isConnected => _isConnected;

  // Lấy thông tin kết nối
  Map<String, dynamic> getConnectionInfo() {
    return {
      'isConnected': _isConnected,
      'userId': _currentUserId,
      'hasNotificationStream': _notificationController != null,
      'hasAnalyticsStream': _analyticsController != null,
    };
  }

  // Cleanup
  void dispose() {
    _disconnect();
  }
}
