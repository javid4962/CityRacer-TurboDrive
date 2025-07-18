// lib/game/modes/level_game.dart
//
// Level mode: each stage has a time or score target
//   • Spawns enemies a bit faster than Classic
//   • Scoring/logic adjusted per level (optional future extension)

import '../utils/game_mode.dart';
import '../racing_game.dart';

class LevelGame extends RacingGame {
  final game = RacingGame(
  mode: GameMode.level,
  levelIndex: 4,
  levelTargetMetres: 1200,
);

  LevelGame({bool autoStartBgm = true})
      : super(
          autoStartBgm: autoStartBgm,
          mode: GameMode.level,
        );
}
