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
            // Xóa form
            _emailController.clear();
            _passwordController.clear();

            // Hiển thị thông báo thành công
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đăng nhập thành công!'),
                backgroundColor: AppColors.success,
              ),
            );

            // Chuyển trang
            context.go('/home');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  authProvider.errorMessage ?? 'Đăng nhập thất bại',
                ),
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
              content: Text('Lỗi đăng nhập: ${e.toString()}'),
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

  void _loginDemo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success = await authProvider.signInAnonymously();

      if (mounted) {
        final user = authProvider.currentUser;
        if (user != null && user.isStudent) {
          context.go('/student');
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success && authProvider.isAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng nhập demo thành công!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.errorMessage ?? 'Đăng nhập demo thất bại',
              ),
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
            content: Text('Lỗi đăng nhập demo: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _createTestAdmin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success = await authProvider.register(
        email: 'admin@test.com',
        password: '123456',
        fullName: 'Admin Test',
        role: 'admin',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success && authProvider.isAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo tài khoản admin thành công!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.errorMessage ?? 'Tạo tài khoản admin thất bại',
              ),
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
            content: Text('Lỗi tạo tài khoản admin: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48, // 48 = padding
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),

                    // Logo and Title
                    Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.event_note,
                            color: AppColors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Chào mừng trở lại!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Đăng nhập để tiếp tục',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // Login Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'Nhập email của bạn',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập email';
                              }
                              if (!value.contains('@')) {
                                return 'Email không hợp lệ';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          CustomTextField(
                            controller: _passwordController,
                            label: 'Mật khẩu',
                            hint: 'Nhập mật khẩu của bạn',
                            obscureText: _obscurePassword,
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
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
                                return 'Vui lòng nhập mật khẩu';
                              }
                              if (value.length < 6) {
                                return 'Mật khẩu phải có ít nhất 6 ký tự';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          CustomButton(
                            text: 'Đăng nhập',
                            onPressed: _isLoading ? null : _login,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Chưa có tài khoản? ',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        GestureDetector(
                          onTap: _goToRegister,
                          child: const Text(
                            'Đăng ký ngay',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Demo Buttons
                    Column(
                      children: [
                        TextButton(
                          onPressed: _isLoading ? null : _loginDemo,
                          child: const Text(
                            'Tiếp tục với tài khoản demo',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _isLoading ? null : _createTestAdmin,
                          child: const Text(
                            'Tạo tài khoản admin test',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
