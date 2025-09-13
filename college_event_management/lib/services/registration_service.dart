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
  }) async {
    try {
      // Kiểm tra xem đã đăng ký chưa
      bool alreadyRegistered = await isUserRegisteredForEvent(eventId, userId);
      if (alreadyRegistered) {
        throw Exception('Bạn đã đăng ký sự kiện này rồi');
      }

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

      return docRef.id;
    } catch (e) {
      throw Exception('Lỗi đăng ký sự kiện: ${e.toString()}');
    }
  }

  // Hủy đăng ký
  Future<void> cancelRegistration(String registrationId) async {
    try {
      await _firestore
          .collection(AppConstants.registrationsCollection)
          .doc(registrationId)
          .update({
            'status': AppConstants.registrationCancelled,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
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

  // Lấy đăng ký của người dùng cho một sự kiện
  Future<RegistrationModel?> getUserRegistrationForEvent(
    String eventId,
    String userId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.registrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return RegistrationModel.fromFirestore(snapshot.docs.first);
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
}
