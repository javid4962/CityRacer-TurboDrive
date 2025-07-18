import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_game_1/game/racing_game.dart';
import 'package:simple_game_1/game/utils/sfx_manager.dart';

class SettingsPopup extends StatefulWidget {
  final RacingGame game;
  final VoidCallback onClose;

  const SettingsPopup({super.key, required this.game, required this.onClose});

  @override
  State<SettingsPopup> createState() => _SettingsPopupState();
}

class _SettingsPopupState extends State<SettingsPopup> {
  bool isSoundOn = true;
  bool isMusicOn = true;
  String controlScheme = 'Swipe';
  bool isProcessing = false;

  final List<Map<String, String>> controlOptions = [
    {
      'label': 'Swipe',
      'icon': 'assets/images/drag_control_normal.png',
      'iconFocused': 'assets/images/drag_control_focus.png',
    },
    // {
    //   'label': 'Tilt',
    //   'icon': 'assets/images/tilt_control_normal.png',
    //   'iconFocused': 'assets/images/tilt_control_focus.png',
    // },
    // {
    //   'label': 'Tap',
    //   'icon': 'assets/images/steering_control_normal.png',
    //   'iconFocused': 'assets/images/steering_control_focus.png',
    // },
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        isSoundOn = prefs.getBool('sound_fx') ?? true;
        isMusicOn = prefs.getBool('music') ?? true;
        controlScheme = prefs.getString('control_scheme') ?? 'Swipe';
      });
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  Future<void> _toggleMusic() async {
    if (isProcessing) return;
    setState(() => isProcessing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final newValue = !(prefs.getBool('music') ?? true);
      await prefs.setBool('music', newValue);

      if (newValue) {
        await SfxManager.startBgm();
      } else {
        await SfxManager.stopBgm();
      }

      setState(() => isMusicOn = newValue);
    } catch (e) {
      debugPrint('Error toggling music: $e');
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<void> _toggleSound() async {
    if (isProcessing) return;
    setState(() => isProcessing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final newVal = !isSoundOn;
      await SfxManager.setFxEnabled(newVal);
      setState(() => isSoundOn = newVal);
    } catch (e) {
      debugPrint('Error toggling sound FX: $e');
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<void> _changeControl(String scheme) async {
    if (isProcessing) return;
    setState(() => isProcessing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('control_scheme', scheme);

      setState(() => controlScheme = scheme);
      widget.game.setControlScheme(scheme);
      await widget.game.updateControlScheme();
    } catch (e) {
      debugPrint('Error changing control scheme: $e');
    } finally {
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double popupWidth = screenSize.width * 0.85;
    final double iconSize = screenSize.width * 0.08;
    final double paddingTop = screenSize.height * 0.08;
    final double controlIconSize = screenSize.width * 0.18;

    return AbsorbPointer(
      absorbing: isProcessing,
      child: Center(
        child: Stack(
          children: [
            // 🎯 Background image
            Positioned.fill(
              child: Image.asset(
                'assets/images/modeselectBG.png',
                fit: BoxFit.cover,
              ),
            ),

            // 🎯 Foreground popup content
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Popup background image
                  Image.asset(
                    'assets/images/settingspopup.png',
                    width: popupWidth,
                    fit: BoxFit.fill,
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: paddingTop,
                      left: screenSize.width * 0.12,
                      right: screenSize.width * 0.15,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSettingRow(
                          label: 'Music',
                          value: isMusicOn,
                          toggle: _toggleMusic,
                          iconSize: iconSize,
                          semanticsLabel: 'Toggle music',
                        ),
                        SizedBox(height: screenSize.height * 0.025),
                        _buildSettingRow(
                          label: 'Sound FX',
                          value: isSoundOn,
                          toggle: _toggleSound,
                          iconSize: iconSize,
                          semanticsLabel: 'Toggle sound effects',
                        ),
                        const SizedBox(height: 50),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: controlOptions
                              .map(
                                (control) => _controlIcon(
                                  label: control['label']!,
                                  imgPath: control['icon']!,
                                  focusedPath: control['iconFocused']!,
                                  size: controlIconSize,
                                ),
                              )
                              .toList(),
                        ),
                        SizedBox(height: screenSize.height * 0.04),
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Container(
                            height: 50,
                            width: 160,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF003366),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.cyanAccent,
                                width: 2,
                              ),
                            ),
                            child: const Text(
                              'BACK',
                              style: TextStyle(
                                fontFamily: 'Akira',
                                decoration: TextDecoration.none,
                                fontSize: 20,
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button
                  Positioned(
                    top: screenSize.height * 0.05 - 10,
                    right: screenSize.width * 0.12 - 10,
                    child: Semantics(
                      label: 'Close settings',
                      child: GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Colors.cyanAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required String label,
    required bool value,
    required VoidCallback toggle,
    required double iconSize,
    required String semanticsLabel,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Akira',
            fontSize: 18,
            decoration: TextDecoration.none,
            color: Colors.cyanAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
        Semantics(
          label: semanticsLabel,
          child: GestureDetector(
            onTap: toggle,
            child: Image.asset(
              value
                  ? 'assets/images/speaker.png'
                  : 'assets/images/speaker_off.png',
              width: iconSize,
              height: iconSize,
            ),
          ),
        ),
      ],
    );
  }

  Widget _controlIcon({
    required String label,
    required String imgPath,
    required String focusedPath,
    required double size,
  }) {
    final isSelected = controlScheme == label;
    return Semantics(
      label: 'Select $label control',
      child: GestureDetector(
        onTap: () => _changeControl(label),
        child: Column(
          children: [
            Image.asset(
              isSelected ? focusedPath : imgPath,
              width: size,
              height: size,
            ),
            const SizedBox(height: 6),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Akira',
                decoration: TextDecoration.none,
                fontSize: 12,
                color: isSelected ? Colors.cyanAccent : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
