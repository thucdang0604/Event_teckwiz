import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/admin_statistics_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_design.dart';
import '../../widgets/admin_bottom_navigation_bar.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen>
    with TickerProviderStateMixin {
  final int _currentIndex = 2; // Statistics tab
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: AppDesign.normalAnimation,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideController = AnimationController(
      duration: AppDesign.normalAnimation,
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start animations first
      _fadeController.forward();
      _slideController.forward();

      // Then load statistics
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          context.read<AdminProvider>().loadStatistics();
        }
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(130),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.adminPrimary, AppColors.adminSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.adminPrimary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistics Dashboard',
                    style: AppDesign.heading2.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'View system analytics and insights',
                    style: AppDesign.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              toolbarHeight: 70,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDesign.radius12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  onPressed: () => context.go('/admin-dashboard'),
                  tooltip: 'Back to Dashboard',
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppDesign.radius12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: () {
                      context.read<AdminProvider>().loadStatistics();
                      _fadeController.reset();
                      _slideController.reset();
                      _fadeController.forward();
                      _slideController.forward();
                    },
                    tooltip: 'Refresh Statistics',
                  ),
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDesign.spacing16,
                      vertical: AppDesign.spacing12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppDesign.radius16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: Colors.white.withOpacity(0.9),
                          size: 20,
                        ),
                        const SizedBox(width: AppDesign.spacing12),
                        Expanded(
                          child: Text(
                            'Real-time analytics and performance metrics',
                            style: AppDesign.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.surfaceVariant,
                AppColors.surfaceVariant.withOpacity(0.8),
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Consumer<AdminProvider>(
                    builder: (context, adminProvider, child) {
                      if (adminProvider.isLoading) {
                        return _buildLoadingState();
                      }

                      final stats = adminProvider.statistics;
                      print('📱 Building statistics screen with data:');
                      print('   - Total Events: ${stats.totalEvents}');
                      print('   - Active Users: ${stats.activeUsers}');
                      print('   - Approved Events: ${stats.approvedEvents}');
                      print('   - Pending Events: ${stats.pendingEvents}');
                      print('   - Rejected Events: ${stats.rejectedEvents}');

                      // Check if we have any data to display
                      final hasData =
                          stats.totalEvents > 0 ||
                          stats.activeUsers > 0 ||
                          stats.approvedEvents > 0 ||
                          stats.pendingEvents > 0 ||
                          stats.rejectedEvents > 0;

                      if (!hasData) {
                        return _buildNoDataState();
                      }

                      return Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppDesign.radius20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, -2),
                                  ),
                                ],
                              ),
                              child: RefreshIndicator(
                                onRefresh: () async {
                                  await adminProvider.loadStatistics();
                                  _fadeController.reset();
                                  _slideController.reset();
                                  _fadeController.forward();
                                  _slideController.forward();
                                },
                                color: AppColors.adminPrimary,
                                backgroundColor: Colors.white,
                                child: CustomScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  slivers: [
                                    SliverPadding(
                                      padding: EdgeInsets.fromLTRB(
                                        constraints.maxWidth > 600
                                            ? AppDesign.spacing24
                                            : AppDesign.spacing16,
                                        AppDesign.spacing16,
                                        constraints.maxWidth > 600
                                            ? AppDesign.spacing24
                                            : AppDesign.spacing16,
                                        AppDesign.spacing32,
                                      ),
                                      sliver: SliverList(
                                        delegate: SliverChildListDelegate([
                                          // Overview Cards
                                          _buildOverviewSection(stats),
                                          const SizedBox(
                                            height: AppDesign.spacing24,
                                          ),

                                          // Charts Section
                                          _buildChartsSection(
                                            stats,
                                            constraints,
                                          ),
                                          const SizedBox(
                                            height: AppDesign.spacing24,
                                          ),

                                          // Detailed Metrics
                                          _buildDetailedMetrics(stats),
                                          const SizedBox(
                                            height: AppDesign.spacing24,
                                          ),

                                          // Recent Activity
                                          _buildRecentActivity(stats),
                                        ]),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: AdminBottomNavigationBar(
          currentIndex: _currentIndex,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.adminPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDesign.radius16),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              size: 40,
              color: AppColors.adminPrimary,
            ),
          ),
          const SizedBox(height: AppDesign.spacing16),
          Text(
            'Loading Statistics...',
            style: AppDesign.bodyLarge.copyWith(
              color: AppColors.adminPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDesign.spacing8),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: AppColors.adminPrimary.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.adminPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDesign.radius16),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              size: 40,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: AppDesign.spacing16),
          Text(
            'No Data Available',
            style: AppDesign.bodyLarge.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDesign.spacing8),
          Text(
            'Statistics will appear once events and users are added',
            style: AppDesign.bodySmall.copyWith(
              color: Colors.grey.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDesign.spacing24),
          ElevatedButton.icon(
            onPressed: () => context.read<AdminProvider>().loadStatistics(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesign.spacing16,
                vertical: AppDesign.spacing12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesign.radius12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(AdminStatisticsModel stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: AppDesign.heading3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppDesign.spacing16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Events',
                stats.totalEvents.toString(),
                Icons.event,
                AppColors.adminPrimary,
              ),
            ),
            const SizedBox(width: AppDesign.spacing12),
            Expanded(
              child: _buildMetricCard(
                'Active Users',
                stats.activeUsers.toString(),
                Icons.people,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDesign.spacing12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Approved',
                stats.approvedEvents.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: AppDesign.spacing12),
            Expanded(
              child: _buildMetricCard(
                'Pending',
                stats.pendingEvents.toString(),
                Icons.pending,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartsSection(
    AdminStatisticsModel stats,
    BoxConstraints constraints,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics',
          style: AppDesign.heading3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppDesign.spacing16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDesign.spacing20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDesign.radius16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
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
              Text(
                'Events by Status',
                style: AppDesign.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDesign.spacing16),
              SizedBox(height: 200, child: _buildSimpleChart(stats)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedMetrics(AdminStatisticsModel stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Metrics',
          style: AppDesign.heading3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppDesign.spacing16),
        Container(
          padding: const EdgeInsets.all(AppDesign.spacing20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDesign.radius16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildMetricRow(
                'Total Registrations',
                stats.totalRegistrations.toString(),
              ),
              const Divider(height: 24),
              _buildMetricRow(
                'Average Events per Month',
                stats.averageEventsPerMonth.toStringAsFixed(1),
              ),
              const Divider(height: 24),
              _buildMetricRow('Top Category', stats.topCategory),
              const Divider(height: 24),
              _buildMetricRow(
                'Most Active Organizer',
                stats.mostActiveOrganizer,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(AdminStatisticsModel stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: AppDesign.heading3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppDesign.spacing16),
        Container(
          padding: const EdgeInsets.all(AppDesign.spacing20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDesign.radius16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: stats.recentActivities
                .map((activity) => _buildActivityItem(activity))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDesign.radius16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDesign.spacing8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDesign.radius12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppDesign.spacing12),
          Text(
            value,
            style: AppDesign.heading2.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: AppDesign.spacing4),
          Text(
            title,
            style: AppDesign.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleChart(AdminStatisticsModel stats) {
    final total =
        stats.approvedEvents + stats.pendingEvents + stats.rejectedEvents;
    if (total == 0) {
      return Center(
        child: Text(
          'No data available',
          style: AppDesign.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: stats.approvedEvents,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(AppDesign.radius8),
            ),
            child: Center(
              child: Text(
                '${((stats.approvedEvents / total) * 100).toStringAsFixed(1)}%',
                style: AppDesign.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        if (stats.pendingEvents > 0) ...[
          const SizedBox(width: 4),
          Expanded(
            flex: stats.pendingEvents,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(AppDesign.radius8),
              ),
              child: Center(
                child: Text(
                  '${((stats.pendingEvents / total) * 100).toStringAsFixed(1)}%',
                  style: AppDesign.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
        if (stats.rejectedEvents > 0) ...[
          const SizedBox(width: 4),
          Expanded(
            flex: stats.rejectedEvents,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(AppDesign.radius8),
              ),
              child: Center(
                child: Text(
                  '${((stats.rejectedEvents / total) * 100).toStringAsFixed(1)}%',
                  style: AppDesign.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppDesign.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: AppDesign.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesign.spacing12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.adminPrimary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppDesign.spacing12),
          Expanded(
            child: Text(
              activity,
              style: AppDesign.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
