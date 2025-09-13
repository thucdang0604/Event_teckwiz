import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_design.dart';
import '../../providers/auth_provider.dart';
import '../../services/student_service.dart';
import '../../services/data_import_service.dart';
import 'debug_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  final StudentService _studentService = StudentService();
  final DataImportService _importService = DataImportService();
  bool _isSyncing = false;
  bool _isImporting = false;
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

  Future<void> _syncStudentsToPublic() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      await _studentService.syncAllStudentsToPublic();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đồng bộ dữ liệu sinh viên thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đồng bộ: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _importSampleData() async {
    setState(() {
      _isImporting = true;
    });

    try {
      await _importService.importSampleStudents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import dữ liệu mẫu thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi import: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.25,
            ),
          ),
          backgroundColor: AppColors.adminPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
            tooltip: 'Back to Home',
          ),
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
            IconButton(
              tooltip: 'Debug Student Data',
              icon: const Icon(Icons.bug_report),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DebugScreen()),
                );
              },
            ),
            IconButton(
              tooltip: 'Import Sample Data',
              icon: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.file_download),
              onPressed: _isImporting ? null : _importSampleData,
            ),
            IconButton(
              tooltip: 'Sync Students Data',
              icon: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.sync),
              onPressed: _isSyncing ? null : _syncStudentsToPublic,
            ),
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout),
              onPressed: () async {
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
                      AppDesign.spacing40,
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
          child: BottomNavigationBar(
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
                  context.go('/admin/statistics');
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
                icon: Icon(Icons.analytics_outlined),
                activeIcon: Icon(Icons.analytics),
                label: 'Statistics',
              ),
            ],
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppDesign.radius12),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppDesign.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, Admin!',
                  style: AppDesign.heading2.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: AppDesign.spacing4),
                Text(
                  'Manage events, users and locations efficiently',
                  style: AppDesign.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
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
          style: AppDesign.heading2.copyWith(color: const Color(0xFF111827)),
        ),
        const SizedBox(height: AppDesign.spacing16),
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final crossAxisCount = screenWidth > 600 ? 3 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: AppDesign.spacing16,
              mainAxisSpacing: AppDesign.spacing16,
              childAspectRatio: screenWidth > 600 ? 1.5 : 1.2,
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppDesign.labelLarge.copyWith(
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w600,
                    ),
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
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppDesign.spacing8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: const Color(0xFF9CA3AF),
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
                  style: AppDesign.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: AppDesign.spacing4),
                Text(
                  subtitle,
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
