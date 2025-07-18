// lib/game/controls/tilt_control_component.dart
import 'dart:async';
import 'package:flame/components.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:simple_game_1/game/racing_game.dart';

/* ─── Tunables (expose via Settings if desired) ────────────────────────────── */
const double _kMaxTiltG = 50.5; // sensor clamp
const double _kDeadZoneG = 0.15; // ignore micro-shakes
const double _kFilterAlpha = 0.85; // EMA smoothing
const double _kSteerGain = 550.0; // px/s² per g
const double _kDamping = 0.95; // velocity damping each frame
const double _kEdgeSpringFactor = 0.50; // soft clamp pullback

/* ─── Component ───────────────────────────────────────────────────────────── */
class TiltControlComponent extends Component with HasGameRef<RacingGame> {
  double _rawTilt = 0.0;
  double _filteredTilt = 0.0;
  StreamSubscription<AccelerometerEvent>? _sub;

  @override
  Future<void> onLoad() async {
    final g = gameRef;
    g
      ..tiltVelocity = 0
      ..tiltPosition = g.size.x * 0.5;

    _sub = accelerometerEvents.listen((e) {
      if (g.gameOver || g.isPaused) return;
      _rawTilt = e.x.clamp(-_kMaxTiltG, _kMaxTiltG);
    });
  }

  @override
  void update(double dt) {
    final g = gameRef;
    if (g.gameOver || g.isPaused) return;

    /* 1️⃣  Low-pass filter */
    _filteredTilt =
        _kFilterAlpha * _filteredTilt + (1 - _kFilterAlpha) * _rawTilt;

    /* 2️⃣  Dead-zone */
    final tiltG = (_filteredTilt.abs() < _kDeadZoneG) ? 0.0 : _filteredTilt;

    /* 3️⃣  Integrate physics */
    g.tiltVelocity += (-tiltG * _kSteerGain) * dt;
    g.tiltVelocity *= _kDamping;
    g.tiltPosition += g.tiltVelocity * dt;

    /* 4️⃣  Soft edge clamp */
    final minX = g.size.x * 0.2, maxX = g.size.x * 0.8;
    if (g.tiltPosition < minX) {
      final over = minX - g.tiltPosition;
      g.tiltVelocity += over * _kEdgeSpringFactor;
    } else if (g.tiltPosition > maxX) {
      final over = g.tiltPosition - maxX;
      g.tiltVelocity -= over * _kEdgeSpringFactor;
    }
    g.tiltPosition = g.tiltPosition.clamp(minX, maxX);

    /* 5️⃣  Apply to car sprite */
    g.playerCar.targetX = g.tiltPosition;
    final lean = (-tiltG * 0.012).clamp(-0.12, 0.12);
    g.currentLeanAngle += (lean - g.currentLeanAngle) * 0.08;
    g.playerCar.angle = g.currentLeanAngle;
  }

  @override
  void onRemove() {
    _sub?.cancel(); // 🔑 sensor cleanup
    super.onRemove();
  }
}
