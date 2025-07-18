// lib/game/modes/classic_game.dart
//
// “Plain” endless-distance race with a fixed enemy-spawn cadence
// and the standard score-by-distance model.

import '../utils/game_mode.dart';
import '../racing_game.dart';

/// Thin wrapper that pre-sets the mode flag.
/// All the actual logic lives inside `RacingGame` and branches on [mode].
class ClassicGame extends RacingGame {
  ClassicGame({bool autoStartBgm = true})
    : super(
        autoStartBgm: autoStartBgm,
        mode: GameMode.classic, // ← the important bit
      );
}
