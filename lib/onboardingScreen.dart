// lib/onboarding_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_game_1/game/racing_game.dart';
import 'package:simple_game_1/game/utils/sfx_manager.dart';
import 'package:simple_game_1/game/widgets/rewarded_ad_offer_popup.dart';
import 'package:simple_game_1/global_tap_detector.dart';
import 'package:simple_game_1/mode_select_screen.dart';
import 'package:simple_game_1/screens/leaderboard_screen.dart';
import 'package:simple_game_1/screens/leaderboardscreen.dart';
import 'package:simple_game_1/settings_screen.dart';
import 'package:simple_game_1/supporting/adservice.dart';

import 'garage_screen.dart';
import 'main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with RouteAware, TickerProviderStateMixin {
  int _totalCoins = 0;
  bool _showRewardedPopup = false;
  int _remainingSeconds = 21600; // 🟢 Testing: 10 seconds countdown
  Timer? _timer;
  bool _awaitingClaim = false;
  bool _isFirstLaunch = false;

  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  // @override
  // void initState() {
  //   super.initState();
  //   _loadCoins();
  //   SfxManager.startBgm();
  //   AdManager.loadRewardedAd();

  //   SharedPreferences.getInstance().then((prefs) async {
  //     // prefs.remove('first_launch'); // For testing only
  //     _isFirstLaunch = prefs.getBool('first_launch') ?? true;

  //     if (_isFirstLaunch) {
  //       await prefs.setBool('first_launch', false);
  //       debugPrint('[LAUNCH] First launch flag: $_isFirstLaunch');

  //       setState(() {
  //         _showRewardedPopup = true;
  //         _awaitingClaim = true;
  //       });
  //     }

  //     _loadTimerState().then((_) {
  //       _startTimer();
  //     });
  //   });

  //   _blinkController = AnimationController(
  //     vsync: this,
  //     duration: const Duration(milliseconds: 800),
  //   )..stop();

  //   _blinkAnimation = Tween<double>(
  //     begin: 0.3,
  //     end: 1.0,
  //   ).animate(_blinkController);
  // }

  @override
  void initState() {
    super.initState();
    _loadCoins();
    SfxManager.startBgm();
    AdManager.loadRewardedAd();
    _initRewardState();

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..stop();

    _blinkAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(_blinkController);
  }

  // inside _initRewardState()
  Future<void> _initRewardState() async {
    final prefs = await SharedPreferences.getInstance();

    // Step 1: Check if it's first launch
    final hasLaunchedBefore = prefs.getBool('first_launch') ?? true;
    _isFirstLaunch = hasLaunchedBefore;
    if (_isFirstLaunch) {
      debugPrint('[INIT] First launch detected.');
    }

    // Step 2: Load cooldown timer
    final savedMillis = prefs.getInt('reward_target_timestamp');
    if (savedMillis != null) {
      final now = DateTime.now();
      final targetTime = DateTime.fromMillisecondsSinceEpoch(savedMillis);
      final remaining = targetTime.difference(now).inSeconds;

      _remainingSeconds = remaining > 0 ? remaining : 0;
      _awaitingClaim = _remainingSeconds == 0;
    } else {
      _remainingSeconds = 21600;
      _awaitingClaim = false;
      final targetTime = DateTime.now().add(const Duration(hours: 6));
      await prefs.setInt(
        'reward_target_timestamp',
        targetTime.millisecondsSinceEpoch,
      );
      debugPrint('[INIT] No timer found. Set new target: $targetTime');
    }

    if (_isFirstLaunch || _remainingSeconds <= 0) {
      _awaitingClaim = true;
      _blinkController.repeat(reverse: true);
      _showRewardedPopup = true;
    }

    if (mounted) {
      setState(() {});
      _startTimer();
    }
  }

  String formatRemainingTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours}h ${minutes}m ${secs}s remaining';
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        if (_awaitingClaim) return;
        if (_remainingSeconds > 1) {
          _remainingSeconds--;
        } else {
          _remainingSeconds = 0;
          _showRewardedPopup = true;
          _awaitingClaim = true;
          _blinkController.repeat(reverse: true);
          debugPrint('[TIMER] Countdown reached zero. Showing popup.');
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blinkController.dispose();
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    appRouteObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() => _loadCoins();

  Future<void> _loadCoins() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _totalCoins = prefs.getInt('coin_count') ?? 0);
  }

  Widget _menuButton({required String path, required VoidCallback onTap}) {
    final double width = MediaQuery.of(context).size.width * .75;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(path, width: width, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Future<void> _loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMillis = prefs.getInt('reward_target_timestamp');

    if (savedMillis != null) {
      final targetTime = DateTime.fromMillisecondsSinceEpoch(savedMillis);
      final now = DateTime.now();
      final diff = targetTime.difference(now).inSeconds;

      debugPrint(
        '[TIMER] Loaded saved target timestamp: $targetTime (Remaining: $diff seconds)',
      );

      setState(() {
        _remainingSeconds = diff > 0 ? diff : 0;
        _awaitingClaim = _remainingSeconds == 0;
        if (_awaitingClaim) {
          _blinkController.repeat(reverse: true);
        }
      });
    } else {
      // No saved timestamp: start 10-second countdown
      final targetTime = DateTime.now().add(const Duration(hours: 6));
      await prefs.setInt(
        'reward_target_timestamp',
        targetTime.millisecondsSinceEpoch,
      );
      debugPrint(
        '[TIMER INIT] No timestamp found. Created new target at: $targetTime',
      );
      setState(() {
        _remainingSeconds = 21600;
        _awaitingClaim = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size scr = MediaQuery.of(context).size;
    final double bottomPad = scr.height * .04;

    return Scaffold(
      backgroundColor: const Color(0xFF00007E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/menu_screen.jpg', fit: BoxFit.cover),

          // Coins
          Positioned(
            left: 12,
            top: MediaQuery.of(context).padding.top + 8,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/coins.png',
                  width: scr.width * .22,
                  fit: BoxFit.contain,
                ),
                Positioned(
                  bottom: 20,
                  child: Text(
                    '$_totalCoins',
                    style: const TextStyle(
                      fontFamily: 'Akira',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF3B3B),
                      shadows: [
                        Shadow(
                          blurRadius: 2,
                          color: Colors.black,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Gift icon
          Positioned(
            right: 12,
            top: MediaQuery.of(context).padding.top + 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showRewardedPopup = true;
                  debugPrint('[UI] Gift icon tapped. Showing popup manually.');
                });
              },
              child: AnimatedBuilder(
                animation: _blinkAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _awaitingClaim ? _blinkAnimation.value : 1.0,
                    child: child,
                  );
                },
                child: Container(
                  width:
                      MediaQuery.of(context).size.width *
                      0.15, // 🔧 15% of screen width
                  height:
                      MediaQuery.of(context).size.width * 0.15, // Keep square
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Image.asset(
                    'assets/images/gift_icon.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // Main menu buttons
          SafeArea(
            child: Center(
              child: Column(
                children: [
                  const Spacer(flex: 4),
                  _menuButton(
                    path: 'assets/images/play.png',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ModeSelectScreen(),
                        ),
                      );
                    },
                  ),
                  _menuButton(
                    path: 'assets/images/garage.png',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GarageScreen(
                            carAssets: [
                              'assets/images/hero1.png',
                              'assets/images/hero2.png',
                              'assets/images/hero3.png',
                              'assets/images/hero4.png',
                              'assets/images/hero5.png',
                              'assets/images/hero6.png',
                              'assets/images/hero7.png',
                              'assets/images/hero8.png',
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  _menuButton(
                    path: 'assets/images/leaderboard.png',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GlobalTapDetector(
                            child: const LeaderboardScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                  _menuButton(
                    path: 'assets/images/settings_btn.png',
                    onTap: () async {
                      final game = RacingGame();
                      await game.onLoad();
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GlobalTapDetector(
                            child: SettingsPopup(
                              game: game,
                              onClose: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                      ).then((_) => _loadCoins());
                    },
                  ),
                  SizedBox(height: bottomPad),
                ],
              ),
            ),
          ),

          // Reward popup
          if (_showRewardedPopup)
            RewardedAdOfferPopup(
              remainingSeconds: _remainingSeconds,
              isFirstLaunch: _isFirstLaunch, // ✅ Pass here
              onWatchAd: () async {
                _blinkController.stop();

                // inside onWatchAd → onRewardEarned
                await AdManager.showRewardedAd(
                  onRewardEarned: () async {
                    debugPrint('[REWARD] User earned the reward.');

                    final prefs = await SharedPreferences.getInstance();

                    // ✅ CREDIT COINS
                    int currentCoins = prefs.getInt('coin_count') ?? 0;
                    currentCoins += 100;
                    await prefs.setInt('coin_count', currentCoins);

                    // ✅ MARK FIRST LAUNCH COMPLETE
                    await prefs.setBool('first_launch', false); // ✅ Moved here

                    // ✅ SET COOLDOWN
                    final targetTime = DateTime.now().add(
                      const Duration(hours: 6),
                    );
                    await prefs.setInt(
                      'reward_target_timestamp',
                      targetTime.millisecondsSinceEpoch,
                    );
                    debugPrint('[REWARD] Timer reset. New target: $targetTime');

                    // ✅ UPDATE UI
                    if (mounted) {
                      setState(() {
                        _totalCoins = currentCoins;
                        _remainingSeconds = 21600;
                        _awaitingClaim = false;
                        _showRewardedPopup = false;
                        _isFirstLaunch = false;
                      });
                    }
                  },
                  onAdClosed: () {
                    if (mounted) {
                      setState(() {
                        _showRewardedPopup = false;
                      });
                    }
                  },
                );
              },
              onDismiss: () {
                setState(() {
                  _showRewardedPopup = false;
                  debugPrint('[UI] Popup dismissed.');
                });
              },
            ),
        ],
      ),
    );
  }
}
