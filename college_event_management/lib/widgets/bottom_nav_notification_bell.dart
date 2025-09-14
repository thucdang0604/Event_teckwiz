import 'package:flutter/material.dart';

class BottomNavNotificationBell extends StatelessWidget {
  final Color iconColor;
  final Color activeIconColor;
  final bool isActive;

  const BottomNavNotificationBell({
    super.key,
    required this.iconColor,
    required this.activeIconColor,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          Icons.notifications,
          color: isActive ? activeIconColor : iconColor,
        ),
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? activeIconColor : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
