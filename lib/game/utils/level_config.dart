import 'dart:math' as math;

class LevelConfig {
  final int level;
  final double targetDistance; // metres
  final int timeLimitSeconds; // sec
  final int fuelSeconds; // sec
  final double enemySpeed; // px / sec
  final double spawnRateSeconds; // sec
  final int coinTarget;
  final bool allowNitro;

  const LevelConfig({
    required this.level,
    required this.targetDistance,
    required this.timeLimitSeconds,
    required this.fuelSeconds,
    required this.enemySpeed,
    required this.spawnRateSeconds,
    required this.coinTarget,
    required this.allowNitro,
  });
}

/* ─────────────────────────────────────────────────────────────
 *  ONE source-of-truth for the scaling rules
 * ────────────────────────────────────────────────────────────*/
const int kNumLevels = 100;
const double kStartDistance = 20; // metres
const int kStartTimeLimit = 89; // seconds
const int kMinTimeLimit = 60;
const int kStartFuel = 45; // seconds
const int kMinFuel = 30;
const double kStartEnemySpeed = 255; // px / s
const double kEnemySpeedStep = 5;
const double kStartSpawnRate = 2.5; // seconds
const double kMinSpawnRate = 1.50;
const double kSpawnRateStep = 0.05;

/*  Helper that clamps a value between min and max. */
T _clamp<T extends num>(T v, T min, T max) => math.max(min, math.min(max, v));

/* ─────────────────────────────────────────────────────────────
 *  List<LevelConfig> generated on the fly
 * ────────────────────────────────────────────────────────────*/
final List<LevelConfig> levelConfigs = List<LevelConfig>.generate(kNumLevels, (
  int i,
) {
  final lvl = i + 1; // level numbers start at 1
  return LevelConfig(
    level: lvl,
    targetDistance: kStartDistance + i * 3, // +2 m
    timeLimitSeconds: _clamp(kStartTimeLimit - i, kMinTimeLimit, 9999), // –1 s
    fuelSeconds: _clamp(
      kStartFuel - (i ~/ 2),
      kMinFuel,
      9999,
    ), // –1 s every 2 lv
    enemySpeed: kStartEnemySpeed + i * kEnemySpeedStep, // +5 px/s
    spawnRateSeconds: _clamp(
      kStartSpawnRate - i * kSpawnRateStep,
      kMinSpawnRate,
      kStartSpawnRate,
    ),
    coinTarget: 1 + i, // +1 coin per level
    allowNitro: i.isOdd, // true on 2,4,6… (your pattern)
  );
}, growable: false);
