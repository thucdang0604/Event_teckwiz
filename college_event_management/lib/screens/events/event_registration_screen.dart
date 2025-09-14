import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart' as qr;
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/registration_service.dart';
import '../../services/payment_service.dart';
import '../../models/event_model.dart';
import '../../models/registration_model.dart';
import '../../models/support_registration_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class EventRegistrationScreen extends StatefulWidget {
  final EventModel event;

  const EventRegistrationScreen({super.key, required this.event});

  @override
  State<EventRegistrationScreen> createState() =>
      _EventRegistrationScreenState();
}

class _EventRegistrationScreenState extends State<EventRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _additionalInfoController = TextEditingController();
  final _registrationService = RegistrationService();
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  String? _errorMessage;
  String _registrationType = 'participant'; // 'participant' or 'support'
  RegistrationModel? _myRegistration;
  SupportRegistrationModel? _mySupportRegistration;
  String _selectedPaymentMethod = 'bank_transfer';

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _loadMyRegistrations();
  }

  @override
  void dispose() {
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.loadLocations();
  }

  Future<void> _loadMyRegistrations() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    try {
      final participantReg = await _registrationService
          .getUserRegistrationForEvent(
            widget.event.id,
            authProvider.currentUser!.id,
          );
      final supportReg = await _registrationService
          .getUserSupportRegistrationForEvent(
            widget.event.id,
            authProvider.currentUser!.id,
          );

      setState(() {
        _myRegistration = participantReg;
        _mySupportRegistration = supportReg;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  void _registerForEvent() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        if (authProvider.currentUser == null) {
          setState(() {
            _errorMessage = 'Please login to register for event';
            _isLoading = false;
          });
          return;
        }

        final selectedLocationName = widget.event.location;

        if (_registrationType == 'participant') {
          // Kiểm tra xem sự kiện có cần thanh toán không
          if (_paymentService.requiresPayment(widget.event)) {
            // Hiển thị dialog chọn phương thức thanh toán
            setState(() {
              _isLoading = false;
            });
            _showPaymentMethodDialog();
            return;
          } else {
            // Đăng ký miễn phí
            await _registrationService.registerForEvent(
              eventId: widget.event.id,
              userId: authProvider.currentUser!.id,
              userEmail: authProvider.currentUser!.email,
              userName: authProvider.currentUser!.fullName,
              additionalInfo: {
                'note': _additionalInfoController.text.trim(),
                'location': selectedLocationName,
              },
            );
          }
        } else {
          await _registrationService.registerForSupportStaff(
            eventId: widget.event.id,
            userId: authProvider.currentUser!.id,
            userEmail: authProvider.currentUser!.email,
            userName: authProvider.currentUser!.fullName,
            additionalInfo: {
              'note': _additionalInfoController.text.trim(),
              'location': selectedLocationName,
            },
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _registrationType == 'participant'
                    ? 'Registration successful! Please wait for approval.'
                    : 'Support staff registration successful! Please wait for approval.',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          // Delay một chút để đảm bảo data đã được lưu
          await Future.delayed(const Duration(milliseconds: 500));
          await _loadMyRegistrations();
          context.pop();
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showPaymentMethodDialog() {
    showDialog(context: context, builder: (context) => _buildPaymentDialog());
  }

  void _processPayment() async {
    setState(() {
      _isLoading = true;
    });
    Navigator.of(context).pop(); // Đóng dialog

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final selectedLocationName = widget.event.location;

      await _registrationService.registerForEventWithPayment(
        eventId: widget.event.id,
        userId: authProvider.currentUser!.id,
        userEmail: authProvider.currentUser!.email,
        userName: authProvider.currentUser!.fullName,
        paymentMethod: _selectedPaymentMethod,
        additionalInfo: {
          'note': _additionalInfoController.text.trim(),
          'location': selectedLocationName,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đăng ký và thanh toán thành công! Đã được tự động duyệt.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        // Delay một chút để đảm bảo data đã được lưu
        await Future.delayed(const Duration(milliseconds: 500));
        await _loadMyRegistrations();
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _cancelRegistration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_myRegistration != null) {
        await _registrationService.cancelRegistration(_myRegistration!.id);
      } else if (_mySupportRegistration != null) {
        await _registrationService.cancelSupportRegistration(
          _mySupportRegistration!.id,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration cancelled successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadMyRegistrations();

        // Refresh notification provider
        final notificationProvider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        await notificationProvider.forceRefresh();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showQRCode() {
    if (_myRegistration != null) {
      _showQRCodeDialog(
        _myRegistration!,
        'Participant QR Code',
        'Registration',
      );
    } else if (_mySupportRegistration != null) {
      _showQRCodeDialog(
        _mySupportRegistration!,
        'Support Staff QR Code',
        'Support',
      );
    }
  }

  void _showQRCodeDialog(dynamic registration, String title, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              ),
              child: Column(
                children: [
                  // QR Code Widget
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: qr.QrImageView(
                      data: registration.qrCode ?? '',
                      version: qr.QrVersions.auto,
                      size: 120,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$type ID: ${registration.id.substring(0, 8)}...',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Show this QR code at the event for check-in',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDialog() {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.account_balance, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Thanh toán qua ngân hàng',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('🏦', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chuyển khoản ngân hàng',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            'Thanh toán qua chuyển khoản ngân hàng',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Số tiền cần thanh toán:',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat.currency(
                          locale: 'vi_VN',
                          symbol: '₫',
                        ).format(widget.event.price),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: AppColors.info, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đây là thanh toán giả lập. Sau khi thanh toán thành công, đăng ký sẽ được tự động duyệt.',
                          style: TextStyle(fontSize: 12, color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Xác nhận thanh toán'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final bool isAdmin = currentUser?.role == 'admin';
    final bool isOrganizerRole = currentUser?.role == 'organizer';
    final bool isEventHost = widget.event.organizerId == currentUser?.id;

    if (isAdmin || isOrganizerRole || isEventHost) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Registration')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.block, size: 56, color: AppColors.warning),
                SizedBox(height: 12),
                Text(
                  'Only students need to register. Administrators and organizers do not need to register.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Check if user already has any active registration (not cancelled)
    final bool hasAnyRegistration =
        (_myRegistration != null && !_myRegistration!.isCancelled) ||
        (_mySupportRegistration != null &&
            !_mySupportRegistration!.isCancelled);
    final bool canRegister =
        widget.event.isRegistrationOpen && !hasAnyRegistration;

    return Scaffold(
      appBar: AppBar(title: const Text('Event Registration')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 32,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Registration Status Card
                    if (hasAnyRegistration) ...[
                      Card(
                        color:
                            _myRegistration?.isApproved == true ||
                                _mySupportRegistration?.isApproved == true
                            ? AppColors.success.withOpacity(0.1)
                            : _myRegistration?.isCancelled == true ||
                                  _mySupportRegistration?.isCancelled == true
                            ? AppColors.error.withOpacity(0.1)
                            : AppColors.warning.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _myRegistration?.isApproved == true ||
                                            _mySupportRegistration
                                                    ?.isApproved ==
                                                true
                                        ? Icons.check_circle
                                        : _myRegistration?.isCancelled ==
                                                  true ||
                                              _mySupportRegistration
                                                      ?.isCancelled ==
                                                  true
                                        ? Icons.cancel_outlined
                                        : Icons.schedule,
                                    color:
                                        _myRegistration?.isApproved == true ||
                                            _mySupportRegistration
                                                    ?.isApproved ==
                                                true
                                        ? AppColors.success
                                        : _myRegistration?.isCancelled ==
                                                  true ||
                                              _mySupportRegistration
                                                      ?.isCancelled ==
                                                  true
                                        ? AppColors.error
                                        : AppColors.warning,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _myRegistration != null
                                        ? 'Participant Registration'
                                        : 'Support Staff Registration',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _myRegistration?.isApproved == true ||
                                        _mySupportRegistration?.isApproved ==
                                            true
                                    ? _myRegistration?.isPaid == true
                                          ? 'Đăng ký đã được duyệt! (Đã thanh toán)'
                                          : 'Đăng ký đã được duyệt!'
                                    : _myRegistration?.isCancelled == true ||
                                          _mySupportRegistration?.isCancelled ==
                                              true
                                    ? 'Đăng ký đã bị hủy.'
                                    : 'Đăng ký đang chờ duyệt.',
                                style: const TextStyle(fontSize: 14),
                              ),
                              if (!(_myRegistration?.isCancelled == true ||
                                  _mySupportRegistration?.isCancelled ==
                                      true)) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _isLoading
                                            ? null
                                            : _cancelRegistration,
                                        icon: const Icon(Icons.cancel),
                                        label: const Text(
                                          'Cancel Registration',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.error,
                                          foregroundColor: AppColors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _isLoading
                                            ? null
                                            : _showQRCode,
                                        icon: const Icon(Icons.qr_code),
                                        label: const Text('Show QR'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: AppColors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else if (!canRegister) ...[
                      Card(
                        color: AppColors.error.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.info, color: AppColors.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.event.isRegistrationOpen
                                      ? 'Registration is not available'
                                      : 'Registration is closed',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      // Registration Type Selection
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Registration Type',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Text('Participant'),
                                      subtitle: const Text(
                                        'Join as event participant',
                                      ),
                                      value: 'participant',
                                      groupValue: _registrationType,
                                      onChanged: (value) {
                                        setState(() {
                                          _registrationType = value!;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Text('Support Staff'),
                                      subtitle: Text(
                                        'Help organize the event (${widget.event.maxSupportStaff} positions available)',
                                      ),
                                      value: 'support',
                                      groupValue: _registrationType,
                                      onChanged:
                                          widget.event.maxSupportStaff > 0
                                          ? (value) {
                                              setState(() {
                                                _registrationType = value!;
                                              });
                                            }
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.event.maxSupportStaff == 0) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'No support staff positions available for this event',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Event Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.event.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.event.description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Start: ${DateFormat(AppConstants.dateTimeFormat).format(widget.event.startDate)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.event,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'End: ${DateFormat(AppConstants.dateTimeFormat).format(widget.event.endDate)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Hiển thị giá sự kiện
                                if (!widget.event.isFree &&
                                    widget.event.price != null) ...[
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.attach_money,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Phí tham gia: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(widget.event.price)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        widget.event.location,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Registration Form (only show if can register)
                    if (canRegister) ...[
                      Text(
                        _registrationType == 'participant'
                            ? 'Participant Registration'
                            : 'Support Staff Registration',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // User Info Display
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.greyLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Registration Information:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, _) {
                                return Column(
                                  children: [
                                    _buildInfoRow(
                                      'Full Name',
                                      authProvider.currentUser?.fullName ?? '',
                                    ),
                                    _buildInfoRow(
                                      'Email',
                                      authProvider.currentUser?.email ?? '',
                                    ),
                                    if (authProvider.currentUser?.phoneNumber !=
                                        null)
                                      _buildInfoRow(
                                        'Phone',
                                        authProvider.currentUser!.phoneNumber!,
                                      ),
                                    if (authProvider.currentUser?.studentId !=
                                        null)
                                      _buildInfoRow(
                                        'Student ID',
                                        authProvider.currentUser!.studentId!,
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Location fixed to event's location
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Event Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.grey),
                              borderRadius: BorderRadius.circular(12),
                              color: AppColors.greyLight,
                            ),
                            child: Text(
                              widget.event.location,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Additional Info
                      CustomTextField(
                        controller: _additionalInfoController,
                        label: 'Additional Notes (Optional)',
                        hint: 'Enter any special requests or notes...',
                        maxLines: 3,
                      ),

                      const SizedBox(height: 24),

                      // Media removed per requirement
                      const SizedBox(height: 24),

                      // Event Requirements
                      if (widget.event.requirements != null) ...[
                        const Text(
                          'Participation Requirements:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.warning.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            widget.event.requirements!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Error Message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.error.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_errorMessage != null) const SizedBox(height: 16),

                      // Register Button
                      CustomButton(
                        text: _registrationType == 'participant'
                            ? 'Register as Participant'
                            : 'Register as Support Staff',
                        onPressed: _isLoading ? null : _registerForEvent,
                        isLoading: _isLoading,
                      ),

                      const SizedBox(height: 16),

                      // Terms and Conditions
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _registrationType == 'participant'
                              ? 'By registering, you agree to the event terms and conditions. Your registration will be reviewed by the organizer.'
                              : 'By registering as support staff, you agree to help organize the event. Your registration will be reviewed by the organizer.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
