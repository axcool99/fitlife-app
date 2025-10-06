import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FitLife Design System Theme
/// Dark theme with vibrant accent colors for fitness app

class FitLifeTheme {
  // ===== COLORS =====
  static const Color background = Color(0xFF0D0D0D);
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color accentGreen = Color(0xFF00FF85);
  static const Color accentBlue = Color(0xFF1E90FF);
  static const Color accentOrange = Color(0xFFFFA500);
  static const Color accentPurple = Color(0xFF9B59B6);
  static const Color highlightPink = Color(0xFFFF0099);
  static const Color error = Color(0xFFFF4444); // Error color for validation and offline indicators

  // ===== BACKWARD COMPATIBILITY COLORS =====
  // These maintain compatibility with existing components
  static const Color backgroundColor = background;
  static const Color surfaceColor = Color(0xFF1A1A1A); // Card background
  static const Color textPrimary = primaryText;
  static const Color textSecondary = Color(0xFFB3B3B3); // Slightly dimmed white
  static const Color accentGray = accentGreen; // Use green as accent
  static const Color borderColor = Color(0xFF333333);
  static const Color buttonBackground = accentGreen;
  static const Color buttonText = primaryText;
  static const Color inputFillColor = Color(0xFF1A1A1A);
  static const Color dividerColor = Color(0xFF333333);
  static const Color focusBorderColor = accentGreen;

  // ===== TYPOGRAPHY =====
  static const String fontFamily = 'Poppins';

  static TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.bold,
      fontSize: 28,
      color: primaryText,
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.bold,
      fontSize: 24,
      color: primaryText,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      color: primaryText,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      color: primaryText.withOpacity(0.8),
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontStyle: FontStyle.italic,
      fontSize: 12,
      color: primaryText.withOpacity(0.6),
    ),
  );

  // ===== COMPONENT COMPATIBILITY TYPOGRAPHY =====
  static TextStyle get headingLarge => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static TextStyle get headingMedium => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static TextStyle get headingSmall => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static TextStyle get bodyLarge => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textSecondary,
  );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textSecondary,
  );

  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
  );

  static TextStyle get link => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: accentGreen,
  );

  // ===== BUTTON STYLES =====
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: accentGreen,
    foregroundColor: background, // Dark text on neon green background
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 4,
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24), // Reduced vertical padding from 14 to 12 for compact buttons while maintaining touch targets
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: accentBlue,
    foregroundColor: background, // Dark text on neon blue background
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 4,
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24), // Reduced vertical padding from 14 to 12 for compact buttons
  );

  static ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    side: BorderSide(color: accentGreen),
    foregroundColor: accentGreen, // Green text on transparent background
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24), // Reduced vertical padding from 14 to 12 for compact buttons
  );

  // ===== SOCIAL BUTTON STYLE =====
  static ButtonStyle socialButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: surfaceColor, // Dark background (#1A1A1A)
    foregroundColor: primaryText, // White text/icon
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24), // Reduced vertical padding from 14 to 12 for compact buttons
  );

  // ===== INPUT DECORATION =====
  // Style Hierarchy:
  // - hintText and labelText (when inside field) use same font size (14px) for consistency
  // - floatingLabelStyle (when focused and label moves up) remains smaller (12px) per Material Design
  // - This ensures readable hint text while maintaining proper label behavior on focus
  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF1A1A1A),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Color(0xFF333333)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: accentGreen),
    ),
    hintStyle: TextStyle(
      color: primaryText.withOpacity(0.5),
      fontSize: 14, // Increased from 12px for better readability while maintaining subtle appearance
      fontFamily: fontFamily,
    ),
    labelStyle: TextStyle(
      color: primaryText.withOpacity(0.8),
      fontSize: 14, // Same size as hintText for consistency when label is displayed inside field
      fontFamily: fontFamily,
    ),
    floatingLabelStyle: TextStyle(
      color: accentGreen, // Use accent green for floating label to match focus state
      fontSize: 12, // Smaller size for floating label per Material Design standards
      fontFamily: fontFamily,
    ),
  );

  // ===== COMPONENT COMPATIBILITY =====
  static InputDecoration get inputDecoration => InputDecoration(
    filled: true,
    fillColor: inputFillColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderColor, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderColor, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: focusBorderColor, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
    labelStyle: bodyMedium,
    hintStyle: bodyMedium.copyWith(color: textSecondary.withOpacity(0.6)),
  );

  // ===== SHADOWS =====
  static BoxShadow get cardShadow => BoxShadow(
    color: Colors.black.withOpacity(0.5),
    blurRadius: 8,
    offset: const Offset(0, 4),
  );

  static BoxShadow get inputShadow => BoxShadow(
    color: Colors.black.withOpacity(0.3),
    blurRadius: 6,
    offset: const Offset(0, 2),
  );

  static BoxShadow get inputFocusShadow => BoxShadow(
    color: accentGreen.withOpacity(0.3),
    blurRadius: 8,
    offset: const Offset(0, 3),
  );

  static BoxShadow get buttonShadow => BoxShadow(
    color: Colors.black.withOpacity(0.4),
    blurRadius: 8,
    offset: const Offset(0, 4),
  );

  static BoxShadow get softShadow => BoxShadow(
    color: Colors.black.withOpacity(0.3),
    blurRadius: 8,
    offset: const Offset(0, 4),
  );

  // ===== DIMENSIONS =====
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  static const double spacingXXXL = 64.0;

  static const double cardBorderRadius = 16.0;
  static const double inputBorderRadius = 12.0;
  static const double buttonBorderRadius = 12.0;
  static const double radiusM = 12.0; // Medium border radius for consistency
  static const double radiusS = 8.0; // Small border radius for consistency

  // ===== LEGACY COMPATIBILITY =====
  static const double legacyButtonBorderRadius = buttonBorderRadius;

  // ===== THEMEDATA =====
  static ThemeData themeData = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    textTheme: textTheme,
    inputDecorationTheme: inputDecorationTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
    iconTheme: IconThemeData(color: primaryText),
    cardTheme: CardThemeData(
      color: Color(0xFF1A1A1A),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.black.withOpacity(0.5),
    ),
    dividerColor: Color(0xFF333333),
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: textPrimary,
      elevation: 0,
      shadowColor: Colors.transparent,
    ),
  );
}
