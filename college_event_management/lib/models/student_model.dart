import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String id;
  final String studentId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? department;
  final String? classCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  StudentModel({
    required this.id,
    required this.studentId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.department,
    this.classCode,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory StudentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return StudentModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      department: data['department'],
      classCode: data['classCode'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] ?? '',
      studentId: json['studentId'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      department: json['department'],
      classCode: json['classCode'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'department': department,
      'classCode': classCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'department': department,
      'classCode': classCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  StudentModel copyWith({
    String? id,
    String? studentId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? department,
    String? classCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return StudentModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      department: department ?? this.department,
      classCode: classCode ?? this.classCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentModel &&
        other.studentId == studentId &&
        other.email == email;
  }

  @override
  int get hashCode => studentId.hashCode ^ email.hashCode;

  @override
  String toString() {
    return 'StudentModel(id: $id, studentId: $studentId, fullName: $fullName, email: $email)';
  }
}
