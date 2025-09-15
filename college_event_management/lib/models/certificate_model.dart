import 'package:cloud_firestore/cloud_firestore.dart';

class CertificateModel {
  final String id;
  final String eventId;
  final String eventTitle;
  final String userId;
  final String userName;
  final String userEmail;
  final String templateId;
  final String certificateNumber;
  final String certificateUrl;
  final String issuedBy;
  final String issuedByName;
  final DateTime issuedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, dynamic>? customFields;

  CertificateModel({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.templateId,
    required this.certificateNumber,
    required this.certificateUrl,
    required this.issuedBy,
    required this.issuedByName,
    required this.issuedAt,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.customFields,
  });

  factory CertificateModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CertificateModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      eventTitle: data['eventTitle'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      templateId: data['templateId'] ?? '',
      certificateNumber: data['certificateNumber'] ?? '',
      certificateUrl: data['certificateUrl'] ?? '',
      issuedBy: data['issuedBy'] ?? '',
      issuedByName: data['issuedByName'] ?? '',
      issuedAt: (data['issuedAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      customFields: data['customFields'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'eventTitle': eventTitle,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'templateId': templateId,
      'certificateNumber': certificateNumber,
      'certificateUrl': certificateUrl,
      'issuedBy': issuedBy,
      'issuedByName': issuedByName,
      'issuedAt': Timestamp.fromDate(issuedAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'customFields': customFields,
    };
  }

  CertificateModel copyWith({
    String? id,
    String? eventId,
    String? eventTitle,
    String? userId,
    String? userName,
    String? userEmail,
    String? templateId,
    String? certificateNumber,
    String? certificateUrl,
    String? issuedBy,
    String? issuedByName,
    DateTime? issuedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? customFields,
  }) {
    return CertificateModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      templateId: templateId ?? this.templateId,
      certificateNumber: certificateNumber ?? this.certificateNumber,
      certificateUrl: certificateUrl ?? this.certificateUrl,
      issuedBy: issuedBy ?? this.issuedBy,
      issuedByName: issuedByName ?? this.issuedByName,
      issuedAt: issuedAt ?? this.issuedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      customFields: customFields ?? this.customFields,
    );
  }

  bool get isValid => certificateUrl.isNotEmpty && isActive;
}
