import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studentIdController = TextEditingController();

  String _selectedRole = 'student';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      bool success = await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        studentId:
            _selectedRole == 'student' &&
                _studentIdController.text.trim().isNotEmpty
            ? _studentIdController.text.trim()
            : null,
        department: null,
        role: _selectedRole,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          // Xóa form
          _emailController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          _fullNameController.clear();
          _phoneController.clear();
          _studentIdController.clear();

          // Hiển thị thông báo thành công
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful!'),
              backgroundColor: Colors.green,
            ),
          );

          // Chuyển trang
          context.go('/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Registration failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
                                          context.go('/login');
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
                                      Icons.person_add,
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
                                    'Create Account',
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
                                    'Join us and start your journey',
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

                              SizedBox(height: isMobile ? 15 : 20),

                              // Registration Form Card
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
                                          // Full Name Field
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
                                              controller: _fullNameController,
                                              decoration: InputDecoration(
                                                labelText: 'Full Name',
                                                hintText:
                                                    'Enter your full name',
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
                                                  return 'Please enter your full name';
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
                                                if (!RegExp(
                                                  r'^[^@]+@[^@]+\.[^@]+',
                                                ).hasMatch(value)) {
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

                                          // Phone Field
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
                                              controller: _phoneController,
                                              keyboardType: TextInputType.phone,
                                              decoration: InputDecoration(
                                                labelText:
                                                    'Phone Number (Optional)',
                                                hintText:
                                                    'Enter your phone number',
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
                                            ),
                                          ),

                                          SizedBox(
                                            height: isMobile
                                                ? 10
                                                : (isSmallScreen ? 12 : 16),
                                          ),

                                          // Student ID Field (only for students)
                                          if (_selectedRole == 'student') ...[
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
                                                controller:
                                                    _studentIdController,
                                                decoration: InputDecoration(
                                                  labelText: 'Student ID',
                                                  hintText:
                                                      'Enter your student ID',
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
                                                    fontSize: isMobile
                                                        ? 13
                                                        : 14,
                                                  ),
                                                  hintStyle: TextStyle(
                                                    color: Colors.grey[400],
                                                    fontSize: isMobile
                                                        ? 13
                                                        : 14,
                                                  ),
                                                ),
                                                style: TextStyle(
                                                  fontSize: isMobile ? 13 : 14,
                                                ),
                                                validator: (value) {
                                                  if (_selectedRole ==
                                                          'student' &&
                                                      (value == null ||
                                                          value.isEmpty)) {
                                                    return 'Please enter your student ID';
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
                                          ],

                                          // Role Selection
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
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isMobile ? 14 : 16,
                                                vertical: isMobile ? 4 : 8,
                                              ),
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  value: _selectedRole,
                                                  isExpanded: true,
                                                  style: TextStyle(
                                                    fontSize: isMobile
                                                        ? 13
                                                        : 14,
                                                    color: Colors.grey[800],
                                                  ),
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
                                                      if (_selectedRole ==
                                                          'organizer') {
                                                        _studentIdController
                                                            .clear();
                                                      }
                                                    });
                                                  },
                                                ),
                                              ),
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
                                              obscureText: _obscurePassword,
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
                                                      _obscurePassword =
                                                          !_obscurePassword;
                                                    });
                                                  },
                                                  icon: Icon(
                                                    _obscurePassword
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
                                                ? 10
                                                : (isSmallScreen ? 12 : 16),
                                          ),

                                          // Confirm Password Field
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
                                              controller:
                                                  _confirmPasswordController,
                                              obscureText:
                                                  _obscureConfirmPassword,
                                              decoration: InputDecoration(
                                                labelText: 'Confirm Password',
                                                hintText:
                                                    'Confirm your password',
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
                                                      _obscureConfirmPassword =
                                                          !_obscureConfirmPassword;
                                                    });
                                                  },
                                                  icon: Icon(
                                                    _obscureConfirmPassword
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
                                                  return 'Please confirm your password';
                                                }
                                                if (value !=
                                                    _passwordController.text) {
                                                  return 'Passwords do not match';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),

                                          SizedBox(
                                            height: isMobile
                                                ? 12
                                                : (isSmallScreen ? 16 : 20),
                                          ),

                                          // Register Button
                                          SizedBox(
                                            width: double.infinity,
                                            height: isMobile
                                                ? 50
                                                : (isSmallScreen ? 52 : 56),
                                            child: ElevatedButton(
                                              onPressed: _isLoading
                                                  ? null
                                                  : _register,
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
                                                      'Create Account',
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

                                          // Login Link
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Already have an account? ",
                                                style: TextStyle(
                                                  fontSize: isMobile ? 11 : 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  context.go('/login');
                                                },
                                                child: Text(
                                                  'Sign In',
                                                  style: TextStyle(
                                                    fontSize: isMobile
                                                        ? 11
                                                        : 12,
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
