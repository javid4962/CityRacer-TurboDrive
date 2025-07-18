import 'package:flame/components.dart';
import 'package:flame/events.dart';

class PauseButtonComponent extends SpriteComponent with TapCallbacks {
  final void Function() onPressed;

  PauseButtonComponent({
    required Sprite sprite,
    required Vector2 position,
    required this.onPressed, required Vector2 size,
  }) : super(
          sprite: sprite,
          size: Vector2(50, 50),
          position: position,
          anchor: Anchor.topRight,
          priority: 100,
        );

  @override
  void onTapUp(TapUpEvent event) {
    onPressed();
  }
   void updateSprite(Sprite newSprite) {
    this.sprite = newSprite;
    
  }
}
