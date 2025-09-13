import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_design.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'user_detail_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AuthService _authService = AuthService();
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  String _searchQuery = '';
  int _currentIndex = 2;

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  Future<void> _loadAllUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _authService.getAllUsers();
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading list: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        // Filter by status
        bool statusMatch = true;
        switch (_selectedFilter) {
          case 'pending':
            statusMatch = user.approvalStatus == AppConstants.userPending;
            break;
          case 'approved':
            statusMatch = user.approvalStatus == AppConstants.userApproved;
            break;
          case 'rejected':
            statusMatch = user.approvalStatus == AppConstants.userRejected;
            break;
          case 'blocked':
            statusMatch = user.isBlocked;
            break;
          case 'all':
          default:
            statusMatch = true;
        }

        // Filter by search query
        bool searchMatch =
            _searchQuery.isEmpty ||
            user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (user.studentId?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false);

        return statusMatch && searchMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Account Management',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.25,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.adminPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/admin-dashboard'),
            tooltip: 'Back to Dashboard',
          ),
          actions: [
            IconButton(
              onPressed: _loadAllUsers,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Container(
          color: AppColors.surfaceVariant,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // Search and Filter
                  Container(
                    padding: EdgeInsets.all(
                      constraints.maxWidth > 600
                          ? AppDesign.spacing24
                          : AppDesign.spacing16,
                    ),
                    color: AppColors.white,
                    child: Column(
                      children: [
                        // Search bar
                        TextField(
                          decoration: AppDesign.textFieldDecoration(
                            hintText: 'Search by name, email, student ID...',
                            prefixIcon: const Icon(Icons.search),
                          ),
                          onChanged: (value) {
                            _searchQuery = value;
                            _filterUsers();
                          },
                        ),

                        const SizedBox(height: AppDesign.spacing16),

                        // Filter chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('All', 'all'),
                              const SizedBox(width: AppDesign.spacing8),
                              _buildFilterChip('Pending', 'pending'),
                              const SizedBox(width: AppDesign.spacing8),
                              _buildFilterChip('Approved', 'approved'),
                              const SizedBox(width: AppDesign.spacing8),
                              _buildFilterChip('Rejected', 'rejected'),
                              const SizedBox(width: AppDesign.spacing8),
                              _buildFilterChip('Blocked', 'blocked'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Users list
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF1E40AF),
                              ),
                            ),
                          )
                        : _filteredUsers.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadAllUsers,
                            color: AppColors.adminPrimary,
                            child: ListView.builder(
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
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                return _buildUserCard(user);
                              },
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.adminPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDesign.radius20),
            ),
            child: Icon(
              Icons.people_outline,
              size: 40,
              color: AppColors.adminPrimary,
            ),
          ),
          const SizedBox(height: AppDesign.spacing20),
          Text(
            'No accounts found',
            style: AppDesign.heading3.copyWith(color: const Color(0xFF111827)),
          ),
          const SizedBox(height: AppDesign.spacing8),
          Text(
            'Try adjusting your filters or refresh the list',
            style: AppDesign.bodyMedium.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: AppDesign.spacing24),
          ElevatedButton.icon(
            onPressed: _loadAllUsers,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: AppDesign.primaryButtonStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        _filterUsers();
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

  Widget _buildUserCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDesign.spacing12),
      decoration: AppDesign.cardDecoration,
      child: InkWell(
        onTap: () => _navigateToDetail(user),
        borderRadius: BorderRadius.circular(AppDesign.radius16),
        child: Padding(
          padding: const EdgeInsets.all(AppDesign.spacing16),
          child: Row(
            children: [
              // Avatar with better styling
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.adminPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDesign.radius16),
                ),
                child: Center(
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.adminPrimary,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppDesign.spacing16),

              // User information
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWideScreen = constraints.maxWidth > 400;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and role
                        if (isWideScreen)
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user.fullName,
                                  style: AppDesign.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF111827),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppDesign.spacing8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDesign.spacing8,
                                  vertical: AppDesign.spacing4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(
                                    user.role,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppDesign.radius12,
                                  ),
                                  border: Border.all(
                                    color: _getRoleColor(
                                      user.role,
                                    ).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _getRoleDisplayName(user.role),
                                  style: AppDesign.labelSmall.copyWith(
                                    color: _getRoleColor(user.role),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: AppDesign.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF111827),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppDesign.spacing4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDesign.spacing8,
                                  vertical: AppDesign.spacing4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(
                                    user.role,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppDesign.radius12,
                                  ),
                                  border: Border.all(
                                    color: _getRoleColor(
                                      user.role,
                                    ).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _getRoleDisplayName(user.role),
                                  style: AppDesign.labelSmall.copyWith(
                                    color: _getRoleColor(user.role),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: AppDesign.spacing8),

                        // Email
                        Text(
                          user.email,
                          style: AppDesign.bodyMedium.copyWith(
                            color: const Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        if (user.studentId?.isNotEmpty == true) ...[
                          const SizedBox(height: AppDesign.spacing4),
                          Text(
                            'ID: ${user.studentId}',
                            style: AppDesign.bodySmall.copyWith(
                              color: const Color(0xFF9CA3AF),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(width: AppDesign.spacing16),

              // Status indicators
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusChip(
                    _getApprovalStatusDisplay(user.approvalStatus),
                    _getApprovalStatusColor(user.approvalStatus),
                  ),
                  if (user.isBlocked) ...[
                    const SizedBox(height: AppDesign.spacing8),
                    _buildStatusChip('Blocked', AppColors.statusRejected),
                  ],
                  const SizedBox(height: AppDesign.spacing8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: const Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.statusRejected;
      case 'organizer':
        return AppColors.adminSecondary;
      case 'student':
        return AppColors.statusApproved;
      default:
        return AppColors.adminPrimary;
    }
  }

  void _navigateToDetail(UserModel user) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => UserDetailScreen(user: user)),
    );

    // Refresh list if there are changes
    if (result == true) {
      _loadAllUsers();
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'organizer':
        return 'Organizer';
      case 'student':
        return 'Student';
      default:
        return role;
    }
  }

  String _getApprovalStatusDisplay(String status) {
    switch (status) {
      case AppConstants.userPending:
        return 'Pending';
      case AppConstants.userApproved:
        return 'Approved';
      case AppConstants.userRejected:
        return 'Rejected';
      default:
        return status;
    }
  }

  Color _getApprovalStatusColor(String status) {
    switch (status) {
      case AppConstants.userPending:
        return AppColors.statusPending;
      case AppConstants.userApproved:
        return AppColors.statusApproved;
      case AppConstants.userRejected:
        return AppColors.statusRejected;
      default:
        return AppColors.textSecondary;
    }
  }
}
