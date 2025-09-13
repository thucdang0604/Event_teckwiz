import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../services/event_service.dart';
import '../../services/registration_service.dart';
import '../../models/registration_model.dart';
import '../../models/event_model.dart';
import '../coorganizer/coorganizer_invitations_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late TabController _eventsTabController;

  @override
  void initState() {
    super.initState();
    _eventsTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _eventsTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf9fafb),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [_buildEventsTab(), _buildMyEventsTab()],
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.currentUser?.role == 'organizer' ||
              authProvider.currentUser?.role == 'admin') {
            return Container(
              margin: const EdgeInsets.only(bottom: 100),
              child: FloatingActionButton(
                onPressed: () {
                  context.go('/create-event');
                },
                backgroundColor: const Color(0xFF10b981),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final user = authProvider.currentUser;
                final initials = user?.fullName != null
                    ? user!.fullName
                          .split(' ')
                          .map((e) => e[0])
                          .take(2)
                          .join()
                          .toUpperCase()
                    : 'U';

                return Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF10b981), Color(0xFF34d399)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${user?.fullName ?? 'User'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF1f2937),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _getUserRoleText(user?.role),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF10b981),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  final isAdmin = authProvider.currentUser?.role == 'admin';
                  final isOrganizer =
                      authProvider.currentUser?.role == 'organizer';

                  if (isAdmin) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: _buildHeaderButton(
                        icon: Icons.admin_panel_settings,
                        onTap: () => context.go('/admin-dashboard'),
                      ),
                    );
                  } else if (isOrganizer) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: _buildHeaderButton(
                        icon: Icons.event_note,
                        onTap: () => context.go('/organizer-dashboard'),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
              _buildHeaderButton(
                icon: Icons.qr_code_scanner,
                onTap: () {
                  context.go('/qr-scanner');
                },
              ),
              const SizedBox(width: 4),
              _buildHeaderButton(
                icon: Icons.notifications,
                onTap: () {
                  // TODO: Navigate to notifications
                },
                badge: '5',
              ),
              const SizedBox(width: 4),
              _buildHeaderButton(
                icon: Icons.more_vert,
                onTap: () {
                  context.go('/profile');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFf3f4f6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            Center(child: Icon(icon, color: const Color(0xFF6b7280), size: 18)),
            if (badge != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFef4444),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getUserRoleText(String? role) {
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

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              icon: Icons.home,
              label: 'Home',
              isActive: _currentIndex == 0,
              onTap: () => setState(() => _currentIndex = 0),
            ),
            _buildNavItem(
              icon: Icons.event_note,
              label: 'Events',
              isActive: _currentIndex == 1,
              onTap: () => setState(() => _currentIndex = 1),
            ),
            _buildNavItem(
              icon: Icons.mail_outline,
              label: 'Invitations',
              isActive: false,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CoOrganizerInvitationsScreen(),
                  ),
                );
              },
            ),
            _buildNavItem(
              icon: Icons.analytics,
              label: 'Reports',
              isActive: false,
              onTap: () {
                // TODO: Navigate to analytics
              },
            ),
            _buildNavItem(
              icon: Icons.person,
              label: 'Profile',
              isActive: false,
              onTap: () => context.go('/profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF10b981).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isActive
                      ? const Color(0xFF10b981)
                      : const Color(0xFF9ca3af),
                  size: 18,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? const Color(0xFF10b981)
                        : const Color(0xFF9ca3af),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 1,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFef4444),
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    return Consumer2<AuthProvider, EventProvider>(
      builder: (context, authProvider, eventProvider, _) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(authProvider),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildStatsGrid(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10b981), Color(0xFF34d399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${authProvider.currentUser?.fullName ?? 'User'}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your events and track performance',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          StreamBuilder(
            stream: authProvider.currentUser?.isOrganizer == true
                ? EventService().getOrganizerEventsStream(
                    authProvider.currentUser!.id,
                  )
                : null,
            builder: (context, snapshot) {
              if (snapshot.hasData &&
                  authProvider.currentUser?.isOrganizer == true) {
                final events = snapshot.data as List<EventModel>;
                int totalParticipants = 0;
                for (var event in events) {
                  totalParticipants += event.currentParticipants;
                }

                return Row(
                  children: [
                    _buildQuickStat('${events.length}', 'My Events'),
                    const SizedBox(width: 24),
                    _buildQuickStat('$totalParticipants', 'Participants'),
                    const SizedBox(width: 24),
                    _buildQuickStat('4.8', 'Rating'),
                  ],
                );
              } else {
                return Row(
                  children: [
                    _buildQuickStat('0', 'My Events'),
                    const SizedBox(width: 24),
                    _buildQuickStat('0', 'Participants'),
                    const SizedBox(width: 24),
                    _buildQuickStat('4.8', 'Rating'),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.currentUser?.isOrganizer == true) {
          return StreamBuilder<List<EventModel>>(
            stream: EventService().getOrganizerEventsStream(
              authProvider.currentUser!.id,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final events = snapshot.data!;
                int totalEvents = events.length;
                int totalParticipants = 0;
                int pendingEvents = 0;
                int completedEvents = 0;

                for (var event in events) {
                  totalParticipants += event.currentParticipants;
                  if (event.status == 'pending') pendingEvents++;
                  if (event.status == 'completed') completedEvents++;
                }

                double attendanceRate = totalEvents > 0
                    ? (completedEvents / totalEvents * 100)
                    : 0.0;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: [
                    _buildStatCard(
                      icon: Icons.calendar_today,
                      value: '$totalEvents',
                      title: 'Total Events',
                      color: const Color(0xFF6366f1),
                    ),
                    _buildStatCard(
                      icon: Icons.people,
                      value: '$totalParticipants',
                      title: 'Total Participants',
                      color: const Color(0xFF10b981),
                    ),
                    _buildStatCard(
                      icon: Icons.schedule,
                      value: '$pendingEvents',
                      title: 'Pending Approval',
                      color: const Color(0xFFf59e0b),
                    ),
                    _buildStatCard(
                      icon: Icons.trending_up,
                      value: '${attendanceRate.toStringAsFixed(0)}%',
                      title: 'Completion Rate',
                      color: const Color(0xFF3b82f6),
                    ),
                  ],
                );
              } else if (snapshot.hasError) {
                return _buildErrorStats();
              } else {
                return _buildLoadingStats();
              }
            },
          );
        } else {
          return StreamBuilder<List<EventModel>>(
            stream: EventService().getEventsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final events = snapshot.data!;
                int totalEvents = events.length;
                int totalParticipants = 0;
                int upcomingEvents = 0;

                for (var event in events) {
                  totalParticipants += event.currentParticipants;
                  if (event.startDate.isAfter(DateTime.now())) upcomingEvents++;
                }

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: [
                    _buildStatCard(
                      icon: Icons.calendar_today,
                      value: '$totalEvents',
                      title: 'Available Events',
                      color: const Color(0xFF6366f1),
                    ),
                    _buildStatCard(
                      icon: Icons.people,
                      value: '$totalParticipants',
                      title: 'Total Participants',
                      color: const Color(0xFF10b981),
                    ),
                    _buildStatCard(
                      icon: Icons.schedule,
                      value: '$upcomingEvents',
                      title: 'Upcoming Events',
                      color: const Color(0xFFf59e0b),
                    ),
                    _buildStatCard(
                      icon: Icons.trending_up,
                      value: '4.8',
                      title: 'App Rating',
                      color: const Color(0xFF3b82f6),
                    ),
                  ],
                );
              } else if (snapshot.hasError) {
                return _buildErrorStats();
              } else {
                return _buildLoadingStats();
              }
            },
          );
        }
      },
    );
  }

  Widget _buildLoadingStats() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: List.generate(
        4,
        (index) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Widget _buildErrorStats() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard(
          icon: Icons.error_outline,
          value: '--',
          title: 'Error Loading',
          color: const Color(0xFFef4444),
        ),
        _buildStatCard(
          icon: Icons.error_outline,
          value: '--',
          title: 'Error Loading',
          color: const Color(0xFFef4444),
        ),
        _buildStatCard(
          icon: Icons.error_outline,
          value: '--',
          title: 'Error Loading',
          color: const Color(0xFFef4444),
        ),
        _buildStatCard(
          icon: Icons.error_outline,
          value: '--',
          title: 'Error Loading',
          color: const Color(0xFFef4444),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String title,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1f2937),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6b7280),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMyEventsTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Column(
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
                          'Events',
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
                        backgroundColor: const Color(0xFF10b981),
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

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFf3f4f6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _eventsTabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF10b981),
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF6b7280),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'My Events'),
                  Tab(text: 'All Events'),
                  Tab(text: 'Co-Organizer'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _eventsTabController,
                children: [
                  _buildMyEventsContent(authProvider),
                  _buildAllEventsContent(authProvider),
                  _buildCoOrganizerEventsContent(authProvider),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMyEventsContent(AuthProvider authProvider) {
    return StreamBuilder(
      stream: authProvider.currentUser?.isOrganizer == true
          ? EventService().getMyEventsStream(authProvider.currentUser!.id)
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
          final myEvents = (snapshot.data as List<EventModel>?) ?? [];
          if (myEvents.isEmpty) {
            return _buildEmptyState();
          }
          return _buildEventsList(myEvents);
        } else {
          final registrations =
              (snapshot.data as List?)?.cast<RegistrationModel>() ?? [];
          if (registrations.isEmpty) {
            return _buildEmptyState();
          }
          return _buildRegistrationsList(registrations);
        }
      },
    );
  }

  Widget _buildCoOrganizerEventsContent(AuthProvider authProvider) {
    return StreamBuilder<List<EventModel>>(
      stream: EventService().getCoOrganizerEventsStream(
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

        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return _buildEmptyState();
        }
        return _buildEventsList(events);
      },
    );
  }

  Widget _buildAllEventsContent(AuthProvider authProvider) {
    return StreamBuilder<List<EventModel>>(
      stream: authProvider.currentUser?.isOrganizer == true
          ? EventService().getAllEventsStream()
          : EventService().getEventsStream(),
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

        final allEvents = snapshot.data ?? [];
        if (allEvents.isEmpty) {
          return _buildEmptyState();
        }
        return _buildEventsList(allEvents);
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
              backgroundColor: const Color(0xFF10b981),
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
              backgroundColor: const Color(0xFF10b981),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildModernEventCard(event),
          );
        },
      ),
    );
  }

  Widget _buildRegistrationsList(List<RegistrationModel> registrations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
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
      ),
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
                            ? const Color(0xFF10b981).withOpacity(0.1)
                            : const Color(0xFFf59e0b).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event.isFree
                            ? 'Free'
                            : '\$${event.price?.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: event.isFree
                              ? const Color(0xFF10b981)
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
        return const Color(0xFF10b981);
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
