import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeData>((ref) {
  return ThemeNotifier();
});

final isDarkModeProvider = StateProvider<bool>((ref) => false);

class ThemeNotifier extends StateNotifier<ThemeData> {
  ThemeNotifier() : super(_lightTheme) {
    _loadTheme();
  }

  static final _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.lightBackground,
    cardColor: AppColors.lightSurface,
    textTheme: TextTheme(
      bodyMedium: TextStyle(fontFamily: GoogleFonts.underdog().fontFamily),
      bodyLarge: TextStyle(fontFamily: GoogleFonts.underdog().fontFamily),
      titleLarge: TextStyle(fontFamily: GoogleFonts.underdog().fontFamily),
    ),
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.lightSurface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.lightOnSurface,
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.underdog(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.underdog(),
      ),
    ),
    dataTableTheme: DataTableThemeData(
      headingTextStyle: GoogleFonts.underdog(fontWeight: FontWeight.w600),
      dataTextStyle: GoogleFonts.underdog(),
    ),
  );

  static final _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardColor: AppColors.darkSurface,
    textTheme: TextTheme(
      bodyMedium: TextStyle(
        fontFamily: GoogleFonts.underdog().fontFamily,
        color: AppColors.darkOnSurface,
      ),
      bodyLarge: TextStyle(
        fontFamily: GoogleFonts.underdog().fontFamily,
        color: AppColors.darkOnSurface,
      ),
      titleLarge: TextStyle(
        fontFamily: GoogleFonts.underdog().fontFamily,
        color: AppColors.darkOnSurface,
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.darkSurface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.darkOnSurface,
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.underdog(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.underdog(),
      ),
    ),
    dataTableTheme: DataTableThemeData(
      headingTextStyle: GoogleFonts.underdog(
        fontWeight: FontWeight.w600,
        color: AppColors.darkOnSurface,
      ),
      dataTextStyle: GoogleFonts.underdog(color: AppColors.darkOnSurface),
    ),
  );

  void toggleTheme() async {
    final isDark = state.brightness == Brightness.dark;
    state = isDark ? _lightTheme : _darkTheme;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', !isDark);
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    state = isDark ? _darkTheme : _lightTheme;
  }
}