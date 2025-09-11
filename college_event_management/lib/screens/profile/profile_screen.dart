import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_colors.dart';
import 'edit_profile_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;

        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Không có thông tin người dùng')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Hồ sơ'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/home'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            user.fullName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor(user.role).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getRoleText(user.role),
                            style: TextStyle(
                              color: _getRoleColor(user.role),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // User Information
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Thông tin cá nhân',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const Divider(height: 1, thickness: 0.6),
                        _buildInfoTile(
                          icon: Icons.person_outline,
                          label: 'Họ và tên',
                          value: user.fullName,
                        ),
                        const Divider(height: 1, thickness: 0.6),
                        _buildInfoTile(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: user.email,
                        ),
                        const Divider(height: 1, thickness: 0.6),
                        _buildInfoTile(
                          icon: Icons.phone_outlined,
                          label: 'Số điện thoại',
                          value: user.phoneNumber ?? 'Chưa cập nhật',
                        ),
                        if (user.isStudent) ...[
                          const Divider(height: 1, thickness: 0.6),
                          _buildInfoTile(
                            icon: Icons.badge_outlined,
                            label: 'Mã sinh viên',
                            value: user.studentId ?? 'Chưa cập nhật',
                          ),
                        ],
                        const Divider(height: 1, thickness: 0.6),
                        _buildInfoTile(
                          icon: Icons.verified_user_outlined,
                          label: 'Vai trò',
                          value: _getRoleText(user.role),
                        ),
                        const Divider(height: 1, thickness: 0.6),
                        _buildInfoTile(
                          icon: Icons.event_note_outlined,
                          label: 'Ngày tạo',
                          value: _formatDate(user.createdAt),
                        ),
                        const Divider(height: 1, thickness: 0.6),
                        _buildInfoTile(
                          icon: Icons.update,
                          label: 'Cập nhật lần cuối',
                          value: _formatDate(user.updatedAt),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.edit,
                          color: AppColors.primary,
                        ),
                        title: const Text('Chỉnh sửa hồ sơ'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.settings,
                          color: AppColors.primary,
                        ),
                        title: const Text('Cài đặt'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.help,
                          color: AppColors.primary,
                        ),
                        title: const Text('Trợ giúp'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tính năng đang phát triển'),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.info,
                          color: AppColors.primary,
                        ),
                        title: const Text('Về ứng dụng'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          _showAboutDialog(context);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await authProvider.signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Đăng xuất'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  // Removed legacy row-based info builder in favor of tile-based UI

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.error;
      case 'organizer':
        return AppColors.warning;
      case 'student':
        return AppColors.success;
      default:
        return AppColors.grey;
    }
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
        return 'Người dùng';
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Quản Lý Sự Kiện',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.event,
        size: 48,
        color: AppColors.primary,
      ),
      children: [
        const Text('Ứng dụng quản lý sự kiện trường đại học'),
        const SizedBox(height: 16),
        const Text('Phát triển bởi: Flutter + Firebase'),
        const Text('Phiên bản: 1.0.0'),
      ],
    );
  }
}
