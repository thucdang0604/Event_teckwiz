import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    // Khởi tạo local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Cấu hình Firebase Messaging
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Lắng nghe thông báo từ Firebase
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Xử lý khi người dùng tap vào thông báo
    print('Notification tapped: ${response.payload}');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Hiển thị thông báo khi app đang chạy
    _showLocalNotification(
      message.notification?.title ?? 'Thông báo mới',
      message.notification?.body ?? 'Bạn có thông báo mới',
      message.data,
    );
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    // Xử lý thông báo khi app ở background
    print('Background message: ${message.data}');
  }

  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic>? data,
  ) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'event_notifications',
          'Event Notifications',
          channelDescription: 'Thông báo về sự kiện và đăng ký',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: data?.toString(),
    );
  }

  // Gửi thông báo đăng ký thành công
  Future<void> sendRegistrationSuccessNotification({
    required String userId,
    required String eventTitle,
    required String eventId,
  }) async {
    String title = 'Đăng ký thành công! 🎉';
    String body = 'Bạn đã đăng ký thành công sự kiện "$eventTitle"';

    await _showLocalNotification(title, body, {
      'type': 'registration_success',
      'eventId': eventId,
    });

    // Lưu vào database để hiển thị trong app
    await _saveNotificationToDatabase(
      userId: userId,
      title: title,
      body: body,
      type: 'registration_success',
      eventId: eventId,
    );
  }

  // Gửi thông báo thanh toán thành công
  Future<void> sendPaymentSuccessNotification({
    required String userId,
    required String eventTitle,
    required double amount,
    required String eventId,
  }) async {
    String title = 'Thanh toán thành công! 💰';
    String body =
        'Bạn đã thanh toán ${amount.toStringAsFixed(0)} VNĐ cho sự kiện "$eventTitle"';

    await _showLocalNotification(title, body, {
      'type': 'payment_success',
      'eventId': eventId,
      'amount': amount.toString(),
    });

    await _saveNotificationToDatabase(
      userId: userId,
      title: title,
      body: body,
      type: 'payment_success',
      eventId: eventId,
    );
  }

  // Gửi thông báo được duyệt làm tình nguyện
  Future<void> sendSupportApprovalNotification({
    required String userId,
    required String eventTitle,
    required String eventId,
  }) async {
    String title = 'Được duyệt làm tình nguyện! 🤝';
    String body = 'Bạn đã được duyệt làm tình nguyện cho sự kiện "$eventTitle"';

    await _showLocalNotification(title, body, {
      'type': 'support_approval',
      'eventId': eventId,
    });

    await _saveNotificationToDatabase(
      userId: userId,
      title: title,
      body: body,
      type: 'support_approval',
      eventId: eventId,
    );
  }

  // Gửi thông báo hủy đăng ký
  Future<void> sendCancellationNotification({
    required String userId,
    required String eventTitle,
    required String eventId,
    required bool isRefund,
    double? refundAmount,
  }) async {
    String title = isRefund ? 'Hủy đăng ký và hoàn tiền! 💸' : 'Hủy đăng ký! ❌';
    String body = isRefund
        ? 'Bạn đã hủy đăng ký sự kiện "$eventTitle" và sẽ được hoàn ${refundAmount?.toStringAsFixed(0) ?? '0'} VNĐ'
        : 'Bạn đã hủy đăng ký sự kiện "$eventTitle"';

    await _showLocalNotification(title, body, {
      'type': 'cancellation',
      'eventId': eventId,
      'isRefund': isRefund.toString(),
      'refundAmount': refundAmount?.toString(),
    });

    await _saveNotificationToDatabase(
      userId: userId,
      title: title,
      body: body,
      type: 'cancellation',
      eventId: eventId,
    );
  }

  // Lưu thông báo vào database
  Future<void> _saveNotificationToDatabase({
    required String userId,
    required String title,
    required String body,
    required String type,
    required String eventId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'eventId': eventId,
        'isRead': false,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error saving notification to database: $e');
    }
  }

  // Lấy danh sách thông báo của user
  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      // Query đơn giản hơn để tránh lỗi index
      QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Sắp xếp trong code thay vì database
        List<QueryDocumentSnapshot> docs = snapshot.docs;

        // Sắp xếp theo createdAt
        docs.sort((a, b) {
          Map<String, dynamic> aData = a.data() as Map<String, dynamic>;
          Map<String, dynamic> bData = b.data() as Map<String, dynamic>;
          Timestamp aTime = aData['createdAt'] ?? Timestamp.now();
          Timestamp bTime = bData['createdAt'] ?? Timestamp.now();
          return bTime.compareTo(aTime);
        });

        // Giới hạn 50 thông báo
        docs = docs.take(50).toList();

        return docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      }

      return [];
    } catch (e) {
      print('Error getting user notifications: $e');
      return [];
    }
  }

  // Đánh dấu thông báo đã đọc
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Đánh dấu tất cả thông báo đã đọc
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      // Query đơn giản hơn để tránh lỗi index
      QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        WriteBatch batch = _firestore.batch();

        // Lọc trong code thay vì database
        for (QueryDocumentSnapshot doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          bool isRead = data['isRead'] ?? false;
          if (!isRead) {
            batch.update(doc.reference, {'isRead': true});
          }
        }

        await batch.commit();
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Lấy số lượng thông báo chưa đọc
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      // Query đơn giản hơn để tránh lỗi index
      QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Lọc trong code thay vì database
        int unreadCount = 0;
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          bool isRead = data['isRead'] ?? false;
          if (!isRead) {
            unreadCount++;
          }
        }
        return unreadCount;
      }

      return 0;
    } catch (e) {
      print('Error getting unread notification count: $e');
      return 0;
    }
  }
}
