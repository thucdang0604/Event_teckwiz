import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coorganizer_invitation_model.dart';

class CoOrganizerInvitationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Gửi lời mời co-organizer
  Future<String> sendInvitation({
    required String eventId,
    required String eventTitle,
    required String organizerId,
    required String organizerName,
    required String invitedUserId,
    required String invitedUserEmail,
    required String invitedUserName,
  }) async {
    try {
      // Kiểm tra xem đã có lời mời chưa (bỏ qua nếu không có quyền đọc)
      bool alreadyInvited = false;
      try {
        alreadyInvited = await isUserInvited(eventId, invitedUserId);
      } catch (_) {
        // Nếu rules chặn đọc, vẫn tiếp tục tạo để tránh block UX
      }
      if (alreadyInvited) {
        throw Exception(
          'Người dùng này đã được mời làm co-organizer cho sự kiện này',
        );
      }

      CoOrganizerInvitationModel invitation = CoOrganizerInvitationModel(
        id: '', // Sẽ được tạo tự động
        eventId: eventId,
        eventTitle: eventTitle,
        organizerId: organizerId,
        organizerName: organizerName,
        invitedUserId: invitedUserId,
        invitedUserEmail: invitedUserEmail,
        invitedUserName: invitedUserName,
        status: 'pending',
        invitedAt: DateTime.now(),
      );

      DocumentReference docRef = await _firestore
          .collection('coorganizer_invitations')
          .add(invitation.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Lỗi gửi lời mời co-organizer: ${e.toString()}');
    }
  }

  // Kiểm tra xem user đã được mời chưa
  Future<bool> isUserInvited(String eventId, String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('coorganizer_invitations')
          .where('eventId', isEqualTo: eventId)
          .where('invitedUserId', isEqualTo: userId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Lỗi kiểm tra lời mời: ${e.toString()}');
    }
  }

  // Lấy danh sách lời mời của user
  Stream<List<CoOrganizerInvitationModel>> getUserInvitationsStream(
    String userId,
  ) {
    return _firestore
        .collection('coorganizer_invitations')
        .where('invitedUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => CoOrganizerInvitationModel.fromFirestore(doc))
              .toList();
          items.sort((a, b) => b.invitedAt.compareTo(a.invitedAt));
          return items;
        });
  }

  // Lấy danh sách lời mời đã gửi của organizer
  Stream<List<CoOrganizerInvitationModel>> getOrganizerInvitationsStream(
    String organizerId,
  ) {
    return _firestore
        .collection('coorganizer_invitations')
        .where('organizerId', isEqualTo: organizerId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => CoOrganizerInvitationModel.fromFirestore(doc))
              .toList();
          items.sort((a, b) => b.invitedAt.compareTo(a.invitedAt));
          return items;
        });
  }

  // Chấp nhận lời mời
  Future<void> acceptInvitation(String invitationId) async {
    try {
      // Lấy thông tin lời mời
      final invitation = await getInvitationById(invitationId);
      if (invitation == null) {
        throw Exception('Không tìm thấy lời mời');
      }

      // Cập nhật trạng thái lời mời
      await _firestore
          .collection('coorganizer_invitations')
          .doc(invitationId)
          .update({
            'status': 'accepted',
            'respondedAt': Timestamp.fromDate(DateTime.now()),
          });

      // Thêm co-organizer vào event
      await _addCoOrganizerToEvent(
        invitation.eventId,
        invitation.invitedUserId,
      );
    } catch (e) {
      throw Exception('Lỗi chấp nhận lời mời: ${e.toString()}');
    }
  }

  // Thêm co-organizer vào event
  Future<void> _addCoOrganizerToEvent(String eventId, String userId) async {
    try {
      // Lấy thông tin event hiện tại
      DocumentSnapshot eventDoc = await _firestore
          .collection('events')
          .doc(eventId)
          .get();

      if (!eventDoc.exists) {
        throw Exception('Không tìm thấy sự kiện');
      }

      Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
      List<String> coOrganizers = List<String>.from(
        eventData['coOrganizers'] ?? [],
      );

      // Kiểm tra xem user đã là co-organizer chưa
      if (!coOrganizers.contains(userId)) {
        coOrganizers.add(userId);

        // Cập nhật event với co-organizer mới
        await _firestore.collection('events').doc(eventId).update({
          'coOrganizers': coOrganizers,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      throw Exception('Lỗi thêm co-organizer vào sự kiện: ${e.toString()}');
    }
  }

  // Từ chối lời mời
  Future<void> rejectInvitation(String invitationId, {String? reason}) async {
    try {
      await _firestore
          .collection('coorganizer_invitations')
          .doc(invitationId)
          .update({
            'status': 'rejected',
            'respondedAt': Timestamp.fromDate(DateTime.now()),
            'responseMessage': reason,
          });
    } catch (e) {
      throw Exception('Lỗi từ chối lời mời: ${e.toString()}');
    }
  }

  // Hủy lời mời (chỉ organizer mới có thể)
  Future<void> cancelInvitation(String invitationId) async {
    try {
      await _firestore
          .collection('coorganizer_invitations')
          .doc(invitationId)
          .delete();
    } catch (e) {
      throw Exception('Lỗi hủy lời mời: ${e.toString()}');
    }
  }

  // Lấy lời mời theo ID
  Future<CoOrganizerInvitationModel?> getInvitationById(
    String invitationId,
  ) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('coorganizer_invitations')
          .doc(invitationId)
          .get();

      if (doc.exists) {
        return CoOrganizerInvitationModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi lấy lời mời: ${e.toString()}');
    }
  }

  // Lấy số lượng lời mời chưa phản hồi
  Future<int> getPendingInvitationsCount(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('coorganizer_invitations')
          .where('invitedUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Lỗi đếm lời mời: ${e.toString()}');
    }
  }
}
