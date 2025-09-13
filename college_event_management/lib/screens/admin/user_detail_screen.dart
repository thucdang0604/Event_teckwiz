import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';

class UserDetailScreen extends StatefulWidget {
  final UserModel user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    _selectedStatus = _getCurrentStatus();
  }

  String _getCurrentStatus() {
    if (widget.user.isBlocked) return 'blocked';
    if (!widget.user.isApproved) return 'pending';
    if (!widget.user.isActive) return 'inactive';
    return 'active';
  }

  Future<void> _updateUserStatus() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Cập nhật theo trạng thái được chọn
      switch (_selectedStatus) {
        case 'active':
          await _authService.approveUser(widget.user.id);
          await _authService.updateUserActiveStatus(widget.user.id, true);
          await _authService.unblockUser(widget.user.id);
          break;
        case 'pending':
          await _authService.rejectUser(widget.user.id);
          await _authService.updateUserActiveStatus(widget.user.id, true);
          await _authService.unblockUser(widget.user.id);
          break;
        case 'inactive':
          await _authService.approveUser(widget.user.id);
          await _authService.updateUserActiveStatus(widget.user.id, false);
          await _authService.unblockUser(widget.user.id);
          break;
        case 'blocked':
          await _authService.approveUser(widget.user.id);
          await _authService.updateUserActiveStatus(widget.user.id, true);
          await _authService.blockUser(widget.user.id);
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Account Details',
          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin cơ bản
            _buildUserInfoCard(),

            const SizedBox(height: 16),

            // Trạng thái hiện tại
            _buildStatusCard(),

            const SizedBox(height: 16),

            // Thay đổi trạng thái
            _buildStatusChangeCard(),

            const SizedBox(height: 24),

            // Nút cập nhật
            CustomButton(
              text: _isLoading ? 'Updating...' : 'Update Status',
              onPressed: _isLoading ? null : _updateUserStatus,
              backgroundColor: AppColors.primary,
              textColor: AppColors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    widget.user.fullName.isNotEmpty
                        ? widget.user.fullName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.user.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Role: ${_getRoleDisplayName(widget.user.role)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (widget.user.phoneNumber != null) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.phone,
                'Phone Number',
                widget.user.phoneNumber!,
              ),
            ],

            if (widget.user.studentId != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.badge, 'Student ID', widget.user.studentId!),
            ],

            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time,
              'Created Date',
              _formatDate(widget.user.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Trạng thái tổng hợp
            _buildStatusItem(
              'Account Status',
              _getStatusDisplay(_getCurrentStatus()),
              _getStatusColor(_getCurrentStatus()),
              _getStatusIcon(_getCurrentStatus()),
            ),

            const SizedBox(height: 12),

            // Chi tiết trạng thái
            _buildStatusDetail(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDetail() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            'Approval',
            widget.user.isApproved ? 'Approved' : 'Pending',
          ),
          _buildDetailRow(
            'Active',
            widget.user.isActive ? 'Active' : 'Inactive',
          ),
          _buildDetailRow(
            'Blocked',
            widget.user.isBlocked ? 'Blocked' : 'Not Blocked',
          ),
          _buildDetailRow(
            'Login',
            widget.user.canLogin ? 'Can Login' : 'Cannot Login',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChangeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Status Dropdown
            _buildDropdown(
              'Account Status',
              _selectedStatus,
              [
                {
                  'value': 'active',
                  'label': 'Active (Approved + Active + Not Blocked)',
                },
                {
                  'value': 'pending',
                  'label': 'Pending (Not Approved + Active + Not Blocked)',
                },
                {
                  'value': 'inactive',
                  'label': 'Inactive (Approved + Inactive + Not Blocked)',
                },
                {
                  'value': 'blocked',
                  'label': 'Blocked (Approved + Active + Blocked)',
                },
              ],
              (value) => setState(() => _selectedStatus = value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<Map<String, String>> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item['value'],
                  child: Text(
                    item['label']!,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
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

  String _getStatusDisplay(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'pending':
        return 'Pending';
      case 'inactive':
        return 'Inactive';
      case 'blocked':
        return 'Blocked';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'inactive':
        return AppColors.error;
      case 'blocked':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'inactive':
        return Icons.pause_circle;
      case 'blocked':
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
