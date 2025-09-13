import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/support_registration_model.dart';
import '../constants/app_constants.dart';

class OrganizerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy danh sách support registrations cho sự kiện của organizer
  Future<List<SupportRegistrationModel>> getEventSupportRegistrations(
    String eventId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.supportRegistrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .get();

      List<SupportRegistrationModel> registrations = snapshot.docs
          .map((doc) => SupportRegistrationModel.fromFirestore(doc))
          .toList();

      // Sort trong code thay vì trong query để tránh cần composite index
      registrations.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));

      return registrations;
    } catch (e) {
      throw Exception('Error getting support registrations: ${e.toString()}');
    }
  }

  // Duyệt support registration
  Future<void> approveSupportRegistration(
    String registrationId,
    String approvedBy,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.supportRegistrationsCollection)
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

  // Từ chối support registration
  Future<void> rejectSupportRegistration(
    String registrationId,
    String rejectedBy,
    String reason,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.supportRegistrationsCollection)
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

  // Cập nhật số lượng support staff trong event
  Future<void> _updateEventSupportStaffCount(String registrationId) async {
    try {
      // Lấy thông tin registration để biết eventId
      DocumentSnapshot regDoc = await _firestore
          .collection(AppConstants.supportRegistrationsCollection)
          .doc(registrationId)
          .get();

      if (!regDoc.exists) return;

      Map<String, dynamic> regData = regDoc.data() as Map<String, dynamic>;
      String eventId = regData['eventId'] ?? '';

      if (eventId.isEmpty) return;

      // Đếm số support staff đã được approve
      QuerySnapshot approvedSnapshot = await _firestore
          .collection(AppConstants.supportRegistrationsCollection)
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

  // Lấy thống kê support registrations cho event
  Future<Map<String, int>> getSupportRegistrationStats(String eventId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.supportRegistrationsCollection)
          .where('eventId', isEqualTo: eventId)
          .get();

      int pending = 0;
      int approved = 0;
      int rejected = 0;
      int cancelled = 0;

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String status = data['status'] ?? '';

        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'approved':
            approved++;
            break;
          case 'rejected':
            rejected++;
            break;
          case 'cancelled':
            cancelled++;
            break;
        }
      }

      return {
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
        'cancelled': cancelled,
        'total': snapshot.docs.length,
      };
    } catch (e) {
      throw Exception(
        'Error getting support registration stats: ${e.toString()}',
      );
    }
  }
}
