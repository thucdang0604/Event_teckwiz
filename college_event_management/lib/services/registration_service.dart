import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/registration_model.dart';
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
          .orderBy('registeredAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RegistrationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Lỗi lấy danh sách đăng ký: ${e.toString()}');
    }
  }

  // Lấy danh sách đăng ký của một sự kiện
  Future<List<RegistrationModel>> getEventRegistrations(String eventId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.registrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .orderBy('registeredAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RegistrationModel.fromFirestore(doc))
          .toList();
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

  // Stream để theo dõi đăng ký real-time
  Stream<List<RegistrationModel>> getUserRegistrationsStream(String userId) {
    return _firestore
        .collection(AppConstants.registrationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RegistrationModel.fromFirestore(doc))
              .toList(),
        );
  }
}
