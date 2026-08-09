import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdaptiveBannerAd extends StatefulWidget {
  const AdaptiveBannerAd({
    super.key,
    required this.adUnitId,
    this.horizontalInset = 0,
  });

  final String adUnitId;
  final double horizontalInset;

  @override
  State<AdaptiveBannerAd> createState() => _AdaptiveBannerAdState();
}

class _AdaptiveBannerAdState extends State<AdaptiveBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;
  int? _lastWidth;
  int _loadGeneration = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width - widget.horizontalInset;
    _loadForWidth(width.truncate());
  }

  Future<void> _loadForWidth(int width) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (width <= 0) return;
    if (_lastWidth == width && _ad != null) return;
    _lastWidth = width;
    final generation = ++_loadGeneration;

    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || generation != _loadGeneration || size == null) return;

    await _ad?.dispose();
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _loaded = false;
      _ad = null;
    });

    final ad = BannerAd(
      adUnitId: widget.adUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || generation != _loadGeneration) {
            ad.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted || generation != _loadGeneration) return;
          setState(() {
            if (identical(_ad, ad)) _ad = null;
            _loaded = false;
          });
        },
      ),
    );

    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _loadGeneration++;
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return Center(
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
