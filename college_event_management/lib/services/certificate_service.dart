import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/certificate_model.dart';
import '../models/certificate_template_model.dart';
import '../constants/app_constants.dart';
import 'notification_service.dart';
import 'unified_notification_service.dart';

class CertificateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Tạo chứng chỉ cho sinh viên sau khi hoàn thành sự kiện
  Future<String> generateCertificate({
    required String registrationId,
    required String eventId,
    required String userId,
    required String userName,
    required String userEmail,
    required String eventTitle,
    required String issuedBy,
    required String issuedByName,
  }) async {
    try {
      // Kiểm tra xem đã có chứng chỉ chưa
      final existingCertificate = await _firestore
          .collection('certificates')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      if (existingCertificate.docs.isNotEmpty) {
        throw Exception('Certificate already exists for this event');
      }

      // Lấy template mặc định
      final defaultTemplate = await getDefaultTemplate();
      if (defaultTemplate == null) {
        throw Exception('No default certificate template found');
      }

      // Tạo số chứng chỉ duy nhất
      final certificateNumber = _generateCertificateNumber();

      // Tạo URL chứng chỉ (trong thực tế sẽ tạo file PDF hoặc hình ảnh)
      final certificateUrl = await _generateCertificateImage(
        template: defaultTemplate,
        recipientName: userName,
        eventTitle: eventTitle,
        issuedDate: DateTime.now(),
        certificateNumber: certificateNumber,
        issuedBy: issuedByName,
      );

      // Tạo model chứng chỉ
      final certificate = CertificateModel(
        id: _uuid.v4(),
        eventId: eventId,
        eventTitle: eventTitle,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        templateId: defaultTemplate.id,
        certificateNumber: certificateNumber,
        certificateUrl: certificateUrl,
        issuedBy: issuedBy,
        issuedByName: issuedByName,
        issuedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      // Lưu vào Firestore
      await _firestore
          .collection('certificates')
          .doc(certificate.id)
          .set(certificate.toFirestore());

      // Gửi thông báo cho sinh viên
      try {
        await UnifiedNotificationService().sendUnifiedNotification(
          userId: userId,
          title: 'Certificate Issued',
          body:
              'You have received a certificate for participating in "$eventTitle"',
          type: NotificationType.certificateIssued,
          data: {
            'eventId': eventId,
            'eventTitle': eventTitle,
            'certificateId': certificate.id,
            'certificateNumber': certificateNumber,
            'userName': userName,
          },
          priority: NotificationPriority.high,
        );
        print('✅ Certificate notification sent to user: $userId');
      } catch (notificationError) {
        print('❌ Error sending certificate notification: $notificationError');
      }

      return certificate.id;
    } catch (e) {
      throw Exception('Error generating certificate: ${e.toString()}');
    }
  }

  // Lấy danh sách chứng chỉ của một sinh viên
  Future<List<CertificateModel>> getUserCertificates(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('certificates')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('issuedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CertificateModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error getting user certificates: ${e.toString()}');
    }
  }

  // Stream chứng chỉ của sinh viên
  Stream<List<CertificateModel>> getUserCertificatesStream(String userId) {
    return _firestore
        .collection('certificates')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('issuedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CertificateModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Lấy chứng chỉ theo ID
  Future<CertificateModel?> getCertificateById(String certificateId) async {
    try {
      final doc = await _firestore
          .collection('certificates')
          .doc(certificateId)
          .get();

      if (doc.exists) {
        return CertificateModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting certificate: ${e.toString()}');
    }
  }

  // Lấy template mặc định
  Future<CertificateTemplateModel?> getDefaultTemplate() async {
    try {
      final snapshot = await _firestore
          .collection('certificate_templates')
          .where('isDefault', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return CertificateTemplateModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting default template: ${e.toString()}');
    }
  }

  // Lấy tất cả template
  Future<List<CertificateTemplateModel>> getAllTemplates() async {
    try {
      final snapshot = await _firestore
          .collection('certificate_templates')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CertificateTemplateModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error getting templates: ${e.toString()}');
    }
  }

  // Tạo template mới
  Future<String> createTemplate(CertificateTemplateModel template) async {
    try {
      final docRef = await _firestore
          .collection('certificate_templates')
          .add(template.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Error creating template: ${e.toString()}');
    }
  }

  // Cập nhật template
  Future<void> updateTemplate(
    String templateId,
    CertificateTemplateModel template,
  ) async {
    try {
      await _firestore
          .collection('certificate_templates')
          .doc(templateId)
          .update(template.toFirestore());
    } catch (e) {
      throw Exception('Error updating template: ${e.toString()}');
    }
  }

  // Xóa template
  Future<void> deleteTemplate(String templateId) async {
    try {
      await _firestore
          .collection('certificate_templates')
          .doc(templateId)
          .update({
            'isActive': false,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      throw Exception('Error deleting template: ${e.toString()}');
    }
  }

  // Tạo template mặc định nếu chưa có
  Future<void> createDefaultTemplateIfNotExists() async {
    try {
      final existingDefault = await getDefaultTemplate();
      if (existingDefault != null) return;

      final defaultTemplate = CertificateTemplateModel(
        id: _uuid.v4(),
        name: 'Default Certificate Template',
        description: 'Default template for event certificates',
        templateUrl: 'assets/certificates/default_template.png',
        backgroundColor: '#FFFFFF',
        textColor: '#000000',
        titleFont: 'Arial',
        bodyFont: 'Arial',
        signatureFont: 'Arial',
        titleFontSize: 24.0,
        bodyFontSize: 16.0,
        signatureFontSize: 14.0,
        titlePosition: {'x': 0.5, 'y': 0.2},
        recipientNamePosition: {'x': 0.5, 'y': 0.4},
        eventTitlePosition: {'x': 0.5, 'y': 0.5},
        issuedDatePosition: {'x': 0.5, 'y': 0.6},
        signaturePosition: {'x': 0.7, 'y': 0.8},
        certificateNumberPosition: {'x': 0.1, 'y': 0.9},
        createdBy: 'system',
        createdByName: 'System',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        isDefault: true,
      );

      await _firestore
          .collection('certificate_templates')
          .doc(defaultTemplate.id)
          .set(defaultTemplate.toFirestore());

      print('✅ Default certificate template created');
    } catch (e) {
      print('❌ Error creating default template: $e');
    }
  }

  // Tạo số chứng chỉ duy nhất
  String _generateCertificateNumber() {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final random = (DateTime.now().millisecondsSinceEpoch % 10000)
        .toString()
        .padLeft(4, '0');

    return 'CERT-$year$month$day-$random';
  }

  // Tạo hình ảnh chứng chỉ (mock implementation)
  Future<String> _generateCertificateImage({
    required CertificateTemplateModel template,
    required String recipientName,
    required String eventTitle,
    required DateTime issuedDate,
    required String certificateNumber,
    required String issuedBy,
  }) async {
    // Trong thực tế, đây sẽ là logic tạo PDF hoặc hình ảnh
    // Sử dụng template để tạo chứng chỉ với thông tin được điền vào

    // Mock: trả về URL giả lập
    final mockUrl = 'https://example.com/certificates/$certificateNumber.pdf';

    // Trong thực tế, có thể sử dụng:
    // - pdf package để tạo PDF
    // - image package để tạo hình ảnh
    // - Canvas API để vẽ chứng chỉ

    return mockUrl;
  }

  // Kiểm tra xem sinh viên có đủ điều kiện nhận chứng chỉ không
  Future<bool> isEligibleForCertificate({
    required String eventId,
    required String userId,
  }) async {
    try {
      // Kiểm tra xem đã có chứng chỉ chưa
      final existingCertificate = await _firestore
          .collection('certificates')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      if (existingCertificate.docs.isNotEmpty) {
        return false; // Đã có chứng chỉ
      }

      // Kiểm tra đăng ký và trạng thái tham dự
      final registrationSnapshot = await _firestore
          .collection(AppConstants.registrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: AppConstants.registrationApproved)
          .get();

      if (registrationSnapshot.docs.isEmpty) {
        return false; // Không có đăng ký được duyệt
      }

      final registrationData = registrationSnapshot.docs.first.data();

      // Kiểm tra xem đã check-in và check-out chưa
      final hasCheckedIn = registrationData['attended'] == true;
      final hasCheckedOut = registrationData['checkedOutAt'] != null;

      return hasCheckedIn && hasCheckedOut;
    } catch (e) {
      print('Error checking certificate eligibility: $e');
      return false;
    }
  }

  // Issue certificates for all eligible participants in an event
  Future<int> issueForEvent(String eventId) async {
    try {
      // Get all approved registrations for the event
      final registrationsSnapshot = await _firestore
          .collection(AppConstants.registrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: AppConstants.registrationApproved)
          .get();

      int issuedCount = 0;

      for (final doc in registrationsSnapshot.docs) {
        final regData = doc.data();
        final String userId = regData['userId'] ?? '';
        final String userName = regData['userName'] ?? '';
        final String userEmail = regData['userEmail'] ?? '';

        if (userId.isEmpty) continue;

        // Check if eligible for certificate
        final isEligible = await isEligibleForCertificate(
          eventId: eventId,
          userId: userId,
        );

        if (!isEligible) continue;

        // Check if certificate already exists
        final existingCert = await _firestore
            .collection(AppConstants.certificatesCollection)
            .where('registrationId', isEqualTo: doc.id)
            .limit(1)
            .get();

        if (existingCert.docs.isNotEmpty) continue;

        // Get event details
        final eventDoc = await _firestore
            .collection(AppConstants.eventsCollection)
            .doc(eventId)
            .get();

        if (!eventDoc.exists) continue;

        final eventData = eventDoc.data()!;
        final String eventTitle = eventData['title'] ?? '';
        final String organizerId = eventData['organizerId'] ?? '';
        final String organizerName = eventData['organizerName'] ?? '';

        // Generate certificate
        await generateCertificate(
          registrationId: doc.id,
          eventId: eventId,
          userId: userId,
          userName: userName,
          userEmail: userEmail,
          eventTitle: eventTitle,
          issuedBy: organizerId,
          issuedByName: organizerName,
        );

        issuedCount++;
      }

      return issuedCount;
    } catch (e) {
      throw Exception('Error issuing certificates for event: ${e.toString()}');
    }
  }

  // Alias for issueForEvent for backward compatibility
  Future<int> issueCertificatesForEvent(String eventId) async {
    return await issueForEvent(eventId);
  }
}
