import 'package:cineflix_app/core/constants/ad_constants.dart';
import 'package:cineflix_app/core/services/ad_mob_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Google Mobile Ads Configuration & Service Tests (iOS & Android)', () {
    test('Exact iOS AdMob Unit IDs are configured correctly', () {
      expect(AdConstants.prodIosAppOpenAdId, 'ca-app-pub-4390946365152897/2006439474');
      expect(AdConstants.prodIosBannerAdId, 'ca-app-pub-4390946365152897/1287032984');
      expect(AdConstants.prodIosInterstitialAdId, 'ca-app-pub-4390946365152897/6927593665');

      expect(AdMobService.iosAppOpenAdUnitId, 'ca-app-pub-4390946365152897/2006439474');
      expect(AdMobService.iosBannerAdUnitId, 'ca-app-pub-4390946365152897/1287032984');
      expect(AdMobService.iosInterstitialAdUnitId, 'ca-app-pub-4390946365152897/6927593665');
    });

    test('Exact Android AdMob Unit IDs are configured correctly', () {
      expect(AdConstants.prodAndroidAppOpenAdId, 'ca-app-pub-4390946365152897/9952166079');
      expect(AdConstants.prodAndroidBannerAdId, 'ca-app-pub-4390946365152897/9832746579');
      expect(AdConstants.prodAndroidInterstitialAdId, 'ca-app-pub-4390946365152897/3646824207');

      expect(AdMobService.androidAppOpenAdUnitId, 'ca-app-pub-4390946365152897/9952166079');
      expect(AdMobService.androidBannerAdUnitId, 'ca-app-pub-4390946365152897/9832746579');
      expect(AdMobService.androidInterstitialAdUnitId, 'ca-app-pub-4390946365152897/3646824207');
    });

    test('AdMobService and AdService are equivalent and return singleton instance', () {
      final adMobService = AdMobService();
      final adService = AdService();
      expect(identical(adMobService, adService), isTrue);
    });

    test('AdMobService getters return valid IDs for both test and production modes', () {
      final prev = AdConstants.useTestAds;
      try {
        // Test Mode
        AdConstants.useTestAds = true;
        expect(AdMobService.bannerAdUnitId, contains('ca-app-pub-3940256099942544'));
        expect(AdMobService.interstitialAdUnitId, contains('ca-app-pub-3940256099942544'));
        expect(AdMobService.appOpenAdUnitId, contains('ca-app-pub-3940256099942544'));

        // Production Mode
        AdConstants.useTestAds = false;
        expect(AdMobService.bannerAdUnitId, contains('ca-app-pub-4390946365152897'));
        expect(AdMobService.interstitialAdUnitId, contains('ca-app-pub-4390946365152897'));
        expect(AdMobService.appOpenAdUnitId, contains('ca-app-pub-4390946365152897'));
      } finally {
        AdConstants.useTestAds = prev;
      }
    });

    test('AdMobService singleton manages pause/resume and full-screen state cleanly', () {
      final service = AdMobService();

      service.pauseAppOpenAds();
      expect(service.isAppOpenAdEnabled, isFalse);

      service.resumeAppOpenAds();
      expect(service.isAppOpenAdEnabled, isTrue);
    });

    test('AdMobService showInterstitialWithInterval executes smoothly without blocking', () {
      final service = AdMobService();
      int dismissedCount = 0;

      service.showInterstitialWithInterval(
        interval: 2,
        onDismissed: () => dismissedCount++,
      );
      expect(dismissedCount, 1);

      service.showInterstitialWithInterval(
        interval: 2,
        onDismissed: () => dismissedCount++,
      );
      expect(dismissedCount, 2);
    });
  });
}
