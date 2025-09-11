import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String message;
  final String messageType; // 'text', 'image', 'file'
  final String? imageUrl;
  final String? fileName;
  final DateTime timestamp;
  final bool isEdited;
  final DateTime? editedAt;
  final String? replyToMessageId;
  final bool isDeleted;

  ChatMessageModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.message,
    this.messageType = 'text',
    this.imageUrl,
    this.fileName,
    required this.timestamp,
    this.isEdited = false,
    this.editedAt,
    this.replyToMessageId,
    this.isDeleted = false,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userAvatarUrl: data['userAvatarUrl'],
      message: data['message'] ?? '',
      messageType: data['messageType'] ?? 'text',
      imageUrl: data['imageUrl'],
      fileName: data['fileName'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isEdited: data['isEdited'] ?? false,
      editedAt: data['editedAt'] != null
          ? (data['editedAt'] as Timestamp).toDate()
          : null,
      replyToMessageId: data['replyToMessageId'],
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'message': message,
      'messageType': messageType,
      'imageUrl': imageUrl,
      'fileName': fileName,
      'timestamp': Timestamp.fromDate(timestamp),
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'replyToMessageId': replyToMessageId,
      'isDeleted': isDeleted,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? message,
    String? messageType,
    String? imageUrl,
    String? fileName,
    DateTime? timestamp,
    bool? isEdited,
    DateTime? editedAt,
    String? replyToMessageId,
    bool? isDeleted,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      imageUrl: imageUrl ?? this.imageUrl,
      fileName: fileName ?? this.fileName,
      timestamp: timestamp ?? this.timestamp,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
