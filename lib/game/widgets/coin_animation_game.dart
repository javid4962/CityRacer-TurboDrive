import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flame/extensions.dart';

class CoinAnimationGame extends FlameGame {
  Future<SpriteAnimation> createCoinAnimation() async {
    final image = await Flame.images.load('coinsprite.png');
    return SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: 19,
        stepTime: 0.04,
        textureSize: Vector2(200, 200),
        // loop: true,
      ),
    );
  }

  @override
  Future<void> onLoad() async {
    final animation = await createCoinAnimation();
    final spriteAnimation = SpriteAnimationComponent(
      animation: animation,
      size: Vector2(50, 50),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2),
    );
    add(spriteAnimation);
  }

  @override
  Color backgroundColor() => const Color(0x00000000);
}
