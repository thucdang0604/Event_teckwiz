import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_design.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboardStats();
      // Also preload data used for overview badges
      context.read<AdminProvider>().loadPendingEvents();
      context.read<AdminProvider>().loadLocations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Admin Dashboard',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.25,
            ),
          ),
          backgroundColor: AppColors.adminPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'Refresh Data',
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<AdminProvider>().loadDashboardStats();
                context.read<AdminProvider>().loadPendingEvents();
                context.read<AdminProvider>().loadLocations();
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
                        context.go('/admin/notifications');
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
              tooltip: 'Logout',
              icon: const Icon(Icons.logout),
              onPressed: () => _showLogoutConfirmation(context),
            ),
          ],
        ),
        body: Consumer<AdminProvider>(
          builder: (context, adminProvider, child) {
            if (adminProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final stats = adminProvider.dashboardStats;

            return Container(
              color: AppColors.surfaceVariant,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      constraints.maxWidth > 600
                          ? AppDesign.spacing24
                          : AppDesign.spacing16,
                      AppDesign.spacing20,
                      constraints.maxWidth > 600
                          ? AppDesign.spacing24
                          : AppDesign.spacing16,
                      AppDesign.spacing40 +
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderSection(),
                        const SizedBox(height: AppDesign.spacing24),
                        _buildOverviewAndActions(stats),
                        const SizedBox(height: AppDesign.spacing32),
                        _buildRecentActivity(),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppColors.cardBorder, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _currentIndex,
                selectedItemColor: AppColors.adminPrimary,
                unselectedItemColor: const Color(0xFF9CA3AF),
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedLabelStyle: AppDesign.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: AppDesign.labelSmall,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  switch (index) {
                    case 0:
                      context.go('/admin-dashboard');
                      break;
                    case 1:
                      context.go('/admin/approvals');
                      break;
                    case 2:
                      context.go('/admin/users');
                      break;
                    case 3:
                      context.go('/admin/locations');
                      break;
                    case 4:
                      context.go('/admin/notifications');
                      break;
                  }
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_outlined),
                    activeIcon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.event_available_outlined),
                    activeIcon: Icon(Icons.event_available),
                    label: 'Approval',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people_outline),
                    activeIcon: Icon(Icons.people),
                    label: 'Users',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.location_on_outlined),
                    activeIcon: Icon(Icons.location_on),
                    label: 'Locations',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.notifications_outlined),
                    activeIcon: Icon(Icons.notifications),
                    label: 'Notifications',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing16),
      decoration: AppDesign.elevatedCardDecoration.copyWith(
        gradient: LinearGradient(
          colors: [AppColors.adminPrimary, AppColors.adminSecondary],
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
              borderRadius: BorderRadius.circular(AppDesign.radius12),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: AppDesign.spacing12),
          Text(
            'Welcome back, Admin!',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppDesign.heading2.copyWith(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: AppDesign.spacing4),
          Text(
            'Manage events, users and locations efficiently',
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

  Widget _buildOverviewAndActions(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppDesign.heading2.copyWith(color: const Color(0xFF111827)),
        ),
        const SizedBox(height: AppDesign.spacing16),
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
              crossAxisSpacing: AppDesign.spacing16,
              mainAxisSpacing: AppDesign.spacing16,
              childAspectRatio: screenWidth > 600 ? 1.2 : 1.1,
              children: [
                _buildActionCard(
                  'User Management',
                  Icons.people_outline,
                  AppColors.adminPrimary,
                  () => context.go('/admin/users'),
                  subtitle: '${stats['totalUsers'] ?? 0} users',
                ),
                _buildActionCard(
                  'Event Approval',
                  Icons.event_available,
                  AppColors.statusPending,
                  () => context.go('/admin/approvals'),
                  subtitle:
                      '${context.read<AdminProvider>().pendingEvents.length} pending',
                ),
                _buildActionCard(
                  'Locations',
                  Icons.location_on,
                  AppColors.statusApproved,
                  () => context.go('/admin/locations'),
                  subtitle:
                      '${context.read<AdminProvider>().locations.length} locations',
                ),
                _buildActionCard(
                  'Statistics',
                  Icons.analytics,
                  AppColors.adminSecondary,
                  () => context.go('/admin/statistics'),
                  subtitle: '${stats['publishedEvents'] ?? 0} approved',
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // old _buildStatsCards removed after merge

  // Keep stat card for potential reuse later
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, [
    VoidCallback? onTap,
  ]) {
    final card = Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      );
    }
    return card;
  }

  // old _buildQuickActions removed after merge

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    String? subtitle,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDesign.radius16),
      child: AnimatedContainer(
        duration: AppDesign.fastAnimation,
        decoration: AppDesign.cardDecoration,
        padding: const EdgeInsets.all(AppDesign.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppDesign.radius12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: AppDesign.spacing12),
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
                    const SizedBox(height: AppDesign.spacing4),
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
            const SizedBox(height: AppDesign.spacing8),
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

  Widget _buildRecentActivity() {
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
              onPressed: () => context.go('/admin/approvals'),
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('View All'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.adminPrimary,
                textStyle: AppDesign.labelMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDesign.spacing16),
        Container(
          decoration: AppDesign.cardDecoration,
          child: Padding(
            padding: const EdgeInsets.all(AppDesign.spacing16),
            child: Column(
              children: [
                _buildActivityItem(
                  'New Events Pending',
                  '2 events',
                  Icons.event_available,
                  AppColors.statusPending,
                ),
                const Divider(height: AppDesign.spacing24),
                _buildActivityItem(
                  'New User Registrations',
                  '5 users',
                  Icons.person_add,
                  AppColors.adminPrimary,
                ),
                const Divider(height: AppDesign.spacing24),
                _buildActivityItem(
                  'Completed Events',
                  '3 events',
                  Icons.check_circle,
                  AppColors.statusApproved,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDesign.spacing8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDesign.radius12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppDesign.spacing12),
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
                const SizedBox(height: AppDesign.spacing4),
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

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text(
            'Are you sure you want to log out from your admin account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await context.read<AuthProvider>().signOut();
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
                        borderRadius: BorderRadius.circular(AppDesign.radius12),
                      ),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
