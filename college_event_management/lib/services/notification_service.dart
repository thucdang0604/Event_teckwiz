import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum NotificationType {
  eventCreated,
  eventUpdated,
  eventCancelled,
  registrationConfirmed,
  registrationRejected,
  eventReminder,
  systemAnnouncement,
  chatMessage,
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.systemAnnouncement,
      ),
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const String _notificationsKey = 'notifications_history';
  static const int _maxStoredNotifications = 100;

  static final List<NotificationModel> _notificationHistory = [];

  // Callback to notify when notifications are updated
  static Function()? _onNotificationsUpdated;

  static const String _notificationsKey = 'notifications_history';
  static const int _maxStoredNotifications = 100;

  static final List<NotificationModel> _notificationHistory = [];

  static Function()? _onNotificationsUpdated;

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onNotificationTapped,
    );


    await _loadNotificationHistory();
    await _initializeFirebaseMessaging();
  }

  void _onNotificationTapped(NotificationResponse response) {

    // Request permission for iOS
    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Load notification history
    await _loadNotificationHistory();

    // Initialize Firebase Messaging
    await _initializeFirebaseMessaging();
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');

    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        final notification = NotificationModel.fromJson(data);


        // Mark as read
        markNotificationAsRead(notification.id);

        // Handle navigation based on notification type

        _handleNotificationNavigation(notification);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  static void _handleNotificationNavigation(NotificationModel notification) {

    // This can be extended to use navigation service or global key for navigation
    print('Handling navigation for notification type: ${notification.type}');

    switch (notification.type) {
      case NotificationType.eventCreated:
        // For admin: event pending approval

        if (notification.data?['eventId'] != null) {
          print('Navigate to event approval: ${notification.data!['eventId']}');
        }
        break;
      case NotificationType.eventUpdated:
      case NotificationType.eventCancelled:
        if (notification.data?['eventId'] != null) {


          print('Navigate to event: ${notification.data!['eventId']}');
        }
        break;
      case NotificationType.registrationConfirmed:
      case NotificationType.registrationRejected:

        print('Navigate to registrations');
        break;
      case NotificationType.chatMessage:
        if (notification.data?['eventId'] != null) {

          print('Navigate to chat: ${notification.data!['eventId']}');
        }
        break;
      default:

        print('Navigate to home');
        break;
    }
  }

  static Future<void> _initializeFirebaseMessaging() async {
    try {
      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
      } else {
        print('User declined or has not accepted permission');
      }
    } catch (e) {
      print('Error initializing Firebase Messaging: $e');
      return;
    }

    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          final notification = NotificationModel(
            id: message.messageId ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            title: message.notification!.title ?? 'Notification',
            body: message.notification!.body ?? '',
            type: _getNotificationTypeFromData(message.data),
            data: message.data,
            timestamp: message.sentTime ?? DateTime.now(),
          );


          final notification = NotificationModel(
            id:
                message.messageId ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            title: message.notification!.title ?? 'Notification',
            body: message.notification!.body ?? '',
            type: _getNotificationTypeFromData(message.data),
            data: message.data,
            timestamp: message.sentTime ?? DateTime.now(),
          );

          _addNotificationToHistory(notification);


          _showLocalNotification(
            notification.title,
            notification.body,
            payload: jsonEncode(notification.toJson()),
          );
        }
      });

      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message.data);
      });

      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {

      // Handle when app is opened from terminated state
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Message opened app from terminated state: ${message.data}');
        _handleNotificationTap(message.data);
      });

      // Get initial message if app was opened from terminated state
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        print('Initial message: ${initialMessage.data}');

        _handleNotificationTap(initialMessage.data);
      }
    } catch (e) {
      print('Error setting up Firebase Messaging listeners: $e');
    }
  }

  static Future<void> _showLocalNotification(
    String title,
    String body, {
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(

          'event_channel',
          'Event Notifications',
          channelDescription: 'Notifications for events',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );


    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _instance._localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  static Future<void> _loadNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];
      _notificationHistory.clear();
      for (final jsonStr in notificationsJson) {
        try {
          final json = jsonDecode(jsonStr);
          final notification = NotificationModel.fromJson(json);
          _notificationHistory.add(notification);
        } catch (e) {
          print('Error parsing notification: $e');
        }
      }
      _notificationHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      print('Error loading notification history: $e');
    }
  }

  static Future<void> _saveNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notificationHistory
          .take(_maxStoredNotifications)
          .map((n) => jsonEncode(n.toJson()))
          .toList();
      await prefs.setStringList(_notificationsKey, notificationsJson);
    } catch (e) {
      print('Error saving notification history: $e');
    }
  }

  static void _addNotificationToHistory(NotificationModel notification) {
    _notificationHistory.insert(0, notification);
    if (_notificationHistory.length > _maxStoredNotifications) {
      _notificationHistory.removeRange(
        _maxStoredNotifications,
        _notificationHistory.length,
      );
    }
    _saveNotificationHistory();
    _onNotificationsUpdated?.call();
  }

  static NotificationType _getNotificationTypeFromData(
    Map<String, dynamic> data,
  ) {
    final type = data['type'] as String?;
    switch (type) {
      case 'eventCreated':
        return NotificationType.eventCreated;
      case 'eventUpdated':
        return NotificationType.eventUpdated;
      case 'eventCancelled':
        return NotificationType.eventCancelled;
      case 'registrationConfirmed':
        return NotificationType.registrationConfirmed;
      case 'registrationRejected':
        return NotificationType.registrationRejected;
      case 'eventReminder':
        return NotificationType.eventReminder;
      case 'chatMessage':
        return NotificationType.chatMessage;
      default:
        return NotificationType.systemAnnouncement;
    }
  }

  static void _handleNotificationTap(Map<String, dynamic> data) {
    print('Handling notification tap with data: $data');
  }

  static Future<void> loadNotificationHistory() async {
    await _loadNotificationHistory();
  }

  static void setNotificationUpdateCallback(Function() callback) {
    _onNotificationsUpdated = callback;
  }

  static List<NotificationModel> getNotificationHistory() {
    return List.unmodifiable(_notificationHistory);
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    final index = _notificationHistory.indexWhere(
      (n) => n.id == notificationId,
    );
    if (index != -1) {
      final updatedNotification = NotificationModel(
        id: _notificationHistory[index].id,
        title: _notificationHistory[index].title,
        body: _notificationHistory[index].body,
        type: _notificationHistory[index].type,
        data: _notificationHistory[index].data,
        timestamp: _notificationHistory[index].timestamp,
        isRead: true,
      );
      _notificationHistory[index] = updatedNotification;
      await _saveNotificationHistory();
    }
  }

  static Future<void> clearNotificationHistory() async {
    _notificationHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
  }

  static int getUnreadNotificationCount() {
    return _notificationHistory.where((n) => !n.isRead).length;
  }

  static Future<void> sendNotificationToAdmin({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final Map<String, dynamic> payloadData = {
        if (data != null) ...data,
        'targetRole': 'admin',
      };
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        data: payloadData,
        timestamp: DateTime.now(),
      );
      _addNotificationToHistory(notification);
      await _showLocalNotification(
        notification.title,
        notification.body,
        payload: jsonEncode(notification.toJson()),
      );
      print('Notification sent to admin: $title');
    } catch (e) {
      print('Error sending notification to admin: $e');
    }
  }

  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final Map<String, dynamic> payloadData = {
        if (data != null) ...data,
        'targetUserId': userId,
      };
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        data: payloadData,
        timestamp: DateTime.now(),
      );
      _addNotificationToHistory(notification);
      await _showLocalNotification(
        notification.title,
        notification.body,
        payload: jsonEncode(notification.toJson()),
      );
      print('Notification sent to user $userId: $title');
    } catch (e) {
      print('Error sending notification to user: $e');
    }
  }

  static Future<void> addTestNotification() async {
    final testNotification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Test Notification',
      body: 'This is a test notification to demonstrate the notification system.',
      type: NotificationType.systemAnnouncement,
      timestamp: DateTime.now(),
    );
    _addNotificationToHistory(testNotification);
    await _showLocalNotification(
      testNotification.title,
      testNotification.body,
      payload: jsonEncode(testNotification.toJson()),
    );
  }

  // Helper methods for notification history
  static Future<void> _loadNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];

      _notificationHistory.clear();
      for (final jsonStr in notificationsJson) {
        try {
          final json = jsonDecode(jsonStr);
          final notification = NotificationModel.fromJson(json);
          _notificationHistory.add(notification);
        } catch (e) {
          print('Error parsing notification: $e');
        }
      }

      // Sort by timestamp (newest first)
      _notificationHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      print('Error loading notification history: $e');
    }
  }

  static Future<void> _saveNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notificationHistory
          .take(_maxStoredNotifications)
          .map((n) => jsonEncode(n.toJson()))
          .toList();

      await prefs.setStringList(_notificationsKey, notificationsJson);
    } catch (e) {
      print('Error saving notification history: $e');
    }
  }

  static void _addNotificationToHistory(NotificationModel notification) {
    _notificationHistory.insert(0, notification); // Add to beginning

    // Keep only the most recent notifications
    if (_notificationHistory.length > _maxStoredNotifications) {
      _notificationHistory.removeRange(
        _maxStoredNotifications,
        _notificationHistory.length,
      );
    }

    _saveNotificationHistory();

    // Notify listeners that notifications have been updated
    _onNotificationsUpdated?.call();
  }

  static NotificationType _getNotificationTypeFromData(
    Map<String, dynamic> data,
  ) {
    final type = data['type'] as String?;
    switch (type) {
      case 'eventCreated':
        return NotificationType.eventCreated;
      case 'eventUpdated':
        return NotificationType.eventUpdated;
      case 'eventCancelled':
        return NotificationType.eventCancelled;
      case 'registrationConfirmed':
        return NotificationType.registrationConfirmed;
      case 'registrationRejected':
        return NotificationType.registrationRejected;
      case 'eventReminder':
        return NotificationType.eventReminder;
      case 'chatMessage':
        return NotificationType.chatMessage;
      default:
        return NotificationType.systemAnnouncement;
    }
  }

  static void _handleNotificationTap(Map<String, dynamic> data) {
    // This method can be extended to navigate to specific screens based on notification type
    print('Handling notification tap with data: $data');
    // TODO: Implement navigation based on notification type and data
  }

  // Public methods for accessing notification history
  static Future<void> loadNotificationHistory() async {
    await _loadNotificationHistory();
  }

  static void setNotificationUpdateCallback(Function() callback) {
    _onNotificationsUpdated = callback;
  }

  static List<NotificationModel> getNotificationHistory() {
    return List.unmodifiable(_notificationHistory);
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    final index = _notificationHistory.indexWhere(
      (n) => n.id == notificationId,
    );
    if (index != -1) {
      final updatedNotification = NotificationModel(
        id: _notificationHistory[index].id,
        title: _notificationHistory[index].title,
        body: _notificationHistory[index].body,
        type: _notificationHistory[index].type,
        data: _notificationHistory[index].data,
        timestamp: _notificationHistory[index].timestamp,
        isRead: true,
      );

      _notificationHistory[index] = updatedNotification;
      await _saveNotificationHistory();
    }
  }

  static Future<void> clearNotificationHistory() async {
    _notificationHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
  }

  static int getUnreadNotificationCount() {
    return _notificationHistory.where((n) => !n.isRead).length;
  }

  // Gửi notification đến admin
  static Future<void> sendNotificationToAdmin({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Tạo notification object
      final Map<String, dynamic> payloadData = {
        if (data != null) ...data,
        'targetRole': 'admin',
      };
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        data: payloadData,
        timestamp: DateTime.now(),
      );

      // Lưu vào local notification history
      _addNotificationToHistory(notification);

      // Hiển thị local notification
      await _showLocalNotification(
        notification.title,
        notification.body,
        payload: jsonEncode(notification.toJson()),
      );

      // Trong thực tế, bạn có thể gửi FCM message đến admin topic
      // Hiện tại chúng ta chỉ hiển thị local notification cho admin
      print('Notification sent to admin: $title');
    } catch (e) {
      print('Error sending notification to admin: $e');
    }
  }

  // Gửi notification đến user cụ thể
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Tạo notification object
      final Map<String, dynamic> payloadData = {
        if (data != null) ...data,
        'targetUserId': userId,
      };
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        data: payloadData,
        timestamp: DateTime.now(),
      );

      // Lưu vào local notification history
      _addNotificationToHistory(notification);

      // Hiển thị local notification
      await _showLocalNotification(
        notification.title,
        notification.body,
        payload: jsonEncode(notification.toJson()),
      );

      // Trong thực tế, bạn có thể gửi FCM message đến user topic
      // Hiện tại chúng ta chỉ hiển thị local notification cho user
      print('Notification sent to user $userId: $title');
    } catch (e) {
      print('Error sending notification to user: $e');
    }
  }

  // Test method to add sample notifications
  static Future<void> addTestNotification() async {
    final testNotification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Test Notification',
      body:
          'This is a test notification to demonstrate the notification system.',
      type: NotificationType.systemAnnouncement,
      timestamp: DateTime.now(),
    );

    _addNotificationToHistory(testNotification);

    // Show local notification
    await _showLocalNotification(
      testNotification.title,
      testNotification.body,
      payload: jsonEncode(testNotification.toJson()),
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');


  if (message.notification != null) {
    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification!.title ?? 'Notification',
      body: message.notification!.body ?? '',
      type: NotificationService._getNotificationTypeFromData(message.data),
      data: message.data,
      timestamp: message.sentTime ?? DateTime.now(),
    );


    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson =
          prefs.getStringList('notifications_history') ?? [];


      notificationsJson.insert(0, jsonEncode(notification.toJson()));

      // Keep only the most recent notifications
      if (notificationsJson.length > 100) {
        notificationsJson.removeRange(100, notificationsJson.length);
      }


      await prefs.setStringList('notifications_history', notificationsJson);
    } catch (e) {
      print('Error saving background notification: $e');
    }
  }
}
