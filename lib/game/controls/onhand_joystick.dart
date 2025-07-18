// // lib/game/controls/onhand_joystick.dart
// import 'dart:ui';
// import 'package:flame/components.dart';
// import 'package:flame/events.dart';
// import '../racing_game.dart';

// /// Thumb-stick for the “On-Hand” control scheme.
// /// • bottom-left position
// /// • X deflection → lane steering
// /// • stick held   → accelerates
// /// • double-tap knob → Nitro
// class OnHandJoystick extends JoystickComponent with TapCallbacks {
//   // ───────── constructor ─────────
//   OnHandJoystick({
//     required Sprite knobSprite,
//     required Sprite baseSprite,
//   }) : super(
//           size: 140, // overall diameter
//           position: Vector2.zero(), // parent decides final position
//           knob: SpriteComponent(sprite: knobSprite, size: Vector2.all(64)),
//           background: SpriteComponent(sprite: baseSprite, size: Vector2.all(140)),
//         );

//   // ───────── double-tap → nitro ─────────
//   static const _doubleTapMs = 300;
//   DateTime _lastTap = DateTime(0);

//   @override
//   bool onTapDown(TapDownEvent event) {
//     final g = game as RacingGame;

//     // start accelerating on any tap-down
//     g.isTouching = true;

//     final now = DateTime.now();
//     final isDoubleTap = now.difference(_lastTap).inMilliseconds <= _doubleTapMs;

//     if (isDoubleTap && !g.isCountingDown) {
//       g.activateNitro();
//     }
//     _lastTap = now;
//     return true; // we handled the tap
//   }

//   @override
//   void onTapUp(TapUpEvent event) => (game as RacingGame).isTouching = false;

//   @override
//   void onTapCancel(TapCancelEvent event) =>
//       (game as RacingGame).isTouching = false;

//   /// When the user releases the stick we must also stop accelerating.
//   @override
//   bool onDragEnd(DragEndEvent event) {
//     final g = game as RacingGame;
//     g.isTouching = false;
//     // Let JoystickComponent reset its internals
//     return super.onDragEnd(event);
//   }

//   // ───────── steering & acceleration each frame ─────────
//   @override
//   void update(double dt) {
//     super.update(dt);

//     final g = game as RacingGame;

//     // ① Steering (relativeDelta.x ∈ −1 … 1)
//     final dx = relativeDelta.x.clamp(-1.0, 1.0);
//     final roadLeft  = g.size.x * 0.15;
//     final roadRight = g.size.x * 0.85;
//     final targetX   = ((dx + 1) * 0.5) * (roadRight - roadLeft) + roadLeft;
//     g.playerCar.targetX = targetX;

//     // ② Acceleration flag
//     g.isTouching = delta != Vector2.zero();

//     // ③ Keep physics in sync
//     g.updateScrollSpeed();
//     g.updateSpeedometer();
//   }
// }
