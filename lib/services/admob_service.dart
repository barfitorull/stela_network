import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class AdMobService {
  static String get interstitialAdUnitId {
    // Real ad unit ID for Stela Network Mining
    return 'ca-app-pub-6928170513581809/1164482168';
  }

  static String get rewardedAdUnitId {
    // Real ad unit ID for Stela Network Booster
    return 'ca-app-pub-6928170513581809/3834861626';
  }

  // Initialize AdMob
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // Create Interstitial Ad for Mining Start
  static InterstitialAd? _interstitialAd;
  
  static Future<void> loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          print('Interstitial ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  static Future<void> showInterstitialAdForMining({
    required Function() onAdCompleted,
    required Function() onAdFailed,
  }) async {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          // User watched the entire ad - start mining
          onAdCompleted();
          ad.dispose();
          _interstitialAd = null;
          // Load next ad
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Interstitial ad failed to show: $error');
          ad.dispose();
          _interstitialAd = null;
          onAdFailed();
        },
      );

      await _interstitialAd!.show();
    } else {
      print('Interstitial ad not loaded');
      onAdFailed();
    }
  }

  // Create Rewarded Ad for Booster
  static RewardedAd? _rewardedAd;
  
  static Future<void> loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          print('Rewarded ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          print('Rewarded ad failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  static Future<void> showRewardedAdForBooster({
    required Function() onRewarded,
    required Function() onFailed,
  }) async {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          // Load next ad
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Rewarded ad failed to show: $error');
          ad.dispose();
          _rewardedAd = null;
          onFailed();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          // User watched the entire ad - activate booster
          onRewarded();
        },
      );
    } else {
      print('Rewarded ad not loaded');
      onFailed();
    }
  }

  // Dispose ads
  static void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
} 