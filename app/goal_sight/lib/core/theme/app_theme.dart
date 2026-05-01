import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Core design tokens for the GoalSight fan experience.
///
/// The palette keeps the UI dark and premium, with restrained neon accents so
/// the analytics content stays readable and the app still feels energetic.
class AppColors {
  static const Color background = Color(0xFF050816);
  static const Color backgroundAlt = Color(0xFF070B14);
  static const Color surface = Color(0xFF0D1324);
  static const Color surfaceElevated = Color(0xFF141C31);
  static const Color surfaceRaised = Color(0xFF1A2340);
  static const Color outline = Color(0xFF24304A);
  static const Color outlineSubtle = Color(0xFF1A2438);

  static const Color primaryBlue = Color(0xFF356BFF);
  static const Color primaryPurple = Color(0xFF705AF5);
  static const Color accentCyan = Color(0xFF2DE2E6);
  static const Color accentGreen = Color(0xFF70F59A);

  static const Color textPrimary = Color(0xFFF5F8FF);
  static const Color textSecondary = Color(0xFFB7C4DD);
  static const Color textMuted = Color(0xFF8391AE);

  static const Color success = Color(0xFF4CE58A);
  static const Color warning = Color(0xFFFFC857);
  static const Color danger = Color(0xFFFF6B8A);

  // Existing auth screen tokens are kept for backwards compatibility.
  static const Color authBackground = Color(0xFFF2F4F8);
  static const Color authCard = Color(0xFFFFFFFF);
  static const Color authText = Color(0xFF101A2D);
}

/// Spacing follows a consistent rhythm so paddings and margins stay predictable.
class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  static const EdgeInsets page =
      EdgeInsets.symmetric(horizontal: 20, vertical: 20);
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets section =
      EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  static const EdgeInsets card = EdgeInsets.all(16);
  static const EdgeInsets cardCompact = EdgeInsets.all(14);
  static const EdgeInsets button =
      EdgeInsets.symmetric(horizontal: 18, vertical: 14);
  static const EdgeInsets input =
      EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  static const EdgeInsets chip =
      EdgeInsets.symmetric(horizontal: 12, vertical: 8);
}

/// Rounded corners stay consistent across cards, buttons and fields.
class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 28;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(20));
  static const BorderRadius cardLarge = BorderRadius.all(Radius.circular(24));
  static const BorderRadius button = BorderRadius.all(Radius.circular(18));
  static const BorderRadius input = BorderRadius.all(Radius.circular(16));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(999));
}

/// Shadows are intentionally soft so surfaces feel lifted without looking heavy.
class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> cardGlow = [
    BoxShadow(
      color: Color(0x2A2DE2E6),
      blurRadius: 28,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> buttonGlow = [
    BoxShadow(
      color: Color(0x33705AF5),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];
}

/// Typography keeps headlines punchy and body text extremely readable on dark
/// surfaces. The same base font family is reused across the app for consistency.
class AppTextStyles {
  static TextStyle headline({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      color: color ?? AppColors.textPrimary,
      letterSpacing: -0.6,
      height: 1.08,
    );
  }

  static TextStyle title({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: color ?? AppColors.textPrimary,
      letterSpacing: -0.2,
      height: 1.15,
    );
  }

  static TextStyle body({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: color ?? AppColors.textSecondary,
      height: 1.5,
    );
  }

  static TextStyle caption({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: color ?? AppColors.textMuted,
      height: 1.35,
      letterSpacing: 0.1,
    );
  }

  static TextStyle button({Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: color ?? AppColors.textPrimary,
      letterSpacing: 0.2,
      height: 1.1,
    );
  }
}

/// Gradients are reserved for brand moments: primary actions, live signals and
/// the logo. This keeps the app feeling premium instead of overly colorful.
class AppGradients {
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primaryPurple, AppColors.accentCyan],
  );

  static const LinearGradient live = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.accentCyan, AppColors.accentGreen],
  );

  static const LinearGradient surface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.surface, AppColors.surfaceElevated],
  );
}

class AppTheme {
  static const Color brandBlue = AppColors.primaryBlue;
  static const Color brandPurple = AppColors.primaryPurple;
  static const Color accentCyan = AppColors.accentCyan;
  static const Color accentGreen = AppColors.accentGreen;

  static const Color darkBackground = AppColors.background;
  static const Color darkSurface = AppColors.surface;
  static const Color darkSurfaceAlt = AppColors.surfaceElevated;
  static const Color darkBorder = AppColors.outline;
  static const Color fanBackground = AppColors.background;
  static const Color fanCard = AppColors.surface;
  static const Color fanCardAlt = AppColors.surfaceElevated;

  static const Color authBackground = AppColors.authBackground;
  static const Color authCard = AppColors.authCard;
  static const Color authText = AppColors.authText;

  static LinearGradient get brandGradient => AppGradients.brand;
  static LinearGradient get accentGradient => AppGradients.live;
  static LinearGradient get surfaceGradient => AppGradients.surface;

  static TextStyle authTitleStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppTextStyles.headline(
      color: isDark ? AppColors.textPrimary : AppColors.authText,
    );
  }

  static TextStyle authSubtitleStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppTextStyles.body(
      color: isDark ? AppColors.textSecondary : const Color(0xFF5D6C8D),
    ).copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.4,
    );
  }

  static ThemeData lightTheme() {
    return _buildTheme(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.authBackground,
      surfaceColor: AppColors.authCard,
      surfaceVariantColor: const Color(0xFFF5F8FD),
      primaryColor: AppColors.primaryBlue,
      secondaryColor: AppColors.primaryPurple,
      tertiaryColor: AppColors.accentCyan,
      outlineColor: const Color(0xFFD8E0EF),
      textPrimary: AppColors.authText,
      textSecondary: const Color(0xFF5D6C8D),
      textMuted: const Color(0xFF7A849B),
      foregroundColor: AppColors.authText,
      shadowColor: const Color(0x14000000),
      errorColor: const Color(0xFFD93A59),
      appBarCenterTitle: true,
      appBarForegroundColor: AppColors.authText,
    );
  }

  static ThemeData darkTheme() {
    return _buildTheme(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      surfaceColor: AppColors.surface,
      surfaceVariantColor: AppColors.surfaceElevated,
      primaryColor: AppColors.primaryPurple,
      secondaryColor: AppColors.accentCyan,
      tertiaryColor: AppColors.accentGreen,
      outlineColor: AppColors.outline,
      textPrimary: AppColors.textPrimary,
      textSecondary: AppColors.textSecondary,
      textMuted: AppColors.textMuted,
      foregroundColor: AppColors.textPrimary,
      shadowColor: const Color(0x44000000),
      errorColor: AppColors.danger,
      appBarCenterTitle: false,
      appBarForegroundColor: AppColors.textPrimary,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldBackgroundColor,
    required Color surfaceColor,
    required Color surfaceVariantColor,
    required Color primaryColor,
    required Color secondaryColor,
    required Color tertiaryColor,
    required Color outlineColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required Color foregroundColor,
    required Color shadowColor,
    required Color errorColor,
    required bool appBarCenterTitle,
    required Color appBarForegroundColor,
  }) {
    final baseText = GoogleFonts.plusJakartaSansTextTheme();
    final textTheme = baseText.copyWith(
      displayLarge: AppTextStyles.headline(color: textPrimary),
      displayMedium: AppTextStyles.headline(color: textPrimary),
      displaySmall: AppTextStyles.headline(color: textPrimary),
      headlineLarge: AppTextStyles.headline(color: textPrimary),
      headlineMedium: AppTextStyles.title(color: textPrimary),
      headlineSmall: AppTextStyles.title(color: textPrimary),
      titleLarge: AppTextStyles.title(color: textPrimary),
      titleMedium: AppTextStyles.title(color: textPrimary),
      titleSmall: AppTextStyles.body(color: textSecondary),
      bodyLarge: AppTextStyles.body(color: textPrimary),
      bodyMedium: AppTextStyles.body(color: textPrimary),
      bodySmall: AppTextStyles.caption(color: textMuted),
      labelLarge: AppTextStyles.button(color: foregroundColor),
      labelMedium: AppTextStyles.caption(color: textSecondary),
      labelSmall: AppTextStyles.caption(color: textMuted),
    );

    final colorScheme = brightness == Brightness.dark
        ? ColorScheme.dark(
            primary: primaryColor,
            secondary: secondaryColor,
            tertiary: tertiaryColor,
            surface: surfaceColor,
            onPrimary: Colors.white,
            onSecondary: Colors.black,
            onTertiary: Colors.black,
            onSurface: foregroundColor,
            surfaceContainerHighest: surfaceVariantColor,
            onSurfaceVariant: textSecondary,
            outline: outlineColor,
            shadow: shadowColor,
            error: errorColor,
            onError: Colors.white,
          )
        : ColorScheme.light(
            primary: primaryColor,
            secondary: secondaryColor,
            tertiary: tertiaryColor,
            surface: surfaceColor,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onTertiary: Colors.black,
            onSurface: foregroundColor,
            surfaceContainerHighest: surfaceVariantColor,
            onSurfaceVariant: textSecondary,
            outline: outlineColor,
            shadow: shadowColor,
            error: errorColor,
            onError: Colors.white,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      canvasColor: scaffoldBackgroundColor,
      cardColor: surfaceColor,
      dividerColor: outlineColor,
      focusColor: primaryColor,
      hoverColor: primaryColor.withValues(alpha: 0.08),
      splashColor: primaryColor.withValues(alpha: 0.12),
      highlightColor: primaryColor.withValues(alpha: 0.08),
      iconTheme: IconThemeData(color: foregroundColor),
      textTheme: textTheme,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withValues(alpha: 0.24),
        selectionHandleColor: primaryColor,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: appBarCenterTitle,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: appBarForegroundColor,
        iconTheme: IconThemeData(color: appBarForegroundColor),
        titleTextStyle: AppTextStyles.title(color: appBarForegroundColor),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        shadowColor: shadowColor,
        elevation: brightness == Brightness.dark ? 1.5 : 1,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? AppColors.surfaceElevated
            : const Color(0xFFF7F8FC),
        contentPadding: AppSpacing.input,
        border: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: outlineColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: outlineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: primaryColor, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: errorColor, width: 1.4),
        ),
        labelStyle: AppTextStyles.body(color: textSecondary),
        hintStyle: AppTextStyles.body(color: textMuted),
        helperStyle: AppTextStyles.caption(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: shadowColor,
          padding: AppSpacing.button,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: AppTextStyles.button(color: Colors.white),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: AppSpacing.button,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: AppTextStyles.button(color: primaryColor),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: outlineColor),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          foregroundColor: foregroundColor,
          padding: AppSpacing.button,
          textStyle: AppTextStyles.button(color: foregroundColor),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        side: BorderSide(color: outlineColor),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: outlineColor,
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: brightness == Brightness.dark
            ? AppColors.surfaceRaised
            : AppColors.authText,
        contentTextStyle: AppTextStyles.body(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        modalBackgroundColor: surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: outlineColor.withValues(alpha: 0.35),
        circularTrackColor: outlineColor.withValues(alpha: 0.25),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        focusElevation: 6,
      ),
    );
  }
}
