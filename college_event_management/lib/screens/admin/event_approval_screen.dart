import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/event_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_design.dart';
import '../../utils/navigation_helper.dart';
import '../../widgets/admin_bottom_navigation_bar.dart';

class EventApprovalScreen extends StatefulWidget {
  const EventApprovalScreen({super.key});

  @override
  State<EventApprovalScreen> createState() => _EventApprovalScreenState();
}

class _EventApprovalScreenState extends State<EventApprovalScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 1;
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _sortBy = 'date_desc';
  String _timeFilter = 'all';
  Set<String> _selectedEvents = {};
  bool _isSelectionMode = false;
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
      context.read<AdminProvider>().loadAllEvents();
      // Start animations
      _fadeController.forward();
      _slideController.forward();
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
                    'Event Management',
                    style: AppDesign.heading2.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Review and approve event submissions',
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
                    icon: const Icon(Icons.filter_list, size: 20),
                    onPressed: () => _showFilterBottomSheet(context),
                    tooltip: 'Advanced Filters',
                  ),
                ),
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
                      context.read<AdminProvider>().loadAllEvents();
                    },
                    tooltip: 'Refresh',
                  ),
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    decoration:
                        AppDesign.textFieldDecoration(
                          hintText:
                              'Search by title, organizer, or location...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.adminPrimary.withOpacity(0.7),
                          ),
                        ).copyWith(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppDesign.radius16,
                            ),
                            borderSide: BorderSide(
                              color: AppColors.adminPrimary.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppDesign.radius16,
                            ),
                            borderSide: BorderSide(
                              color: AppColors.adminPrimary.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppDesign.radius16,
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.adminPrimary,
                              width: 2,
                            ),
                          ),
                        ),
                    onChanged: (v) => setState(() => _searchQuery = v),
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

                      final filteredSorted = _filterAndSort(
                        adminProvider.allEvents,
                      );

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
                                  await adminProvider.loadAllEvents();
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
                                    if (filteredSorted.isEmpty &&
                                        adminProvider.allEvents.isEmpty)
                                      SliverFillRemaining(
                                        hasScrollBody: false,
                                        child: _buildEnhancedEmptyState(),
                                      )
                                    else
                                      SliverPadding(
                                        padding: EdgeInsets.fromLTRB(
                                          constraints.maxWidth > 600
                                              ? AppDesign.spacing24
                                              : AppDesign.spacing16,
                                          AppDesign.spacing8,
                                          constraints.maxWidth > 600
                                              ? AppDesign.spacing24
                                              : AppDesign.spacing16,
                                          AppDesign.spacing32,
                                        ),
                                        sliver: SliverList(
                                          delegate: SliverChildBuilderDelegate((
                                            context,
                                            index,
                                          ) {
                                            final event = filteredSorted[index];
                                            return TweenAnimationBuilder<
                                              double
                                            >(
                                              duration: Duration(
                                                milliseconds:
                                                    300 + (index * 50),
                                              ),
                                              tween: Tween(
                                                begin: 0.0,
                                                end: 1.0,
                                              ),
                                              builder: (context, value, child) {
                                                return Transform.translate(
                                                  offset: Offset(
                                                    0,
                                                    20 * (1 - value),
                                                  ),
                                                  child: Opacity(
                                                    opacity: value,
                                                    child:
                                                        _buildEnhancedEventCard(
                                                          event,
                                                          adminProvider,
                                                          constraints,
                                                        ),
                                                  ),
                                                );
                                              },
                                            );
                                          }, childCount: filteredSorted.length),
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
        floatingActionButton: _isSelectionMode && _selectedEvents.isNotEmpty
            ? _buildBulkActionButtons()
            : null,
      ),
    );
  }

  Widget _buildLoadingState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Header skeleton
          Container(
            margin: const EdgeInsets.all(AppDesign.spacing16),
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.adminPrimary.withOpacity(0.1),
                  AppColors.adminSecondary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(AppDesign.radius16),
            ),
            child: Container(
              padding: const EdgeInsets.all(AppDesign.spacing16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(AppDesign.radius16),
                border: Border.all(
                  color: AppColors.adminPrimary.withOpacity(0.1),
                ),
              ),
            ),
          ),

          // Stats skeleton
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppDesign.spacing16),
            height: 100,
            child: Row(
              children: List.generate(
                3,
                (index) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: AppDesign.spacing12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDesign.radius12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppDesign.spacing24),

          // List skeleton
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDesign.radius20),
                ),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(AppDesign.spacing16),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppDesign.spacing12),
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDesign.radius16),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppDesign.spacing16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(AppDesign.radius16),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filters',
          style: AppDesign.labelLarge.copyWith(
            color: const Color(0xFF374151),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDesign.spacing12),

        // Status filters with enhanced design
        Container(
          padding: const EdgeInsets.all(AppDesign.spacing12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppDesign.radius12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 16,
                    color: AppColors.adminPrimary,
                  ),
                  const SizedBox(width: AppDesign.spacing8),
                  Text(
                    'Status',
                    style: AppDesign.labelMedium.copyWith(
                      color: const Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDesign.spacing12),
              Wrap(
                spacing: AppDesign.spacing8,
                runSpacing: AppDesign.spacing8,
                children: [
                  _buildEnhancedFilterChip(
                    'All',
                    'all',
                    'status',
                    Icons.all_inclusive,
                  ),
                  _buildEnhancedFilterChip(
                    'Published',
                    'published',
                    'status',
                    Icons.check_circle,
                  ),
                  _buildEnhancedFilterChip(
                    'Pending',
                    'pending',
                    'status',
                    Icons.schedule,
                  ),
                  _buildEnhancedFilterChip(
                    'Rejected',
                    'rejected',
                    'status',
                    Icons.cancel,
                  ),
                  _buildEnhancedFilterChip(
                    'Cancelled',
                    'cancelled',
                    'status',
                    Icons.block,
                  ),
                  _buildEnhancedFilterChip(
                    'Draft',
                    'draft',
                    'status',
                    Icons.edit,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDesign.spacing16),

        // Time filters
        Container(
          padding: const EdgeInsets.all(AppDesign.spacing12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppDesign.radius12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.adminPrimary,
                  ),
                  const SizedBox(width: AppDesign.spacing8),
                  Text(
                    'Time Period',
                    style: AppDesign.labelMedium.copyWith(
                      color: const Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDesign.spacing12),
              Wrap(
                spacing: AppDesign.spacing8,
                runSpacing: AppDesign.spacing8,
                children: [
                  _buildEnhancedFilterChip(
                    'All Time',
                    'all',
                    'time',
                    Icons.calendar_view_month,
                  ),
                  _buildEnhancedFilterChip(
                    'Upcoming',
                    'upcoming',
                    'time',
                    Icons.upcoming,
                  ),
                  _buildEnhancedFilterChip(
                    'Ongoing',
                    'ongoing',
                    'time',
                    Icons.play_circle,
                  ),
                  _buildEnhancedFilterChip(
                    'Past',
                    'past',
                    'time',
                    Icons.history,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDesign.spacing16),

        // Sort options
        Container(
          padding: const EdgeInsets.all(AppDesign.spacing12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppDesign.radius12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sort, size: 16, color: AppColors.adminPrimary),
                  const SizedBox(width: AppDesign.spacing8),
                  Text(
                    'Sort By',
                    style: AppDesign.labelMedium.copyWith(
                      color: const Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDesign.spacing12),
              Wrap(
                spacing: AppDesign.spacing8,
                runSpacing: AppDesign.spacing8,
                children: [
                  _buildEnhancedFilterChip(
                    'Newest',
                    'date_desc',
                    'sort',
                    Icons.arrow_downward,
                  ),
                  _buildEnhancedFilterChip(
                    'Oldest',
                    'date_asc',
                    'sort',
                    Icons.arrow_upward,
                  ),
                  _buildEnhancedFilterChip(
                    'A-Z',
                    'title_asc',
                    'sort',
                    Icons.sort_by_alpha,
                  ),
                  _buildEnhancedFilterChip(
                    'Z-A',
                    'title_desc',
                    'sort',
                    Icons.sort_by_alpha,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.adminPrimary.withOpacity(0.2),
                  AppColors.adminSecondary.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppDesign.radius24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.adminPrimary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.event_available_outlined,
              size: 60,
              color: AppColors.adminPrimary,
            ),
          ),
          const SizedBox(height: AppDesign.spacing24),
          Text(
            'No Events Yet',
            style: AppDesign.heading2.copyWith(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDesign.spacing8),
          Text(
            'Events will appear here once submitted for approval.\nCheck back later or refresh to load new submissions.',
            style: AppDesign.bodyMedium.copyWith(
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDesign.spacing32),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.adminPrimary, AppColors.adminSecondary],
              ),
              borderRadius: BorderRadius.circular(AppDesign.radius16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.adminPrimary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                context.read<AdminProvider>().loadAllEvents();
                _fadeController.reset();
                _slideController.reset();
                _fadeController.forward();
                _slideController.forward();
              },
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Refresh Events'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesign.spacing24,
                  vertical: AppDesign.spacing16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDesign.radius16),
                ),
                textStyle: AppDesign.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(AdminProvider adminProvider) {
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
              Icons.event_available,
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
                  'Event Approval Center',
                  style: AppDesign.heading2.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: AppDesign.spacing4),
                Text(
                  'Review and manage event submissions efficiently',
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

  Widget _buildOverviewStats(AdminProvider adminProvider) {
    final events = adminProvider.allEvents;
    final pendingCount = events.where((e) => e.status == 'pending').length;
    final publishedCount = events.where((e) => e.status == 'published').length;
    final rejectedCount = events.where((e) => e.status == 'rejected').length;

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
                _buildStatCard(
                  'Pending Approval',
                  '$pendingCount',
                  Icons.pending_actions,
                  AppColors.statusPending,
                ),
                _buildStatCard(
                  'Published Events',
                  '$publishedCount',
                  Icons.check_circle,
                  AppColors.statusApproved,
                ),
                _buildStatCard(
                  'Rejected Events',
                  '$rejectedCount',
                  Icons.cancel,
                  AppColors.statusRejected,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDesign.radius16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDesign.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppDesign.radius12),
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
  }

  Widget _buildEventsListHeader(AdminProvider adminProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _isSelectionMode
                    ? '${_selectedEvents.length} selected'
                    : 'Event Submissions',
                style: AppDesign.heading2.copyWith(
                  color: const Color(0xFF111827),
                ),
              ),
            ),
            if (!_isSelectionMode) ...[
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _statusFilter = 'pending';
                    _timeFilter = 'all';
                    _sortBy = 'date_desc';
                  });
                },
                icon: const Icon(Icons.filter_list, size: 16),
                label: const Text('Show Pending Only'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.adminPrimary,
                  textStyle: AppDesign.labelMedium,
                ),
              ),
              const SizedBox(width: AppDesign.spacing8),
              TextButton.icon(
                onPressed: () => setState(() => _isSelectionMode = true),
                icon: const Icon(Icons.checklist, size: 16),
                label: const Text('Select'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.adminPrimary,
                  textStyle: AppDesign.labelMedium,
                ),
              ),
            ] else ...[
              TextButton.icon(
                onPressed: () => setState(() {
                  _selectedEvents.clear();
                  _isSelectionMode = false;
                }),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Cancel'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey,
                  textStyle: AppDesign.labelMedium,
                ),
              ),
              const SizedBox(width: AppDesign.spacing8),
              TextButton.icon(
                onPressed: () {
                  final allPending = adminProvider.allEvents
                      .where((e) => e.status == 'pending')
                      .map((e) => e.id)
                      .toSet();
                  setState(() {
                    if (_selectedEvents.containsAll(allPending)) {
                      _selectedEvents.removeAll(allPending);
                    } else {
                      _selectedEvents.addAll(allPending);
                    }
                  });
                },
                icon: const Icon(Icons.select_all, size: 16),
                label: const Text('Select All Pending'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.adminPrimary,
                  textStyle: AppDesign.labelMedium,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppDesign.spacing16),
      ],
    );
  }

  Widget _buildEnhancedFilterChip(
    String label,
    String value,
    String type,
    IconData icon,
  ) {
    bool isSelected = false;
    switch (type) {
      case 'status':
        isSelected = _statusFilter == value;
        break;
      case 'time':
        isSelected = _timeFilter == value;
        break;
      case 'sort':
        isSelected = _sortBy == value;
        break;
    }

    return AnimatedContainer(
      duration: AppDesign.fastAnimation,
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppColors.adminPrimary
                  : const Color(0xFF6B7280),
            ),
            const SizedBox(width: AppDesign.spacing6),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            switch (type) {
              case 'status':
                _statusFilter = value;
                break;
              case 'time':
                _timeFilter = value;
                break;
              case 'sort':
                _sortBy = value;
                break;
            }
          });
        },
        selectedColor: AppColors.adminPrimary.withOpacity(0.15),
        checkmarkColor: AppColors.adminPrimary,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppColors.adminPrimary : AppColors.cardBorder,
          width: isSelected ? 2 : 1,
        ),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.adminPrimary : const Color(0xFF6B7280),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesign.spacing12,
          vertical: AppDesign.spacing10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radius20),
        ),
      ),
    );
  }

  Widget _buildEnhancedEventCard(
    EventModel event,
    AdminProvider adminProvider,
    BoxConstraints constraints,
  ) {
    final isSelected = _selectedEvents.contains(event.id);
    final isWideScreen = constraints.maxWidth > 600;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDesign.spacing12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDesign.radius16),
        border: Border.all(
          color: isSelected ? AppColors.adminPrimary : AppColors.cardBorder,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.adminPrimary.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: _isSelectionMode
            ? () => setState(() {
                if (isSelected) {
                  _selectedEvents.remove(event.id);
                } else {
                  _selectedEvents.add(event.id);
                }
              })
            : () => context.go('/event-detail/${event.id}'),
        borderRadius: BorderRadius.circular(AppDesign.radius16),
        child: Padding(
          padding: const EdgeInsets.all(AppDesign.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with enhanced design
              Row(
                children: [
                  if (_isSelectionMode)
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: AppDesign.spacing12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.adminPrimary
                              : AppColors.cardBorder,
                          width: 2,
                        ),
                        color: isSelected
                            ? AppColors.adminPrimary
                            : Colors.white,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
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
                  _buildEnhancedStatusChip(
                    _getStatusText(event.status),
                    _getStatusColor(event.status),
                  ),
                ],
              ),

              const SizedBox(height: AppDesign.spacing12),

              // Enhanced event details
              LayoutBuilder(
                builder: (context, cardConstraints) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category icon with enhanced design
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

                      // Event information with better layout
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Organizer
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 14,
                                  color: const Color(0xFF6B7280),
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

                            // Description with better styling
                            Container(
                              padding: const EdgeInsets.all(AppDesign.spacing8),
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
                                maxLines: isWideScreen ? 2 : 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            const SizedBox(height: AppDesign.spacing12),

                            // Location and date/time
                            if (isWideScreen)
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

                            // Participants count
                            _buildInfoRow(
                              Icons.people,
                              '${event.currentParticipants}/${event.maxParticipants} participants',
                              AppColors.adminPrimary,
                            ),
                          ],
                        ),
                      ),

                      // Enhanced action buttons
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildEnhancedActionButtons(event, adminProvider),
                          const SizedBox(height: AppDesign.spacing8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
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
            borderRadius: BorderRadius.circular(AppDesign.radius6),
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: AppDesign.spacing6),
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

  Widget _buildEnhancedStatusChip(String label, Color color) {
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
          const SizedBox(width: AppDesign.spacing6),
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

  Widget _buildEnhancedActionButtons(
    EventModel event,
    AdminProvider adminProvider,
  ) {
    switch (event.status) {
      case 'pending':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEnhancedActionButton(
              icon: Icons.close,
              color: AppColors.statusRejected,
              onPressed: () => _showRejectDialog(event, adminProvider),
              tooltip: 'Reject Event',
            ),
            const SizedBox(width: AppDesign.spacing8),
            _buildEnhancedActionButton(
              icon: Icons.check,
              color: AppColors.statusApproved,
              onPressed: () => _approveEvent(event, adminProvider),
              tooltip: 'Approve Event',
            ),
          ],
        );
      case 'published':
        return _buildEnhancedActionButton(
          icon: Icons.cancel,
          color: AppColors.statusCancelled,
          onPressed: () => _showCancelDialog(event, adminProvider),
          tooltip: 'Cancel Event',
        );
      case 'rejected':
        return _buildEnhancedActionButton(
          icon: Icons.check,
          color: AppColors.statusApproved,
          onPressed: () => _approveEvent(event, adminProvider),
          tooltip: 'Approve Event',
        );
      case 'cancelled':
        return _buildEnhancedActionButton(
          icon: Icons.check,
          color: AppColors.statusApproved,
          onPressed: () => _approveEvent(event, adminProvider),
          tooltip: 'Approve Event',
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEnhancedActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDesign.radius12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: color),
        padding: EdgeInsets.zero,
        tooltip: tooltip,
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'học thuật':
        return Icons.school;
      case 'thể thao':
        return Icons.sports_soccer;
      case 'văn hóa - nghệ thuật':
        return Icons.palette;
      case 'tình nguyện':
        return Icons.volunteer_activism;
      case 'kỹ năng mềm':
        return Icons.lightbulb;
      case 'hội thảo':
        return Icons.forum;
      case 'triển lãm':
        return Icons.exposure;
      default:
        return Icons.event;
    }
  }

  Widget _buildFilterChip(String label, String value, String type) {
    bool isSelected = false;
    switch (type) {
      case 'status':
        isSelected = _statusFilter == value;
        break;
      case 'time':
        isSelected = _timeFilter == value;
        break;
      case 'sort':
        isSelected = _sortBy == value;
        break;
    }

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          switch (type) {
            case 'status':
              _statusFilter = value;
              break;
            case 'time':
              _timeFilter = value;
              break;
            case 'sort':
              _sortBy = value;
              break;
          }
        });
      },
      selectedColor: AppColors.adminPrimary.withOpacity(0.2),
      checkmarkColor: AppColors.adminPrimary,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.adminPrimary : AppColors.cardBorder,
        width: 1,
      ),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.adminPrimary : const Color(0xFF6B7280),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 14,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spacing12,
        vertical: AppDesign.spacing8,
      ),
    );
  }

  Widget _buildEventCard(EventModel event, AdminProvider adminProvider) {
    final isSelected = _selectedEvents.contains(event.id);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDesign.spacing12),
      decoration: AppDesign.cardDecoration.copyWith(
        border: isSelected
            ? Border.all(color: AppColors.adminPrimary, width: 2)
            : null,
      ),
      child: InkWell(
        onTap: _isSelectionMode
            ? () => setState(() {
                if (isSelected) {
                  _selectedEvents.remove(event.id);
                } else {
                  _selectedEvents.add(event.id);
                }
              })
            : () => context.go('/event-detail/${event.id}'),
        borderRadius: BorderRadius.circular(AppDesign.radius16),
        child: Padding(
          padding: const EdgeInsets.all(AppDesign.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with checkbox, title and status
              Row(
                children: [
                  if (_isSelectionMode)
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) => setState(() {
                        if (value == true) {
                          _selectedEvents.add(event.id);
                        } else {
                          _selectedEvents.remove(event.id);
                        }
                      }),
                      activeColor: AppColors.adminPrimary,
                    ),
                  Expanded(
                    child: Text(
                      event.title,
                      style: AppDesign.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppDesign.spacing12),
                  _buildStatusChip(
                    _getStatusText(event.status),
                    _getStatusColor(event.status),
                  ),
                ],
              ),

              const SizedBox(height: AppDesign.spacing12),

              // Event details
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWideScreen = constraints.maxWidth > 400;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(
                            event.category,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppDesign.radius12,
                          ),
                        ),
                        child: Icon(
                          Icons.event,
                          color: _getCategoryColor(event.category),
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: AppDesign.spacing12),

                      // Event information
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Organizer: ${event.organizerName}',
                              style: AppDesign.bodyMedium.copyWith(
                                color: const Color(0xFF6B7280),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppDesign.spacing4),
                            Text(
                              event.description,
                              style: AppDesign.bodySmall.copyWith(
                                color: const Color(0xFF6B7280),
                              ),
                              maxLines: isWideScreen ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppDesign.spacing8),

                            // Location and participants
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                const SizedBox(width: AppDesign.spacing4),
                                Expanded(
                                  child: Text(
                                    event.location,
                                    style: AppDesign.bodySmall.copyWith(
                                      color: const Color(0xFF6B7280),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDesign.spacing4),

                            // Date and participants count
                            if (isWideScreen)
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(width: AppDesign.spacing4),
                                  Text(
                                    _formatDate(event.startDate),
                                    style: AppDesign.bodySmall.copyWith(
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(width: AppDesign.spacing16),
                                  Icon(
                                    Icons.people,
                                    size: 16,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(width: AppDesign.spacing4),
                                  Text(
                                    '${event.currentParticipants}/${event.maxParticipants}',
                                    style: AppDesign.bodySmall.copyWith(
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: const Color(0xFF9CA3AF),
                                      ),
                                      const SizedBox(width: AppDesign.spacing4),
                                      Text(
                                        _formatDate(event.startDate),
                                        style: AppDesign.bodySmall.copyWith(
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppDesign.spacing4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 16,
                                        color: const Color(0xFF9CA3AF),
                                      ),
                                      const SizedBox(width: AppDesign.spacing4),
                                      Text(
                                        '${event.currentParticipants}/${event.maxParticipants}',
                                        style: AppDesign.bodySmall.copyWith(
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),

                      // Action buttons
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildActionButtons(event, adminProvider),
                          const SizedBox(height: AppDesign.spacing8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _approveEvent(EventModel event, AdminProvider adminProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radius16),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.statusApproved.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDesign.radius12),
              ),
              child: Icon(
                Icons.check_circle,
                color: AppColors.statusApproved,
                size: 24,
              ),
            ),
            const SizedBox(width: AppDesign.spacing12),
            Expanded(
              child: Text(
                'Confirm Approval',
                style: AppDesign.heading3.copyWith(
                  color: const Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Details:',
              style: AppDesign.labelLarge.copyWith(
                color: const Color(0xFF374151),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDesign.spacing8),
            Container(
              padding: const EdgeInsets.all(AppDesign.spacing12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(AppDesign.radius8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: AppDesign.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: AppDesign.spacing4),
                  Text(
                    'Organizer: ${event.organizerName}',
                    style: AppDesign.bodySmall.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDesign.spacing16),
            Text(
              'Are you sure you want to approve this event? Once approved, it will be published and visible to all users.',
              style: AppDesign.bodyMedium.copyWith(
                color: const Color(0xFF374151),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                safePop(context, fallbackRoute: '/admin-dashboard'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesign.spacing16,
                vertical: AppDesign.spacing12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesign.radius8),
              ),
            ),
            child: Text(
              'Cancel',
              style: AppDesign.labelLarge.copyWith(
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await adminProvider.approveEvent(event.id);
              if (mounted) {
                safePop(context, fallbackRoute: '/admin-dashboard');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Text('Event approved successfully'),
                      ],
                    ),
                    backgroundColor: AppColors.statusApproved,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDesign.radius8),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusApproved,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesign.spacing20,
                vertical: AppDesign.spacing12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesign.radius8),
              ),
            ),
            child: const Text('Approve Event'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(EventModel event, AdminProvider adminProvider) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radius16),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.statusRejected.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDesign.radius12),
              ),
              child: Icon(
                Icons.cancel,
                color: AppColors.statusRejected,
                size: 24,
              ),
            ),
            const SizedBox(width: AppDesign.spacing12),
            Expanded(
              child: Text(
                'Reject Event',
                style: AppDesign.heading3.copyWith(
                  color: const Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Details:',
              style: AppDesign.labelLarge.copyWith(
                color: const Color(0xFF374151),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDesign.spacing8),
            Container(
              padding: const EdgeInsets.all(AppDesign.spacing12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(AppDesign.radius8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: AppDesign.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: AppDesign.spacing4),
                  Text(
                    'Organizer: ${event.organizerName}',
                    style: AppDesign.bodySmall.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDesign.spacing16),
            Text(
              'Rejection Reason (Required):',
              style: AppDesign.labelLarge.copyWith(
                color: const Color(0xFF374151),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDesign.spacing8),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Please provide a reason for rejection...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDesign.radius8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDesign.radius8),
                  borderSide: BorderSide(
                    color: AppColors.adminPrimary,
                    width: 2,
                  ),
                ),
              ),
              maxLines: 3,
              style: AppDesign.bodyMedium,
            ),
            const SizedBox(height: AppDesign.spacing12),
            Container(
              padding: const EdgeInsets.all(AppDesign.spacing12),
              decoration: BoxDecoration(
                color: AppColors.statusRejected.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppDesign.radius8),
                border: Border.all(
                  color: AppColors.statusRejected.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: AppColors.statusRejected,
                    size: 20,
                  ),
                  const SizedBox(width: AppDesign.spacing8),
                  Expanded(
                    child: Text(
                      'The organizer will be notified with this reason. Please be constructive and professional.',
                      style: AppDesign.bodySmall.copyWith(
                        color: AppColors.statusRejected,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                safePop(context, fallbackRoute: '/admin-dashboard'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesign.spacing16,
                vertical: AppDesign.spacing12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesign.radius8),
              ),
            ),
            child: Text(
              'Cancel',
              style: AppDesign.labelLarge.copyWith(
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isNotEmpty) {
                await adminProvider.rejectEvent(
                  event.id,
                  reasonController.text.trim(),
                );
                if (mounted) {
                  safePop(context, fallbackRoute: '/admin-dashboard');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          const Text('Event rejected successfully'),
                        ],
                      ),
                      backgroundColor: AppColors.statusRejected,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDesign.radius8),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRejected,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesign.spacing20,
                vertical: AppDesign.spacing12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesign.radius8),
              ),
            ),
            child: const Text('Reject Event'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(EventModel event, AdminProvider adminProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radius16),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.statusCancelled.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDesign.radius12),
              ),
              child: Icon(
                Icons.cancel_schedule_send,
                color: AppColors.statusCancelled,
                size: 24,
              ),
            ),
            const SizedBox(width: AppDesign.spacing12),
            Expanded(
              child: Text(
                'Cancel Event',
                style: AppDesign.heading3.copyWith(
                  color: const Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Details:',
              style: AppDesign.labelLarge.copyWith(
                color: const Color(0xFF374151),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDesign.spacing8),
            Container(
              padding: const EdgeInsets.all(AppDesign.spacing12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(AppDesign.radius8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: AppDesign.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: AppDesign.spacing4),
                  Text(
                    'Organizer: ${event.organizerName}',
                    style: AppDesign.bodySmall.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDesign.spacing16),
            Container(
              padding: const EdgeInsets.all(AppDesign.spacing12),
              decoration: BoxDecoration(
                color: AppColors.statusCancelled.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppDesign.radius8),
                border: Border.all(
                  color: AppColors.statusCancelled.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: AppColors.statusCancelled,
                    size: 20,
                  ),
                  const SizedBox(width: AppDesign.spacing8),
                  Expanded(
                    child: Text(
                      'This action will cancel the event and notify all registered participants. This cannot be undone.',
                      style: AppDesign.bodySmall.copyWith(
                        color: AppColors.statusCancelled,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDesign.spacing16),
            Text(
              'Are you sure you want to cancel this event?',
              style: AppDesign.bodyMedium.copyWith(
                color: const Color(0xFF374151),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesign.spacing16,
                vertical: AppDesign.spacing12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesign.radius8),
              ),
            ),
            child: Text(
              'Keep Event',
              style: AppDesign.labelLarge.copyWith(
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await adminProvider.cancelEvent(event.id);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          Icons.cancel_schedule_send,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text('Event cancelled successfully'),
                      ],
                    ),
                    backgroundColor: AppColors.statusCancelled,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDesign.radius8),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusCancelled,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesign.spacing20,
                vertical: AppDesign.spacing12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesign.radius8),
              ),
            ),
            child: const Text('Cancel Event'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spacing8,
        vertical: AppDesign.spacing4,
      ),
      decoration: AppDesign.statusChipDecoration(color),
      child: Text(
        label,
        style: AppDesign.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'học thuật':
        return const Color(0xFF8b5cf6);
      case 'thể thao':
        return const Color(0xFF10b981);
      case 'văn hóa - nghệ thuật':
        return const Color(0xFFf59e0b);
      case 'tình nguyện':
        return const Color(0xFFef4444);
      case 'kỹ năng mềm':
        return const Color(0xFF3b82f6);
      case 'hội thảo':
        return const Color(0xFF06b6d4);
      case 'triển lãm':
        return const Color(0xFF8b5cf6);
      default:
        return const Color(0xFF6b7280);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'published':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      case 'draft':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'published':
        return 'Published';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      case 'draft':
        return 'Draft';
      default:
        return 'Unknown';
    }
  }

  Widget _buildActionButtons(EventModel event, AdminProvider adminProvider) {
    switch (event.status) {
      case 'pending':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              icon: Icons.close,
              color: AppColors.statusRejected,
              onPressed: () => _showRejectDialog(event, adminProvider),
              tooltip: 'Reject Event',
            ),
            const SizedBox(width: AppDesign.spacing8),
            _buildActionButton(
              icon: Icons.check,
              color: AppColors.statusApproved,
              onPressed: () => _approveEvent(event, adminProvider),
              tooltip: 'Approve Event',
            ),
          ],
        );
      case 'published':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              icon: Icons.cancel,
              color: AppColors.statusCancelled,
              onPressed: () => _showCancelDialog(event, adminProvider),
              tooltip: 'Cancel Event',
            ),
          ],
        );
      case 'rejected':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              icon: Icons.check,
              color: AppColors.statusApproved,
              onPressed: () => _approveEvent(event, adminProvider),
              tooltip: 'Approve Event',
            ),
          ],
        );
      case 'cancelled':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              icon: Icons.check,
              color: AppColors.statusApproved,
              onPressed: () => _approveEvent(event, adminProvider),
              tooltip: 'Approve Event',
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBulkActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spacing16,
        vertical: AppDesign.spacing8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDesign.radius16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            onPressed: () => _bulkApproveEvents(),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Approve All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusApproved,
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
          const SizedBox(width: AppDesign.spacing12),
          ElevatedButton.icon(
            onPressed: () => _showBulkRejectDialog(),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Reject All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRejected,
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

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDesign.radius8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: color),
        padding: EdgeInsets.zero,
        tooltip: tooltip,
      ),
    );
  }

  Future<void> _bulkApproveEvents() async {
    if (_selectedEvents.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bulk Approval'),
        content: Text('Approve ${_selectedEvents.length} selected events?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusApproved,
            ),
            child: const Text('Approve All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final adminProvider = context.read<AdminProvider>();
      int successCount = 0;

      for (final eventId in _selectedEvents) {
        await adminProvider.approveEvent(eventId);
        successCount++;
      }

      setState(() {
        _selectedEvents.clear();
        _isSelectionMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully approved $successCount events'),
            backgroundColor: AppColors.statusApproved,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving events: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showBulkRejectDialog() async {
    if (_selectedEvents.isEmpty) return;

    final TextEditingController reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Multiple Events'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject ${_selectedEvents.length} selected events?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRejected,
            ),
            child: const Text('Reject All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final adminProvider = context.read<AdminProvider>();
      final reason = reasonController.text.trim();
      int successCount = 0;

      for (final eventId in _selectedEvents) {
        await adminProvider.rejectEvent(eventId, reason);
        successCount++;
      }

      setState(() {
        _selectedEvents.clear();
        _isSelectionMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully rejected $successCount events'),
            backgroundColor: AppColors.statusRejected,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting events: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<EventModel> _filterAndSort(List<EventModel> events) {
    List<EventModel> filtered = events.where((e) {
      final q = _searchQuery.trim().toLowerCase();
      final matchesQuery =
          q.isEmpty ||
          e.title.toLowerCase().contains(q) ||
          (e.organizerName.toLowerCase().contains(q));

      final matchesStatus = _statusFilter == 'all' || e.status == _statusFilter;
      final matchesTime = _matchesTimeFilter(e);

      return matchesQuery && matchesStatus && matchesTime;
    }).toList();

    switch (_sortBy) {
      case 'date_asc':
        filtered.sort((a, b) => a.startDate.compareTo(b.startDate));
        break;
      case 'title_asc':
        filtered.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case 'title_desc':
        filtered.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
      case 'date_desc':
      default:
        filtered.sort((a, b) => b.startDate.compareTo(a.startDate));
    }

    return filtered;
  }

  bool _matchesTimeFilter(EventModel event) {
    if (_timeFilter == 'all') return true;

    final now = DateTime.now();
    final startDate = event.startDate;
    final endDate = event.endDate;

    switch (_timeFilter) {
      case 'upcoming':
        // Sắp diễn ra: sự kiện chưa bắt đầu
        return startDate.isAfter(now) && event.status == 'published';
      case 'ongoing':
        // Đang diễn ra: sự kiện đang trong thời gian diễn ra
        return startDate.isBefore(now) &&
            endDate.isAfter(now) &&
            event.status == 'published';
      case 'past':
        // Đã qua: sự kiện đã kết thúc
        return endDate.isBefore(now) && event.status == 'published';
      case 'pending':
        // Chờ duyệt: sự kiện có trạng thái pending
        return event.status == 'pending';
      default:
        return true;
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDesign.radius16),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDesign.spacing16),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Advanced Filters',
                                style: AppDesign.heading2.copyWith(
                                  color: const Color(0xFF111827),
                                  fontSize: 18,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close),
                                tooltip: 'Close',
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDesign.spacing12),

                          Text(
                            'Status',
                            style: AppDesign.labelLarge.copyWith(
                              color: const Color(0xFF374151),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: AppDesign.spacing8),
                          Wrap(
                            spacing: AppDesign.spacing8,
                            runSpacing: AppDesign.spacing8,
                            children: [
                              _buildBottomSheetFilterChip(
                                'All',
                                'all',
                                'status',
                                modalSetState: modalSetState,
                              ),
                              _buildBottomSheetFilterChip(
                                'Published',
                                'published',
                                'status',
                                modalSetState: modalSetState,
                              ),
                              _buildBottomSheetFilterChip(
                                'Pending',
                                'pending',
                                'status',
                                modalSetState: modalSetState,
                              ),
                              _buildBottomSheetFilterChip(
                                'Rejected',
                                'rejected',
                                'status',
                                modalSetState: modalSetState,
                              ),
                              _buildBottomSheetFilterChip(
                                'Cancelled',
                                'cancelled',
                                'status',
                                modalSetState: modalSetState,
                              ),
                              _buildBottomSheetFilterChip(
                                'Draft',
                                'draft',
                                'status',
                                modalSetState: modalSetState,
                              ),
                            ],
                          ),

                          const SizedBox(height: AppDesign.spacing16),

                          Text(
                            'Time Period',
                            style: AppDesign.labelLarge.copyWith(
                              color: const Color(0xFF374151),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: AppDesign.spacing8),
                          Wrap(
                            spacing: AppDesign.spacing8,
                            runSpacing: AppDesign.spacing8,
                            children: [
                              _buildBottomSheetFilterChip(
                                'All Time',
                                'all',
                                'time',
                                modalSetState: modalSetState,
                              ),
                              _buildBottomSheetFilterChip(
                                'Upcoming',
                                'upcoming',
                                'time',
                                modalSetState: modalSetState,
                              ),
                              _buildBottomSheetFilterChip(
                                'Ongoing',
                                'ongoing',
                                'time',
                                modalSetState: modalSetState,
                              ),
                              _buildBottomSheetFilterChip(
                                'Past',
                                'past',
                                'time',
                                modalSetState: modalSetState,
                              ),
                            ],
                          ),

                          const SizedBox(height: AppDesign.spacing16),

                          Text(
                            'Sort By',
                            style: AppDesign.labelLarge.copyWith(
                              color: const Color(0xFF374151),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: AppDesign.spacing8),
                          Wrap(
                            spacing: AppDesign.spacing8,
                            runSpacing: AppDesign.spacing8,
                            children: [
                              _buildBottomSheetFilterChip(
                                'Newest',
                                'date_desc',
                                'sort',
                                modalSetState: modalSetState,
                              ),
                              _buildBottomSheetFilterChip(
                                'Oldest',
                                'date_asc',
                                'sort',
                                modalSetState: modalSetState,
                              ),
                              _buildBottomSheetFilterChip(
                                'A-Z',
                                'title_asc',
                                'sort',
                                modalSetState: modalSetState,
                              ),
                              _buildBottomSheetFilterChip(
                                'Z-A',
                                'title_desc',
                                'sort',
                                modalSetState: modalSetState,
                              ),
                            ],
                          ),

                          const SizedBox(height: AppDesign.spacing20),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: AppDesign.primaryButtonStyle.copyWith(
                                backgroundColor: MaterialStateProperty.all(
                                  AppColors.adminPrimary,
                                ),
                              ),
                              child: const Text('Apply Filters'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBottomSheetFilterChip(
    String label,
    String value,
    String type, {
    StateSetter? modalSetState,
  }) {
    bool isSelected = false;
    switch (type) {
      case 'status':
        isSelected = _statusFilter == value;
        break;
      case 'time':
        isSelected = _timeFilter == value;
        break;
      case 'sort':
        isSelected = _sortBy == value;
        break;
    }

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          switch (type) {
            case 'status':
              _statusFilter = value;
              break;
            case 'time':
              _timeFilter = value;
              break;
            case 'sort':
              _sortBy = value;
              break;
          }
        });
        if (modalSetState != null) {
          modalSetState(() {});
        }
      },
      selectedColor: AppColors.adminPrimary.withOpacity(0.2),
      checkmarkColor: AppColors.adminPrimary,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.adminPrimary : AppColors.cardBorder,
        width: 1,
      ),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.adminPrimary : const Color(0xFF6B7280),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spacing12,
        vertical: AppDesign.spacing8,
      ),
    );
  }
}
