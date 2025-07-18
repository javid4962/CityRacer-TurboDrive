// lib/game/controls/tap_lane_control_component.dart
//
// Touch left  → hop one lane left
// Touch right → hop one lane right
// Smooth tween to lane centre; ignores continuous physics.
// Flame 1.14+  (TapCallbacks).

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_game_1/game/racing_game.dart';

/* ─ Tunables ─────────────────────────────────────────────────────────────── */
const int    _kLaneCount      = 3;          // 3-lane highway
const double _kEdgePaddingPct = 0.25;       // centres start at 20 % and end at 80 %
const double _kSnapDuration   = 0.18;       // seconds for lane hop
const double _kLeanAngle      = 0.05;       // radians bank during hop

class TapLaneControlComponent extends PositionComponent
    with HasGameRef<RacingGame>, TapCallbacks {

  late final List<double> _laneCenters;      // cached x-coords
  int    _currentLane = 1;                  // start middle (0-based)
  double _animT       = 1.0;                // 0 → 1 lerp progress
  double _startX      = 0.0;
  double _targetX     = 0.0;

  TapLaneControlComponent() : super(priority: 100);

  @override
  Future<void> onLoad() async {
    size     = gameRef.size;
    position = Vector2.zero();

    final w      = gameRef.size.x;
    final span   = 1.0 - (_kEdgePaddingPct * 2);
    final stride = span / (_kLaneCount - 1);
    _laneCenters = List.generate(
      _kLaneCount,
      (i) => w * (_kEdgePaddingPct + stride * i),
    );

    // init player position
    _targetX             = _laneCenters[_currentLane];
    gameRef.tiltPosition = _targetX;
    gameRef.playerCar.x  = _targetX;
  }

  /* ─ Input Routing ─ */

  @override
  void onTapDown(TapDownEvent e) {
    final leftSide = e.localPosition.x < size.x * 0.5;

    if (leftSide && _currentLane > 0) {
      _snapTo(_currentLane - 1);
    } else if (!leftSide && _currentLane < _kLaneCount - 1) {
      _snapTo(_currentLane + 1);
    }
  }

  void _snapTo(int laneIndex) {
    _startX       = gameRef.tiltPosition;
    _targetX      = _laneCenters[laneIndex];
    _currentLane  = laneIndex;
    _animT        = 0.0;                    // reset lerp
  }

  /* ─ Per-frame Interpolation ─ */

  @override
  void update(double dt) {
    final g = gameRef;
    if (g.gameOver || g.isPaused) return;

    if (_animT < 1.0) {
      _animT += dt / _kSnapDuration;
      if (_animT > 1.0) _animT = 1.0;
      final t = Curves.easeOut.transform(_animT);

      g.tiltPosition        = _lerp(_startX, _targetX, t);
      g.playerCar.targetX   = g.tiltPosition;

      // banking effect
      final dir             = (_targetX - _startX).sign;   // −1 left, +1 right
      final targetLean      = -dir * _kLeanAngle;
      g.currentLeanAngle    = _lerp(g.currentLeanAngle, targetLean, 0.35);
      g.playerCar.angle     = g.currentLeanAngle;

      if (_animT == 1.0) {                    // snap lean back to 0
        g.currentLeanAngle = 0;
        g.playerCar.angle  = 0;
      }
    }
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}
