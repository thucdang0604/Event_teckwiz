import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        context.go('/home');
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isMobile = screenWidth < 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile
                                ? screenWidth * 0.05
                                : screenWidth * 0.06,
                            vertical: isSmallScreen ? 6 : 10,
                          ),
                          child: Column(
                            children: [
                              // Header Section
                              Column(
                                children: [
                                  SizedBox(height: isMobile ? 10 : 15),

                                  // Back Button
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: IconButton(
                                      onPressed: () {
                                        if (Navigator.canPop(context)) {
                                          context.pop();
                                        } else {
                                          context.go('/splash');
                                        }
                                      },
                                      icon: Icon(
                                        Icons.arrow_back_ios,
                                        color: Colors.white,
                                        size: isMobile ? 20 : 24,
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: isMobile ? 8 : 12),

                                  // Logo
                                  Container(
                                    width: isMobile
                                        ? 45
                                        : (isSmallScreen ? 50 : 60),
                                    height: isMobile
                                        ? 45
                                        : (isSmallScreen ? 50 : 60),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        isMobile ? 15 : 20,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: isMobile ? 15 : 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.event,
                                      size: isMobile
                                          ? 25
                                          : (isSmallScreen ? 30 : 35),
                                      color: const Color(0xFF667eea),
                                    ),
                                  ),

                                  SizedBox(
                                    height: isMobile
                                        ? 8
                                        : (isSmallScreen ? 10 : 15),
                                  ),

                                  // Title
                                  Text(
                                    'Welcome Back!',
                                    style: TextStyle(
                                      fontSize: isMobile
                                          ? 18
                                          : (isSmallScreen ? 20 : 24),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),

                                  SizedBox(height: isMobile ? 2 : 4),

                                  // Subtitle
                                  Text(
                                    'Sign in to continue',
                                    style: TextStyle(
                                      fontSize: isMobile
                                          ? 11
                                          : (isSmallScreen ? 12 : 14),
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),

                                  SizedBox(
                                    height: isMobile
                                        ? 8
                                        : (isSmallScreen ? 10 : 15),
                                  ),
                                ],
                              ),

                              // Login Form Card
                              Flexible(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      isMobile ? 15 : 20,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: isMobile ? 15 : 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                      isMobile ? 14 : (isSmallScreen ? 16 : 20),
                                    ),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Email Field
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey[50],
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    isMobile ? 10 : 12,
                                                  ),
                                              border: Border.all(
                                                color: Colors.grey[300]!,
                                                width: 1,
                                              ),
                                            ),
                                            child: TextFormField(
                                              controller: _emailController,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              decoration: InputDecoration(
                                                labelText: 'Email',
                                                hintText: 'Enter your email',
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: isMobile
                                                          ? 14
                                                          : 16,
                                                      vertical: isMobile
                                                          ? 14
                                                          : 16,
                                                    ),
                                                labelStyle: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: isMobile ? 13 : 14,
                                                ),
                                                hintStyle: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: isMobile ? 13 : 14,
                                                ),
                                              ),
                                              style: TextStyle(
                                                fontSize: isMobile ? 13 : 14,
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Please enter your email';
                                                }
                                                if (!value.contains('@')) {
                                                  return 'Please enter a valid email';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),

                                          SizedBox(
                                            height: isMobile
                                                ? 10
                                                : (isSmallScreen ? 12 : 16),
                                          ),

                                          // Password Field
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey[50],
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    isMobile ? 10 : 12,
                                                  ),
                                              border: Border.all(
                                                color: Colors.grey[300]!,
                                                width: 1,
                                              ),
                                            ),
                                            child: TextFormField(
                                              controller: _passwordController,
                                              obscureText: !_isPasswordVisible,
                                              decoration: InputDecoration(
                                                labelText: 'Password',
                                                hintText: 'Enter your password',
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: isMobile
                                                          ? 14
                                                          : 16,
                                                      vertical: isMobile
                                                          ? 14
                                                          : 16,
                                                    ),
                                                suffixIcon: IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _isPasswordVisible =
                                                          !_isPasswordVisible;
                                                    });
                                                  },
                                                  icon: Icon(
                                                    _isPasswordVisible
                                                        ? Icons.visibility_off
                                                        : Icons.visibility,
                                                    color: Colors.grey[600],
                                                    size: isMobile ? 18 : 20,
                                                  ),
                                                ),
                                                labelStyle: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: isMobile ? 13 : 14,
                                                ),
                                                hintStyle: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: isMobile ? 13 : 14,
                                                ),
                                              ),
                                              style: TextStyle(
                                                fontSize: isMobile ? 13 : 14,
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Please enter your password';
                                                }
                                                if (value.length < 6) {
                                                  return 'Password must be at least 6 characters';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),

                                          SizedBox(
                                            height: isMobile
                                                ? 6
                                                : (isSmallScreen ? 8 : 12),
                                          ),

                                          // Forgot Password
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: () {
                                                // TODO: Implement forgot password
                                              },
                                              child: Text(
                                                'Forgot Password?',
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: isMobile ? 11 : 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),

                                          SizedBox(
                                            height: isMobile
                                                ? 10
                                                : (isSmallScreen ? 12 : 16),
                                          ),

                                          // Sign In Button
                                          SizedBox(
                                            width: double.infinity,
                                            height: isMobile
                                                ? 50
                                                : (isSmallScreen ? 52 : 56),
                                            child: ElevatedButton(
                                              onPressed: _isLoading
                                                  ? null
                                                  : _login,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.primary,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        isMobile ? 10 : 12,
                                                      ),
                                                ),
                                              ),
                                              child: _isLoading
                                                  ? SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(Colors.white),
                                                      ),
                                                    )
                                                  : Text(
                                                      'Sign In',
                                                      style: TextStyle(
                                                        fontSize: isMobile
                                                            ? 13
                                                            : (isSmallScreen
                                                                  ? 14
                                                                  : 16),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                            ),
                                          ),

                                          SizedBox(
                                            height: isMobile
                                                ? 10
                                                : (isSmallScreen ? 12 : 16),
                                          ),

                                          // Sign Up Link
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Don't have an account? ",
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: isMobile ? 11 : 12,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  context.go('/register');
                                                },
                                                child: Text(
                                                  'Sign Up',
                                                  style: TextStyle(
                                                    color: AppColors.primary,
                                                    fontSize: isMobile
                                                        ? 11
                                                        : 12,
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
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
