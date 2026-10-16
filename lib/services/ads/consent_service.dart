import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Wraps the Google UMP (User Messaging Platform) API that ships inside
/// `google_mobile_ads`.
///
/// Rules enforced here:
/// - Consent info is requested on every launch, and the form is shown only
///   if required (e.g. EEA/UK users).
/// - [isResolved] stays false until that flow finishes, and [isFormShowing]
///   is true while any UMP form is on screen. Ads must check both.
/// - Every failure is swallowed silently. Consent errors never crash the app
///   or show dialogs; ads are simply not requested.
class ConsentService {
  ConsentService._();
  static final ConsentService instance = ConsentService._();

  Future<void>? _gatherFuture;
  bool _isResolved = false;
  bool _isFormShowing = false;

  /// Whether the "Privacy settings" entry point must be shown in the app.
  /// Updated after each consent info update / privacy form dismissal.
  final ValueNotifier<bool> privacyOptionsRequired = ValueNotifier<bool>(false);

  /// Called after the user changes their choice via the privacy options form.
  /// The ad manager hooks in here to load or drop ads.
  VoidCallback? onConsentChanged;

  /// True once this launch's consent flow has completed (successfully or not).
  bool get isResolved => _isResolved;

  /// True while a UMP consent or privacy options form is on screen.
  bool get isFormShowing => _isFormShowing;

  /// Requests the latest consent info and shows the consent form if required.
  /// Safe to call multiple times; the flow only runs once per launch.
  Future<void> gatherConsent() {
    return _gatherFuture ??= _runGatherConsent();
  }

  Future<void> _runGatherConsent() async {
    final completer = Completer<void>();

    void finish() {
      _isFormShowing = false;
      _isResolved = true;
      if (!completer.isCompleted) completer.complete();
    }

    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          try {
            _isFormShowing = true;
            await ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
              if (error != null) {
                debugPrint('[Consent] form error: ${error.errorCode} ${error.message}');
              }
            });
          } catch (e) {
            debugPrint('[Consent] form exception: $e');
          }
          await _refreshPrivacyOptionsRequirement();
          finish();
        },
        (FormError error) {
          // Offline or misconfigured: keep whatever consent state the SDK
          // already has from a previous launch. canRequestAds() decides.
          debugPrint('[Consent] info update failed: ${error.errorCode} ${error.message}');
          unawaited(_refreshPrivacyOptionsRequirement());
          finish();
        },
      );
    } catch (e) {
      debugPrint('[Consent] request exception: $e');
      finish();
    }

    return completer.future;
  }

  /// Returns true only if consent is resolved and the SDK allows ad requests.
  Future<bool> canRequestAds() async {
    if (!_isResolved || _isFormShowing) return false;
    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      debugPrint('[Consent] canRequestAds exception: $e');
      return false;
    }
  }

  Future<void> _refreshPrivacyOptionsRequirement() async {
    try {
      final status =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      privacyOptionsRequired.value =
          status == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      debugPrint('[Consent] privacy status exception: $e');
    }
  }

  /// Opens the UMP privacy options form so the user can change their choice.
  /// Returns false if the form could not be shown.
  Future<bool> showPrivacyOptionsForm() async {
    if (_isFormShowing) return false;
    var shownOk = true;
    _isFormShowing = true;
    try {
      await ConsentForm.showPrivacyOptionsForm((FormError? error) {
        if (error != null) {
          shownOk = false;
          debugPrint('[Consent] privacy form error: ${error.errorCode} ${error.message}');
        }
      });
    } catch (e) {
      shownOk = false;
      debugPrint('[Consent] privacy form exception: $e');
    } finally {
      _isFormShowing = false;
    }
    await _refreshPrivacyOptionsRequirement();
    onConsentChanged?.call();
    return shownOk;
  }
}
