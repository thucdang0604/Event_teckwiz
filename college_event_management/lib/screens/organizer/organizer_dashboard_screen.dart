import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/notification_provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_design.dart';
import '../../widgets/app_bottom_navigation_bar.dart';

class OrganizerDashboardScreen extends StatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  State<OrganizerDashboardScreen> createState() =>
      _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends State<OrganizerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().loadEvents();
      context.read<NotificationProvider>().refreshNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Organizer Dashboard',
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
                        print('Notification button tapped!');
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
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    try {
                      await authProvider.signOut();
                      if (!mounted) return;
                      context.go('/login');
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Logout failed: $e'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
        body: Consumer<EventProvider>(
          builder: (context, eventProvider, child) {
            if (eventProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = context.watch<AuthProvider>().currentUser;
            final myEvents = eventProvider.events
                .where((event) => event.organizerId == user?.id)
                .toList();

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
                            _buildHeaderSection(user?.fullName ?? 'Organizer'),
                            const SizedBox(height: 24),
                            _buildOverviewAndActions(myEvents),
                            const SizedBox(height: 32),
                            _buildRecentActivity(),
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
        bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 0),
      ),
    );
  }

  Widget _buildHeaderSection(String userName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDesign.elevatedCardDecoration.copyWith(
        gradient: LinearGradient(
          colors: [AppColors.organizerPrimary, AppColors.organizerSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
            'Welcome back, $userName!',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppDesign.heading2.copyWith(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your events and co-organizers efficiently',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppDesign.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewAndActions(List myEvents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Overview',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppDesign.heading2.copyWith(color: const Color(0xFF111827)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final crossAxisCount = screenWidth > 600
                ? 3
                : screenWidth > 360
                ? 2
                : 1;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: screenWidth > 600 ? 1.2 : 1.1,
              children: [
                _buildActionCard(
                  'Create Event',
                  Icons.add,
                  AppColors.organizerPrimary,
                  () => context.go('/create-event'),
                  subtitle: 'New event',
                ),
                _buildActionCard(
                  'My Events',
                  Icons.event_available,
                  AppColors.organizerSecondary,
                  () => context.go('/organizer/events'),
                  subtitle: '${myEvents.length} events',
                ),
                _buildActionCard(
                  'Co-organizers',
                  Icons.group,
                  AppColors.organizerAccent,
                  () => context.go('/organizer/coorganizers'),
                  subtitle: 'Manage team',
                ),
                _buildActionCard(
                  'Invitations',
                  Icons.mark_email_unread,
                  AppColors.accent,
                  () => context.go('/coorganizer-invitations'),
                  subtitle: 'Co-organizer invites',
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    final eventProvider = context.watch<EventProvider>();
    final user = context.watch<AuthProvider>().currentUser;
    final myEvents = eventProvider.events
        .where((event) => event.organizerId == user?.id)
        .toList();

    final activeEvents = myEvents.where((event) {
      final now = DateTime.now();
      return event.startDate.isBefore(now) && event.endDate.isAfter(now);
    }).length;

    final pendingEvents = myEvents
        .where((event) => event.status == 'pending' || event.status == 'draft')
        .length;

    final completedEvents = myEvents
        .where((event) => event.endDate.isBefore(DateTime.now()))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Activity',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppDesign.heading2.copyWith(
                color: const Color(0xFF111827),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => context.go('/organizer/events'),
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('View All'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.organizerPrimary,
                textStyle: AppDesign.labelMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: AppDesign.cardDecoration,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildActivityItem(
                  'Active Events',
                  '$activeEvents events currently running',
                  Icons.event_available,
                  AppColors.organizerPrimary,
                ),
                const Divider(height: 24),
                _buildActivityItem(
                  'Pending Events',
                  '$pendingEvents events waiting for approval',
                  Icons.pending,
                  AppColors.warning,
                ),
                const Divider(height: 24),
                _buildActivityItem(
                  'Completed Events',
                  '$completedEvents events finished',
                  Icons.check_circle,
                  AppColors.success,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    String? subtitle,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: AppDesign.fastAnimation,
        decoration: AppDesign.cardDecoration,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppDesign.labelLarge.copyWith(
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppDesign.labelSmall.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: const Color(0xFF9CA3AF),
              ),
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
                  style: AppDesign.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppDesign.bodySmall.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: const Color(0xFF9CA3AF),
          ),
        ],
      ),
    );
  }
}
