import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
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
              'Registration and payment successful! Automatically approved.',
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

  Widget _buildCancelButton() {
    final now = DateTime.now();
    final eventStart = widget.event.startDate.toLocal();
    final eventEnd = widget.event.endDate.toLocal();

    final isEventHappening = eventStart.isBefore(now) && eventEnd.isAfter(now);
    final isEventStarted = eventStart.isBefore(now);
    final isEventEnded = eventEnd.isBefore(now);

    // Don't show cancel button if event has ended
    if (isEventEnded) {
      return const SizedBox.shrink();
    }

    if (isEventHappening) {
      return ElevatedButton.icon(
        onPressed: null, // Disabled during event
        icon: const Icon(Icons.block),
        label: const Text('Event in Progress - Cannot Cancel'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      );
    }

    if (isEventStarted) {
      return ElevatedButton.icon(
        onPressed: null, // Disabled after event started
        icon: const Icon(Icons.block),
        label: const Text('Event Started - Cannot Cancel'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handleCancelOrRefund,
      icon: Icon(
        _myRegistration?.isPaid == true ? Icons.money_off : Icons.cancel,
      ),
      label: Text(
        _myRegistration?.isPaid == true
            ? 'Cancel & Request Refund'
            : 'Cancel Registration',
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _myRegistration?.isPaid == true
            ? AppColors.warning
            : AppColors.error,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  Future<void> _handleCancelOrRefund() async {
    // Check if event is currently happening or has already started
    final now = DateTime.now();
    final eventStart = widget.event.startDate.toLocal();
    final eventEnd = widget.event.endDate.toLocal();

    // Check if event is currently in progress
    final isEventInProgress = eventStart.isBefore(now) && eventEnd.isAfter(now);

    // Check if event has already started (even if ended)
    final isEventStarted = eventStart.isBefore(now);

    if (isEventInProgress) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot cancel registration during the event. Please contact the organizer.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (isEventStarted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot cancel registration after the event has started. Please contact the organizer.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (_myRegistration?.isPaid == true) {
      // If paid, show refund dialog
      await _requestRefund();
    } else {
      // If not paid, just cancel registration
      await _cancelRegistration();
    }
  }

  Future<void> _cancelRegistration() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Registration'),
        content: const Text(
          'Are you sure you want to cancel your registration? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
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
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling registration: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _requestRefund() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Refund'),
        content: const Text(
          'Are you sure you want to request a refund? This will cancel your registration and process a refund.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Request Refund'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Simulate refund process
        await Future.delayed(const Duration(seconds: 2));

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
              content: Text(
                'Refund requested successfully. You will receive your money back within 3-5 business days.',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error processing refund: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
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
                          locale: 'en_US',
                          symbol: '\$',
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
                          'This is a simulated payment. After successful payment, registration will be automatically approved.',
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

    // Check registration availability with detailed conditions
    final bool isRegistrationDeadlinePassed = DateTime.now().isAfter(
      widget.event.registrationDeadline,
    );
    final bool isEventStarted = DateTime.now().isAfter(widget.event.startDate);
    final bool isEventInProgress =
        DateTime.now().isAfter(widget.event.startDate) &&
        DateTime.now().isBefore(widget.event.endDate);
    final bool isEventFull = widget.event.isFull;
    final bool isEventPublished = widget.event.isPublished;

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
                                          ? 'Registration approved! (Paid)'
                                          : 'Registration approved!'
                                    : _myRegistration?.isCancelled == true ||
                                          _mySupportRegistration?.isCancelled ==
                                              true
                                    ? 'Registration cancelled.'
                                    : 'Registration pending approval.',
                                style: const TextStyle(fontSize: 14),
                              ),
                              // Show cancel button for approved registrations regardless of registration status
                              if (_myRegistration?.isApproved == true ||
                                  _mySupportRegistration?.isApproved ==
                                      true) ...[
                                const SizedBox(height: 12),
                                Center(child: _buildCancelButton()),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.info,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Registration Not Available',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getRegistrationUnavailableReason(
                                  isRegistrationDeadlinePassed,
                                  isEventStarted,
                                  isEventInProgress,
                                  isEventFull,
                                  isEventPublished,
                                  hasAnyRegistration,
                                ),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Show cancel button for approved registrations even when registration is closed
                      if (hasAnyRegistration &&
                          (_myRegistration?.isApproved == true ||
                              _mySupportRegistration?.isApproved == true)) ...[
                        Center(child: _buildCancelButton()),
                        const SizedBox(height: 16),
                      ],
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
                                      'Start: ${DateFormat(AppConstants.dateTimeFormat).format(widget.event.startDate.toLocal())}',
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
                                      'End: ${DateFormat(AppConstants.dateTimeFormat).format(widget.event.endDate.toLocal())}',
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
                                        'Participation Fee: ${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(widget.event.price)}',
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

  String _getRegistrationUnavailableReason(
    bool isRegistrationDeadlinePassed,
    bool isEventStarted,
    bool isEventInProgress,
    bool isEventFull,
    bool isEventPublished,
    bool hasAnyRegistration,
  ) {
    if (hasAnyRegistration) {
      return 'You have already registered for this event.';
    }

    if (!isEventPublished) {
      return 'This event is not yet published.';
    }

    if (isEventInProgress) {
      return 'Registration is not available during the event.';
    }

    if (isEventStarted) {
      return 'Registration is not available after the event has started.';
    }

    if (isRegistrationDeadlinePassed) {
      return 'Registration deadline has passed.';
    }

    if (isEventFull) {
      return 'This event is full. No more participants can be accepted.';
    }

    return 'Registration is currently not available.';
  }
}
