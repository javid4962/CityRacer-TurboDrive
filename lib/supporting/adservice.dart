import 'dart:ui';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_game_1/supporting/adunits.dart';

class AdManager {
  // ──────────────── Interstitial Ad ────────────────
  static InterstitialAd? _interstitialAd;
  // Set cooldown to 40 seconds.
  static const int adCooldownSeconds = 1;

  /// Loads the interstitial ad.
  static Future<void> loadInterstitialAd() async {
    if (_interstitialAd != null) {
      print(
        "Goldratelogs: Interstitial ad is already loaded. Not loading a new one.",
      );
      return;
    }
    print(
      "Goldratelogs: Loading interstitial ad using unit id: ${AdUnits.interstitialAdUnitId}",
    );
    InterstitialAd.load(
      adUnitId:
          AdUnits.interstitialAdUnitId, // Use your interstitial ad unit ID.
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          print("Goldratelogs: Interstitial ad loaded successfully.");
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print("Goldratelogs: Interstitial ad failed to load: $error");
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Shows an interstitial ad if cooldown has passed; otherwise calls [onAdClosed] immediately.
  static Future<void> showInterstitialAd({required Function onAdClosed}) async {
    final prefs = await SharedPreferences.getInstance();
    final adTimestampStr = prefs.getString('ad_close_timestamp');
    DateTime lastAdClose = DateTime.fromMillisecondsSinceEpoch(0);
    if (adTimestampStr != null) {
      lastAdClose =
          DateTime.tryParse(adTimestampStr) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }
    final now = DateTime.now();
    print(
      "Goldratelogs: Checking ad cooldown: now: $now, lastAdClose: $lastAdClose, diff: ${now.difference(lastAdClose).inSeconds} seconds",
    );

    // If less than 40 seconds have passed or the ad isn't loaded, call the callback.
    if (now.difference(lastAdClose).inSeconds < adCooldownSeconds) {
      print(
        "Goldratelogs: Cooldown not passed. Calling onAdClosed immediately.",
      );
      onAdClosed();
      return;
    }

    if (_interstitialAd == null) {
      print(
        "Goldratelogs: Ad not loaded yet. Loading now and calling onAdClosed.",
      );
      loadInterstitialAd();
      onAdClosed();
      return;
    }

    // Setup callbacks for the full-screen ad.
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) async {
        print("Goldratelogs: Interstitial ad dismissed.");
        ad.dispose();
        _interstitialAd = null; // Set to null so a new ad can be loaded.
        await prefs.setString(
          'ad_close_timestamp',
          DateTime.now().toIso8601String(),
        );
        onAdClosed();
        loadInterstitialAd(); // Load a fresh ad after closing.
      },
      onAdFailedToShowFullScreenContent:
          (InterstitialAd ad, AdError error) async {
            print("Goldratelogs: Interstitial ad failed to show: $error");
            ad.dispose();
            _interstitialAd = null; // Set to null so a new ad can be loaded.
            await prefs.setString(
              'ad_close_timestamp',
              DateTime.now().toIso8601String(),
            );
            onAdClosed();
            loadInterstitialAd();
          },
    );
    print("Goldratelogs: Showing interstitial ad now.");
    _interstitialAd!.show();
  }

  // ──────────────── Rewarded Ad ────────────────
  static RewardedAd? _rewardedAd;
  static bool _isRewardedLoading = false;

  /// Loads a rewarded ad.
  static Future<void> loadRewardedAd() async {
    if (_rewardedAd != null || _isRewardedLoading) {
      print("Goldratelogs: Rewarded ad is already loaded or loading.");
      return;
    }
    _isRewardedLoading = true;
    print(
      "Goldratelogs: Loading rewarded ad using unit id: ${AdUnits.rewardedAdUnitId}",
    );
    RewardedAd.load(
      adUnitId: AdUnits.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          print("Goldratelogs: Rewarded ad loaded successfully.");
          _rewardedAd = ad;
          _isRewardedLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print("Goldratelogs: Rewarded ad failed to load: $error");
          _rewardedAd = null;
          _isRewardedLoading = false;
        },
      ),
    );
  }

  /// Shows a rewarded ad if available.
 static Future<void> showRewardedAd({
  required VoidCallback onRewardEarned,
  required VoidCallback onAdClosed,
}) async {
  if (_rewardedAd == null) {
    print("Goldratelogs: No rewarded ad loaded. Loading a new one.");
    loadRewardedAd();
    return;
  }

  bool rewardGranted = false;

  _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
    onAdShowedFullScreenContent: (RewardedAd ad) {
      print("Goldratelogs: Rewarded ad is showing.");
    },
    onAdDismissedFullScreenContent: (RewardedAd ad) {
      print("Goldratelogs: Rewarded ad dismissed.");
      ad.dispose();
      _rewardedAd = null;
      loadRewardedAd();

      // Here we notify the UI that the ad is fully closed
      onAdClosed();
    },
    onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
      print("Goldratelogs: Failed to show rewarded ad: $error");
      ad.dispose();
      _rewardedAd = null;
      loadRewardedAd();

      // Still call onAdClosed in case you want to clean up UI
      onAdClosed();
    },
  );

  _rewardedAd!.setImmersiveMode(true);

  _rewardedAd!.show(
    onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
      print("Goldratelogs: Rewarded ad completed. Granting revive.");
      rewardGranted = true;
      onRewardEarned();
    },
  );

  _rewardedAd = null;
}
}
