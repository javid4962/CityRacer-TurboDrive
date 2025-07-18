import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:simple_game_1/global_tap_detector.dart';
import 'package:simple_game_1/onboardingScreen.dart';
import 'package:simple_game_1/supporting/adunits.dart'; // Make sure this import is correct

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  AppOpenAd? _appOpenAd;
  bool _isAdShown = false;

  @override
  void initState() {
    super.initState();
    _loadAppOpenAd();
    // Also start timer as a fallback if ad doesn't show
    Timer(const Duration(seconds: 4), _navigateToOnboarding);
  }

  void _loadAppOpenAd() {
    AppOpenAd.load(
      adUnitId: AdUnits.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) return;
          _appOpenAd = ad;
          _showAppOpenAd();
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ App Open Ad failed to load: $error');
          // Do nothing, fallback timer will trigger
        },
      ),
    );
  }

  void _showAppOpenAd() {
    if (_appOpenAd == null || _isAdShown) {
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isAdShown = true;
        debugPrint('✅ App Open Ad shown.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('✅ App Open Ad dismissed.');
        ad.dispose();
        _navigateToOnboarding();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('❌ Failed to show App Open Ad: $error');
        ad.dispose();
        _navigateToOnboarding();
      },
    );

    _appOpenAd!.show();
  }

  void _navigateToOnboarding() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GlobalTapDetector(child: const OnboardingScreen()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00007E), // Dark Blue
      body: SizedBox.expand(
        child: Image.asset('assets/images/splash_bg.png', fit: BoxFit.cover),
      ),
    );
  }
}
