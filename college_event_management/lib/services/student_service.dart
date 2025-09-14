import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import 'admin_sync_service.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AdminSyncService _syncService = AdminSyncService();

  static const String _collectionName = 'students';

  Future<void> addStudent(StudentModel student) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(student.id)
          .set(student.toFirestore());

      await _syncService.addStudentToPublic(student);
    } catch (e) {
      throw Exception('Lỗi thêm sinh viên: ${e.toString()}');
    }
  }

  Future<void> addMultipleStudents(List<StudentModel> students) async {
    try {
      WriteBatch batch = _firestore.batch();

      for (StudentModel student in students) {
        DocumentReference docRef = _firestore
            .collection(_collectionName)
            .doc(student.id);
        batch.set(docRef, student.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Lỗi thêm nhiều sinh viên: ${e.toString()}');
    }
  }

  Future<StudentModel?> getStudentById(String studentId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(studentId)
          .get();

      if (doc.exists) {
        return StudentModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi lấy thông tin sinh viên: ${e.toString()}');
    }
  }

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

  Future<List<StudentModel>> getAllStudents() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StudentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Lỗi lấy danh sách sinh viên: ${e.toString()}');
    }
  }

  Future<List<StudentModel>> searchStudents(String query) async {
    try {
      if (query.isEmpty) {
        return await getAllStudents();
      }

      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('fullName', isGreaterThanOrEqualTo: query)
          .where('fullName', isLessThan: '${query}z')
          .orderBy('fullName')
          .get();

      List<StudentModel> students = snapshot.docs
          .map((doc) => StudentModel.fromFirestore(doc))
          .toList();

      students.addAll(
        (await _firestore
                .collection(_collectionName)
                .where('studentId', isGreaterThanOrEqualTo: query)
                .where('studentId', isLessThan: '${query}z')
                .orderBy('studentId')
                .get())
            .docs
            .map((doc) => StudentModel.fromFirestore(doc))
            .toList(),
      );

      students.addAll(
        (await _firestore
                .collection(_collectionName)
                .where('email', isGreaterThanOrEqualTo: query.toLowerCase())
                .where('email', isLessThan: '${query.toLowerCase()}z')
                .orderBy('email')
                .get())
            .docs
            .map((doc) => StudentModel.fromFirestore(doc))
            .toList(),
      );

      return students.toSet().toList();
    } catch (e) {
      throw Exception('Lỗi tìm kiếm sinh viên: ${e.toString()}');
    }
  }

  Future<void> updateStudent(StudentModel student) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(student.id)
          .update(student.toFirestore());

      await _syncService.updateStudentInPublic(student);
    } catch (e) {
      throw Exception('Lỗi cập nhật sinh viên: ${e.toString()}');
    }
  }

  Future<void> deleteStudent(String studentId) async {
    try {
      await _firestore.collection(_collectionName).doc(studentId).delete();
      await _syncService.deleteStudentFromPublic(studentId);
    } catch (e) {
      throw Exception('Lỗi xóa sinh viên: ${e.toString()}');
    }
  }

  Future<void> importStudentsFromJson(
    List<Map<String, dynamic>> jsonData,
  ) async {
    try {
      List<StudentModel> students = jsonData
          .map((json) => StudentModel.fromJson(json))
          .toList();

      await addMultipleStudents(students);
    } catch (e) {
      throw Exception('Lỗi import sinh viên từ JSON: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getStudentStats() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .get();

      int totalStudents = snapshot.docs.length;
      int activeStudents = snapshot.docs
          .where(
            (doc) => (doc.data() as Map<String, dynamic>)['isActive'] == true,
          )
          .length;

      return {
        'totalStudents': totalStudents,
        'activeStudents': activeStudents,
        'inactiveStudents': totalStudents - activeStudents,
      };
    } catch (e) {
      throw Exception('Lỗi lấy thống kê sinh viên: ${e.toString()}');
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

  Future<void> syncAllStudentsToPublic() async {
    try {
      await _syncService.syncStudentsToPublic();
    } catch (e) {
      throw Exception('Lỗi đồng bộ tất cả sinh viên: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getSyncStats() async {
    try {
      return await _syncService.getSyncStats();
    } catch (e) {
      throw Exception('Lỗi lấy thống kê đồng bộ: ${e.toString()}');
    }
  }
}
