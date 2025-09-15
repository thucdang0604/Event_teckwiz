import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../constants/app_constants.dart';
import '../services/notification_service.dart';
import 'unified_notification_service.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UnifiedNotificationService _unifiedNotificationService =
      UnifiedNotificationService();

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
      // Tạo sự kiện với trạng thái pending (cần admin duyệt)
      EventModel pendingEvent = event.copyWith(
        status: AppConstants.eventPending,
      );

      DocumentReference docRef = await _firestore
          .collection(AppConstants.eventsCollection)
          .add(pendingEvent.toFirestore());

      // Gửi notification cho admin về sự kiện mới cần duyệt
      try {
        await NotificationService.sendNotificationToAdmin(
          title: 'Sự kiện mới cần duyệt',
          body:
              '${event.organizerName} đã tạo sự kiện "${event.title}" cần được duyệt',
          type: NotificationType.eventCreated,
          data: {
            'type': 'event_pending_approval',
            'eventId': docRef.id,
            'eventTitle': event.title,
            'organizerId': event.organizerId,
            'organizerName': event.organizerName,
          },
        );

        // Trigger notification refresh for admin
        // Note: This would need to be handled by the NotificationProvider in the UI
        print('Notification sent to admin for new event: ${event.title}');
      } catch (e) {
        print('Lỗi gửi notification cho admin khi tạo sự kiện: $e');
        // Không throw error để không làm gián đoạn flow tạo sự kiện
      }

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

  // Duyệt sự kiện
  Future<void> approveEvent(String eventId, String approvedBy) async {
    try {
      await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId)
          .update({
            'status': AppConstants.eventPublished,
            'approvedAt': Timestamp.fromDate(DateTime.now()),
            'approvedBy': approvedBy,
          });

      // Gửi unified notification cho organizer về việc sự kiện được duyệt
      try {
        final event = await getEventById(eventId);
        if (event != null) {
          await _unifiedNotificationService.sendUnifiedNotification(
            userId: event.organizerId,
            title: 'Sự kiện được duyệt',
            body: 'Sự kiện "${event.title}" của bạn đã được duyệt và xuất bản',
            type: NotificationType.eventCreated,
            data: {
              'type': 'event_approved',
              'eventId': eventId,
              'eventTitle': event.title,
              'eventDate': event.startDate.toIso8601String(),
              'organizerName': event.organizerName,
            },
            priority: NotificationPriority.high,
          );
          print(
            '✅ Unified notification sent to organizer: ${event.organizerId}',
          );
        }
      } catch (e) {
        print('Lỗi gửi unified notification khi duyệt sự kiện: $e');
      }
    } catch (e) {
      throw Exception('Lỗi duyệt sự kiện: ${e.toString()}');
    }
  }

  // Từ chối sự kiện
  Future<void> rejectEvent(
    String eventId,
    String rejectedBy,
    String reason,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId)
          .update({
            'status': AppConstants.eventCancelled,
            'approvedAt': Timestamp.fromDate(DateTime.now()),
            'approvedBy': rejectedBy,
            'rejectionReason': reason,
          });

      // Gửi unified notification cho organizer về việc sự kiện bị từ chối
      try {
        final event = await getEventById(eventId);
        if (event != null) {
          await _unifiedNotificationService.sendUnifiedNotification(
            userId: event.organizerId,
            title: 'Sự kiện bị từ chối',
            body:
                'Sự kiện "${event.title}" của bạn đã bị từ chối. Lý do: $reason',
            type: NotificationType.eventCancelled,
            data: {
              'type': 'event_rejected',
              'eventId': eventId,
              'eventTitle': event.title,
              'reason': reason,
              'organizerName': event.organizerName,
            },
            priority: NotificationPriority.high,
          );
          print(
            '✅ Unified notification sent to organizer: ${event.organizerId}',
          );
        }
      } catch (e) {
        print('Lỗi gửi unified notification khi từ chối sự kiện: $e');
      }
    } catch (e) {
      throw Exception('Lỗi từ chối sự kiện: ${e.toString()}');
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
