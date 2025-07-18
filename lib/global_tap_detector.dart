import 'package:flutter/material.dart';
import 'package:simple_game_1/game/utils/sfx_manager.dart';

class GlobalTapDetector extends StatelessWidget {
  final Widget child;

  const GlobalTapDetector({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        SfxManager.playTouch();
      },
      child: child,
    );
  }
}
