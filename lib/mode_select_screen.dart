import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_game_1/game/widgets/game_transition_screen.dart';
import 'package:simple_game_1/game/utils/game_mode.dart';
import 'package:simple_game_1/game/utils/sfx_manager.dart';
import 'package:simple_game_1/level_select_screen.dart';

class ModeSelectScreen extends StatefulWidget {
  const ModeSelectScreen({super.key});

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen> {
  @override
  void initState() {
    super.initState();
    SfxManager.startBgm();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00007E),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/modeselectBG.png',
              fit: BoxFit.cover,
            ),
          ),

          // Content
          Column(
            children: [
              const SizedBox(height: 64),

              // Title
              Center(
                child: Image.asset(
                  'assets/images/select.png',
                  width: MediaQuery.of(context).size.width * .80,
                ),
              ),

              const Spacer(),

              // Classic Mode
              _ModeCard(
                assetPath: 'assets/images/classic.png',
                mode: GameMode.classic,
                onTap: () => _open(GameMode.classic),
                infoText:
                    "🏁 Classic Mode\n\nEndless traffic.\n💰 Collect 150 coins to win.\n💥 Avoid enemy cars.",
              ),
              const SizedBox(height: 20),

              // Level Mode
              _ModeCard(
                assetPath: 'assets/images/levelmode.png',
                mode: GameMode.level,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LevelSelectScreen()),
                ),
                infoText:
                    "⭐ Level Mode\n\nComplete target distance.\n🎯 Collect required coins.\n⛽ Don’t run out of fuel!",
              ),
              const SizedBox(height: 18),

              // Endless Mode
              _ModeCard(
                assetPath: 'assets/images/endless.png',
                mode: GameMode.endless,
                onTap: () => _open(GameMode.endless),
                infoText:
                    "♾️ Endless Mode\n\nDrive as far as you can.\n🎯 Rack up distance.\n💥 Don’t crash.",
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  /// Opens the GameTransitionScreen for Classic or Endless mode.
  Future<void> _open(GameMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final car = prefs.getString('selected_car_path');

    if (!mounted) return;

    if (car == null) {
      // Provide user feedback if no car is selected.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a car in the garage first."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameTransitionScreen(
          selectedCarImage: 'assets/images/$car',
          selectedMode: mode,
        ),
      ),
    );
  }
}

/*────────────────────────────  Mode Card  ─────────────────────────────*/
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.assetPath,
    required this.mode,
    required this.onTap,
    required this.infoText,
  });

  final String assetPath;
  final GameMode mode;
  final VoidCallback onTap;
  final String infoText;

  String get _title => switch (mode) {
    GameMode.classic => 'Classic Mode',
    GameMode.level => 'Level Mode',
    GameMode.endless => 'Endless Mode',
  };

  void _showDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF001A33),
        title: Text(
          _title,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(infoText, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'GOT IT',
              style: TextStyle(color: Colors.cyanAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: .82,
      child: Stack(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Image.asset(assetPath, fit: BoxFit.contain),
          ),

          // ℹ️ Info icon
          Positioned(
            top: 50,
            right: 10,
            child: GestureDetector(
              onTap: () => _showDialog(context),
              child: const Icon(Icons.info_outline, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
