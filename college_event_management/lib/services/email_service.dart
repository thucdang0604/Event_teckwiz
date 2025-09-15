import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'email_templates.dart';

enum EmailType {
  verification,
  eventRegistration,
  eventReminder,
  eventCancellation,
  registrationApproval,
  registrationRejection,
  eventUpdate,
  welcome,
  passwordReset,
  coOrganizerInvitation,
  bulkAnnouncement,
  eventApproval,
  eventRejection,
  certificateIssued,
}

class EmailTemplate {
  final String subject;
  final String htmlContent;
  final String textContent;

  EmailTemplate({
    required this.subject,
    required this.htmlContent,
    required this.textContent,
  });
}

class EmailService {
  static EmailService? _instance;
  static EmailService get instance => _instance ??= EmailService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _verificationCollection = 'email_verifications';

  // Email configuration
  SmtpServer? _smtpServer;
  String _fromEmail = 'noreply@example.com';
  bool _isInitialized = false;

  EmailService._internal() {
    _initializeEmail();
  }

  void _initializeEmail() {
    if (_isInitialized) return;

    try {
      String? gmailPassword;
      try {
        gmailPassword = dotenv.env['GMAIL_APP_PASSWORD'];
      } catch (e) {
        print('⚠️ Dotenv not initialized, using fallback configuration');
        gmailPassword = null;
      }
      if (gmailPassword == null || gmailPassword.isEmpty) {
        print('⚠️ GMAIL_APP_PASSWORD not found in .env file');
        print('🔧 Using hardcoded App Password for testing...');
        // Sử dụng App Password đã cung cấp
        _smtpServer = SmtpServer(
          'smtp.gmail.com',
          username: 'thucdang2205@gmail.com',
          password: 'soco lnxr xwvx yohb',
          port: 587,
          allowInsecure: false,
        );
        _fromEmail = 'thucdang2205@gmail.com';
        print('✅ Gmail SMTP configured successfully');
      } else {
        // Firebase/Gmail SMTP configuration
        _smtpServer = SmtpServer(
          'smtp.gmail.com',
          username: 'thucdang2205@gmail.com',
          password: gmailPassword,
          port: 587,
          allowInsecure: false,
        );
        _fromEmail = 'thucdang2205@gmail.com';
        print('✅ Gmail SMTP configured from .env file');
      }
      _isInitialized = true;
    } catch (e) {
      print('❌ Error initializing email service: ${e.toString()}');
      // Fallback với hardcoded password
      _smtpServer = SmtpServer(
        'smtp.gmail.com',
        username: 'thucdang2205@gmail.com',
        password: 'soco lnxr xwvx yohb',
        port: 587,
        allowInsecure: false,
      );
      _fromEmail = 'thucdang2205@gmail.com';
      print('✅ Gmail SMTP configured with fallback');
      _isInitialized = true;
    }
  }

  String _generateVerificationCode() {
    const chars = '0123456789';
    final random = Random();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<String> sendVerificationCode(String email) async {
    try {
      final verificationCode = _generateVerificationCode();
      final now = DateTime.now();
      final expiresAt = now.add(
        const Duration(minutes: 10),
      ); // Mã hết hạn sau 10 phút

      // Lưu mã xác thực vào Firestore
      await _firestore.collection(_verificationCollection).add({
        'email': email.toLowerCase(),
        'code': verificationCode,
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'isUsed': false,
      });

      // Gửi email thật qua SendGrid hoặc fallback console
      await _sendEmailWithSendGrid(email, verificationCode);

      return verificationCode;
    } catch (e) {
      throw Exception('Error sending verification code: ${e.toString()}');
    }
  }

  Future<void> _sendEmailWithSendGrid(String email, String code) async {
    try {
      if (_smtpServer == null) {
        throw Exception('SMTP server not initialized');
      }

      final template = _buildVerificationTemplate(code);
      final message = Message()
        ..from = Address(_fromEmail, 'College Event Management')
        ..recipients.add(email)
        ..subject = template.subject
        ..html = template.htmlContent
        ..text = template.textContent;

      print('📧 Sending email to: $email');
      print('🔑 Using SMTP: ${_smtpServer!.host}:${_smtpServer!.port}');

      await send(message, _smtpServer!);

      print('✅ Email sent successfully to: $email');
      print('📬 Check your inbox for the verification code!');
    } catch (e) {
      print('❌ Error sending email: ${e.toString()}');
      print('🔄 Attempting fallback to console logging...');

      // Fallback to console logging
      print('=== EMAIL VERIFICATION (FALLBACK) ===');
      print('Email: $email');
      print('Verification Code: $code');
      print('Expires at: ${DateTime.now().add(const Duration(minutes: 10))}');
      print('=====================================');
    }
  }

  // New email sending methods
  Future<bool> sendEmail({
    required String to,
    required EmailType type,
    required Map<String, dynamic> data,
  }) async {
    try {
      if (_smtpServer == null) {
        throw Exception('SMTP server not initialized');
      }

      final template = _buildEmailTemplate(type, data);

      final message = Message()
        ..from = Address(_fromEmail, 'College Event Management')
        ..recipients.add(to)
        ..subject = template.subject
        ..html = template.htmlContent
        ..text = template.textContent;

      print('📧 Sending $type email to: $to');
      print('🔑 Subject: ${template.subject}');

      await send(message, _smtpServer!);

      print('✅ Email sent successfully to: $to');
      return true;
    } catch (e) {
      print('❌ Error sending email: ${e.toString()}');
      print('🔄 Attempting fallback to console logging...');

      // Fallback to console logging
      final template = _buildEmailTemplate(type, data);
      print('=== EMAIL SEND (FALLBACK) ===');
      print('To: $to');
      print('Type: $type');
      print('Subject: ${template.subject}');
      print('Data: $data');
      print('==============================');
      return false;
    }
  }

  Future<bool> sendBulkEmail({
    required List<String> recipients,
    required EmailType type,
    required Map<String, dynamic> data,
  }) async {
    int successCount = 0;
    int failCount = 0;

    for (String recipient in recipients) {
      try {
        bool success = await sendEmail(to: recipient, type: type, data: data);
        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        print('❌ Error sending email to $recipient: $e');
        failCount++;
      }
    }

    print('📊 Bulk email results: $successCount success, $failCount failed');
    return failCount == 0;
  }

  Future<bool> sendEventRegistrationEmail({
    required String userEmail,
    required String userName,
    required String eventTitle,
    required DateTime eventDate,
    required String eventLocation,
  }) async {
    return await sendEmail(
      to: userEmail,
      type: EmailType.eventRegistration,
      data: {
        'userName': userName,
        'eventTitle': eventTitle,
        'eventDate': eventDate.toIso8601String(),
        'eventLocation': eventLocation,
      },
    );
  }

  Future<bool> sendEventReminderEmail({
    required String userEmail,
    required String userName,
    required String eventTitle,
    required DateTime eventDate,
    required String eventLocation,
    required String reminderType,
  }) async {
    return await sendEmail(
      to: userEmail,
      type: EmailType.eventReminder,
      data: {
        'userName': userName,
        'eventTitle': eventTitle,
        'eventDate': eventDate.toIso8601String(),
        'eventLocation': eventLocation,
        'reminderType': reminderType,
      },
    );
  }

  Future<bool> sendEventCancellationEmail({
    required String userEmail,
    required String userName,
    required String eventTitle,
    required DateTime eventDate,
    required String reason,
  }) async {
    return await sendEmail(
      to: userEmail,
      type: EmailType.eventCancellation,
      data: {
        'userName': userName,
        'eventTitle': eventTitle,
        'eventDate': eventDate.toIso8601String(),
        'reason': reason,
      },
    );
  }

  Future<bool> sendRegistrationApprovalEmail({
    required String userEmail,
    required String userName,
    required String eventTitle,
    required DateTime eventDate,
    required String eventLocation,
  }) async {
    return await sendEmail(
      to: userEmail,
      type: EmailType.registrationApproval,
      data: {
        'userName': userName,
        'eventTitle': eventTitle,
        'eventDate': eventDate.toIso8601String(),
        'eventLocation': eventLocation,
      },
    );
  }

  Future<bool> sendRegistrationRejectionEmail({
    required String userEmail,
    required String userName,
    required String eventTitle,
    required String reason,
  }) async {
    return await sendEmail(
      to: userEmail,
      type: EmailType.registrationRejection,
      data: {'userName': userName, 'eventTitle': eventTitle, 'reason': reason},
    );
  }

  Future<bool> sendEventApprovalEmail({
    required String organizerEmail,
    required String organizerName,
    required String eventTitle,
    required DateTime eventDate,
  }) async {
    return await sendEmail(
      to: organizerEmail,
      type: EmailType.eventApproval,
      data: {
        'organizerName': organizerName,
        'eventTitle': eventTitle,
        'eventDate': eventDate.toIso8601String(),
      },
    );
  }

  Future<bool> sendEventRejectionEmail({
    required String organizerEmail,
    required String organizerName,
    required String eventTitle,
    required String reason,
  }) async {
    return await sendEmail(
      to: organizerEmail,
      type: EmailType.eventRejection,
      data: {
        'organizerName': organizerName,
        'eventTitle': eventTitle,
        'reason': reason,
      },
    );
  }

  Future<bool> sendWelcomeEmail({
    required String userEmail,
    required String userName,
    required String userRole,
  }) async {
    return await sendEmail(
      to: userEmail,
      type: EmailType.welcome,
      data: {'userName': userName, 'userRole': userRole},
    );
  }

  // Template builder methods
  EmailTemplate _buildEmailTemplate(EmailType type, Map<String, dynamic> data) {
    switch (type) {
      case EmailType.verification:
        return _buildVerificationTemplate(data['code'] as String);
      case EmailType.eventRegistration:
        return _buildEventRegistrationTemplate(data);
      case EmailType.eventReminder:
        return _buildEventReminderTemplate(data);
      case EmailType.eventCancellation:
        return _buildEventCancellationTemplate(data);
      case EmailType.registrationApproval:
        return _buildRegistrationApprovalTemplate(data);
      case EmailType.registrationRejection:
        return _buildRegistrationRejectionTemplate(data);
      case EmailType.eventUpdate:
        return _buildEventUpdateTemplate(data);
      case EmailType.welcome:
        return _buildWelcomeTemplate(data);
      case EmailType.passwordReset:
        return _buildPasswordResetTemplate(data);
      case EmailType.coOrganizerInvitation:
        return _buildCoOrganizerInvitationTemplate(data);
      case EmailType.bulkAnnouncement:
        return _buildBulkAnnouncementTemplate(data);
      case EmailType.eventApproval:
        return _buildEventApprovalTemplate(data);
      case EmailType.eventRejection:
        return _buildEventRejectionTemplate(data);
      case EmailType.certificateIssued:
        return _buildCertificateIssuedTemplate(data);
    }
  }

  EmailTemplate _buildVerificationTemplate(String code) {
    return EmailTemplate(
      subject: 'Email Verification Code - College Event Management',
      htmlContent:
          '''
      <!DOCTYPE html>
      <html>
      <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Mã xác thực email</title>
      </head>
      <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
              <h1 style="color: white; margin: 0; font-size: 28px;">🎓 College Event Management</h1>
          </div>
          
          <div style="background: #f8f9fa; padding: 30px; border-radius: 0 0 10px 10px; border: 1px solid #e9ecef;">
              <h2 style="color: #495057; margin-top: 0;">Mã xác thực email</h2>
              
              <p style="font-size: 16px; margin-bottom: 25px;">
                  Chào bạn!<br>
                  Bạn đã yêu cầu tạo tài khoản trong hệ thống College Event Management.
              </p>
              
              <div style="background: white; padding: 25px; border-radius: 8px; text-align: center; margin: 25px 0; border: 2px solid #e9ecef;">
                  <p style="margin: 0 0 15px 0; font-size: 16px; color: #6c757d;">Mã xác thực của bạn là:</p>
                  <div style="background: #007bff; color: white; font-size: 32px; font-weight: bold; padding: 15px 25px; border-radius: 8px; letter-spacing: 5px; display: inline-block;">
                      $code
                  </div>
              </div>
              
              <div style="background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 20px 0;">
                  <p style="margin: 0; color: #856404; font-size: 14px;">
                      ⚠️ <strong>Lưu ý quan trọng:</strong>
                      <br>• Mã xác thực có hiệu lực trong <strong>10 phút</strong>
                      <br>• Mỗi mã chỉ sử dụng được <strong>1 lần</strong>
                      <br>• Không chia sẻ mã này với bất kỳ ai
                  </p>
              </div>
              
              <p style="font-size: 14px; color: #6c757d; margin-top: 25px;">
                  Nếu bạn không yêu cầu tạo tài khoản, vui lòng bỏ qua email này.
              </p>
          </div>
          
          <div style="text-align: center; margin-top: 20px; color: #6c757d; font-size: 12px;">
              <p>© 2024 College Event Management. All rights reserved.</p>
          </div>
      </body>
      </html>
      ''',
      textContent:
          'Your email verification code is: $code. The code is valid for 10 minutes.',
    );
  }

  EmailTemplate _buildEventRegistrationTemplate(Map<String, dynamic> data) {
    return EmailTemplate(
      subject:
          'Event Registration Successful - ${data['eventTitle'] ?? 'Event'}',
      htmlContent: EmailTemplates.buildEventRegistrationTemplate(data),
      textContent:
          'You have successfully registered for the event "${data['eventTitle'] ?? 'Event'}".',
    );
  }

  EmailTemplate _buildEventReminderTemplate(Map<String, dynamic> data) {
    return EmailTemplate(
      subject: 'Event Reminder - ${data['eventTitle'] ?? 'Event'}',
      htmlContent: EmailTemplates.buildEventReminderTemplate(data),
      textContent:
          'Reminder: Event "${data['eventTitle'] ?? 'Event'}" is coming up.',
    );
  }

  EmailTemplate _buildEventCancellationTemplate(Map<String, dynamic> data) {
    return EmailTemplate(
      subject: 'Event Cancelled - ${data['eventTitle'] ?? 'Event'}',
      htmlContent: EmailTemplates.buildEventCancellationTemplate(data),
      textContent:
          'Event "${data['eventTitle'] ?? 'Event'}" has been cancelled.',
    );
  }

  EmailTemplate _buildRegistrationApprovalTemplate(Map<String, dynamic> data) {
    return EmailTemplate(
      subject: 'Registration Approved - ${data['eventTitle'] ?? 'Event'}',
      htmlContent: EmailTemplates.buildRegistrationApprovalTemplate(data),
      textContent:
          'Your registration for event "${data['eventTitle'] ?? 'Event'}" has been approved.',
    );
  }

  EmailTemplate _buildRegistrationRejectionTemplate(Map<String, dynamic> data) {
    return EmailTemplate(
      subject: 'Registration Rejected - ${data['eventTitle'] ?? 'Event'}',
      htmlContent: EmailTemplates.buildRegistrationRejectionTemplate(data),
      textContent:
          'Your registration for event "${data['eventTitle'] ?? 'Event'}" has been rejected.',
    );
  }

  EmailTemplate _buildEventUpdateTemplate(Map<String, dynamic> data) {
    return EmailTemplate(
      subject: 'Event Update - ${data['eventTitle'] ?? 'Event'}',
      htmlContent: EmailTemplates.buildEventRegistrationTemplate(
        data,
      ), // Reuse template
      textContent: 'Event "${data['eventTitle'] ?? 'Event'}" has been updated.',
    );
  }

  EmailTemplate _buildWelcomeTemplate(Map<String, dynamic> data) {
    return EmailTemplate(
      subject: 'Welcome to College Event Management',
      htmlContent: EmailTemplates.buildWelcomeTemplate(data),
      textContent:
          'Welcome ${data['userName'] ?? 'you'} to College Event Management!',
    );
  }

  EmailTemplate _buildPasswordResetTemplate(Map<String, dynamic> data) {
    return EmailTemplate(
      subject: 'Password Reset - College Event Management',
      htmlContent: EmailTemplates.buildEventRegistrationTemplate(
        data,
      ), // Placeholder
      textContent: 'Password reset request for your account.',
    );
  }

  EmailTemplate _buildCoOrganizerInvitationTemplate(Map<String, dynamic> data) {
    return EmailTemplate(
      subject: 'Co-organizer Invitation - ${data['eventTitle'] ?? 'Event'}',
      htmlContent: EmailTemplates.buildEventRegistrationTemplate(
        data,
      ), // Placeholder
      textContent:
          'You are invited to be a co-organizer for event "${data['eventTitle'] ?? 'Event'}".',
    );
  }

  EmailTemplate _buildBulkAnnouncementTemplate(Map<String, dynamic> data) {
    return EmailTemplate(
      subject: 'Announcement - ${data['title'] ?? 'College Event Management'}',
      htmlContent: EmailTemplates.buildEventRegistrationTemplate(
        data,
      ), // Placeholder
      textContent:
          data['message'] ?? 'Announcement from College Event Management.',
    );
  }

  EmailTemplate _buildEventApprovalTemplate(Map<String, dynamic> data) {
    return EmailTemplate(
      subject: 'Event Approved - ${data['eventTitle'] ?? 'Event'}',
      htmlContent: EmailTemplates.buildEventApprovalTemplate(data),
      textContent:
          'Your event "${data['eventTitle'] ?? 'Event'}" has been approved.',
    );
  }

  EmailTemplate _buildEventRejectionTemplate(Map<String, dynamic> data) {
    return EmailTemplate(
      subject: 'Event Rejected - ${data['eventTitle'] ?? 'Event'}',
      htmlContent: EmailTemplates.buildEventRejectionTemplate(data),
      textContent:
          'Your event "${data['eventTitle'] ?? 'Event'}" has been rejected.',
    );
  }

  EmailTemplate _buildCertificateIssuedTemplate(Map<String, dynamic> data) {
    return EmailTemplate(
      subject: 'Certificate Issued - ${data['eventTitle'] ?? 'Event'}',
      htmlContent: EmailTemplates.buildCertificateIssuedTemplate(data),
      textContent:
          'Congratulations! You have received a certificate for participating in "${data['eventTitle'] ?? 'Event'}".',
    );
  }

  Future<bool> verifyCode(String email, String code) async {
    try {
      final now = DateTime.now();

      QuerySnapshot snapshot = await _firestore
          .collection(_verificationCollection)
          .where('email', isEqualTo: email.toLowerCase())
          .where('code', isEqualTo: code)
          .where('isUsed', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return false;
      }

      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();

      if (now.isAfter(expiresAt)) {
        return false; // Mã đã hết hạn
      }

      // Đánh dấu mã đã sử dụng
      await doc.reference.update({'isUsed': true});

      return true;
    } catch (e) {
      throw Exception('Error verifying code: ${e.toString()}');
    }
  }

  Future<void> cleanupExpiredCodes() async {
    try {
      final now = DateTime.now();

      QuerySnapshot snapshot = await _firestore
          .collection(_verificationCollection)
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .get();

      WriteBatch batch = _firestore.batch();
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error cleanup expired codes: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getVerificationStats() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_verificationCollection)
          .get();

      int totalCodes = snapshot.docs.length;
      int usedCodes = snapshot.docs
          .where(
            (doc) => (doc.data() as Map<String, dynamic>)['isUsed'] == true,
          )
          .length;
      int expiredCodes = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final expiresAt = (data['expiresAt'] as Timestamp).toDate();
        return DateTime.now().isAfter(expiresAt);
      }).length;

      return {
        'totalCodes': totalCodes,
        'usedCodes': usedCodes,
        'expiredCodes': expiredCodes,
        'activeCodes': totalCodes - usedCodes - expiredCodes,
      };
    } catch (e) {
      throw Exception('Error getting verification stats: ${e.toString()}');
    }
  }
}
