import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime registrationDeadline;
  final int maxParticipants;
  final int currentParticipants;
  final String status;
  final String organizerId;
  final String organizerName;
  final List<String> coOrganizers;
  final int maxSupportStaff;
  final int currentSupportStaff;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final String? requirements;
  final String? contactInfo;
  final bool isFree;
  final double? price;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.registrationDeadline,
    required this.maxParticipants,
    this.currentParticipants = 0,
    required this.status,
    required this.organizerId,
    required this.organizerName,
    this.coOrganizers = const [],
    this.maxSupportStaff = 0,
    this.currentSupportStaff = 0,
    this.imageUrls = const [],
    this.videoUrls = const [],
    this.requirements,
    this.contactInfo,
    this.isFree = true,
    this.price,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      location: data['location'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      registrationDeadline: (data['registrationDeadline'] as Timestamp)
          .toDate(),
      maxParticipants: data['maxParticipants'] ?? 0,
      currentParticipants: data['currentParticipants'] ?? 0,
      status: data['status'] ?? 'draft',
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      coOrganizers: List<String>.from(data['coOrganizers'] ?? []),
      maxSupportStaff: data['maxSupportStaff'] ?? 0,
      currentSupportStaff: data['currentSupportStaff'] ?? 0,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      videoUrls: List<String>.from(data['videoUrls'] ?? []),
      requirements: data['requirements'],
      contactInfo: data['contactInfo'],
      isFree: data['isFree'] ?? true,
      price: data['price']?.toDouble(),
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'registrationDeadline': Timestamp.fromDate(registrationDeadline),
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'status': status,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'coOrganizers': coOrganizers,
      'maxSupportStaff': maxSupportStaff,
      'currentSupportStaff': currentSupportStaff,
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'requirements': requirements,
      'contactInfo': contactInfo,
      'isFree': isFree,
      'price': price,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? registrationDeadline,
    int? maxParticipants,
    int? currentParticipants,
    String? status,
    String? organizerId,
    String? organizerName,
    List<String>? coOrganizers,
    int? maxSupportStaff,
    int? currentSupportStaff,
    List<String>? imageUrls,
    List<String>? videoUrls,
    String? requirements,
    String? contactInfo,
    bool? isFree,
    double? price,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      status: status ?? this.status,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      coOrganizers: coOrganizers ?? this.coOrganizers,
      maxSupportStaff: maxSupportStaff ?? this.maxSupportStaff,
      currentSupportStaff: currentSupportStaff ?? this.currentSupportStaff,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      requirements: requirements ?? this.requirements,
      contactInfo: contactInfo ?? this.contactInfo,
      isFree: isFree ?? this.isFree,
      price: price ?? this.price,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isPublished => status == 'published';
  bool get isDraft => status == 'draft';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';

  bool get isRegistrationOpen {
    final now = DateTime.now();
    return isPublished &&
        now.isBefore(registrationDeadline) &&
        currentParticipants < maxParticipants;
  }

  bool get isFull => currentParticipants >= maxParticipants;

  int get availableSpots => maxParticipants - currentParticipants;
}
