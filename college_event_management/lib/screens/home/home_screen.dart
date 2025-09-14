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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWelcomeSection(authProvider),
                            const SizedBox(height: 24),
                            _buildOverviewSection(authProvider),
                            const SizedBox(height: 32),
                            _buildRecentActivitySection(authProvider),
                          ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
            _buildOverviewCard(
              title: 'Analytics',
              subtitle: 'View insights',
              icon: Icons.analytics,
              color: AppColors.organizerSecondary,
              onTap: () {},
            ),
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
                    if (authProvider.currentUser?.isOrganizer == true)
                      ElevatedButton.icon(
                        onPressed: () => context.go('/create-event'),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Create'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.organizerPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
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
                      if (myEvents.isEmpty) {
                        return _buildEmptyState();
                      }
                      return _buildEventsList(myEvents);
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
          child: _buildModernEventCard(event),
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
              child: _buildModernEventCard(event),
            );
          },
        );
      },
    );
  }

  Widget _buildModernEventCard(EventModel event) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/event-detail/${event.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with category and status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          event.category,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event.category,
                        style: TextStyle(
                          color: _getCategoryColor(event.category),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(event.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(event.status),
                        style: TextStyle(
                          color: _getStatusColor(event.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Event title and description
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1f2937),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                const SizedBox(height: 16),

                // Event details
                Row(
                  children: [
                    _buildEventDetail(
                      Icons.calendar_today,
                      _formatDate(event.startDate),
                    ),
                    const SizedBox(width: 16),
                    _buildEventDetail(
                      Icons.access_time,
                      _formatTime(event.startDate),
                    ),
                    const SizedBox(width: 16),
                    _buildEventDetail(Icons.location_on, event.location),
                  ],
                ),
                const SizedBox(height: 12),

                // Participants and price
                Row(
                  children: [
                    _buildEventDetail(
                      Icons.people,
                      '${event.currentParticipants}/${event.maxParticipants}',
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: event.isFree
                            ? AppColors.organizerPrimary.withOpacity(0.1)
                            : const Color(0xFFf59e0b).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event.isFree
                            ? 'Free'
                            : '\$${event.price?.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: event.isFree
                              ? AppColors.organizerPrimary
                              : const Color(0xFFf59e0b),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9ca3af)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6b7280)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

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

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
