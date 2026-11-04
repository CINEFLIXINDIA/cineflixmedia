import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/ad_constants.dart';

/// Centralized service to manage Google Mobile Ads (AdMob) for both iOS and Android.
///
/// Provides platform-aware Ad Unit ID resolvers and coordinates full-screen ad
/// presentation, App Open ad resume triggers, cooldowns, and disposal.
class AdMobService with WidgetsBindingObserver {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ---------------------------------------------------------------------------
  // Clean Platform-Aware Ad Unit ID Resolvers
  // ---------------------------------------------------------------------------

  /// Returns the appropriate Banner Ad Unit ID based on platform (iOS vs Android)
  /// and environment (production vs test).
  static String get bannerAdUnitId {
    if (Platform.isIOS) {
      return AdConstants.useTestAds
          ? AdConstants.testIosBannerId
          : AdConstants.prodIosBannerAdId;
    }
    return AdConstants.useTestAds
        ? AdConstants.testAndroidBannerId
        : AdConstants.prodAndroidBannerAdId;
  }

  /// Returns the appropriate Interstitial Ad Unit ID based on platform (iOS vs Android)
  /// and environment (production vs test).
  static String get interstitialAdUnitId {
    if (Platform.isIOS) {
      return AdConstants.useTestAds
          ? AdConstants.testIosInterstitialId
          : AdConstants.prodIosInterstitialAdId;
    }
    return AdConstants.useTestAds
        ? AdConstants.testAndroidInterstitialId
        : AdConstants.prodAndroidInterstitialAdId;
  }

  /// Returns the appropriate App Open Ad Unit ID based on platform (iOS vs Android)
  /// and environment (production vs test).
  static String get appOpenAdUnitId {
    if (Platform.isIOS) {
      return AdConstants.useTestAds
          ? AdConstants.testIosAppOpenId
          : AdConstants.prodIosAppOpenAdId;
    }
    return AdConstants.useTestAds
        ? AdConstants.testAndroidAppOpenId
        : AdConstants.prodAndroidAppOpenAdId;
  }

  // Exact iOS production IDs
  static const String iosAppOpenAdUnitId = AdConstants.prodIosAppOpenAdId; // ca-app-pub-4390946365152897/2006439474
  static const String iosBannerAdUnitId = AdConstants.prodIosBannerAdId;   // ca-app-pub-4390946365152897/1287032984
  static const String iosInterstitialAdUnitId = AdConstants.prodIosInterstitialAdId; // ca-app-pub-4390946365152897/6927593665

  // Exact Android production IDs
  static const String androidAppOpenAdUnitId = AdConstants.prodAndroidAppOpenAdId; // ca-app-pub-4390946365152897/9952166079
  static const String androidBannerAdUnitId = AdConstants.prodAndroidBannerAdId;   // ca-app-pub-4390946365152897/9832746579
  static const String androidInterstitialAdUnitId = AdConstants.prodAndroidInterstitialAdId; // ca-app-pub-4390946365152897/3646824207

  // ---------------------------------------------------------------------------
  // App Open Ad State
  // ---------------------------------------------------------------------------
  AppOpenAd? _appOpenAd;
  DateTime? _appOpenLoadTime;
  bool _isAppOpenLoading = false;
  bool _isShowingAppOpenAd = false;

  /// Control whether App Open ad should trigger on resume.
  bool isAppOpenAdEnabled = true;

  /// Minimum time between consecutive App Open ads (prevents ad fatigue).
  Duration appOpenCooldown = const Duration(seconds: 45);
  DateTime? _lastAppOpenDismissedTime;

  // ---------------------------------------------------------------------------
  // Interstitial Ad State
  // ---------------------------------------------------------------------------
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  bool _isShowingInterstitial = false;
  int _articleCounter = 0;

  /// Global flag to prevent multiple full-screen ads simultaneously
  bool get isShowingFullScreenAd => _isShowingAppOpenAd || _isShowingInterstitial;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('[AdMobService] Initializing MobileAds SDK (iOS: ${Platform.isIOS})...');
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('[AdMobService] MobileAds SDK initialized successfully.');

      // Register lifecycle observer for App Open ads on resume
      WidgetsBinding.instance.addObserver(this);

      // Pre-warm initial ads in the background
      loadAppOpenAd();
      loadInterstitialAd();
    } catch (e, stack) {
      debugPrint('[AdMobService] MobileAds initialization failed: $e\n$stack');
    }
  }

  // ---------------------------------------------------------------------------
  // App Lifecycle Handling (for App Open Ads)
  // ---------------------------------------------------------------------------
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[AdMobService] App resumed -> checking App Open Ad availability.');
      showAppOpenAdIfAvailable();
    }
  }

  /// Temporarily pause App Open ads (e.g. during camera, gallery, or OAuth).
  void pauseAppOpenAds() {
    isAppOpenAdEnabled = false;
  }

  /// Resume App Open ads after sensitive tasks complete.
  void resumeAppOpenAds() {
    isAppOpenAdEnabled = true;
  }

  // ---------------------------------------------------------------------------
  // App Open Ad Implementation
  // ---------------------------------------------------------------------------
  bool get isAppOpenAdAvailable {
    if (_appOpenAd == null) return false;
    if (_appOpenLoadTime == null) return false;

    // Google AdMob guidelines: App open ads expire after 4 hours.
    final isExpired = DateTime.now().difference(_appOpenLoadTime!) >= const Duration(hours: 4);
    if (isExpired) {
      debugPrint('[AdMobService] Cached App Open Ad expired (4hr limit). Disposing...');
      _appOpenAd?.dispose();
      _appOpenAd = null;
      loadAppOpenAd();
      return false;
    }
    return true;
  }

  /// Loads an App Open Ad into memory using platform-appropriate Unit ID.
  Future<void> loadAppOpenAd() async {
    if (!_isInitialized || _isAppOpenLoading || isAppOpenAdAvailable) return;

    _isAppOpenLoading = true;
    final adUnitId = appOpenAdUnitId;
    debugPrint('[AdMobService] Loading App Open Ad (unit: $adUnitId, iOS: ${Platform.isIOS})...');

    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (AppOpenAd ad) {
          debugPrint('[AdMobService] App Open Ad loaded successfully.');
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
          _isAppOpenLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('[AdMobService] App Open Ad failed to load: ${error.message} (code: ${error.code})');
          _appOpenAd = null;
          _appOpenLoadTime = null;
          _isAppOpenLoading = false;
        },
      ),
    );
  }

  /// Shows the App Open Ad if available, obeying cooldowns and state guards.
  void showAppOpenAdIfAvailable() {
    if (!isAppOpenAdEnabled) {
      debugPrint('[AdMobService] App Open Ad skipped: disabled or temporarily paused.');
      return;
    }

    if (isShowingFullScreenAd) {
      debugPrint('[AdMobService] App Open Ad skipped: another full-screen ad is active.');
      return;
    }

    // Check cooldown to avoid showing an ad too soon after previous dismissal
    if (_lastAppOpenDismissedTime != null &&
        DateTime.now().difference(_lastAppOpenDismissedTime!) < appOpenCooldown) {
      debugPrint('[AdMobService] App Open Ad skipped: within cooldown period.');
      return;
    }

    if (!isAppOpenAdAvailable) {
      debugPrint('[AdMobService] App Open Ad not ready. Triggering background load.');
      loadAppOpenAd();
      return;
    }

    _isShowingAppOpenAd = true;
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (Ad ad) {
        debugPrint('[AdMobService] App Open Ad displayed full screen.');
      },
      onAdDismissedFullScreenContent: (Ad ad) {
        debugPrint('[AdMobService] App Open Ad dismissed by user.');
        _isShowingAppOpenAd = false;
        _lastAppOpenDismissedTime = DateTime.now();
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
        debugPrint('[AdMobService] App Open Ad failed to show: ${error.message}');
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );

    _appOpenAd!.show();
  }

  // ---------------------------------------------------------------------------
  // Interstitial Ad Implementation
  // ---------------------------------------------------------------------------
  bool get isInterstitialAdAvailable => _interstitialAd != null;

  /// Preloads an Interstitial Ad using platform-appropriate Unit ID.
  Future<void> loadInterstitialAd() async {
    if (!_isInitialized || _isInterstitialLoading || _interstitialAd != null) return;

    _isInterstitialLoading = true;
    final adUnitId = interstitialAdUnitId;
    debugPrint('[AdMobService] Loading Interstitial Ad (unit: $adUnitId, iOS: ${Platform.isIOS})...');

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('[AdMobService] Interstitial Ad loaded successfully.');
          _interstitialAd = ad;
          _isInterstitialLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('[AdMobService] Interstitial Ad failed to load: ${error.message} (code: ${error.code})');
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  /// Shows an Interstitial Ad if available, then executes [onDismissed].
  /// If the ad is not ready, immediately executes [onDismissed] and loads the next ad.
  void showInterstitialAd({VoidCallback? onDismissed}) {
    if (isShowingFullScreenAd || _interstitialAd == null) {
      debugPrint('[AdMobService] Interstitial not ready or full screen active. Calling onDismissed directly.');
      onDismissed?.call();
      if (_interstitialAd == null) {
        loadInterstitialAd();
      }
      return;
    }

    _isShowingInterstitial = true;
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (Ad ad) {
        debugPrint('[AdMobService] Interstitial Ad presented.');
      },
      onAdDismissedFullScreenContent: (Ad ad) {
        debugPrint('[AdMobService] Interstitial Ad dismissed.');
        _isShowingInterstitial = false;
        ad.dispose();
        _interstitialAd = null;
        onDismissed?.call();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
        debugPrint('[AdMobService] Interstitial Ad failed to show: ${error.message}');
        _isShowingInterstitial = false;
        ad.dispose();
        _interstitialAd = null;
        onDismissed?.call();
        loadInterstitialAd();
      },
    );

    _interstitialAd!.show();
  }

  /// Shows an Interstitial Ad only every [interval] articles/clicks to avoid fatigue.
  void showInterstitialWithInterval({int interval = 3, VoidCallback? onDismissed}) {
    _articleCounter++;
    debugPrint('[AdMobService] Article click count: $_articleCounter / interval: $interval');
    if (_articleCounter >= interval) {
      _articleCounter = 0;
      showInterstitialAd(onDismissed: onDismissed);
    } else {
      onDismissed?.call();
    }
  }

  // ---------------------------------------------------------------------------
  // Disposal
  // ---------------------------------------------------------------------------
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInitialized = false;
  }
}

/// Backwards compatibility alias for [AdMobService].
typedef AdService = AdMobService;
