import 'package:flutter/material.dart';
import 'appcolors.dart';

class AppTheme {
  // ☀️ Tema Claro
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.primary,
      cardColor: AppColors.lightCard,
      dividerColor: AppColors.borderLight, // 👉 agregado
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightText,
        elevation: 0,
      ),
      iconTheme: const IconThemeData(color: AppColors.lightText),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.lightText),
        bodyLarge: TextStyle(color: AppColors.lightText, fontSize: 18),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        background: AppColors.lightBackground,
        surface: AppColors.lightCard,
        onBackground: AppColors.lightText,
        onSurface: AppColors.lightText,
      ),
    );
  }

  // 🌙 Tema Oscuro
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.primary,
      cardColor: AppColors.darkCard,
      dividerColor: AppColors.borderDark, // 👉 agregado
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkText,
        elevation: 0,
      ),
      iconTheme: const IconThemeData(color: AppColors.darkText),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.darkText),
        bodyLarge: TextStyle(color: AppColors.darkText, fontSize: 18),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        background: AppColors.darkBackground,
        surface: AppColors.darkCard,
        onBackground: AppColors.darkText,
        onSurface: AppColors.darkText,
      ),
    );
  }
}
