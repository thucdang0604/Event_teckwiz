import 'package:flutter/material.dart';

/// Design System for the Admin UI
class AppDesign {
  // Spacing System
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;

  // Border Radius
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;

  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0x0F000000),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: const Color(0x1A000000),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Typography
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.25,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.5,
  );

  // Card Styles
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius16),
    border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
    boxShadow: cardShadow,
  );

  static BoxDecoration elevatedCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius16),
    border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
    boxShadow: elevatedShadow,
  );

  static BoxDecoration statusChipDecoration(Color color) => BoxDecoration(
    color: color.withOpacity(0.1),
    borderRadius: BorderRadius.circular(radius20),
    border: Border.all(color: color.withOpacity(0.2), width: 1),
  );

  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    elevation: 0,
    backgroundColor: const Color(0xFF1E40AF),
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      horizontal: spacing16,
      vertical: spacing12,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius12),
    ),
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
  );

  static ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    side: const BorderSide(color: Color(0xFF1E40AF), width: 1),
    foregroundColor: const Color(0xFF1E40AF),
    padding: const EdgeInsets.symmetric(
      horizontal: spacing16,
      vertical: spacing12,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius12),
    ),
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
  );

  static ButtonStyle actionButtonStyle(Color color) => ElevatedButton.styleFrom(
    elevation: 0,
    backgroundColor: color.withOpacity(0.1),
    foregroundColor: color,
    padding: const EdgeInsets.symmetric(
      horizontal: spacing12,
      vertical: spacing8,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius8)),
    minimumSize: const Size(32, 32),
    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  );

  // Input Styles
  static InputDecoration textFieldDecoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius12),
      borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius12),
      borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius12),
      borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: spacing16,
      vertical: spacing12,
    ),
    filled: true,
    fillColor: Colors.white,
  );

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
}

/// Extension for consistent spacing
extension SpacingExtension on num {
  double get s4 => this * 4.0;
  double get s8 => this * 8.0;
  double get s12 => this * 12.0;
  double get s16 => this * 16.0;
  double get s20 => this * 20.0;
  double get s24 => this * 24.0;
  double get s32 => this * 32.0;
  double get s40 => this * 40.0;
  double get s48 => this * 48.0;
}
