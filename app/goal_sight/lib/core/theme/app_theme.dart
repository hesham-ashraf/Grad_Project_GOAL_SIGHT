import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color brandBlue = Color(0xFF3F84F8);
  static const Color brandPurple = Color(0xFF7257F5);
  static const Color authBackground = Color(0xFFF2F4F8);
  static const Color authCard = Color(0xFFFFFFFF);
  static const Color authText = Color(0xFF101A2D);
  static const Color darkBackground = Color(0xFF040B1E);
  static const Color darkSurface = Color(0xFF111F35);
  static const Color darkSurfaceAlt = Color(0xFF172743);
  static const Color darkBorder = Color(0xFF334B7A);
  static const Color fanBackground = Color(0xFF0D0F1A);
  static const Color fanCard = Color(0xFF15182B);
  static const Color fanCardAlt = Color(0xFF1A1F37);

  static LinearGradient get brandGradient => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [brandPurple, brandBlue],
      );

  static TextStyle authTitleStyle(BuildContext context) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      color: authText,
      letterSpacing: -0.2,
      height: 1.1,
      textStyle: Theme.of(context).textTheme.headlineMedium,
    );
  }

  static TextStyle authSubtitleStyle(BuildContext context) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF5D6C8D),
      height: 1.4,
      textStyle: Theme.of(context).textTheme.bodyMedium,
    );
  }

  static ThemeData lightTheme() {
    final baseText = GoogleFonts.plusJakartaSansTextTheme().apply(
      fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Arial'],
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: authBackground,
      colorScheme: const ColorScheme.light(
        primary: brandBlue,
        secondary: brandPurple,
        surface: authCard,
      ),
      textTheme: baseText.apply(bodyColor: authText, displayColor: authText),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: authText,
      ),
      cardTheme: CardThemeData(
        color: authCard,
        elevation: 0,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F8FC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDE2EE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDE2EE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: brandBlue),
        ),
        labelStyle: const TextStyle(color: Color(0xFF4B587A)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFD7DDF0)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          foregroundColor: authText,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(color: Color(0xFFA8B2CA)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  static ThemeData darkTheme() {
    final baseText = GoogleFonts.plusJakartaSansTextTheme().apply(
      fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Arial'],
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: fanBackground,
      colorScheme: const ColorScheme.dark(
        primary: brandPurple,
        secondary: brandBlue,
        surface: fanCard,
        onSurface: Colors.white,
      ),
      textTheme:
          baseText.apply(bodyColor: Colors.white, displayColor: Colors.white),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: fanCard,
        shadowColor: const Color(0x1A000000),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF3A4268)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          foregroundColor: Colors.white,
        ),
      ),
      dividerColor: const Color(0xFF2A3152),
    );
  }
}
