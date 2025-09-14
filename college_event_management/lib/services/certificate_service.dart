import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../models/event_model.dart';
import '../models/registration_model.dart';
import 'event_service.dart';
import 'notification_service.dart';

class CertificateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> _uploadBytes(String path, Uint8List data) async {
    final ref = _storage.ref().child(path);
    final uploadTask = await ref.putData(
      data,
      SettableMetadata(contentType: 'application/pdf'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  Future<Uint8List> _buildSimplePdfBytes({
    required String studentName,
    required String eventTitle,
    required DateTime date,
  }) async {
    final content =
        'Certificate of Participation\n\nThis is to certify that $studentName has successfully completed the event "$eventTitle" on ${DateFormat('dd/MM/yyyy').format(date)}.';
    final bytes = Uint8List.fromList(content.codeUnits);
    return bytes;
  }

  Future<String> issueCertificateForRegistration(RegistrationModel reg) async {
    final EventModel? event = await EventService().getEventById(reg.eventId);
    if (event == null) {
      throw Exception('Event not found');
    }

    if (!(reg.attended || reg.checkedOutAt != null)) {
      throw Exception('User has not attended the event');
    }

    final pdfBytes = await _buildSimplePdfBytes(
      studentName: reg.userName,
      eventTitle: event.title,
      date: reg.checkedOutAt ?? reg.attendedAt ?? DateTime.now(),
    );

    final path =
        'certificates/${reg.userId}_${reg.eventId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final url = await _uploadBytes(path, pdfBytes);

    await _firestore
        .collection(AppConstants.registrationsCollection)
        .doc(reg.id)
        .update({
          'certificateUrl': url,
          'certificateIssuedAt': Timestamp.fromDate(DateTime.now()),
        });

    await NotificationService.sendNotificationToUser(
      userId: reg.userId,
      title: 'Chứng chỉ hoàn thành',
      body: 'Bạn đã nhận chứng chỉ cho sự kiện "${event.title}"',
      type: NotificationType.systemAnnouncement,
      data: {
        'type': 'certificateIssued',
        'eventId': reg.eventId,
        'registrationId': reg.id,
        'certificateUrl': url,
      },
    );

    return url;
  }

  Future<int> issueCertificatesForEvent(String eventId) async {
    final regs = await _firestore
        .collection(AppConstants.registrationsCollection)
        .where('eventId', isEqualTo: eventId)
        .get();

    int issued = 0;
    for (final doc in regs.docs) {
      final reg = RegistrationModel.fromFirestore(doc);
      if ((reg.attended || reg.checkedOutAt != null) &&
          (reg.certificateUrl == null)) {
        try {
          await issueCertificateForRegistration(reg);
          issued++;
        } catch (_) {}
      }
    }
    return issued;
  }
}
