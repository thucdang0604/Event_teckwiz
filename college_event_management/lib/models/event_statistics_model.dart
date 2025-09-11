import 'package:cloud_firestore/cloud_firestore.dart';

class EventStatisticsModel {
  final String eventId;
  final String eventTitle;
  final int totalRegistrations;
  final int actualAttendees;
  final int expectedAttendees;
  final double attendanceRate;
  final DateTime eventDate;
  final String location;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventStatisticsModel({
    required this.eventId,
    required this.eventTitle,
    required this.totalRegistrations,
    required this.actualAttendees,
    required this.expectedAttendees,
    required this.attendanceRate,
    required this.eventDate,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventStatisticsModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EventStatisticsModel(
      eventId: data['eventId'] ?? '',
      eventTitle: data['eventTitle'] ?? '',
      totalRegistrations: data['totalRegistrations'] ?? 0,
      actualAttendees: data['actualAttendees'] ?? 0,
      expectedAttendees: data['expectedAttendees'] ?? 0,
      attendanceRate: (data['attendanceRate'] ?? 0.0).toDouble(),
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'eventTitle': eventTitle,
      'totalRegistrations': totalRegistrations,
      'actualAttendees': actualAttendees,
      'expectedAttendees': expectedAttendees,
      'attendanceRate': attendanceRate,
      'eventDate': Timestamp.fromDate(eventDate),
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  EventStatisticsModel copyWith({
    String? eventId,
    String? eventTitle,
    int? totalRegistrations,
    int? actualAttendees,
    int? expectedAttendees,
    double? attendanceRate,
    DateTime? eventDate,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventStatisticsModel(
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      totalRegistrations: totalRegistrations ?? this.totalRegistrations,
      actualAttendees: actualAttendees ?? this.actualAttendees,
      expectedAttendees: expectedAttendees ?? this.expectedAttendees,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      eventDate: eventDate ?? this.eventDate,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
