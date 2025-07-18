import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_game_1/game/utils/level_config.dart';
import 'package:simple_game_1/game/widgets/game_transition_screen.dart';
import 'package:simple_game_1/game/utils/game_mode.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  static const int levelsPerPage = 15;
  static const int levelsPerRow = 3;
  final int totalLevels = 100;

  late Future<List<bool>> _unlockedLevelsFuture;
  final PageController _pageController = PageController(viewportFraction: 0.93);
  int? _pressedLevel;

  @override
  void initState() {
    super.initState();
    _unlockedLevelsFuture = _loadUnlockedLevels();
  }

  Future<List<bool>> _loadUnlockedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    return List.generate(totalLevels, (i) {
      return prefs.getBool('level_${i}_complete') ?? (i == 0);
    });
  }

  Future<void> _startLevel(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final carPath = prefs.getString('selected_car_path') ?? 'player_car.png';

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameTransitionScreen(
          selectedCarImage: 'assets/images/$carPath',
          selectedMode: GameMode.level,
          levelIndex: index,
          levelConfig: levelConfigs[index],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int pageCount = (totalLevels / levelsPerPage).ceil();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/modeselectBG.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Center(
                  child: Text(
                    "Select Level",
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontFamily: 'akira',
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: FutureBuilder<List<bool>>(
                    future: _unlockedLevelsFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final unlocked = snapshot.data!;
                      return PageView.builder(
                        controller: _pageController,
                        physics: const _FasterPagePhysics(),
                        allowImplicitScrolling: true,
                        itemCount: pageCount,
                        itemBuilder: (context, pageIndex) {
                          final int start = pageIndex * levelsPerPage;
                          final int end = (start + levelsPerPage).clamp(
                            0,
                            totalLevels,
                          );

                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: GridView.builder(
                              padding: const EdgeInsets.only(top: 20),
                              itemCount: end - start,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: levelsPerRow,
                                    mainAxisSpacing: 20,
                                    crossAxisSpacing: 20,
                                    childAspectRatio: 1,
                                  ),
                              itemBuilder: (context, index) {
                                final int levelNumber = start + index;
                                final bool isUnlocked = unlocked[levelNumber];
                                final bool isTapped =
                                    _pressedLevel == levelNumber && isUnlocked;
                                final String framePath = isTapped
                                    ? 'assets/images/empty_normal.png'
                                    : 'assets/images/empty_focus.png';

                                return GestureDetector(
                                  onTapDown: (_) {
                                    if (isUnlocked) {
                                      setState(
                                        () => _pressedLevel = levelNumber,
                                      );
                                    }
                                  },
                                  onTapUp: (_) {
                                    if (isUnlocked) {
                                      setState(() => _pressedLevel = null);
                                      _startLevel(levelNumber);
                                    }
                                  },
                                  onTapCancel: () =>
                                      setState(() => _pressedLevel = null),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Positioned.fill(
                                        child: Image.asset(
                                          framePath,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      Text(
                                        '${levelNumber + 1}',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: isUnlocked
                                              ? Colors.white
                                              : Colors.white,
                                        ),
                                      ),
                                      if (!isUnlocked)
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: Image.asset(
                                            'assets/images/lock_icon.png',
                                            width: 40,
                                            height: 40,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FasterPagePhysics extends PageScrollPhysics {
  const _FasterPagePhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  _FasterPagePhysics applyTo(ScrollPhysics? ancestor) =>
      _FasterPagePhysics(parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    return super.createBallisticSimulation(position, velocity * 1.8);
  }
}
