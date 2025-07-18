// ignore_for_file: invalid_use_of_internal_member, deprecated_member_use

import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_game_1/game/utils/game_mode.dart';
import 'package:simple_game_1/game/utils/level_config.dart';
import 'package:simple_game_1/game/racing_game.dart';
import 'package:simple_game_1/game/widgets/game_transition_screen.dart';
import 'package:simple_game_1/global_tap_detector.dart';
import 'package:simple_game_1/mode_select_screen.dart';
import 'package:simple_game_1/onboardingScreen.dart';
import 'package:simple_game_1/game/utils/sfx_manager.dart';
import 'package:simple_game_1/supporting/adservice.dart'; // ⬅️ NEW

class GamePlayScreen extends StatefulWidget {
  final RacingGame game;
  final GameMode mode; // << ADD
  const GamePlayScreen({
    Key? key,
    required this.game,
    required this.mode, // <-- this line is critical
  }) : super(key: key);

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen>
    with WidgetsBindingObserver {
  int _session = 0;
  bool _nitroVisible = false;
  Timer? _nitroDelayTimer;
  RacingGame? _currentGame;
  bool showGameOver = false;
  bool isPaused = false;
  bool isAcceleratorPressed = false;
  bool showHeroOverlay = true;
  bool hasUsedRevive = false;
  late final String _modeLabel = switch (widget.mode) {
    GameMode.classic => 'CLASSIC',
    GameMode.level => 'LEVEL',
    GameMode.endless => 'ENDLESS',
  };

  String selectedCarImage = '';
  bool isBrakePressed = false;
  bool musicEnabled = true;
  bool sfxEnabled = true;
  bool showSettings = false;

  bool headlightsOn = true;
  bool backlightsOn = true;
  bool showFuelEmpty = false;
  bool _fuelAlertRaised = false;
  bool _lightsPressed = false;
  bool _nitroPressed = false;
  bool _nitroCooldown = false;
  DateTime? _nitroCooldownStartedAt;
  Duration? _nitroCooldownRemaining;
  bool _nitroCooldownPaused = false;

  Timer? _nitroTimer;
  bool showClassicWin = false;
  bool showLevelComplete = false;
  late Future<void> _bootstrapFuture; // ONE authoritative future
  bool _gameReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _currentGame = widget.game;

    if (_currentGame!.mode == GameMode.level &&
        _currentGame!.levelConfig != null) {
      _currentGame!.setupLevel(_currentGame!.levelConfig!);
    }

    _wireGameCallbacks(_currentGame!); // ← single authoritative wiring
    _bootstrapFuture = _bootstrapGame();
    // _initializeGame();
    // _startNitroCooldown();
  }

  Future<void> _bootstrapGame() async {
    // ⚠️ only load if not already loaded by GameTransitionScreen
    if (!_currentGame!.isLoaded) {
      await _currentGame!.load();
    } // 🔹 Flame onLoad + asset stream
    await _prepareHudAndPrefs(); // 🔹 formerly _initializeGame()
    _startNitroCooldown(); // 🔹 kick timers AFTER assets exist
    if (mounted) setState(() => _gameReady = true);
  }

  /// Moved content from _initializeGame()
  Future<void> _prepareHudAndPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final carPath = prefs.getString('selected_car_path') ?? 'player_car.png';

    setState(() {
      selectedCarImage = 'assets/images/$carPath';
      showHeroOverlay = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => showHeroOverlay = false);
  }

  @override
  void dispose() {
    _nitroDelayTimer?.cancel(); // stop cool-down timer
    _nitroTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this); // ← fix
    super.dispose();
  }

  Future<void> _markLevelAsCompleted(int levelIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('level_${levelIndex}_complete', true);
  }

  void _startNitroCooldown() {
    _nitroCooldown = true;
    _nitroCooldownPaused = false;
    _nitroCooldownStartedAt = DateTime.now();
    _nitroCooldownRemaining = const Duration(seconds: 10);

    _nitroTimer?.cancel();
    _nitroDelayTimer?.cancel();

    setState(() => _nitroVisible = false);

    _nitroDelayTimer = Timer(_nitroCooldownRemaining!, () {
      if (!mounted) return;
      setState(() => _nitroVisible = true);
      _nitroCooldown = false;
      _nitroCooldownStartedAt = null;
      _nitroCooldownRemaining = null;
    });
  }

  void _pauseNitroCooldown() {
    if (_nitroCooldown && !_nitroCooldownPaused) {
      final elapsed = DateTime.now().difference(_nitroCooldownStartedAt!);
      _nitroCooldownRemaining = _nitroCooldownRemaining! - elapsed;
      _nitroDelayTimer?.cancel();
      _nitroCooldownPaused = true;
    }
  }

  void _resumeNitroCooldown() {
    if (_nitroCooldown && _nitroCooldownPaused) {
      _nitroCooldownStartedAt = DateTime.now();
      _nitroCooldownPaused = false;

      _nitroDelayTimer = Timer(_nitroCooldownRemaining!, () {
        if (!mounted) return;
        setState(() => _nitroVisible = true);
        _nitroCooldown = false;
        _nitroCooldownStartedAt = null;
        _nitroCooldownRemaining = null;
      });
    }
  }

  void _wireGameCallbacks(RacingGame game) {
    game
      // — Game-over —
      ..onGameOver = () async {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        setState(() => showGameOver = true);
      }
      // — Pause —
      ..onPause = () {
        if (!_gameReady) return;
        setState(() => isPaused = true);
      }
      // — Fuel empty —
      ..onFuelEmpty = () {
        if (_fuelAlertRaised) return;
        _fuelAlertRaised = true;
        setState(() {
          showFuelEmpty = true;
          isPaused = true;
        });
        game.pauseEngine();
      }
      // — Classic win —
      ..onClassicGameCleared = () {
        game.pauseEngine();
        if (!mounted) return;
        setState(() => showClassicWin = true);
      }
      // — Level cleared —
      ..onLevelCleared = () {
        game.pauseEngine();
        if (!mounted) return;

        setState(() => showLevelComplete = true);
      };
  }

  /* ────────────────────────────────────────────────
   *  App-lifecycle handler - pause on focus-loss
   * ────────────────────────────────────────────────*/
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_currentGame != null && !isPaused && !showFuelEmpty) {
          _currentGame!.resumeGame();
        }
        _resumeNitroCooldown();
        SfxManager.startBgm();
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        if (_currentGame != null) {
          _currentGame!.triggerPause();
        }
        _pauseNitroCooldown();
        SfxManager.pauseBgm();
        break;
    }
  }

  void _pauseGameAndMusic() {
    if (!_currentGame!.isPaused && !_currentGame!.gameOver) {
      setState(() => isPaused = true);
      _currentGame!.triggerPause(); // freezes engine + hows overlay
      _currentGame!.musicPlayer?.pause(); // stop bg-music mmediately
    }
  }

  Future<void> restartGame() async {
    final oldGame = _currentGame!;

    // 1. Temporarily remove the game reference
    setState(() {
      _currentGame = null;
      _gameReady = false;
      _session++; // force GameWidget rebuild
      isPaused = false;
      showFuelEmpty = false;
      showGameOver = false;
      showClassicWin = false;
      showLevelComplete = false;
      _fuelAlertRaised = false;
      _nitroVisible = false;
    });

    // 2. Wait for the widget tree to detach GameWidget
    await Future.delayed(Duration.zero);

    // 3. Dispose the old game safely
    if (oldGame != null) {
      await oldGame.dispose();
    }

    // 4. Create a fresh game instance
    final fresh = RacingGame(
      mode: widget.mode,
      levelConfig: oldGame?.levelConfig,
      levelIndex: oldGame?.levelIndex ?? 1,
    );

    _wireGameCallbacks(fresh);

    // 5. Load assets
    await fresh.load();

    // 6. Re-initialize state
    setState(() {
      _currentGame = fresh;
    });

    await _prepareHudAndPrefs();
    _startNitroCooldown();

    if (mounted) {
      setState(() => _gameReady = true);
    }
    setState(() {
      hasUsedRevive = false;
    });
  }

  // Future<void> restartGame() async {
  //   _currentGame!.pauseEngine();
  //   _currentGame!.dispose();

  //   final fresh = RacingGame(
  //     mode: widget.mode,
  //     levelConfig: _currentGame!.levelConfig,
  //     levelIndex: _currentGame!.levelIndex,
  //   );
  //   _wireGameCallbacks(fresh);

  //   setState(() {
  //     _currentGame! = fresh;
  //     _gameReady = false;
  //     _session++; // keeps speedometer duplicates away
  //   });

  //   await fresh.load(); // 👈 ensure assets are ready
  //   if (!mounted) return;
  //   await _prepareHudAndPrefs(); // HUD refresh
  //   _startNitroCooldown();
  //   setState(() => _gameReady = true);
  // }

  void _handleSwipe(DragEndDetails details) {
    if (_currentGame!.controlScheme != 'Swipe') return;
    if (details.velocity.pixelsPerSecond.dx > 0) {
      _currentGame!.playerCar.moveRight();
      _currentGame!.playerCar.tiltRight();
    } else if (details.velocity.pixelsPerSecond.dx < 0) {
      _currentGame!.playerCar.moveLeft();
      _currentGame!.playerCar.tiltLeft();
    }
  }

  double _px(double designPixels, double screenWidth) {
    const double baseWidth = 411.0; // standard 1080p logical width
    return designPixels * (screenWidth / baseWidth);
  }

  void _toggleLights() {
    if (_currentGame!.gameOver || isPaused) return;
    setState(() {
      headlightsOn = !headlightsOn; // flip front lights
      backlightsOn = !backlightsOn; // flip rear lights
    });

    // Tell the car to update its overlays (adjust the
    // signature if your CarNode takes a parameter here).
    SfxManager.lightsToggle();
    _currentGame!.playerCar.toggleLights();
  }

  Widget _buildBottomHudRow(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return SizedBox(
      height: sh * 0.15,
      child: Row(
        children: [
          // SCORE & COINS
          Expanded(
            flex: 10,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SCORE: ${_currentGame?.score ?? 0}',
                  style: const TextStyle(
                    fontFamily: 'Akira',
                    fontSize: 14,
                    color: Colors.cyanAccent,
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  'COINS: ${_currentGame?.coins ?? 0}',
                  style: const TextStyle(
                    fontFamily: 'Akira',
                    fontSize: 14,
                    color: Colors.cyanAccent,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),

          // PAUSE BUTTON
          Expanded(
            flex: 10,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isPaused = true;
                });
                _currentGame?.triggerPause();
                _pauseNitroCooldown();
              },
              child: Icon(Icons.pause, color: Colors.white, size: 32),
            ),
          ),

          // FUEL METER
          Expanded(
            flex: 10,
            child: Image.asset(
              'assets/images/fuelmeter.png',
              width: sw * 0.08,
              height: sw * 0.08,
            ),
          ),

          // BRAKE BUTTON
          Expanded(
            flex: 10,
            child: GestureDetector(
              onTapDown: (_) {
                setState(() => isBrakePressed = true);
                _currentGame?.applyBrake();
              },
              onTapUp: (_) {
                setState(() => isBrakePressed = false);
                _currentGame?.releaseBrake();
              },
              onTapCancel: () {
                setState(() => isBrakePressed = false);
                _currentGame?.releaseBrake();
              },
              child: Image.asset(
                isBrakePressed
                    ? 'assets/images/break_focus.png'
                    : 'assets/images/break_normal.png',
                width: sw * 0.08,
                height: sw * 0.08,
              ),
            ),
          ),

          // SPEEDOMETER
          Expanded(
            flex: 10,
            child: Image.asset(
              'assets/images/speedometer.png',
              width: sw * 0.1,
              height: sw * 0.1,
            ),
          ),

          // NITRO
          Expanded(
            flex: 10,
            child: GestureDetector(
              onTap: () async {
                if (_nitroCooldown) return;
                await _currentGame?.activateNitro();
                _startNitroCooldown();
              },
              child: Image.asset(
                'assets/images/nitro.png',
                width: sw * 0.08,
                height: sw * 0.08,
              ),
            ),
          ),

          // CAR LIGHT
          Expanded(
            flex: 10,
            child: GestureDetector(
              onTap: _toggleLights,
              child: Image.asset(
                'assets/images/carlight.png',
                width: sw * 0.08,
                height: sw * 0.08,
              ),
            ),
          ),

          // HERO CAR SPACE
          Expanded(
            flex: 30,
            child: Center(
              child: Image.asset(
                'assets/images/hero_car.png',
                width: sw * 0.2,
                height: sw * 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    /* ───────── helpers ───────── */
    final Size scr = MediaQuery.of(context).size;
    final double sw = scr.width;
    final double sh = scr.height;

    final TextStyle labelStyle = TextStyle(
      fontFamily: 'Akira',
      decoration: TextDecoration.none,
      fontSize: _px(20, sw),
      color: Colors.cyanAccent,
      fontWeight: FontWeight.w600,
    );

    /* ───────── loading guard ───────── */
    if (!_gameReady) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1B2A),
        body: SizedBox.expand(), // empty, no spinner
      );
    }

    /* ───────── main tree ───────── */
    return WillPopScope(
      onWillPop: () async {
        if (!_currentGame!.isPaused && !showFuelEmpty) {
          setState(() => isPaused = true);
          _currentGame!.triggerPause();
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        body: Stack(
          children: [
            /* — GAME CANVAS — */
            if (_currentGame != null)
              GestureDetector(
                onHorizontalDragEnd: _handleSwipe,
                child: GameWidget(
                  key: ValueKey<int>(_session),
                  game: _currentGame!,
                ),
              )
            else
              const SizedBox.expand(), // Fallback UI while game is null
            /* ============ HUD BUTTONS ============ */
            if (_currentGame!.controlScheme != 'OnHand' && !showFuelEmpty) ...[
              // Brake
              Positioned(
                bottom: _px(30, sw),
                left: _px(40, sw),
                child: GestureDetector(
                  onTapDown: (_) {
                    setState(() => isBrakePressed = true);
                    _currentGame!.applyBrake();
                  },
                  onTapUp: (_) {
                    setState(() => isBrakePressed = false);
                    _currentGame!.releaseBrake();
                  },
                  onTapCancel: () {
                    setState(() => isBrakePressed = false);
                    _currentGame!.releaseBrake();
                  },
                  child: Image.asset(
                    isBrakePressed
                        ? 'assets/images/break_focus.png'
                        : 'assets/images/break_normal.png',
                    width: sw * .15,
                  ),
                ),
              ),

              /* ─────────── Nitro button ─────────── */
              if (widget.mode != GameMode.level)
                Positioned(
                  bottom: _px(40, sw),
                  right: _px(45, sw),
                  child: AnimatedOpacity(
                    opacity: (_nitroVisible && !isPaused) ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: IgnorePointer(
                      ignoring:
                          !_nitroVisible ||
                          _nitroCooldown, // ← disables for 10 s
                      child: GestureDetector(
                        onTapDown: (_) {
                          if (_nitroCooldown) return;
                          setState(() => _nitroPressed = true);
                        },
                        onTapUp: (_) async {
                          if (_nitroCooldown) return;
                          setState(() => _nitroPressed = false);

                          await _currentGame!
                              .activateNitro(); // triggers speed boost
                          _startNitroCooldown(); // 🔒 lock button
                        },
                        onTapCancel: () =>
                            setState(() => _nitroPressed = false),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 1.0, end: 1.15),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeInOut,
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: _nitroPressed ? 1.2 : scale,
                              child: child,
                            );
                          },
                          child: Image.asset(
                            'assets/images/nitro.png',
                            width: sw * .12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Head-/Tail-lights toggle
            ],
            if (!showFuelEmpty)
              /* ─────────── Lights toggle ─────────── */
              Positioned(
                bottom: _px(30, sw) + sw * .15 + _px(20, sw),
                right: _px(40, sw),
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _lightsPressed = true),
                  onTapUp: (_) {
                    setState(() => _lightsPressed = false);
                    _toggleLights();
                  },
                  onTapCancel: () => setState(() => _lightsPressed = false),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.0, end: 1.15),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: _lightsPressed ? 1.2 : scale,
                        child: child,
                      );
                    },
                    onEnd: () => setState(() {}),
                    child: Image.asset(
                      'assets/images/carlight.png',
                      width: sw * .12,
                    ),
                  ),
                ),
              ),
            /* — MODE TAG + HUD + POP-UPS … (unchanged) — */
            if (showFuelEmpty)
              _buildFuelEmptyPopup(
                onClose: _handleFuelClose,
                onRetry:
                    restartGame, // This should encapsulate the restart logic
              ),
            if (isPaused && !showFuelEmpty)
              _buildPauseOverlay(sw, sh, labelStyle),
            if (showClassicWin)
              _buildClassicWinPopup(
                onHome: () => Navigator.pop(context),
                onRetry: restartGame,
              ),
            if (showGameOver && !showFuelEmpty)
              buildGameOverPopup(
                score: _currentGame!.score,
                best: _currentGame!.highScore,
                onHome: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  );
                },
                onRetry: restartGame,
                onWatchAd: () async {
                  await AdManager.showRewardedAd(
                    onRewardEarned: () {
                      if (!mounted) return;

                      // Mark that revive has been used
                      setState(() {
                        hasUsedRevive = true;
                      });

                      // IMPORTANT: Do NOT revive here
                      // The game remains stopped behind the ad
                    },
                    onAdClosed: () {
                      if (!mounted) return;

                      // After the ad closes, hide Game Over and show pause overlay
                      setState(() {
                        showGameOver = false;
                        isPaused = true;
                      });

                      // Revive the player but keep the engine paused
                      _currentGame?.revive();
                      _currentGame?.triggerPause();
                    },
                  );
                },
                hasUsedRevive: hasUsedRevive,
              ),

            /* ——— LEVEL COMPLETE (always on top) ——— */
            if (showLevelComplete)
              Positioned.fill(
                child: _buildLevelCompletePopup(
                  onNext: _handleNextLevel,
                  onReplay: restartGame,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleFuelClose() {
    setState(() {
      showFuelEmpty = false;
      isPaused = false;
      _fuelAlertRaised = false;
    });
    _currentGame!.triggerGameOver();
  }

  Future<void> _handleNextLevel() async {
    final currentIndex = _currentGame!.levelIndex;
    final nextIndex = _currentGame!.levelIndex + 1;

    if (nextIndex >= levelConfigs.length) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ModeSelectScreen()),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('level_${nextIndex}_complete', true);

    // ⬇️ New path: go to transition screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameTransitionScreen(
          selectedCarImage: selectedCarImage,
          selectedMode: GameMode.level,
          levelIndex: nextIndex,
          levelConfig: levelConfigs[nextIndex],
        ),
      ),
    );
  }

  /// ─────────────────────────────────────────────────────────────
  ///  LEVEL-COMPLETE POP-UP
  ///  * centred Stack with background frame image
  ///  * vertical layout – headline, stats, two full-width buttons
  /// ─────────────────────────────────────────────────────────────
  Widget _buildLevelCompletePopup({
    required VoidCallback onNext,
    required VoidCallback onReplay,
  }) {
    final double sw = MediaQuery.of(context).size.width;
    final double sh = MediaQuery.of(context).size.height;

    // Inner horizontal padding so text/buttons don’t touch the frame
    const double sidePadFactor = 0.12; // 12 % of screen-width
    final EdgeInsets contentPadding = EdgeInsets.symmetric(
      horizontal: sw * sidePadFactor,
      vertical: sh * 0.12,
    );

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // — frame —
          Image.asset(
            'assets/images/gameover_popup.png',
            width: sw * 0.85,
            fit: BoxFit.fill,
          ),

          // — dialog content —
          Padding(
            padding: contentPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch, // <-- key line
              children: [
                /* HEADLINE */
                const Text(
                  'LEVEL COMPLETE!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Akira',
                    fontSize: 32,
                    color: Colors.cyanAccent,
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                /* DISTANCE INFO */
                Text(
                  'Distance Reached: '
                  '${_currentGame!.distanceMetres.toStringAsFixed(1)} m',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Akira',
                    fontSize: 18,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 30),

                /* FULL-WIDTH “REPLAY” BUTTON */
                ElevatedButton(
                  onPressed: onReplay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.cyanAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.cyanAccent, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'REPLAY',
                    style: TextStyle(
                      fontFamily: 'Akira',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                /* FULL-WIDTH “NEXT LEVEL” BUTTON */
                ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'NEXT LEVEL',
                    style: TextStyle(
                      fontFamily: 'Akira',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassicWinPopup({
    required VoidCallback onHome,
    required VoidCallback onRetry,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/gameover_popup.png',
            width: screenWidth * 0.85,
            fit: BoxFit.fill,
          ),
          Padding(
            padding: EdgeInsets.only(
              top: screenHeight * 0.10,
              left: screenWidth * 0.12,
              right: screenWidth * 0.12,
              bottom: screenHeight * 0.05,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'YOU WIN!',
                  style: TextStyle(
                    fontFamily: 'Akira',
                    decoration: TextDecoration.none,
                    fontSize: 32,
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Collected 150 Coins',
                  style: TextStyle(
                    fontFamily: 'Akira',
                    decoration: TextDecoration.none,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: onHome,
                      child: Image.asset(
                        'assets/images/home.png',
                        width: 50,
                        height: 50,
                      ),
                    ),
                    GestureDetector(
                      onTap: onRetry,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.cyanAccent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF003366),
                        ),
                        child: const Text(
                          'REPLAY',
                          style: TextStyle(
                            fontFamily: 'Akira',
                            decoration: TextDecoration.none,
                            fontSize: 20,
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* ───────────────────────────────────────────────
 * Extracted pause overlay into its own builder to
 * keep build() tidy.
 * ─────────────────────────────────────────────── */
  Widget _buildPauseOverlay(double sw, double sh, TextStyle labelStyle) {
    return Padding(
      padding: EdgeInsets.all(_px(18, sw)),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // background
            SizedBox(
              width: sw * .85,
              height: sh * .55,
              child: Image.asset(
                'assets/images/pausepopup.png',
                fit: BoxFit.fill,
              ),
            ),

            // content
            Container(
              width: sw * .75,
              height: sh * .40,
              padding: EdgeInsets.only(
                top: _px(60, sw),
                left: _px(20, sw),
                right: _px(20, sw),
              ),
              child: Column(
                children: [
                  _buildSoundRow(
                    context,
                    'Music',
                    musicEnabled,
                    labelStyle,
                    () async {
                      await SfxManager.toggleMusic();

                      final p = await SharedPreferences.getInstance();
                      setState(() => musicEnabled = p.getBool('music') ?? true);
                    },
                  ),
                  SizedBox(height: _px(20, sw)),
                  _buildSoundRow(
                    context,
                    'Sound FX',
                    sfxEnabled,
                    labelStyle,
                    () async {
                      final p = await SharedPreferences.getInstance();
                      final newVal = !sfxEnabled;
                      await p.setBool('sound_fx', newVal);
                      await SfxManager.setFxEnabled(newVal);
                      setState(() => sfxEnabled = newVal);
                    },
                  ),

                  const Spacer(),
                  IconButton(
                    icon: Image.asset(
                      'assets/images/home.png',
                      width: _px(48, sw),
                      height: _px(48, sw),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            GlobalTapDetector(child: const OnboardingScreen()),
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() => isPaused = false);
                      _currentGame!.resumeGame();
                      _resumeNitroCooldown();
                    },
                    child: Container(
                      height: _px(50, sw),
                      width: _px(160, sw),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF003366),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.cyanAccent, width: 2),
                      ),
                      child: Text(
                        'RESUME',
                        style: TextStyle(
                          fontFamily: 'Akira',
                          decoration: TextDecoration.none,
                          fontSize: _px(20, sw),
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // close-X
            Positioned(
              top: sh * .05 - _px(10, sw),
              right: sw * .05 - _px(10, sw),
              child: GestureDetector(
                onTap: () {
                  setState(() => isPaused = false);
                  _currentGame!.resumeGame();
                  _resumeNitroCooldown();
                },
                child: Container(
                  width: _px(32, sw),
                  height: _px(32, sw),
                  decoration: const BoxDecoration(
                    color: Colors.cyanAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 20, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fuel-empty dialog with a close button
  /// Fuel-empty overlay — no more overflow
  Widget _buildFuelEmptyPopup({
    required VoidCallback onClose,
    required VoidCallback onRetry, // new param
  }) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.all(_px(18, sw)),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            /* ─── Panel bg ─── */
            SizedBox(
              width: sw * .85,
              height: sh * .58,
              child: Image.asset(
                'assets/images/pausepopup.png',
                fit: BoxFit.fill,
              ),
            ),

            /* ─── Panel body ─── */
            Container(
              width: sw * .75,
              height: sh * .47,
              padding: EdgeInsets.only(
                top: _px(60, sw),
                left: _px(15, sw),
                right: _px(15, sw),
              ),
              child: Column(
                children: [
                  Text(
                    'OUT OF FUEL!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Akira',
                      fontSize: _px(28, sw),
                      fontWeight: FontWeight.w900,
                      color: Colors.cyanAccent,
                      decoration: TextDecoration.none,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: _px(18, sw)),
                  Text(
                    'Your tank is empty.\nReplay or finish the run.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Akira',
                      fontSize: _px(18, sw),
                      color: Colors.white,
                      decoration: TextDecoration.none,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: _px(35, sw)),

                  /* ─── Buttons ─── */
                  Column(
                    children: [
                      _buildPrimaryButton(
                        sw,
                        label: 'REPLAY',
                        iconPath: 'assets/images/home.png',
                        onTap: () {
                          setState(() {
                            showFuelEmpty = false;
                            _fuelAlertRaised = false;
                          });
                          onRetry(); // External logic handles the replay
                        },
                      ),
                      SizedBox(height: _px(16, sw)),
                      _buildPrimaryButton(
                        sw,
                        label: 'GIVE UP',
                        iconPath: 'assets/images/home.png',
                        onTap: onClose,
                      ),
                    ],
                  ),

                  const Spacer(),
                ],
              ),
            ),

            /* ─── Close X ─── */
            Positioned(
              top: sh * .05 - _px(10, sw),
              right: sw * .05 - _px(10, sw),
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  width: _px(32, sw),
                  height: _px(32, sw),
                  decoration: const BoxDecoration(
                    color: Colors.cyanAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 20, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* helper */
  Widget _buildPrimaryButton(
    double sw, {
    required String label,
    required String iconPath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: _px(50, sw),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF003366),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyanAccent, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconPath, width: _px(24, sw), height: _px(24, sw)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Akira',
                fontSize: _px(18, sw),
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundRow(
    BuildContext context,
    String label,
    bool isEnabled,
    TextStyle style,
    VoidCallback onTap,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        GestureDetector(
          onTap: onTap,
          child: Image.asset(
            isEnabled
                ? 'assets/images/speaker.png'
                : 'assets/images/speaker_off.png',
            width: 30,
            height: 30,
          ),
        ),
      ],
    );
  }

  /// New cyber-style Game-Over overlay (matches second reference image)
  Widget buildGameOverPopup({
    required int score,
    required int best,
    required VoidCallback onHome,
    required VoidCallback onRetry,
    required VoidCallback onWatchAd,
    bool hasUsedRevive = false,
  }) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.85,
        child: Container(
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/images/gameover_popup.png'),
              fit: BoxFit.fill,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.only(
            top: sh * 0.12, // Top padding
            bottom: sh * 0.02, // Bottom padding (you can change this)
            left: sw * 0.05, // Left padding
            right: sw * 0.05, // Right padding
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Score
              const Text(
                'SCORE',
                style: TextStyle(
                  fontFamily: 'Akira',
                  fontSize: 22,
                  color: Colors.cyanAccent,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: sh * 0.01),
              Text(
                '$score',
                style: TextStyle(
                  fontFamily: 'Akira',
                  fontSize: sw * 0.12,
                  color: Colors.cyanAccent,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: sh * 0.01),
              const Text(
                'BEST',
                style: TextStyle(
                  fontFamily: 'Akira',
                  fontSize: 22,
                  color: Colors.cyanAccent,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: sh * 0.01),
              Text(
                '$best',
                style: TextStyle(
                  fontFamily: 'Akira',
                  fontSize: sw * 0.12,
                  color: Colors.cyanAccent,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: sh * 0.03),
              // Home and Retry
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: onHome,
                    child: Image.asset(
                      'assets/images/home.png',
                      width: sw * 0.10,
                      height: sw * 0.10,
                    ),
                  ),
                  GestureDetector(
                    onTap: onRetry,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: sw * 0.04,
                        vertical: sh * 0.01,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.cyanAccent, width: 2),
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF003366),
                      ),
                      child: Text(
                        'RETRY',
                        style: TextStyle(
                          fontFamily: 'Akira',
                          fontSize: sw * 0.045,
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (!hasUsedRevive) ...[
                SizedBox(height: sh * 0.02),
                GestureDetector(
                  onTap: onWatchAd,
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: sh * 0.012),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amberAccent, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF222222),
                    ),
                    child: Text(
                      'WATCH AD TO REVIVE',
                      style: TextStyle(
                        fontFamily: 'Akira',
                        fontSize: sw * 0.045,
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
