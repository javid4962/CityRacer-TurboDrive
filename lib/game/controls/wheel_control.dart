import 'package:simple_game_1/game/racing_game.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import 'dart:math';

void enableWheelControl(RacingGame game) {
  final wheel = SpriteComponent(
    sprite: game.wheelSprite,
    size: Vector2(160, 140),
    anchor: Anchor.center,
    position: Vector2(100, game.size.y - 100),
    priority: 20,
  );
  game.wheelComponent = wheel;
  game.add(wheel);

  game.add(
    TapAreaComponent(
      size: wheel.size,
      position: wheel.position,
      handleDragUpdate: (event) {
        final dx = event.localDelta.x;
        game.lastDragX += dx;

        final angle = game.lastDragX * pi / 180.0;
        wheel.angle = angle;
        game.isWheelHeld = true;

        final steeringInput = angle.clamp(-pi / 2, pi / 2);
        game.steeringInput = steeringInput;

        // Lane switch thresholds
        if (!game.laneChangeInProgress) {
          if (steeringInput > 0.6 &&
              game.playerCar.currentLane < game.playerCar.laneCount - 1) {
            game.playerCar.moveRight();
            game.playerCar.tiltRight();
            game.laneChangeInProgress = true;
          } else if (steeringInput < -0.6 &&
              game.playerCar.currentLane > 0) {
            game.playerCar.moveLeft();
            game.playerCar.tiltLeft();
            game.laneChangeInProgress = true;
          }
        }

        // Reset the lock if returned to center
        if (game.laneChangeInProgress && steeringInput.abs() < 0.3) {
          game.laneChangeInProgress = false;
        }
      },
      handleDragEnd: () {
        game.lastDragX = 0;
        game.steeringInput = 0;
        game.isWheelHeld = false;
        game.laneChangeInProgress = false;

        wheel.add(
          RotateEffect.to(
            0,
            EffectController(duration: 0.3, curve: Curves.easeOut),
          ),
        );
      },
    ),
  );
}
