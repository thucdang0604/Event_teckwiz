import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_design.dart';
import '../../widgets/app_bottom_navigation_bar.dart';

class OrganizerCoOrganizersScreen extends StatefulWidget {
  const OrganizerCoOrganizersScreen({super.key});

  @override
  State<OrganizerCoOrganizersScreen> createState() =>
      _OrganizerCoOrganizersScreenState();
}

class _OrganizerCoOrganizersScreenState
    extends State<OrganizerCoOrganizersScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Co-organizers',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.organizerPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'Invite Co-organizer',
              icon: const Icon(Icons.person_add),
              onPressed: () {
                // TODO: Implement invite co-organizer functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invite co-organizer feature coming soon!'),
                    backgroundColor: AppColors.organizerPrimary,
                  ),
                );
              },
            ),
          ],
        ),
        body: Container(
          color: AppColors.surfaceVariant,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.organizerPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Icon(
                      Icons.group,
                      size: 60,
                      color: AppColors.organizerPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Co-organizers',
                    style: AppDesign.heading2.copyWith(
                      color: const Color(0xFF111827),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your team of co-organizers',
                    style: AppDesign.bodyMedium.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement invite co-organizer functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Invite co-organizer feature coming soon!',
                          ),
                          backgroundColor: AppColors.organizerPrimary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Invite Co-organizer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.organizerPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 2),
      ),
    );
  }
}
