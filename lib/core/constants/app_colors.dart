import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // CineFlix Media Brand Colors
  static const Color primary = Color(0xFFFF006B); // CineFlix editorial pink
  static const Color primaryDark = Color(0xFFC60052);
  static const Color secondary = Color(0xFF020B14); // Cinema navy
  static const Color accent = Color(0xFFFF006B);

  // Neutral Colors (Light)
  static const Color lightBackground = Color(0xFFF6F4F7);
  static const Color lightSurface = Colors.white;
  static const Color lightCard = Colors.white;
  static const Color lightTextPrimary = Color(0xFF090C14);
  static const Color lightTextSecondary = Color(0xFF626773);
  static const Color lightTextMuted = Color(0xFF9E9E9E);
  static const Color lightBorder = Color(0xFFE4DEE5);

  // Neutral Colors (Dark)
  static const Color darkBackground = Colors.transparent;
  static const Color darkSurface = Color(0xD906111D);
  static const Color darkCard = Color(0xCC081725);
  static const Color darkTextPrimary = Color(0xFFF8F7F9);
  static const Color darkTextSecondary = Color(0xFFC5C8D0);
  static const Color darkTextMuted = Color(0xFF7D8490);
  static const Color darkBorder = Color(0x55172635);

  // States
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFDC3545);

  // Convenient Aliases
  static const Color backgroundDark = darkBackground;
  static const Color backgroundLight = lightBackground;
  static const Color cardDark = darkCard;
  static const Color cardLight = lightCard;
  static const Color textPrimaryLight = lightTextPrimary;
  static const Color textSecondaryLight = lightTextSecondary;
  static const Color textPrimaryDark = darkTextPrimary;
  static const Color textSecondaryDark = darkTextSecondary;
}
