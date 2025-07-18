import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:simple_game_1/game/racing_game.dart';
import 'package:simple_game_1/game/utils/level_config.dart';
import 'package:simple_game_1/game/utils/sfx_manager.dart';
import 'package:simple_game_1/game_play_screen.dart';
import 'package:simple_game_1/game/utils/game_mode.dart';

class GameTransitionScreen extends StatefulWidget {
  final String selectedCarImage;
  final GameMode selectedMode;
  final int? levelIndex;
  final LevelConfig? levelConfig;

  const GameTransitionScreen({
    super.key,
    required this.selectedCarImage,
    this.selectedMode = GameMode.classic,
    this.levelIndex,
    this.levelConfig,
  });

  @override
  State<GameTransitionScreen> createState() => _GameTransitionScreenState();
}

class _GameTransitionScreenState extends State<GameTransitionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeInCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _bgBlurCtrl;
  late final RacingGame _game;

  @override
  void initState() {
    super.initState();

    _fadeInCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _bgBlurCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _game = widget.levelIndex != null
        ? RacingGame(
            mode: widget.selectedMode,
            levelIndex: widget.levelIndex!,
            levelConfig: widget.levelConfig,
          )
        : RacingGame(mode: widget.selectedMode);

    _prepareAndStart();
  }

  Future<void> _prepareAndStart() async {
    try {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;

      await _game.load();
      if (!mounted) return;

      _pulseCtrl.stop();
      if (!mounted) return;

      SfxManager.ignition();
      await Future.delayed(const Duration(milliseconds: 3500));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) =>
              GamePlayScreen(game: _game, mode: widget.selectedMode),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } catch (e) {
      debugPrint('[GameTransitionScreen] Game failed to load: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start game: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }

 @override
void dispose() {
  _fadeInCtrl.dispose();
  _pulseCtrl.dispose();
  _bgBlurCtrl.dispose();

  SfxManager.stopIgnition(); // stop sound when navigating away

  super.dispose();
}


  @override
  Widget build(BuildContext context) {
    final pulse = Tween(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    final fadeScale = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeInCtrl, curve: Curves.easeOutBack));
    final blur = Tween<double>(
      begin: 10,
      end: 0,
    ).animate(CurvedAnimation(parent: _bgBlurCtrl, curve: Curves.easeOut));

    final size = MediaQuery.of(context).size;
    final ringSize = size.width * 0.55;
    final carWidth = size.width * 0.30;
    final carHeight = size.width * 0.70;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: blur,
              builder: (_, __) => ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: blur.value,
                  sigmaY: blur.value,
                ),
                child: Image.asset(
                  'assets/images/race_bg.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_fadeInCtrl, _pulseCtrl]),
              builder: (_, __) {
                final safeOpacity = fadeScale.value.clamp(0.0, 1.0);
                final safeScale = fadeScale.value.clamp(0.0, double.infinity);
                final safePulse = pulse.value.clamp(0.0, double.infinity);

                return Opacity(
                  opacity: safeOpacity,
                  child: Transform.scale(
                    scale: safeScale,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.scale(
                          scale: safePulse,
                          child: Container(
                            width: ringSize,
                            height: ringSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.cyanAccent.withOpacity(0.6),
                                  Colors.cyan.withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Hero(
                          tag: 'selected-car',
                          child: Image.asset(
                            widget.selectedCarImage,
                            width: carWidth,
                            height: carHeight,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.car_rental,
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Get Ready...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Akira',
                  shadows: [
                    Shadow(
                      offset: Offset(0, 3),
                      blurRadius: 6,
                      color: Colors.black38,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
