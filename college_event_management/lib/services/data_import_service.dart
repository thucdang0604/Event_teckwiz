import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';

class DataImportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> importSampleStudents() async {
    try {
      String jsonString = await rootBundle.loadString(
        'assets/sample_students.json',
      );
      List<dynamic> jsonList = json.decode(jsonString);

      List<StudentModel> students = jsonList.map((json) {
        return StudentModel.fromJson({
          ...json,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }).toList();

      await _importToStudentsCollection(students);
      await _importToPublicStudentsCollection(students);
    } catch (e) {
      throw Exception('Lỗi import dữ liệu mẫu: ${e.toString()}');
    }
  }

  Future<void> _importToStudentsCollection(List<StudentModel> students) async {
    try {
      WriteBatch batch = _firestore.batch();

      for (StudentModel student in students) {
        DocumentReference docRef = _firestore
            .collection('students')
            .doc(student.id);
        batch.set(docRef, student.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Lỗi import vào collection students: ${e.toString()}');
    }
  }

  Future<void> _importToPublicStudentsCollection(
    List<StudentModel> students,
  ) async {
    try {
      WriteBatch batch = _firestore.batch();

      for (StudentModel student in students) {
        DocumentReference docRef = _firestore
            .collection('public_students')
            .doc(student.id);
        batch.set(docRef, student.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      throw Exception(
        'Lỗi import vào collection public_students: ${e.toString()}',
      );
    }
  }

  Future<void> clearAllStudents() async {
    try {
      await _clearCollection('students');
      await _clearCollection('public_students');
    } catch (e) {
      throw Exception('Lỗi xóa dữ liệu: ${e.toString()}');
    }
  }

  Future<void> _clearCollection(String collectionName) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(collectionName)
          .get();
      WriteBatch batch = _firestore.batch();

      for (QueryDocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Lỗi xóa collection $collectionName: ${e.toString()}');
    }
  }

  Future<Map<String, int>> getCollectionStats() async {
    try {
      QuerySnapshot studentsSnapshot = await _firestore
          .collection('students')
          .get();
      QuerySnapshot publicStudentsSnapshot = await _firestore
          .collection('public_students')
          .get();

      return {
        'students': studentsSnapshot.docs.length,
        'public_students': publicStudentsSnapshot.docs.length,
      };
    } catch (e) {
      throw Exception('Lỗi lấy thống kê: ${e.toString()}');
    }
  }

  Future<void> copyStudentsToPublic() async {
    try {
      QuerySnapshot studentsSnapshot = await _firestore
          .collection('students')
          .get();

      WriteBatch batch = _firestore.batch();

      for (QueryDocumentSnapshot doc in studentsSnapshot.docs) {
        Map<String, dynamic> studentData = doc.data() as Map<String, dynamic>;

        DocumentReference publicDocRef = _firestore
            .collection('public_students')
            .doc(doc.id);

        batch.set(publicDocRef, studentData);
      }

      await batch.commit();
    } catch (e) {
      throw Exception(
        'Lỗi copy dữ liệu từ students sang public_students: ${e.toString()}',
      );
    }
  }
}
