import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;

  static Future<void> initialize() async {
    // Firebase is already initialized in main.dart
    // No need to initialize again
  }

  static User? get currentUser => auth.currentUser;
  static String? get currentUserId => currentUser?.uid;

  static Future<void> signOut() async {
    await auth.signOut();
  }

  static Stream<User?> get authStateChanges => auth.authStateChanges();
}
