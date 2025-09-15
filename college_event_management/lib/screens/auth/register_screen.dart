import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../services/student_service.dart';
import '../../services/email_service.dart';
import '../../models/student_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  String _selectedRole = 'student';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSearchingStudent = false;
  bool _isEmailVerificationSent = false;
  bool _isVerifyingEmail = false;
  StudentModel? _foundStudent;
  final StudentService _studentService = StudentService();
  final EmailService _emailService = EmailService.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _studentIdController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  Future<void> _searchStudentByStudentId(String studentId) async {
    if (studentId.isEmpty) {
      setState(() {
        _foundStudent = null;
        _isSearchingStudent = false;
      });
      return;
    }

    setState(() {
      _isSearchingStudent = true;
    });

    try {
      StudentModel? student = await _studentService.getStudentByStudentId(
        studentId,
      );

      if (student != null) {
        setState(() {
          _foundStudent = student;
          _fullNameController.text = student.fullName;
          _emailController.text = student.email;
          _phoneController.text = student.phoneNumber;
        });
      } else {
        setState(() {
          _foundStudent = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Student not found with this ID. Please check and try again.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching for student: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingStudent = false;
        });
      }
    }
  }

  Future<void> _sendVerificationCode() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your email address before sending verification code',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isVerifyingEmail = true;
    });

    try {
      await _emailService.sendVerificationCode(_emailController.text.trim());
      setState(() {
        _isEmailVerificationSent = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Verification code has been sent to your email. Please check your inbox.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending verification code: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingEmail = false;
        });
      }
    }
  }

  Future<bool> _verifyEmailCode() async {
    if (_verificationCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter verification code'),
          backgroundColor: AppColors.warning,
        ),
      );
      return false;
    }

    try {
      bool isValid = await _emailService.verifyCode(
        _emailController.text.trim(),
        _verificationCodeController.text.trim(),
      );

      if (isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email has been verified successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        return true;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification code is incorrect or has expired'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return false;
    }
  }

  void _showApprovalPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.pending_actions, color: AppColors.warning, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Account Pending Approval',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your account has been created successfully!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              const Text(
                'However, your account needs to be approved by an administrator before you can use it.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Please contact the administrator to activate your account.',
                        style: TextStyle(
                          fontSize: 13,
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Understood',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      // Check email verification before registration
      if (!_isEmailVerificationSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please verify your email before registering'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      // Verify email code
      bool isEmailVerified = await _verifyEmailCode();
      if (!isEmailVerified) {
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      bool success = await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        studentId: _selectedRole == 'student'
            ? _studentIdController.text.trim()
            : null,
        department: _selectedRole == 'student' && _foundStudent != null
            ? _foundStudent!.department
            : null,
        role: _selectedRole,
      );

      if (success && mounted) {
        // Clear form
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _fullNameController.clear();
        _phoneController.clear();
        _studentIdController.clear();
        _foundStudent = null;

        // Show approval pending dialog
        _showApprovalPendingDialog();

        // Navigate to login
        context.go('/login');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Sign up failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [AppColors.adminPrimary, AppColors.adminSecondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: BoxDecoration(gradient: gradient),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bottomInset = MediaQuery.of(context).viewInsets.bottom;
                final bool isCompact = constraints.maxHeight < 700;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Container(
                        decoration: const BoxDecoration(color: AppColors.white),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(bottom: bottomInset + 16),
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: isCompact ? 12 : 20,
                                ),
                                decoration: BoxDecoration(
                                  gradient: gradient,
                                  borderRadius: BorderRadius.zero,
                                ),
                                child: Column(
                                  children: [
                                    const _HeaderBackButton(to: '/login'),
                                    const SizedBox(height: 6),
                                    _AppLogo(size: isCompact ? 48 : 60),
                                    const SizedBox(height: 6),
                                    Text(
                                      'FusionFiesta',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isCompact ? 20 : 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Create your account',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: isCompact ? 11 : 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Tabs
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  12,
                                  20,
                                  0,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.hoverBackground,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _SegmentButton(
                                          label: 'Sign In',
                                          selected: false,
                                          onTap: () => context.go('/login'),
                                        ),
                                      ),
                                      Expanded(
                                        child: _SegmentButton(
                                          label: 'Sign Up',
                                          selected: true,
                                          onTap: () {},
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Form
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  12,
                                  20,
                                  16,
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      CustomTextField(
                                        controller: _fullNameController,
                                        label: 'Full name *',
                                        hint: 'Enter your full name',
                                        prefixIcon: Icons.person_outlined,
                                        readOnly:
                                            _selectedRole == 'student' &&
                                            _foundStudent != null,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      CustomTextField(
                                        controller: _emailController,
                                        label: 'Email *',
                                        hint: 'Enter your email',
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        prefixIcon: Icons.email_outlined,
                                        readOnly:
                                            _selectedRole == 'student' &&
                                            _foundStudent != null,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your email address';
                                          }
                                          if (!RegExp(
                                            r'^[^@]+@[^@]+\.[^@]+',
                                          ).hasMatch(value)) {
                                            return 'Please enter a valid email address';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      CustomTextField(
                                        controller: _phoneController,
                                        label: 'Phone number',
                                        hint: 'Enter phone (optional)',
                                        keyboardType: TextInputType.phone,
                                        prefixIcon: Icons.phone_outlined,
                                        readOnly:
                                            _selectedRole == 'student' &&
                                            _foundStudent != null,
                                      ),
                                      const SizedBox(height: 12),
                                      // Email verification section
                                      if (!_isEmailVerificationSent) ...[
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: _isVerifyingEmail
                                                    ? null
                                                    : _sendVerificationCode,
                                                icon: _isVerifyingEmail
                                                    ? const SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                Color
                                                              >(Colors.white),
                                                        ),
                                                      )
                                                    : const Icon(
                                                        Icons.email_outlined,
                                                      ),
                                                label: Text(
                                                  _isVerifyingEmail
                                                      ? 'Sending...'
                                                      : 'Send Verification Code',
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.primary,
                                                  foregroundColor: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                      ] else ...[
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.success
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: AppColors.success
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: AppColors.success,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              const Expanded(
                                                child: Text(
                                                  'Verification code has been sent. Please check your email and enter the code below.',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        CustomTextField(
                                          controller:
                                              _verificationCodeController,
                                          label: 'Verification Code *',
                                          hint: 'Enter 6-digit code from email',
                                          keyboardType: TextInputType.number,
                                          prefixIcon: Icons.security,
                                          maxLines: 1,
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      if (_selectedRole == 'student') ...[
                                        const Text(
                                          'Enter student ID and click search to auto-fill information',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        CustomTextField(
                                          controller: _studentIdController,
                                          label: 'Student ID *',
                                          hint:
                                              'Enter your student ID and click search',
                                          prefixIcon: Icons.badge_outlined,
                                          suffixIcon: _isSearchingStudent
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: Padding(
                                                    padding: EdgeInsets.all(
                                                      12.0,
                                                    ),
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(AppColors.primary),
                                                    ),
                                                  ),
                                                )
                                              : IconButton(
                                                  icon: const Icon(
                                                    Icons.search,
                                                  ),
                                                  tooltip: 'Search student',
                                                  onPressed: () {
                                                    if (_studentIdController
                                                        .text
                                                        .trim()
                                                        .isNotEmpty) {
                                                      _searchStudentByStudentId(
                                                        _studentIdController
                                                            .text
                                                            .trim(),
                                                      );
                                                    } else {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Please enter student ID before searching',
                                                          ),
                                                          backgroundColor:
                                                              AppColors.warning,
                                                        ),
                                                      );
                                                    }
                                                  },
                                                ),
                                          onChanged: (value) {
                                            if (value.isEmpty) {
                                              setState(() {
                                                _foundStudent = null;
                                                _fullNameController.clear();
                                                _emailController.clear();
                                                _phoneController.clear();
                                              });
                                            }
                                          },
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Student ID is required for students';
                                            }
                                            if (_foundStudent == null) {
                                              return 'Please enter a valid student ID';
                                            }
                                            return null;
                                          },
                                        ),
                                        if (_foundStudent != null) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppColors.success
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: AppColors.success
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.check_circle,
                                                  color: AppColors.success,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Student found: ${_foundStudent!.fullName}',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Role *',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: AppColors.grey,
                                          ),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _selectedRole,
                                            isExpanded: true,
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'student',
                                                child: Text('Student'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'organizer',
                                                child: Text('Organizer'),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedRole = value!;
                                                if (value != 'student') {
                                                  _foundStudent = null;
                                                  _fullNameController.clear();
                                                  _emailController.clear();
                                                  _phoneController.clear();
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      CustomTextField(
                                        controller: _passwordController,
                                        label: 'Password *',
                                        hint: 'Enter your password',
                                        obscureText: _obscurePassword,
                                        prefixIcon: Icons.lock_outlined,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter password';
                                          }
                                          if (value.length < 6) {
                                            return 'Password must be at least 6 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      CustomTextField(
                                        controller: _confirmPasswordController,
                                        label: 'Confirm password *',
                                        hint: 'Re-enter your password',
                                        obscureText: _obscureConfirmPassword,
                                        prefixIcon: Icons.lock_outlined,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureConfirmPassword =
                                                  !_obscureConfirmPassword;
                                            });
                                          },
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please confirm password';
                                          }
                                          if (value !=
                                              _passwordController.text) {
                                            return 'Passwords do not match';
                                          }
                                          return null;
                                        },
                                      ),

                                      const SizedBox(height: 20),
                                      Consumer<AuthProvider>(
                                        builder: (context, authProvider, _) {
                                          return CustomButton(
                                            text: 'Sign Up',
                                            onPressed: authProvider.isLoading
                                                ? null
                                                : _register,
                                            isLoading: authProvider.isLoading,
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Already have an account? ',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                context.go('/login'),
                                            child: const Text(
                                              'Sign in',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderBackButton extends StatelessWidget {
  final String to;
  const _HeaderBackButton({this.to = '/home'});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: () => context.go(to),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  final double size;
  const _AppLogo({this.size = 60});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(Icons.person_add_alt_1, color: Colors.white, size: 28),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.adminPrimary : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
