import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_config.dart';
import 'consent_service.dart';

/// Loads, caches and shows UTOPIA's single App Open ad.
///
/// The ad is shown over the attendance loader while attendance data is
/// fetched. Rules:
/// - Waits at most [AdConfig.maxShowWait] for an ad, then gives up. Callers
///   never await it on the critical path, so attendance loading is never
///   blocked.
/// - Never shown on the first launch after install.
/// - At most once per [AdConfig.frequencyCap].
/// - Never shown before consent is resolved or while a consent form is open.
/// - Preloaded ads older than [AdConfig.adExpiry] are discarded and reloaded.
/// - The next ad is preloaded after one is shown or dismissed.
/// - All load/show errors fail silently.
class AppOpenAdManager {
  AppOpenAdManager._();
  static final AppOpenAdManager instance = AppOpenAdManager._();

  static const String _kFirstLaunchDoneKey = 'ads_first_launch_done';
  static const String _kLastShownKey = 'ads_app_open_last_shown_ms';

  /// AdMob is only configured for Android in this app.
  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  AppOpenAd? _ad;
  DateTime? _adLoadedAt;
  bool _isLoading = false;
  bool _isShowing = false;
  Completer<void>? _loadCompleter;
  bool _bootstrapped = false;

  /// Defaults to true so nothing is shown until bootstrap confirms otherwise.
  bool _isFirstLaunch = true;

  /// Whether an App Open ad is currently on screen.
  bool get isShowingAd => _isShowing;

  bool get _hasFreshAd =>
      _ad != null &&
      _adLoadedAt != null &&
      DateTime.now().difference(_adLoadedAt!) < AdConfig.adExpiry;

  /// Starts the ad pipeline as early as possible: records first-launch
  /// state, gathers consent, then preloads an ad. Never throws.
  /// `MobileAds.instance.initialize()` is called separately in `main()`.
  Future<void> bootstrap() async {
    if (!isSupported || _bootstrapped) return;
    _bootstrapped = true;

    ConsentService.instance.onConsentChanged = _handleConsentChanged;

    try {
      final prefs = await SharedPreferences.getInstance();
      final done = prefs.getBool(_kFirstLaunchDoneKey) ?? false;
      _isFirstLaunch = !done;
      if (!done) await prefs.setBool(_kFirstLaunchDoneKey, true);
      debugPrint('[Ads] Bootstrap complete. First launch: $_isFirstLaunch');
    } catch (e) {
      debugPrint('[Ads] first-launch check failed: $e');
      _isFirstLaunch = true; // Fail safe: no ad this session.
    }

    await ConsentService.instance.gatherConsent();

    // No point loading an ad that can't be shown this session.
    if (_isFirstLaunch) {
      debugPrint('[Ads] Skipping ad preloading on first launch.');
      return;
    }
    await loadAd();
  }

  /// Loads an App Open ad if none is cached (or the cached one expired).
  Future<void> loadAd() async {
    if (!isSupported || _isLoading || _isShowing) return;
    if (_ad != null) {
      if (_hasFreshAd) {
        debugPrint('[Ads] Cached App Open ad is still fresh.');
        return;
      }
      _disposeCachedAd(); // Older than 4h: discard and reload.
    }

    // Register the in-flight load synchronously so a concurrent
    // showIfEligible() can wait on it.
    _isLoading = true;
    final completer = Completer<void>();
    _loadCompleter = completer;

    void done() {
      _isLoading = false;
      if (!completer.isCompleted) completer.complete();
    }

    if (!await ConsentService.instance.canRequestAds()) {
      debugPrint('[Ads] cannot request ads per consent status.');
      done();
      return;
    }

    try {
      debugPrint('[Ads] Loading App Open ad (${AdConfig.appOpenAdUnitId})...');
      await AppOpenAd.load(
        adUnitId: AdConfig.appOpenAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _ad?.dispose();
            _ad = ad;
            _adLoadedAt = DateTime.now();
            debugPrint('[Ads] App Open ad loaded successfully!');
            done();
          },
          onAdFailedToLoad: (error) {
            debugPrint('[Ads] App Open failed to load: ${error.code} ${error.message}');
            done();
          },
        ),
      );
    } catch (e) {
      debugPrint('[Ads] App Open load exception: $e');
      done();
    }
  }

  /// Shows the App Open ad if every rule allows it. Waits at most
  /// [AdConfig.maxShowWait] for an in-flight load.
  ///
  /// [isStillRelevant] is checked right before showing; return false once
  /// the loading screen is gone so the ad never interrupts real content.
  ///
  /// Do not await this on any critical path. Returns true if an ad was shown.
  Future<bool> showIfEligible({required bool Function() isStillRelevant}) async {
    try {
      return await _showIfEligible(isStillRelevant);
    } catch (e) {
      debugPrint('[Ads] showIfEligible exception: $e');
      _isShowing = false;
      return false;
    }
  }

  Future<bool> _showIfEligible(bool Function() isStillRelevant) async {
    if (!isSupported) return false;
    if (_isShowing) {
      debugPrint('[Ads] showIfEligible: ad is already showing.');
      return false;
    }
    if (_isFirstLaunch) {
      debugPrint('[Ads] showIfEligible: skipped (first launch after install).');
      return false;
    }

    final deadline = DateTime.now().add(AdConfig.maxShowWait);
    final consent = ConsentService.instance;
    if (!consent.isResolved || consent.isFormShowing) {
      debugPrint('[Ads] showIfEligible: consent not yet resolved or form is open.');
      return false;
    }
    if (!await consent.canRequestAds()) {
      debugPrint('[Ads] showIfEligible: canRequestAds returned false.');
      return false;
    }
    if (!await _isOutsideFrequencyCap()) {
      debugPrint('[Ads] showIfEligible: skipped due to 4-hour frequency cap.');
      return false;
    }

    if (!_hasFreshAd) {
      unawaited(loadAd()); // No-op if a load is already in flight.
      final pending = _loadCompleter;
      final remaining = deadline.difference(DateTime.now());
      if (pending != null && !pending.isCompleted && remaining > Duration.zero) {
        try {
          await pending.future.timeout(remaining);
        } on TimeoutException {
          debugPrint('[Ads] showIfEligible: 3-second wait deadline reached; skipping ad.');
          return false;
        }
      }
    }

    final ad = _ad;
    if (ad == null || !_hasFreshAd) {
      debugPrint('[Ads] showIfEligible: no ad available to show.');
      return false;
    }
    if (DateTime.now().isAfter(deadline)) {
      debugPrint('[Ads] showIfEligible: exceeded deadline.');
      return false;
    }
    if (!isStillRelevant()) {
      debugPrint('[Ads] showIfEligible: attendance loader already closed.');
      return false;
    }
    if (_isShowing || consent.isFormShowing) return false;

    _isShowing = true;
    _ad = null; // Ownership moves to the showing flow.
    _adLoadedAt = null;

    var finished = false;
    void finish(AppOpenAd shownAd) {
      if (finished) return;
      finished = true;
      _isShowing = false;
      shownAd.dispose();
      debugPrint('[Ads] App Open ad closed; preloading next ad.');
      unawaited(loadAd()); // Preload the next one.
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdShowedFullScreenContent: (_) {
        debugPrint('[Ads] App Open ad impression shown on screen.');
        unawaited(_recordShown());
      },
      onAdFailedToShowFullScreenContent: (shownAd, error) {
        debugPrint('[Ads] App Open failed to show: ${error.code} ${error.message}');
        finish(shownAd);
      },
      onAdDismissedFullScreenContent: finish,
    );

    try {
      debugPrint('[Ads] Showing App Open ad now.');
      await ad.show();
      return true;
    } catch (e) {
      debugPrint('[Ads] App Open show exception: $e');
      finish(ad);
      return false;
    }
  }

  Future<bool> _isOutsideFrequencyCap() async {
    if (AdConfig.frequencyCap == Duration.zero) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt(_kLastShownKey);
      if (lastMs == null) return true;
      final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
      final elapsed = DateTime.now().difference(last);
      // A negative elapsed time means the clock moved back. Treat it as capped.
      return !elapsed.isNegative && elapsed >= AdConfig.frequencyCap;
    } catch (e) {
      debugPrint('[Ads] frequency cap check failed: $e');
      return false;
    }
  }

  Future<void> _recordShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kLastShownKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[Ads] failed to record impression time: $e');
    }
  }

  void _handleConsentChanged() {
    unawaited(() async {
      if (await ConsentService.instance.canRequestAds()) {
        if (!_isFirstLaunch) await loadAd();
      } else {
        _disposeCachedAd(); // Consent withdrawn: drop anything cached.
      }
    }());
  }

  void _disposeCachedAd() {
    _ad?.dispose();
    _ad = null;
    _adLoadedAt = null;
  }
}
