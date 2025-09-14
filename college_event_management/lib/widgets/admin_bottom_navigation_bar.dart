import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_design.dart';

class AdminBottomNavigationBar extends StatefulWidget {
  final int? currentIndex;

  const AdminBottomNavigationBar({super.key, this.currentIndex});

  @override
  State<AdminBottomNavigationBar> createState() =>
      _AdminBottomNavigationBarState();
}

class _AdminBottomNavigationBarState extends State<AdminBottomNavigationBar> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex ?? 0;
  }

  @override
  void didUpdateWidget(AdminBottomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex &&
        widget.currentIndex != null) {
      setState(() {
        _currentIndex = widget.currentIndex!;
      });
    }
  }

  void _onItemTapped(int index, BuildContext context) {
    // Only navigate if it's a different tab to avoid unnecessary navigation
    if (_currentIndex == index) {
      return; // Already on this tab
    }

    // Always navigate to allow switching between pages
    String route;
    switch (index) {
      case 0:
        route = '/admin-dashboard';
        break;
      case 1:
        route = '/admin/approvals';
        break;
      case 2:
        route = '/admin/users';
        break;
      case 3:
        route = '/admin/locations';
        break;
      case 4:
        route = '/admin/statistics';
        break;
      default:
        route = '/admin-dashboard';
    }

    // Update state and navigate immediately
    setState(() {
      _currentIndex = index;
    });

    // Navigate using GoRouter
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.adminPrimary,
        unselectedItemColor: const Color(0xFF9CA3AF),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedLabelStyle: AppDesign.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppDesign.labelSmall,
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available_outlined),
            activeIcon: Icon(Icons.event_available),
            label: 'Approval',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'Locations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Statistics',
          ),
        ],
      ),
    );
  }
}

// Helper function to determine current index based on route
int getAdminNavigationIndex(String currentRoute) {
  if (currentRoute.contains('/admin-dashboard')) {
    return 0;
  } else if (currentRoute.contains('/admin/approvals')) {
    return 1;
  } else if (currentRoute.contains('/admin/users')) {
    return 2;
  } else if (currentRoute.contains('/admin/locations')) {
    return 3;
  } else if (currentRoute.contains('/admin/statistics')) {
    return 4;
  }
  return 0; // Default to dashboard
}
