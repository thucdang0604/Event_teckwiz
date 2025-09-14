import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/user_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_design.dart';
import '../../widgets/admin_bottom_navigation_bar.dart';
import '../../widgets/user_card_widget.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with TickerProviderStateMixin {
  final int _currentIndex = 3; // Users tab
  String _searchQuery = '';
  String _roleFilter = 'all';
  String _statusFilter = 'all';
  String _approvalFilter = 'all';
  final Set<String> _selectedUsers = {};
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
      context.read<AdminProvider>().loadUsers();
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
                    'User Management',
                    style: AppDesign.heading2.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Manage and approve user accounts',
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
                      context.read<AdminProvider>().loadUsers();
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
                          hintText: 'Search by name, email, or student ID...',
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
                        adminProvider.users,
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
                                  await adminProvider.loadUsers();
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
                                        adminProvider.users.isEmpty)
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
                                            final user = filteredSorted[index];
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
                                                    child: UserCardWidget(
                                                      user: user,
                                                      adminProvider:
                                                          adminProvider,
                                                      constraints: constraints,
                                                      isSelected: _selectedUsers
                                                          .contains(user.id),
                                                      onTap: _isSelectionMode
                                                          ? () => setState(() {
                                                              if (_selectedUsers
                                                                  .contains(
                                                                    user.id,
                                                                  )) {
                                                                _selectedUsers
                                                                    .remove(
                                                                      user.id,
                                                                    );
                                                              } else {
                                                                _selectedUsers
                                                                    .add(
                                                                      user.id,
                                                                    );
                                                              }
                                                            })
                                                          : () =>
                                                                _showUserDetailsDialog(
                                                                  user,
                                                                  adminProvider,
                                                                ),
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
        floatingActionButton: _isSelectionMode && _selectedUsers.isNotEmpty
            ? _buildBulkActionButtons()
            : null,
      ),
    );
  }

  List<UserModel> _filterAndSort(List<UserModel> users) {
    return users.where((user) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final matchesSearch =
            user.fullName.toLowerCase().contains(searchLower) ||
            user.email.toLowerCase().contains(searchLower) ||
            (user.studentId?.toLowerCase().contains(searchLower) ?? false) ||
            (user.department?.toLowerCase().contains(searchLower) ?? false);
        if (!matchesSearch) return false;
      }

      // Role filter
      if (_roleFilter != 'all' && user.role != _roleFilter) {
        return false;
      }

      // Status filter
      if (_statusFilter != 'all') {
        if (_statusFilter == 'active' && !user.isActive) return false;
        if (_statusFilter == 'inactive' && user.isActive) return false;
        if (_statusFilter == 'blocked' && !user.isBlocked) return false;
        if (_statusFilter == 'unblocked' && user.isBlocked) return false;
      }

      // Approval filter
      if (_approvalFilter != 'all') {
        if (_approvalFilter == 'approved' && !user.isApproved) return false;
        if (_approvalFilter == 'pending' && !user.isPending) return false;
        if (_approvalFilter == 'rejected' && !user.isRejected) return false;
      }

      return true;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDesign.radius20),
        ),
      ),
      builder: (context) => _buildEnhancedFilterSection(),
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

  Widget _buildEnhancedEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDesign.spacing24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.adminPrimary.withOpacity(0.1),
                  AppColors.adminSecondary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 48,
              color: AppColors.adminPrimary,
            ),
          ),
          const SizedBox(height: AppDesign.spacing16),
          Text(
            'No users found',
            style: AppDesign.heading3.copyWith(color: const Color(0xFF374151)),
          ),
          const SizedBox(height: AppDesign.spacing8),
          Text(
            'Try adjusting your search or filters',
            style: AppDesign.bodyMedium.copyWith(
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedFilterSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppDesign.spacing16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDesign.radius20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                'Filters',
                style: AppDesign.heading3.copyWith(
                  color: const Color(0xFF111827),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _roleFilter = 'all';
                    _statusFilter = 'all';
                    _approvalFilter = 'all';
                  });
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Reset',
                  style: AppDesign.bodyMedium.copyWith(
                    color: AppColors.adminPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDesign.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role filters
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
                            Icons.person,
                            size: 16,
                            color: AppColors.adminPrimary,
                          ),
                          const SizedBox(width: AppDesign.spacing8),
                          Text(
                            'Role',
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
                            'role',
                            Icons.all_inclusive,
                          ),
                          _buildEnhancedFilterChip(
                            'Student',
                            'student',
                            'role',
                            Icons.school,
                          ),
                          _buildEnhancedFilterChip(
                            'Organizer',
                            'organizer',
                            'role',
                            Icons.event,
                          ),
                          _buildEnhancedFilterChip(
                            'Admin',
                            'admin',
                            'role',
                            Icons.admin_panel_settings,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDesign.spacing16),

                // Status filters
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
                            Icons.info,
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
                            'Active',
                            'active',
                            'status',
                            Icons.check_circle,
                          ),
                          _buildEnhancedFilterChip(
                            'Inactive',
                            'inactive',
                            'status',
                            Icons.cancel,
                          ),
                          _buildEnhancedFilterChip(
                            'Blocked',
                            'blocked',
                            'status',
                            Icons.block,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDesign.spacing16),

                // Approval filters
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
                            Icons.verified,
                            size: 16,
                            color: AppColors.adminPrimary,
                          ),
                          const SizedBox(width: AppDesign.spacing8),
                          Text(
                            'Approval Status',
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
                            'approval',
                            Icons.all_inclusive,
                          ),
                          _buildEnhancedFilterChip(
                            'Approved',
                            'approved',
                            'approval',
                            Icons.verified,
                          ),
                          _buildEnhancedFilterChip(
                            'Pending',
                            'pending',
                            'approval',
                            Icons.schedule,
                          ),
                          _buildEnhancedFilterChip(
                            'Rejected',
                            'rejected',
                            'approval',
                            Icons.close,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDesign.spacing24),

                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.adminPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDesign.spacing16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDesign.radius12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Apply Filters',
                      style: AppDesign.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedFilterChip(
    String label,
    String value,
    String type,
    IconData icon,
  ) {
    final isSelected = _getCurrentFilterValue(type) == value;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : AppColors.adminPrimary,
          ),
          const SizedBox(width: AppDesign.spacing4),
          Text(
            label,
            style: AppDesign.bodySmall.copyWith(
              color: isSelected ? Colors.white : const Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _setFilterValue(type, selected ? value : 'all');
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.adminPrimary,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.radius8),
        side: BorderSide(
          color: isSelected ? AppColors.adminPrimary : AppColors.cardBorder,
          width: 1,
        ),
      ),
      elevation: isSelected ? 2 : 0,
      shadowColor: AppColors.adminPrimary.withOpacity(0.3),
    );
  }

  String _getCurrentFilterValue(String type) {
    switch (type) {
      case 'role':
        return _roleFilter;
      case 'status':
        return _statusFilter;
      case 'approval':
        return _approvalFilter;
      default:
        return 'all';
    }
  }

  void _setFilterValue(String type, String value) {
    switch (type) {
      case 'role':
        _roleFilter = value;
        break;
      case 'status':
        _statusFilter = value;
        break;
      case 'approval':
        _approvalFilter = value;
        break;
    }
  }

  Widget _buildBulkActionButtons() {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDesign.radius16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: () => _showBulkActionDialog('approve'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            label: Text('Approve (${_selectedUsers.length})'),
            icon: const Icon(Icons.check),
          ),
          const SizedBox(width: AppDesign.spacing12),
          FloatingActionButton.extended(
            onPressed: () => _showBulkActionDialog('reject'),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            label: Text('Reject (${_selectedUsers.length})'),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  void _showBulkActionDialog(String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm $action'),
        content: Text(
          'Are you sure you want to $action ${_selectedUsers.length} selected users?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _performBulkAction(action);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'approve' ? Colors.green : Colors.red,
            ),
            child: Text(action.toUpperCase()),
          ),
        ],
      ),
    );
  }

  void _performBulkAction(String action) {
    // TODO: Implement bulk actions
    setState(() {
      _selectedUsers.clear();
      _isSelectionMode = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Bulk $action completed')));
  }

  void _showUserDetailsDialog(UserModel user, AdminProvider adminProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getRoleIcon(user.role), color: _getRoleColor(user.role)),
            const SizedBox(width: AppDesign.spacing8),
            Expanded(
              child: Text(
                user.fullName,
                style: AppDesign.heading3,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Role', _getRoleDisplayText(user.role)),
              if (user.studentId != null)
                _buildDetailRow('Student ID', user.studentId!),
              if (user.department != null)
                _buildDetailRow('Department', user.department!),
              if (user.phoneNumber != null)
                _buildDetailRow('Phone', user.phoneNumber!),
              _buildDetailRow('Status', user.isActive ? 'Active' : 'Inactive'),
              _buildDetailRow(
                'Approval Status',
                _getApprovalStatusText(user.approvalStatus),
              ),
              if (user.isBlocked) _buildDetailRow('Blocked', 'Yes'),
              _buildDetailRow(
                'Created',
                '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (user.isPending) ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _rejectUser(user, adminProvider);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reject'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _approveUser(user, adminProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve'),
            ),
          ] else if (!user.isBlocked) ...[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _blockUser(user, adminProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Block'),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _unblockUser(user, adminProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Unblock'),
            ),
          ],
        ],
      ),
    );
  }

  // Helpers for role/states used in dialog header
  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'organizer':
        return Icons.event;
      case 'student':
        return Icons.school;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'organizer':
        return Colors.blue;
      case 'student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayText(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'organizer':
        return 'Event Organizer';
      case 'student':
        return 'Student';
      default:
        return role;
    }
  }

  String _getApprovalStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesign.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppDesign.bodySmall.copyWith(
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppDesign.bodySmall.copyWith(
                color: const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _approveUser(UserModel user, AdminProvider adminProvider) async {
    try {
      await adminProvider.approveUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.fullName} has been approved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _rejectUser(UserModel user, AdminProvider adminProvider) async {
    try {
      await adminProvider.rejectUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.fullName} has been rejected'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _blockUser(UserModel user, AdminProvider adminProvider) async {
    try {
      await adminProvider.blockUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.fullName} has been blocked'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error blocking user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _unblockUser(UserModel user, AdminProvider adminProvider) async {
    try {
      await adminProvider.unblockUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.fullName} has been unblocked'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error unblocking user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
