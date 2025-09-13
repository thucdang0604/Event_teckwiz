import 'package:cloud_firestore/cloud_firestore.dart';

class CoOrganizerInvitationModel {
  final String id;
  final String eventId;
  final String eventTitle;
  final String organizerId;
  final String organizerName;
  final String invitedUserId;
  final String invitedUserEmail;
  final String invitedUserName;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime invitedAt;
  final DateTime? respondedAt;
  final String? responseMessage;

  CoOrganizerInvitationModel({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.organizerId,
    required this.organizerName,
    required this.invitedUserId,
    required this.invitedUserEmail,
    required this.invitedUserName,
    required this.status,
    required this.invitedAt,
    this.respondedAt,
    this.responseMessage,
  });

  factory CoOrganizerInvitationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CoOrganizerInvitationModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      eventTitle: data['eventTitle'] ?? '',
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      invitedUserId: data['invitedUserId'] ?? '',
      invitedUserEmail: data['invitedUserEmail'] ?? '',
      invitedUserName: data['invitedUserName'] ?? '',
      status: data['status'] ?? 'pending',
      invitedAt: (data['invitedAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      responseMessage: data['responseMessage'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'eventTitle': eventTitle,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'invitedUserId': invitedUserId,
      'invitedUserEmail': invitedUserEmail,
      'invitedUserName': invitedUserName,
      'status': status,
      'invitedAt': Timestamp.fromDate(invitedAt),
      'respondedAt': respondedAt != null
          ? Timestamp.fromDate(respondedAt!)
          : null,
      'responseMessage': responseMessage,
    };
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  CoOrganizerInvitationModel copyWith({
    String? id,
    String? eventId,
    String? eventTitle,
    String? organizerId,
    String? organizerName,
    String? invitedUserId,
    String? invitedUserEmail,
    String? invitedUserName,
    String? status,
    DateTime? invitedAt,
    DateTime? respondedAt,
    String? responseMessage,
  }) {
    return CoOrganizerInvitationModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      invitedUserId: invitedUserId ?? this.invitedUserId,
      invitedUserEmail: invitedUserEmail ?? this.invitedUserEmail,
      invitedUserName: invitedUserName ?? this.invitedUserName,
      status: status ?? this.status,
      invitedAt: invitedAt ?? this.invitedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      responseMessage: responseMessage ?? this.responseMessage,
    );
  }
}
