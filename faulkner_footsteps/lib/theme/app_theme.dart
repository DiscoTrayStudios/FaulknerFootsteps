import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTheme centralizes all theme-related settings for the application.
/// This ensures consistent styling across the entire app.
class AppTheme {
  AppTheme._(); // Private constructor to prevent instantiation

  // Main color palette
  static const Color primaryBackground =
      Color(0xFFEED6C4); // Light beige - main background
  static const Color secondaryBackground =
      Color(0xFFFFF3E4); // Lighter beige - card background
  static const Color primaryColor =
      Color(0xFF6B4F4F); // Maroon brown - primary accent
  static const Color secondaryColor =
      Color(0xFFDABA82); // Tan - secondary accent
  static const Color textPrimary =
      Color(0xFF483434); // Dark brown - primary text
  static const Color textSecondary =
      Color(0xFF6B4F4F); // Maroon brown - secondary text
  static const Color textOnPrimary =
      Color(0xFFFFF3E4); // Light beige - text on primary color
  static const Color errorColor = Color(0xFFFF4639); // Red - for errors
  static const Color successColor =
      Color(0xFF4CAF50); // Green - for success states

  // Gradients
  static const LinearGradient splashGradient = LinearGradient(
    colors: [
      Color(0xFF483434), // Dark brown
      Color(0xFFB88D6A), // Light brown
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Typography
  static TextStyle get ultraHeading => GoogleFonts.ultra(
        textStyle: const TextStyle(
          color: textPrimary,
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
        ),
      );

  static TextStyle get ultraHeadingSmall => GoogleFonts.ultra(
        textStyle: const TextStyle(
          color: textPrimary,
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
        ),
      );

  static TextStyle get ultraHeadingOnPrimary => GoogleFonts.ultra(
        textStyle: const TextStyle(
          color: textOnPrimary,
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
        ),
      );

  static TextStyle get rakkasBody => GoogleFonts.rakkas(
        textStyle: const TextStyle(
          color: textSecondary,
          fontSize: 16.0,
        ),
      );

  static TextStyle get rakkasBodySmall => GoogleFonts.rakkas(
        textStyle: const TextStyle(
          color: textSecondary,
          fontSize: 14.0,
        ),
      );

  static TextStyle get rakkasBodyOnPrimary => GoogleFonts.rakkas(
        textStyle: const TextStyle(
          color: textOnPrimary,
          fontSize: 16.0,
        ),
      );

  // Card decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: secondaryBackground,
        border: Border.all(
          color: Color(0xFFB08585), // Light maroon border
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8.0,
            offset: Offset(3, 4),
          ),
        ],
      );

  // Button styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: secondaryColor,
        foregroundColor: textPrimary,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      );

  static ButtonStyle get textButtonStyle => TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );

  // Input decoration
  static InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
        fillColor: secondaryBackground,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: Color(0xFFB08585),
            width: 2.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: primaryColor,
            width: 2.0,
          ),
        ),
        labelStyle: rakkasBody,
        hintStyle: rakkasBodySmall,
      );

  // App bar theme
  static AppBarTheme get appBarTheme => AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 4.0,
        shadowColor: Colors.black45,
        titleTextStyle: ultraHeadingOnPrimary,
        iconTheme: IconThemeData(color: textOnPrimary),
      );

  // Full theme data
  static ThemeData get themeData => ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: primaryBackground,
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          secondary: secondaryColor,
          surface: secondaryBackground,
          background: primaryBackground,
          error: errorColor,
          onPrimary: textOnPrimary,
          onBackground: textPrimary,
          onSurface: textPrimary,
        ),
        appBarTheme: appBarTheme,
        inputDecorationTheme: inputDecorationTheme,
        elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
        textButtonTheme: TextButtonThemeData(style: textButtonStyle),
        textTheme: TextTheme(
          displayLarge: ultraHeading,
          displayMedium: ultraHeadingSmall,
          bodyLarge: rakkasBody,
          bodyMedium: rakkasBodySmall,
        ),
      );
}
