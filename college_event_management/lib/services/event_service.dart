import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../constants/app_constants.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy danh sách sự kiện - chỉ hiển thị sự kiện đã được duyệt cho sinh viên
  Future<List<EventModel>> getEvents({
    String? category,
    String? status,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      // Sử dụng query đơn giản để tránh lỗi index
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.eventsCollection)
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: AppConstants.eventPublished)
          .get();

      List<EventModel> events = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();

      // Lọc theo category nếu có
      if (category != null && category.isNotEmpty) {
        events = events.where((event) => event.category == category).toList();
      }

      // Lọc theo status nếu có (chỉ áp dụng cho admin)
      if (status != null && status.isNotEmpty) {
        events = events.where((event) => event.status == status).toList();
      }

      // Sắp xếp theo createdAt
      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Giới hạn số lượng
      if (events.length > limit) {
        events = events.take(limit).toList();
      }

      return events;
    } catch (e) {
      throw Exception('Lỗi lấy danh sách sự kiện: ${e.toString()}');
    }
  }

  // Lấy tất cả sự kiện cho admin (bao gồm pending)
  Future<List<EventModel>> getAllEventsForAdmin({
    String? category,
    String? status,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.eventsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      List<EventModel> events = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();

      // Lọc theo category nếu có
      if (category != null && category.isNotEmpty) {
        events = events.where((event) => event.category == category).toList();
      }

      // Lọc theo status nếu có
      if (status != null && status.isNotEmpty) {
        events = events.where((event) => event.status == status).toList();
      }

      // Sắp xếp theo createdAt
      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Giới hạn số lượng
      if (events.length > limit) {
        events = events.take(limit).toList();
      }

      return events;
    } catch (e) {
      throw Exception('Lỗi lấy danh sách sự kiện cho admin: ${e.toString()}');
    }
  }

  // Lấy sự kiện theo ID
  Future<EventModel?> getEventById(String eventId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId)
          .get();

      if (doc.exists) {
        return EventModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi lấy thông tin sự kiện: ${e.toString()}');
    }
  }

  // Tạo sự kiện mới
  Future<String> createEvent(EventModel event) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(AppConstants.eventsCollection)
          .add(event.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Lỗi tạo sự kiện: ${e.toString()}');
    }
  }

  // Cập nhật sự kiện
  Future<void> updateEvent(EventModel event) async {
    try {
      await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(event.id)
          .update(event.toFirestore());
    } catch (e) {
      throw Exception('Lỗi cập nhật sự kiện: ${e.toString()}');
    }
  }

  // Xóa sự kiện (soft delete)
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId)
          .update({'isActive': false});
    } catch (e) {
      throw Exception('Lỗi xóa sự kiện: ${e.toString()}');
    }
  }

  // Tìm kiếm sự kiện - chỉ tìm kiếm sự kiện đã được duyệt
  Future<List<EventModel>> searchEvents(String searchTerm) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.eventsCollection)
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: AppConstants.eventPublished)
          .get();

      List<EventModel> events = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .where(
            (event) =>
                (event.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
                event.description.toLowerCase().contains(
                  searchTerm.toLowerCase(),
                ) ||
                event.category.toLowerCase().contains(
                  searchTerm.toLowerCase(),
                ) ||
                event.tags.any(
                  (tag) => tag.toLowerCase().contains(searchTerm.toLowerCase()),
                )),
          )
          .toList();

      return events;
    } catch (e) {
      throw Exception('Lỗi tìm kiếm sự kiện: ${e.toString()}');
    }
  }

  // Lấy sự kiện theo người tổ chức
  Future<List<EventModel>> getEventsByOrganizer(String organizerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.eventsCollection)
          .where('organizerId', isEqualTo: organizerId)
          .where('isActive', isEqualTo: true)
          .get();

      List<EventModel> events = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();

      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return events;
    } catch (e) {
      throw Exception('Lỗi lấy sự kiện theo người tổ chức: ${e.toString()}');
    }
  }

  // Cập nhật số lượng người tham gia
  Future<void> updateParticipantCount(String eventId, int newCount) async {
    try {
      await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId)
          .update({'currentParticipants': newCount});
    } catch (e) {
      throw Exception('Lỗi cập nhật số lượng tham gia: ${e.toString()}');
    }
  }

  // Lấy sự kiện sắp diễn ra - chỉ hiển thị sự kiện đã được duyệt
  Future<List<EventModel>> getUpcomingEvents({int limit = 10}) async {
    try {
      DateTime now = DateTime.now();
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.eventsCollection)
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: AppConstants.eventPublished)
          .get();

      List<EventModel> events = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .where((event) => event.startDate.isAfter(now))
          .toList();

      events.sort((a, b) => a.startDate.compareTo(b.startDate));

      if (events.length > limit) {
        events = events.take(limit).toList();
      }

      return events;
    } catch (e) {
      throw Exception('Lỗi lấy sự kiện sắp diễn ra: ${e.toString()}');
    }
  }

  // Stream để theo dõi sự kiện real-time - chỉ hiển thị sự kiện đã được duyệt cho sinh viên
  Stream<List<EventModel>> getEventsStream() {
    return _firestore
        .collection(AppConstants.eventsCollection)
        .where('isActive', isEqualTo: true)
        .where('status', isEqualTo: AppConstants.eventPublished)
        .snapshots()
        .map((snapshot) {
          List<EventModel> events = snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList();

          // Sắp xếp theo createdAt
          events.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return events;
        });
  }

  // Stream để theo dõi tất cả sự kiện (bao gồm pending) - dành cho admin
  Stream<List<EventModel>> getAllEventsStream() {
    return _firestore
        .collection(AppConstants.eventsCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          List<EventModel> events = snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList();

          // Sắp xếp theo createdAt
          events.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return events;
        });
  }

  // Stream để theo dõi sự kiện cho organizer - hiển thị sự kiện đã published + sự kiện của organizer
  Stream<List<EventModel>> getOrganizerEventsStream(String organizerId) {
    return _firestore
        .collection(AppConstants.eventsCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          List<EventModel> events = snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList();

          // Lọc sự kiện: published hoặc của organizer này (organizer có thể thấy sự kiện pending của mình)
          events = events
              .where(
                (event) =>
                    event.status == AppConstants.eventPublished ||
                    event.organizerId == organizerId,
              )
              .toList();

          // Sắp xếp theo createdAt
          events.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return events;
        });
  }

  // Stream để lấy chỉ sự kiện của organizer (cho My Events tab)
  Stream<List<EventModel>> getMyEventsStream(String organizerId) {
    return _firestore
        .collection(AppConstants.eventsCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          List<EventModel> events = snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList();

          // Lọc: sự kiện do tôi tạo hoặc tôi là co-organizer
          events = events
              .where(
                (event) =>
                    event.organizerId == organizerId ||
                    (event.coOrganizers).contains(organizerId),
              )
              .toList();

          // Sắp xếp theo createdAt
          events.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return events;
        });
  }

  // Stream: chỉ các sự kiện mà user là co-organizer
  Stream<List<EventModel>> getCoOrganizerEventsStream(String userId) {
    return _firestore
        .collection(AppConstants.eventsCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          List<EventModel> events = snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .where((event) => event.coOrganizers.contains(userId))
              .toList();

          events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return events;
        });
  }
}
