// lib/game/modes/endless_game.dart
//
// Endless mode: continuous race with dynamically increasing difficulty
//   • Enemies spawn faster over time
//   • Score increases by distance
//   • Fuel depletes normally

import '../utils/game_mode.dart';
import '../racing_game.dart';

class EndlessGame extends RacingGame {
  EndlessGame({bool autoStartBgm = true})
      : super(
          autoStartBgm: autoStartBgm,
          mode: GameMode.endless,
        );
}
