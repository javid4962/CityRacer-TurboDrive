import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import '../racing_game.dart';

void enableSwipeControl(RacingGame game) {
  // Remove any earlier swipe components so we never add duplicates
  game.children.whereType<_SwipeAreaComponent>().forEach(
    (c) => c.removeFromParent(),
  );
  game.add(_SwipeAreaComponent(game));
}

class _SwipeAreaComponent extends PositionComponent with DragCallbacks {
  final RacingGame game;
  double _deltaX = 0.0;
  static const double _swipeThreshold = 40.0;

  _SwipeAreaComponent(this.game) {
    size = game.size;
    position = Vector2.zero();
    priority = 1_000; // always on top for input
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _deltaX = 0.0;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _deltaX += event.localDelta.x;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (_deltaX.abs() >= _swipeThreshold) {
      _handleLaneChange(_deltaX > 0 ? LaneDir.right : LaneDir.left);
    }
    _deltaX = 0.0;
  }

  /* ───────────────────────────────────────────── */

  void _handleLaneChange(LaneDir dir) {
    if (game.laneChangeInProgress) return; // still animating previous swipe

    game.laneChangeInProgress = true;

    if (dir == LaneDir.right) {
      game.playerCar.tiltRight();
      game.playerCar.moveRight();
    } else {
      game.playerCar.tiltLeft();
      game.playerCar.moveLeft();
    }

    _applySwipePenalty(); // ← always applied
    // flag reset happens after move-animation is finished inside CarNode,
    // but we defensively drop it after 300 ms in case that callback never fires
    Future.delayed(
      const Duration(milliseconds: 300),
      () => game.laneChangeInProgress = false,
    );
  }

  void _applySwipePenalty() {
    const double factor = 0.8; // -20 %
    const int penaltyMillis = 300; // visible for 0.3 s

    // 1️⃣ slow the player
    game.currentPlayerSpeed *= factor;

    // 2️⃣ force road/enemy speed to match _right now_
    game.updateScrollSpeed(); // <<< this was missing
    game.updateSpeedometer();

    // 3️⃣ after 300 ms restore whatever the speed has naturally climbed to
    Future.delayed(const Duration(milliseconds: penaltyMillis), () {
      if (game.gameOver || game.isPaused) return;

      // don’t overwrite later boosts / brakes
      game.currentPlayerSpeed = math.max(
        game.currentPlayerSpeed, // could have changed meanwhile
        game.playerMaxSpeed * 0.25, // or pick some baseline
      );
      game.updateScrollSpeed();
      game.updateSpeedometer();
    });
  }
}

/* simple enum for clarity */
enum LaneDir { left, right }
