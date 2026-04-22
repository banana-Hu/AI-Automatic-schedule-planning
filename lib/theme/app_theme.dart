import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryCream = Color(0xFFF5F0E6);
  static const Color primaryBeige = Color(0xFFEDE4D3);
  static const Color accentPeach = Color(0xFFE8C4A2);
  static const Color accentPink = Color(0xFFE8B4B8);
  static const Color accentLavender = Color(0xFFD4C4E8);
  static const Color accentMint = Color(0xFFB8E0D2);
  static const Color textBrown = Color(0xFF5D4E37);
  static const Color textLightBrown = Color(0xFF8B7355);
  static const Color dividerColor = Color(0xFFD4C4B0);
  static const Color cardBackground = Color(0xFFFFFDF8);
  static const Color shadowColor = Color(0x1A5D4E37);

  static const List<Color> priorityColors = [
    Color(0xFFE8E0D5),
    Color(0xFFB8E0D2),
    Color(0xFFD4E4E8),
    Color(0xFFFFF0E0),
    Color(0xFFE8D4C4),
    Color(0xFFE8C4C4),
  ];

  static const List<Color> warmPastelColors = [
    Color(0xFFFFF0E6),
    Color(0xFFE8F0E8),
    Color(0xFFE6F0FF),
    Color(0xFFFFF6E6),
    Color(0xFFF6E6F6),
    Color(0xFFE6F6F6),
  ];

  static ThemeData get warmDiaryTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBeige,
      scaffoldBackgroundColor: primaryCream,
      colorScheme: ColorScheme.light(
        primary: accentPeach,
        secondary: accentPink,
        tertiary: accentLavender,
        surface: cardBackground,
        onPrimary: textBrown,
        onSecondary: textBrown,
        onSurface: textBrown,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryCream,
        foregroundColor: textBrown,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textBrown,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardTheme(
        color: cardBackground,
        elevation: 2,
        shadowColor: shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPeach,
          foregroundColor: textBrown,
          elevation: 2,
          shadowColor: shadowColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textBrown,
          side: const BorderSide(color: accentPeach, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textLightBrown,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBackground,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentPeach, width: 2),
        ),
        hintStyle: TextStyle(color: textLightBrown.withOpacity(0.6)),
        labelStyle: const TextStyle(color: textLightBrown),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardBackground,
        selectedItemColor: accentPeach,
        unselectedItemColor: textLightBrown,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentPeach;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(textBrown),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: const BorderSide(color: accentPeach, width: 1.5),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textBrown,
        contentTextStyle: const TextStyle(color: cardBackground),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          color: textBrown,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: textLightBrown,
          fontSize: 14,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textBrown,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        headlineMedium: TextStyle(
          color: textBrown,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: textBrown,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textBrown,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textBrown,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: textLightBrown,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: textBrown,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textLightBrown,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: textLightBrown,
          fontSize: 12,
        ),
        labelLarge: TextStyle(
          color: textBrown,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
