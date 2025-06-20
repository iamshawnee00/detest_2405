// File: lib/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Define core colors
  static const Color primaryColor = Color(0xFFFF6B6B); // A vibrant coral/red
  static const Color secondaryColor = Color(0xFF4ECDC4); // A calming teal
  static const Color accentColor = Color(0xFFFFE66D); // A cheerful yellow
  static const Color errorColor = Color(0xFFE74C3C); // A standard error red

  // Light Theme specific colors
  static const Color lightBackgroundColor = Color(0xFFF8F9FA); // Very light grey
  static const Color lightSurfaceColor = Colors.white;
  static const Color lightTextColorDark = Colors.black87;
  static const Color lightTextColorLight = Colors.black54;

  // Dark Theme specific colors
  static const Color darkBackgroundColor = Color(0xFF121212); // Standard dark theme bg
  static const Color darkSurfaceColor = Color(0xFF1E1E1E); // Slightly lighter dark surface
  static const Color darkTextColor = Colors.white70;
  static const Color darkMutedTextColor = Colors.white54;


  // --- Light Theme ---
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: lightBackgroundColor,
    cardColor: lightSurfaceColor,
    hintColor: secondaryColor, // Often used for accent elements like active toggles
    appBarTheme: const AppBarTheme(
      backgroundColor: lightSurfaceColor,
      elevation: 1, // Subtle elevation
      iconTheme: IconThemeData(color: lightTextColorDark),
      titleTextStyle: TextStyle(
        color: lightTextColorDark,
        fontSize: 20, // Slightly larger for app bar titles
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins', // Example: Using a custom font
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Consistent border radius
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 3, // Slightly less elevation for a cleaner look
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // Consistent border radius
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: lightTextColorDark, fontFamily: 'Poppins'),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: lightTextColorDark, fontFamily: 'Poppins'),
      headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: lightTextColorDark, fontFamily: 'Poppins'), // Adjusted size
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: lightTextColorDark, fontFamily: 'Poppins'), // Adjusted size
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: lightTextColorDark, fontFamily: 'Poppins'), // For list tiles, etc.
      bodyLarge: TextStyle(fontSize: 16, color: lightTextColorDark, fontFamily: 'Roboto', height: 1.5), // Using Roboto for body
      bodyMedium: TextStyle(fontSize: 14, color: lightTextColorLight, fontFamily: 'Roboto', height: 1.4),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Poppins'), // For button text
      bodySmall: TextStyle(fontSize: 12, color: lightTextColorLight, fontFamily: 'Roboto'),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      hintStyle: TextStyle(color: Colors.grey[400], fontFamily: 'Roboto'),
      labelStyle: TextStyle(color: lightTextColorDark.withAlpha((0.7 * 255).round()), fontFamily: 'Roboto'),
    ),
    iconTheme: const IconThemeData(
      color: lightTextColorDark,
      size: 24.0,
    ),
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: lightSurfaceColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: lightTextColorDark,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
    // Use the helper for primarySwatch
    primarySwatch: _createMaterialColor(primaryColor),
  );


  // --- Dark Theme ---
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor, // Keep primary color vibrant
    scaffoldBackgroundColor: darkBackgroundColor,
    cardColor: darkSurfaceColor,
    hintColor: secondaryColor, // Teal can work well in dark themes too
    appBarTheme: AppBarTheme(
      backgroundColor: darkSurfaceColor,
      elevation: 1,
      iconTheme: IconThemeData(color: darkTextColor),
      titleTextStyle: TextStyle(
        color: Colors.white, // Brighter title for dark app bar
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white, // Text on button
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentColor, // Use accent for text buttons in dark mode
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      color: darkSurfaceColor,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins'),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins'),
      headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Poppins'),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Poppins'),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Poppins'),
      bodyLarge: TextStyle(fontSize: 16, color: darkTextColor, fontFamily: 'Roboto', height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, color: darkMutedTextColor, fontFamily: 'Roboto', height: 1.4),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Poppins'), // For button text
      bodySmall: TextStyle(fontSize: 12, color: darkMutedTextColor, fontFamily: 'Roboto'),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: accentColor, width: 2), // Use accent for focus
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      hintStyle: TextStyle(color: Colors.grey[600], fontFamily: 'Roboto'),
      labelStyle: TextStyle(color: darkTextColor.withAlpha((0.7 * 255).round()), fontFamily: 'Roboto'),
    ),
    iconTheme: IconThemeData(
      color: darkTextColor,
      size: 24.0,
    ),
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: darkSurfaceColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.black, // Or a light color if secondary is dark
      onSurface: darkTextColor,
      onError: Colors.black, // Text on error color
      brightness: Brightness.dark,
    ),
    // Use the helper for primarySwatch
    primarySwatch: _createMaterialColor(primaryColor),
  );

  // Helper function to create MaterialColor from a single Color
  // This is useful for `primarySwatch` which needs a MaterialColor.
  static MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor((color.alpha << 24) | (color.red << 16) | (color.green << 8) | color.blue, swatch);
  }
}
