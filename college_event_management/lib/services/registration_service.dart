import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/registration_model.dart';
import '../models/support_registration_model.dart';
import '../constants/app_constants.dart';

class RegistrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Đăng ký tham gia sự kiện
  Future<String> registerForEvent({
    required String eventId,
    required String userId,
    required String userEmail,
    required String userName,
    Map<String, dynamic>? additionalInfo,
    bool isPaid = false,
    double? amountPaid,
    String? paymentMethod,
    String? paymentId,
  }) async {
    try {
      // Kiểm tra xem đã đăng ký chưa
      bool alreadyRegistered = await isUserRegisteredForEvent(eventId, userId);
      if (alreadyRegistered) {
        throw Exception('Bạn đã đăng ký sự kiện này rồi');
      }

      // Lấy thông tin sự kiện để kiểm tra số lượng và giá
      DocumentSnapshot eventDoc = await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId)
          .get();

      if (!eventDoc.exists) {
        throw Exception('Sự kiện không tồn tại');
      }

      Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
      int maxParticipants = eventData['maxParticipants'] ?? 0;
      int currentParticipants = eventData['currentParticipants'] ?? 0;

      // Tạo mã QR cho đăng ký
      String qrCode =
          'EVENT_${eventId}_USER_${userId}_${DateTime.now().millisecondsSinceEpoch}';

      // Xác định trạng thái đăng ký
      String status;
      bool isInQueue = false;
      int? queuePosition;

      if (currentParticipants < maxParticipants) {
        // Còn chỗ trống - tự động chấp nhận
        status = AppConstants.registrationApproved;
      } else {
        // Hết chỗ - chuyển vào hàng đợi
        status = AppConstants.registrationInQueue;
        isInQueue = true;
        queuePosition = await _getNextQueuePosition(eventId);
      }

      RegistrationModel registration = RegistrationModel(
        id: '', // Sẽ được tạo tự động
        eventId: eventId,
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        status: status,
        registeredAt: DateTime.now(),
        additionalInfo: additionalInfo,
        qrCode: qrCode,
        isPaid: isPaid,
        amountPaid: amountPaid,
        paymentMethod: paymentMethod,
        paymentId: paymentId,
        isInQueue: isInQueue,
        queuePosition: queuePosition,
      );

      DocumentReference docRef = await _firestore
          .collection(AppConstants.registrationsCollection)
          .add(registration.toFirestore());

      // Cập nhật số lượng người tham gia nếu được chấp nhận
      if (status == AppConstants.registrationApproved) {
        await _updateEventParticipantCount(eventId);
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Lỗi đăng ký sự kiện: ${e.toString()}');
    }
  }

  // Hủy đăng ký
  Future<void> cancelRegistration(String registrationId) async {
    try {
      // Lấy thông tin đăng ký để biết eventId
      DocumentSnapshot regDoc = await _firestore
          .collection(AppConstants.registrationsCollection)
          .doc(registrationId)
          .get();

      if (!regDoc.exists) {
        throw Exception('Không tìm thấy đăng ký');
      }

      Map<String, dynamic> regData = regDoc.data() as Map<String, dynamic>;
      String eventId = regData['eventId'] ?? '';
      String currentStatus = regData['status'] ?? '';

      // Cập nhật trạng thái đăng ký
      await _firestore
          .collection(AppConstants.registrationsCollection)
          .doc(registrationId)
          .update({
            'status': AppConstants.registrationCancelled,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      // Cập nhật số lượng người tham gia nếu đăng ký đã được chấp nhận hoặc đã thanh toán
      if ((currentStatus == AppConstants.registrationApproved ||
              currentStatus == AppConstants.registrationPaid) &&
          eventId.isNotEmpty) {
        await _updateEventParticipantCount(eventId);
      }

      print('Registration $registrationId cancelled successfully');
    } catch (e) {
      print('Error cancelling registration: $e');
      throw Exception('Lỗi hủy đăng ký: ${e.toString()}');
    }
  }

  // Hoàn tiền đăng ký
  Future<void> refundRegistration(String registrationId) async {
    try {
      // Lấy thông tin đăng ký
      DocumentSnapshot regDoc = await _firestore
          .collection(AppConstants.registrationsCollection)
          .doc(registrationId)
          .get();

      if (!regDoc.exists) {
        throw Exception('Không tìm thấy đăng ký');
      }

      Map<String, dynamic> regData = regDoc.data() as Map<String, dynamic>;
      String eventId = regData['eventId'] ?? '';
      String currentStatus = regData['status'] ?? '';
      double amountPaid = (regData['amountPaid'] ?? 0.0).toDouble();

      // Kiểm tra xem đăng ký có thể hoàn tiền không
      if (currentStatus != AppConstants.registrationPaid &&
          currentStatus != AppConstants.registrationApproved) {
        throw Exception('Chỉ có thể hoàn tiền cho đăng ký đã thanh toán');
      }

      if (amountPaid <= 0) {
        throw Exception('Không có tiền để hoàn');
      }

      // Cập nhật trạng thái đăng ký thành hoàn tiền
      await _firestore
          .collection(AppConstants.registrationsCollection)
          .doc(registrationId)
          .update({
            'status': AppConstants.registrationCancelled,
            'refundedAt': Timestamp.fromDate(DateTime.now()),
            'refundAmount': amountPaid,
            'refundStatus': 'pending', // pending, completed, failed
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      // Cập nhật số lượng người tham gia
      if (eventId.isNotEmpty) {
        await _updateEventParticipantCount(eventId);
      }

      print(
        'Registration $registrationId refunded successfully - Amount: $amountPaid VNĐ',
      );
    } catch (e) {
      print('Error refunding registration: $e');
      throw Exception('Lỗi hoàn tiền: ${e.toString()}');
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
              AppConstants.registrationPaid,
              AppConstants.registrationInQueue,
            ],
          )
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Lỗi kiểm tra đăng ký: ${e.toString()}');
    }
  }

  // Lấy đăng ký theo ID
  Future<RegistrationModel?> getRegistrationById(String registrationId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.registrationsCollection)
          .doc(registrationId)
          .get();

      if (doc.exists) {
        return RegistrationModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi lấy thông tin đăng ký: ${e.toString()}');
    }
  }

  // Lấy đăng ký của người dùng cho một sự kiện
  Future<RegistrationModel?> getUserRegistrationForEvent(
    String eventId,
    String userId,
  ) async {
    try {
      // Query đơn giản hơn để tránh lỗi index
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.registrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Lọc và sắp xếp trong code thay vì database
        List<QueryDocumentSnapshot> docs = snapshot.docs;

        // Lọc theo status active
        docs = docs.where((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String status = data['status'] ?? '';
          return status == AppConstants.registrationPending ||
              status == AppConstants.registrationApproved ||
              status == AppConstants.registrationPaid ||
              status == AppConstants.registrationInQueue;
        }).toList();

        // Sắp xếp theo registeredAt
        docs.sort((a, b) {
          Map<String, dynamic> aData = a.data() as Map<String, dynamic>;
          Map<String, dynamic> bData = b.data() as Map<String, dynamic>;
          Timestamp aTime = aData['registeredAt'] ?? Timestamp.now();
          Timestamp bTime = bData['registeredAt'] ?? Timestamp.now();
          return bTime.compareTo(aTime);
        });

        if (docs.isNotEmpty) {
          return RegistrationModel.fromFirestore(docs.first);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi lấy thông tin đăng ký: ${e.toString()}');
    }
  }

  // Lấy danh sách đăng ký của người dùng
  Future<List<RegistrationModel>> getUserRegistrations(String userId) async {
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
      throw Exception('Lỗi lấy danh sách đăng ký: ${e.toString()}');
    }
  }

  // Stream đăng ký của người dùng
  Stream<List<RegistrationModel>> getUserRegistrationsStream(String userId) {
    return _firestore
        .collection(AppConstants.registrationsCollection)
        .where('userId', isEqualTo: userId)
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
    } catch (e) {
      throw Exception('Lỗi checkout: ${e.toString()}');
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
      // Query đơn giản hơn để tránh lỗi index
      QuerySnapshot snapshot = await _firestore
          .collection('support_registrations')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Lọc và sắp xếp trong code thay vì database
        List<QueryDocumentSnapshot> docs = snapshot.docs;

        // Lọc theo status active
        docs = docs.where((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String status = data['status'] ?? '';
          return status == AppConstants.registrationPending ||
              status == AppConstants.registrationApproved;
        }).toList();

        // Sắp xếp theo registeredAt
        docs.sort((a, b) {
          Map<String, dynamic> aData = a.data() as Map<String, dynamic>;
          Map<String, dynamic> bData = b.data() as Map<String, dynamic>;
          Timestamp aTime = aData['registeredAt'] ?? Timestamp.now();
          Timestamp bTime = bData['registeredAt'] ?? Timestamp.now();
          return bTime.compareTo(aTime);
        });

        if (docs.isNotEmpty) {
          return SupportRegistrationModel.fromFirestore(docs.first);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error getting support registration: ${e.toString()}');
    }
  }

  // Hủy đăng ký hỗ trợ
  Future<void> cancelSupportRegistration(String registrationId) async {
    try {
      await _firestore
          .collection('support_registrations')
          .doc(registrationId)
          .update({
            'status': AppConstants.registrationCancelled,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
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

  // Lấy vị trí tiếp theo trong hàng đợi
  Future<int> _getNextQueuePosition(String eventId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.registrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .where('isInQueue', isEqualTo: true)
          .get();

      return snapshot.docs.length + 1;
    } catch (e) {
      return 1;
    }
  }

  // Cập nhật số lượng người tham gia trong sự kiện (public method)
  Future<void> updateEventParticipantCount(String eventId) async {
    await _updateEventParticipantCount(eventId);
  }

  // Cập nhật số lượng người tham gia trong sự kiện (private method)
  Future<void> _updateEventParticipantCount(String eventId) async {
    try {
      QuerySnapshot approvedSnapshot = await _firestore
          .collection(AppConstants.registrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .where(
            'status',
            whereIn: [
              AppConstants.registrationApproved,
              AppConstants.registrationPaid,
            ],
          )
          .get();

      int approvedCount = approvedSnapshot.docs.length;

      await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId)
          .update({
            'currentParticipants': approvedCount,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      print('Updated participant count for event $eventId: $approvedCount');
    } catch (e) {
      print('Error updating participant count: $e');
      throw Exception('Lỗi cập nhật số lượng người tham gia: ${e.toString()}');
    }
  }

  // Xử lý thanh toán cho đăng ký
  Future<void> processPayment({
    required String registrationId,
    required double amount,
    required String paymentMethod,
    required String paymentId,
  }) async {
    try {
      // Lấy thông tin đăng ký để biết eventId
      DocumentSnapshot regDoc = await _firestore
          .collection(AppConstants.registrationsCollection)
          .doc(registrationId)
          .get();

      if (!regDoc.exists) {
        throw Exception('Không tìm thấy đăng ký');
      }

      Map<String, dynamic> regData = regDoc.data() as Map<String, dynamic>;
      String eventId = regData['eventId'] ?? '';

      if (eventId.isEmpty) {
        throw Exception('Không tìm thấy ID sự kiện');
      }

      // Cập nhật trạng thái thanh toán
      await _firestore
          .collection(AppConstants.registrationsCollection)
          .doc(registrationId)
          .update({
            'isPaid': true,
            'amountPaid': amount,
            'paidAt': Timestamp.fromDate(DateTime.now()),
            'paymentMethod': paymentMethod,
            'paymentId': paymentId,
            'status': AppConstants
                .registrationApproved, // Chuyển sang approved sau khi thanh toán
          });

      // Cập nhật số lượng người tham gia
      await _updateEventParticipantCount(eventId);

      print('Payment processed successfully for registration $registrationId');
    } catch (e) {
      print('Error processing payment: $e');
      throw Exception('Lỗi xử lý thanh toán: ${e.toString()}');
    }
  }

  // Chuyển từ hàng đợi sang chấp nhận khi có chỗ trống
  Future<void> promoteFromQueue(String eventId) async {
    try {
      // Lấy đăng ký đầu tiên trong hàng đợi
      QuerySnapshot queueSnapshot = await _firestore
          .collection(AppConstants.registrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .where('isInQueue', isEqualTo: true)
          .orderBy('registeredAt')
          .limit(1)
          .get();

      if (queueSnapshot.docs.isNotEmpty) {
        String registrationId = queueSnapshot.docs.first.id;

        // Cập nhật trạng thái
        await _firestore
            .collection(AppConstants.registrationsCollection)
            .doc(registrationId)
            .update({
              'status': AppConstants.registrationApproved,
              'isInQueue': false,
              'queuePosition': null,
              'approvedAt': Timestamp.fromDate(DateTime.now()),
            });

        // Cập nhật số lượng người tham gia
        await _updateEventParticipantCount(eventId);

        // Cập nhật vị trí hàng đợi cho các đăng ký còn lại
        await _updateQueuePositions(eventId);
      }
    } catch (e) {
      print('Error promoting from queue: $e');
    }
  }

  // Cập nhật vị trí hàng đợi
  Future<void> _updateQueuePositions(String eventId) async {
    try {
      QuerySnapshot queueSnapshot = await _firestore
          .collection(AppConstants.registrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .where('isInQueue', isEqualTo: true)
          .orderBy('registeredAt')
          .get();

      for (int i = 0; i < queueSnapshot.docs.length; i++) {
        await _firestore
            .collection(AppConstants.registrationsCollection)
            .doc(queueSnapshot.docs[i].id)
            .update({'queuePosition': i + 1});
      }
    } catch (e) {
      print('Error updating queue positions: $e');
    }
  }

  // Lấy danh sách đăng ký trong hàng đợi
  Future<List<RegistrationModel>> getQueueRegistrations(String eventId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.registrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .where('isInQueue', isEqualTo: true)
          .orderBy('registeredAt')
          .get();

      return snapshot.docs
          .map((doc) => RegistrationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Lỗi lấy danh sách hàng đợi: ${e.toString()}');
    }
  }
}
