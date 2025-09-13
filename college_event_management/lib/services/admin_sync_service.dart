import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';

class AdminSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _studentsCollection = 'students';
  static const String _publicStudentsCollection = 'public_students';

  Future<void> syncStudentsToPublic() async {
    try {
      QuerySnapshot studentsSnapshot = await _firestore
          .collection(_studentsCollection)
          .get();

      WriteBatch batch = _firestore.batch();

      for (QueryDocumentSnapshot doc in studentsSnapshot.docs) {
        Map<String, dynamic> studentData = doc.data() as Map<String, dynamic>;

        DocumentReference publicDocRef = _firestore
            .collection(_publicStudentsCollection)
            .doc(doc.id);

        batch.set(publicDocRef, studentData);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Lỗi đồng bộ dữ liệu sinh viên: ${e.toString()}');
    }
  }

  Future<void> addStudentToPublic(StudentModel student) async {
    try {
      await _firestore
          .collection(_publicStudentsCollection)
          .doc(student.id)
          .set(student.toFirestore());
    } catch (e) {
      throw Exception(
        'Lỗi thêm sinh viên vào public collection: ${e.toString()}',
      );
    }
  }

  Future<void> updateStudentInPublic(StudentModel student) async {
    try {
      await _firestore
          .collection(_publicStudentsCollection)
          .doc(student.id)
          .update(student.toFirestore());
    } catch (e) {
      throw Exception(
        'Lỗi cập nhật sinh viên trong public collection: ${e.toString()}',
      );
    }
  }

  Future<void> deleteStudentFromPublic(String studentId) async {
    try {
      await _firestore
          .collection(_publicStudentsCollection)
          .doc(studentId)
          .delete();
    } catch (e) {
      throw Exception(
        'Lỗi xóa sinh viên khỏi public collection: ${e.toString()}',
      );
    }
  }

  Future<Map<String, dynamic>> getSyncStats() async {
    try {
      QuerySnapshot studentsSnapshot = await _firestore
          .collection(_studentsCollection)
          .get();

      QuerySnapshot publicStudentsSnapshot = await _firestore
          .collection(_publicStudentsCollection)
          .get();

      return {
        'totalStudents': studentsSnapshot.docs.length,
        'totalPublicStudents': publicStudentsSnapshot.docs.length,
        'isSynced':
            studentsSnapshot.docs.length == publicStudentsSnapshot.docs.length,
      };
    } catch (e) {
      throw Exception('Lỗi lấy thống kê đồng bộ: ${e.toString()}');
    }
  }
}
