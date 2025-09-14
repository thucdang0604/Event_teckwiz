import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'vi';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.person,
              title: 'Personal Information',
              subtitle: 'Edit account information',
              onTap: () {
                // TODO: Navigate to edit profile
              },
            ),
            _buildSettingsTile(
              icon: Icons.security,
              title: 'Bảo mật',
              subtitle: 'Mật khẩu và xác thực',
              onTap: () {
                // TODO: Navigate to security settings
              },
            ),
          ]),

          const SizedBox(height: 24),

          // App Settings Section
          _buildSectionHeader('Application'),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'View notification history',
              onTap: () {
                Navigator.of(context).pushNamed('/notifications');
              },
            ),
            _buildSwitchTile(
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              subtitle: 'Use dark interface',
              value: _darkModeEnabled,
              onChanged: (value) {
                setState(() {
                  _darkModeEnabled = value;
                });
              },
            ),
            _buildSettingsTile(
              icon: Icons.language,
              title: 'Language',
              subtitle: _getLanguageName(_selectedLanguage),
              onTap: () {
                _showLanguageDialog();
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Data Section
          _buildSectionHeader('Dữ liệu'),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.download,
              title: 'Tải dữ liệu',
              subtitle: 'Tải xuống dữ liệu cá nhân',
              onTap: () {
                _showDownloadDataDialog();
              },
            ),
            _buildSettingsTile(
              icon: Icons.delete,
              title: 'Xóa dữ liệu',
              subtitle: 'Xóa tất cả dữ liệu cá nhân',
              onTap: () {
                _showDeleteDataDialog();
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Support Section
          _buildSectionHeader('Hỗ trợ'),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.help,
              title: 'Trợ giúp',
              subtitle: 'Câu hỏi thường gặp và hướng dẫn',
              onTap: () {
                // TODO: Navigate to help
              },
            ),
            _buildSettingsTile(
              icon: Icons.feedback,
              title: 'Gửi phản hồi',
              subtitle: 'Góp ý và báo lỗi',
              onTap: () {
                _showFeedbackDialog();
              },
            ),
            _buildSettingsTile(
              icon: Icons.info,
              title: 'About App',
              subtitle: 'Version 1.0.0',
              onTap: () {
                _showAboutDialog();
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Logout Button
          CustomButton(
            text: 'Đăng xuất',
            onPressed: () {
              _showLogoutDialog();
            },
            backgroundColor: AppColors.error,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(child: Column(children: children));
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn ngôn ngữ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Tiếng Việt'),
              value: 'vi',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDownloadDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tải dữ liệu'),
        content: const Text(
          'Bạn có muốn tải xuống tất cả dữ liệu cá nhân của mình?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang được phát triển')),
              );
            },
            child: const Text('Tải xuống'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa dữ liệu'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa tất cả dữ liệu cá nhân? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang được phát triển')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gửi phản hồi'),
        content: TextField(
          controller: feedbackController,
          decoration: const InputDecoration(
            hintText: 'Nhập phản hồi của bạn...',
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cảm ơn bạn đã gửi phản hồi!')),
              );
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'College Event Management',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.event,
        size: 64,
        color: AppColors.primary,
      ),
      children: [
        const Text('Ứng dụng quản lý sự kiện trường đại học'),
        const SizedBox(height: 16),
        const Text('Phát triển bởi: TechWiz Team'),
        const SizedBox(height: 8),
        const Text('© 2024 All rights reserved'),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'vi':
        return 'Tiếng Việt';
      case 'en':
        return 'English';
      default:
        return 'Tiếng Việt';
    }
  }
}
