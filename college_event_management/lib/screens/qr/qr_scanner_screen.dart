import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/registration_service.dart';
import '../../models/registration_model.dart';
import '../../models/support_registration_model.dart';
import '../../constants/app_colors.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  final RegistrationService _registrationService = RegistrationService();

  bool _isLoading = false;
  String? _errorMessage;
  RegistrationModel? _scannedRegistration;
  SupportRegistrationModel? _scannedSupportRegistration;
  String _registrationType = ''; // 'participant' or 'support'

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;

    if (barcodes.isNotEmpty) {
      final String qrCode = barcodes.first.rawValue ?? '';

      if (qrCode.isEmpty) return;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Thử tìm participant registration trước
        final registration = await _registrationService.getRegistrationByQRCode(
          qrCode,
        );

        if (registration != null) {
          setState(() {
            _scannedRegistration = registration;
            _scannedSupportRegistration = null;
            _registrationType = 'participant';
            _isLoading = false;
          });
          return;
        }

        // Nếu không tìm thấy participant registration, thử tìm support registration
        final supportRegistration = await _registrationService
            .getSupportRegistrationByQRCode(qrCode);

        if (supportRegistration != null) {
          setState(() {
            _scannedRegistration = null;
            _scannedSupportRegistration = supportRegistration;
            _registrationType = 'support';
            _isLoading = false;
          });
          return;
        }

        // Nếu không tìm thấy cả hai
        setState(() {
          _errorMessage = 'Không tìm thấy đăng ký với mã QR này';
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Lỗi: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAttendance() async {
    if (_scannedRegistration == null && _scannedSupportRegistration == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_registrationType == 'participant' && _scannedRegistration != null) {
        await _registrationService.markAttendance(_scannedRegistration!.id);
      } else if (_registrationType == 'support' &&
          _scannedSupportRegistration != null) {
        await _registrationService.markSupportAttendance(
          _scannedSupportRegistration!.id,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Check-in thành công! (${_registrationType == 'participant' ? 'Tham gia' : 'Hỗ trợ'})',
            ),
            backgroundColor: AppColors.success,
          ),
        );

        setState(() {
          _scannedRegistration = null;
          _scannedSupportRegistration = null;
          _registrationType = '';
          _isLoading = false;
        });
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markCheckout() async {
    if (_scannedRegistration == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _registrationService.markCheckout(_scannedRegistration!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-out thành công!'),
            backgroundColor: AppColors.success,
          ),
        );

        setState(() {
          _scannedRegistration = null;
          _isLoading = false;
        });
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét QR Code'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            onPressed: () => controller.toggleTorch(),
            icon: const Icon(Icons.flashlight_on),
          ),
          IconButton(
            onPressed: () => controller.switchCamera(),
            icon: const Icon(Icons.camera_front),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera View
          MobileScanner(controller: controller, onDetect: _onDetect),

          // Overlay
          Container(
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
            child: Column(
              children: [
                const Spacer(),

                // Scanning Area
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 50),
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(color: Colors.transparent),
                  ),
                ),

                const Spacer(),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    'Đặt mã QR trong khung để quét',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Đang xử lý...',
                      style: TextStyle(color: AppColors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Error Message
          if (_errorMessage != null)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: AppColors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.white),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                      icon: const Icon(Icons.close, color: AppColors.white),
                    ),
                  ],
                ),
              ),
            ),

          // Scanned Registration Info
          if (_scannedRegistration != null ||
              _scannedSupportRegistration != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _registrationType == 'support'
                          ? Icons.support_agent
                          : Icons.check_circle,
                      color: _registrationType == 'support'
                          ? AppColors.warning
                          : AppColors.success,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _registrationType == 'support'
                          ? 'Tìm thấy nhân viên hỗ trợ'
                          : 'Tìm thấy đăng ký',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _registrationType == 'support'
                          ? _scannedSupportRegistration!.userName
                          : _scannedRegistration!.userName,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _registrationType == 'support'
                          ? _scannedSupportRegistration!.userEmail
                          : _scannedRegistration!.userEmail,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _registrationType == 'support'
                            ? AppColors.warning.withOpacity(0.1)
                            : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _registrationType == 'support'
                            ? 'Nhân viên hỗ trợ'
                            : 'Người tham gia',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _registrationType == 'support'
                              ? AppColors.warning
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _scannedRegistration = null;
                                      _scannedSupportRegistration = null;
                                      _registrationType = '';
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.grey,
                              foregroundColor: AppColors.white,
                            ),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _markAttendance,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: AppColors.white,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : Text(
                                    _registrationType == 'support'
                                        ? 'Check-in Hỗ trợ'
                                        : 'Check-in',
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _markCheckout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              foregroundColor: AppColors.white,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : const Text('Check-out'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
