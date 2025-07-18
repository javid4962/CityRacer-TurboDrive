// lib/game/nodes/coin_component.dart
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:simple_game_1/game/debug/collision_outline_mixin.dart';

class CoinComponent extends SpriteAnimationComponent
    with CollisionOutlineMixin {
  CoinComponent({
    required super.animation,
    required super.size,
    required super.position,
    required super.anchor,
    required super.priority,
  });

  @override
  Rect get collisionRect => Rect.fromLTWH(
    // anchor = bottom-center, so we shift up by height
    position.x - size.x / 2,
    position.y - size.y,
    size.x,
    size.y,
  );
}
