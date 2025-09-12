import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../providers/auth_provider.dart';

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
            _emailController.clear();
            _passwordController.clear();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Signed in successfully'),
                backgroundColor: AppColors.success,
              ),
            );

            final user = authProvider.currentUser;
            if (user != null && user.isStudent) {
              context.go('/student');
            } else {
              context.go('/home');
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authProvider.errorMessage ?? 'Sign in failed'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign in error: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _goToRegister() {
    context.go('/register');
  }

  // demo and test admin helpers removed per UI cleanup

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
                                    color: const Color(0xFFF3F4F6),
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
                                        label: 'Email',
                                        hint: 'Enter your email',
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        prefixIcon: Icons.email_outlined,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter email';
                                          }
                                          if (!value.contains('@')) {
                                            return 'Invalid email address';
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
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                          ),
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
                                          const Expanded(
                                            child: Text(
                                              'Remember me for 30 days',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            fit: FlexFit.loose,
                                            child: TextButton(
                                              onPressed: _isLoading
                                                  ? null
                                                  : () async {
                                                      if (_emailController
                                                          .text
                                                          .isEmpty) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Enter email to reset password',
                                                            ),
                                                          ),
                                                        );
                                                        return;
                                                      }
                                                      final provider =
                                                          Provider.of<
                                                            AuthProvider
                                                          >(
                                                            context,
                                                            listen: false,
                                                          );
                                                      await provider
                                                          .resetPassword(
                                                            _emailController
                                                                .text
                                                                .trim(),
                                                          );
                                                      if (!mounted) return;
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Password reset link sent',
                                                          ),
                                                        ),
                                                      );
                                                    },
                                              child: const Text(
                                                'Forgot password?',
                                                overflow: TextOverflow.ellipsis,
                                              ),
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

                                      const SizedBox(height: 12),
                                      Row(
                                        children: const [
                                          Expanded(child: Divider()),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Text(
                                              'or continue with',
                                              style: TextStyle(
                                                color: Color(0xFF9CA3AF),
                                              ),
                                            ),
                                          ),
                                          Expanded(child: Divider()),
                                        ],
                                      ),

                                      const SizedBox(height: 12),
                                      OutlinedButton.icon(
                                        onPressed: _isLoading
                                            ? null
                                            : () {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Google Sign-In not configured',
                                                    ),
                                                  ),
                                                );
                                              },
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFFE5E7EB),
                                            width: 2,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          foregroundColor: const Color(
                                            0xFF374151,
                                          ),
                                          backgroundColor: AppColors.white,
                                        ),
                                        icon: const Icon(
                                          Icons.g_mobiledata,
                                          size: 28,
                                        ),
                                        label: const Text(
                                          'Sign in with Google',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _CircleIconButton(
                                            icon: Icons.fingerprint,
                                            onTap: () {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Biometric auth not configured',
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 12),
                                          _CircleIconButton(
                                            icon: Icons.face,
                                            onTap: () {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Face ID not configured',
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            "Don't have an account? ",
                                            style: TextStyle(
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: _goToRegister,
                                            child: const Text(
                                              'Sign Up',
                                              style: TextStyle(
                                                color: Color(0xFF6366F1),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 6),

                                      // removed demo/admin test shortcuts
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
                    color: const Color(0x1A000000),
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
            color: selected ? const Color(0xFF6366F1) : const Color(0xFF6B7280),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
        ),
        child: Icon(icon, color: const Color(0xFF6B7280)),
      ),
    );
  }
}
