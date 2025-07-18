// lib/game/debug/collision_outline_mixin.dart
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';   // kDebugMode
import 'package:flutter/material.dart';

mixin CollisionOutlineMixin on PositionComponent {
  /// Override this to supply your own rect if you can’t expose one directly.
  Rect get collisionRect => toRect();

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!kDebugMode) return;                // strip in release

    final rect = collisionRect;
    canvas.drawRect(
      rect,
      Paint()
        ..color       = Colors.red
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}
