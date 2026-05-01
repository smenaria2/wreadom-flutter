import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ReaderAdService {
  static const String rewardedInterstitialAdUnitId =
      'ca-app-pub-7031076798250177/5021226142';
  static const String archiveLoadingInterstitialAdUnitId =
      'ca-app-pub-7031076798250177/4531194994';

  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isLoadingRewardedInterstitial = false;
  bool _isShowingArchiveLoadingInterstitial = false;
  bool _isDisposed = false;

  bool get _canShowAds =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> preloadNextChapterAd() async {
    if (!_canShowAds ||
        _rewardedInterstitialAd != null ||
        _isLoadingRewardedInterstitial) {
      return;
    }

    _isLoadingRewardedInterstitial = true;
    try {
      await RewardedInterstitialAd.load(
        adUnitId: rewardedInterstitialAdUnitId,
        request: const AdRequest(),
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _isLoadingRewardedInterstitial = false;
            if (_isDisposed) {
              ad.dispose();
              return;
            }
            _rewardedInterstitialAd = ad;
          },
          onAdFailedToLoad: (error) {
            debugPrint('Next chapter ad failed to load: $error');
            _isLoadingRewardedInterstitial = false;
            _rewardedInterstitialAd = null;
          },
        ),
      );
    } catch (error) {
      debugPrint('Next chapter ad load error: $error');
      _isLoadingRewardedInterstitial = false;
      _rewardedInterstitialAd = null;
    }
  }

  Future<void> showNextChapterAdIfReady() async {
    if (!_canShowAds || _isDisposed) return;

    final ad = _rewardedInterstitialAd;
    if (ad == null) {
      unawaited(preloadNextChapterAd());
      return;
    }

    _rewardedInterstitialAd = null;
    final completer = Completer<void>();

    void completeOnce() {
      if (!completer.isCompleted) completer.complete();
    }

    ad.fullScreenContentCallback =
        FullScreenContentCallback<RewardedInterstitialAd>(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            completeOnce();
            unawaited(preloadNextChapterAd());
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            debugPrint('Next chapter ad failed to show: $error');
            ad.dispose();
            completeOnce();
            unawaited(preloadNextChapterAd());
          },
        );

    try {
      await ad.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint(
            'Next chapter ad reward earned: ${reward.amount} ${reward.type}',
          );
        },
      );
      await completer.future.timeout(const Duration(seconds: 45));
    } catch (error) {
      debugPrint('Next chapter ad show error: $error');
      ad.dispose();
      completeOnce();
      unawaited(preloadNextChapterAd());
    }
  }

  Future<void> showArchiveLoadingAd() async {
    if (!_canShowAds || _isDisposed || _isShowingArchiveLoadingInterstitial) {
      return;
    }

    _isShowingArchiveLoadingInterstitial = true;
    try {
      await InterstitialAd.load(
        adUnitId: archiveLoadingInterstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) async {
            if (_isDisposed) {
              ad.dispose();
              return;
            }

            final completer = Completer<void>();

            void completeOnce() {
              if (!completer.isCompleted) completer.complete();
            }

            ad.fullScreenContentCallback =
                FullScreenContentCallback<InterstitialAd>(
                  onAdDismissedFullScreenContent: (ad) {
                    ad.dispose();
                    completeOnce();
                  },
                  onAdFailedToShowFullScreenContent: (ad, error) {
                    debugPrint('Archive loading ad failed to show: $error');
                    ad.dispose();
                    completeOnce();
                  },
                );

            try {
              await ad.show();
              await completer.future.timeout(const Duration(seconds: 45));
            } catch (error) {
              debugPrint('Archive loading ad show error: $error');
              ad.dispose();
              completeOnce();
            } finally {
              _isShowingArchiveLoadingInterstitial = false;
            }
          },
          onAdFailedToLoad: (error) {
            debugPrint('Archive loading ad failed to load: $error');
            _isShowingArchiveLoadingInterstitial = false;
          },
        ),
      );
    } catch (error) {
      debugPrint('Archive loading ad load error: $error');
      _isShowingArchiveLoadingInterstitial = false;
    }
  }

  void dispose() {
    _isDisposed = true;
    _rewardedInterstitialAd?.dispose();
    _rewardedInterstitialAd = null;
  }
}
