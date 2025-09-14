import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/event_service.dart';
import '../../services/registration_service.dart';
import '../../models/event_model.dart';
import '../../models/registration_model.dart';
import '../../constants/app_colors.dart';
import '../coorganizer/coorganizer_invitations_screen.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../../constants/app_design.dart';

class HomeScreen extends StatefulWidget {
  final int? initialTab;
  const HomeScreen({super.key, this.initialTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late TabController _eventsTabController;
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab ?? 0;
    _eventsTabController = TabController(length: 3, vsync: this);
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != null &&
        widget.initialTab != oldWidget.initialTab) {
      setState(() {
        _currentIndex = widget.initialTab!;
      });
    }
  }

  @override
  void dispose() {
    _eventsTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Event Hub',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.25,
            ),
          ),
          backgroundColor: AppColors.organizerPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'Refresh Data',
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // Refresh all data
                context.read<EventProvider>().loadEvents();
                context.read<NotificationProvider>().refreshNotifications();
              },
            ),
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                final unreadCount = notificationProvider.unreadCount;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        context.go('/notifications');
                      },
                      tooltip: unreadCount > 0
                          ? 'Notifications (${unreadCount > 99 ? "99+" : unreadCount})'
                          : 'Notifications',
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            IconButton(
              tooltip: 'Profile',
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.go('/profile'),
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            // Home Tab (index 0)
            Consumer2<AuthProvider, EventProvider>(
              builder: (context, authProvider, eventProvider, _) {
                if (eventProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Container(
                  color: AppColors.surfaceVariant,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          constraints.maxWidth > 600 ? 24 : 16,
                          20,
                          constraints.maxWidth > 600 ? 24 : 16,
                          40 + MediaQuery.of(context).padding.bottom,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildWelcomeSection(authProvider),
                                const SizedBox(height: 24),
                                _buildOverviewSection(authProvider),
                                const SizedBox(height: 32),
                                _buildRecentActivitySection(authProvider),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            // My Events Tab (index 1)
            _buildMyEventsTab(),
          ],
        ),
        bottomNavigationBar: AppBottomNavigationBar(
          currentIndex: _currentIndex,
        ),
        floatingActionButton: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.currentUser?.role == 'organizer' ||
                authProvider.currentUser?.role == 'admin') {
              return Container(
                margin: const EdgeInsets.only(bottom: 80),
                child: FloatingActionButton(
                  onPressed: () {
                    context.go('/create-event');
                  },
                  backgroundColor: AppColors.organizerPrimary,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.organizerPrimary, AppColors.organizerSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_available,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Welcome back, ${authProvider.currentUser?.fullName ?? 'User'}!',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            authProvider.currentUser?.isOrganizer == true
                ? 'Manage your events and track performance'
                : 'Discover events and join the community',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Activity',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.25,
                color: Color(0xFF111827),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() => _currentIndex = 1),
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('View All'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.organizerPrimary,
                textStyle: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (authProvider.currentUser?.isOrganizer == true)
          _buildOrganizerRecentActivity(authProvider)
        else
          _buildStudentRecentActivity(),
      ],
    );
  }

  Widget _buildOrganizerRecentActivity(AuthProvider authProvider) {
    return StreamBuilder(
      stream: EventService().getOrganizerEventsStream(
        authProvider.currentUser!.id,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final events = snapshot.data as List<EventModel>;
        final activeEvents = events.where((event) {
          final now = DateTime.now();
          return event.startDate.isBefore(now) && event.endDate.isAfter(now);
        }).length;

        final pendingEvents = events
            .where(
              (event) => event.status == 'pending' || event.status == 'draft',
            )
            .length;

        final completedEvents = events
            .where((event) => event.endDate.isBefore(DateTime.now()))
            .length;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildActivityItem(
                  'Active Events',
                  '$activeEvents events currently running',
                  Icons.event_available,
                  AppColors.statusApproved,
                ),
                const Divider(height: 24),
                _buildActivityItem(
                  'Pending Events',
                  '$pendingEvents events waiting for approval',
                  Icons.pending,
                  AppColors.statusPending,
                ),
                const Divider(height: 24),
                _buildActivityItem(
                  'Completed Events',
                  '$completedEvents events finished',
                  Icons.check_circle,
                  AppColors.organizerSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentRecentActivity() {
    return StreamBuilder<List<EventModel>>(
      stream: EventService().getEventsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final events = snapshot.data!;
        final upcomingEvents = events.where((event) {
          return event.startDate.isAfter(DateTime.now());
        }).length;

        final availableEvents = events.length;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildActivityItem(
                  'Available Events',
                  '$availableEvents events you can join',
                  Icons.event,
                  AppColors.organizerPrimary,
                ),
                const Divider(height: 24),
                _buildActivityItem(
                  'Upcoming Events',
                  '$upcomingEvents events coming soon',
                  Icons.schedule,
                  AppColors.statusPending,
                ),
                const Divider(height: 24),
                _buildActivityItem(
                  'Popular Events',
                  'Most registered events this month',
                  Icons.trending_up,
                  AppColors.organizerPrimary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewSection(AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Overview',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.25,
            color: Color(0xFF111827),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (authProvider.currentUser?.isOrganizer == true)
          _buildOrganizerOverviewCards(authProvider)
        else
          _buildStudentOverviewCards(),
      ],
    );
  }

  Widget _buildOrganizerOverviewCards(AuthProvider authProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9,
          children: [
            // Single entry to create events
            _buildOverviewCard(
              title: 'Create Event',
              subtitle: 'New event',
              icon: Icons.add,
              color: AppColors.organizerPrimary,
              onTap: () => context.go('/create-event'),
            ),
            _buildOverviewCard(
              title: 'My Events',
              subtitle: 'View list',
              icon: Icons.event_available,
              color: AppColors.organizerSecondary,
              onTap: () => setState(() => _currentIndex = 1),
            ),
            _buildOverviewCard(
              title: 'Co-organizers',
              subtitle: 'Manage team',
              icon: Icons.group,
              color: AppColors.organizerAccent,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CoOrganizerInvitationsScreen(),
                  ),
                );
              },
            ),
            // Removed duplicate create event entry if existed elsewhere
          ],
        );
      },
    );
  }

  Widget _buildStudentOverviewCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9,
          children: [
            _buildOverviewCard(
              title: 'Browse Events',
              subtitle: 'Find events',
              icon: Icons.search,
              color: AppColors.organizerPrimary,
              onTap: () => setState(() => _currentIndex = 1),
            ),
            _buildOverviewCard(
              title: 'My Registrations',
              subtitle: 'View registered',
              icon: Icons.event_note,
              color: AppColors.organizerSecondary,
              onTap: () => setState(() => _currentIndex = 1),
            ),
            _buildOverviewCard(
              title: 'Notifications',
              subtitle: 'Stay updated',
              icon: Icons.notifications,
              color: AppColors.statusPending,
              onTap: () => context.go('/notifications'),
            ),
            _buildOverviewCard(
              title: 'Profile',
              subtitle: 'Manage account',
              icon: Icons.person,
              color: AppColors.organizerPrimary,
              onTap: () => context.go('/profile'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Color(0xFF9CA3AF),
          ),
        ],
      ),
    );
  }

  Widget _buildMyEventsTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Container(
          color: AppColors.surfaceVariant,
          child: Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Events',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            authProvider.currentUser?.isOrganizer == true
                                ? 'Manage your events and discover new ones'
                                : 'Discover and join events',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6b7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Search and status filter
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  decoration: AppDesign.textFieldDecoration(
                    hintText: 'Search by title, organizer, or location...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.organizerPrimary.withOpacity(0.7),
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              SizedBox(
                height: 32,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildStatusChip('All', 'all'),
                    _buildStatusChip('Published', 'published'),
                    _buildStatusChip('Pending', 'pending'),
                    _buildStatusChip('Rejected', 'rejected'),
                  ],
                ),
              ),

              // Events List
              Expanded(
                child: StreamBuilder(
                  stream: authProvider.currentUser?.isOrganizer == true
                      ? EventService().getMyEventsStream(
                          authProvider.currentUser!.id,
                        )
                      : RegistrationService().getUserRegistrationsStream(
                          authProvider.currentUser!.id,
                        ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    }

                    if (authProvider.currentUser?.isOrganizer == true) {
                      final myEvents =
                          (snapshot.data as List<EventModel>?) ?? [];
                      final filtered = _filterEvents(myEvents);
                      if (filtered.isEmpty) {
                        return _buildEmptyState();
                      }
                      return _buildEventsList(filtered);
                    } else {
                      final registrations =
                          (snapshot.data as List?)?.cast<RegistrationModel>() ??
                          [];
                      if (registrations.isEmpty) {
                        return _buildEmptyState();
                      }
                      return _buildRegistrationsList(registrations);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<EventModel> _filterEvents(List<EventModel> events) {
    final q = _searchQuery.trim().toLowerCase();
    return events.where((e) {
      final matchesQuery =
          q.isEmpty ||
          e.title.toLowerCase().contains(q) ||
          e.organizerName.toLowerCase().contains(q) ||
          e.location.toLowerCase().contains(q);
      final matchesStatus = _statusFilter == 'all' || e.status == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList()..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  // Helper: Tính toán lại số lượng participants cho event dựa trên registrations
  Future<int> _getEventParticipantCount(String eventId) async {
    try {
      final registrations = await RegistrationService().getEventRegistrations(
        eventId,
      );
      return registrations.where((r) => r.isApproved).length;
    } catch (e) {
      // Nếu có lỗi, trả về currentParticipants từ event
      return 0;
    }
  }

  // Helper: Tính toán lại số lượng support staff cho event dựa trên support registrations
  Future<int> _getEventSupportStaffCount(String eventId) async {
    try {
      final supportRegistrations = await RegistrationService()
          .getEventSupportRegistrations(eventId);

      // Debug: in ra thông tin để kiểm tra
      print(
        'Event $eventId - Support registrations count: ${supportRegistrations.length}',
      );
      for (var reg in supportRegistrations) {
        print(
          '  Support reg ID: ${reg.id}, status: ${reg.status}, isApproved: ${reg.isApproved}',
        );
      }

      // Thử đếm với nhiều điều kiện khác nhau để debug
      final approvedCount = supportRegistrations
          .where((r) => r.isApproved)
          .length;
      final allCount = supportRegistrations.length;
      final pendingCount = supportRegistrations
          .where((r) => r.isPending)
          .length;
      final rejectedCount = supportRegistrations
          .where((r) => r.isRejected)
          .length;

      print('Event $eventId - Support staff counts:');
      print(
        '  Total: $allCount, Approved: $approvedCount, Pending: $pendingCount, Rejected: $rejectedCount',
      );

      // Nếu không có approved nhưng có pending, có thể cần approve registrations này
      // Hoặc có thể vấn đề là status field trong Firestore có giá trị khác
      if (allCount > 0 && approvedCount == 0) {
        print(
          'Event $eventId - WARNING: No approved support staff but have ${allCount} registrations',
        );
        print(
          'Event $eventId - First registration status: ${supportRegistrations.first.status}',
        );
      }

      // TEMPORARY: Trả về allCount để test xem có dữ liệu không
      // TODO: Đổi lại thành approvedCount sau khi debug xong
      return allCount;
    } catch (e) {
      // Nếu có lỗi, trả về currentSupportStaff từ event
      print('Error getting support staff count for event $eventId: $e');
      return 0;
    }
  }

  // Wrapper widget để tính toán participant và support staff count trước khi hiển thị event card
  Widget _buildEventCardWithParticipantCount(EventModel event) {
    return FutureBuilder<List<int>>(
      future: Future.wait([
        _getEventParticipantCount(event.id),
        _getEventSupportStaffCount(event.id),
      ]),
      builder: (context, snapshot) {
        final participantCount =
            snapshot.data?.elementAtOrNull(0) ?? event.currentParticipants;
        final supportStaffCount =
            snapshot.data?.elementAtOrNull(1) ?? event.currentSupportStaff;

        // Tạo event mới với participant và support staff count đã được tính toán lại
        final updatedEvent = event.copyWith(
          currentParticipants: participantCount,
          currentSupportStaff: supportStaffCount,
        );
        return _buildModernEventCard(updatedEvent);
      },
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final bool selected = _statusFilter == value;
    final Color color = selected
        ? AppColors.organizerPrimary
        : const Color(0xFF6B7280);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _statusFilter = value),
        selectedColor: color.withOpacity(0.12),
        backgroundColor: const Color(0xFFF3F4F6),
        labelStyle: TextStyle(
          color: selected ? color : const Color(0xFF374151),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withOpacity(selected ? 0.4 : 0.2)),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 64, color: Color(0xFFef4444)),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Refresh the page
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.organizerPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(
            Icons.event_note_outlined,
            size: 64,
            color: Color(0xFF9ca3af),
          ),
          const SizedBox(height: 16),
          const Text(
            'No events yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first event to get started',
            style: TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/create-event'),
            icon: const Icon(Icons.add),
            label: const Text('Create Event'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.organizerPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<EventModel> events) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildEventCardWithParticipantCount(event),
        );
      },
    );
  }

  Widget _buildRegistrationsList(List<RegistrationModel> registrations) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: registrations.length,
      itemBuilder: (context, index) {
        final reg = registrations[index];
        return FutureBuilder<EventModel?>(
          future: EventService().getEventById(reg.eventId),
          builder: (context, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            final event = snap.data!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildEventCardWithParticipantCount(event),
            );
          },
        );
      },
    );
  }

  Widget _buildModernEventCard(EventModel event) {
    return Container(
      decoration: AppDesign.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/event-detail/${event.id}'),
          borderRadius: BorderRadius.circular(AppDesign.radius16),
          child: Padding(
            padding: const EdgeInsets.all(AppDesign.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: AppDesign.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppDesign.spacing12),
                    _buildStatusBadge(
                      _getStatusText(event.status),
                      _getStatusColor(event.status),
                    ),
                  ],
                ),
                const SizedBox(height: AppDesign.spacing12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getCategoryColor(
                                  event.category,
                                ).withOpacity(0.2),
                                _getCategoryColor(
                                  event.category,
                                ).withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppDesign.radius16,
                            ),
                            border: Border.all(
                              color: _getCategoryColor(
                                event.category,
                              ).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            _getCategoryIcon(event.category),
                            color: _getCategoryColor(event.category),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppDesign.spacing16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    size: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                  const SizedBox(width: AppDesign.spacing4),
                                  Expanded(
                                    child: Text(
                                      'Organizer: ${event.organizerName}',
                                      style: AppDesign.bodySmall.copyWith(
                                        color: const Color(0xFF6B7280),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppDesign.spacing8),
                              Container(
                                padding: const EdgeInsets.all(
                                  AppDesign.spacing8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant.withOpacity(
                                    0.5,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppDesign.radius8,
                                  ),
                                ),
                                child: Text(
                                  event.description,
                                  style: AppDesign.bodySmall.copyWith(
                                    color: const Color(0xFF374151),
                                    height: 1.4,
                                  ),
                                  maxLines: isWide ? 2 : 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: AppDesign.spacing12),
                              if (isWide)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoRow(
                                        Icons.location_on,
                                        event.location,
                                        const Color(0xFF059669),
                                      ),
                                    ),
                                    const SizedBox(width: AppDesign.spacing16),
                                    Expanded(
                                      child: _buildInfoRow(
                                        Icons.calendar_today,
                                        _formatDate(event.startDate),
                                        const Color(0xFF7C3AED),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    _buildInfoRow(
                                      Icons.location_on,
                                      event.location,
                                      const Color(0xFF059669),
                                    ),
                                    const SizedBox(height: AppDesign.spacing8),
                                    _buildInfoRow(
                                      Icons.calendar_today,
                                      _formatDate(event.startDate),
                                      const Color(0xFF7C3AED),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: AppDesign.spacing8),
                              _buildInfoRow(
                                Icons.people,
                                '${event.currentParticipants}/${event.maxParticipants} participants',
                                AppColors.organizerPrimary,
                              ),
                              const SizedBox(height: AppDesign.spacing4),
                              _buildInfoRow(
                                Icons.support_agent,
                                '${event.currentSupportStaff}/${event.maxSupportStaff} support staff',
                                const Color(0xFF7C3AED),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppDesign.spacing8),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Color(0xFF9CA3AF),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppDesign.bodySmall.copyWith(
              color: const Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spacing10,
        vertical: AppDesign.spacing6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDesign.radius12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppDesign.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // removed old small detail row (replaced by _buildInfoRow)

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'technology':
        return const Color(0xFF3b82f6);
      case 'academic':
        return const Color(0xFF8b5cf6);
      case 'culture':
        return const Color(0xFFf59e0b);
      case 'sports':
        return const Color(0xFF10b981);
      case 'exhibition':
        return const Color(0xFFef4444);
      default:
        return const Color(0xFF6b7280);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'technology':
        return Icons.school;
      case 'sports':
        return Icons.sports_soccer;
      case 'culture':
        return Icons.palette;
      default:
        return Icons.event;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return const Color(0xFF6b7280);
      case 'pending':
        return const Color(0xFFf59e0b);
      case 'approved':
      case 'published':
        return AppColors.organizerPrimary;
      case 'live':
        return const Color(0xFF3b82f6);
      case 'done':
      case 'completed':
        return const Color(0xFF8b5cf6);
      case 'cancelled':
        return const Color(0xFFef4444);
      default:
        return const Color(0xFF6b7280);
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'pending':
        return 'Pending';
      case 'approved':
      case 'published':
        return 'Published';
      case 'live':
        return 'Live';
      case 'done':
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // removed unused _formatTime
}
