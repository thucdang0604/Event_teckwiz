import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../events/event_registration_screen.dart';
import '../events/event_registrations_screen.dart';
import '../qr/qr_scanner_screen.dart';
import '../chat/event_chat_screen.dart';
import '../../providers/auth_provider.dart';

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
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with image
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
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
                    // Event image placeholder
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

                  const SizedBox(height: 100), // Space for floating button
                ],
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: _event!.isRegistrationOpen
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EventRegistrationScreen(event: _event!),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: AppColors.white),
              label: const Text(
                'Đăng ký tham gia',
                style: TextStyle(color: AppColors.white),
              ),
            )
          : null,
      persistentFooterButtons: [
        // QR Scanner Button
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QRScannerScreen()),
            );
          },
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Quét QR'),
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

        // Manage Registrations Button (for organizers)
        if (_event!.organizerId ==
            Provider.of<AuthProvider>(context, listen: false).currentUser?.id)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventRegistrationsScreen(
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
}
