import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Material 3 Expressive Shape Scale & Dimensions
/// Provides standard M3 Expressive corner radiuses, squircle scales, and stadium capsules.
class M3Shapes {
  const M3Shapes._();

  /// 4dp - Micro tags, tiny badges, small indicators
  static const double extraSmall = 4.0;
  static final BorderRadius extraSmallRadius = BorderRadius.circular(extraSmall);
  static final ShapeBorder extraSmallShape = RoundedRectangleBorder(borderRadius: extraSmallRadius);

  /// 8dp - Micro chips, mini status indicators
  static const double small = 8.0;
  static final BorderRadius smallRadius = BorderRadius.circular(small);
  static final ShapeBorder smallShape = RoundedRectangleBorder(borderRadius: smallRadius);

  /// 12dp - Secondary list items, inner modal buttons
  static const double medium = 12.0;
  static final BorderRadius mediumRadius = BorderRadius.circular(medium);
  static final ShapeBorder mediumShape = RoundedRectangleBorder(borderRadius: mediumRadius);

  /// 16dp - Squircle icon badges, dialogs, inner action cards
  static const double large = 16.0;
  static final BorderRadius largeRadius = BorderRadius.circular(large);
  static final ShapeBorder largeShape = RoundedRectangleBorder(borderRadius: largeRadius);

  /// 24dp - Material 3 Expressive Squircle Cards (Hub Cards, Peer Cards, News)
  static const double card = 24.0;
  static final BorderRadius cardRadius = BorderRadius.circular(card);
  static final ShapeBorder cardShape = RoundedRectangleBorder(borderRadius: cardRadius);

  /// 28dp - Material 3 Expressive Sheet & Panel Radius
  static const double extraLarge = 28.0;
  static final BorderRadius extraLargeRadius = BorderRadius.circular(extraLarge);
  static final ShapeBorder extraLargeShape = RoundedRectangleBorder(borderRadius: extraLargeRadius);

  /// 32dp - Material 3 Expressive Hero Containers (Attendance Hero, Profile Header)
  static const double hero = 32.0;
  static final BorderRadius heroRadius = BorderRadius.circular(hero);
  static final ShapeBorder heroShape = RoundedRectangleBorder(borderRadius: heroRadius);

  /// 999dp - Capsule / Stadium pill shapes (bottom nav dock, search bar, filter chips, action pills)
  static const double full = 999.0;
  static final BorderRadius fullRadius = BorderRadius.circular(full);
  static const ShapeBorder fullShape = StadiumBorder();
}

/// Material 3 Expressive Typography Scale
/// Uses Roboto Flex variable font with expressive weights and optical sizing.
class M3Typography {
  const M3Typography._();

  static TextTheme createTextTheme({required Color textColor, required Color subColor}) {
    final base = GoogleFonts.robotoFlexTextTheme();
    return base.copyWith(
      // Display
      displayLarge: GoogleFonts.robotoFlex(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: textColor,
        height: 1.12,
      ),
      displayMedium: GoogleFonts.robotoFlex(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: textColor,
        height: 1.16,
      ),
      displaySmall: GoogleFonts.robotoFlex(
        fontSize: 36,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: textColor,
        height: 1.22,
      ),

      // Headline
      headlineLarge: GoogleFonts.robotoFlex(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: textColor,
        height: 1.25,
      ),
      headlineMedium: GoogleFonts.robotoFlex(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: textColor,
        height: 1.29,
      ),
      headlineSmall: GoogleFonts.robotoFlex(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: textColor,
        height: 1.33,
      ),

      // Title
      titleLarge: GoogleFonts.robotoFlex(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: textColor,
        height: 1.27,
      ),
      titleMedium: GoogleFonts.robotoFlex(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: textColor,
        height: 1.5,
      ),
      titleSmall: GoogleFonts.robotoFlex(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: textColor,
        height: 1.43,
      ),

      // Body
      bodyLarge: GoogleFonts.robotoFlex(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: textColor,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.robotoFlex(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: textColor.withValues(alpha: 0.85),
        height: 1.43,
      ),
      bodySmall: GoogleFonts.robotoFlex(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: subColor,
        height: 1.33,
      ),

      // Label
      labelLarge: GoogleFonts.robotoFlex(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: textColor,
        height: 1.43,
      ),
      labelMedium: GoogleFonts.robotoFlex(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: textColor,
        height: 1.33,
      ),
      labelSmall: GoogleFonts.robotoFlex(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: subColor,
        height: 1.45,
      ),
    );
  }
}

/// Helper class to create M3 ColorScheme and ThemeData with M3 Expressive aesthetics.
class M3ThemeFactory {
  const M3ThemeFactory._();

  /// Minimalist Monochrome Dark primary seed color for Utopia
  static const Color monochromeSeed = Color(0xFFFFFFFF);

  /// Generates full M3 ColorScheme from a seed color with proper light & dark surface tiers.
  static ColorScheme createColorScheme({
    required Color seedColor,
    required bool isDark,
    Color? surfaceBackground,
    Color? customSurface,
    Color? customCard,
    Color? customPrimary,
    Color? customSecondary,
    Color? customText,
    Color? customSub,
  }) {
    final base = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );

    final effectivePrimary = customPrimary ?? seedColor;
    final effectiveSecondary = customSecondary ?? seedColor;
    final effectiveSurface = surfaceBackground ??
        (isDark ? const Color(0xFF09090B) : const Color(0xFFFFF8F6));
    final effectiveText = customText ??
        (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1C1B1F));
    final effectiveSub = customSub ??
        (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF49454F));

    final onPrimary = ThemeData.estimateBrightnessForColor(effectivePrimary) == Brightness.dark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF000000);
    final onSecondary = ThemeData.estimateBrightnessForColor(effectiveSecondary) == Brightness.dark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF000000);

    final primaryContainer = isDark
        ? const Color(0xFF27272A)
        : Color.lerp(effectivePrimary, Colors.white, 0.85)!;
    final onPrimaryContainer = isDark
        ? const Color(0xFFFFFFFF)
        : Color.lerp(effectivePrimary, Colors.black, 0.45)!;

    final secondaryContainer = isDark
        ? const Color(0xFF18181B)
        : Color.lerp(effectiveSecondary, Colors.white, 0.88)!;
    final onSecondaryContainer = isDark
        ? const Color(0xFFE4E4E7)
        : Color.lerp(effectiveSecondary, Colors.black, 0.45)!;

    // Surface container elevation steps for Material 3
    final surfaceContainerLowest = isDark
        ? (surfaceBackground ?? const Color(0xFF000000))
        : const Color(0xFFFFFFFF);
    final surfaceContainerLow = customSurface ??
        (isDark ? const Color(0xFF121214) : Color.lerp(effectiveSurface, Colors.black, 0.02)!);
    final surfaceContainer = customCard ??
        (isDark ? const Color(0xFF18181B) : Color.lerp(effectiveSurface, Colors.black, 0.04)!);
    final surfaceContainerHigh = isDark
        ? const Color(0xFF27272A)
        : Color.lerp(effectiveSurface, Colors.black, 0.06)!;
    final surfaceContainerHighest = isDark
        ? const Color(0xFF3F3F46)
        : Color.lerp(effectiveSurface, Colors.black, 0.09)!;

    final outlineVariant = isDark
        ? const Color(0xFF27272A)
        : Color.lerp(effectiveSurface, Colors.black, 0.12)!;
    final outline = isDark
        ? const Color(0xFF3F3F46)
        : Color.lerp(effectiveSurface, Colors.black, 0.25)!;

    return base.copyWith(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: effectivePrimary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: effectiveSecondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      surface: effectiveSurface,
      onSurface: effectiveText,
      onSurfaceVariant: effectiveSub,
      surfaceDim: surfaceContainerLowest,
      surfaceBright: surfaceContainerHigh,
      surfaceContainerLowest: surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest,
      outline: outline,
      outlineVariant: outlineVariant,
    );
  }

  /// Builds a complete Material 3 ThemeData matching the exact Interceptor style.
  static ThemeData createThemeData({
    required ColorScheme colorScheme,
    required Color text,
    required Color sub,
    required Color border,
  }) {
    final cs = colorScheme;
    final textTheme = GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
        displaySmall: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
        headlineLarge: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
        headlineSmall: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
        titleLarge: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: cs.onSurface, height: 1.6),
        bodyMedium: TextStyle(color: cs.onSurface, height: 1.5),
        bodySmall: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
        labelLarge: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: cs.onSurfaceVariant),
        labelSmall: TextStyle(color: cs.onSurfaceVariant),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: cs.brightness,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surfaceContainerLowest,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: cs.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      cardTheme: CardThemeData(
        color: cs.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.outline),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHigh,
        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cs.surfaceContainerLow,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurfaceVariant,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 0.5,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        disabledElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainerLow,
        selectedColor: cs.primaryContainer,
        labelStyle: TextStyle(color: cs.onSurface, fontSize: 13),
        side: BorderSide(color: cs.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cs.inverseSurface,
        contentTextStyle: GoogleFonts.inter(
          color: cs.onInverseSurface,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      iconTheme: IconThemeData(color: cs.onSurfaceVariant),
    );
  }
}
