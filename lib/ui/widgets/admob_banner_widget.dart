import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/services/ad_mob_service.dart';

/// A reusable, production-ready Banner Ad widget for CineFlix Media.
///
/// Handles banner loading, disposal, responsive sizing, and collapsible
/// fallbacks (zero-height on load failure) so UI layout never breaks.
class AdMobBannerWidget extends StatefulWidget {
  final String? adUnitId;
  final AdSize adSize;
  final EdgeInsetsGeometry margin;
  final bool showAdLabel;
  final Widget? placeholder;

  const AdMobBannerWidget({
    super.key,
    this.adUnitId,
    this.adSize = AdSize.banner,
    this.margin = const EdgeInsets.symmetric(vertical: 10),
    this.showAdLabel = false,
    this.placeholder,
  });

  @override
  State<AdMobBannerWidget> createState() => _AdMobBannerWidgetState();
}

class _AdMobBannerWidgetState extends State<AdMobBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _hasFailed = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    final unitId = widget.adUnitId ?? AdMobService.bannerAdUnitId;

    _bannerAd = BannerAd(
      adUnitId: unitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('[AdMobBannerWidget] Banner loaded successfully ($unitId).');
          if (mounted) {
            setState(() {
              _isLoaded = true;
              _hasFailed = false;
            });
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('[AdMobBannerWidget] Banner failed to load: ${error.message} (code: ${error.code})');
          ad.dispose();
          _bannerAd = null;
          if (mounted) {
            setState(() {
              _isLoaded = false;
              _hasFailed = true;
            });
          }
        },
        onAdOpened: (Ad ad) {
          debugPrint('[AdMobBannerWidget] Banner ad tapped/opened.');
        },
        onAdClosed: (Ad ad) {
          debugPrint('[AdMobBannerWidget] Banner ad closed.');
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If the ad failed to load, collapse completely to avoid empty blank space
    if (_hasFailed) {
      return const SizedBox.shrink();
    }

    // While loading, return placeholder or empty space
    if (!_isLoaded || _bannerAd == null) {
      return widget.placeholder ?? const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: widget.margin,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showAdLabel)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'ADVERTISEMENT',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
          SizedBox(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ],
      ),
    );
  }
}

