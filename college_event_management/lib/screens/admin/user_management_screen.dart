import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/user_model.dart';
import '../../constants/app_colors.dart';
import '../../utils/navigation_helper.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _selectedRole = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin-dashboard'),
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<UserModel> filteredUsers = _filterUsers(adminProvider.users);

          return Column(
            children: [
              _buildFilters(),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _buildUserCard(user, adminProvider);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Tìm kiếm người dùng...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Vai trò: '),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedRole,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(
                      value: 'organizer',
                      child: Text('Organizer'),
                    ),
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user, AdminProvider adminProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.profileImageUrl != null
              ? NetworkImage(user.profileImageUrl!)
              : null,
          child: user.profileImageUrl == null
              ? Text(user.fullName[0].toUpperCase())
              : null,
        ),
        title: Text(user.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Text('Vai trò: ${_getRoleText(user.role)}'),
            if (user.studentId != null) Text('MSSV: ${user.studentId}'),
            if (user.department != null) Text('Khoa: ${user.department}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleUserAction(value, user, adminProvider),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle_status',
              child: Text(user.isActive ? 'Vô hiệu hóa' : 'Kích hoạt'),
            ),
            if (user.role != 'admin')
              PopupMenuItem(
                value: 'change_role',
                child: const Text('Thay đổi vai trò'),
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'admin':
        return 'Quản trị viên';
      case 'organizer':
        return 'Người tổ chức';
      case 'student':
        return 'Sinh viên';
      default:
        return role;
    }
  }

  void _handleUserAction(
    String action,
    UserModel user,
    AdminProvider adminProvider,
  ) {
    switch (action) {
      case 'toggle_status':
        adminProvider.updateUserStatus(user.id, !user.isActive);
        break;
      case 'change_role':
        _showRoleChangeDialog(user, adminProvider);
        break;
    }
  }

  void _showRoleChangeDialog(UserModel user, AdminProvider adminProvider) {
    String newRole = user.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thay đổi vai trò'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Người dùng: ${user.fullName}'),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: newRole,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'student', child: Text('Sinh viên')),
                  DropdownMenuItem(
                    value: 'organizer',
                    child: Text('Người tổ chức'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    newRole = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  safePop(context, fallbackRoute: '/admin-dashboard'),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                adminProvider.updateUserRole(user.id, newRole);
                safePop(context, fallbackRoute: '/admin-dashboard');
              },
              child: const Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    return users.where((user) {
      bool matchesRole = _selectedRole == 'all' || user.role == _selectedRole;
      bool matchesSearch =
          _searchQuery.isEmpty ||
          user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (user.studentId?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);

      return matchesRole && matchesSearch;
    }).toList();
  }
}
