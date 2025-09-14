import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/registration_service.dart';
import '../../models/event_model.dart';
import '../../models/registration_model.dart';
import '../../models/support_registration_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/payment_popup.dart';

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
  bool _isLoading = false;
  String? _errorMessage;
  String _registrationType = 'participant'; // 'participant' or 'support'
  RegistrationModel? _myRegistration;
  SupportRegistrationModel? _mySupportRegistration;

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

      // Debug logging
      print('DEBUG: Loading registrations for event: ${widget.event.id}');
      print('DEBUG: User ID: ${authProvider.currentUser!.id}');
      print('DEBUG: participantReg = $participantReg');
      print('DEBUG: supportReg = $supportReg');

      if (participantReg != null) {
        print(
          'Registration found - Status: ${participantReg.status}, isApproved: ${participantReg.isApproved}, isPaid: ${participantReg.isPaid}',
        );
      }

      setState(() {
        _myRegistration = participantReg;
        _mySupportRegistration = supportReg;
      });
    } catch (e) {
      print('Error loading registrations: $e');
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
          // Kiểm tra xem sự kiện có phí không
          if (!widget.event.isFree &&
              widget.event.price != null &&
              widget.event.price! > 0) {
            // Hiển thị popup thanh toán cho sự kiện có phí
            _showPaymentDialog();
          } else {
            // Đăng ký miễn phí
            await _processRegistration();
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

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Support staff registration successful! Please wait for approval.',
                ),
                backgroundColor: AppColors.success,
              ),
            );

            // Gửi thông báo đăng ký support staff thành công
            final notificationProvider = Provider.of<NotificationProvider>(
              context,
              listen: false,
            );
            await notificationProvider.sendRegistrationSuccessNotification(
              userId: authProvider.currentUser!.id,
              eventTitle: widget.event.title,
              eventId: widget.event.id,
            );

            await _loadMyRegistrations();
            context.pop();
          }
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => PaymentPopup(
        amount: widget.event.price!,
        eventTitle: widget.event.title,
        onPaymentComplete: (success, paymentId) async {
          if (success) {
            await _processRegistration(
              isPaid: true,
              amountPaid: widget.event.price!,
              paymentMethod: 'card',
              paymentId: paymentId,
            );
          } else {
            setState(() {
              _isLoading = false;
            });
          }
        },
      ),
    );
  }

  Future<void> _processRegistration({
    bool isPaid = false,
    double? amountPaid,
    String? paymentMethod,
    String? paymentId,
  }) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final selectedLocationName = widget.event.location;

      String registrationId = await _registrationService.registerForEvent(
        eventId: widget.event.id,
        userId: authProvider.currentUser!.id,
        userEmail: authProvider.currentUser!.email,
        userName: authProvider.currentUser!.fullName,
        additionalInfo: {
          'note': _additionalInfoController.text.trim(),
          'location': selectedLocationName,
        },
        isPaid: isPaid,
        amountPaid: amountPaid,
        paymentMethod: paymentMethod,
        paymentId: paymentId,
      );

      // Nếu đã thanh toán, cập nhật trạng thái thanh toán
      if (isPaid && paymentId != null) {
        await _registrationService.processPayment(
          registrationId: registrationId,
          amount: amountPaid!,
          paymentMethod: paymentMethod!,
          paymentId: paymentId,
        );
      } else {
        // Nếu không thanh toán, vẫn cần cập nhật số lượng người tham gia
        await _registrationService.updateEventParticipantCount(widget.event.id);
      }

      if (mounted) {
        // Lấy thông tin đăng ký mới tạo để hiển thị mã QR
        RegistrationModel? newRegistration = await _registrationService
            .getRegistrationById(registrationId);

        String message = 'Đăng ký thành công!';
        if (isPaid) {
          message += ' Thanh toán đã được xử lý.';
        }

        if (newRegistration != null && newRegistration.qrCode != null) {
          message += ' Mã QR đã được tạo.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.success),
        );

        // Gửi thông báo đăng ký thành công
        final notificationProvider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        await notificationProvider.sendRegistrationSuccessNotification(
          userId: authProvider.currentUser!.id,
          eventTitle: widget.event.title,
          eventId: widget.event.id,
        );

        // Nếu đã thanh toán, gửi thông báo thanh toán thành công
        if (isPaid && amountPaid != null) {
          await notificationProvider.sendPaymentSuccessNotification(
            userId: authProvider.currentUser!.id,
            eventTitle: widget.event.title,
            amount: amountPaid,
            eventId: widget.event.id,
          );
        }

        await _loadMyRegistrations();

        // Refresh event data để cập nhật số lượng người tham gia
        final eventProvider = Provider.of<EventProvider>(
          context,
          listen: false,
        );
        await eventProvider.getEventById(widget.event.id);

        context.pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getRegistrationStatusText() {
    if (_myRegistration != null) {
      if (_myRegistration!.isApproved ||
          _myRegistration!.status == AppConstants.registrationPaid) {
        if (_myRegistration!.isPaid) {
          return 'Đăng ký đã được chấp nhận và thanh toán thành công!';
        } else {
          return 'Đăng ký đã được chấp nhận!';
        }
      } else if (_myRegistration!.isInQueue) {
        return 'Bạn đang trong hàng đợi (vị trí ${_myRegistration!.queuePosition}). Sẽ được thông báo khi có chỗ trống.';
      } else {
        return 'Đăng ký đang chờ duyệt.';
      }
    } else if (_mySupportRegistration != null) {
      if (_mySupportRegistration!.isApproved) {
        return 'Đăng ký hỗ trợ đã được chấp nhận!';
      } else {
        return 'Đăng ký hỗ trợ đang chờ duyệt.';
      }
    }
    return '';
  }

  String _getRegisterButtonText() {
    if (_registrationType == 'participant') {
      if (!widget.event.isFree &&
          widget.event.price != null &&
          widget.event.price! > 0) {
        return 'Đăng ký và thanh toán (${widget.event.price!.toStringAsFixed(0)} VNĐ)';
      } else {
        return 'Đăng ký tham gia';
      }
    } else {
      return 'Đăng ký hỗ trợ';
    }
  }

  String _getTermsText() {
    if (_registrationType == 'participant') {
      if (!widget.event.isFree &&
          widget.event.price != null &&
          widget.event.price! > 0) {
        return 'Bằng cách đăng ký, bạn đồng ý với điều khoản sự kiện. Đăng ký sẽ được tự động chấp nhận sau khi thanh toán thành công.';
      } else {
        return 'Bằng cách đăng ký, bạn đồng ý với điều khoản sự kiện. Đăng ký sẽ được tự động chấp nhận.';
      }
    } else {
      return 'Bằng cách đăng ký hỗ trợ, bạn đồng ý giúp tổ chức sự kiện. Đăng ký sẽ được xem xét bởi người tổ chức.';
    }
  }

  void _cancelRegistration() async {
    // Kiểm tra xem có cần xác nhận hủy đăng ký không
    bool shouldCancel = await _showCancelConfirmationDialog();
    if (!shouldCancel) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_myRegistration != null) {
        // Nếu đã thanh toán, tự động hoàn tiền
        if (_myRegistration!.isPaid) {
          await _registrationService.refundRegistration(_myRegistration!.id);
        } else {
          await _registrationService.cancelRegistration(_myRegistration!.id);
        }
      } else if (_mySupportRegistration != null) {
        await _registrationService.cancelSupportRegistration(
          _mySupportRegistration!.id,
        );
      }

      if (mounted) {
        String message = _myRegistration?.isPaid == true
            ? 'Hủy đăng ký và hoàn tiền thành công! Số tiền ${_myRegistration?.amountPaid?.toStringAsFixed(0) ?? '0'} VNĐ sẽ được hoàn về tài khoản của bạn trong vòng 3-5 ngày làm việc.'
            : 'Hủy đăng ký thành công!';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.success,
            duration: Duration(
              seconds: _myRegistration?.isPaid == true ? 5 : 3,
            ),
          ),
        );

        // Gửi thông báo hủy đăng ký
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final notificationProvider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        if (authProvider.currentUser != null) {
          await notificationProvider.sendCancellationNotification(
            userId: authProvider.currentUser!.id,
            eventTitle: widget.event.title,
            eventId: widget.event.id,
            isRefund: _myRegistration?.isPaid == true,
            refundAmount: _myRegistration?.amountPaid,
          );
        }

        await _loadMyRegistrations();

        // Refresh event data để cập nhật số lượng người tham gia
        final eventProvider = Provider.of<EventProvider>(
          context,
          listen: false,
        );
        await eventProvider.getEventById(widget.event.id);
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

  Future<bool> _showCancelConfirmationDialog() async {
    bool isPaid = _myRegistration?.isPaid ?? false;
    String title = isPaid ? 'Hủy đăng ký và hoàn tiền' : 'Hủy đăng ký';
    String content = isPaid
        ? 'Bạn đã thanh toán cho sự kiện này. Việc hủy đăng ký sẽ tự động hoàn tiền ${_myRegistration?.amountPaid?.toStringAsFixed(0) ?? '0'} VNĐ về tài khoản của bạn trong vòng 3-5 ngày làm việc. Bạn có chắc chắn muốn hủy?'
        : 'Bạn có chắc chắn muốn hủy đăng ký sự kiện này?';

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Không'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    isPaid ? 'Có, hủy và hoàn tiền' : 'Có, hủy đăng ký',
                    style: TextStyle(
                      color: isPaid ? AppColors.warning : AppColors.error,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
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

    // Check if user already has any active registration
    final bool hasAnyActiveRegistration =
        _myRegistration != null || _mySupportRegistration != null;
    final bool canRegister =
        widget.event.isRegistrationOpen && !hasAnyActiveRegistration;

    // Debug logging
    print('DEBUG: _myRegistration = $_myRegistration');
    print('DEBUG: _mySupportRegistration = $_mySupportRegistration');
    print('DEBUG: hasAnyActiveRegistration = $hasAnyActiveRegistration');
    print('DEBUG: canRegister = $canRegister');

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
                    if (hasAnyActiveRegistration) ...[
                      // Debug logging
                      Text('DEBUG: Showing registration status card'),
                      Card(
                        color:
                            (_myRegistration?.isApproved == true ||
                                _myRegistration?.status ==
                                    AppConstants.registrationPaid ||
                                _mySupportRegistration?.isApproved == true)
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.warning.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    (_myRegistration?.isApproved == true ||
                                            _myRegistration?.status ==
                                                AppConstants.registrationPaid ||
                                            _mySupportRegistration
                                                    ?.isApproved ==
                                                true)
                                        ? Icons.check_circle
                                        : Icons.schedule,
                                    color:
                                        (_myRegistration?.isApproved == true ||
                                            _myRegistration?.status ==
                                                AppConstants.registrationPaid ||
                                            _mySupportRegistration
                                                    ?.isApproved ==
                                                true)
                                        ? AppColors.success
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
                                _getRegistrationStatusText(),
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // Nút hủy đăng ký (tự động hoàn tiền nếu đã thanh toán)
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _isLoading
                                          ? null
                                          : _cancelRegistration,
                                      icon: Icon(
                                        _myRegistration?.isPaid == true
                                            ? Icons.money_off
                                            : Icons.cancel,
                                      ),
                                      label: Text(
                                        _myRegistration?.isPaid == true
                                            ? 'Hủy đăng ký và hoàn tiền'
                                            : 'Hủy đăng ký',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            _myRegistration?.isPaid == true
                                            ? AppColors.warning
                                            : AppColors.error,
                                        foregroundColor: AppColors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else if (!canRegister) ...[
                      // Debug logging
                      Text('DEBUG: Showing cannot register message'),
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
                      // Debug logging
                      Text('DEBUG: Showing registration form'),
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
                            // Price information
                            if (!widget.event.isFree &&
                                widget.event.price != null &&
                                widget.event.price! > 0) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.payment,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Phí tham gia: ${widget.event.price!.toStringAsFixed(0)} VNĐ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
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
                        text: _getRegisterButtonText(),
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
                          _getTermsText(),
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
