import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_design.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import '../../widgets/app_bottom_navigation_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;

        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = user.role;
        final Color roleColor = role == 'admin'
            ? AppColors.adminPrimary
            : role == 'organizer'
            ? AppColors.organizerPrimary
            : AppColors.primary;

        return Scaffold(
          backgroundColor: AppColors.surfaceVariant,
          appBar: AppBar(
            title: Text(
              'Profile',
              style: AppDesign.heading2.copyWith(color: Colors.white),
            ),
            backgroundColor: roleColor,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, size: 24),
              onPressed: () => context.go('/home'),
              tooltip: 'Back to Home',
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, size: 24),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
                tooltip: 'Edit Profile',
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header with gradient background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [roleColor, roleColor.withOpacity(0.8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      child: Column(
                        children: [
                          // Avatar section
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 48,
                              backgroundColor: Colors.white,
                              child: Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName
                                          .substring(0, 1)
                                          .toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: roleColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Name and role
                          Text(
                            user.fullName,
                            style: AppDesign.heading1.copyWith(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          Text(
                            user.email,
                            style: AppDesign.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),

                          // Role badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getRoleText(user.role),
                              style: AppDesign.labelMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Main content container
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Personal Information Section
                      _buildPersonalInfoSection(user, roleColor),

                      const SizedBox(height: 24),

                      // Action buttons section
                      _buildActionButtons(user, roleColor, context),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 4),
        );
      },
    );
  }

  Widget _buildPersonalInfoSection(user, Color roleColor) {
    return Container(
      decoration: AppDesign.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: AppDesign.heading3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.email_outlined, 'Email', user.email, roleColor),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.phone_outlined,
            'Phone',
            user.phoneNumber ?? 'Not set',
            roleColor,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.verified_user_outlined,
            'Role',
            _getRoleText(user.role),
            roleColor,
          ),
          if (user.isStudent) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.badge_outlined,
              'Student ID',
              user.studentId ?? 'Not set',
              roleColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(user, Color roleColor, BuildContext context) {
    return Container(
      decoration: AppDesign.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Actions',
            style: AppDesign.heading3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 20),

          // Primary actions row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: roleColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              if (user.role == 'organizer') ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.lock_reset, size: 18),
                    label: const Text('Change Password'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: roleColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: roleColor, width: 1.5),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final authProvider = context.read<AuthProvider>();
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text('Sign Out', style: AppDesign.heading3),
                    content: Text(
                      'Are you sure you want to sign out?',
                      style: AppDesign.bodyMedium,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Cancel', style: AppDesign.labelLarge),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        child: Text(
                          'Sign Out',
                          style: AppDesign.labelLarge.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true) {
                  await authProvider.signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'organizer':
        return 'Event Organizer';
      case 'student':
        return 'Student';
      default:
        return 'User';
    }
  }
}

Widget _buildInfoRow(
  IconData icon,
  String label,
  String value,
  Color roleColor,
) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: roleColor.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: roleColor.withOpacity(0.1), width: 1),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: roleColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: roleColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppDesign.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppDesign.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
