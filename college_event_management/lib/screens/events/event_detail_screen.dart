import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/navigation_helper.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../events/event_registration_screen.dart';
import '../events/event_registrations_screen.dart';
import '../events/event_attendance_screen.dart';
import '../chat/event_chat_screen.dart';
import '../../providers/auth_provider.dart';
import '../../services/registration_service.dart';
import '../../models/registration_model.dart';
import 'package:qr_flutter/qr_flutter.dart' as qr;
import 'package:url_launcher/url_launcher.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  EventModel? _event;
  bool _isLoading = true;
  String? _errorMessage;
  final RegistrationService _registrationService = RegistrationService();
  RegistrationModel? _myRegistration;
  int _pendingCount = 0;
  int _approvedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);

    try {
      EventModel? event = await eventProvider.getEventById(widget.eventId);
      setState(() {
        _event = event;
        _isLoading = false;
      });
      await _loadMyRegistrationIfNeeded();
      await _loadOrganizerSummaryIfNeeded();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMyRegistrationIfNeeded() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null || _event == null) return;
    try {
      final reg = await _registrationService.getUserRegistrationForEvent(
        _event!.id,
        user.id,
      );
      if (mounted) {
        setState(() {
          _myRegistration = reg;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadOrganizerSummaryIfNeeded() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null || _event == null) return;
    if (_event!.organizerId != user.id) return;
    try {
      final regs = await _registrationService.getEventRegistrations(_event!.id);
      int pending = 0;
      int approved = 0;
      for (final r in regs) {
        if (r.isPending) pending++;
        if (r.isApproved) approved++;
      }
      if (mounted) {
        setState(() {
          _pendingCount = pending;
          _approvedCount = approved;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null || _event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Không tìm thấy sự kiện',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    final currentUser = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser;
    final bool isAdmin = currentUser?.role == 'admin';
    final bool isOrganizerRole = currentUser?.role == 'organizer';
    final bool isEventHost = _event!.organizerId == currentUser?.id;
    final bool canRegisterBase =
        _event!.isRegistrationOpen &&
        !(isAdmin || isOrganizerRole || isEventHost);
    final bool hasActiveRegistration =
        _myRegistration != null &&
        (_myRegistration!.isPending || _myRegistration!.isApproved);
    final bool canRegister = canRegisterBase && !hasActiveRegistration;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with image
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              onPressed: () => safePop(context, fallbackRoute: '/home'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _getCategoryColor(_event!.category).withOpacity(0.8),
                      _getCategoryColor(_event!.category),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    if (_event!.imageUrls.isNotEmpty)
                      PageView.builder(
                        itemCount: _event!.imageUrls.length,
                        itemBuilder: (context, index) {
                          return Image.network(
                            _event!.imageUrls[index],
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    else
                      Center(
                        child: Icon(
                          Icons.event,
                          size: 120,
                          color: AppColors.white.withOpacity(0.3),
                        ),
                      ),
                    // Category badge
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _event!.category,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Status badge
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            _event!.status,
                          ).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(_event!.status),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Event content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event title
                  Text(
                    _event!.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Event details
                  _buildDetailRow(
                    Icons.calendar_today,
                    'Ngày bắt đầu',
                    DateFormat(
                      AppConstants.dateTimeFormat,
                    ).format(_event!.startDate),
                  ),

                  _buildDetailRow(
                    Icons.calendar_today,
                    'Ngày kết thúc',
                    DateFormat(
                      AppConstants.dateTimeFormat,
                    ).format(_event!.endDate),
                  ),

                  _buildDetailRow(
                    Icons.location_on,
                    'Địa điểm',
                    _event!.location,
                  ),

                  _buildDetailRow(
                    Icons.person,
                    'Người tổ chức',
                    _event!.organizerName,
                  ),

                  _buildDetailRow(
                    Icons.people,
                    'Số lượng tham gia',
                    '${_event!.currentParticipants}/${_event!.maxParticipants}',
                  ),

                  if (!_event!.isFree)
                    _buildDetailRow(
                      Icons.attach_money,
                      'Phí tham gia',
                      '${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(_event!.price)}',
                    ),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Mô tả sự kiện',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _event!.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  if (_event!.requirements != null) ...[
                    const SizedBox(height: 24),

                    const Text(
                      'Yêu cầu tham gia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _event!.requirements!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],

                  if (_event!.contactInfo != null) ...[
                    const SizedBox(height: 24),

                    const Text(
                      'Thông tin liên hệ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _event!.contactInfo!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],

                  // Organizer summary
                  if (_event!.organizerId ==
                      Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).currentUser?.id) ...[
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Đăng ký của sinh viên',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildChip(
                                    'Chờ duyệt',
                                    _pendingCount,
                                    AppColors.warning,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildChip(
                                    'Đã duyệt',
                                    _approvedCount,
                                    AppColors.success,
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EventRegistrationsScreen(
                                                eventId: _event!.id,
                                                eventTitle: _event!.title,
                                              ),
                                        ),
                                      );
                                      _loadOrganizerSummaryIfNeeded();
                                    },
                                    icon: const Icon(Icons.list),
                                    label: const Text('Xem danh sách'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 100), // Space for floating button
                ],
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: _buildFloatingActionButton(
        isAdmin: isAdmin,
        isOrganizerRole: isOrganizerRole,
        isEventHost: isEventHost,
        canRegister: canRegister,
        hasActiveRegistration: hasActiveRegistration,
      ),
      persistentFooterButtons: [
        // QR Scanner Button
        ElevatedButton.icon(
          onPressed: _openEventVideo,
          icon: const Icon(Icons.play_circle_fill),
          label: const Text('Xem video'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
        ),

        // Chat Button
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventChatScreen(eventId: _event!.id),
              ),
            );
          },
          icon: const Icon(Icons.chat),
          label: const Text('Chat'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.white,
          ),
        ),

        // Manage Attendance Button (for organizers)
        if (_event!.organizerId ==
            Provider.of<AuthProvider>(context, listen: false).currentUser?.id)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventAttendanceScreen(
                    eventId: _event!.id,
                    eventTitle: _event!.title,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.people),
            label: const Text('Quản lý'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: AppColors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Học thuật':
        return AppColors.academicColor;
      case 'Thể thao':
        return AppColors.sportsColor;
      case 'Văn hóa - Nghệ thuật':
        return AppColors.cultureColor;
      case 'Tình nguyện':
        return AppColors.volunteerColor;
      case 'Kỹ năng mềm':
        return AppColors.skillsColor;
      case 'Hội thảo':
        return AppColors.workshopColor;
      case 'Triển lãm':
        return AppColors.exhibitionColor;
      default:
        return AppColors.otherColor;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.eventPublished:
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      case AppConstants.eventDraft:
        return AppColors.warning;
      case AppConstants.eventCancelled:
        return AppColors.error;
      case AppConstants.eventCompleted:
        return AppColors.info;
      default:
        return AppColors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case AppConstants.eventPublished:
        return 'Đã xuất bản';
      case 'pending':
        return 'Chờ duyệt';
      case 'rejected':
        return 'Từ chối';
      case AppConstants.eventDraft:
        return 'Bản nháp';
      case AppConstants.eventCancelled:
        return 'Đã hủy';
      case AppConstants.eventCompleted:
        return 'Đã hoàn thành';
      default:
        return 'Không xác định';
    }
  }

  Widget _buildChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $count',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton({
    required bool isAdmin,
    required bool isOrganizerRole,
    required bool isEventHost,
    required bool canRegister,
    required bool hasActiveRegistration,
  }) {
    if (_event == null) return null;
    if (isAdmin || isOrganizerRole || isEventHost) return null;

    // If approved registration exists, show View QR button
    if (_myRegistration != null && _myRegistration!.isApproved) {
      return FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Mã QR Check-in'),
                content: SizedBox(
                  width: 240,
                  height: 240,
                  child: Center(
                    child: _myRegistration!.qrCode != null
                        ? qr.QrImageView(
                            data: _myRegistration!.qrCode!,
                            version: qr.QrVersions.auto,
                          )
                        : const Text('Không có mã QR'),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: AppColors.success,
        icon: const Icon(Icons.qr_code, color: AppColors.white),
        label: const Text(
          'Xem mã QR',
          style: TextStyle(color: AppColors.white),
        ),
      );
    }

    // Show register button or pending state
    if (_event!.isRegistrationOpen) {
      return FloatingActionButton.extended(
        onPressed: canRegister
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EventRegistrationScreen(event: _event!),
                  ),
                ).then((_) => _loadMyRegistrationIfNeeded());
              }
            : null,
        backgroundColor: canRegister ? AppColors.primary : AppColors.grey,
        icon: Icon(
          hasActiveRegistration ? Icons.hourglass_top : Icons.add,
          color: AppColors.white,
        ),
        label: Text(
          hasActiveRegistration ? 'Đang chờ duyệt' : 'Đăng ký tham gia',
          style: const TextStyle(color: AppColors.white),
        ),
      );
    }
    return null;
  }

  Future<void> _openEventVideo() async {
    if (_event == null || _event!.videoUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sự kiện chưa có video'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    final url = _event!.videoUrls.first;
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không mở được video'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
