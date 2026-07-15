import 'package:flutter/material.dart';

class ClientTheme {
  // Colors — charcoal-navy neutrals shared with the PowerFit landing page.
  // The names keep their historical "grey" identifiers so call sites don't
  // churn; the crimson brand accent applies only to the unbranded default —
  // gyms with custom branding get their own colors via buildBrandedTheme.
  static const Color primaryRed = Color(0xFFDC143C); // Crimson brand
  static const Color darkGrey = Color(0xFF0E1425);   // Scaffold / background
  static const Color mediumGrey = Color(0xFF131C33); // Nav / app bar surface
  static const Color cardGrey = Color(0xFF16203A);   // Cards & rows
  static const Color lightGrey = Color(0xFF1B2748);  // Filled inputs
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF9AA3B8);
  static const Color subtleGrey = Color(0xFF6B7590); // Captions / hints

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkGrey,
      primaryColor: primaryRed,

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: mediumGrey,
        foregroundColor: textWhite,
        elevation: 0,
        centerTitle: true,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: cardGrey,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: textWhite,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: textGrey),
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textWhite,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textWhite,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textWhite,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textWhite,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textWhite,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textWhite,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textWhite,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textWhite,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textGrey,
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: primaryRed,
      ),

      // Floating Action Button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryRed,
        foregroundColor: textWhite,
      ),

      // Bottom Navigation Bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: mediumGrey,
        selectedItemColor: primaryRed,
        unselectedItemColor: textGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: lightGrey,
        thickness: 1,
      ),

      colorScheme: const ColorScheme.dark(
        primary: primaryRed,
        secondary: primaryRed,
        surface: mediumGrey,
        error: Colors.red,
        onPrimary: textWhite,
        onSecondary: textWhite,
        onSurface: textWhite,
        onError: textWhite,
      ),
    );
  }

  /// Build a themed variant using the gym's branding colors.
  static ThemeData buildBrandedTheme(Color primary, Color secondary) {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkGrey,
      primaryColor: primary,
      appBarTheme: AppBarTheme(
        backgroundColor: mediumGrey,
        foregroundColor: textWhite,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: cardGrey,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textWhite,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: textGrey),
      ),
      iconTheme: IconThemeData(color: primary),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: textWhite,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: mediumGrey,
        selectedItemColor: primary,
        unselectedItemColor: textGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: DividerThemeData(color: lightGrey, thickness: 1),
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: mediumGrey,
        error: Colors.red,
        onPrimary: textWhite,
        onSecondary: textWhite,
        onSurface: textWhite,
        onError: textWhite,
      ),
    );
  }
}
