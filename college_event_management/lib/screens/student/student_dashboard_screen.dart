import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../models/event_model.dart';
import '../../models/registration_model.dart';
import '../events/event_detail_screen.dart';
import '../../services/registration_service.dart';
import '../../services/event_service.dart';
import '../qr/student_qr_scanner_screen.dart';
import 'package:qr_flutter/qr_flutter.dart' as qr;

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() async {
    try {
      await Future.wait([
        context.read<EventProvider>().loadUpcomingEvents(),
        context.read<EventProvider>().loadEvents(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.currentUser?.fullName ?? 'Student';

    return Scaffold(
      backgroundColor: const Color(0xfff9fafb),
      body: SafeArea(
        child: Column(
          children: [
            _header(context, userName),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: 5,
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return _HomeTab(
                        onNavigateToTab: (tabIndex) {
                          setState(() {
                            _currentIndex = tabIndex;
                          });
                          _pageController.animateToPage(
                            tabIndex,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      );
                    case 1:
                      return const _EventsTab();
                    case 2:
                      return const _TicketsTab();
                    case 3:
                      return const _CertificatesTab();
                    case 4:
                      return _ProfileTab(onLogout: _showLogoutConfirmation);
                    default:
                      return _HomeTab(
                        onNavigateToTab: (tabIndex) {
                          setState(() {
                            _currentIndex = tabIndex;
                          });
                          _pageController.animateToPage(
                            tabIndex,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_num_outlined),
            label: 'Tickets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.workspace_premium_outlined),
            label: 'Certificates',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String userName) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $userName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Welcome to your dashboard',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
                ),
              ],
            ),
          ),
          _logoutIconButton(context),
        ],
      ),
    );
  }

  Widget _logoutIconButton(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(22),
      ),
      child: IconButton(
        onPressed: authProvider.isLoading
            ? null
            : () {
                _showLogoutConfirmation(context, authProvider);
              },
        icon: authProvider.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.error),
                ),
              )
            : Icon(Icons.logout, color: AppColors.error),
      ),
    );
  }

  void _showLogoutConfirmation(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text(
            'Are you sure you want to logout from your account?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await authProvider.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}

class _HomeTab extends StatelessWidget {
  final Function(int) onNavigateToTab;

  const _HomeTab({required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _welcomeCard(context),
          const SizedBox(height: 16),
          _quickActions(context),
        ],
      ),
    );
  }

  Widget _welcomeCard(BuildContext context) {
    final eventProvider = context.read<EventProvider>();
    final totalAvailable = eventProvider.events.length;
    final totalRegistered = eventProvider.filteredEvents.length;
    final totalCompleted = eventProvider.events
        .where((e) => e.isCompleted)
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Event Statistics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statItem('Available', totalAvailable.toString()),
              ),
              Expanded(
                child: _statItem('Registered', totalRegistered.toString()),
              ),
              Expanded(
                child: _statItem('Completed', totalCompleted.toString()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _quickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _actionCard(
                icon: Icons.qr_code_scanner,
                color: Colors.white,
                iconColor: AppColors.primary,
                title: 'Scan QR',
                desc: 'Event details',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const StudentQRScannerScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionCard(
                icon: Icons.workspace_premium,
                color: Colors.white,
                iconColor: const Color(0xFF3b82f6),
                title: 'Certificates',
                desc: 'View certificates',
                onTap: () {
                  onNavigateToTab(3); // Navigate to Certificates tab
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _actionCard(
                icon: Icons.event,
                color: Colors.white,
                iconColor: const Color(0xFF10b981),
                title: 'Events',
                desc: 'Browse all',
                onTap: () {
                  onNavigateToTab(1); // Navigate to Events tab
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionCard(
                icon: Icons.confirmation_num,
                color: Colors.white,
                iconColor: const Color(0xFFf59e0b),
                title: 'Tickets',
                desc: 'Your tickets',
                onTap: () {
                  onNavigateToTab(2); // Navigate to Tickets tab
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventsTab extends StatefulWidget {
  const _EventsTab();

  @override
  State<_EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<_EventsTab> {
  String _selectedStatus = 'all';

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();

    // Filter events based on status only
    final filteredEvents = eventProvider.events.where((event) {
      // Hide draft events for students
      if (event.isDraft) return false;

      // Status filter
      final matchesStatus =
          _selectedStatus == 'all' ||
          (_selectedStatus == 'published' && event.isPublished) ||
          (_selectedStatus == 'pending' && event.isPending) ||
          (_selectedStatus == 'rejected' && event.isRejected) ||
          (_selectedStatus == 'cancelled' && event.isCancelled) ||
          (_selectedStatus == 'completed' && event.isCompleted);

      return matchesStatus;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('All Events'),
          const SizedBox(height: 8),
          _buildStatusFilter(),
          const SizedBox(height: 16),
          if (eventProvider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (filteredEvents.isEmpty)
            _emptyState(
              icon: Icons.event_busy,
              title: _selectedStatus != 'all'
                  ? 'No Events Found'
                  : 'No Events Available',
              desc: _selectedStatus != 'all'
                  ? 'Try adjusting your filter criteria.'
                  : 'There are currently no events available. Please check back later for new events.',
            )
          else
            Column(
              children: filteredEvents
                  .map((e) => _eventCard2(e, context))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatusChip('All', 'all'),
          const SizedBox(width: 8),
          _buildStatusChip('Published', 'published'),
          const SizedBox(width: 8),
          _buildStatusChip('Pending', 'pending'),
          const SizedBox(width: 8),
          _buildStatusChip('Rejected', 'rejected'),
          const SizedBox(width: 8),
          _buildStatusChip('Cancelled', 'cancelled'),
          const SizedBox(width: 8),
          _buildStatusChip('Completed', 'completed'),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final isSelected = _selectedStatus == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF1f2937),
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text(
            'View All',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(icon, size: 48, color: const Color(0xFF9ca3af)),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6b7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<RegistrationModel?> _getRegistrationStatus(
    String eventId,
    BuildContext context,
  ) async {
    final currentUser = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentUser;
    if (currentUser == null) return null;

    try {
      final registrationService = RegistrationService();
      final registration = await registrationService
          .getUserRegistrationForEvent(eventId, currentUser.id);
      return registration;
    } catch (e) {
      return null;
    }
  }

  Widget _eventCard2(EventModel event, BuildContext context) {
    return FutureBuilder<RegistrationModel?>(
      future: _getRegistrationStatus(event.id, context),
      builder: (context, snapshot) {
        final registration = snapshot.data;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.8),
                      AppColors.primary.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _statusTextBadge(event.status),
                    ),
                    if (registration != null)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: _registrationStatusBadge(registration.status),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6b7280),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(event.startDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: registration != null
                                ? null
                                : () async {
                                    final currentUser =
                                        Provider.of<AuthProvider>(
                                          context,
                                          listen: false,
                                        ).currentUser;
                                    if (currentUser == null) return;

                                    try {
                                      final registrationService =
                                          RegistrationService();
                                      await registrationService
                                          .registerForEvent(
                                            eventId: event.id,
                                            userId: currentUser.id,
                                            userEmail: currentUser.email,
                                            userName: currentUser.fullName,
                                            additionalInfo: {
                                              'note': '',
                                              'location': event.location,
                                            },
                                          );

                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Registration successful! Please wait for approval.',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Registration failed: ${e.toString()}',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: registration != null
                                  ? Colors.grey
                                  : AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              registration != null
                                  ? _getRegistrationButtonText(
                                      registration.status,
                                    )
                                  : 'Register Now',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EventDetailScreen(eventId: event.id),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: AppColors.primary),
                            ),
                            child: const Text(
                              'View Details',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusTextBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'approved':
      case 'published':
        bg = const Color(0x1A10B981);
        fg = const Color(0xFF10B981);
        break;
      case 'live':
        bg = const Color(0x1A3B82F6);
        fg = const Color(0xFF3B82F6);
        break;
      case 'pending':
        bg = const Color(0x1AF59E0B);
        fg = const Color(0xFFF59E0B);
        break;
      case 'completed':
        bg = const Color(0x1A8B5CF6);
        fg = const Color(0xFF8B5CF6);
        break;
      default:
        bg = const Color(0x1A6B7280);
        fg = const Color(0xFF6B7280);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _registrationStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String text;

    switch (status.toLowerCase()) {
      case 'approved':
        bgColor = const Color(0xFF10B981);
        textColor = Colors.white;
        icon = Icons.check_circle;
        text = 'Approved';
        break;
      case 'pending':
        bgColor = const Color(0xFFF59E0B);
        textColor = Colors.white;
        icon = Icons.pending;
        text = 'Pending';
        break;
      case 'rejected':
        bgColor = const Color(0xFFEF4444);
        textColor = Colors.white;
        icon = Icons.cancel;
        text = 'Rejected';
        break;
      default:
        bgColor = const Color(0xFF6B7280);
        textColor = Colors.white;
        icon = Icons.info;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getRegistrationButtonText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'pending':
        return 'Pending Approval';
      case 'rejected':
        return 'Registration Rejected';
      default:
        return 'Registered';
    }
  }
}

class _TicketsTab extends StatelessWidget {
  const _TicketsTab();

  @override
  Widget build(BuildContext context) {
    final registrationService = RegistrationService();
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Please login to view your tickets'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Your Tickets'),
          const SizedBox(height: 8),
          StreamBuilder<List<RegistrationModel>>(
            stream: registrationService.getUserRegistrationsStream(
              currentUser.id,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading tickets',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final registrations = snapshot.data ?? [];

              if (registrations.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.confirmation_num_outlined,
                          size: 48,
                          color: Color(0xFF9ca3af),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No Tickets Yet',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Register for events to get your tickets',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6b7280),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: registrations
                    .where((reg) => reg.isApproved || reg.isPending)
                    .map((registration) => _ticketCard(registration))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _ticketCard(RegistrationModel registration) {
    return FutureBuilder<EventModel?>(
      future: EventService().getEventById(registration.eventId),
      builder: (context, snapshot) {
        final event = snapshot.data;
        if (event == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Event Info Section
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatDateTime(event.startDate)} • ${event.location}',
                                style: const TextStyle(
                                  color: Color(0xFF6b7280),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: registration.isApproved
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            registration.isApproved ? 'Approved' : 'Pending',
                            style: TextStyle(
                              color: registration.isApproved
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // QR Code Section
              if (registration.isApproved) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Your QR Code',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 1,
                          ),
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
                              'Registration ID: ${registration.id.substring(0, 8)}...',
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF0),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pending_outlined,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Your registration is pending approval',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _sectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF1f2937),
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text(
            'View All',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _CertificatesTab extends StatelessWidget {
  const _CertificatesTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Your Certificates'),
          const SizedBox(height: 8),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_outlined,
                    size: 48,
                    color: Color(0xFF9ca3af),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Certificates Yet',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Complete events to earn certificates',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6b7280),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF1f2937),
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text(
            'View All',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final Function(BuildContext, AuthProvider) onLogout;

  const _ProfileTab({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;

        if (user == null) {
          return const Center(child: Text('Please login to view profile'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          user.fullName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6b7280),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getRoleText(user.role),
                          style: TextStyle(
                            color: _getRoleColor(user.role),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // User Information
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      const Divider(height: 1, thickness: 0.6),
                      _buildInfoTile(
                        icon: Icons.person_outline,
                        label: 'Full Name',
                        value: user.fullName,
                      ),
                      const Divider(height: 1, thickness: 0.6),
                      _buildInfoTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user.email,
                      ),
                      const Divider(height: 1, thickness: 0.6),
                      _buildInfoTile(
                        icon: Icons.phone_outlined,
                        label: 'Phone Number',
                        value: user.phoneNumber ?? 'Not updated',
                      ),
                      if (user.isStudent) ...[
                        const Divider(height: 1, thickness: 0.6),
                        _buildInfoTile(
                          icon: Icons.badge_outlined,
                          label: 'Student ID',
                          value: user.studentId ?? 'Not updated',
                        ),
                      ],
                      const Divider(height: 1, thickness: 0.6),
                      _buildInfoTile(
                        icon: Icons.verified_user_outlined,
                        label: 'Role',
                        value: _getRoleText(user.role),
                      ),
                      const Divider(height: 1, thickness: 0.6),
                      _buildInfoTile(
                        icon: Icons.event_note_outlined,
                        label: 'Created At',
                        value: _formatDate(user.createdAt),
                      ),
                      const Divider(height: 1, thickness: 0.6),
                      _buildInfoTile(
                        icon: Icons.update,
                        label: 'Last Updated',
                        value: _formatDate(user.updatedAt),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Phone Number Update
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.phone,
                        color: AppColors.primary,
                      ),
                      title: const Text('Update Phone Number'),
                      subtitle: Text(
                        user.phoneNumber ?? 'Not set',
                        style: const TextStyle(
                          color: Color(0xFF6b7280),
                          fontSize: 14,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        _showPhoneUpdateDialog(context, user);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: authProvider.isLoading
                      ? null
                      : () {
                          onLogout(context, authProvider);
                        },
                  icon: authProvider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.logout),
                  label: Text(
                    authProvider.isLoading ? 'Logging out...' : 'Logout',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6b7280),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.error;
      case 'organizer':
        return AppColors.warning;
      case 'student':
        return AppColors.success;
      default:
        return const Color(0xFF6b7280);
    }
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'organizer':
        return 'Event Organizer';
      case 'student':
        return 'Student';
      default:
        return 'User';
    }
  }

  void _showPhoneUpdateDialog(BuildContext context, dynamic user) {
    final TextEditingController phoneController = TextEditingController(
      text: user.phoneNumber ?? '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Phone Number'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your new phone number:',
                style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your phone number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPhone = phoneController.text.trim();
                if (newPhone.isNotEmpty) {
                  try {
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    final currentUser = authProvider.currentUser;
                    if (currentUser != null) {
                      final updatedUser = currentUser.copyWith(
                        phoneNumber: newPhone,
                      );
                      await authProvider.updateUser(updatedUser);

                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Phone number updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to update phone number: ${e.toString()}',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid phone number'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}
