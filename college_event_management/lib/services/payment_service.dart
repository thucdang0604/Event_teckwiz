import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Thanh toán giả lập cho sự kiện có phí
  Future<Map<String, dynamic>> processMockPayment({
    required String eventId,
    required String userId,
    required String userEmail,
    required String userName,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      // Tạo payment ID giả lập
      String paymentId = 'PAY_${DateTime.now().millisecondsSinceEpoch}';

      // Giả lập thời gian xử lý thanh toán (1-3 giây)
      await Future.delayed(Duration(seconds: 2));

      // Giả lập kết quả thanh toán (luôn thành công trong môi trường test)
      return {
        'success': true,
        'paymentId': paymentId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'paidAt': DateTime.now(),
        'transactionId': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
      };
    } catch (e) {
      throw Exception('Lỗi xử lý thanh toán: ${e.toString()}');
    }
  }

  // Cập nhật registration với thông tin thanh toán
  Future<void> updateRegistrationWithPayment({
    required String registrationId,
    required String paymentId,
    required double amount,
    required String paymentMethod,
    required DateTime paidAt,
  }) async {
    try {
      await _firestore.collection('registrations').doc(registrationId).update({
        'isPaid': true,
        'paidAt': Timestamp.fromDate(paidAt),
        'paymentId': paymentId,
        'paymentMethod': paymentMethod,
        'amountPaid': amount,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Lỗi cập nhật thông tin thanh toán: ${e.toString()}');
    }
  }

  // Kiểm tra xem sự kiện có cần thanh toán không
  bool requiresPayment(EventModel event) {
    return !event.isFree && event.price != null && event.price! > 0;
  }

  // Lấy danh sách phương thức thanh toán hỗ trợ (chỉ ngân hàng)
  List<Map<String, dynamic>> getSupportedPaymentMethods() {
    return [
      {
        'id': 'bank_transfer',
        'name': 'Chuyển khoản ngân hàng',
        'icon': '🏦',
        'description': 'Thanh toán qua chuyển khoản ngân hàng',
      },
    ];
  }

  // Hoàn tiền giả lập
  Future<Map<String, dynamic>> processMockRefund({
    required String paymentId,
    required double amount,
    String method = 'bank_transfer',
  }) async {
    try {
      await Future.delayed(Duration(seconds: 1));
      return {
        'success': true,
        'refundId': 'REF_${DateTime.now().millisecondsSinceEpoch}',
        'refundedAt': DateTime.now(),
        'refundMethod': method,
        'refundAmount': amount,
      };
    } catch (e) {
      throw Exception('Lỗi hoàn tiền: ${e.toString()}');
    }
  }
}
