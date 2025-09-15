import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/registration_model.dart';
import '../models/support_registration_model.dart';
import '../models/event_model.dart';
import '../constants/app_constants.dart';
import 'notification_service.dart';
import 'event_service.dart';
import 'payment_service.dart';
import 'unified_notification_service.dart';
import 'certificate_service.dart';

class RegistrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PaymentService _paymentService = PaymentService();
  final UnifiedNotificationService _unifiedNotificationService =
      UnifiedNotificationService();
  final CertificateService _certificateService = CertificateService();

  // Đăng ký tham gia sự kiện
  Future<String> registerForEvent({
    required String eventId,
    required String userId,
    required String userEmail,
    required String userName,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      // Lấy thông tin sự kiện để kiểm tra điều kiện đăng ký
      EventModel? event = await EventService().getEventById(eventId);
      if (event == null) {
        throw Exception('Event not found');
      }

      // Kiểm tra thời gian đăng ký
      final now = DateTime.now();
      final eventStart = event.startDate.toLocal();
      final eventEnd = event.endDate.toLocal();
      final registrationDeadline = event.registrationDeadline.toLocal();

      // Không cho phép đăng ký nếu sự kiện chưa được publish
      if (!event.isPublished) {
        throw Exception('This event is not yet published');
      }

      // Không cho phép đăng ký nếu đã qua hạn đăng ký
      if (now.isAfter(registrationDeadline)) {
        throw Exception('Registration deadline has passed');
      }

      // Không cho phép đăng ký nếu sự kiện đang diễn ra
      if (eventStart.isBefore(now) && eventEnd.isAfter(now)) {
        throw Exception('Registration is not available during the event');
      }

      // Không cho phép đăng ký nếu sự kiện đã bắt đầu
      if (eventStart.isBefore(now)) {
        throw Exception(
          'Registration is not available after the event has started',
        );
      }

      // Không cho phép đăng ký nếu sự kiện đã đầy
      if (event.isFull) {
        throw Exception(
          'This event is full. No more participants can be accepted',
        );
      }

      // Kiểm tra xem đã đăng ký chưa (chỉ kiểm tra đăng ký active)
      bool alreadyRegistered = await isUserRegisteredForEvent(eventId, userId);
      if (alreadyRegistered) {
        throw Exception('You have already registered for this event');
      }

      // Kiểm tra xem có đăng ký cancelled không (đơn giản hóa để tránh lỗi index)
      await _firestore
          .collection(AppConstants.registrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: AppConstants.registrationCancelled)
          .get();

      // Tạo mã QR cho đăng ký
      String qrCode =
          'EVENT_${eventId}_USER_${userId}_${DateTime.now().millisecondsSinceEpoch}';

      RegistrationModel registration = RegistrationModel(
        id: '', // Sẽ được tạo tự động
        eventId: eventId,
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        status: AppConstants.registrationPending,
        registeredAt: DateTime.now(),
        additionalInfo: additionalInfo,
        qrCode: qrCode,
      );

      DocumentReference docRef = await _firestore
          .collection(AppConstants.registrationsCollection)
          .add(registration.toFirestore());

      // Gửi unified notification xác nhận đăng ký
      try {
        final event = await EventService().getEventById(eventId);
        if (event != null) {
          await _unifiedNotificationService.sendUnifiedNotification(
            userId: userId,
            title: 'Đăng ký sự kiện thành công',
            body: 'Bạn đã đăng ký tham gia sự kiện "${event.title}" thành công',
            type: NotificationType.registrationConfirmed,
            data: {
              'eventId': eventId,
              'eventTitle': event.title,
              'eventDate': event.startDate.toIso8601String(),
              'eventLocation': event.location,
              'userName': userName,
            },
            priority: NotificationPriority.normal,
          );
          print('✅ Unified notification sent to user: $userId');
        }
      } catch (notificationError) {
        print('❌ Error sending unified notification: $notificationError');
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Lỗi đăng ký sự kiện: ${e.toString()}');
    }
  }

  // Đăng ký tham gia sự kiện với thanh toán
  Future<String> registerForEventWithPayment({
    required String eventId,
    required String userId,
    required String userEmail,
    required String userName,
    required String paymentMethod,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      // Lấy thông tin sự kiện để kiểm tra phí
      EventModel? event = await EventService().getEventById(eventId);
      if (event == null) {
        throw Exception('Event not found');
      }

      // Kiểm tra thời gian đăng ký
      final now = DateTime.now();
      final eventStart = event.startDate.toLocal();
      final eventEnd = event.endDate.toLocal();
      final registrationDeadline = event.registrationDeadline.toLocal();

      // Không cho phép đăng ký nếu sự kiện chưa được publish
      if (!event.isPublished) {
        throw Exception('This event is not yet published');
      }

      // Không cho phép đăng ký nếu đã qua hạn đăng ký
      if (now.isAfter(registrationDeadline)) {
        throw Exception('Registration deadline has passed');
      }

      // Không cho phép đăng ký nếu sự kiện đang diễn ra
      if (eventStart.isBefore(now) && eventEnd.isAfter(now)) {
        throw Exception('Registration is not available during the event');
      }

      // Không cho phép đăng ký nếu sự kiện đã bắt đầu
      if (eventStart.isBefore(now)) {
        throw Exception(
          'Registration is not available after the event has started',
        );
      }

      // Không cho phép đăng ký nếu sự kiện đã đầy
      if (event.isFull) {
        throw Exception(
          'This event is full. No more participants can be accepted',
        );
      }

      // Kiểm tra xem đã đăng ký chưa (chỉ kiểm tra đăng ký active)
      bool alreadyRegistered = await isUserRegisteredForEvent(eventId, userId);
      if (alreadyRegistered) {
        throw Exception('You have already registered for this event');
      }

      // Kiểm tra xem có đăng ký cancelled không (đơn giản hóa để tránh lỗi index)
      QuerySnapshot cancelledRegistrations = await _firestore
          .collection(AppConstants.registrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: AppConstants.registrationCancelled)
          .get();

      if (cancelledRegistrations.docs.isNotEmpty) {
        // Chỉ kiểm tra đăng ký cancelled gần đây nhất
        var latestCancelled = cancelledRegistrations.docs.first;
        var data = latestCancelled.data() as Map<String, dynamic>;
        if (data['updatedAt'] != null) {
          DateTime updatedAt = (data['updatedAt'] as Timestamp).toDate();
          if (updatedAt.isAfter(
            DateTime.now().subtract(const Duration(minutes: 1)),
          )) {
            throw Exception(
              'Bạn vừa hủy đăng ký. Vui lòng đợi 1 phút trước khi đăng ký lại',
            );
          }
        }
      }

      // Tạo mã QR cho đăng ký
      String qrCode =
          'EVENT_${eventId}_USER_${userId}_${DateTime.now().millisecondsSinceEpoch}';

      // Xử lý thanh toán nếu sự kiện có phí
      String? paymentId;
      DateTime? paidAt;
      double? amountPaid;

      if (_paymentService.requiresPayment(event)) {
        Map<String, dynamic> paymentResult = await _paymentService
            .processMockPayment(
              eventId: eventId,
              userId: userId,
              userEmail: userEmail,
              userName: userName,
              amount: event.price!,
              paymentMethod: paymentMethod,
            );

        if (!paymentResult['success']) {
          throw Exception('Thanh toán thất bại');
        }

        paymentId = paymentResult['paymentId'];
        paidAt = paymentResult['paidAt'];
        amountPaid = paymentResult['amount'];
      }

      // Tự động approve nếu đã thanh toán
      String registrationStatus = paymentId != null
          ? AppConstants.registrationApproved
          : AppConstants.registrationPending;

      RegistrationModel registration = RegistrationModel(
        id: '', // Sẽ được tạo tự động
        eventId: eventId,
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        status: registrationStatus,
        registeredAt: DateTime.now(),
        additionalInfo: additionalInfo,
        qrCode: qrCode,
        isPaid: paymentId != null,
        paidAt: paidAt,
        paymentId: paymentId,
        paymentMethod: paymentId != null ? paymentMethod : null,
        amountPaid: amountPaid,
        // Tự động set thời gian approve nếu đã thanh toán
        approvedAt: paymentId != null ? DateTime.now() : null,
        approvedBy: paymentId != null ? 'system' : null,
      );

      DocumentReference docRef = await _firestore
          .collection(AppConstants.registrationsCollection)
          .add(registration.toFirestore());

      // Gửi unified notification xác nhận đăng ký
      try {
        await _unifiedNotificationService.sendUnifiedNotification(
          userId: userId,
          title: 'Đăng ký sự kiện thành công',
          body: 'Bạn đã đăng ký tham gia sự kiện "${event.title}" thành công',
          type: NotificationType.registrationConfirmed,
          data: {
            'eventId': eventId,
            'eventTitle': event.title,
            'eventDate': event.startDate.toIso8601String(),
            'eventLocation': event.location,
            'userName': userName,
            'isPaid': paymentId != null,
            'amountPaid': amountPaid,
          },
          priority: NotificationPriority.normal,
        );
        print('✅ Unified notification sent to user: $userId');
      } catch (notificationError) {
        print('❌ Error sending unified notification: $notificationError');
      }

      // If auto-approved, refresh event participant count
      if (paymentId != null) {
        try {
          await _updateEventParticipantCountByEvent(eventId);
        } catch (_) {}
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Lỗi đăng ký sự kiện: ${e.toString()}');
    }
  }

  // Hủy đăng ký
  Future<void> cancelRegistration(String registrationId) async {
    try {
      // Lấy thông tin đăng ký trước khi hủy
      DocumentSnapshot registrationDoc = await _firestore
          .collection(AppConstants.registrationsCollection)
          .doc(registrationId)
          .get();

      if (!registrationDoc.exists) {
        throw Exception('Đăng ký không tồn tại');
      }

      Map<String, dynamic> registrationData =
          registrationDoc.data() as Map<String, dynamic>;
      String userId = registrationData['userId'] ?? '';
      String eventId = registrationData['eventId'] ?? '';

      // Lấy thông tin sự kiện để xác định điều kiện hoàn tiền
      EventModel? event = await EventService().getEventById(eventId);

      // Kiểm tra thời gian sự kiện trước khi cho phép hủy
      if (event != null) {
        final now = DateTime.now();
        final eventStart = event.startDate.toLocal();
        final eventEnd = event.endDate.toLocal();

        // Không cho phép hủy nếu sự kiện đang diễn ra
        if (eventStart.isBefore(now) && eventEnd.isAfter(now)) {
          throw Exception(
            'Cannot cancel registration during the event. Please contact the organizer.',
          );
        }

        // Không cho phép hủy nếu sự kiện đã bắt đầu
        if (eventStart.isBefore(now)) {
          throw Exception(
            'Cannot cancel registration after the event has started. Please contact the organizer.',
          );
        }
      }

      // Cập nhật trạng thái đăng ký
      await _firestore
          .collection(AppConstants.registrationsCollection)
          .doc(registrationId)
          .update({
            'status': AppConstants.registrationCancelled,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      // Update event participant count after cancellation
      if (eventId.isNotEmpty) {
        await _updateEventParticipantCountByEvent(eventId);
      }

      // Xử lý hoàn tiền nếu đã thanh toán và sự kiện chưa bắt đầu và chưa tham dự
      if ((registrationData['isPaid'] == true) &&
          (registrationData['attended'] != true)) {
        final DateTime now = DateTime.now();
        final bool eventNotStarted = event == null
            ? true
            : now.isBefore(event.startDate);
        if (eventNotStarted) {
          try {
            final double amount = (registrationData['amountPaid'] ?? 0)
                .toDouble();
            final String paymentId = registrationData['paymentId'] ?? '';
            if (amount > 0 && paymentId.isNotEmpty) {
              final refund = await _paymentService.processMockRefund(
                paymentId: paymentId,
                amount: amount,
                method: registrationData['paymentMethod'] ?? 'bank_transfer',
              );
              await _firestore
                  .collection(AppConstants.registrationsCollection)
                  .doc(registrationId)
                  .update({
                    'isRefunded': true,
                    'refundedAt': Timestamp.fromDate(refund['refundedAt']),
                    'refundId': refund['refundId'],
                    'refundMethod': refund['refundMethod'],
                    'refundAmount': refund['refundAmount'],
                  });
            }
          } catch (e) {
            print('Refund error: $e');
          }
        }
      }

      // Lấy thông tin sự kiện để gửi thông báo
      try {
        if (event != null) {
          // Gửi thông báo đến user
          await NotificationService.sendNotificationToUser(
            userId: userId,
            title: 'Đăng ký sự kiện đã được hủy',
            body: 'Bạn đã hủy đăng ký sự kiện "${event.title}" thành công.',
            type: NotificationType.registrationCancelled,
            data: {
              'eventId': eventId,
              'registrationId': registrationId,
              'eventTitle': event.title,
            },
          );

          // Gửi thông báo đến admin
          await NotificationService.sendNotificationToAdmin(
            title: 'Sinh viên hủy đăng ký sự kiện',
            body: 'Một sinh viên đã hủy đăng ký sự kiện "${event.title}"',
            type: NotificationType.registrationCancelled,
            data: {
              'eventId': eventId,
              'registrationId': registrationId,
              'eventTitle': event.title,
              'userId': userId,
            },
          );
        }
      } catch (notificationError) {
        print('Error sending notification: $notificationError');
        // Không throw error vì việc hủy đăng ký đã thành công
      }
    } catch (e) {
      throw Exception('Lỗi hủy đăng ký: ${e.toString()}');
    }
  }

  // Kiểm tra xem người dùng đã đăng ký sự kiện chưa
  Future<bool> isUserRegisteredForEvent(String eventId, String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.registrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .where(
            'status',
            whereIn: [
              AppConstants.registrationPending,
              AppConstants.registrationApproved,
            ],
          )
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Lỗi kiểm tra đăng ký: ${e.toString()}');
    }
  }

  // Lấy đăng ký của người dùng cho một sự kiện (ưu tiên đăng ký active)
  Future<RegistrationModel?> getUserRegistrationForEvent(
    String eventId,
    String userId,
  ) async {
    try {
      // Tránh yêu cầu composite index: bỏ orderBy và xử lý sort phía client
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.registrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Map về model và sắp xếp theo registeredAt mới nhất
        final list = snapshot.docs
            .map((doc) => RegistrationModel.fromFirestore(doc))
            .toList();
        list.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));

        // Ưu tiên registration không bị huỷ
        final active = list.firstWhere(
          (r) => r.status != AppConstants.registrationCancelled,
          orElse: () => list.first,
        );
        return active;
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi lấy thông tin đăng ký: ${e.toString()}');
    }
  }

  // Lấy danh sách đăng ký của người dùng (chỉ đăng ký active)
  Future<List<RegistrationModel>> getUserRegistrations(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.registrationsCollection)
          .where('userId', isEqualTo: userId)
          .where(
            'status',
            whereIn: [
              AppConstants.registrationPending,
              AppConstants.registrationApproved,
            ],
          )
          .get();

      final registrations = snapshot.docs
          .map((doc) => RegistrationModel.fromFirestore(doc))
          .toList();
      registrations.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
      return registrations;
    } catch (e) {
      throw Exception('Lỗi lấy danh sách đăng ký: ${e.toString()}');
    }
  }

  // Stream đăng ký của người dùng (chỉ đăng ký active)
  Stream<List<RegistrationModel>> getUserRegistrationsStream(String userId) {
    return _firestore
        .collection(AppConstants.registrationsCollection)
        .where('userId', isEqualTo: userId)
        .where(
          'status',
          whereIn: [
            AppConstants.registrationPending,
            AppConstants.registrationApproved,
          ],
        )
        .snapshots()
        .map((snapshot) {
          final registrations = snapshot.docs
              .map((d) => RegistrationModel.fromFirestore(d))
              .toList();
          registrations.sort(
            (a, b) => b.registeredAt.compareTo(a.registeredAt),
          );
          return registrations;
        });
  }

  // Lấy tất cả đăng ký của người dùng (bao gồm cancelled) - dành cho admin
  Future<List<RegistrationModel>> getAllUserRegistrations(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.registrationsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final registrations = snapshot.docs
          .map((doc) => RegistrationModel.fromFirestore(doc))
          .toList();
      registrations.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
      return registrations;
    } catch (e) {
      throw Exception('Lỗi lấy tất cả đăng ký: ${e.toString()}');
    }
  }

  // Lấy danh sách đăng ký của một sự kiện
  Future<List<RegistrationModel>> getEventRegistrations(String eventId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.registrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .get();

      final list = snapshot.docs
          .map((doc) => RegistrationModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
      return list;
    } catch (e) {
      throw Exception('Lỗi lấy danh sách đăng ký sự kiện: ${e.toString()}');
    }
  }

  // Duyệt đăng ký
  Future<void> approveRegistration(
    String registrationId,
    String approvedBy,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.registrationsCollection)
          .doc(registrationId)
          .update({
            'status': AppConstants.registrationApproved,
            'approvedAt': Timestamp.fromDate(DateTime.now()),
            'approvedBy': approvedBy,
          });

      // Update event participant count based on approved registrations
      try {
        final regDoc = await _firestore
            .collection(AppConstants.registrationsCollection)
            .doc(registrationId)
            .get();
        final data = regDoc.data();
        final String eventId = data?['eventId'] ?? '';
        if (eventId.isNotEmpty) {
          await _updateEventParticipantCountByEvent(eventId);
        }
      } catch (_) {}
    } catch (e) {
      throw Exception('Lỗi duyệt đăng ký: ${e.toString()}');
    }
  }

  // Từ chối đăng ký
  Future<void> rejectRegistration(
    String registrationId,
    String rejectedBy,
    String reason,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.registrationsCollection)
          .doc(registrationId)
          .update({
            'status': AppConstants.registrationRejected,
            'approvedAt': Timestamp.fromDate(DateTime.now()),
            'approvedBy': rejectedBy,
            'rejectionReason': reason,
          });

      // Recalculate participant count in case a previously approved reg is changed
      try {
        final regDoc = await _firestore
            .collection(AppConstants.registrationsCollection)
            .doc(registrationId)
            .get();
        final data = regDoc.data();
        final String eventId = data?['eventId'] ?? '';
        if (eventId.isNotEmpty) {
          await _updateEventParticipantCountByEvent(eventId);
        }
      } catch (_) {}
    } catch (e) {
      throw Exception('Lỗi từ chối đăng ký: ${e.toString()}');
    }
  }

  // Đánh dấu tham dự
  Future<void> markAttendance(String registrationId) async {
    try {
      await _firestore
          .collection(AppConstants.registrationsCollection)
          .doc(registrationId)
          .update({
            'attended': true,
            'attendedAt': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      throw Exception('Lỗi đánh dấu tham dự: ${e.toString()}');
    }
  }

  // Đánh dấu checkout
  Future<void> markCheckout(String registrationId) async {
    try {
      await _firestore
          .collection(AppConstants.registrationsCollection)
          .doc(registrationId)
          .update({'checkedOutAt': Timestamp.fromDate(DateTime.now())});

      // Ensure participant count remains consistent (no change on checkout)
      try {
        final regDoc = await _firestore
            .collection(AppConstants.registrationsCollection)
            .doc(registrationId)
            .get();
        final data = regDoc.data();
        final String eventId = data?['eventId'] ?? '';
        if (eventId.isNotEmpty) {
          await _updateEventParticipantCountByEvent(eventId);
        }
      } catch (_) {}

      // Tự động tạo chứng chỉ sau khi checkout
      try {
        await _generateCertificateAfterCheckout(registrationId);
      } catch (certError) {
        print('Error generating certificate after checkout: $certError');
        // Không throw error vì checkout đã thành công
      }
    } catch (e) {
      throw Exception('Lỗi checkout: ${e.toString()}');
    }
  }

  // Tạo chứng chỉ sau khi checkout
  Future<void> _generateCertificateAfterCheckout(String registrationId) async {
    try {
      // Lấy thông tin đăng ký
      final regDoc = await _firestore
          .collection(AppConstants.registrationsCollection)
          .doc(registrationId)
          .get();

      if (!regDoc.exists) return;

      final regData = regDoc.data();
      final String eventId = regData?['eventId'] ?? '';
      final String userId = regData?['userId'] ?? '';
      final String userName = regData?['userName'] ?? '';
      final String userEmail = regData?['userEmail'] ?? '';

      if (eventId.isEmpty || userId.isEmpty) return;

      // Kiểm tra xem có đủ điều kiện nhận chứng chỉ không
      final isEligible = await _certificateService.isEligibleForCertificate(
        eventId: eventId,
        userId: userId,
      );

      if (!isEligible) return;

      // Lấy thông tin sự kiện
      final event = await EventService().getEventById(eventId);
      if (event == null) return;

      // Tạo chứng chỉ
      await _certificateService.generateCertificate(
        registrationId: registrationId,
        eventId: eventId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        eventTitle: event.title,
        issuedBy: event.organizerId,
        issuedByName: event.organizerName,
      );

      print('✅ Certificate generated for user $userId after checkout');
    } catch (e) {
      print('❌ Error in _generateCertificateAfterCheckout: $e');
      rethrow;
    }
  }

  // Helper: recalculate and update event.currentParticipants by counting approved registrations
  Future<void> _updateEventParticipantCountByEvent(String eventId) async {
    try {
      final approvedSnapshot = await _firestore
          .collection(AppConstants.registrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: AppConstants.registrationApproved)
          .get();

      final int count = approvedSnapshot.docs.length;
      await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId)
          .update({'currentParticipants': count});
    } catch (e) {
      // ignore errors
    }
  }

  // Lấy đăng ký theo QR code
  Future<RegistrationModel?> getRegistrationByQRCode(String qrCode) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.registrationsCollection)
          .where('qrCode', isEqualTo: qrCode)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return RegistrationModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi lấy đăng ký theo QR: ${e.toString()}');
    }
  }

  // ========== SUPPORT STAFF REGISTRATION METHODS ==========

  // Đăng ký làm người hỗ trợ
  Future<String> registerForSupportStaff({
    required String eventId,
    required String userId,
    required String userEmail,
    required String userName,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      // Lấy thông tin sự kiện để kiểm tra điều kiện đăng ký
      EventModel? event = await EventService().getEventById(eventId);
      if (event == null) {
        throw Exception('Event not found');
      }

      // Kiểm tra thời gian đăng ký
      final now = DateTime.now();
      final eventStart = event.startDate.toLocal();
      final eventEnd = event.endDate.toLocal();
      final registrationDeadline = event.registrationDeadline.toLocal();

      // Không cho phép đăng ký nếu sự kiện chưa được publish
      if (!event.isPublished) {
        throw Exception('This event is not yet published');
      }

      // Không cho phép đăng ký nếu đã qua hạn đăng ký
      if (now.isAfter(registrationDeadline)) {
        throw Exception('Registration deadline has passed');
      }

      // Không cho phép đăng ký nếu sự kiện đang diễn ra
      if (eventStart.isBefore(now) && eventEnd.isAfter(now)) {
        throw Exception('Registration is not available during the event');
      }

      // Không cho phép đăng ký nếu sự kiện đã bắt đầu
      if (eventStart.isBefore(now)) {
        throw Exception(
          'Registration is not available after the event has started',
        );
      }

      // Kiểm tra xem đã đăng ký chưa (cả participant và support)
      bool alreadyRegistered = await isUserRegisteredForEvent(eventId, userId);
      bool alreadySupportRegistered = await isUserRegisteredForSupport(
        eventId,
        userId,
      );

      if (alreadyRegistered || alreadySupportRegistered) {
        throw Exception('You have already registered for this event');
      }

      // Tạo mã QR cho đăng ký
      String qrCode =
          'SUPPORT_${eventId}_USER_${userId}_${DateTime.now().millisecondsSinceEpoch}';

      SupportRegistrationModel registration = SupportRegistrationModel(
        id: '', // Sẽ được tạo tự động
        eventId: eventId,
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        status: AppConstants.registrationPending,
        registeredAt: DateTime.now(),
        additionalInfo: additionalInfo,
        qrCode: qrCode,
      );

      DocumentReference docRef = await _firestore
          .collection('support_registrations')
          .add(registration.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Error registering for support staff: ${e.toString()}');
    }
  }

  // Kiểm tra xem người dùng đã đăng ký hỗ trợ chưa
  Future<bool> isUserRegisteredForSupport(String eventId, String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('support_registrations')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .where(
            'status',
            whereIn: [
              AppConstants.registrationPending,
              AppConstants.registrationApproved,
            ],
          )
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error checking support registration: ${e.toString()}');
    }
  }

  // Lấy đăng ký hỗ trợ của người dùng cho một sự kiện
  Future<SupportRegistrationModel?> getUserSupportRegistrationForEvent(
    String eventId,
    String userId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('support_registrations')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return SupportRegistrationModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting support registration: ${e.toString()}');
    }
  }

  // Hủy đăng ký hỗ trợ
  Future<void> cancelSupportRegistration(String registrationId) async {
    try {
      // Lấy thông tin đăng ký hỗ trợ trước khi hủy
      DocumentSnapshot registrationDoc = await _firestore
          .collection('support_registrations')
          .doc(registrationId)
          .get();

      if (!registrationDoc.exists) {
        throw Exception('Đăng ký hỗ trợ không tồn tại');
      }

      Map<String, dynamic> registrationData =
          registrationDoc.data() as Map<String, dynamic>;
      String userId = registrationData['userId'] ?? '';
      String eventId = registrationData['eventId'] ?? '';

      // Lấy thông tin sự kiện để kiểm tra thời gian
      EventModel? event = await EventService().getEventById(eventId);

      // Kiểm tra thời gian sự kiện trước khi cho phép hủy
      if (event != null) {
        final now = DateTime.now();
        final eventStart = event.startDate.toLocal();
        final eventEnd = event.endDate.toLocal();

        // Không cho phép hủy nếu sự kiện đang diễn ra
        if (eventStart.isBefore(now) && eventEnd.isAfter(now)) {
          throw Exception(
            'Cannot cancel support registration during the event. Please contact the organizer.',
          );
        }

        // Không cho phép hủy nếu sự kiện đã bắt đầu
        if (eventStart.isBefore(now)) {
          throw Exception(
            'Cannot cancel support registration after the event has started. Please contact the organizer.',
          );
        }
      }

      // Cập nhật trạng thái đăng ký hỗ trợ
      await _firestore
          .collection('support_registrations')
          .doc(registrationId)
          .update({
            'status': AppConstants.registrationCancelled,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      // Lấy thông tin sự kiện để gửi thông báo
      try {
        EventModel? event = await EventService().getEventById(eventId);
        if (event != null) {
          // Gửi thông báo đến user
          await NotificationService.sendNotificationToUser(
            userId: userId,
            title: 'Đăng ký hỗ trợ đã được hủy',
            body:
                'Bạn đã hủy đăng ký hỗ trợ sự kiện "${event.title}" thành công.',
            type: NotificationType.registrationCancelled,
            data: {
              'eventId': eventId,
              'registrationId': registrationId,
              'eventTitle': event.title,
              'isSupport': true,
            },
          );

          // Gửi thông báo đến admin
          await NotificationService.sendNotificationToAdmin(
            title: 'Sinh viên hủy đăng ký hỗ trợ',
            body:
                'Một sinh viên đã hủy đăng ký hỗ trợ sự kiện "${event.title}"',
            type: NotificationType.registrationCancelled,
            data: {
              'eventId': eventId,
              'registrationId': registrationId,
              'eventTitle': event.title,
              'userId': userId,
              'isSupport': true,
            },
          );
        }
      } catch (notificationError) {
        print('Error sending notification: $notificationError');
        // Không throw error vì việc hủy đăng ký đã thành công
      }
    } catch (e) {
      throw Exception('Error cancelling support registration: ${e.toString()}');
    }
  }

  // Lấy danh sách đăng ký hỗ trợ của một sự kiện
  Future<List<SupportRegistrationModel>> getEventSupportRegistrations(
    String eventId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('support_registrations')
          .where('eventId', isEqualTo: eventId)
          .get();

      final list = snapshot.docs
          .map((doc) => SupportRegistrationModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
      return list;
    } catch (e) {
      throw Exception('Error getting support registrations: ${e.toString()}');
    }
  }

  // Duyệt đăng ký hỗ trợ
  Future<void> approveSupportRegistration(
    String registrationId,
    String approvedBy,
  ) async {
    try {
      await _firestore
          .collection('support_registrations')
          .doc(registrationId)
          .update({
            'status': AppConstants.registrationApproved,
            'approvedAt': Timestamp.fromDate(DateTime.now()),
            'approvedBy': approvedBy,
          });

      // Cập nhật currentSupportStaff count trong event
      await _updateEventSupportStaffCount(registrationId);
    } catch (e) {
      throw Exception('Error approving support registration: ${e.toString()}');
    }
  }

  // Cập nhật số lượng support staff trong event
  Future<void> _updateEventSupportStaffCount(String registrationId) async {
    try {
      // Lấy thông tin registration để biết eventId
      DocumentSnapshot regDoc = await _firestore
          .collection('support_registrations')
          .doc(registrationId)
          .get();

      if (!regDoc.exists) return;

      Map<String, dynamic> regData = regDoc.data() as Map<String, dynamic>;
      String eventId = regData['eventId'] ?? '';

      if (eventId.isEmpty) return;

      // Đếm số support staff đã được approve
      QuerySnapshot approvedSnapshot = await _firestore
          .collection('support_registrations')
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: AppConstants.registrationApproved)
          .get();

      // Cập nhật currentSupportStaff trong event
      await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId)
          .update({'currentSupportStaff': approvedSnapshot.docs.length});
    } catch (e) {
      print('Error updating support staff count: $e');
    }
  }

  // Từ chối đăng ký hỗ trợ
  Future<void> rejectSupportRegistration(
    String registrationId,
    String rejectedBy,
    String reason,
  ) async {
    try {
      await _firestore
          .collection('support_registrations')
          .doc(registrationId)
          .update({
            'status': AppConstants.registrationRejected,
            'approvedAt': Timestamp.fromDate(DateTime.now()),
            'approvedBy': rejectedBy,
            'rejectionReason': reason,
          });
    } catch (e) {
      throw Exception('Error rejecting support registration: ${e.toString()}');
    }
  }

  // Lấy support registration bằng QR code
  Future<SupportRegistrationModel?> getSupportRegistrationByQRCode(
    String qrCode,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('support_registrations')
          .where('qrCode', isEqualTo: qrCode)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return SupportRegistrationModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception(
        'Error getting support registration by QR code: ${e.toString()}',
      );
    }
  }

  // Đánh dấu tham dự cho support staff
  Future<void> markSupportAttendance(String registrationId) async {
    try {
      await _firestore
          .collection('support_registrations')
          .doc(registrationId)
          .update({
            'attended': true,
            'attendedAt': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      throw Exception('Error marking support attendance: ${e.toString()}');
    }
  }

  // Lấy stream support registrations của user
  Stream<List<SupportRegistrationModel>> getUserSupportRegistrationsStream(
    String userId,
  ) {
    return _firestore
        .collection('support_registrations')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SupportRegistrationModel.fromFirestore(doc))
              .toList();
        });
  }
}
