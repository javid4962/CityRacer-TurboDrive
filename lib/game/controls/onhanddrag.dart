import 'package:flame/components.dart';
import 'package:flame/events.dart';
import '../racing_game.dart';

/// Full‑screen touch controller: press/hold to accelerate, swipe
/// **left/right** (horizontal) to steer,     double‑tap for nitro.
class OnHandDragArea extends PositionComponent
    with DragCallbacks, TapCallbacks {
  final RacingGame game;

  static const double _doubleTapThreshold = 300; // ms for double‑tap
  static const double _smooth             = 0.10; // steering easing

  DateTime? _lastTapTime;

  OnHandDragArea({required this.game});

  @override
  Future<void> onLoad() async {
    size     = game.size;      // matches game canvas
    position = Vector2.zero(); // origin at top‑left
    priority = 1;              // above gameplay sprites
  }

  /*────────────────  Drag to steer  ────────────────*/
  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    game.isTouching = true; // start accelerating immediately
    _applySteer(event.localPosition.x); // snap to finger
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _applySteer(event.canvasStartPosition.x); // follow finger X directly
  }

  void _applySteer(double fingerX) {
    final minX = size.x * .15;
    final maxX = size.x * .85;
    final clamped = fingerX.clamp(minX, maxX);

    // Smoothly interpolate toward target to avoid jitter
    game.playerCar.targetX +=
        (clamped - game.playerCar.targetX) * _smooth;

    game.updateScrollSpeed();
    game.updateSpeedometer();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    game.playerCar.angle = 0;
    game.isTouching      = false; // stop acceleration
  }

  /*────────────────  Tap / double‑tap  ─────────────*/
  @override
  void onTapDown(TapDownEvent event) {
    final now = DateTime.now();
    final isDoubleTap =
        _lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds <= _doubleTapThreshold;

    _lastTapTime   = now;
    game.isTouching = true; // accelerate on touch

    if (isDoubleTap && !game.isCountingDown) {
      game.activateNitro();
    }
  }

  @override
  void onTapUp(TapUpEvent event) => game.isTouching = false;
  @override
  void onTapCancel(TapCancelEvent event) => game.isTouching = false;
}
