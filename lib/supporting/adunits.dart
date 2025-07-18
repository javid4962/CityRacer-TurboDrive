import 'dart:io';
import 'package:flutter/foundation.dart';

class AdUnits {
  // ────────────── Android Live IDs ──────────────
  static const String _androidAppOpenAdUnitId =
      'ca-app-pub-5787710865160187/7352606322';
  static const String _androidInterstitialAdUnitId =
      'ca-app-pub-5787710865160187/2918537295';
  static const String _androidRewardedAdUnitId =
      'ca-app-pub-5787710865160187/xxxxxxx'; // ← REPLACE with your real Rewarded Ad ID

  // ────────────── iOS Live IDs ──────────────
  static const String _iosAppOpenAdUnitId =
      'ca-app-pub-5787710865160187/9842380128';
  static const String _iosInterstitialAdUnitId =
      'ca-app-pub-5787710865160187/4562133281';
  static const String _iosRewardedAdUnitId =
      'ca-app-pub-5787710865160187/6664432882'; // ← REPLACE with your real Rewarded Ad ID

  // ────────────── Test IDs ──────────────
  static const String _testAppOpenAdUnitId =
      'ca-app-pub-3940256099942544/9257395921';
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  /// Returns the correct App Open Ad Unit ID.
  static String get appOpenAdUnitId {
    if (kDebugMode) {
      return _testAppOpenAdUnitId;
    }
    if (Platform.isAndroid) {
      return _androidAppOpenAdUnitId;
    }
    if (Platform.isIOS) {
      return _iosAppOpenAdUnitId;
    }
    return _testAppOpenAdUnitId;
  }

  /// Returns the correct Interstitial Ad Unit ID.
  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return _testInterstitialAdUnitId;
    }
    if (Platform.isAndroid) {
      return _androidInterstitialAdUnitId;
    }
    if (Platform.isIOS) {
      return _iosInterstitialAdUnitId;
    }
    return _testInterstitialAdUnitId;
  }

  /// Returns the correct Rewarded Ad Unit ID.
  static String get rewardedAdUnitId {
    if (kDebugMode) {
      return _testRewardedAdUnitId;
    }
    if (Platform.isAndroid) {
      return _androidRewardedAdUnitId;
    }
    if (Platform.isIOS) {
      return _iosRewardedAdUnitId;
    }
    return _testRewardedAdUnitId;
  }
}
