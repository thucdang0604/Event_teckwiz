import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../providers/auth_provider.dart';

// Error types for better error handling
enum LoginErrorType {
  invalidCredentials,
  accountBlocked,
  accountNotApproved,
  networkError,
  unknownError,
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _currentErrorMessage;
  LoginErrorType? _currentErrorType;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _currentErrorMessage = null;
        _currentErrorType = null;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        bool success = await authProvider.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (success && authProvider.isAuthenticated) {
            _clearForm();
            _showSuccessMessage();

            final user = authProvider.currentUser;
            if (user != null) {
              _navigateToAppropriateScreen(user);
            }
          } else {
            _handleLoginFailure(authProvider.errorMessage);
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _handleLoginException(e.toString());
        }
      }
    }
  }

  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      _currentErrorMessage = null;
      _currentErrorType = null;
    });
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Successfully signed in!'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToAppropriateScreen(dynamic user) {
    if (user.role == 'admin') {
      context.go('/admin-dashboard');
    } else if (user.isStudent) {
      context.go('/student');
    } else {
      context.go('/home');
    }
  }

  void _handleLoginFailure(String? errorMessage) {
    final errorType = _determineErrorType(errorMessage ?? '');
    setState(() {
      _currentErrorMessage = _getErrorMessage(errorType);
      _currentErrorType = errorType;
    });

    if (errorType == LoginErrorType.accountBlocked) {
      _showBlockedUserDialog();
    } else if (errorType == LoginErrorType.accountNotApproved) {
      _showAccountNotApprovedDialog();
    }
  }

  void _handleLoginException(String errorString) {
    final errorType = _determineErrorType(errorString);
    setState(() {
      _currentErrorMessage = _getErrorMessage(errorType);
      _currentErrorType = errorType;
    });

    if (errorType == LoginErrorType.accountBlocked) {
      _showBlockedUserDialog();
    } else if (errorType == LoginErrorType.accountNotApproved) {
      _showAccountNotApprovedDialog();
    }
  }

  LoginErrorType _determineErrorType(String errorMessage) {
    final message = errorMessage.toLowerCase();

    if (message.contains('blocked') || message.contains('block')) {
      return LoginErrorType.accountBlocked;
    } else if (message.contains('not approved') ||
        message.contains('pending') ||
        message.contains('chưa được duyệt') ||
        message.contains('not verified')) {
      return LoginErrorType.accountNotApproved;
    } else if (message.contains('invalid') ||
        message.contains('wrong') ||
        message.contains('incorrect') ||
        message.contains('credentials')) {
      return LoginErrorType.invalidCredentials;
    } else if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout')) {
      return LoginErrorType.networkError;
    } else {
      return LoginErrorType.unknownError;
    }
  }

  String _getErrorMessage(LoginErrorType errorType) {
    switch (errorType) {
      case LoginErrorType.invalidCredentials:
        return 'Invalid email or password. Please check your credentials and try again.';
      case LoginErrorType.accountBlocked:
        return 'Your account has been blocked. Please contact administrator.';
      case LoginErrorType.accountNotApproved:
        return 'Your account is pending approval. Please contact administrator.';
      case LoginErrorType.networkError:
        return 'Network error. Please check your connection and try again.';
      case LoginErrorType.unknownError:
        return 'An error occurred during sign in. Please try again later.';
    }
  }

  void _goToRegister() {
    context.go('/register');
  }

  void _showBlockedUserDialog() {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.block, color: AppColors.error, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Account Blocked',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your account has been blocked by the administrator.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This action may be due to violation of terms of service or security concerns. Please contact the administrator immediately to resolve this issue.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.contact_support_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Email: admin@fusionfiesta.com',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Phone: +1 (555) 123-4567',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // You can add logic to open email app here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Contact Admin',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAccountNotApprovedDialog() {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.pending_actions,
                  color: AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Account Pending Approval',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your account registration is pending administrator approval.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This process typically takes 1-2 business days. You will receive a notification once your account is approved. For urgent matters, please contact the administrator.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.contact_support_rounded,
                          color: AppColors.warning,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Email: admin@fusionfiesta.com',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Phone: +1 (555) 123-4567',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // You can add logic to open email app here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Contact Admin',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
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
                                    const _HeaderBackButton(),
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
                                      'University Event Management System',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: isCompact ? 11 : 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      textAlign: TextAlign.center,
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
                                          selected: true,
                                          onTap: () {},
                                        ),
                                      ),
                                      Expanded(
                                        child: _SegmentButton(
                                          label: 'Sign Up',
                                          selected: false,
                                          onTap: _goToRegister,
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
                                        controller: _emailController,
                                        label: 'Email Address',
                                        hint: 'Enter your email address',
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        prefixIcon: Icons.email_outlined,
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
                                        controller: _passwordController,
                                        label: 'Password',
                                        hint: 'Enter your password',
                                        obscureText: _obscurePassword,
                                        prefixIcon: Icons.lock_outline,
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: AppColors.textHint,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your password';
                                          }
                                          if (value.length < 6) {
                                            return 'Password must be at least 6 characters';
                                          }
                                          return null;
                                        },
                                      ),

                                      // Error message display
                                      if (_currentErrorMessage != null)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            top: 12,
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color:
                                                _currentErrorType ==
                                                    LoginErrorType
                                                        .accountBlocked
                                                ? AppColors.error.withOpacity(
                                                    0.1,
                                                  )
                                                : _currentErrorType ==
                                                      LoginErrorType
                                                          .accountNotApproved
                                                ? AppColors.warning.withOpacity(
                                                    0.1,
                                                  )
                                                : AppColors.error.withOpacity(
                                                    0.1,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color:
                                                  _currentErrorType ==
                                                      LoginErrorType
                                                          .accountBlocked
                                                  ? AppColors.error.withOpacity(
                                                      0.3,
                                                    )
                                                  : _currentErrorType ==
                                                        LoginErrorType
                                                            .accountNotApproved
                                                  ? AppColors.warning
                                                        .withOpacity(0.3)
                                                  : AppColors.error.withOpacity(
                                                      0.3,
                                                    ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                _currentErrorType ==
                                                        LoginErrorType
                                                            .accountBlocked
                                                    ? Icons.block
                                                    : _currentErrorType ==
                                                          LoginErrorType
                                                              .accountNotApproved
                                                    ? Icons.pending_actions
                                                    : Icons.error_outline,
                                                color:
                                                    _currentErrorType ==
                                                        LoginErrorType
                                                            .accountBlocked
                                                    ? AppColors.error
                                                    : _currentErrorType ==
                                                          LoginErrorType
                                                              .accountNotApproved
                                                    ? AppColors.warning
                                                    : AppColors.error,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _currentErrorMessage!,
                                                  style: TextStyle(
                                                    color:
                                                        _currentErrorType ==
                                                            LoginErrorType
                                                                .accountBlocked
                                                        ? AppColors.error
                                                        : _currentErrorType ==
                                                              LoginErrorType
                                                                  .accountNotApproved
                                                        ? AppColors.warning
                                                        : AppColors.error,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _rememberMe,
                                            onChanged: (v) {
                                              setState(
                                                () => _rememberMe = v ?? false,
                                              );
                                            },
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'Remember Me',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 8),
                                      CustomButton(
                                        text: 'Sign In',
                                        onPressed: _isLoading ? null : _login,
                                        isLoading: _isLoading,
                                      ),

                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () {
                                            // TODO: Navigate to forgot password screen
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Forgot password feature coming soon',
                                                ),
                                              ),
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                          ),
                                          child: const Text(
                                            'Forgot Password?',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 20),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceVariant,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: AppColors.cardBorder,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              "Don't have an account? ",
                                              style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 15,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: _goToRegister,
                                              child: Text(
                                                'Create Account',
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 6),
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
  const _HeaderBackButton();
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: () => context.go('/home'),
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
        child: Icon(Icons.calendar_month, color: Colors.white, size: 28),
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
