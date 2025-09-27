import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

import 'dart:io';

class AdMobService {
  static String get interstitialAdUnitId {
    // Platform-specific ad unit IDs
    if (Platform.isIOS) {
      return 'ca-app-pub-6928170513581809/4887155976'; // iOS Interstitial
    } else {
      return 'ca-app-pub-6928170513581809/1164482168'; // Android Interstitial
    }
  }

  static String get rewardedAdUnitId {
    // Platform-specific ad unit IDs
    if (Platform.isIOS) {
      return 'ca-app-pub-6928170513581809/2415893549'; // iOS Rewarded
    } else {
      return 'ca-app-pub-6928170513581809/3834861626'; // Android Rewarded
    }
  }

  // Initialize AdMob
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // Create Interstitial Ad for Mining Start
  static InterstitialAd? _interstitialAd;
  
  static Future<void> loadInterstitialAd() async {
    print('🔄 Loading interstitial ad with ID: $interstitialAdUnitId');
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          print('✅ Interstitial ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          print('❌ Interstitial ad failed to load: $error');
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
      print('🔄 Showing interstitial ad for mining');
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          // User watched the entire ad - start mining
          print('✅ Interstitial ad completed - starting mining');
          onAdCompleted();
          ad.dispose();
          _interstitialAd = null;
          // Load next ad
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('❌ Interstitial ad failed to show: $error');
          ad.dispose();
          _interstitialAd = null;
          onAdFailed();
        },
      );

      await _interstitialAd!.show();
    } else {
      print('❌ Interstitial ad not loaded - calling onAdFailed');
      onAdFailed();
    }
  }

  // Create Rewarded Ad for Booster
  static RewardedAd? _rewardedAd;
  
  static Future<void> loadRewardedAd() async {
    print('🔄 Loading rewarded ad with ID: $rewardedAdUnitId');
    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          print('✅ Rewarded ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          print('❌ Rewarded ad failed to load: $error');
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
      print('🔄 Showing rewarded ad for booster');
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          // Load next ad
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('❌ Rewarded ad failed to show: $error');
          ad.dispose();
          _rewardedAd = null;
          onFailed();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          // User watched the entire ad - activate booster
          print('✅ Rewarded ad completed - activating booster');
          onRewarded();
        },
      );
    } else {
      print('❌ Rewarded ad not loaded - calling onFailed');
      onFailed();
    }
  }

  // Dispose ads
  static void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
} 