import 'package:flutter/material.dart';

class AppTheme {
  // Dark mode colors with dark grey and red theme
  static const Color primaryColor = Color(0xFFDC2626); // Vibrant Red
  static const Color secondaryColor = Color(0xFFEF4444); // Light Red
  static const Color accentColor = Color(0xFFF87171); // Accent Red
  static const Color successColor = Color(0xFF10B981); // Emerald
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color errorColor = Color(0xFFDC2626); // Red
  static const Color infoColor = Color(0xFF4C6FFF); // Data blue

  // Charcoal-navy neutrals — the instrument-panel system from the landing
  // page. These are platform surfaces: gym-branded themes keep the owner's
  // chosen accent colors and only inherit these neutrals.
  static const Color darkBackground = Color(0xFF0E1425); // Navy base
  static const Color darkSurface = Color(0xFF131C33); // App bars / nav
  static const Color darkCard = Color(0xFF16203A); // Cards & panels
  static const Color edge = Color(0xFF243050); // Hairline borders
  static const Color mutedText = Color(0xFF9AA3B8); // Secondary text
  static const Color subtleText = Color(0xFF6B7590); // Captions / hints

  // Super Admin theme color - Gold
  static const Color superAdminColor = Color(0xFFF59E0B); // Amber/Gold

  // Owner theme color - Red
  static const Color ownerColor = Color(0xFFDC2626); // Red

  // Branch Manager theme color - Dark Red
  static const Color branchManagerColor = Color(0xFFB91C1C); // Dark Red

  // Reception theme color - Red
  static const Color receptionColor = Color(0xFFEF4444); // Light Red

  // Accountant theme color - Orange Red
  static const Color accountantColor = Color(0xFFF97316); // Orange

  // Dark Theme with modern design
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Cairo',
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: darkSurface,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: darkSurface,
      foregroundColor: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      color: darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: edge),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: edge),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      filled: true,
      fillColor: darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: mutedText),
      hintStyle: const TextStyle(color: subtleText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      elevation: 0, // Remove elevation, we'll add custom shadow
      backgroundColor: darkSurface.withValues(alpha: 0.9), // Translucent
      selectedItemColor: primaryColor,
      unselectedItemColor: subtleText,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: darkSurface,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dividerColor: edge,
  );

  // Get theme by role with dark mode design
  static ThemeData getThemeByRole(String? role) {
    Color seedColor;

    switch (role) {
      case 'owner':
        seedColor = ownerColor;
        break;
      case 'branch_manager':
        seedColor = branchManagerColor;
        break;
      case 'reception':
      case 'front_desk':
        seedColor = receptionColor;
        break;
      case 'accountant':
      case 'central_accountant':
      case 'branch_accountant':
        seedColor = accountantColor;
        break;
      case 'super_admin':
        seedColor = superAdminColor;
        break;
      default:
        seedColor = primaryColor;
    }

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.dark(
        primary: seedColor,
        secondary: secondaryColor,
        surface: darkSurface,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        color: darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: edge),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: edge),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: seedColor, width: 2),
        ),
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: mutedText),
        hintStyle: const TextStyle(color: subtleText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: seedColor,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0, // Remove elevation, we'll add custom shadow
        backgroundColor: darkSurface.withValues(alpha: 0.9), // Translucent
        selectedItemColor: seedColor,
        unselectedItemColor: subtleText,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: darkSurface,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerColor: edge,
    );
  }

  /// Super Admin dedicated theme (Gold/Amber).
  static ThemeData get superAdminTheme => _buildTheme(superAdminColor);

  /// Build a theme using custom gym branding colors.
  static ThemeData getThemeByGymBranding({
    required Color primaryColor,
    Color? secondaryColor,
  }) {
    return _buildTheme(primaryColor, secondary: secondaryColor);
  }

  /// Internal helper to build a full theme from a seed color.
  static ThemeData _buildTheme(Color seedColor, {Color? secondary}) {
    final sec = secondary ?? seedColor.withValues(alpha: 0.8);
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.dark(
        primary: seedColor,
        secondary: sec,
        surface: darkSurface,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        titleTextStyle: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        color: darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: edge),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: edge),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: seedColor, width: 2),
        ),
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: mutedText),
        hintStyle: const TextStyle(color: subtleText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: seedColor),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: darkSurface.withValues(alpha: 0.9),
        selectedItemColor: seedColor,
        unselectedItemColor: subtleText,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      drawerTheme: DrawerThemeData(backgroundColor: darkSurface),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerColor: edge,
    );
  }
}
