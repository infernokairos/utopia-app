import 'package:flutter/foundation.dart' show kReleaseMode;

/// Single source of truth for every AdMob ID and ad rule used by UTOPIA.
///
/// Only ONE ad format is used: an App Open ad shown over the attendance
/// loader. No banner, interstitial, rewarded or native ads.
///
/// NOTE: The AdMob *App IDs* are also read natively from AndroidManifest.xml
/// at startup, so they are mirrored as manifest placeholders in
/// `android/app/build.gradle.kts` (`admobAppId`). Keep both in sync:
///   - debug builds   -> [testAppId]
///   - release builds -> [releaseAppId]
class AdConfig {
  AdConfig._();

  // ── App IDs (mirrored in android/app/build.gradle.kts) ──
  static const String releaseAppId = 'ca-app-pub-4588116985120282~6041702659';
  static const String testAppId = 'ca-app-pub-3940256099942544~3347511713';

  // ── App Open ad unit IDs ──
  static const String _releaseAppOpenAdUnitId =
      'ca-app-pub-4588116985120282/8702243752';
  static const String _testAppOpenAdUnitId =
      'ca-app-pub-3940256099942544/9257395921';

  /// The App ID matching the current build mode (informational only; the
  /// native SDK reads it from the manifest).
  static String get appId => kReleaseMode ? releaseAppId : testAppId;

  /// Real ad unit only in release builds. Debug and profile builds always
  /// use Google's test unit so real ads are never served (or tapped) in dev.
  static String get appOpenAdUnitId =>
      kReleaseMode ? _releaseAppOpenAdUnitId : _testAppOpenAdUnitId;

  // ── Rules ──

  /// Longest we will wait for an ad before letting the user continue.
  static const Duration maxShowWait = Duration(seconds: 3);

  /// Minimum time between two App Open ad impressions.
  /// (Turned off for now per request; set back to Duration(hours: 4) when needed)
  static const Duration frequencyCap = Duration.zero;

  /// A preloaded App Open ad older than this is discarded and reloaded.
  static const Duration adExpiry = Duration(hours: 4);
}
