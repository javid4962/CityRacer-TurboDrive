import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/widgets.dart';
import 'package:simple_game_1/game/utils/sfx_manager.dart';


class CarNode extends PositionComponent
    with DoubleTapCallbacks {
  final int laneCount = 3;
  int currentLane;
  bool isEnemy;
  static double enemyMoveSpeed = 350;
  double moveSpeed = 1000;
  late double targetX;
  final Vector2 screenSize;
  final double tiltAngle = 0.075;
  bool isTilting = false;
  bool passedPlayer = false;
  final Sprite sprite;
  final Sprite lightSprite;
  final Sprite shadowSprite;
  final String? carName;

  late SpriteComponent carBody;
  late SpriteComponent lightOverlay;
  late SpriteComponent shadowOverlay;

  late Sprite _tailNormal, _tailNitro;
  SpriteComponent? _tailOverlay;

  bool _headLightsOn = true;
  bool _backLightsOn = true;
  bool _nitroTailActive = false; // <- NEW

  CarNode({
    required this.sprite,
    required this.currentLane,
    required this.isEnemy,
    required this.screenSize,
    required this.lightSprite,
    required this.shadowSprite,
    this.carName,
  });

  @override
  Future<void> onLoad() async {
    final carSize = Vector2(screenSize.x * 0.175, screenSize.x * 0.16 * 2.4);
    size = carSize;
    anchor = Anchor.center;
    targetX = _laneToX(currentLane, screenSize);
    position = Vector2(targetX, isEnemy ? -150 : screenSize.y * 0.8);

    carBody = SpriteComponent(
      sprite: sprite,
      size: carSize,
      anchor: Anchor.center,
      // position: Vector2.zero(),
      position: Vector2(carSize.x * 0.5, 0),
    );

    // Load dynamic lights only for player cars
    if (!isEnemy && carName != null) {
      final frontLight = await Sprite.load('cars/${carName}_lighton.png');
      _tailNormal = await Sprite.load('cars/${carName}_taillight.png');
      _tailNitro = await Sprite.load('cars/${carName}_nitro.png');

      // 🔆 Front Light Overlay (Headlights)
      lightOverlay = SpriteComponent(
        sprite: frontLight,
        size: size,
        anchor: Anchor.center,
        position: Vector2(
          size.x * 0.5,
          size.y * -0.22 ,
        ), // perfectly centered
        priority: 1,
      );

      // 🔴 Tail Light Overlay (Backlights)
      shadowOverlay = SpriteComponent(
        sprite: _tailNormal,
        size: size,
        anchor: Anchor.center,
        position: Vector2(size.x * 0.5, size.y * 0.227 ), // same center
        priority: 1, // ensure it renders below if needed
      );

      _tailOverlay = SpriteComponent(
        sprite: _tailNormal,
        size: size,
        anchor: Anchor.center,
        position: Vector2(size.x * 0.5, size.y * 0.227 ),
        priority: 1,
      );

      addAll([shadowOverlay, lightOverlay, carBody, _tailOverlay!]);
    } else {
      // Static light for enemy cars
      lightOverlay = SpriteComponent(
        sprite: lightSprite,
        size: Vector2(carSize.x * 1, carSize.y * 0.5),
        anchor: Anchor.topCenter,
        position: Vector2(carSize.x * 0.5, carSize.y * -0.85 ),
        priority: -1,
      );

      shadowOverlay = SpriteComponent(
        sprite: shadowSprite,
        size: carSize,
        anchor: Anchor.bottomRight,
        position: Vector2(carSize.x * 1.5, carSize.y * 0.5 ),
        priority: -1,
      );
    }

    if (isEnemy) {
      carBody.angle = 3.1416;
      lightOverlay.angle = 3.1416;
      lightOverlay.position = Vector2(carSize.x * 0.5, carSize.y * 0.85 );
    }

    addAll([shadowOverlay, lightOverlay, carBody]);
  }

  void toggleNitroTail(bool on) {
    if (_tailOverlay == null) return;

    _nitroTailActive = on; // keep track
    _tailOverlay!.sprite = on ? _tailNitro : _tailNormal;

    // always show the flame while nitro is on
    _tailOverlay!.opacity = on ? 1.0 : (_backLightsOn ? 1.0 : 0.0);
  }

  // CarNode.dart
  void toggleLights() {
    _headLightsOn = !_headLightsOn;
    _backLightsOn = !_backLightsOn;

    // front lights
    lightOverlay.opacity = _headLightsOn ? 1.0 : 0.0;

    // rear lights: keep them visible if nitro is burning
    _tailOverlay?.opacity = (_backLightsOn || _nitroTailActive) ? 1.0 : 0.0;
  }

  /// Player-car tap ⇒ flip lights + honk.
  @override
  void onDoubleTapDown(DoubleTapDownEvent event) {
    if (isEnemy) return; // ignore enemy cars

    // toggleLights(); // switch lights on/off
    // SfxManager.lightsToggle(); // play click sound
    SfxManager.horn(); // play honk
  }

  bool get headLightsOn => _headLightsOn;
  bool get backLightsOn => _backLightsOn;

  Future<void> moveToX(double targetX) async {
    final effect = MoveEffect.to(
      Vector2(targetX, position.y),
      EffectController(duration: 0.2, curve: Curves.easeOut),
    );
    await add(effect);
    await Future.delayed(const Duration(milliseconds: 200)); // match duration
  }

  static double _laneToX(num lane, Vector2 screenSize) {
    final roadLeft = screenSize.x * 0.1;
    final roadWidth = screenSize.x * 0.8;
    final laneWidth = roadWidth / 3;
    return roadLeft + laneWidth * lane + laneWidth / 2;
  }

  void setAnalogLanePosition(double analogLane) {
    analogLane = analogLane.clamp(0.0, laneCount - 1.0);
    targetX = _laneToX(analogLane, screenSize);
  }

  void tiltLeft() {
    if (!isTilting) {
      isTilting = true;
      add(
        RotateEffect.to(
          -tiltAngle,
          EffectController(
            duration: 0.2,
            reverseDuration: 0.2,
            curve: Curves.easeInOutCirc,
            alternate: true,
          ),
          onComplete: () => isTilting = false,
        ),
      );
    }
  }

  void tiltRight() {
    if (!isTilting) {
      isTilting = true;
      add(
        RotateEffect.to(
          tiltAngle,
          EffectController(
            duration: 0.2,
            reverseDuration: 0.2,
            curve: Curves.easeInOutCirc,
            alternate: true,
          ),
          onComplete: () => isTilting = false,
        ),
      );
    }
  }

  void switchToLane(int newLane) {
    if (newLane < 0 || newLane >= laneCount || newLane == currentLane) return;

    currentLane = newLane;
    final destination = _laneToX(newLane, screenSize);

    children.whereType<MoveEffect>().forEach((e) => e.removeFromParent());

    add(
      MoveEffect.to(
        Vector2(destination, position.y),
        EffectController(duration: 0.5, curve: Curves.easeOutCubic),
      ),
    );

    if (destination > position.x) {
      tiltRight();
    } else {
      tiltLeft();
    }

    targetX = destination;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isEnemy) {
      position.y += CarNode.enemyMoveSpeed * dt;
    } else {
      final dx = targetX - position.x;
      final step = moveSpeed * dt;
      if (dx.abs() < step) {
        position.x = targetX;
      } else {
        position.x += step * dx.sign;
      }
    }
  }

  @override
  Rect toRect() {
    if (isEnemy) {
      // Enemy car collision box (tight and centered)
      final offsetX = screenSize.x * 0.01;
      final offsetY = -screenSize.y * 0.03;
      final shrinkX = screenSize.x * 0.02;
      final shrinkY = screenSize.y * 0.04;

      return Rect.fromLTWH(
        position.x - size.x / 2 + offsetX,
        position.y - size.y / 2 + offsetY,
        size.x - shrinkX,
        size.y - shrinkY,
      );
    } else {
      // Player car collision box (adjusted lower and wider)
      final offsetX = screenSize.x * 0.005;
      final offsetY = -screenSize.y * 0.07;
      final shrinkX = screenSize.x * 0.01;
      final shrinkY = screenSize.y * 0.05;

      return Rect.fromLTWH(
        position.x - size.x / 2 + offsetX,
        position.y - size.y / 2 + offsetY,
        size.x - shrinkX,
        size.y - shrinkY,
      );
    }
  }

  void moveLeft() => switchToLane(currentLane - 1);
  void moveRight() => switchToLane(currentLane + 1);
}
