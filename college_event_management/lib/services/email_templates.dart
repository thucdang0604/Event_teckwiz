import 'package:intl/intl.dart';

class EmailTemplates {
  static String _getHeader() {
    return '''
    <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
        <h1 style="color: white; margin: 0; font-size: 28px;">🎓 College Event Management</h1>
    </div>
    ''';
  }

  static String _getFooter() {
    return '''
    <div style="text-align: center; margin-top: 20px; color: #6c757d; font-size: 12px;">
        <p>© 2024 College Event Management. All rights reserved.</p>
    </div>
    ''';
  }

  static String _getMainContent(String title, String content) {
    return '''
    <div style="background: #f8f9fa; padding: 30px; border-radius: 0 0 10px 10px; border: 1px solid #e9ecef;">
        <h2 style="color: #495057; margin-top: 0;">$title</h2>
        $content
    </div>
    ''';
  }

  static String buildEventRegistrationTemplate(Map<String, dynamic> data) {
    final eventTitle = data['eventTitle'] ?? 'Event';
    final eventDate = data['eventDate'] != null
        ? DateFormat(
            'dd/MM/yyyy HH:mm',
          ).format(DateTime.parse(data['eventDate']))
        : 'Not specified';
    final eventLocation = data['eventLocation'] ?? 'Not specified';
    final userName = data['userName'] ?? 'You';

    final content =
        '''
    <p style="font-size: 16px; margin-bottom: 25px;">
        Hello $userName!<br>
        You have successfully registered for the event.
    </p>
    
    <div style="background: white; padding: 25px; border-radius: 8px; margin: 25px 0; border: 2px solid #e9ecef;">
        <h3 style="color: #007bff; margin-top: 0;">📅 Event Information</h3>
        <p><strong>Event Name:</strong> $eventTitle</p>
        <p><strong>Date & Time:</strong> $eventDate</p>
        <p><strong>Location:</strong> $eventLocation</p>
    </div>
    
    <div style="background: #d4edda; border: 1px solid #c3e6cb; padding: 15px; border-radius: 5px; margin: 20px 0;">
        <p style="margin: 0; color: #155724; font-size: 14px;">
            ✅ <strong>Registration Successful!</strong><br>
            You will receive a notification when your registration is approved.
        </p>
    </div>
    
    <p style="font-size: 14px; color: #6c757d; margin-top: 25px;">
        Thank you for participating in our event!
    </p>
    ''';

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Event Registration Successful</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        ${_getHeader()}
        ${_getMainContent('Event Registration Successful', content)}
        ${_getFooter()}
    </body>
    </html>
    ''';
  }

  static String buildEventReminderTemplate(Map<String, dynamic> data) {
    final eventTitle = data['eventTitle'] ?? 'Event';
    final eventDate = data['eventDate'] != null
        ? DateFormat(
            'dd/MM/yyyy HH:mm',
          ).format(DateTime.parse(data['eventDate']))
        : 'Not specified';
    final eventLocation = data['eventLocation'] ?? 'Not specified';
    final userName = data['userName'] ?? 'You';
    final reminderType = data['reminderType'] ?? '24h';

    String reminderText = '';
    if (reminderType == '24h') {
      reminderText = 'Sự kiện sẽ diễn ra trong 24 giờ tới';
    } else if (reminderType == '1h') {
      reminderText = 'Sự kiện sẽ diễn ra trong 1 giờ tới';
    } else {
      reminderText = 'Sự kiện sắp diễn ra';
    }

    final content =
        '''
    <p style="font-size: 16px; margin-bottom: 25px;">
        Hello $userName!<br>
        $reminderText
    </p>
    
    <div style="background: white; padding: 25px; border-radius: 8px; margin: 25px 0; border: 2px solid #e9ecef;">
        <h3 style="color: #007bff; margin-top: 0;">📅 Event Information</h3>
        <p><strong>Event Name:</strong> $eventTitle</p>
        <p><strong>Date & Time:</strong> $eventDate</p>
        <p><strong>Location:</strong> $eventLocation</p>
    </div>
    
    <div style="background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 20px 0;">
        <p style="margin: 0; color: #856404; font-size: 14px;">
            ⏰ <strong>Nhắc nhở:</strong><br>
            Vui lòng có mặt đúng giờ để tham gia sự kiện.
        </p>
    </div>
    
    <p style="font-size: 14px; color: #6c757d; margin-top: 25px;">
        Chúc bạn có trải nghiệm tuyệt vời tại sự kiện!
    </p>
    ''';

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Nhắc nhở sự kiện</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        ${_getHeader()}
        ${_getMainContent('Nhắc nhở sự kiện', content)}
        ${_getFooter()}
    </body>
    </html>
    ''';
  }

  static String buildEventCancellationTemplate(Map<String, dynamic> data) {
    final eventTitle = data['eventTitle'] ?? 'Event';
    final eventDate = data['eventDate'] != null
        ? DateFormat(
            'dd/MM/yyyy HH:mm',
          ).format(DateTime.parse(data['eventDate']))
        : 'Not specified';
    final reason = data['reason'] ?? 'Lý do không được cung cấp';
    final userName = data['userName'] ?? 'You';

    final content =
        '''
    <p style="font-size: 16px; margin-bottom: 25px;">
        Hello $userName!<br>
        Chúng tôi rất tiếc phải thông báo rằng sự kiện đã bị hủy.
    </p>
    
    <div style="background: white; padding: 25px; border-radius: 8px; margin: 25px 0; border: 2px solid #e9ecef;">
        <h3 style="color: #dc3545; margin-top: 0;">❌ Event Information bị hủy</h3>
        <p><strong>Event Name:</strong> $eventTitle</p>
        <p><strong>Thời gian dự kiến:</strong> $eventDate</p>
        <p><strong>Lý do hủy:</strong> $reason</p>
    </div>
    
    <div style="background: #f8d7da; border: 1px solid #f5c6cb; padding: 15px; border-radius: 5px; margin: 20px 0;">
        <p style="margin: 0; color: #721c24; font-size: 14px;">
            ⚠️ <strong>Thông báo quan trọng:</strong><br>
            Nếu bạn đã thanh toán phí tham gia, chúng tôi sẽ hoàn tiền trong vòng 3-5 ngày làm việc.
        </p>
    </div>
    
    <p style="font-size: 14px; color: #6c757d; margin-top: 25px;">
        Chúng tôi xin lỗi vì sự bất tiện này và hy vọng được phục vụ bạn trong các sự kiện tiếp theo.
    </p>
    ''';

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Sự kiện đã bị hủy</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        ${_getHeader()}
        ${_getMainContent('Sự kiện đã bị hủy', content)}
        ${_getFooter()}
    </body>
    </html>
    ''';
  }

  static String buildRegistrationApprovalTemplate(Map<String, dynamic> data) {
    final eventTitle = data['eventTitle'] ?? 'Event';
    final eventDate = data['eventDate'] != null
        ? DateFormat(
            'dd/MM/yyyy HH:mm',
          ).format(DateTime.parse(data['eventDate']))
        : 'Not specified';
    final eventLocation = data['eventLocation'] ?? 'Not specified';
    final userName = data['userName'] ?? 'You';

    final content =
        '''
    <p style="font-size: 16px; margin-bottom: 25px;">
        Hello $userName!<br>
        Đăng ký tham gia sự kiện của bạn đã được duyệt.
    </p>
    
    <div style="background: white; padding: 25px; border-radius: 8px; margin: 25px 0; border: 2px solid #e9ecef;">
        <h3 style="color: #28a745; margin-top: 0;">✅ Event Information</h3>
        <p><strong>Event Name:</strong> $eventTitle</p>
        <p><strong>Date & Time:</strong> $eventDate</p>
        <p><strong>Location:</strong> $eventLocation</p>
    </div>
    
    <div style="background: #d4edda; border: 1px solid #c3e6cb; padding: 15px; border-radius: 5px; margin: 20px 0;">
        <p style="margin: 0; color: #155724; font-size: 14px;">
            🎉 <strong>Chúc mừng!</strong><br>
            Bạn đã được chấp nhận tham gia sự kiện. Vui lòng có mặt đúng giờ.
        </p>
    </div>
    
    <p style="font-size: 14px; color: #6c757d; margin-top: 25px;">
        Chúc bạn có trải nghiệm tuyệt vời tại sự kiện!
    </p>
    ''';

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Đăng ký được duyệt</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        ${_getHeader()}
        ${_getMainContent('Đăng ký được duyệt', content)}
        ${_getFooter()}
    </body>
    </html>
    ''';
  }

  static String buildRegistrationRejectionTemplate(Map<String, dynamic> data) {
    final eventTitle = data['eventTitle'] ?? 'Event';
    final reason = data['reason'] ?? 'Không đủ điều kiện tham gia';
    final userName = data['userName'] ?? 'You';

    final content =
        '''
    <p style="font-size: 16px; margin-bottom: 25px;">
        Hello $userName!<br>
        Chúng tôi rất tiếc phải thông báo rằng đăng ký tham gia sự kiện của bạn không được chấp nhận.
    </p>
    
    <div style="background: white; padding: 25px; border-radius: 8px; margin: 25px 0; border: 2px solid #e9ecef;">
        <h3 style="color: #dc3545; margin-top: 0;">❌ Event Information</h3>
        <p><strong>Event Name:</strong> $eventTitle</p>
        <p><strong>Lý do từ chối:</strong> $reason</p>
    </div>
    
    <div style="background: #f8d7da; border: 1px solid #f5c6cb; padding: 15px; border-radius: 5px; margin: 20px 0;">
        <p style="margin: 0; color: #721c24; font-size: 14px;">
            ℹ️ <strong>Thông tin:</strong><br>
            Nếu bạn đã thanh toán phí tham gia, chúng tôi sẽ hoàn tiền trong vòng 3-5 ngày làm việc.
        </p>
    </div>
    
    <p style="font-size: 14px; color: #6c757d; margin-top: 25px;">
        Chúng tôi hy vọng được phục vụ bạn trong các sự kiện tiếp theo.
    </p>
    ''';

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Đăng ký bị từ chối</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        ${_getHeader()}
        ${_getMainContent('Đăng ký bị từ chối', content)}
        ${_getFooter()}
    </body>
    </html>
    ''';
  }

  static String buildEventApprovalTemplate(Map<String, dynamic> data) {
    final eventTitle = data['eventTitle'] ?? 'Event';
    final eventDate = data['eventDate'] != null
        ? DateFormat(
            'dd/MM/yyyy HH:mm',
          ).format(DateTime.parse(data['eventDate']))
        : 'Not specified';
    final organizerName = data['organizerName'] ?? 'You';

    final content =
        '''
    <p style="font-size: 16px; margin-bottom: 25px;">
        Chào $organizerName!<br>
        Sự kiện của bạn đã được duyệt và xuất bản thành công.
    </p>
    
    <div style="background: white; padding: 25px; border-radius: 8px; margin: 25px 0; border: 2px solid #e9ecef;">
        <h3 style="color: #28a745; margin-top: 0;">✅ Event Information</h3>
        <p><strong>Event Name:</strong> $eventTitle</p>
        <p><strong>Date & Time:</strong> $eventDate</p>
    </div>
    
    <div style="background: #d4edda; border: 1px solid #c3e6cb; padding: 15px; border-radius: 5px; margin: 20px 0;">
        <p style="margin: 0; color: #155724; font-size: 14px;">
            🎉 <strong>Chúc mừng!</strong><br>
            Sự kiện của bạn đã được phê duyệt và hiện đang hiển thị cho tất cả người dùng.
        </p>
    </div>
    
    <p style="font-size: 14px; color: #6c757d; margin-top: 25px;">
        Chúc bạn tổ chức sự kiện thành công!
    </p>
    ''';

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Sự kiện được duyệt</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        ${_getHeader()}
        ${_getMainContent('Sự kiện được duyệt', content)}
        ${_getFooter()}
    </body>
    </html>
    ''';
  }

  static String buildEventRejectionTemplate(Map<String, dynamic> data) {
    final eventTitle = data['eventTitle'] ?? 'Event';
    final reason = data['reason'] ?? 'Không đáp ứng yêu cầu';
    final organizerName = data['organizerName'] ?? 'You';

    final content =
        '''
    <p style="font-size: 16px; margin-bottom: 25px;">
        Chào $organizerName!<br>
        Chúng tôi rất tiếc phải thông báo rằng sự kiện của bạn không được duyệt.
    </p>
    
    <div style="background: white; padding: 25px; border-radius: 8px; margin: 25px 0; border: 2px solid #e9ecef;">
        <h3 style="color: #dc3545; margin-top: 0;">❌ Event Information</h3>
        <p><strong>Event Name:</strong> $eventTitle</p>
        <p><strong>Lý do từ chối:</strong> $reason</p>
    </div>
    
    <div style="background: #f8d7da; border: 1px solid #f5c6cb; padding: 15px; border-radius: 5px; margin: 20px 0;">
        <p style="margin: 0; color: #721c24; font-size: 14px;">
            ℹ️ <strong>Thông tin:</strong><br>
            Bạn có thể chỉnh sửa sự kiện và gửi lại để xem xét.
        </p>
    </div>
    
    <p style="font-size: 14px; color: #6c757d; margin-top: 25px;">
        Chúng tôi hy vọng được hỗ trợ bạn trong các sự kiện tiếp theo.
    </p>
    ''';

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Sự kiện bị từ chối</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        ${_getHeader()}
        ${_getMainContent('Sự kiện bị từ chối', content)}
        ${_getFooter()}
    </body>
    </html>
    ''';
  }

  static String buildWelcomeTemplate(Map<String, dynamic> data) {
    final userName = data['userName'] ?? 'You';
    final userRole = data['userRole'] ?? 'Sinh viên';

    final content =
        '''
    <p style="font-size: 16px; margin-bottom: 25px;">
        Chào mừng $userName!<br>
        Chúc mừng bạn đã tham gia vào hệ thống College Event Management.
    </p>
    
    <div style="background: white; padding: 25px; border-radius: 8px; margin: 25px 0; border: 2px solid #e9ecef;">
        <h3 style="color: #007bff; margin-top: 0;">👋 Thông tin tài khoản</h3>
        <p><strong>Tên:</strong> $userName</p>
        <p><strong>Vai trò:</strong> $userRole</p>
    </div>
    
    <div style="background: #d1ecf1; border: 1px solid #bee5eb; padding: 15px; border-radius: 5px; margin: 20px 0;">
        <p style="margin: 0; color: #0c5460; font-size: 14px;">
            💡 <strong>Bắt đầu sử dụng:</strong><br>
            • Khám phá các sự kiện thú vị<br>
            • Đăng ký tham gia sự kiện<br>
            • Tạo sự kiện của riêng bạn (nếu là organizer)
        </p>
    </div>
    
    <p style="font-size: 14px; color: #6c757d; margin-top: 25px;">
        Chúc bạn có trải nghiệm tuyệt vời với hệ thống!
    </p>
    ''';

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Chào mừng đến với College Event Management</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        ${_getHeader()}
        ${_getMainContent('Chào mừng!', content)}
        ${_getFooter()}
    </body>
    </html>
    ''';
  }

  static String buildCertificateIssuedTemplate(Map<String, dynamic> data) {
    final eventTitle = data['eventTitle'] ?? 'Event';
    final userName = data['userName'] ?? 'You';
    final certificateNumber = data['certificateNumber'] ?? 'N/A';
    final issuedDate = data['issuedDate'] != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(data['issuedDate']))
        : DateFormat('dd/MM/yyyy').format(DateTime.now());

    final content =
        '''
    <p style="font-size: 16px; margin-bottom: 25px;">
        Congratulations $userName!<br>
        You have successfully received a certificate for participating in the event.
    </p>
    
    <div style="background: white; padding: 25px; border-radius: 8px; margin: 25px 0; border: 2px solid #e9ecef;">
        <h3 style="color: #28a745; margin-top: 0;">🏆 Certificate Information</h3>
        <p><strong>Event Name:</strong> $eventTitle</p>
        <p><strong>Certificate Number:</strong> $certificateNumber</p>
        <p><strong>Issued Date:</strong> $issuedDate</p>
    </div>
    
    <div style="background: #d4edda; border: 1px solid #c3e6cb; padding: 15px; border-radius: 5px; margin: 20px 0;">
        <p style="margin: 0; color: #155724; font-size: 14px;">
            🎉 <strong>Congratulations!</strong><br>
            This certificate recognizes your participation and achievement in the event.
        </p>
    </div>
    
    <p style="font-size: 14px; color: #6c757d; margin-top: 25px;">
        Thank you for your participation and we look forward to seeing you in future events!
    </p>
    ''';

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Certificate Issued - College Event Management</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        ${_getHeader()}
        ${_getMainContent('Certificate Issued', content)}
        ${_getFooter()}
    </body>
    </html>
    ''';
  }
}
