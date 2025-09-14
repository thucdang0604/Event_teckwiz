import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationModel {
  final String id;
  final String eventId;
  final String userId;
  final String userEmail;
  final String userName;
  final String status;
  final DateTime registeredAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final String? rejectionReason;
  final Map<String, dynamic>? additionalInfo;
  final String? qrCode;
  final bool attended;
  final DateTime? attendedAt;
  final DateTime? checkedOutAt;
  final String? notes;
  final bool isPaid;
  final double? amountPaid;
  final DateTime? paidAt;
  final String? paymentMethod;
  final String? paymentId;
  final bool isInQueue;
  final int? queuePosition;

  RegistrationModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.status,
    required this.registeredAt,
    this.approvedAt,
    this.approvedBy,
    this.rejectionReason,
    this.additionalInfo,
    this.qrCode,
    this.attended = false,
    this.attendedAt,
    this.checkedOutAt,
    this.notes,
    this.isPaid = false,
    this.amountPaid,
    this.paidAt,
    this.paymentMethod,
    this.paymentId,
    this.isInQueue = false,
    this.queuePosition,
  });

  factory RegistrationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RegistrationModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'] ?? '',
      status: data['status'] ?? 'pending',
      registeredAt: (data['registeredAt'] as Timestamp).toDate(),
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      approvedBy: data['approvedBy'],
      rejectionReason: data['rejectionReason'],
      additionalInfo: data['additionalInfo'] != null
          ? Map<String, dynamic>.from(data['additionalInfo'])
          : null,
      qrCode: data['qrCode'],
      attended: data['attended'] ?? false,
      attendedAt: data['attendedAt'] != null
          ? (data['attendedAt'] as Timestamp).toDate()
          : null,
      checkedOutAt: data['checkedOutAt'] != null
          ? (data['checkedOutAt'] as Timestamp).toDate()
          : null,
      notes: data['notes'],
      isPaid: data['isPaid'] ?? false,
      amountPaid: data['amountPaid']?.toDouble(),
      paidAt: data['paidAt'] != null
          ? (data['paidAt'] as Timestamp).toDate()
          : null,
      paymentMethod: data['paymentMethod'],
      paymentId: data['paymentId'],
      isInQueue: data['isInQueue'] ?? false,
      queuePosition: data['queuePosition'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'status': status,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      'rejectionReason': rejectionReason,
      'additionalInfo': additionalInfo,
      'qrCode': qrCode,
      'attended': attended,
      'attendedAt': attendedAt != null ? Timestamp.fromDate(attendedAt!) : null,
      'checkedOutAt': checkedOutAt != null
          ? Timestamp.fromDate(checkedOutAt!)
          : null,
      'notes': notes,
      'isPaid': isPaid,
      'amountPaid': amountPaid,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'isInQueue': isInQueue,
      'queuePosition': queuePosition,
    };
  }

  RegistrationModel copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? userEmail,
    String? userName,
    String? status,
    DateTime? registeredAt,
    DateTime? approvedAt,
    String? approvedBy,
    String? rejectionReason,
    Map<String, dynamic>? additionalInfo,
    String? qrCode,
    bool? attended,
    DateTime? attendedAt,
    DateTime? checkedOutAt,
    String? notes,
    bool? isPaid,
    double? amountPaid,
    DateTime? paidAt,
    String? paymentMethod,
    String? paymentId,
    bool? isInQueue,
    int? queuePosition,
  }) {
    return RegistrationModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      status: status ?? this.status,
      registeredAt: registeredAt ?? this.registeredAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      qrCode: qrCode ?? this.qrCode,
      attended: attended ?? this.attended,
      attendedAt: attendedAt ?? this.attendedAt,
      checkedOutAt: checkedOutAt ?? this.checkedOutAt,
      notes: notes ?? this.notes,
      isPaid: isPaid ?? this.isPaid,
      amountPaid: amountPaid ?? this.amountPaid,
      paidAt: paidAt ?? this.paidAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
      isInQueue: isInQueue ?? this.isInQueue,
      queuePosition: queuePosition ?? this.queuePosition,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';
  bool get isInWaitingList => isInQueue;
}
