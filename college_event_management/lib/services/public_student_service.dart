import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';

class PublicStudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collectionName = 'students';

  Future<StudentModel?> getStudentByStudentId(String studentId) async {
    try {
      // First try: Query by studentId field
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return StudentModel.fromFirestore(snapshot.docs.first);
      }

      // Second try: Get all documents and search manually
      QuerySnapshot allSnapshot = await _firestore
          .collection(_collectionName)
          .get();

      for (QueryDocumentSnapshot doc in allSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['studentId'] == studentId) {
          return StudentModel.fromFirestore(doc);
        }
      }

      return null;
    } catch (e) {
      throw Exception('Lỗi tìm sinh viên theo mã số: ${e.toString()}');
    }
  }

  Future<StudentModel?> getStudentByEmail(String email) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return StudentModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi tìm sinh viên theo email: ${e.toString()}');
    }
  }

  Future<bool> validateStudentRegistration(
    String email,
    String studentId,
  ) async {
    try {
      StudentModel? studentByEmail = await getStudentByEmail(email);
      StudentModel? studentById = await getStudentByStudentId(studentId);

      if (studentByEmail == null || studentById == null) {
        return false;
      }

      return studentByEmail.id == studentById.id &&
          studentByEmail.studentId == studentId;
    } catch (e) {
      throw Exception('Lỗi xác thực đăng ký sinh viên: ${e.toString()}');
    }
  }

  Future<bool> isStudentExists(String studentId, String email) async {
    try {
      StudentModel? studentByEmail = await getStudentByEmail(email);
      StudentModel? studentById = await getStudentByStudentId(studentId);

      return studentByEmail != null || studentById != null;
    } catch (e) {
      throw Exception('Lỗi kiểm tra sinh viên tồn tại: ${e.toString()}');
    }
  }
}
