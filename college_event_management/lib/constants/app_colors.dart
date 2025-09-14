import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Blue Theme
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF42A5F5);

  // Secondary Colors - Light Blue Theme
  static const Color secondary = Color(0xFF2196F3);
  static const Color secondaryDark = Color(0xFF1565C0);
  static const Color secondaryLight = Color(0xFF64B5F6);

  // Accent Colors - Cyan Theme
  static const Color accent = Color(0xFF00BCD4);
  static const Color accentDark = Color(0xFF0097A7);
  static const Color accentLight = Color(0xFF4DD0E1);

  // Status Colors - Blue Theme
  static const Color success = Color(0xFF00ACC1);
  static const Color warning = Color(0xFF26A69A);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF1976D2);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFF5F5F5);
  static const Color greyDark = Color(0xFF616161);
  static const Color border = Color(0xFFE0E0E0);

  // Background Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Event Category Colors - Blue Theme
  static const Color academicColor = Color(0xFF1976D2);
  static const Color sportsColor = Color(0xFF2196F3);
  static const Color cultureColor = Color(0xFF42A5F5);
  static const Color volunteerColor = Color(0xFF64B5F6);
  static const Color skillsColor = Color(0xFF00BCD4);
  static const Color workshopColor = Color(0xFF26A69A);
  static const Color exhibitionColor = Color(0xFF00ACC1);
  static const Color otherColor = Color(0xFF9E9E9E);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Enhanced Colors for Admin UI - Blue Theme
  static const Color adminPrimary = Color(0xFF0D47A1);
  static const Color adminSecondary = Color(0xFF1565C0);
  static const Color adminAccent = Color(0xFF00BCD4);

  // Enhanced Colors for Organizer UI - Green Theme
  static const Color organizerPrimary = Color(0xFF2E7D32);
  static const Color organizerSecondary = Color(0xFF4CAF50);
  static const Color organizerAccent = Color(0xFF66BB6A);

  // Status Colors for Admin - Blue Theme
  static const Color statusPending = Color(0xFF26A69A);
  static const Color statusApproved = Color(0xFF00ACC1);
  static const Color statusRejected = Color(0xFFF44336);
  static const Color statusBlocked = Color(0xFF757575);
  static const Color statusPublished = Color(0xFF1976D2);
  static const Color statusDraft = Color(0xFF9E9E9E);
  static const Color statusCancelled = Color(0xFFEF4444);

  // Card and Surface Colors
  static const Color cardShadow = Color(0x0F000000);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color surfaceVariant = Color(0xFFF9FAFB);

  // Interactive Colors - Blue Theme
  static const Color hoverBackground = Color(0xFFE3F2FD);
  static const Color selectedBackground = Color(0xFFBBDEFB);
  static const Color pressedBackground = Color(0xFF90CAF9);
}
