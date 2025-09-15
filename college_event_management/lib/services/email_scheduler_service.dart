import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'email_service.dart';
import 'event_service.dart';
import 'registration_service.dart';
import '../models/event_model.dart';

class EmailSchedulerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EmailService _emailService = EmailService.instance;
  EventService? _eventService;
  RegistrationService? _registrationService;

  EventService get _eventServiceInstance => _eventService ??= EventService();
  RegistrationService get _registrationServiceInstance =>
      _registrationService ??= RegistrationService();

  Timer? _reminderTimer;
  static const String _scheduledEmailsCollection = 'scheduled_emails';

  // Khởi tạo scheduler
  void initialize() {
    print('🕐 Initializing email scheduler...');
    _startReminderScheduler();
  }

  // Bắt đầu scheduler cho reminders
  void _startReminderScheduler() {
    // Chạy mỗi 30 phút để kiểm tra reminders
    _reminderTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _checkAndSendReminders();
    });
    print('✅ Email reminder scheduler started');
  }

  // Kiểm tra và gửi reminders
  Future<void> _checkAndSendReminders() async {
    try {
      final now = DateTime.now();

      // Kiểm tra reminders 24h trước sự kiện
      await _sendRemindersForTimeframe(
        now.add(const Duration(hours: 24)),
        '24h',
      );

      // Kiểm tra reminders 1h trước sự kiện
      await _sendRemindersForTimeframe(now.add(const Duration(hours: 1)), '1h');
    } catch (e) {
      print('❌ Error checking reminders: $e');
    }
  }

  // Gửi reminders cho một khoảng thời gian cụ thể
  Future<void> _sendRemindersForTimeframe(
    DateTime targetTime,
    String reminderType,
  ) async {
    try {
      final startOfHour = DateTime(
        targetTime.year,
        targetTime.month,
        targetTime.day,
        targetTime.hour,
      );
      final endOfHour = startOfHour.add(const Duration(hours: 1));

      // Lấy tất cả sự kiện trong khoảng thời gian này
      final events = await _eventServiceInstance.getEvents(
        status: 'published',
        limit: 100,
      );

      final upcomingEvents = events.where((event) {
        return event.startDate.isAfter(startOfHour) &&
            event.startDate.isBefore(endOfHour);
      }).toList();

      print(
        '📅 Found ${upcomingEvents.length} events for $reminderType reminder',
      );

      for (final event in upcomingEvents) {
        await _sendEventReminders(event, reminderType);
      }
    } catch (e) {
      print('❌ Error sending $reminderType reminders: $e');
    }
  }

  // Gửi reminders cho một sự kiện cụ thể
  Future<void> _sendEventReminders(
    EventModel event,
    String reminderType,
  ) async {
    try {
      // Lấy danh sách đăng ký đã được duyệt
      final registrations = await _registrationServiceInstance
          .getEventRegistrations(event.id);
      final approvedRegistrations = registrations
          .where((reg) => reg.status == 'approved' || reg.status == 'confirmed')
          .toList();

      print(
        '📧 Sending $reminderType reminders for event: ${event.title} to ${approvedRegistrations.length} participants',
      );

      for (final registration in approvedRegistrations) {
        try {
          await _emailService.sendEventReminderEmail(
            userEmail: registration.userEmail,
            userName: registration.userName,
            eventTitle: event.title,
            eventDate: event.startDate,
            eventLocation: event.location,
            reminderType: reminderType,
          );

          // Lưu log để tránh gửi trùng
          await _logScheduledEmail(
            eventId: event.id,
            userEmail: registration.userEmail,
            emailType: 'eventReminder',
            reminderType: reminderType,
          );
        } catch (e) {
          print('❌ Error sending reminder to ${registration.userEmail}: $e');
        }
      }
    } catch (e) {
      print('❌ Error sending event reminders: $e');
    }
  }

  // Lên lịch gửi email
  Future<void> scheduleEmail({
    required String eventId,
    required String userEmail,
    required EmailType emailType,
    required Map<String, dynamic> data,
    required DateTime scheduledTime,
  }) async {
    try {
      await _firestore.collection(_scheduledEmailsCollection).add({
        'eventId': eventId,
        'userEmail': userEmail,
        'emailType': emailType.name,
        'data': data,
        'scheduledTime': Timestamp.fromDate(scheduledTime),
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      print('📅 Email scheduled for ${scheduledTime.toIso8601String()}');
    } catch (e) {
      print('❌ Error scheduling email: $e');
    }
  }

  // Lên lịch gửi email hàng loạt
  Future<void> scheduleBulkEmail({
    required List<String> userEmails,
    required EmailType emailType,
    required Map<String, dynamic> data,
    required DateTime scheduledTime,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final userEmail in userEmails) {
        final docRef = _firestore.collection(_scheduledEmailsCollection).doc();
        batch.set(docRef, {
          'userEmail': userEmail,
          'emailType': emailType.name,
          'data': data,
          'scheduledTime': Timestamp.fromDate(scheduledTime),
          'status': 'pending',
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'isBulk': true,
        });
      }

      await batch.commit();
      print('📅 Bulk email scheduled for ${userEmails.length} recipients');
    } catch (e) {
      print('❌ Error scheduling bulk email: $e');
    }
  }

  // Gửi email đã được lên lịch
  Future<void> processScheduledEmails() async {
    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));

      final snapshot = await _firestore
          .collection(_scheduledEmailsCollection)
          .where('status', isEqualTo: 'pending')
          .where('scheduledTime', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('scheduledTime', isGreaterThan: Timestamp.fromDate(oneHourAgo))
          .get();

      print('📧 Processing ${snapshot.docs.length} scheduled emails');

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final emailType = EmailType.values.firstWhere(
            (e) => e.name == data['emailType'],
            orElse: () => EmailType.bulkAnnouncement,
          );

          final success = await _emailService.sendEmail(
            to: data['userEmail'],
            type: emailType,
            data: Map<String, dynamic>.from(data['data'] ?? {}),
          );

          if (success) {
            await doc.reference.update({'status': 'sent'});
            print('✅ Scheduled email sent to ${data['userEmail']}');
          } else {
            await doc.reference.update({'status': 'failed'});
            print('❌ Failed to send scheduled email to ${data['userEmail']}');
          }
        } catch (e) {
          print('❌ Error processing scheduled email: $e');
          await doc.reference.update({'status': 'failed'});
        }
      }
    } catch (e) {
      print('❌ Error processing scheduled emails: $e');
    }
  }

  // Lưu log email đã gửi
  Future<void> _logScheduledEmail({
    required String eventId,
    required String userEmail,
    required String emailType,
    required String reminderType,
  }) async {
    try {
      await _firestore.collection('email_logs').add({
        'eventId': eventId,
        'userEmail': userEmail,
        'emailType': emailType,
        'reminderType': reminderType,
        'sentAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('❌ Error logging email: $e');
    }
  }

  // Lên lịch gửi welcome email cho user mới
  Future<void> scheduleWelcomeEmail({
    required String userEmail,
    required String userName,
    required String userRole,
    DateTime? scheduledTime,
  }) async {
    final time =
        scheduledTime ?? DateTime.now().add(const Duration(minutes: 5));

    await scheduleEmail(
      eventId: 'welcome',
      userEmail: userEmail,
      emailType: EmailType.welcome,
      data: {'userName': userName, 'userRole': userRole},
      scheduledTime: time,
    );
  }

  // Lên lịch gửi event reminder
  Future<void> scheduleEventReminder({
    required String eventId,
    required DateTime eventDate,
    required String reminderType,
  }) async {
    DateTime scheduledTime;

    if (reminderType == '24h') {
      scheduledTime = eventDate.subtract(const Duration(hours: 24));
    } else if (reminderType == '1h') {
      scheduledTime = eventDate.subtract(const Duration(hours: 1));
    } else {
      return; // Invalid reminder type
    }

    // Chỉ lên lịch nếu thời gian trong tương lai
    if (scheduledTime.isAfter(DateTime.now())) {
      await scheduleEmail(
        eventId: eventId,
        userEmail: 'bulk', // Sẽ được xử lý riêng
        emailType: EmailType.eventReminder,
        data: {'eventId': eventId, 'reminderType': reminderType},
        scheduledTime: scheduledTime,
      );
    }
  }

  // Dọn dẹp scheduler
  void dispose() {
    _reminderTimer?.cancel();
    print('🛑 Email scheduler disposed');
  }

  // Lấy thống kê email
  Future<Map<String, dynamic>> getEmailStats() async {
    try {
      final snapshot = await _firestore.collection('email_logs').get();

      int totalSent = snapshot.docs.length;
      int welcomeEmails = snapshot.docs
          .where((doc) => doc.data()['emailType'] == 'welcome')
          .length;
      int reminderEmails = snapshot.docs
          .where((doc) => doc.data()['emailType'] == 'eventReminder')
          .length;
      int registrationEmails = snapshot.docs
          .where((doc) => doc.data()['emailType'] == 'eventRegistration')
          .length;

      return {
        'totalSent': totalSent,
        'welcomeEmails': welcomeEmails,
        'reminderEmails': reminderEmails,
        'registrationEmails': registrationEmails,
      };
    } catch (e) {
      print('❌ Error getting email stats: $e');
      return {};
    }
  }
}
