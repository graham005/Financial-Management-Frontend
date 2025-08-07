import 'package:flutter/material.dart';

class AppColors {
  // Color palette from the provided image
  static const Color richBlackPrimary = Color(0xFF00040D);
  static const Color richBlackSecondary = Color(0xFF011126);
  static const Color bigFootFeetPrimary = Color(0xFFF2955E);
  static const Color bigFootFeetSecondary = Color(0xFFF2845C);
  static const Color ueRed = Color(0xFFBF0404);

  // Light theme colors
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Colors.white;
  static const Color lightOnSurface = richBlackPrimary;

  // Dark theme colors
  static const Color darkBackground = richBlackPrimary;
  static const Color darkSurface = richBlackSecondary;
  static const Color darkOnSurface = Colors.white;

  // Common colors
  static const Color primary = bigFootFeetPrimary;
  static const Color secondary = bigFootFeetSecondary;
  static const Color accent = ueRed;
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color error = ueRed;
}