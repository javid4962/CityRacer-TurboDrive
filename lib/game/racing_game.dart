// ignore_for_file: deprecated_member_use

import 'dart:async' as async;
import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:simple_game_1/game/controls/swipe_control.dart';
import 'package:simple_game_1/game/controls/tap_control_component.dart';
import 'package:simple_game_1/game/controls/tilt_control.dart';
import 'package:simple_game_1/game/controls/wheel_control.dart';
import 'package:simple_game_1/game/utils/road_catalog.dart';
import 'package:simple_game_1/models/player_leaderboard_entry.dart';
import 'package:simple_game_1/services/local_player_service.dart';
import 'package:simple_game_1/supporting/adservice.dart';

import 'nodes/car_node.dart';
import 'nodes/road_node.dart';
import 'widgets/pause_button_component.dart';
import 'utils/car_stats.dart';
import 'controls/onhanddrag.dart';
import 'package:simple_game_1/game/utils/sfx_manager.dart';
import 'package:simple_game_1/game/utils/game_mode.dart';
import 'utils/level_config.dart';
import 'utils/lane_utils.dart';

// ─────────────────────────────────────────────────────────
// GAME MODES
// ─────────────────────────────────────────────────────────

class RacingGame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents {
  final GameMode mode;

  RacingGame({
    this.mode = GameMode.classic,
    this.levelConfig,
    this.autoStartBgm = false,
    this.levelTargetMetres = 1000, // 1 km goal for Level-mode
    this.levelIndex = 1, // which stage (for later)
  });

  // ── Level-mode helpers ───────────────────────────────
  double levelTargetMetres; // distance to clear
  final int levelIndex; // (for future use)
  bool _levelCleared = false;
  final List<async.Timer> _activeTimers = [];
  bool isLoaded = false;

  final bool autoStartBgm;
  // === Player Speed State ===
  double currentPlayerSpeed = 0.0;
  double scrollSpeed = 0.0;
  double playerMaxSpeed = 260.0; // default, will be overridden by selected car
  double acceleration = 0.0;
  double currentEnemySpeed = 0.0;
  final List<double> speedMarks = [0, 75, 150, 225, 300, 375];
  final List<double> angleMarks = [
    -pi / 2, // full left
    -pi / 4, // halfway
    0, // slightly left
    pi / 4, // center
    pi / 2, // right
    pi, // full right
  ];
  int _currentScore = 0;

  AudioPlayer? musicPlayer;

  double accelerationPerSecond = 0.0;
  bool _isBoosting = false;
  bool _isPaused = false;
  bool gameOver = false;
  bool _assetsLoaded = false;
  bool _isBraking = false;
  SpriteComponent? _startLineRoad;
  bool _startLineVisible = false;
  bool _spawningEnabled = true;

  // late async.Timer _speedTimer;
  double enemyMaxSpeed = 0.0;

  late CarNode playerCar;
  late RoadNode road;
  late Sprite _lightSprite;
  late Sprite _shadowSprite;
  late RoadModel selectedRoad;

  late Sprite _playerSprite;
  late Sprite _roadSprite;
  late List<Sprite> _enemySprites;
  late Sprite _leftSprite;
  late Sprite _rightSprite;
  late Sprite _speedometerSprite;
  late Sprite _pointerSprite;
  late Sprite _pauseSprite;
  late PauseButtonComponent _pauseButton;
  late SpriteComponent speedometer;
  late SpriteComponent pointer;
  late Sprite _scoreBoardSprite;
  late SpriteComponent _scoreBoardComponent;
  late String controlScheme = 'Swipe';
  late Sprite wheelSprite;
  late TextComponent coinText;
  late async.Timer _coinTimer; // Add this at the class level
  late CarStats selectedCarStats;
  SpriteComponent? acceleratorComponent;

  /*─────────────────────────────────────────────────────────
 *  High-score key generator
 *────────────────────────────────────────────────────────*/
  String get _scoreKey {
    switch (mode) {
      case GameMode.classic:
        return 'high_score_classic';
      case GameMode.endless:
        return 'high_score_endless';
      case GameMode.level:
        return 'high_score_level';
    }
  }

  // inside RacingGame
  late final AudioPlayer _nitroPlayer; // one reusable player
  DateTime? _nitroSfxStart; // timestamp for debug

  late async.Timer _debugLogTimer;
  late async.Timer _pointerLogTimer;

  double scrollDeltaY = 0;

  SpriteComponent? wheelComponent;

  double lastDragX = 0.0;
  double steeringInput = 0.0; // -1.0 (left) to 1.0 (right)
  bool isWheelHeld = false;
  bool laneChangeInProgress = false;
  double _currentPointerAngle = 0;
  double tiltVelocity = 0.0;
  double tiltPosition = 0.0;
  double currentLeanAngle = 0.0;
  bool _speedoIntroDone = false;
  bool isTouching = false;
  bool _isInitialized = false;
  bool isCountingDown = true;
  bool _fuelDepletedHandled = false;
  Duration gameTime = Duration.zero;

  bool _highScoreDirty = false;
  bool bounced = false;
  int score = 0;
  int highScore = 0;
  bool get isPaused => _isPaused;
  // Nitro (50 % speed bump for 5 seconds)
  bool _nitroActive = false;
  async.Timer? _nitroTimer;
  async.Timer? _coinFlushTimer;
  static const double _nitroFactor = 2.5; // +50 %
  static const _nitroTime = Duration(seconds: 3);

  // RacingGame.dart  (class fields)
  double get distanceMetres => _distanceMetres;

  double _distanceMetres = 0; // running total, metres
  static const double _pxPerMetre = 500; // tune to “feel” right on screen

  double _baseEnemySpeed = 300;
  late TextComponent scoreText;
  late TextComponent highScoreText;
  late Future<SpriteAnimation> _coinAnimationFuture;
  late String carName;

  final List<SpriteAnimationComponent> coins = [];
  int coinCount = 0;

  final Random random = Random();
  late async.Timer _scoreTimer;
  late async.Timer _enemySpawnTimer;

  // ─── fuel system ───────────────────────────────────────────────
  late int mileageOutTime; // e.g. 45 s  (set from CarStats)
  int? _fuelSecondsLeft;
  // countdown ticks
  static const int _fuelSpawnCount = 3;
  late int _fuelSpawnInterval; // = mileageOutTime / 5
  int _cansSpawnedThisTank = 0; // reset each tank
  async.Timer? _fuelTimer;
  bool _fuelPaused = false;
  final List<SpriteComponent> _fuelCans = [];
  late final Sprite _fuelSprite; // load once in _loadAssets()
  late Sprite _fuelMeterSprite;
  late Sprite _fuelPointerSprite;
  late SpriteComponent _fuelPointer;
  // Smooth fuel-needle angle (radians)
  double _currentFuelAngle = 0.0;
  int _coinsCollected = 0;

  // ─────────────────── Nitor speed gradual slowdown
  // ─── Nitro-recovery helpers ───
  double? _recoveryStartPlayer; // snapshot when nitro turns off
  double? _recoveryStartScroll;
  double? _recoveryStartEnemy;
  double _recoveryElapsed = 0.0;
  static const double _recoveryDuration = 1.0; // seconds of easing

  // test time in speedometer
  // ── Speedometer test helpers ──
  bool _speedoTestRunning = false; // armed after countdown
  // seconds
  // log every 1 s
  int _nextSpawnTick = 0; // global to RacingGame
  int _collisionCount = 0;
  double _collisionCooldown = 0;
  Function(String reason)? onLevelFailed;

  // For hit flash effect
  bool showDamageFlash = false;
  bool _levelClearNotified = false;
  double damageFlashOpacity = 0.0;

  final LevelConfig? levelConfig;

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}.'
      '${dt.millisecond.toString().padLeft(3, '0')}';

  /*────────── Fuel spawn diagnostics ─────────*/
  DateTime? _lastFuelSpawnTime; // null → first can of the tank

  late double _playerMaxSpeed;
  late double _accelPerSecond;
  late double _enemySpeed;
  late String _selectedHeroId;
  // ─── COIN-PERSISTENCE PIPELINE ────────────────────────────────
  int _coinsCollectedThisRun = 0; // dirty counter (not yet flushed)

  StreamSubscription<AccelerometerEvent>? accelerometerSubscription;
  void Function()? onGameOver;
  void Function()? onPause;
  void Function()? onFuelEmpty;
  void Function()? onLevelCleared;

  void Function()? onClassicGameCleared;

  async.Future<void> dispose() async {
    // Cancel all running timers and subscriptions
    _scoreTimer.cancel();
    _enemySpawnTimer.cancel();
    _coinTimer.cancel();
    _fuelTimer?.cancel();
    _debugLogTimer.cancel();
    _pointerLogTimer.cancel();
    _nitroTimer?.cancel();
    accelerometerSubscription?.cancel();
    _coinFlushTimer?.cancel();

    speedometer.removeFromParent();
    pointer.removeFromParent();
    // Remove OnHandComponent if active
    onHandComponent?.removeFromParent();
    onHandComponent = null;

    // Null out callbacks to prevent crossfire
    onFuelEmpty = null;
    onGameOver = null;
    onPause = null;
    // make sure the last few coins of the run aren’t lost
    _coinFlushTimer?.cancel();
    if (_coinsCollectedThisRun > 0) {
      final prefs = await SharedPreferences.getInstance();
      final grandTotal = prefs.getInt('coin_count') ?? 0;
      await prefs.setInt('coin_count', grandTotal + _coinsCollectedThisRun);
    }
    overlays.clear(); // ← final safety net
  }

  @override
  Future<void> onLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final isMusicEnabled = prefs.getBool('music') ?? true;

    // ─── Nitro SFX setup ─────────────────────
    _nitroPlayer = AudioPlayer();
    await _nitroPlayer.setSourceAsset('audio/sounds/nitro_start.wav');
    _nitroPlayer.setReleaseMode(ReleaseMode.stop);
    _nitroPlayer.onPlayerComplete.listen((_) {
      DateTime.now().difference(_nitroSfxStart!);
    });

    // ─── Music setup ─────────────────────────
    musicPlayer = AudioPlayer();
    await musicPlayer!.setReleaseMode(ReleaseMode.loop);
    if (autoStartBgm && isMusicEnabled) {
      await SfxManager.startBgm();
    }

    // ─── Control scheme fallback ─────────────
    controlScheme = prefs.getString('control_scheme') ?? 'Swipe';

    // ─── Car selection and stat loading ──────
    String savedCar = prefs.getString('selected_car_path') ?? 'hero1.png';
    carName = savedCar.replaceAll('.png', '');

    if (savedCar.startsWith('assets/images/')) {
      savedCar = savedCar.replaceFirst('assets/images/', '');
      await prefs.setString('selected_car_path', savedCar);
    }

    final carKey = savedCar.replaceAll('.png', '');
    _selectedHeroId = carKey;
    selectedCarStats = carPerformanceMap[carKey] ?? carPerformanceMap['hero1']!;
    _playerSprite = Sprite(await images.load(savedCar));

    SfxManager.setActiveCar(selectedCarStats);

    // ─── Parameter Resolution by Mode ────────
    await _setupParams();

    // ─── Apply resolved parameters ───────────
    playerMaxSpeed = _playerMaxSpeed;
    currentPlayerSpeed = selectedCarStats.baseSpeed;
    acceleration = _accelPerSecond;
    currentEnemySpeed = _enemySpeed * 0.9;
    enemyMaxSpeed = _enemySpeed;

    // ─── Dynamic Road Asset Loading ───────────
    final selectedRoadId = prefs.getInt('selected_road_id') ?? 1;
    final roadModel = getRoadById(selectedRoadId);

    _roadSprite = Sprite(await images.load(roadModel.centerSprite));
    _leftSprite = Sprite(await images.load(roadModel.leftSprite));
    _rightSprite = Sprite(await images.load(roadModel.rightSprite));

    // ─── Coin flush timer (every 2 seconds) ───
    _coinFlushTimer = async.Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_coinsCollectedThisRun == 0) return;

      // Schedule the write without blocking the timer loop
      unawaited(() async {
        final prefs = await SharedPreferences.getInstance();
        final grandTotal = prefs.getInt('coin_count') ?? 0;
        await prefs.setInt('coin_count', grandTotal + _coinsCollectedThisRun);
        _coinsCollectedThisRun = 0;
      }());
    });

    // ─── Load remaining art assets ───────────
    await _loadAssets();
    // await AdManager.loadInterstitialAd();
    await AdManager.loadRewardedAd();
  }

  @override
  void onRemove() {
    musicPlayer?.stop();
    super.onRemove();
  }

  Future<void> _loadAssets() async {
    if (_assetsLoaded) return;
    _assetsLoaded = true;
    await FlameAudio.audioCache.loadAll([
      'sounds/coin_collect.mp3',
      'sounds/fuel_collect.mp3',
      'sounds/car_hit.wav',
      'sounds/brake.mp3',
      'sounds/horn.wav',
    ]);

    // _roadSprite = Sprite(await images.load('road.png'));
    // _leftSprite = Sprite(await images.load('left.png'));
    // _rightSprite = Sprite(await images.load('right.png'));
    _lightSprite = Sprite(await images.load('lightbeam.png'));
    _shadowSprite = Sprite(await images.load('carshadow.png'));
    _speedometerSprite = Sprite(await images.load('speedmeter.png'));
    _pointerSprite = Sprite(await images.load('pointer.png'));
    _pauseSprite = Sprite(await images.load('pause.png'));
    _scoreBoardSprite = Sprite(await images.load('score.png'));
    wheelSprite = Sprite(await images.load('wheel.png'));
    _coinAnimationFuture = createCoinAnimation();

    _enemySprites = [];
    for (int i = 1; i <= 10; i++) {
      _enemySprites.add(Sprite(await images.load('enemy_car-$i.png')));
    }
    _fuelSprite = Sprite(await images.load('fuelcan.png'));
    _fuelMeterSprite = Sprite(await images.load('fuelmeter.png'));
    _fuelPointerSprite = Sprite(await images.load('fuelmeter_pointer.png'));
  }

  Future<void> _setupParams() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedHeroId = prefs.getString('selectedHeroId') ?? 'hero1';

    final stats = carPerformanceMap[_selectedHeroId]!;

    _playerMaxSpeed = stats.maxSpeed;
    _accelPerSecond = stats.maxSpeed / stats.timeToMaxSpeed;

    if (mode == GameMode.level && levelConfig != null) {
      _enemySpeed = levelConfig!.enemySpeed;
      _playerMaxSpeed = math.min(_playerMaxSpeed, _enemySpeed * 1.15);
    } else {
      _enemySpeed = _playerMaxSpeed * 0.9;
    }
  }

  Future<SpriteAnimation> createCoinAnimation() async {
    final image = await images.load('coinsprite.png');

    return SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: 19, // ✅ total frames
        stepTime: 0.04, // ✅ smoother animation (20 fps)
        textureSize: Vector2(200, 200), // ✅ size of each frame
        loop: true,
      ),
    );
  }

  /* ---------- START-LINE CONTROL ---------- */
  Future<void> showStartLine() async {
    if (_startLineVisible) return;
    _startLineVisible = true;

    final sprite = Sprite(await images.load('startline_nobg.png'));

    // full road-width
    final double w = size.x;

    // banner height = ⅓ of the screen-height
    final double h = size.y;

    // we want the banner’s *bottom* to sit ⅓ of the screen-height from the
    // bottom ⇒ Y-coordinate = 2 ⁄ 3 of the screen-height
    final double yPos = size.y * 2 / 3;

    _startLineRoad = SpriteComponent(
      sprite: sprite,
      size: Vector2(w, h),
      anchor: Anchor.bottomCenter, // bottom edge = position.y
      position: Vector2(w, yPos), // centred horizontally, ⅔ down vertically
      priority: 5, // under cars, above road
    );

    add(_startLineRoad!);
  }

  void hideStartLine() {
    _startLineRoad?..removeFromParent();
    _startLineRoad = null;
    _startLineVisible = false;
  }

  // lane helper
  // ── RacingGame.dart  (add just below class fields) ────────────────
  late List<double> _laneCenters; // computed once after road is built
  late double _laneWidth; // center-to-center distance

  Lane _laneForX(double x) {
    // 0, 1, 2  →  Lane.left / center / right
    int best = 0;
    double dist = double.infinity;
    for (int i = 0; i < _laneCenters.length; i++) {
      final d = (x - _laneCenters[i]).abs();
      if (d < dist) {
        dist = d;
        best = i;
      }
    }
    return Lane.values[best];
  }

  /* ---------- SPAWN GATE ---------- */
  void pauseSpawning() => _spawningEnabled = false;
  void resumeSpawning() => _spawningEnabled = true;

  @override
  Future<void> onGameResize(Vector2 canvasSize) async {
    super.onGameResize(canvasSize);

    if (!_isInitialized) {
      await _loadAssets();
      await _initializeGame();

      _isInitialized = true;

      // Spawn coins periodically only once
      _coinTimer = async.Timer.periodic(const Duration(milliseconds: 1234), (
        timer,
      ) {
        if (_isPaused || gameOver) return;

        final bool allowSpawn = controlScheme != 'OnHand' || isTouching;
        if (_isBraking || currentPlayerSpeed < 70.0) return;
        if (allowSpawn) {
          _spawnCoin();
        }
      });
    }
  }

  Future<void> _saveLeaderboardRecord() async {
    final existing = await LocalPlayerService.loadMyRecord();
    final prefs = await SharedPreferences.getInstance();

    final int finalScore = highScore;

    debugPrint('[LEADERBOARD] Existing record:');
    debugPrint('  Classic: ${existing?.classicHighScore}');
    debugPrint('  Endless: ${existing?.endlessHighScore}');
    debugPrint('  Levels: ${existing?.levelsHighestCompleted}');
    debugPrint('  Coins: ${existing?.totalCoins}');

    final entry = PlayerLeaderboardEntry(
      userId: existing?.userId ?? 'you',
      username: existing?.username ?? 'You',
      profilePicture:
          existing?.profilePicture ?? 'https://i.pravatar.cc/150?img=69',
      totalCoins: (existing?.totalCoins ?? 0) + _coinsCollectedThisRun,

      classicHighScore: mode == GameMode.classic
          ? math.max(finalScore, existing?.classicHighScore ?? 0)
          : existing?.classicHighScore ?? 0,

      endlessHighScore: mode == GameMode.endless
          ? math.max(finalScore, existing?.endlessHighScore ?? 0)
          : existing?.endlessHighScore ?? 0,

      levelsHighestCompleted: mode == GameMode.level
          ? math.max(levelIndex, existing?.levelsHighestCompleted ?? 0)
          : existing?.levelsHighestCompleted ?? 0,

      ownedCars: existing?.ownedCars ?? [carName],
      ownedRoads: existing?.ownedRoads ?? [1],
      friendIds: existing?.friendIds ?? [],
    );
    await LocalPlayerService.saveMyRecord(entry);

    // debugPrint('[LEADERBOARD] New saved record:');
    // debugPrint('  Classic: ${entry.classicHighScore}');
    // debugPrint('  Endless: ${entry.endlessHighScore}');
    // debugPrint('  Levels: ${entry.levelsHighestCompleted}');
    // debugPrint('  Coins: ${entry.totalCoins}');
    debugPrint('[LEADERBOARD] Leaderboard record successfully saved.');
    debugPrint('  New Endless High Score: ${entry.endlessHighScore}');
    debugPrint('  New Classic High Score: ${entry.classicHighScore}');
    debugPrint(
      '  New Levels Highest Completed: ${entry.levelsHighestCompleted}',
    );
    debugPrint('  New Total Coins: ${entry.totalCoins}');
    // Also sync SharedPreferences
    final highScoreKey = _scoreKey;
    final savedHigh = prefs.getInt(highScoreKey) ?? 0;
    if (finalScore > savedHigh) {
      await prefs.setInt(highScoreKey, finalScore);
      debugPrint('[HIGH SCORE SAVE] Synced SharedPreferences: $finalScore');
    }
  }

  void _spawnCoin() async {
    if (_isPaused || gameOver) return; // ✅ Safety check in place

    final animation = await _coinAnimationFuture; // Already preloaded
    final lane = random.nextInt(playerCar.laneCount);
    final coin = SpriteAnimationComponent(
      animation: animation,
      size: Vector2(35, 35),
      position: Vector2(road.getLaneX(lane), 0),
      anchor: Anchor.bottomCenter,
      priority: 0,
    );

    coins.add(coin); // ✅ Add to tracking list
    add(coin); // ✅ Add to the game tree
  }

  // ── RacingGame.dart ───────────────────────────────────────────────
  Future<void> onCoinCollected() async {
    _coinsCollected++; // level tally
    coinCount++; // HUD
    _coinsCollectedThisRun++; // to be flushed by _coinFlushTimer

    // Classic-mode win check (unchanged)
    if (mode == GameMode.classic) {
      const int classicWinThreshold = 150;
      if (!_levelCleared && coinCount >= classicWinThreshold) {
        _levelCleared = true;
        pauseEngine();
        onClassicGameCleared?.call();
      }
    }

    SfxManager.coinCollect(); // sound: already cached
  }

  /*──────────────── Coin pickup – HOT PATH ───────────────*/
  /*──────────────── Coin pickup – HOT PATH ───────────────*/
  void _registerCoinPickup() {
    coinCount++; // HUD display
    _coinsCollected++; // per-level tally
    _coinsCollectedThisRun++; // session flush target

    SfxManager.coinCollect(); // pre-loaded clip, no stutter
  }

  void _checkLevelClearCondition() {
    if (mode != GameMode.level || _levelCleared) return;

    if (_distanceMetres >= levelTargetMetres &&
        _coinsCollected >= levelConfig!.coinTarget) {
      _levelCleared = true;
      pauseEngine();
      if (kDebugMode) {
        debugPrint(
          '[Level Complete ✅] Distance: $_distanceMetres / $levelTargetMetres | Coins: $_coinsCollected / ${levelConfig!.coinTarget}',
        );
      }
      // AdManager.showInterstitialAd(
      //   onAdClosed: () {
          onLevelCleared?.call();
      //   },
      // );
    }
  }

  /* ----------------------  F U E L  ---------------------- */
  /*──────────────── 1. Restart a full tank ───────────────*/
  void restartFuelTank() {
    // assign once to a local, then to the field
    final int fuelLeft = mileageOutTime; // always non-null
    _fuelSecondsLeft = fuelLeft;

    /* 1️⃣  compute spawn interval */
    if (mode == GameMode.classic) {
      final minutesPlayed = gameTime.inMinutes.clamp(1, 10); // 1–10 min
      final scale = 1.0 + minutesPlayed * 0.15; // slower
      _fuelSpawnInterval = (mileageOutTime / (_fuelSpawnCount * scale))
          .floor()
          .clamp(2, 999);
    } else {
      _fuelSpawnInterval = (mileageOutTime / _fuelSpawnCount).floor();
    }

    /* 2️⃣  next fuel-can spawn tick */
    _nextSpawnTick = fuelLeft - _fuelSpawnInterval;

    /* 3️⃣  reset session counters */
    _cansSpawnedThisTank = 0;
    _fuelDepletedHandled = false;
    _lastFuelSpawnTime = null;

    /* 4️⃣  (re)start per-second timer */
    if (_fuelTimer?.isActive != true) {
      _startFuelTimer();
    }
    _fuelPaused = false; // resume countdown immediately
  }

  /*──────────────── 2. Per-second countdown ───────────────*/
  void _startFuelTimer() {
    _fuelTimer ??= async.Timer.periodic(const Duration(milliseconds: 987), (_) {
      if (gameOver || _isPaused) return;
      if (_fuelPaused) return;

      // Ensure _fuelSecondsLeft is initialized
      if (_fuelSecondsLeft == null) return;

      // Decrement safely
      _fuelSecondsLeft = _fuelSecondsLeft! - 1;

      if (_fuelSecondsLeft != null &&
          _fuelSecondsLeft == _nextSpawnTick &&
          _cansSpawnedThisTank < _fuelSpawnCount) {
        _spawnSingleFuelCan();
        _nextSpawnTick = (_fuelSecondsLeft ?? 0) - _fuelSpawnInterval;
      }

      if ((_fuelSecondsLeft ?? 0) <= 0 && !_fuelDepletedHandled) {
        _fuelDepletedHandled = true;
        onFuelEmpty?.call();
      }
    });
  }

  double? _levelTimeRemaining;

  void setupLevel(LevelConfig config) {
    levelTargetMetres = config.targetDistance;
    mileageOutTime = config.fuelSeconds;
    enemyMaxSpeed = config.enemySpeed;
    _fuelSecondsLeft = mileageOutTime;
    _fuelSpawnInterval = (mileageOutTime / 5).floor();
    _levelTimeRemaining = config.timeLimitSeconds.toDouble();
  }

  /*──────────────── 3. Spawn one fuel-can ───────────────*/
  void _spawnSingleFuelCan() {
    final now = DateTime.now();
    _fmtTime(now);

    if (_lastFuelSpawnTime == null) {
    } else {}
    _lastFuelSpawnTime = now;

    final lane = random.nextInt(playerCar.laneCount);

    final can = SpriteComponent(
      sprite: _fuelSprite,
      size: Vector2(50, 50),
      anchor: Anchor.bottomCenter,
      position: Vector2(road.getLaneX(lane), -100), // just above the screen
      priority: 0,
    );

    add(can);
    _fuelCans.add(can);
    _cansSpawnedThisTank++;
  }

  Future<void> _initializeGame() async {
    currentEnemySpeed = playerMaxSpeed;
    enemyMaxSpeed = playerMaxSpeed;
    _migrateLegacyScore();
    _baseEnemySpeed = 300;
    CarNode.enemyMoveSpeed = 0;
    _spawningEnabled = false;
    if (mode == GameMode.level && levelConfig != null) {
      setupLevel(levelConfig!);
      currentEnemySpeed = levelConfig!.enemySpeed * 0.9;
    }

    if (controlScheme == 'Wheel') {
      wheelComponent = SpriteComponent(
        sprite: Sprite(await images.load('wheel.png')),
        size: Vector2(160, 140),
        anchor: Anchor.center,
        position: Vector2(100, size.y - 100),
        priority: 20,
      );
      add(wheelComponent!);

      add(
        TapAreaComponent(
          size: wheelComponent!.size,
          position: wheelComponent!.position,
          handleDragUpdate: (event) {
            final dx = event.localDelta.x;
            lastDragX += dx;
            final angle = lastDragX * pi / 180.0;
            wheelComponent!.angle = angle;
            isWheelHeld = true;
          },
          handleDragEnd: () {
            lastDragX = 0;
            isWheelHeld = false;
            laneChangeInProgress = false;
            wheelComponent!.add(
              RotateEffect.to(
                0,
                EffectController(duration: 0.4, curve: Curves.easeOut),
              ),
            );
          },
        ),
      );
    }

    // Let wheelComponent mount

    final startLineSprite = Sprite(await images.load('startline_nobg.png'));

    road = RoadNode(
      roadSprite: _roadSprite,
      leftSprite: _leftSprite,
      rightSprite: _rightSprite,
      startLineSprite: startLineSprite,

      size: size,
      onCountdownComplete: () {
        isCountingDown = false;
        _speedoTestRunning = true; // ⏱ start the stopwatch
        _spawningEnabled = true;
        CarNode.enemyMoveSpeed = _baseEnemySpeed;
      },
      controlScheme: controlScheme,
    );

    add(road);
    _laneCenters = List.generate(3, (i) => road.getLaneX(i));
    _laneWidth = _laneCenters[1] - _laneCenters[0];

    speedometer = SpriteComponent(
      sprite: _speedometerSprite,
      size: Vector2(140, 140),
      position: Vector2(size.x / 2, size.y - 70),
      anchor: Anchor.center,
      priority: 10,
    );

    pointer = SpriteComponent(
      sprite: _pointerSprite,
      size: Vector2(90, 100),
      position: speedometer.position.clone(),
      anchor: Anchor.center,
      angle: -1.5,
      priority: 11,
    );
    speedometer.removeFromParent();
    pointer.removeFromParent();
    addAll([speedometer, pointer]);
    _pointerLogTimer = async.Timer.periodic(const Duration(seconds: 3), (_) {
      if (gameOver || _isPaused) return;

      if (kDebugMode) {
        // debugPrint(
      }
      //   '[Pointer Monitor] 🎯 Angle: ${_currentPointerAngle.toStringAsFixed(3)} rad '
      //   '| Scroll Speed: ${road.scrollSpeed.toStringAsFixed(1)} '
      //   '| Player Speed: ${currentPlayerSpeed.toStringAsFixed(1)}',
      // );
    });
    pointer.angle = angleMarks.first; // Corresponds to speed 0
    _currentPointerAngle = angleMarks.first;

    // ✅ Ensure pointer updates start
    _speedoIntroDone = true;

    playerCar = CarNode(
      sprite: _playerSprite,
      currentLane: 1,
      isEnemy: false,
      screenSize: size,
      lightSprite: _lightSprite,
      shadowSprite: _shadowSprite,
      carName: carName,
    )..position = Vector2(road.getLaneX(1), size.y * 0.8);
    add(playerCar);

    /* ⛽ fuel ---------------------------------------- */
    _fuelSecondsLeft = selectedCarStats.mileageOutTime;
    _startFuelTimer(); // begin ticking
    mileageOutTime = selectedCarStats.mileageOutTime;
    restartFuelTank();

    _handleControlScheme(controlScheme); // ✅ Now it's safe to call

    final textStyle = TextPaint(
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: const Color.fromARGB(255, 255, 0, 0),
        fontFamily: 'akira',
        shadows: [
          Shadow(
            color: const Color(0xFF001A33),
            offset: Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );

    final double scoreboardWidth = size.x * 0.2;
    final double scoreboardHeight = size.y * 0.1;

    _scoreBoardComponent = SpriteComponent(
      sprite: _scoreBoardSprite,
      size: Vector2(scoreboardWidth, scoreboardHeight),
      position: Vector2(size.x * 0.05, size.y * 0.03), // top-left margin
      anchor: Anchor.topLeft,
      priority: 9,
    );
    add(_scoreBoardComponent);

    scoreText = TextComponent(
      text: '$score',
      textRenderer: textStyle,
      position:
          _scoreBoardComponent.position +
          Vector2(scoreboardWidth / 2, scoreboardHeight * 0.65),
      anchor: Anchor.center,
      priority: 10,
    );
    add(scoreText);

    // // ─────────  F U E L   G A U G E  ──────────────────────────────────────────

    // ---- gauge background ----------------------------------------------------
    final double shortest = min(size.x, size.y); // keeps square
    final double gaugeDia = shortest * 0.2; // ≈ 22 % of screen
    final Vector2 centre = Vector2(
      size.x * 0.17,
      gaugeDia * 8.95,
    ); // left of speedo

    /*──────────── Gauge background ───────────*/
    final fuelMeter = SpriteComponent(
      sprite: _fuelMeterSprite,
      size: Vector2(gaugeDia, gaugeDia / 1.6),
      position: centre,
      anchor: Anchor.center,
      priority: 10,
    );
    add(fuelMeter);

    /*──────────── Needle / pointer ───────────*/

    // 1️⃣  Size of the pointer (same as before)
    final double needleLen = gaugeDia * 0.55; // 55 % of meter width

    // 2️⃣  The centre of the gauge (already calculated)
    //      > centre = Vector2(size.x * 0.15, gaugeDia * 1.95);

    // 3️⃣  Where the *arc’s* centre lies vertically
    final double arcBaseline = centre.y + fuelMeter.size.y * 0.5;

    // 4️⃣  Nudge the pivot up by half the white-dot’s diameter
    final double dotRadius = needleLen * 0.08; // ≈ fine-tuned visually
    final Vector2 pivot = Vector2(centre.x, arcBaseline - dotRadius);

    // 5️⃣  Build the pointer
    _fuelPointer = SpriteComponent(
      sprite: _fuelPointerSprite,
      size: Vector2(10, 30),
      position: pivot, // tail now on the arc’s baseline
      anchor: Anchor.bottomCenter, // rotate around the tail
      angle: _angleForFuel(1.0), // start at “Empty”
      priority: 11,
    );

    add(_fuelPointer);
    _currentFuelAngle = _fuelPointer.angle;

    // Coin Board (top-right)
    final double coinBoardWidth = size.x * 0.2;
    final double coinBoardHeight = size.y * 0.1;

    final Sprite coinBoardSprite = Sprite(await images.load('coins.png'));

    final SpriteComponent coinBoardComponent = SpriteComponent(
      sprite: coinBoardSprite,
      size: Vector2(coinBoardWidth, coinBoardHeight),
      position: Vector2(size.x - coinBoardWidth - 20, size.y * 0.03),
      anchor: Anchor.topLeft,
      priority: 9,
    );
    add(coinBoardComponent);

    _pauseButton = PauseButtonComponent(
      sprite: _pauseSprite,
      position: Vector2(
        size.x - 20,
        coinBoardComponent.position.y + coinBoardHeight + 20,
      ),
      onPressed: triggerPause,
      size: Vector2(50, 50),
    );
    add(_pauseButton);

    // Initialize and add coinText properly
    coinText = TextComponent(
      text: '$coinCount',
      textRenderer: textStyle,
      position:
          coinBoardComponent.position +
          Vector2(coinBoardWidth / 2, coinBoardHeight * 0.65),
      anchor: Anchor.center,
      priority: 10,
    );
    add(coinText);

    // pointer.angle = -pi * 5 / 6; // this is 0 speed angle (far left)
    // _currentPointerAngle = pointer.angle;

    // first wave so the road is never empty
    _spawnEnemies();

    /*────────────────  Mode-aware spawn timer ───────────────*/
    final _spawnInterval = switch (mode) {
      GameMode.classic => const Duration(seconds: 3),
      GameMode.level => const Duration(seconds: 2), // bit spicier
      GameMode.endless => const Duration(seconds: 3),
    };

    _enemySpawnTimer = async.Timer.periodic(_spawnInterval, (_) {
      if (!_spawningEnabled || gameOver || _isPaused) return;

      // Endless mode ⇒ tighten interval every 30 s
      if (mode == GameMode.endless) {
        final secs = gameTime.inSeconds; // see §5
        final newDelay = (3 - secs ~/ 30).clamp(1, 3); // 3 → 1 s

        // every ~10 ticks we rebuild the timer if a shorter delay is due
        if (_enemySpawnTimer.tick % 10 == 0 &&
            _enemySpawnTimer.isActive &&
            _enemySpawnTimer.tick > 0) {
          _enemySpawnTimer.cancel();
          _enemySpawnTimer = async.Timer.periodic(
            Duration(seconds: newDelay.toInt()),
            (_) => _spawnEnemies(),
          );
        }
      }

      _spawnEnemies();
    });

    _startScoreTimer();
    // _loadHighScore();
    await _loadHighScoreSharedPrefs();
    _debugLogTimer = async.Timer.periodic(const Duration(seconds: 3), (_) {
      if (gameOver || _isPaused) return;
    });
    isLoaded = true;
  }

  void setControlScheme(String scheme) {
    if (controlScheme == scheme) return;
    controlScheme = scheme;
    _handleControlScheme(scheme); // instant rewire
  }

  /// Exposed so UI can re-wire controls instantly.
  Future<void> updateControlScheme() async {
    final prefs = await SharedPreferences.getInstance();
    final newScheme = prefs.getString('control_scheme') ?? 'Swipe';

    if (newScheme != controlScheme) {
      controlScheme = newScheme;
      _handleControlScheme(controlScheme);

      // 🔁 Handle swipe control external activation
      if (controlScheme == 'Swipe') {
        enableSwipeControl(this);
      }
    }
  }

  void _handleControlScheme(String scheme) {
    accelerometerSubscription?.cancel();
    onHandComponent?.removeFromParent();
    onHandComponent = null;
    wheelComponent?.removeFromParent();
    wheelComponent = null;
    children.whereType<TapAreaComponent>().forEach((c) => c.removeFromParent());

    switch (scheme) {
      case 'Tilt':
        add(TiltControlComponent());
        break;
      case 'Wheel':
        enableWheelControl(this);
        break;
      case 'Swipe':
        enableSwipeControl(this); // ✅ Here it is
        break;
      case 'Tap':
        add(TapLaneControlComponent()); // ✅ attach to game tree
        break;
      // case 'OnHand':
      //   enableOnHandDragControl(); // Drag logic handled via update()
      //   // _enableOnHandJoystick();
      //   break;
    }
  }

  void triggerPause() {
    if (_isPaused || gameOver) return; // 🔒 prevent double pause
    _isPaused = true;
    pauseEngine();
    onPause?.call();
    _debugLogTimer.cancel();
    print('[DEBUG] triggerPause fired');
  }

  void resumeGame() {
    // resumeEngine();
    if (!_isPaused) return;
    _isPaused = false;
    resumeEngine();
    _debugLogTimer = async.Timer.periodic(const Duration(seconds: 3), (_) {
      if (gameOver || _isPaused) return;
    });
  }

  void _spawnEnemies() {
    final Map<int, double> laneY = {
      0: double.infinity - 250,
      1: double.infinity,
      2: double.infinity - 250,
    };

    for (final child in children) {
      if (child is CarNode && child.isEnemy) {
        final lane = child.currentLane;
        laneY[lane] = min(laneY[lane]!, child.position.y);
      }
    }

    final minGap = size.y * 0.9;
    final allowedLanes = [0, 1, 2];
    final safeLanes = laneY.entries
        .where((e) => allowedLanes.contains(e.key) && e.value > minGap)
        .map((e) => e.key)
        .toList();

    if (safeLanes.isEmpty) return;

    final lane = safeLanes[random.nextInt(safeLanes.length)];
    final sprite = _enemySprites[random.nextInt(_enemySprites.length)];

    add(
      CarNode(
        sprite: sprite,
        currentLane: lane,
        isEnemy: true,
        screenSize: size,
        lightSprite: _lightSprite,
        shadowSprite: _shadowSprite,
      ),
    );
  }

  // ── RacingGame.dart  ──
  void _startScoreTimer() {
    _scoreTimer = async.Timer.periodic(const Duration(seconds: 1), (_) {
      if (gameOver || _isPaused) return;
    });
  }

  void updateScrollSpeed() {
    if (_isBoosting) return;

    const double scrollBoostThreshold = 300.0;
    const double maxSpeedForScroll = 600.0;
    const double baseMultiplier = 2.5;
    const double boostedMultiplier = 4.5;

    final double normalized =
        ((currentPlayerSpeed - scrollBoostThreshold) /
                (maxSpeedForScroll - scrollBoostThreshold))
            .clamp(0.0, 1.0);

    final double multiplier =
        baseMultiplier + (boostedMultiplier - baseMultiplier) * normalized;

    // Force scroll in Endless mode
    final bool allowRoadScroll =
        mode == GameMode.endless || controlScheme != 'OnHand' || isTouching;

    scrollSpeed = allowRoadScroll ? currentPlayerSpeed * multiplier : 0.0;

    road.scrollSpeed = scrollSpeed;
    CarNode.enemyMoveSpeed = currentPlayerSpeed + 120 * multiplier * 0.6;
  }

  double _speedFromPointerAngle(double angle) {
    // Find the segment in angleMarks that bounds this angle
    for (int i = 0; i < angleMarks.length - 1; i++) {
      final a0 = angleMarks[i];
      final a1 = angleMarks[i + 1];
      if (angle >= min(a0, a1) && angle <= max(a0, a1)) {
        final t = (angle - a0) / (a1 - a0); // 0-to-1 within segment
        return lerpDouble(speedMarks[i], speedMarks[i + 1], t)!;
      }
    }
    // Fallback (shouldn’t happen): clamp to ends
    return angle < angleMarks.first ? speedMarks.first : speedMarks.last;
  }

  void updateSpeedometer() {
    if (!_speedoIntroDone) return;

    final double speed = _isBoosting
        ? (currentPlayerSpeed * 1.5).clamp(0, playerMaxSpeed * 1.5)
        : currentPlayerSpeed;

    final double clampedSpeed = speed.clamp(speedMarks.first, speedMarks.last);

    int index = 0;
    for (int i = 0; i < speedMarks.length - 1; i++) {
      if (clampedSpeed >= speedMarks[i] && clampedSpeed <= speedMarks[i + 1]) {
        index = i;
        break;
      }
    }

    final double lowerSpeed = speedMarks[index];
    final double upperSpeed = speedMarks[index + 1];
    final double lowerAngle = angleMarks[index];
    final double upperAngle = angleMarks[index + 1];

    final double t = ((clampedSpeed - lowerSpeed) / (upperSpeed - lowerSpeed))
        .clamp(0.0, 1.0);
    final double targetAngle = lerpDouble(lowerAngle, upperAngle, t)!;

    const smoothing = 5.0; // hard-coded
    final k = min(1.0, smoothing * 0.016); // → 0.08   (at 60 FPS)
    _currentPointerAngle += (targetAngle - _currentPointerAngle) * k;

    pointer.angle = _currentPointerAngle;
  }

  void activateBoost() {
    if (_isBoosting) return;
    _isBoosting = true;

    // Calculate base scroll speed first (same logic as _updateScrollSpeed)
    const double scrollBoostThreshold = 300.0;
    const double maxSpeedForScroll = 600.0;
    const double baseMultiplier = 2.5;
    const double boostedMultiplier = 4.5;

    final normalized =
        ((currentPlayerSpeed - scrollBoostThreshold) /
                (maxSpeedForScroll - scrollBoostThreshold))
            .clamp(0.0, 1.0);

    final multiplier =
        baseMultiplier + (boostedMultiplier - baseMultiplier) * normalized;

    final baseScrollSpeed = currentPlayerSpeed * multiplier;

    // ✅ Apply boost bonus (+400 units)
    scrollSpeed = baseScrollSpeed + 400.0;
    road.scrollSpeed = scrollSpeed;
    CarNode.enemyMoveSpeed = scrollSpeed * 0.9;

    // ADD THIS:
    updateSpeedometer();
  }

  void deactivateBoost() {
    if (!_isBoosting) return;
    _isBoosting = false;

    const double scrollBoostThreshold = 300.0;
    const double maxSpeedForScroll = 600.0;
    const double baseMultiplier = 2.5;
    const double boostedMultiplier = 4.5;

    final normalized =
        ((currentPlayerSpeed - scrollBoostThreshold) /
                (maxSpeedForScroll - scrollBoostThreshold))
            .clamp(0.0, 1.0);

    final multiplier =
        baseMultiplier + (boostedMultiplier - baseMultiplier) * normalized;

    scrollSpeed = currentPlayerSpeed * multiplier;
    road.scrollSpeed = scrollSpeed;
    CarNode.enemyMoveSpeed = scrollSpeed * 0.9;
    // ADD THIS:
    updateSpeedometer();
  }

  void applyBrake() {
    if (gameOver || isPaused) return;
    if (!_isBraking) SfxManager.brake(); // ← ADD
    _isBraking = true;
  }

  void releaseBrake() {
    if (gameOver || isPaused) return;
    _isBraking = false;
  }

  // Nitro boost
  // ── RacingGame.dart ──
  // RacingGame.dart
  async.Future<void> activateNitro() async {
    if (isCountingDown || _nitroActive || gameOver || isPaused) return;

    _nitroActive = true;
    _isBoosting = true;

    unawaited(SfxManager.nitroStart()); // includes one-shot and loop internally

    _nitroSfxStart = DateTime.now();

    currentPlayerSpeed = playerMaxSpeed * _nitroFactor;

    const baseMultiplier = 2.5;
    const boostedMultiplier = 4.5;
    final normalised = ((currentPlayerSpeed - 300) / (600 - 300)).clamp(
      0.0,
      1.0,
    );
    final multiplier =
        baseMultiplier + (boostedMultiplier - baseMultiplier) * normalised;

    scrollSpeed = currentPlayerSpeed * multiplier;
    road.scrollSpeed = scrollSpeed;
    CarNode.enemyMoveSpeed = scrollSpeed * 0.9;

    updateSpeedometer();
    playerCar.toggleNitroTail(true);

    _nitroTimer?.cancel();
    _nitroTimer = async.Timer(_nitroTime, deactivateNitro);
  }

  async.Future<void> deactivateNitro() async {
    if (!_nitroActive) return;
    await SfxManager.nitroStop();
    _nitroActive = false;
    _isBoosting = false;
    _nitroTimer?.cancel();
    _nitroTimer = null;
    playerCar.toggleNitroTail(false);

    // _nitroPlayer.stop(); // 🔇 cut the sound

    /* take a snapshot of the boosted speeds – we’ll ease down from here */
    _recoveryStartPlayer = currentPlayerSpeed;
    _recoveryStartScroll = scrollSpeed;
    _recoveryStartEnemy = CarNode.enemyMoveSpeed;
    _recoveryElapsed = 0.0; // reset timer
  }

  Future<void> updatePlayerCar(String carImagePath) async {
    final prefs = await SharedPreferences.getInstance();
    final filename = carImagePath.split('/').last;
    await prefs.setString('selected_car_path', filename);

    final newSprite = Sprite(await images.load('assets/images/$filename'));

    // Update stats for new car
    final carKey = filename.replaceAll('.png', '');
    selectedCarStats = carPerformanceMap[carKey] ?? carPerformanceMap['hero1']!;
    selectedCarStats = carPerformanceMap[carKey] ?? carPerformanceMap['hero1']!;
    SfxManager.setActiveCar(selectedCarStats); // ← ADD

    currentPlayerSpeed = selectedCarStats.baseSpeed;
    playerMaxSpeed = selectedCarStats.maxSpeed;
    currentEnemySpeed = selectedCarStats.baseSpeed * 0.9;
    enemyMaxSpeed = selectedCarStats.maxSpeed * 0.9;
    CarNode.enemyMoveSpeed = currentEnemySpeed; // ✅ Immediate movement

    if (playerCar.isMounted) {
      playerCar.removeFromParent();
    }

    await Future.delayed(const Duration(milliseconds: 50));

    playerCar = CarNode(
      sprite: newSprite,
      currentLane: 1,
      isEnemy: false,
      screenSize: size,
      lightSprite: _lightSprite,
      shadowSprite: _shadowSprite,
      carName: carKey,
    )..position = Vector2(road.getLaneX(1), size.y * 0.8);

    add(playerCar);
  }

  OnHandDragArea? onHandComponent;

  Future<void> enableOnHandDragControl() async {
    if (onHandComponent != null && onHandComponent!.isMounted) return;

    onHandComponent = OnHandDragArea(game: this);
    add(onHandComponent!);
  }

  // ─── helper: maps 0-1 to dial angles ───
  double _angleForFuel(double f) {
    const double empty = -3 * pi / 6.2; //  –135°  (your custom range)
    const double full = 3 * pi / 7.5; //   +??°  (matches the sprite)
    return lerpDouble(empty, full, f)!;
  }

  // ─── smooth update each frame ───
  void _updateFuelGauge(double dt) {
    // Guard: if the fuel counter hasn’t been initialised yet, skip drawing.
    final fuelLeft = _fuelSecondsLeft;
    if (fuelLeft == null) return;

    // Normalise 0-1
    final double fuel01 = (fuelLeft / mileageOutTime).clamp(0.0, 1.0);

    final double target = _angleForFuel(fuel01);

    const double smoothing = 4.0; // bigger = snappier
    _currentFuelAngle +=
        (target - _currentFuelAngle) * math.min(1.0, smoothing * dt);

    _fuelPointer.angle = _currentFuelAngle;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;

    updateScrollSpeed();
    if (_fuelSecondsLeft == null) return;

    if (_collisionCooldown > 0) {
      _collisionCooldown -= dt;
      if (_collisionCooldown < 0) _collisionCooldown = 0;
    }
    if (showDamageFlash) {
      damageFlashOpacity -= dt * 2.5; // fades out over 0.4 seconds
      if (damageFlashOpacity <= 0) {
        damageFlashOpacity = 0;
        showDamageFlash = false;
      }
    }

    if (_levelCleared) {
      if (!_levelClearNotified) {
        _levelClearNotified = true;
        onLevelCleared?.call(); // ← tell UI layer
      }
      return; // skip the rest of the tick
    }

    if (_levelTimeRemaining != null) {
      _levelTimeRemaining = (_levelTimeRemaining! - dt).clamp(
        0,
        double.infinity,
      );
      if (_levelTimeRemaining == 0) {
        onLevelFailed?.call("Time's up");
        pauseEngine();
        triggerGameOver();
        return;
      }
    }

    final fuelLeft = _fuelSecondsLeft; // promote to non-nullable local
    if (fuelLeft != null && fuelLeft <= 0) {
      onLevelFailed?.call('Out of fuel');
      pauseEngine();
      triggerGameOver();
      return;
    }

    /* ── 1. Early exits ───────────────────────────────────────── */
    if (isCountingDown) return; // pre-race banner
    if (!_isInitialized || gameOver || _isPaused) return;
    gameTime += Duration(milliseconds: (dt * 1000).toInt());

    /* ── SPEEDOMETER TEST ─────────────────────────────────────────── */
    if (_speedoTestRunning) {
      // done once we visually reach, or exceed, maxSpeed
      final visible = _speedFromPointerAngle(_currentPointerAngle);
      if (visible >= selectedCarStats.maxSpeed - 1.0) {
        // ±1 km/h tolerance

        _speedoTestRunning = false;
      }
    }

    /* ── 2. Smooth Nitro fade-out (if any) ─────────────────────── */
    if (_recoveryStartPlayer != null) {
      _recoveryElapsed += dt;
      final t = (_recoveryElapsed / _recoveryDuration).clamp(0.0, 1.0);

      currentPlayerSpeed = lerpDouble(
        _recoveryStartPlayer!,
        playerMaxSpeed,
        t,
      )!;
      scrollSpeed = lerpDouble(
        _recoveryStartScroll!,
        currentPlayerSpeed * 3.2,
        t,
      )!;
      CarNode.enemyMoveSpeed = lerpDouble(
        _recoveryStartEnemy!,
        currentPlayerSpeed * 2.9,
        t,
      )!;

      updateSpeedometer();
      road.scrollSpeed = scrollSpeed;

      if (t >= 1.0) {
        // finished – clear snapshots
        _recoveryStartPlayer = _recoveryStartScroll = _recoveryStartEnemy =
            null;
      }
    }

    /* ── 3. Brake handling ─────────────────────────────────────── */
    if (_isBraking) {
      const brakeStrength = 4.0;
      currentPlayerSpeed = max(
        0,
        currentPlayerSpeed - brakeStrength * dt * playerMaxSpeed,
      );
      scrollSpeed = currentPlayerSpeed * 2.5;
      road.scrollSpeed = scrollSpeed;
      updateSpeedometer();
    }

    /* ── 4. Enemy cars (collision & pass detection) ────────────── */
    for (final child in children.toList()) {
      if (child is! CarNode || !child.isEnemy) continue;

      child.update(dt);

      if (!_nitroActive && child.toRect().overlaps(playerCar.toRect())) {
        onPlayerHitEnemy(child.position); // ✅ Use your 3-hit logic
        return;
      }

      // final onHand = controlScheme == 'OnHand';
      // final allowScoring = !onHand || (onHand && isTouching);
      // if (allowScoring &&
      //     !child.passedPlayer &&
      //     child.position.y > playerCar.position.y + playerCar.size.y / 2) {
      //   child.passedPlayer = true;
      //   if (++score > highScore) {
      //     highScore = score;
      //     _highScoreDirty = true;
      //     debugPrint('[DEBUG] New Endless High Score: $highScore');
      //   }
      // }
    }

    /* ── 5. Save high-score if it changed ──────────────────────── */
    // if (_highScoreDirty) {
    //   _highScoreDirty = false;
    //   Future.microtask(_saveHighScore);
    // }
    // if (_highScoreDirty) {
    //   _highScoreDirty = false;
    //   Future.microtask(_saveHighScoreSharedPrefs);
    // }
    /* ── 6. On-Hand control component (mount lazily) ───────────── */
    if (controlScheme == 'OnHand') {
      enableOnHandDragControl();
    }

    /* ── 7. Player acceleration (all schemes) ──────────────────── */
    if (!gameOver && !_isPaused) {
      if (controlScheme == 'OnHand') {
        // accelerate only while touching; coast slowly when not
        final double accel = isTouching ? 1.0 : -0.6; // tweak to taste
        currentPlayerSpeed += accel * acceleration * dt;
      } else {
        currentPlayerSpeed += 0.7 * acceleration * dt; // ← true linear ramp
      }

      currentPlayerSpeed = currentPlayerSpeed.clamp(0.0, playerMaxSpeed);

      if (_recoveryStartPlayer == null) {
        // Allow normal acceleration / deceleration flow
        updateScrollSpeed();

        // if (mode == GameMode.endless) {
        //   // debugPrint('[Endless] road.scrollSpeed=${road.scrollSpeed}');
        // }

        // ─── Distance accumulation ──────────────────────────────
        if (road.scrollSpeed > 0) {
          // ignore when stationary
          _distanceMetres += (road.scrollSpeed * dt) / _pxPerMetre;

          // Centralised level-mode completion check
          if (mode == GameMode.level && !_levelCleared) {
            _checkLevelClearCondition(); // ← single source of truth
          }

          // Score is defined as floor(distance)
          final int newScore = _distanceMetres.floor();
          if (newScore > score) {
            score = newScore;
            if (score > highScore) {
              highScore = score;
              _highScoreDirty = true; // deferred persistence
            }
          }
        }
      }

      updateSpeedometer();
    }
    /* ── 8. Coins movement & pickup ─────────────────────────────── */
    for (final coin in coins.toList()) {
      coin.position.y += road.scrollSpeed * dt;

      if (coin.position.y > size.y) {
        coin.removeFromParent();
        coins.remove(coin);
        continue;
      }

      final double laneWidth =
          _laneWidth; // Or match to your actual lane spacing
      final double dx = (coin.position.x - playerCar.position.x).abs();
      final double dy = (coin.position.y - (playerCar.position.y - 40)).abs();

      if (dx < laneWidth * 0.35 &&
          dy < (coin.size.y + playerCar.size.y) * 0.5) {
        coin.removeFromParent();
        coins.remove(coin);
        _registerCoinPickup(); // ← centralised handling
        //

        // Check Classic mode win condition based on coins
        if (!_levelCleared && mode == GameMode.classic) {
          const int classicWinThreshold = 150;

          if (coinCount >= classicWinThreshold) {
            _levelCleared = true;
            pauseEngine(); // stop all game activity
            onClassicGameCleared?.call(); // trigger overlay
            if (kDebugMode) {
              debugPrint('[Classic] Level Cleared with $coinCount coins!');
            }
          }
        }
      }
    }

    /* ── 9. Fuel-cans movement & pickup ─────────────────────────── */
    for (final can in _fuelCans.toList()) {
      can.position.y += road.scrollSpeed * dt;

      if (can.position.y > size.y) {
        can.removeFromParent();
        _fuelCans.remove(can);

        continue;
      }

      final double laneWidth =
          _laneWidth; // Or match to your actual lane spacing
      final double dx = (can.position.x - playerCar.position.x).abs();
      final double dy = (can.position.y - (playerCar.position.y - 40)).abs();

      if (dx < laneWidth * 0.35 && dy < (can.size.y + playerCar.size.y) * 0.5) {
        can.removeFromParent();
        _fuelCans.remove(can);

        SfxManager.fuelCollect();
        restartFuelTank(); // ← centralised handling
        //

        //   can.position.y += road.scrollSpeed * dt;

        //   if (can.position.y > size.y) {
        //     _fuelCans..remove(can);
        //     can.removeFromParent();
        //     continue;
        //   }

        //   if (can.toRect().overlaps(playerCar.toRect())) {
        //     _fuelCans..remove(can);
        //     can.removeFromParent();
        //     SfxManager.fuelCollect();
        //     restartFuelTank(); // refill
      }
    }

    const double minRollingSpeed =
        5.0; // px/s: treat anything under this as 'stopped'

    final bool carMoving = currentPlayerSpeed > minRollingSpeed;

    // ① car just stopped → pause the fuel countdown
    if (!carMoving) _fuelPaused = true;

    // ② car just started moving → restart the countdown
    if (carMoving) {
      _fuelPaused = false; // 🔑 un-pause

      // ensure a timer exists (it might have been cancelled elsewhere)
      if (_fuelTimer?.isActive != true) {
        _startFuelTimer();
      }
    }

    /* ──10. Refresh HUD text ───────────────────────────────────── */
    scoreText.text = '$score';
    coinText.text = '$coinCount';
    _updateFuelGauge(dt);
  }

  void onPlayerHitEnemy(Vector2 enemyPosition) {
    if (mode != GameMode.classic) {
      SfxManager.crash();
      triggerGameOver();
      return;
    }

    if (_collisionCooldown > 0) return;

    _collisionCount++;
    _collisionCooldown = 1.0;
    SfxManager.hit();

    showDamageFlash = true;
    damageFlashOpacity = 1.0;

    // Determine enemy and player lanes
    _laneForX(enemyPosition.x);
    _laneForX(playerCar.position.x);

    if (_collisionCount >= 4) {
      SfxManager.crash();
      triggerGameOver();
    }
  }

  void revive() {
    if (!gameOver) return;

    debugPrint('[REVIVE] Reviving game after rewarded ad');

    gameOver = false;
    _collisionCount = 0; // Reset hits in Classic mode
    _fuelDepletedHandled = false;

    // Clear all enemies
    children.whereType<CarNode>().where((c) => c.isEnemy).toList().forEach((
      enemy,
    ) {
      enemy.removeFromParent();
    });

    // Temporarily disable spawning
    pauseSpawning();

    // Resume spawning after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (!gameOver) {
        resumeSpawning();
        debugPrint('[REVIVE] Enemy spawning resumed.');
      }
    });

    // Restart fuel timer if needed
    if (_fuelTimer?.isActive != true && !_fuelPaused) {
      _startFuelTimer();
    }

    // Restart timers
    _scoreTimer = async.Timer.periodic(const Duration(seconds: 1), (_) {
      if (gameOver || _isPaused) return;
    });

    _enemySpawnTimer = async.Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_spawningEnabled || gameOver || _isPaused) return;
      _spawnEnemies();
    });

    _coinTimer = async.Timer.periodic(const Duration(milliseconds: 1234), (_) {
      if (_isPaused || gameOver) return;
      if (_isBraking || currentPlayerSpeed < 70.0) return;
      final bool allowSpawn = controlScheme != 'OnHand' || isTouching;
      if (allowSpawn) _spawnCoin();
    });

    resumeEngine();

    debugPrint('[REVIVE] Game resumed successfully.');
  }

  void triggerGameOver() {
    _saveLeaderboardRecord();
    gameOver = true;
    _scoreTimer.cancel();
    _coinFlushTimer?.cancel();
    _enemySpawnTimer.cancel();
    _coinTimer.cancel();
    _fuelTimer?.cancel();
    // _saveHighScore();

    // ✅ This is what saves the PlayerLeaderboardEntry
    accelerometerSubscription?.cancel();
    pauseEngine();
    onGameOver?.call();
    _debugLogTimer.cancel();
    _pointerLogTimer.cancel();
    onHandComponent?.removeFromParent();
    onHandComponent = null;
    // AdManager.showInterstitialAd(
    //   onAdClosed: () {
        // Only after ad is closed, notify that game over overlay should show
        onGameOver?.call();
    //   },
    // );
  }

  // Future<void> _loadHighScore() async {
  //   final record = await LocalPlayerService.loadMyRecord();
  //   final prefs = await SharedPreferences.getInstance();
  //   if (record != null) {
  //     switch (mode) {
  //       case GameMode.classic:
  //         highScore = record.classicHighScore;
  //         break;
  //       case GameMode.endless:
  //         highScore = record.endlessHighScore;
  //         break;
  //       case GameMode.level:
  //         highScore = record.levelsHighestCompleted;
  //         break;
  //     }
  //   } else {
  //     // fallback to SharedPreferences
  //     final saved = prefs.getInt(_scoreKey) ?? 0;
  //     highScore = saved;
  //   }
  //   debugPrint('[HIGH SCORE LOAD] High score loaded: $highScore');
  // }

  // Save high score
  // Future<void> _saveHighScoreSharedPrefs() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final saved = prefs.getInt(_scoreKey) ?? 0;
  //   final newHigh = highScore;

  //   if (newHigh > saved) {
  //     debugPrint('[HIGH SCORE SAVE] Updating SharedPreferences: $newHigh');
  //     await prefs.setInt(_scoreKey, newHigh);

  //     // 🟢 Ensure leaderboard record is updated too
  //     final existing = await LocalPlayerService.loadMyRecord();
  //     final entry = PlayerLeaderboardEntry(
  //       userId: existing?.userId ?? 'you',
  //       username: existing?.username ?? 'You',
  //       profilePicture:
  //           existing?.profilePicture ?? 'https://i.pravatar.cc/150?img=69',
  //       totalCoins: existing?.totalCoins ?? 0,
  //       classicHighScore: existing?.classicHighScore ?? 0,
  //       endlessHighScore: newHigh, // ✅ Update this
  //       levelsHighestCompleted: existing?.levelsHighestCompleted ?? 0,
  //       ownedCars: existing?.ownedCars ?? [],
  //       ownedRoads: existing?.ownedRoads ?? [],
  //       friendIds: existing?.friendIds ?? [],
  //     );
  //     await LocalPlayerService.saveMyRecord(entry);
  //     debugPrint('[LEADERBOARD] Synced leaderboard endlessHighScore: $newHigh');
  //   } else {
  //     debugPrint('[HIGH SCORE SAVE] Not updating: existing $saved >= $newHigh');
  //   }
  // }

  // Load high score
  Future<void> _loadHighScoreSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_scoreKey) ?? 0;
    highScore = saved;
    debugPrint('[HIGH SCORE LOAD] From SharedPreferences: $highScore');
  }
  // Future<void> _saveHighScore() async {
  //   final box = Hive.box('scores');
  //   final saved = box.get(_scoreKey, defaultValue: 0) as int;
  //   final newHigh = highScore;

  //   if (newHigh > saved) {
  //     debugPrint('[HIGH SCORE SAVE] Updating Hive: $newHigh');
  //     await box.put(_scoreKey, newHigh);
  //   } else {
  //     debugPrint(
  //       '[HIGH SCORE SAVE] Not updating Hive: existing $saved >= $newHigh',
  //     );
  //   }
  // }

  void _migrateLegacyScore() async {
    final box = Hive.box('scores');
    if (box.containsKey('high_score')) {
      final legacy = box.get('high_score') as int;
      box.put('high_score_classic', legacy);
      box.delete('high_score'); // optional cleanup
    }
  }

  void resetScore() {
    score = 0;
    _distanceMetres = 0;
  }
}

class TapAreaComponent extends PositionComponent with DragCallbacks {
  final void Function(DragUpdateEvent) handleDragUpdate;
  final void Function()? handleDragEnd;

  TapAreaComponent({
    required Vector2 size,
    required Vector2 position,
    required this.handleDragUpdate,
    this.handleDragEnd,
  }) {
    this.size = size;
    this.position = position;
    anchor = Anchor.center;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) => handleDragUpdate(event);

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    return handleDragEnd?.call();
  }
}

class DebugRect extends PositionComponent {
  final Rect rect;
  bool showDamageFlash = false;
  double damageFlashOpacity = 0.0;

  DebugRect({required this.rect}) {
    priority = 9999;
    size = rect.size.toVector2();

    position = rect.topLeft.toVector2();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (showDamageFlash && damageFlashOpacity > 0) {
      final paint = Paint()
        ..color = const Color(0xFFFF0000).withOpacity(damageFlashOpacity);
      canvas.drawRect(size.toRect(), paint);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (showDamageFlash) {
      damageFlashOpacity -= dt * 2.5; // fades in ~0.4 sec
      if (damageFlashOpacity <= 0) {
        damageFlashOpacity = 0;
        showDamageFlash = false;
      }
    }
  }

  void triggerFlash() {
    showDamageFlash = true;
    damageFlashOpacity = 1.0;
  }
}
