import 'package:cloud_firestore/cloud_firestore.dart';

class DebugFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> debugStudentsCollection() async {
    try {
      print('=== DEBUG STUDENTS COLLECTION ===');

      QuerySnapshot snapshot = await _firestore.collection('students').get();

      print('Total documents: ${snapshot.docs.length}');

      for (int i = 0; i < snapshot.docs.length; i++) {
        DocumentSnapshot doc = snapshot.docs[i];
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        print('Document $i:');
        print('  ID: ${doc.id}');
        print('  studentId: ${data['studentId']}');
        print('  fullName: ${data['fullName']}');
        print('  email: ${data['email']}');
        print('  ---');
      }

      // Test specific search
      print('\n=== TESTING SPECIFIC SEARCH ===');
      QuerySnapshot searchSnapshot = await _firestore
          .collection('students')
          .where('studentId', isEqualTo: 'SV2024001')
          .get();

      print('Search results for SV2024001: ${searchSnapshot.docs.length}');
      if (searchSnapshot.docs.isNotEmpty) {
        DocumentSnapshot foundDoc = searchSnapshot.docs.first;
        Map<String, dynamic> foundData =
            foundDoc.data() as Map<String, dynamic>;
        print('Found student: ${foundData['fullName']}');
      }
    } catch (e) {
      print('ERROR: ${e.toString()}');
    }
  }

  Future<void> testDirectQuery() async {
    try {
      print('=== TESTING DIRECT QUERY ===');

      // Test 1: Get all documents
      QuerySnapshot allDocs = await _firestore.collection('students').get();
      print('All documents count: ${allDocs.docs.length}');

      // Test 2: Search by studentId
      try {
        QuerySnapshot byStudentId = await _firestore
            .collection('students')
            .where('studentId', isEqualTo: 'SV2024001')
            .get();
        print('Documents with studentId SV2024001: ${byStudentId.docs.length}');
      } catch (e) {
        print('ERROR in where query: ${e.toString()}');
        print(
          'This might be an index issue. Check Firebase Console for index requirements.',
        );
      }

      // Test 3: Search by document ID
      DocumentSnapshot byDocId = await _firestore
          .collection('students')
          .doc('student_001')
          .get();
      print('Document with ID student_001 exists: ${byDocId.exists}');
      if (byDocId.exists) {
        Map<String, dynamic> data = byDocId.data() as Map<String, dynamic>;
        print('Document data: ${data['studentId']} - ${data['fullName']}');
      }

      // Test 4: Manual search through all documents
      print('\n=== MANUAL SEARCH ===');
      for (QueryDocumentSnapshot doc in allDocs.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['studentId'] == 'SV2024001') {
          print('FOUND by manual search: ${data['fullName']}');
          break;
        }
      }
    } catch (e) {
      print('ERROR in direct query: ${e.toString()}');
    }
  }
}
