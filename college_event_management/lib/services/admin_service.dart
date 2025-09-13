import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../models/location_model.dart';
import '../models/event_statistics_model.dart';
import '../constants/app_constants.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách người dùng: $e');
    }
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'isActive': isActive, 'updatedAt': Timestamp.now()});
    } catch (e) {
      throw Exception('Lỗi khi cập nhật trạng thái người dùng: $e');
    }
  }

  Future<void> updateUserRole(String userId, String role) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'role': role, 'updatedAt': Timestamp.now()});
    } catch (e) {
      throw Exception('Lỗi khi cập nhật vai trò người dùng: $e');
    }
  }

  Future<List<EventModel>> getPendingEvents() async {
    try {
      print('🔍 Đang tìm kiếm sự kiện pending...');
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.eventsCollection)
          .where('status', isEqualTo: 'pending')
          .where('isActive', isEqualTo: true)
          .get();

      print('📊 Tìm thấy ${snapshot.docs.length} sự kiện pending');
      List<EventModel> events = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();

      // Fallback: một số sự kiện cũ có thể chưa có field status.
      // Lấy thêm danh sách sự kiện đang active và lọc local các event thiếu status hoặc draft.
      QuerySnapshot fallbackSnapshot = await _firestore
          .collection(AppConstants.eventsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      final fallbackEvents = fallbackSnapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .where((e) => e.status == 'pending' || e.status == 'draft')
          .toList();

      // Gộp 2 nguồn và loại trùng theo id
      final Map<String, EventModel> unique = {
        for (final e in [...events, ...fallbackEvents]) e.id: e,
      };
      events = unique.values.toList();

      // Sắp xếp theo createdAt desc
      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      for (var event in events) {
        print('📅 Sự kiện: ${event.title} - Status: ${event.status}');
      }

      return events;
    } catch (e) {
      print('❌ Lỗi khi lấy sự kiện pending: $e');
      throw Exception('Lỗi khi lấy danh sách sự kiện chờ duyệt: $e');
    }
  }

  Future<List<EventModel>> getAllEvents() async {
    try {
      print('🔍 Đang tải tất cả sự kiện...');
      // Lấy tất cả sự kiện active trước, sau đó sort trong code để tránh cần composite index
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.eventsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      print('📊 Tìm thấy ${snapshot.docs.length} sự kiện active');
      List<EventModel> events = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();

      // Sort trong code thay vì trong query
      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return events;
    } catch (e) {
      print('❌ Lỗi khi lấy tất cả sự kiện: $e');
      throw Exception('Lỗi khi lấy danh sách tất cả sự kiện: $e');
    }
  }

  Future<void> approveEvent(String eventId) async {
    try {
      await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId)
          .update({'status': 'published', 'updatedAt': Timestamp.now()});
    } catch (e) {
      throw Exception('Lỗi khi duyệt sự kiện: $e');
    }
  }

  Future<void> rejectEvent(String eventId, String reason) async {
    try {
      await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId)
          .update({
            'status': 'rejected',
            'rejectionReason': reason,
            'updatedAt': Timestamp.now(),
          });
    } catch (e) {
      throw Exception('Lỗi khi từ chối sự kiện: $e');
    }
  }

  Future<List<LocationModel>> getAllLocations() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('locations')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LocationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách vị trí: $e');
    }
  }

  Future<void> addLocation(LocationModel location) async {
    try {
      await _firestore.collection('locations').add(location.toFirestore());
    } catch (e) {
      throw Exception('Lỗi khi thêm vị trí: $e');
    }
  }

  Future<void> updateLocation(LocationModel location) async {
    try {
      await _firestore
          .collection('locations')
          .doc(location.id)
          .update(location.toFirestore());
    } catch (e) {
      throw Exception('Lỗi khi cập nhật vị trí: $e');
    }
  }

  Future<void> deleteLocation(String locationId) async {
    try {
      await _firestore.collection('locations').doc(locationId).delete();
    } catch (e) {
      throw Exception('Lỗi khi xóa vị trí: $e');
    }
  }

  Future<List<EventModel>> getEventsByLocation(String locationName) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('events')
          .where('location', isEqualTo: locationName)
          .where('isActive', isEqualTo: true)
          .orderBy('startDate', descending: false)
          .get();

      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy sự kiện theo vị trí: $e');
    }
  }

  Future<List<EventStatisticsModel>> getEventStatistics() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('event_statistics')
          .orderBy('eventDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => EventStatisticsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy thống kê sự kiện: $e');
    }
  }

  Future<void> updateEventStatistics(
    String eventId,
    int actualAttendees,
  ) async {
    try {
      DocumentSnapshot eventDoc = await _firestore
          .collection('events')
          .doc(eventId)
          .get();

      if (eventDoc.exists) {
        EventModel event = EventModel.fromFirestore(eventDoc);

        double attendanceRate = event.currentParticipants > 0
            ? (actualAttendees / event.currentParticipants) * 100
            : 0.0;

        await _firestore.collection('event_statistics').doc(eventId).set({
          'eventId': eventId,
          'eventTitle': event.title,
          'totalRegistrations': event.currentParticipants,
          'actualAttendees': actualAttendees,
          'expectedAttendees': event.currentParticipants,
          'attendanceRate': attendanceRate,
          'eventDate': Timestamp.fromDate(event.startDate),
          'location': event.location,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Lỗi khi cập nhật thống kê sự kiện: $e');
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      QuerySnapshot eventsSnapshot = await _firestore
          .collection('events')
          .where('isActive', isEqualTo: true)
          .get();
      QuerySnapshot registrationsSnapshot = await _firestore
          .collection('registrations')
          .get();

      int totalUsers = usersSnapshot.docs.length;
      int activeUsers = usersSnapshot.docs
          .where(
            (doc) => (doc.data() as Map<String, dynamic>)['isActive'] == true,
          )
          .length;
      int totalEvents = eventsSnapshot.docs.length;
      int publishedEvents = eventsSnapshot.docs
          .where(
            (doc) =>
                (doc.data() as Map<String, dynamic>)['status'] == 'published',
          )
          .length;
      int totalRegistrations = registrationsSnapshot.docs.length;

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'totalEvents': totalEvents,
        'publishedEvents': publishedEvents,
        'totalRegistrations': totalRegistrations,
      };
    } catch (e) {
      throw Exception('Lỗi khi lấy thống kê tổng quan: $e');
    }
  }

  Future<void> approveUser(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'approvalStatus': AppConstants.userApproved,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      throw Exception('Lỗi duyệt tài khoản: $e');
    }
  }

  Future<void> rejectUser(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'approvalStatus': AppConstants.userRejected,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      throw Exception('Lỗi từ chối tài khoản: $e');
    }
  }

  Future<void> blockUser(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'isBlocked': true,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      throw Exception('Lỗi block tài khoản: $e');
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'isBlocked': false,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      throw Exception('Lỗi unblock tài khoản: $e');
    }
  }

  Future<void> cancelEvent(String eventId) async {
    try {
      await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId)
          .update({'status': 'cancelled', 'updatedAt': Timestamp.now()});
    } catch (e) {
      throw Exception('Lỗi hủy sự kiện: $e');
    }
  }

  Future<void> updateEventStatus(String eventId, String status) async {
    try {
      await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId)
          .update({'status': status, 'updatedAt': Timestamp.now()});
    } catch (e) {
      throw Exception('Lỗi cập nhật trạng thái sự kiện: $e');
    }
  }
}
