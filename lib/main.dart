import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';

import 'services/cache_service.dart';
import 'services/chat_service.dart';
import 'services/notification_service.dart';
import 'services/platform_support.dart';
import 'screens/app_shell.dart';
import 'screens/join_class_screen.dart';
import 'screens/university_selection_screen.dart';
import 'services/focus_supabase_service.dart';
import 'services/university_service.dart';
import 'models/university_model.dart';

import 'screens/event_details_screen.dart';
import 'services/event_service.dart';
import 'theme/m3_expressive_theme.dart';
import 'services/ads/app_open_ad_manager.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late final Future<AppInitializationState> appInitialization;
SupabaseClient get supabase => Supabase.instance.client;

class AppInitializationState {
  const AppInitializationState({
    required this.firebaseReady,
    this.blockingMessage,
  });

  final bool firebaseReady;
  final String? blockingMessage;
}

class AppTheme {
  const AppTheme({
    required this.key,
    required this.accentId,
    required this.label,
    required this.description,
    required this.colorScheme,
    required this.mermaidPrimary,
    required this.mermaidBackground,
    required this.mermaidLine,
  });

  final String key;
  final String accentId;
  final String label;
  final String description;
  final ColorScheme colorScheme;
  final String mermaidPrimary;
  final String mermaidBackground;
  final String mermaidLine;

  bool get isDark => colorScheme.brightness == Brightness.dark;
  Color get bg => colorScheme.surfaceContainerLowest;
  Color get surface => colorScheme.surfaceContainerLow;
  Color get card => colorScheme.surfaceContainer;
  Color get border => colorScheme.outlineVariant;
  Color get text => colorScheme.onSurface;
  Color get sub => colorScheme.onSurfaceVariant;
  Color get dim => colorScheme.outline;
  Color get primary => colorScheme.primary;
  Color get teal => colorScheme.tertiary;
  Color get red => colorScheme.error;
  Color get green => isDark ? const Color(0xFF66DBA4) : const Color(0xFF006C45);
  Color get peach => colorScheme.tertiary;
  Color get blue => isDark ? const Color(0xFF82CFFF) : const Color(0xFF006594);
  Color get gold => isDark ? const Color(0xFFE7C349) : const Color(0xFF715C00);
  Color get sky => isDark ? const Color(0xFFA4CDDE) : const Color(0xFF3C6473);
  Color get lavender => colorScheme.primary;
  Color get gray => colorScheme.onSurfaceVariant;

  Color get mdH1 => colorScheme.onSurface;
  Color get mdH2 => colorScheme.onSurface;
  Color get mdH3 => colorScheme.onSurfaceVariant;
  Color get mdBold => colorScheme.primary;
  Color get mdItalic => colorScheme.tertiary;
  Color get mdCode => colorScheme.primary;
  Color get mdLink => colorScheme.primary;
  Color get mdBlockquote => colorScheme.onSurfaceVariant;
  Color get mdDel => colorScheme.outline;
}

// ─────────────────────────────────────────────────────────────────────────────
// Exact Interceptor Material 3 Token Themes (5 accents × Dark & Light)
// ─────────────────────────────────────────────────────────────────────────────

const _interceptorDefaultDark = AppTheme(
  key: 'interceptor-default-dark',
  accentId: 'default',
  label: 'Default',
  description: 'Canonical Material 3 dark',
  mermaidPrimary: '#D0BCFF',
  mermaidBackground: '#211F26',
  mermaidLine: '#E6E1E5',
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFD0BCFF),
    onPrimary: Color(0xFF381E72),
    primaryContainer: Color(0xFF4F378B),
    onPrimaryContainer: Color(0xFFEADDFF),
    secondary: Color(0xFFCCC2DC),
    onSecondary: Color(0xFF332D41),
    secondaryContainer: Color(0xFF4A4458),
    onSecondaryContainer: Color(0xFFE8DEF8),
    tertiary: Color(0xFFEFB8C8),
    onTertiary: Color(0xFF492532),
    tertiaryContainer: Color(0xFF633B48),
    onTertiaryContainer: Color(0xFFFFD8E4),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    surface: Color(0xFF141218),
    onSurface: Color(0xFFE6E1E5),
    onSurfaceVariant: Color(0xFFCAC4D0),
    surfaceDim: Color(0xFF141218),
    surfaceBright: Color(0xFF3B383E),
    surfaceContainerLowest: Color(0xFF0F0D13),
    surfaceContainerLow: Color(0xFF1D1B20),
    surfaceContainer: Color(0xFF211F26),
    surfaceContainerHigh: Color(0xFF2B2930),
    surfaceContainerHighest: Color(0xFF36343B),
    outline: Color(0xFF938F99),
    outlineVariant: Color(0xFF49454F),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFE6E1E5),
    onInverseSurface: Color(0xFF313033),
    inversePrimary: Color(0xFF6750A4),
  ),
);

const _interceptorDefaultLight = AppTheme(
  key: 'interceptor-default-light',
  accentId: 'default',
  label: 'Default',
  description: 'Canonical Material 3 light',
  mermaidPrimary: '#6750A4',
  mermaidBackground: '#F3EDF7',
  mermaidLine: '#1D1B20',
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF6750A4),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFEADDFF),
    onPrimaryContainer: Color(0xFF21005D),
    secondary: Color(0xFF625B71),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE8DEF8),
    onSecondaryContainer: Color(0xFF1D192B),
    tertiary: Color(0xFF7D5260),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFD8E4),
    onTertiaryContainer: Color(0xFF31111D),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFFEF7FF),
    onSurface: Color(0xFF1D1B20),
    onSurfaceVariant: Color(0xFF49454F),
    surfaceDim: Color(0xFFDED8E1),
    surfaceBright: Color(0xFFFEF7FF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF7F2FA),
    surfaceContainer: Color(0xFFF3EDF7),
    surfaceContainerHigh: Color(0xFFECE6F0),
    surfaceContainerHighest: Color(0xFFE6E0E9),
    outline: Color(0xFF79747E),
    outlineVariant: Color(0xFFCAC4D0),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFF313033),
    onInverseSurface: Color(0xFFF4EFF4),
    inversePrimary: Color(0xFFD0BCFF),
  ),
);

const _interceptorEmeraldDark = AppTheme(
  key: 'interceptor-emerald-dark',
  accentId: 'emerald',
  label: 'Emerald Forest',
  description: 'Organic botanical dark',
  mermaidPrimary: '#66DBA4',
  mermaidBackground: '#162A1F',
  mermaidLine: '#E0EBE3',
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF66DBA4),
    onPrimary: Color(0xFF003822),
    primaryContainer: Color(0xFF005234),
    onPrimaryContainer: Color(0xFF84F8BF),
    secondary: Color(0xFFB3CCBB),
    onSecondary: Color(0xFF1F3529),
    secondaryContainer: Color(0xFF354C3E),
    onSecondaryContainer: Color(0xFFCFE8D7),
    tertiary: Color(0xFFA4CDDE),
    onTertiary: Color(0xFF063543),
    tertiaryContainer: Color(0xFF234C5A),
    onTertiaryContainer: Color(0xFFC0E9FA),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF09160F),
    onSurface: Color(0xFFE0EBE3),
    onSurfaceVariant: Color(0xFFBFC9C1),
    surfaceDim: Color(0xFF09160F),
    surfaceBright: Color(0xFF334338),
    surfaceContainerLowest: Color(0xFF050E09),
    surfaceContainerLow: Color(0xFF102017),
    surfaceContainer: Color(0xFF162A1F),
    surfaceContainerHigh: Color(0xFF1E3527),
    surfaceContainerHighest: Color(0xFF284132),
    outline: Color(0xFF8A938C),
    outlineVariant: Color(0xFF404943),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFE0EBE3),
    onInverseSurface: Color(0xFF2B332D),
    inversePrimary: Color(0xFF006C45),
  ),
);

const _interceptorEmeraldLight = AppTheme(
  key: 'interceptor-emerald-light',
  accentId: 'emerald',
  label: 'Emerald Forest',
  description: 'Organic botanical light',
  mermaidPrimary: '#006C45',
  mermaidBackground: '#E4EFE7',
  mermaidLine: '#161D18',
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF006C45),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF84F8BF),
    onPrimaryContainer: Color(0xFF002113),
    secondary: Color(0xFF4C6354),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFCFE8D7),
    onSecondaryContainer: Color(0xFF092014),
    tertiary: Color(0xFF3C6473),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFC0E9FA),
    onTertiaryContainer: Color(0xFF001F29),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFF4FAF5),
    onSurface: Color(0xFF161D18),
    onSurfaceVariant: Color(0xFF404943),
    surfaceDim: Color(0xFFD5E1D9),
    surfaceBright: Color(0xFFF4FAF5),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFECF5EE),
    surfaceContainer: Color(0xFFE4EFE7),
    surfaceContainerHigh: Color(0xFFDDE8E0),
    surfaceContainerHighest: Color(0xFFD5E1D9),
    outline: Color(0xFF707972),
    outlineVariant: Color(0xFFBFC9C1),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFF2B332D),
    onInverseSurface: Color(0xFFECF3EC),
    inversePrimary: Color(0xFF66DBA4),
  ),
);

const _interceptorCrimsonDark = AppTheme(
  key: 'interceptor-crimson-dark',
  accentId: 'crimson',
  label: 'Crimson Bloom',
  description: 'Expressive magenta dark',
  mermaidPrimary: '#FFB1C8',
  mermaidBackground: '#2D1220',
  mermaidLine: '#FCE9EE',
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFB1C8),
    onPrimary: Color(0xFF5E1133),
    primaryContainer: Color(0xFF7B2949),
    onPrimaryContainer: Color(0xFFFFD9E2),
    secondary: Color(0xFFE5BDC6),
    onSecondary: Color(0xFF432931),
    secondaryContainer: Color(0xFF5C3F47),
    onSecondaryContainer: Color(0xFFFFD9E2),
    tertiary: Color(0xFFF4B79E),
    onTertiary: Color(0xFF4B2717),
    tertiaryContainer: Color(0xFF653D2B),
    onTertiaryContainer: Color(0xFFFFDBCE),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF1A0812),
    onSurface: Color(0xFFFCE9EE),
    onSurfaceVariant: Color(0xFFD5C1C6),
    surfaceDim: Color(0xFF1A0812),
    surfaceBright: Color(0xFF431D2E),
    surfaceContainerLowest: Color(0xFF12030B),
    surfaceContainerLow: Color(0xFF230D19),
    surfaceContainer: Color(0xFF2D1220),
    surfaceContainerHigh: Color(0xFF381829),
    surfaceContainerHighest: Color(0xFF451F33),
    outline: Color(0xFF9E8C91),
    outlineVariant: Color(0xFF524347),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFFCE9EE),
    onInverseSurface: Color(0xFF38292D),
    inversePrimary: Color(0xFF984061),
  ),
);

const _interceptorCrimsonLight = AppTheme(
  key: 'interceptor-crimson-light',
  accentId: 'crimson',
  label: 'Crimson Bloom',
  description: 'Expressive magenta light',
  mermaidPrimary: '#984061',
  mermaidBackground: '#F9E8EC',
  mermaidLine: '#22191C',
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF984061),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFD9E2),
    onPrimaryContainer: Color(0xFF3E001D),
    secondary: Color(0xFF74565F),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFD9E2),
    onSecondaryContainer: Color(0xFF2B151C),
    tertiary: Color(0xFF805642),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFDBCE),
    onTertiaryContainer: Color(0xFF321406),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFFF8F8),
    onSurface: Color(0xFF22191C),
    onSurfaceVariant: Color(0xFF524347),
    surfaceDim: Color(0xFFEED9DF),
    surfaceBright: Color(0xFFFFF8F8),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFDF0F2),
    surfaceContainer: Color(0xFFF9E8EC),
    surfaceContainerHigh: Color(0xFFF4E0E5),
    surfaceContainerHighest: Color(0xFFEED9DF),
    outline: Color(0xFF847377),
    outlineVariant: Color(0xFFD5C1C6),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFF38292D),
    onInverseSurface: Color(0xFFFAEEF1),
    inversePrimary: Color(0xFFFFB1C8),
  ),
);

const _interceptorAmberDark = AppTheme(
  key: 'interceptor-amber-dark',
  accentId: 'amber',
  label: 'Solar Amber',
  description: 'Warm honey ochre dark',
  mermaidPrimary: '#E7C349',
  mermaidBackground: '#282213',
  mermaidLine: '#EBE6D9',
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFE7C349),
    onPrimary: Color(0xFF3C2F00),
    primaryContainer: Color(0xFF574500),
    onPrimaryContainer: Color(0xFFFFE171),
    secondary: Color(0xFFD2C6A1),
    onSecondary: Color(0xFF373016),
    secondaryContainer: Color(0xFF4E462A),
    onSecondaryContainer: Color(0xFFEFE2BC),
    tertiary: Color(0xFFA9D0B4),
    onTertiary: Color(0xFF143724),
    tertiaryContainer: Color(0xFF2C4E39),
    onTertiaryContainer: Color(0xFFC5ECCF),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF161208),
    onSurface: Color(0xFFEBE6D9),
    onSurfaceVariant: Color(0xFFCBC6B4),
    surfaceDim: Color(0xFF161208),
    surfaceBright: Color(0xFF3F3725),
    surfaceContainerLowest: Color(0xFF0F0C04),
    surfaceContainerLow: Color(0xFF1F1A0D),
    surfaceContainer: Color(0xFF282213),
    surfaceContainerHigh: Color(0xFF332C1B),
    surfaceContainerHighest: Color(0xFF3F3725),
    outline: Color(0xFF959080),
    outlineVariant: Color(0xFF4A4639),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFEBE6D9),
    onInverseSurface: Color(0xFF333027),
    inversePrimary: Color(0xFF715C00),
  ),
);

const _interceptorAmberLight = AppTheme(
  key: 'interceptor-amber-light',
  accentId: 'amber',
  label: 'Solar Amber',
  description: 'Warm honey ochre light',
  mermaidPrimary: '#715C00',
  mermaidBackground: '#F4F0E4',
  mermaidLine: '#1E1C15',
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF715C00),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFE171),
    onPrimaryContainer: Color(0xFF221B00),
    secondary: Color(0xFF665E40),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFEFE2BC),
    onSecondaryContainer: Color(0xFF211B04),
    tertiary: Color(0xFF436650),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFC5ECCF),
    onTertiaryContainer: Color(0xFF002110),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFFFDF6),
    onSurface: Color(0xFF1E1C15),
    onSurfaceVariant: Color(0xFF4A4639),
    surfaceDim: Color(0xFFE9E4D9),
    surfaceBright: Color(0xFFFFFDF6),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFAF6EB),
    surfaceContainer: Color(0xFFF4F0E4),
    surfaceContainerHigh: Color(0xFFEFEADF),
    surfaceContainerHighest: Color(0xFFE9E4D9),
    outline: Color(0xFF7B7768),
    outlineVariant: Color(0xFFCBC6B4),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFF333027),
    onInverseSurface: Color(0xFFF7F2E6),
    inversePrimary: Color(0xFFE7C349),
  ),
);

const _interceptorCobaltDark = AppTheme(
  key: 'interceptor-cobalt-dark',
  accentId: 'cobalt',
  label: 'Electric Cobalt',
  description: 'High-tech oceanic dark',
  mermaidPrimary: '#82CFFF',
  mermaidBackground: '#122035',
  mermaidLine: '#DEE4EB',
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF82CFFF),
    onPrimary: Color(0xFF00344F),
    primaryContainer: Color(0xFF004C71),
    onPrimaryContainer: Color(0xFFC8E6FF),
    secondary: Color(0xFFB6C9D8),
    onSecondary: Color(0xFF20333E),
    secondaryContainer: Color(0xFF374955),
    onSecondaryContainer: Color(0xFFD1E5F4),
    tertiary: Color(0xFFCEBEE3),
    onTertiary: Color(0xFF352B46),
    tertiaryContainer: Color(0xFF4C415E),
    onTertiaryContainer: Color(0xFFEADDFE),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF070E18),
    onSurface: Color(0xFFDEE4EB),
    onSurfaceVariant: Color(0xFFC0C8CF),
    surfaceDim: Color(0xFF070E18),
    surfaceBright: Color(0xFF2B3A4F),
    surfaceContainerLowest: Color(0xFF03070E),
    surfaceContainerLow: Color(0xFF0C1625),
    surfaceContainer: Color(0xFF122035),
    surfaceContainerHigh: Color(0xFF192B44),
    surfaceContainerHighest: Color(0xFF223755),
    outline: Color(0xFF8A9299),
    outlineVariant: Color(0xFF40484F),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFDEE4EB),
    onInverseSurface: Color(0xFF28313A),
    inversePrimary: Color(0xFF006594),
  ),
);

const _interceptorCobaltLight = AppTheme(
  key: 'interceptor-cobalt-light',
  accentId: 'cobalt',
  label: 'Electric Cobalt',
  description: 'High-tech oceanic light',
  mermaidPrimary: '#006594',
  mermaidBackground: '#E5EEF4',
  mermaidLine: '#161D22',
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF006594),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFC8E6FF),
    onPrimaryContainer: Color(0xFF001E30),
    secondary: Color(0xFF4F616D),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD1E5F4),
    onSecondaryContainer: Color(0xFF0A1D28),
    tertiary: Color(0xFF645877),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFEADDFE),
    onTertiaryContainer: Color(0xFF201631),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFF6FAFE),
    onSurface: Color(0xFF161D22),
    onSurfaceVariant: Color(0xFF40484F),
    surfaceDim: Color(0xFFD7E3EA),
    surfaceBright: Color(0xFFF6FAFE),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFEEF4F9),
    surfaceContainer: Color(0xFFE5EEF4),
    surfaceContainerHigh: Color(0xFFDFE8EF),
    surfaceContainerHighest: Color(0xFFD7E3EA),
    outline: Color(0xFF707880),
    outlineVariant: Color(0xFFC0C8CF),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFF28313A),
    onInverseSurface: Color(0xFFEDF2F8),
    inversePrimary: Color(0xFF82CFFF),
  ),
);

const appThemes = [
  _interceptorDefaultDark,
  _interceptorEmeraldDark,
  _interceptorCrimsonDark,
  _interceptorAmberDark,
  _interceptorCobaltDark,
  _interceptorDefaultLight,
  _interceptorEmeraldLight,
  _interceptorCrimsonLight,
  _interceptorAmberLight,
  _interceptorCobaltLight,
];

final ValueNotifier<AppTheme> appThemeNotifier = ValueNotifier<AppTheme>(
  _interceptorDefaultDark,
);


final ValueNotifier<bool> morningNotifEnabledNotifier = ValueNotifier<bool>(true);
final ValueNotifier<int> appLoadingCounter = ValueNotifier<int>(0);

void _applySystemUiForTheme(AppTheme theme) {
  final isDark = theme.isDark;
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: theme.bg,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );
}

void showAppLoading() {
  appLoadingCounter.value = appLoadingCounter.value + 1;
}

void hideAppLoading() {
  if (appLoadingCounter.value > 0) {
    appLoadingCounter.value = appLoadingCounter.value - 1;
  }
}

class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: appLoadingCounter,
      builder: (context, count, _) {
        return Stack(
          children: [
            child,
            if (count > 0)
              Positioned.fill(
                child: Container(
                  color: U.bg.withValues(alpha: 0.85),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: U.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: U.border),
                        boxShadow: [
                          BoxShadow(
                            color: U.primary.withValues(alpha: 0.15),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: U.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading...',
                            style: GoogleFonts.outfit(
                              color: U.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class AppAccentStyle {
  const AppAccentStyle({
    required this.key,
    required this.label,
    required this.primary,
  });

  final String key;
  final String label;
  final Color primary;
}

Future<AppInitializationState> _initializeApp() async {
  if (PlatformSupport.isWindows) {
    return const AppInitializationState(
      firebaseReady: false,
      blockingMessage:
          'Windows support is only partially configured. Add a Windows Firebase app and a desktop authentication flow before signing in on Windows.',
    );
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (PlatformSupport.supportsNotifications) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      unawaited(NotificationService.initialize());
    }

    // Cache current user identity for background notification actions
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (user != null) {
          await prefs.setString('current_user_uid', user.uid);
          if (user.displayName != null && user.displayName!.isNotEmpty) {
            await prefs.setString('current_user_name', user.displayName!);
          }
        }
      } catch (_) {}
    });

    // Initialize global Supabase in the background (used by notes, events, etc.)
    unawaited(() async {
      try {
        final doc = await FirebaseFirestore.instance.collection('config').doc('supabase').get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final url = data['url'] as String?;
          final anonKey = data['anon_key'] as String?;
          if (url != null && anonKey != null) {
            await Supabase.initialize(url: url, anonKey: anonKey);
            debugPrint('Supabase Init: Initialized global Supabase with URL: $url');
          } else {
            debugPrint('Supabase config missing url or anon_key');
          }
        } else {
          debugPrint('Supabase config document not found');
        }
      } catch (e) {
        debugPrint('Failed to initialize Supabase: $e');
      }
    }());

    // Initialize Focus Supabase in the background
    unawaited(FocusSupabaseService().initialize());

    return const AppInitializationState(firebaseReady: true);
  } catch (e) {
    debugPrint('Firebase init error: $e');
    return AppInitializationState(
      firebaseReady: false,
      blockingMessage:
          'Firebase failed to initialize: $e',
    );
  }
}

String? _initialAccentKey;

Future<String?> _loadInitialAccent() async {
  final cached = await CacheService().getAppSetting('theme_accent');
  return cached;
}

Future<void> _loadAppToggleSettings() async {

  final cachedMorning = await CacheService().getAppSetting('morning_notif_enabled');
  if (cachedMorning != null) {
    morningNotifEnabledNotifier.value = cachedMorning == 'true';
  }

  final cachedUniId = await CacheService().getAppSetting('cached_university_id');
  if (cachedUniId != null) {
    U.cachedUniversityId = cachedUniId;
  }
  final cachedUniName = await CacheService().getAppSetting('cached_university_name');
  if (cachedUniName != null) {
    U.cachedUniversityName = cachedUniName;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite FFI for desktop platforms
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Kick off Firebase & backend init immediately in parallel with local prefs
  appInitialization = _initializeApp();

  // Initialize AdMob asynchronously so it never slows down app startup
  if (AppOpenAdManager.isSupported) {
    unawaited(() async {
      try {
        await MobileAds.instance.initialize();
      } catch (e) {
        debugPrint('[Ads] SDK init failed: $e');
      }
      await AppOpenAdManager.instance.bootstrap();
    }());
  }

  await Future.wait([
    () async {
      try {
        _initialAccentKey = await _loadInitialAccent();
        U.applyTheme(_initialAccentKey);
      } catch (e) {
        debugPrint('Failed to load initial accent: $e');
      }
    }(),
    () async {
      try {
        await _loadAppToggleSettings();
      } catch (e) {
        debugPrint('Failed to load app toggle settings: $e');
      }
    }(),
  ]);

  if (!kIsWeb) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
  _applySystemUiForTheme(appThemeNotifier.value);
  runApp(const UtopiaApp());
}

class U {
  static String cachedUniversityId = '';
  static String cachedUniversityName = '';

  static bool get isAditya => isAdityaCollege(cachedUniversityId, cachedUniversityName);

  static bool isAdityaCollege([String? id, String? name]) {
    final checkId = (id ?? cachedUniversityId).trim().toLowerCase();
    final checkName = (name ?? cachedUniversityName).trim().toLowerCase();
    return checkId.contains('aditya') || checkName.contains('aditya');
  }

  static ColorScheme get colorScheme => appThemeNotifier.value.colorScheme;
  static ColorScheme scheme(BuildContext context) => Theme.of(context).colorScheme;

  static Color get bg => appThemeNotifier.value.bg;
  static Color get surface => appThemeNotifier.value.surface;
  static Color get card => appThemeNotifier.value.card;
  static Color get border => appThemeNotifier.value.border;
  static Color get text => appThemeNotifier.value.text;
  static Color get sub => appThemeNotifier.value.sub;
  static Color get dim => appThemeNotifier.value.dim;
  static Color get primary => appThemeNotifier.value.primary;
  static Color get teal => appThemeNotifier.value.teal;
  static Color get red => appThemeNotifier.value.red;
  static Color get green => appThemeNotifier.value.green;
  static Color get peach => appThemeNotifier.value.peach;
  static Color get blue => appThemeNotifier.value.blue;
  static Color get gold => appThemeNotifier.value.gold;
  static Color get sky => appThemeNotifier.value.sky;
  static Color get lavender => appThemeNotifier.value.lavender;
  static Color get gray => appThemeNotifier.value.gray;

  static Color get surfaceContainerLowest => appThemeNotifier.value.colorScheme.surfaceContainerLowest;
  static Color get surfaceContainerLow => appThemeNotifier.value.surface;
  static Color get surfaceContainer => appThemeNotifier.value.card;
  static Color get surfaceContainerHigh => appThemeNotifier.value.colorScheme.surfaceContainerHigh;
  static Color get surfaceContainerHighest => appThemeNotifier.value.colorScheme.surfaceContainerHighest;
  static Color get primaryContainer => appThemeNotifier.value.colorScheme.primaryContainer;
  static Color get onPrimaryContainer => appThemeNotifier.value.colorScheme.onPrimaryContainer;
  static Color get secondaryContainer => appThemeNotifier.value.colorScheme.secondaryContainer;
  static Color get onSecondaryContainer => appThemeNotifier.value.colorScheme.onSecondaryContainer;
  static Color get outlineVariant => appThemeNotifier.value.border;

  static Color getContrastColor(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : const Color(0xFF11140E);
  }

  static Color get mdH1 => appThemeNotifier.value.mdH1;
  static Color get mdH2 => appThemeNotifier.value.mdH2;
  static Color get mdH3 => appThemeNotifier.value.mdH3;
  static Color get mdBold => appThemeNotifier.value.mdBold;
  static Color get mdItalic => appThemeNotifier.value.mdItalic;
  static Color get mdCode => appThemeNotifier.value.mdCode;
  static Color get mdLink => appThemeNotifier.value.mdLink;
  static Color get mdBlockquote => appThemeNotifier.value.mdBlockquote;
  static Color get mdDel => appThemeNotifier.value.mdDel;

  static String get mermaidPrimary => appThemeNotifier.value.mermaidPrimary;
  static String get mermaidBackground =>
      appThemeNotifier.value.mermaidBackground;
  static String get mermaidLine => appThemeNotifier.value.mermaidLine;

  static String get currentThemeKey => appThemeNotifier.value.key;


  static bool get morningNotifEnabled => morningNotifEnabledNotifier.value;

  static List<AppTheme> themesForBrightness(bool isDark) {
    return appThemes.where((t) => t.isDark == isDark).toList();
  }

  static String counterpartKey(String key, bool targetIsDark) {
    final current = themeForKey(key);
    for (final theme in appThemes) {
      if (theme.accentId == current.accentId && theme.isDark == targetIsDark) {
        return theme.key;
      }
    }
    return targetIsDark
        ? _interceptorDefaultDark.key
        : _interceptorDefaultLight.key;
  }

  static AppTheme themeForKey(String? key) {
    for (final theme in appThemes) {
      if (theme.key == key) {
        return theme;
      }
    }
    return _interceptorDefaultDark;
  }

  static void applyTheme(String? key) {
    final next = themeForKey(key);
    appThemeNotifier.value = next;
    _applySystemUiForTheme(next);
    unawaited(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('theme_primary_color_value', next.primary.toARGB32());
      } catch (_) {}
    }());
  }

  static String sanitizeDisplayName(String? name) {
    var clean = (name ?? '').trim();
    if (clean.isEmpty) return 'Student';
    if (clean.contains('@')) {
      final prefix = clean.split('@').first.trim();
      if (prefix.isEmpty) return 'Student';
      clean = prefix.replaceAll('.', ' ').replaceAll('_', ' ');
    }

    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'Student';

    // Deduplicate identical consecutive words (e.g. "25B11CE107 25B11CE107" -> "25B11CE107")
    final deduplicated = <String>[];
    for (final word in words) {
      if (deduplicated.isEmpty || deduplicated.last.toLowerCase() != word.toLowerCase()) {
        deduplicated.add(word);
      }
    }

    return deduplicated.map((word) {
      if (word.length <= 1) return word.toUpperCase();
      // If it looks like a roll number / alphanumeric ID (e.g. 25B11CE107), keep uppercase
      if (RegExp(r'^\d+[a-zA-Z]+\d+').hasMatch(word)) return word.toUpperCase();
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_circle_rounded,
    Color? iconColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E222B).withValues(alpha: 0.94)
                    : const Color(0xFFFFFFFF).withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: iconColor ?? (isDark ? const Color(0xFF08BB68) : const Color(0xFF059669)),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white : const Color(0xFF191C16),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String sanitizeDisplayName(String? name) => U.sanitizeDisplayName(name);

class UtopiaApp extends StatelessWidget {
  const UtopiaApp({super.key});

  static String sanitizeDisplayName(String? name) => U.sanitizeDisplayName(name);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, _) {
        final colorScheme = theme.colorScheme;
        final m3Theme = M3ThemeFactory.createThemeData(
          colorScheme: colorScheme,
          text: theme.text,
          sub: theme.sub,
          border: theme.border,
        );

        return MaterialApp(
          title: 'UTOPIA',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: m3Theme,
          home: const AppLoadingOverlay(child: AuthGate()),
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  final Future<AppInitializationState> _appInit = appInitialization;

  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.setAppForeground(true);

    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.setAppForeground(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    NotificationService.setAppForeground(state == AppLifecycleState.resumed);
    if (state == AppLifecycleState.resumed) {
      unawaited(() async {
        final init = await _appInit;
        if (init.firebaseReady) {
          await ChatService().touchPresence();
        }
      }());
      if (PlatformSupport.supportsNotifications) {
        unawaited(NotificationService.refreshTokenRegistration());
      }
    }
  }



  void _initDeepLinks() {
    final appLinks = AppLinks();
    appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleLink(uri);
    });
    _linkSub = appLinks.uriLinkStream.listen(_handleLink);
  }

  void _handleLink(Uri uri) {
    String? classCode;
    String? eventId;

    // Handle class join links: https://classes.inferalis.space/join/CODE or utopia://join/CODE
    if (uri.path.startsWith('/join/')) {
      classCode = uri.pathSegments.last;
    } else if (uri.scheme == 'utopia' && uri.host == 'join') {
      classCode = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }

    // Handle event links: https://events.inferalis.space/eventID or utopia://event/eventID
    if (uri.host == 'events.inferalis.space' || uri.path.startsWith('/event/')) {
      eventId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
    } else if (uri.scheme == 'utopia' && uri.host == 'event') {
      eventId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    } else if (uri.host == 'events.inferalis.space' && uri.path.isNotEmpty) {
      eventId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }

    if (classCode != null && classCode.isNotEmpty) {
      // Wait for navigator to be ready, then push the join screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final nav = navigatorKey.currentState;
        if (nav != null) {
          nav.push(
            MaterialPageRoute(
              builder: (_) => JoinClassScreen(classCode: classCode!),
            ),
          );
        }
      });
    } else if (eventId != null && eventId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final nav = navigatorKey.currentState;
        if (nav != null) {
          try {
            // Show dynamic feedback/dialog or direct navigation
            final event = await EventService.instance.getEvent(eventId!);
            if (event != null) {
              nav.push(
                MaterialPageRoute(
                  builder: (_) => EventDetailsScreen(event: event),
                ),
              );
            }
          } catch (e) {
            debugPrint('Failed to load deep-linked event: $e');
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppInitializationState>(
      future: _appInit,
      builder: (context, initSnapshot) {
        if (initSnapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }
        final initState =
            initSnapshot.data ??
            const AppInitializationState(firebaseReady: false);
        if (!initState.firebaseReady) {
          return _PlatformSetupScreen(
            message:
                initState.blockingMessage ??
                'This platform is not configured for UTOPIA yet.',
          );
        }


        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }
            if (snapshot.hasData) {
              unawaited(ChatService().touchPresence());
              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(snapshot.data!.uid)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting &&
                      !userSnapshot.hasData &&
                      U.cachedUniversityId.isEmpty) {
                    return const SplashScreen();
                  }

                  final themeAccent =
                      userSnapshot.data?.data()?['themeAccent'] as String?;
                  if (themeAccent != null) {
                    unawaited(
                      CacheService().saveAppSetting(
                        'theme_accent',
                        themeAccent,
                      ),
                    );
                  }

                  final userData = userSnapshot.data?.data();
                  final docUniId = (userData?['selectedUniversityId'] as String? ??
                                   userData?['universityId'] as String? ??
                                   userData?['university'] as String? ??
                                   '').trim();

                  final effectiveUniId = docUniId.isNotEmpty ? docUniId : U.cachedUniversityId.trim();

                  // If no university is selected in Firestore or local cache, prompt selection
                  if (userSnapshot.connectionState == ConnectionState.active && effectiveUniId.isEmpty) {
                    return const UniversitySelectionScreen();
                  }

                  if (effectiveUniId.isNotEmpty) {
                    if (U.cachedUniversityId != effectiveUniId) {
                      U.cachedUniversityId = effectiveUniId;
                      unawaited(CacheService().saveAppSetting('cached_university_id', effectiveUniId));
                    }
                    final docUniName = (userData?['universityName'] as String? ?? '').trim();
                    if (docUniName.isNotEmpty && U.cachedUniversityName != docUniName) {
                      U.cachedUniversityName = docUniName;
                      unawaited(CacheService().saveAppSetting('cached_university_name', docUniName));
                    }
                  }

                  return const AppShell();
                },
              );
            }
            U.applyTheme(null);
            return const LoginScreen();
          },
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: Center(
        child: Text.rich(
          TextSpan(
            text: 'utopia',
            style: GoogleFonts.inter(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.2,
              color: colorScheme.onSurface,
            ),
            children: [
              TextSpan(
                text: '.',
                style: TextStyle(color: colorScheme.primary),
              ),
            ],
          ),
          maxLines: 1,
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;
  int _logoTapCount = 0;
  DateTime? _lastLogoTap;

  Future<void> _signIn() async {
    if (!PlatformSupport.supportsGoogleSignIn) {
      setState(() {
        _error =
            'Google sign-in is not available on Windows in this build. Add a desktop auth flow before shipping the Windows app.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        final credential =
            await FirebaseAuth.instance.signInWithPopup(googleProvider);
        if (credential.user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(credential.user!.uid)
              .set({
            'displayName': credential.user?.displayName ?? '',
            'email': credential.user?.email ?? '',
            'photoUrl': credential.user?.photoURL,
            'lastSeen': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        return;
      }

      await GoogleSignIn.instance.initialize(
        clientId: null,
        serverClientId:
            '402670858978-94eqn0qvvrtv59ijne3hn1g5flr4ahve.apps.googleusercontent.com',
      );
      final user = await GoogleSignIn.instance.authenticate();
      final auth = user.authentication;
      final cred = GoogleAuthProvider.credential(idToken: auth.idToken);
      final credential =
          await FirebaseAuth.instance.signInWithCredential(cred);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user?.uid)
          .set({
        'displayName': credential.user?.displayName ?? '',
        'email': credential.user?.email ?? '',
        'photoUrl': credential.user?.photoURL,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Sign-in error: $e');
      setState(() {
        _error = 'Sign-in error: $e';
        _loading = false;
      });
    }
  }

  void _showAdminLoginDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool dialogLoading = false;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: !_loading,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: U.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Admin Login',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: U.text,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter administrator email and password to log in.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: U.sub,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: U.text),
                    decoration: InputDecoration(
                      hintText: 'Admin Email',
                      hintStyle: TextStyle(color: U.dim),
                      filled: true,
                      fillColor: U.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: U.border, width: 0.8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: U.border, width: 0.8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: U.primary, width: 1.2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: TextStyle(color: U.text),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: TextStyle(color: U.dim),
                      filled: true,
                      fillColor: U.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: U.border, width: 0.8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: U.border, width: 0.8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: U.primary, width: 1.2),
                      ),
                    ),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      dialogError!,
                      style: GoogleFonts.outfit(
                        color: U.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: dialogLoading ? null : () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(
                      color: U.sub,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: dialogLoading
                      ? null
                      : () async {
                          final email = emailController.text.trim();
                          final password = passwordController.text.trim();
                          if (email.isEmpty || password.isEmpty) {
                            setDialogState(() {
                              dialogError = 'Email and password cannot be empty.';
                            });
                            return;
                          }
                          setDialogState(() {
                            dialogLoading = true;
                            dialogError = null;
                          });
                          try {
                            final credential = await FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                              email: email,
                              password: password,
                            );
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(credential.user?.uid)
                                .set({
                              'displayName': credential.user?.displayName ?? email.split('@')[0],
                              'email': credential.user?.email ?? email,
                              'photoUrl': credential.user?.photoURL,
                              'lastSeen': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setDialogState(() {
                                dialogLoading = false;
                                dialogError = 'Login failed: ${e.toString().split(']').last.trim()}';
                              });
                            }
                          }
                        },
                  child: dialogLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: U.primary,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Login',
                          style: GoogleFonts.outfit(
                            color: U.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: U.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 4),
              GestureDetector(
                onTap: () {
                  final now = DateTime.now();
                  if (_lastLogoTap == null || now.difference(_lastLogoTap!) < const Duration(seconds: 2)) {
                    _logoTapCount++;
                  } else {
                    _logoTapCount = 1;
                  }
                  _lastLogoTap = now;

                  if (_logoTapCount >= 5) {
                    _logoTapCount = 0;
                    _showAdminLoginDialog();
                  }
                },
                child: Text(
                  'UTOPIA',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    color: U.primary,
                    fontStyle: FontStyle.italic,
                    height: 1,
                    letterSpacing: -1,
                    shadows: [
                      Shadow(
                        color: U.primary.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.15, end: 0, duration: 600.ms, curve: Curves.easeOut),
              const SizedBox(height: 10),
              Text(
                'The Productivity Platform',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: U.sub,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 600.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.15, end: 0, delay: 200.ms, duration: 600.ms, curve: Curves.easeOut),
              const Spacer(flex: 3),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: U.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: U.red.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _error!,
                    style: GoogleFonts.outfit(
                      color: U.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Animated container for the button state
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: U.primary.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _loading || !PlatformSupport.supportsGoogleSignIn
                      ? null
                      : _signIn,
                  child: _loading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: U.bg,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const _GoogleIcon(),
                            const SizedBox(width: 12),
                            Text(
                              PlatformSupport.supportsGoogleSignIn
                                  ? 'Continue with Google'
                                  : 'Google sign-in unavailable',
                            ),
                          ],
                        ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 600.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.15, end: 0, delay: 400.ms, duration: 600.ms, curve: Curves.easeOut),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  '𝕀 ℕ 𝔽 𝔼 ℝ ℕ 𝕆',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: U.dim,
                    letterSpacing: 0.5,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 600.ms),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlatformSetupScreen extends StatelessWidget {
  const _PlatformSetupScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: U.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: U.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: U.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Windows Setup Needed',
                      style: GoogleFonts.outfit(
                        color: U.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: GoogleFonts.outfit(
                        color: U.sub,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Current blockers: Firebase desktop config, desktop login, and push notifications.',
                      style: GoogleFonts.outfit(
                        color: U.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0; // scale factor from 24x24 viewBox

    // Blue
    final bluePath = Path()
      ..moveTo(22.56 * s, 12.25 * s)
      ..cubicTo(22.56 * s, 11.47 * s, 22.49 * s, 10.72 * s, 22.36 * s, 10.0 * s)
      ..lineTo(12.0 * s, 10.0 * s)
      ..lineTo(12.0 * s, 14.26 * s)
      ..lineTo(17.92 * s, 14.26 * s)
      ..cubicTo(17.66 * s, 15.63 * s, 16.88 * s, 16.79 * s, 15.71 * s, 17.57 * s)
      ..lineTo(15.71 * s, 20.34 * s)
      ..lineTo(19.28 * s, 20.34 * s)
      ..cubicTo(21.36 * s, 18.42 * s, 22.56 * s, 15.6 * s, 22.56 * s, 12.25 * s)
      ..close();
    canvas.drawPath(bluePath, Paint()..color = const Color(0xFF4285F4));

    // Green
    final greenPath = Path()
      ..moveTo(12.0 * s, 23.0 * s)
      ..cubicTo(14.97 * s, 23.0 * s, 17.46 * s, 22.02 * s, 19.28 * s, 20.34 * s)
      ..lineTo(15.71 * s, 17.57 * s)
      ..cubicTo(14.73 * s, 18.23 * s, 13.48 * s, 18.63 * s, 12.0 * s, 18.63 * s)
      ..cubicTo(9.14 * s, 18.63 * s, 6.71 * s, 16.69 * s, 5.84 * s, 14.09 * s)
      ..lineTo(2.18 * s, 14.09 * s)
      ..lineTo(2.18 * s, 16.94 * s)
      ..cubicTo(3.99 * s, 20.53 * s, 7.7 * s, 23.0 * s, 12.0 * s, 23.0 * s)
      ..close();
    canvas.drawPath(greenPath, Paint()..color = const Color(0xFF34A853));

    // Yellow
    final yellowPath = Path()
      ..moveTo(5.84 * s, 14.09 * s)
      ..cubicTo(5.62 * s, 13.43 * s, 5.49 * s, 12.73 * s, 5.49 * s, 12.0 * s)
      ..cubicTo(5.49 * s, 11.27 * s, 5.62 * s, 10.57 * s, 5.84 * s, 9.91 * s)
      ..lineTo(5.84 * s, 7.06 * s)
      ..lineTo(2.18 * s, 7.06 * s)
      ..cubicTo(1.43 * s, 8.55 * s, 1.0 * s, 10.22 * s, 1.0 * s, 12.0 * s)
      ..cubicTo(1.0 * s, 13.78 * s, 1.43 * s, 15.45 * s, 2.18 * s, 16.94 * s)
      ..lineTo(5.84 * s, 14.09 * s)
      ..close();
    canvas.drawPath(yellowPath, Paint()..color = const Color(0xFFFBBC05));

    // Red
    final redPath = Path()
      ..moveTo(12.0 * s, 5.38 * s)
      ..cubicTo(13.62 * s, 5.38 * s, 15.06 * s, 5.94 * s, 16.21 * s, 7.02 * s)
      ..lineTo(19.36 * s, 3.87 * s)
      ..cubicTo(17.45 * s, 2.09 * s, 14.97 * s, 1.0 * s, 12.0 * s, 1.0 * s)
      ..cubicTo(7.7 * s, 1.0 * s, 3.99 * s, 3.47 * s, 2.18 * s, 7.06 * s)
      ..lineTo(5.84 * s, 9.91 * s)
      ..cubicTo(6.71 * s, 7.31 * s, 9.14 * s, 5.38 * s, 12.0 * s, 5.38 * s)
      ..close();
    canvas.drawPath(redPath, Paint()..color = const Color(0xFFEA4335));
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter old) => false;
}
