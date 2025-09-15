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
import '../organizer/support_registrations_screen.dart';
import 'event_coorganizers_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../services/registration_service.dart';
import '../../services/auth_service.dart';
import '../../services/certificate_service.dart';
import '../../models/registration_model.dart';
import '../../models/support_registration_model.dart';
import 'package:qr_flutter/qr_flutter.dart' as qr;
import 'package:url_launcher/url_launcher.dart';

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });
}

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen>
    with WidgetsBindingObserver {
  EventModel? _event;
  bool _isLoading = true;
  String? _errorMessage;
  final RegistrationService _registrationService = RegistrationService();
  final AuthService _authService = AuthService();
  final CertificateService _certificateService = CertificateService();
  RegistrationModel? _myRegistration;
  SupportRegistrationModel? _mySupportRegistration;
  int _pendingCount = 0;
  int _approvedCount = 0;
  Map<String, String> _coOrganizerNames = {}; // userId -> name

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadEvent();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _event != null) {
      _loadParticipantCount();
    }
  }

  Future<void> _loadEvent() async {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      EventModel? event = await eventProvider.getEventById(widget.eventId);

      if (event != null &&
          authProvider.currentUser?.role == 'student' &&
          event.status != AppConstants.eventPublished) {
        setState(() {
          _errorMessage = 'Sự kiện này chưa được duyệt hoặc không tồn tại';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _event = event;
        _isLoading = false;
      });
      await _loadMyRegistrationIfNeeded();
      await _loadOrganizerSummaryIfNeeded();
      await _loadParticipantCount();
      await _loadCoOrganizerNames();
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
      await Future.delayed(const Duration(milliseconds: 500));
      final participantReg = await _registrationService
          .getUserRegistrationForEvent(_event!.id, user.id);
      final supportReg = await _registrationService
          .getUserSupportRegistrationForEvent(_event!.id, user.id);
      if (mounted) {
        setState(() {
          _myRegistration = participantReg;
          _mySupportRegistration = supportReg;
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

  Future<void> _loadParticipantCount() async {
    if (_event == null) return;
    try {
      final regs = await _registrationService.getEventRegistrations(_event!.id);

      int approved = 0;
      for (final r in regs) {
        if (r.isApproved) approved++;
      }

      if (mounted) {
        setState(() {
          _approvedCount = approved;
        });
      }
    } catch (e) {}
  }

  Future<void> _loadCoOrganizerNames() async {
    if (_event == null || _event!.coOrganizers.isEmpty) return;

    try {
      final names = <String, String>{};

      for (final userId in _event!.coOrganizers) {
        try {
          final user = await _authService.getUserById(userId);
          if (user != null) {
            names[userId] = user.fullName;
          } else {
            names[userId] = 'Unknown User';
          }
        } catch (e) {
          names[userId] = 'Unknown User';
        }
      }

      if (mounted) {
        setState(() {
          _coOrganizerNames = names;
        });
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null || _event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Event not found',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
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
    final bool isCoOrganizer = _event!.coOrganizers.contains(currentUser?.id);
    final bool isEventOrganizer = isEventHost || isCoOrganizer;
    final bool canRegisterBase =
        _event!.isRegistrationOpen &&
        !(isAdmin || isOrganizerRole || isEventOrganizer);
    final bool hasActiveRegistration =
        (_myRegistration != null &&
            (_myRegistration!.isPending || _myRegistration!.isApproved) &&
            !_myRegistration!.isCancelled) ||
        (_mySupportRegistration != null &&
            (_mySupportRegistration!.isPending ||
                _mySupportRegistration!.isApproved) &&
            !_mySupportRegistration!.isCancelled);
    final bool canRegister = canRegisterBase && !hasActiveRegistration;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              onPressed: () {
                final role = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).currentUser?.role;
                final fallback = role == 'admin' ? '/admin/approvals' : '/home';
                safePop(context, fallbackRoute: fallback);
              },
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _event!.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCompactDashboard(),
                  const SizedBox(height: 24),
                  if (isAdmin && _event!.status == 'pending') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings,
                                  color: AppColors.warning,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Admin Approval',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Review this pending event and make a decision.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showRejectDialog(),
                                  icon: const Icon(
                                    Icons.close,
                                    color: AppColors.white,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Reject',
                                    style: TextStyle(color: AppColors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _approveEvent(),
                                  icon: const Icon(
                                    Icons.check,
                                    color: AppColors.white,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Approve',
                                    style: TextStyle(color: AppColors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.description,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _event!.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_event!.requirements != null &&
                      _event!.requirements!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFF59E0B,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.assignment,
                                  color: Color(0xFFF59E0B),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Requirements',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _event!.requirements!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_event!.contactInfo != null &&
                      _event!.contactInfo!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.contact_phone,
                                  color: Color(0xFF10B981),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Contact Info',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _event!.contactInfo!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_event!.organizerId ==
                      Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).currentUser?.id) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.analytics,
                                  color: AppColors.info,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Registrations',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildChip(
                                'Pending',
                                _pendingCount,
                                AppColors.warning,
                              ),
                              const SizedBox(width: 8),
                              _buildChip(
                                'Approved',
                                _approvedCount,
                                AppColors.success,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 80),
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
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildCompactDashboard() {
    final dateFormatter = DateFormat(AppConstants.dateTimeFormat);
    final timeFormatter = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.dashboard,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Event Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildCompactInfoCard(
                Icons.play_arrow,
                'Start',
                dateFormatter.format(_event!.startDate.toLocal()),
                timeFormatter.format(_event!.startDate.toLocal()),
                const Color(0xFF10B981),
              ),
              _buildCompactInfoCard(
                Icons.stop,
                'End',
                dateFormatter.format(_event!.endDate.toLocal()),
                timeFormatter.format(_event!.endDate.toLocal()),
                const Color(0xFFF59E0B),
              ),
              _buildCompactInfoCard(
                Icons.location_on,
                'Venue',
                _event!.location,
                '',
                const Color(0xFF8B5CF6),
              ),
              _buildCompactInfoCard(
                Icons.person,
                'Organizer',
                _event!.organizerName,
                '',
                const Color(0xFF6366F1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  Icons.people,
                  '$_approvedCount/${_event!.maxParticipants}',
                  'Participants',
                  _approvedCount >= _event!.maxParticipants
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF3B82F6),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventRegistrationsScreen(
                          eventId: _event!.id,
                          eventTitle: _event!.title,
                        ),
                      ),
                    );
                    _loadOrganizerSummaryIfNeeded();
                  },
                ),
              ),
              const SizedBox(width: 8),
              if (_event!.maxSupportStaff > 0)
                Expanded(
                  child: _buildStatsCard(
                    Icons.support_agent,
                    '${_event!.currentSupportStaff}/${_event!.maxSupportStaff}',
                    'Support',
                    const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SupportRegistrationsScreen(
                            eventId: _event!.id,
                            eventTitle: _event!.title,
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                const Expanded(child: SizedBox()),
              const SizedBox(width: 8),
              if (!_event!.isFree)
                Expanded(
                  child: _buildStatsCard(
                    Icons.attach_money,
                    NumberFormat.currency(
                      locale: 'en_US',
                      symbol: '\$',
                    ).format(_event!.price),
                    'Fee',
                    const Color(0xFF059669),
                  ),
                )
              else
                Expanded(
                  child: _buildStatsCard(
                    Icons.free_breakfast,
                    'Free',
                    'Event',
                    const Color(0xFF10B981),
                  ),
                ),
            ],
          ),
          if (_event!.coOrganizers.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Co-Organizers',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _event!.coOrganizers.map((userId) {
                final name = _coOrganizerNames[userId] ?? 'Loading...';
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventCoOrganizersScreen(
                          eventId: _event!.id,
                          eventTitle: _event!.title,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactInfoCard(
    IconData icon,
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    IconData icon,
    String value,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final currentUser = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser;
    final isEventHost = _event!.organizerId == currentUser?.id;
    final isCoOrganizer = _event!.coOrganizers.contains(currentUser?.id);
    final isEventOrganizer = isEventHost || isCoOrganizer;
    final bool showQrButton =
        _myRegistration?.isApproved == true && !isEventOrganizer;

    final List<_ActionItem> actions = [];

    if (_event!.videoUrls.isNotEmpty) {
      actions.add(
        _ActionItem(
          icon: Icons.play_circle_fill,
          label: 'Video',
          color: AppColors.primary,
          onPressed: _openEventVideo,
        ),
      );
    }

    actions.add(
      _ActionItem(
        icon: Icons.chat,
        label: 'Chat',
        color: const Color(0xFF10B981),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventChatScreen(eventId: _event!.id),
            ),
          );
        },
      ),
    );

    if (showQrButton) {
      actions.add(
        _ActionItem(
          icon: Icons.qr_code,
          label: 'QR Code',
          color: AppColors.success,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Check-in QR Code'),
                  content: SizedBox(
                    width: 240,
                    height: 240,
                    child: Center(
                      child: _myRegistration?.qrCode != null
                          ? qr.QrImageView(
                              data: _myRegistration!.qrCode!,
                              version: qr.QrVersions.auto,
                            )
                          : const Text('No QR Code'),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                );
              },
            );
          },
        ),
      );
    }

    if (isEventOrganizer) {
      actions.addAll([
        _ActionItem(
          icon: Icons.qr_code_scanner,
          label: 'Manage',
          color: const Color(0xFFF59E0B),
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
        ),
        _ActionItem(
          icon: Icons.group_add,
          label: 'Co-org',
          color: const Color(0xFF8B5CF6),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventCoOrganizersScreen(
                  eventId: _event!.id,
                  eventTitle: _event!.title,
                ),
              ),
            );
          },
        ),
      ]);
    }

    final List<_ActionItem> primary = actions.take(4).toList();
    final List<_ActionItem> overflow = actions.skip(4).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              for (int i = 0; i < primary.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: primary[i].icon,
                    label: primary[i].label,
                    color: primary[i].color,
                    onPressed: primary[i].onPressed,
                  ),
                ),
              ],
              if (overflow.isNotEmpty) ...[
                if (primary.isNotEmpty) const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.more_horiz,
                    label: 'More',
                    color: const Color(0xFF6B7280),
                    onPressed: () => _showMoreActions(overflow),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreActions(List<_ActionItem> items) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: item.color.withOpacity(0.12),
                  child: Icon(item.icon, color: item.color),
                ),
                title: Text(
                  item.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  item.onPressed();
                },
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemCount: items.length,
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    height: 1.05,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Technology':
        return AppColors.academicColor;
      case 'Sports':
        return AppColors.sportsColor;
      case 'Culture':
        return AppColors.cultureColor;
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
        return 'Published';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      case AppConstants.eventDraft:
        return 'Draft';
      case AppConstants.eventCancelled:
        return 'Cancelled';
      case AppConstants.eventCompleted:
        return 'Completed';
      default:
        return 'Unknown';
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

    if (_event!.isRegistrationOpen) {
      if (hasActiveRegistration) {
        String buttonText = '';
        Color buttonColor = AppColors.warning;
        IconData buttonIcon = Icons.hourglass_top;

        if (_myRegistration != null) {
          if (_myRegistration!.isPending) {
            buttonText = 'Registration Pending';
            buttonColor = AppColors.warning;
            buttonIcon = Icons.hourglass_top;
          } else if (_myRegistration!.isApproved) {
            buttonText = 'Registration Approved';
            buttonColor = AppColors.success;
            buttonIcon = Icons.check_circle;
          } else if (_myRegistration!.isRejected) {
            buttonText = 'Registration Rejected';
            buttonColor = AppColors.error;
            buttonIcon = Icons.cancel;
          }
        } else if (_mySupportRegistration != null) {
          if (_mySupportRegistration!.isPending) {
            buttonText = 'Support Registration Pending';
            buttonColor = AppColors.warning;
            buttonIcon = Icons.hourglass_top;
          } else if (_mySupportRegistration!.isApproved) {
            buttonText = 'Support Registration Approved';
            buttonColor = AppColors.success;
            buttonIcon = Icons.check_circle;
          } else if (_mySupportRegistration!.isRejected) {
            buttonText = 'Support Registration Rejected';
            buttonColor = AppColors.error;
            buttonIcon = Icons.cancel;
          }
        }

        return FloatingActionButton.extended(
          onPressed:
              (_myRegistration?.isApproved == true ||
                  _mySupportRegistration?.isApproved == true)
              ? () {
                  // Navigate to registration detail screen for cancellation
                  context.push('/event/${widget.eventId}/register');
                }
              : null,
          backgroundColor: buttonColor,
          icon: Icon(buttonIcon, color: AppColors.white),
          label: Text(
            buttonText,
            style: const TextStyle(color: AppColors.white),
          ),
        );
      } else {
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
          icon: const Icon(Icons.add, color: AppColors.white),
          label: const Text(
            'Register for Event',
            style: TextStyle(color: AppColors.white),
          ),
        );
      }
    }
    return null;
  }

  Future<void> _openEventVideo() async {
    if (_event == null || _event!.videoUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event has no video'),
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
          content: Text('Cannot open video'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _approveEvent() async {
    if (_event == null) return;

    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      await adminProvider.approveEvent(_event!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event approved successfully'),
            backgroundColor: AppColors.success,
          ),
        );

        await _loadEvent();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving event: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  } 
  void _showRejectDialog() {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please provide a reason for rejecting this event:'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'Enter rejection reason...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a rejection reason'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                  return;
                }
                _rejectEvent(reasonController.text.trim());
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text(
                'Reject',
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _rejectEvent(String reason) async {
    if (_event == null) return;

    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      await adminProvider.rejectEvent(_event!.id, reason);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event rejected successfully'),
            backgroundColor: AppColors.error,
          ),
        );

        await _loadEvent();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting event: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
