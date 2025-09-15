import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';
import '../services/student_service.dart';
import '../constants/app_constants.dart';
import 'email_scheduler_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StudentService _studentService = StudentService();
  EmailSchedulerService? _emailScheduler;
  EmailSchedulerService get _emailSchedulerInstance =>
      _emailScheduler ??= EmailSchedulerService();

  // Đăng ký người dùng mới
  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? studentId,
    String? department,
    String role = AppConstants.studentRole,
  }) async {
    try {
      // Kiểm tra xác thực sinh viên nếu là role student
      if (role == AppConstants.studentRole) {
        if (studentId == null || studentId.isEmpty) {
          throw Exception('Mã số sinh viên là bắt buộc');
        }

        // Kiểm tra sinh viên có tồn tại trong danh sách không
        StudentModel? student = await _studentService.getStudentByEmail(email);
        if (student == null) {
          throw Exception(
            'Email không có trong danh sách sinh viên được phép đăng ký',
          );
        }

        if (student.studentId != studentId) {
          throw Exception('Mã số sinh viên không khớp với email');
        }

        if (!student.isActive) {
          throw Exception('Tài khoản sinh viên đã bị vô hiệu hóa');
        }
      }

      // Tạo tài khoản Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // Tạo thông tin người dùng trong Firestore
        UserModel newUser = UserModel(
          id: userCredential.user!.uid,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber,
          studentId: studentId,
          department: department,
          role: role,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          approvalStatus: role == AppConstants.adminRole
              ? AppConstants.userApproved
              : AppConstants.userPending,
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userCredential.user!.uid)
            .set(newUser.toFirestore());

        // Gửi welcome email
        try {
          await _emailSchedulerInstance.scheduleWelcomeEmail(
            userEmail: email,
            userName: fullName,
            userRole: role,
          );
          print('✅ Welcome email scheduled for: $email');
        } catch (emailError) {
          print('❌ Error scheduling welcome email: $emailError');
        }

        return newUser;
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi đăng ký: ${e.toString()}');
    }
  }

  // Đăng nhập
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        UserModel? user = await getUserById(userCredential.user!.uid);
        if (user != null) {
          // Kiểm tra tài khoản bị block
          if (user.isBlocked) {
            await _auth.signOut();
            throw Exception('BLOCKED_USER');
          }
          // Admin luôn được phép đăng nhập, bỏ qua kiểm tra approval
          if (user.role != AppConstants.adminRole) {
            // Kiểm tra tài khoản chưa được duyệt (chỉ áp dụng cho non-admin)
            if (user.approvalStatus != AppConstants.userApproved) {
              await _auth.signOut();
              throw Exception(
                'Tài khoản của bạn chưa được duyệt. Vui lòng liên hệ admin để được kích hoạt tài khoản.',
              );
            }
          }
        }
        return user;
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi đăng nhập: ${e.toString()}');
    }
  }

  // Đăng nhập ẩn danh (cho demo)
  Future<UserModel?> signInAnonymously() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();

      if (userCredential.user != null) {
        // Tạo user model cho anonymous user
        UserModel anonymousUser = UserModel(
          id: userCredential.user!.uid,
          email: 'anonymous@example.com',
          fullName: 'Người dùng ẩn danh',
          role: AppConstants.studentRole,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userCredential.user!.uid)
            .set(anonymousUser.toFirestore());

        return anonymousUser;
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi đăng nhập ẩn danh: ${e.toString()}');
    }
  }

  // Lấy thông tin người dùng theo ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi lấy thông tin người dùng: ${e.toString()}');
    }
  }

  // Cập nhật thông tin người dùng
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .update(user.toFirestore());
    } catch (e) {
      throw Exception('Lỗi cập nhật thông tin: ${e.toString()}');
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Lỗi đăng xuất: ${e.toString()}');
    }
  }

  // Đặt lại mật khẩu
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Lỗi đặt lại mật khẩu: ${e.toString()}');
    }
  }

  // Đổi mật khẩu
  Future<void> changePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw Exception('Không tìm thấy người dùng hiện tại');
      }
    } catch (e) {
      throw Exception('Lỗi đổi mật khẩu: ${e.toString()}');
    }
  }

  // Lấy người dùng hiện tại
  User? get currentUser => _auth.currentUser;

  // Stream để theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Admin duyệt tài khoản
  Future<void> approveUser(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'approvalStatus': AppConstants.userApproved,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      throw Exception('Lỗi duyệt tài khoản: ${e.toString()}');
    }
  }

  // Admin từ chối tài khoản
  Future<void> rejectUser(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'approvalStatus': AppConstants.userRejected,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      throw Exception('Lỗi từ chối tài khoản: ${e.toString()}');
    }
  }

  // Admin block tài khoản
  Future<void> blockUser(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'isBlocked': true,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      throw Exception('Lỗi block tài khoản: ${e.toString()}');
    }
  }

  // Admin unblock tài khoản
  Future<void> unblockUser(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'isBlocked': false,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      throw Exception('Lỗi unblock tài khoản: ${e.toString()}');
    }
  }

  // Cập nhật active status
  Future<void> updateUserActiveStatus(String userId, bool isActive) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'isActive': isActive,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      throw Exception('Lỗi cập nhật trạng thái hoạt động: ${e.toString()}');
    }
  }

  // Lấy danh sách tài khoản chờ duyệt
  Future<List<UserModel>> getPendingUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('approvalStatus', isEqualTo: AppConstants.userPending)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Lỗi lấy danh sách tài khoản chờ duyệt: ${e.toString()}');
    }
  }

  // Lấy tất cả tài khoản
  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Lỗi lấy danh sách tài khoản: ${e.toString()}');
    }
  }

  // Cập nhật tài khoản admin cũ (migration)
  Future<void> updateLegacyAdminUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.adminRole)
          .get();

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Kiểm tra nếu admin chưa có approvalStatus hoặc isBlocked
        if (!data.containsKey('approvalStatus') ||
            !data.containsKey('isBlocked')) {
          Map<String, dynamic> updateData = {
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          };

          if (!data.containsKey('approvalStatus')) {
            updateData['approvalStatus'] = AppConstants.userApproved;
          }

          if (!data.containsKey('isBlocked')) {
            updateData['isBlocked'] = false;
          }

          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(doc.id)
              .update(updateData);
        }
      }
    } catch (e) {
      throw Exception('Lỗi cập nhật admin cũ: ${e.toString()}');
    }
  }

  // Lấy thông tin người dùng theo email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return UserModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting user by email: ${e.toString()}');
    }
  }
}
