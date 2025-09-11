import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/image_service.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _departmentController = TextEditingController();

  String _selectedRole = 'student';
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedAvatar;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      _fullNameController.text = user.fullName;
      _phoneNumberController.text = user.phoneNumber ?? '';
      _studentIdController.text = user.studentId ?? '';
      _departmentController.text = user.department ?? '';
      _selectedRole = user.role;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _studentIdController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser != null) {
        String? avatarUrl = currentUser.profileImageUrl;
        if (_selectedAvatar != null) {
          final imageService = ImageService();
          avatarUrl = await imageService.uploadImage(_selectedAvatar!);
        }
        final updatedUser = UserModel(
          id: currentUser.id,
          fullName: _fullNameController.text.trim(),
          email: currentUser.email,
          phoneNumber: _phoneNumberController.text.trim(),
          studentId: _studentIdController.text.trim(),
          department: _departmentController.text.trim(),
          role: _selectedRole,
          profileImageUrl: avatarUrl,
          createdAt: currentUser.createdAt,
          updatedAt: DateTime.now(),
        );

        await authProvider.updateUser(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật hồ sơ thành công'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật hồ sơ: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Lưu',
              style: TextStyle(
                color: _isLoading ? AppColors.grey : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: _selectedAvatar != null
                          ? FileImage(_selectedAvatar!)
                          : (Provider.of<AuthProvider>(
                                      context,
                                      listen: false,
                                    ).currentUser?.profileImageUrl !=
                                    null
                                ? NetworkImage(
                                    Provider.of<AuthProvider>(
                                      context,
                                      listen: false,
                                    ).currentUser!.profileImageUrl!,
                                  )
                                : null),
                      child:
                          _selectedAvatar == null &&
                              (Provider.of<AuthProvider>(
                                    context,
                                    listen: false,
                                  ).currentUser?.profileImageUrl ==
                                  null)
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () async {
                            final picked = await _imagePicker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1024,
                              imageQuality: 85,
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedAvatar = File(picked.path);
                              });
                            }
                          },
                          icon: const Icon(
                            Icons.camera_alt,
                            color: AppColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Personal Information
              const Text(
                'Thông tin cá nhân',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _fullNameController,
                label: 'Họ và tên',
                hint: 'Nhập họ và tên',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: _phoneNumberController,
                label: 'Số điện thoại',
                hint: 'Nhập số điện thoại',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value.trim())) {
                      return 'Số điện thoại không hợp lệ';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: _studentIdController,
                label: 'Mã sinh viên',
                hint: 'Nhập mã sinh viên',
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (value.trim().length < 5) {
                      return 'Mã sinh viên phải có ít nhất 5 ký tự';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: _departmentController,
                label: 'Khoa/Bộ môn',
                hint: 'Nhập khoa/bộ môn',
              ),

              const SizedBox(height: 24),

              // Role Selection
              const Text(
                'Vai trò',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'student',
                        child: Text('Sinh viên'),
                      ),
                      DropdownMenuItem(
                        value: 'organizer',
                        child: Text('Người tổ chức'),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('Quản trị viên'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              CustomButton(
                text: 'Lưu thay đổi',
                onPressed: _isLoading ? null : _saveProfile,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 16),

              // Cancel Button
              CustomButton(
                text: 'Hủy',
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                backgroundColor: AppColors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
