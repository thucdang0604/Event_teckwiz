import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _verificationCollection = 'email_verifications';

  // Email configuration
  SmtpServer? _smtpServer;
  String _fromEmail = 'noreply@example.com';

  EmailService() {
    _initializeEmail();
  }

  void _initializeEmail() {
    try {
      final gmailPassword = dotenv.env['GMAIL_APP_PASSWORD'];
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
      throw Exception('Lỗi gửi mã xác thực: ${e.toString()}');
    }
  }

  Future<void> _sendEmailWithSendGrid(String email, String code) async {
    try {
      if (_smtpServer == null) {
        throw Exception('SMTP server not initialized');
      }

      final message = Message()
        ..from = Address(_fromEmail, 'College Event Management')
        ..recipients.add(email)
        ..subject = 'Mã xác thực email - College Event Management'
        ..html = _buildEmailTemplate(code);

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

  String _buildEmailTemplate(String code) {
    return '''
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
    ''';
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
      throw Exception('Lỗi xác thực mã: ${e.toString()}');
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
      print('Lỗi cleanup expired codes: ${e.toString()}');
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
      throw Exception('Lỗi lấy thống kê xác thực: ${e.toString()}');
    }
  }
}
