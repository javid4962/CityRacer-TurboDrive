import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'coin_animation_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RewardedAdOfferPopup extends StatelessWidget {
  final VoidCallback onWatchAd;
  final VoidCallback onDismiss;
  final int remainingSeconds;
  final bool isFirstLaunch; // ← New flag

  const RewardedAdOfferPopup({
    Key? key,
    required this.onWatchAd,
    required this.onDismiss,
    required this.remainingSeconds,
    required this.isFirstLaunch, // ← New parameter
  }) : super(key: key);

  String formatRemainingTime(int seconds) {
    if (seconds <= 0) return "Ready to claim!";
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return "${hours}h ${minutes}m ${secs}s remaining";
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final bool isButtonEnabled =
        isFirstLaunch || remainingSeconds <= 0; // ← Updated logic

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/modeselectBG.png",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              onTap: onDismiss,
              child: Container(color: Colors.black54),
            ),
          ),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: sw * 0.85,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  image: const DecorationImage(
                    image: AssetImage("assets/images/modeselectBG.png"),
                    fit: BoxFit.cover,
                    opacity: 0.3,
                  ),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF651FFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF00E5FF).withOpacity(0.5),
                      blurRadius: 32,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF80D8FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF00E5FF).withOpacity(0.7),
                              blurRadius: 32,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: GameWidget(game: CoinAnimationGame()),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF69F0AE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds);
                        },
                        child: const Text(
                          'Get 100 Coins!',
                          style: TextStyle(
                            fontFamily: 'Akira',
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Watch a short video ad and instantly collect your reward!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Calistoga-Regular',
                          fontSize: 18,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!isButtonEnabled) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            formatRemainingTime(remainingSeconds),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontFamily: 'Akira',
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: isButtonEnabled
                                ? const Color(0xFF00E5FF)
                                : Colors.grey.shade700,
                            foregroundColor: Colors.black,
                            elevation: 8,
                            shadowColor: const Color(0xFF00E5FF),
                          ),
                          onPressed: isButtonEnabled ? onWatchAd : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isButtonEnabled
                                    ? Icons.play_circle_fill
                                    : Icons.hourglass_empty,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isButtonEnabled
                                    ? 'Watch Ad to Claim'
                                    : 'Please Wait...',
                                style: const TextStyle(
                                  fontFamily: 'Akira',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: onDismiss,
                        child: const Text(
                          'No Thanks',
                          style: TextStyle(
                            color: Colors.white54,
                            fontFamily: 'Akira',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
