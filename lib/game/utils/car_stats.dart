// lib/car_stats.dart
// Central place to keep all per‑car performance numbers, including price.
// -----------------------------------------------------------------------
//  • Brake and lights sounds are GLOBAL (generic).
//  • Each hero keeps its OWN nitro‑start whoosh.
//  • If you ever want nitro‑loop / end per hero, just
//    uncomment those fields and supply the files.
// -----------------------------------------------------------------------

import 'package:meta/meta.dart';

@immutable
class CarStats {
  final double baseSpeed;
  final double maxSpeed;
  final double timeToMaxSpeed;
  final int mileageOutTime;
  final int cost; // ⬅ price in coins (0 = free)

  // per‑car SFX
  final String nitroStartSfx;
  // final String nitroLoopSfx;
  // final String nitroEndSfx;

  const CarStats({
    required this.baseSpeed,
    required this.maxSpeed,
    required this.timeToMaxSpeed,
    required this.mileageOutTime,
    required this.nitroStartSfx,
    this.cost = 0,
  });
}

/*──────── baseline constants ───────*/
const double _baselineMaxSpeed = 250;
const double _baselineTimeToMax = 2; // seconds
const int _baselineMileage = 15; // seconds of fuel

const double _accelPerSecond =
    _baselineMaxSpeed / _baselineTimeToMax; // 125 km/h²

/*──────── helper ───────────────────*/
CarStats _makeStats({
  required String heroId,
  required double maxSpeed,
  required int cost,
}) {
  final tToMax = double.parse((maxSpeed / _accelPerSecond).toStringAsFixed(1));
  final mileage = (_baselineMileage * _baselineMaxSpeed / maxSpeed).round();

  String _sfx(String file) => 'sounds/$file';

  return CarStats(
    baseSpeed: 0,
    maxSpeed: maxSpeed,
    timeToMaxSpeed: tToMax,
    mileageOutTime: mileage,
    nitroStartSfx: _sfx('nitro_start.wav'),
    cost: cost,
  );
}

/*──────── catalogue ───────────────*/
final Map<String, CarStats> carPerformanceMap = {
  // heroId : CarStats
  'hero1': const CarStats(
    baseSpeed: 0,
    maxSpeed: _baselineMaxSpeed,
    timeToMaxSpeed: _baselineTimeToMax,
    mileageOutTime: _baselineMileage,
    nitroStartSfx: 'sounds/nitro_start.wav',
    cost: 0, // starter car
  ),

  // 'hero2': _makeStats(heroId: 'hero2', maxSpeed: 260, cost: 1),
  // 'hero3': _makeStats(heroId: 'hero3', maxSpeed: 260, cost: 1),
  // 'hero4': _makeStats(heroId: 'hero4', maxSpeed: 270, cost: 1),
  // 'hero5': _makeStats(heroId: 'hero5', maxSpeed: 270, cost: 1),
  // 'hero6': _makeStats(heroId: 'hero6', maxSpeed: 280, cost: 1),
  // 'hero7': _makeStats(heroId: 'hero7', maxSpeed: 300, cost: 1),
  // 'hero8': _makeStats(heroId: 'hero8', maxSpeed: 320, cost: 1),
  'hero2': _makeStats(heroId: 'hero2', maxSpeed: 260, cost: 499),
  'hero3': _makeStats(heroId: 'hero3', maxSpeed: 260, cost: 699),
  'hero4': _makeStats(heroId: 'hero4', maxSpeed: 270, cost: 899),
  'hero5': _makeStats(heroId: 'hero5', maxSpeed: 270, cost: 3749),
  'hero6': _makeStats(heroId: 'hero6', maxSpeed: 280, cost: 2499),
  'hero7': _makeStats(heroId: 'hero7', maxSpeed: 300, cost: 2999),
  'hero8': _makeStats(heroId: 'hero8', maxSpeed: 320, cost: 4999),
};

// Road shop assets (used in RoadShopScreen)
// final List<String> roadAssets = [
//   'assets/images/roads/Garden.png',
//   'assets/images/roads/Snow.png',
//   'assets/images/roads/Lawn.png',
//   'assets/images/roads/Park.png',
//   'assets/images/roads/road.png',
//   'assets/images/roads/Street.png',
//   'assets/images/roads/Beach.png',
// ];

// Metadata for each road (price and label shown in shop)
class RoadInfo {
  final int cost;
  final String label;

  const RoadInfo({required this.cost, required this.label});
}

// final Map<String, RoadInfo> roadData = {
//   'garden': RoadInfo(cost: 1, label: 'Garden'),
//   'snow_city': RoadInfo(cost: 3, label: 'Snow Road'),
//   'lawn': RoadInfo(cost: 0, label: 'Lawn'),
//   'park': RoadInfo(cost: 100, label: 'Park'),
//   'road': RoadInfo(cost: 0, label: 'CyberCity'),
//   'street': RoadInfo(cost: 2, label: 'Street Road'),
//   'desert_road': RoadInfo(cost: 1, label: 'Beach'),
// };
// final Map<String, RoadInfo> roadData = {
//   'garden': RoadInfo(cost: 300, label: 'Garden'),
//   'snow_city': RoadInfo(cost: 500, label: 'Snow Road'),
//   'lawn': RoadInfo(cost: 700, label: 'Lawn'),
//   'park': RoadInfo(cost: 700, label: 'Park'),
//   'road': RoadInfo(cost: 0, label: 'CyberCity'),
//   'street': RoadInfo(cost: 700, label: 'Street Road'),
//   'desert_road': RoadInfo(cost: 800, label: 'Beach'),
// };
