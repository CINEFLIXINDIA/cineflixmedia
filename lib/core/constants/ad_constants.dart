import 'dart:io';
import 'package:flutter/foundation.dart';

/// Centralized Google Mobile Ads (AdMob) IDs and configuration for Android and iOS.
class AdConstants {
  AdConstants._();

  static const String prodPublisherId = 'ca-app-pub-4390946365152897';

  // ---------------------------------------------------------------------------
  // Android Production Ad Units (CineFlix Media)
  // ---------------------------------------------------------------------------
  static const String prodAndroidAppOpenAdId = 'ca-app-pub-4390946365152897/9952166079';
  static const String prodAndroidBannerAdId = 'ca-app-pub-4390946365152897/9832746579';
  static const String prodAndroidInterstitialAdId = 'ca-app-pub-4390946365152897/3646824207';

  // ---------------------------------------------------------------------------
  // iOS Production Ad Units (CineFlix Media)
  // ---------------------------------------------------------------------------
  static const String prodIosAppId = 'ca-app-pub-4390946365152897~4337089346';
  static const String prodIosAppOpenAdId = 'ca-app-pub-4390946365152897/2006439474';
  static const String prodIosBannerAdId = 'ca-app-pub-4390946365152897/1287032984';
  static const String prodIosInterstitialAdId = 'ca-app-pub-4390946365152897/6927593665';

  // Aliases for default/backward compatibility
  static const String prodAppOpenAdId = prodAndroidAppOpenAdId;
  static const String prodBannerAdId = prodAndroidBannerAdId;
  static const String prodInterstitialAdId = prodAndroidInterstitialAdId;

  // ---------------------------------------------------------------------------
  // Google Official Sample / Test Ad Unit IDs
  // Used in debug mode to reliably test ads without policy flags or no-fill errors.
  // ---------------------------------------------------------------------------
  static const String testAndroidBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testIosBannerId = 'ca-app-pub-3940256099942544/2934735716';

  static const String testAndroidInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testIosInterstitialId = 'ca-app-pub-3940256099942544/4411468910';

  static const String testAndroidAppOpenId = 'ca-app-pub-3940256099942544/9257395921';
  static const String testIosAppOpenId = 'ca-app-pub-3940256099942544/5575463023';

  // Sample App ID for Android/iOS initialization testing
  static const String testAndroidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String testIosAppId = 'ca-app-pub-3940256099942544~1458002511';

  /// Whether to use test ad units.
  /// Defaults to [kDebugMode] so emulator and test sessions load sample ads cleanly.
  /// In release builds, this automatically switches to the production AdMob IDs.
  static bool useTestAds = kDebugMode;

  /// Returns active App Open Ad Unit ID according to platform and environment.
  static String get appOpenAdUnitId {
    if (useTestAds) {
      return Platform.isIOS ? testIosAppOpenId : testAndroidAppOpenId;
    }
    return Platform.isIOS ? prodIosAppOpenAdId : prodAndroidAppOpenAdId;
  }

  /// Returns active Banner Ad Unit ID according to platform and environment.
  static String get bannerAdUnitId {
    if (useTestAds) {
      return Platform.isIOS ? testIosBannerId : testAndroidBannerId;
    }
    return Platform.isIOS ? prodIosBannerAdId : prodAndroidBannerAdId;
  }

  /// Returns active Interstitial Ad Unit ID according to platform and environment.
  static String get interstitialAdUnitId {
    if (useTestAds) {
      return Platform.isIOS ? testIosInterstitialId : testAndroidInterstitialId;
    }
    return Platform.isIOS ? prodIosInterstitialAdId : prodAndroidInterstitialAdId;
  }
}
