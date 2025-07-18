// ignore_for_file: deprecated_member_use, unused_element

import 'dart:ui';

import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supporting/adservice.dart';
import 'package:flame/flame.dart';
import 'package:flame/components.dart' hide Matrix4; // Vector2, SpriteAnimation
import 'package:flame/widgets.dart'; // SpriteAnimationWidget
import 'package:simple_game_1/main.dart';

import 'package:simple_game_1/mode_select_screen.dart';
import 'package:simple_game_1/game/utils/car_stats.dart';
import 'package:simple_game_1/game/utils/sfx_manager.dart';
import 'package:simple_game_1/road_shop_screen.dart';
import 'package:simple_game_1/game/utils/car_stats.dart';

class GarageScreen extends StatefulWidget {
  final List<String> carAssets;

  const GarageScreen({super.key, required this.carAssets});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen>
    with TickerProviderStateMixin {
  double _pageOffset = 0.0;
  late AnimationController _buttonController;
  late Animation<Offset> _slideAnimation;
  late CarStats selectedCarStats;
  late CarStats _stats;
  Set<String> _owned = {}; // no late → avoids LateError
  int _coins = 0; // default wallet
  int _initialPageIndex = 0;
  bool _loading = true;

  SpriteAnimation? _hudAnim; // the raw animation
  SpriteAnimationTicker? _hudTicker; // its ticker

  bool _isOwned(String assetPath) => _owned.contains(assetPath.split('/').last);

  int selectedIndex = 0;
  static const int _initialPage = 10000;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _buttonController, curve: Curves.easeOutBack),
        );

    _loadHudCoinAnim();
    _initializeOwnedCars();
    // AdManager.loadInterstitialAd();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadPlayerData();
    final initialPage =
        10000 - (10000 % widget.carAssets.length) + _initialPageIndex;

    _pageController = PageController(
      viewportFraction: 0.6,
      initialPage: initialPage,
    );

    _refreshStats(_initialPageIndex);
    _pageOffset = initialPage.toDouble();

    _pageController!.addListener(() {
      if (mounted) {
        setState(() {
          _pageOffset = _pageController!.page ?? 0.0;
        });
      }
    });

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _refreshStats(int pageIndex) {
    final fname = widget.carAssets[pageIndex]
        .split('/')
        .last
        .replaceAll('.png', '');
    _stats = carPerformanceMap[fname] ?? carPerformanceMap['hero1']!;
  }

  Future<void> _loadHudCoinAnim() async {
    final image = await Flame.images.load('coinsprite.png');
    _hudAnim = SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: 19,
        stepTime: 0.04,
        textureSize: Vector2(200, 200),
        loop: true,
      ),
    );

    _hudTicker = SpriteAnimationTicker(_hudAnim!);
    if (mounted) setState(() {}); // rebuild HUD once ready
  }

  Future<void> _initializeOwnedCars() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('owned_cars')) {
      await prefs.setStringList('owned_cars', ['hero1.png']);
    }
  }

  Future<void> _loadPlayerData() async {
    final p = await SharedPreferences.getInstance();
    _owned = (p.getStringList('owned_cars') ?? ['hero1.png']).toSet();
    _coins = p.getInt('coin_count') ?? 0;

    final selectedCarFile = p.getString('selected_car_path') ?? 'hero1.png';
    final index = widget.carAssets.indexWhere(
      (asset) => asset.endsWith(selectedCarFile),
    );
    _initialPageIndex = index >= 0 ? index : 0;
  }

  /// Handles the BUY / SELECT button tap
  Future<void> _handleBuyOrSelect() async {
    final prefs = await SharedPreferences.getInstance();

    // Identify the in-focus car
    final String fileKey = widget.carAssets[selectedIndex]
        .split('/')
        .last; // e.g. hero2.png
    final CarStats stats = carPerformanceMap[fileKey.replaceAll('.png', '')]!;

    final bool owned = _owned.contains(fileKey);
    final bool affordable = _coins >= stats.cost;

    /* ─────────────────  BUY FLOW  ───────────────── */
    if (!owned) {
      // Not enough coins → show alert and bail out
      if (!affordable) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF001A33),
            title: const Text(
              'Not enough coins',
              style: TextStyle(color: Colors.cyanAccent, fontFamily: 'Akira'),
            ),
            content: const Text(
              'You need more coins to buy this car.',
              style: TextStyle(color: Colors.white70, fontFamily: 'Akira'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.cyanAccent),
                ),
              ),
            ],
          ),
        );
        return;
      }

      // Successful purchase
      // setState(() {
      //   _coins -= stats.cost;
      //   _owned.add(fileKey);
      // });
      // AdManager.showInterstitialAd(
      //   onAdClosed: () async {
          // Successful purchase after ad
          setState(() {
            _coins -= stats.cost;
            _owned.add(fileKey);
          });

          await prefs.setInt('coin_count', _coins);
          await logAllHiveData();
          await prefs.setStringList('owned_cars', _owned.toList());

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Purchased ${fileKey.replaceAll('.png', '').toUpperCase()}!',
                style: const TextStyle(fontFamily: 'Akira'),
              ),
              backgroundColor: Colors.cyan,
              duration: const Duration(seconds: 2),
            ),
          );
      //   },
      // );
      return; // stay in garage after buying
    }

    /* ─────────────────  SELECT FLOW  ───────────────── */
    await prefs.setString('selected_car_path', fileKey);
    await SfxManager.setActiveCar(stats);

    if (!mounted) return;

    // Instead of ModeSelectScreen, navigate to RoadShopScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RoadShopScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final carCount = widget.carAssets.length;

    /* ── helpers for the in-focus car ─────────────────────────── */
    final fileKey = widget.carAssets[selectedIndex].split('/').last;
    final stats = carPerformanceMap[fileKey.replaceAll('.png', '')]!;
    final bool owned = _isOwned(widget.carAssets[selectedIndex]);
    final bool affordable = _coins >= stats.cost;

    final String buttonAsset = owned
        ? 'assets/images/selectcar.png'
        : affordable
        ? 'assets/images/buy.png'
        : 'assets/images/buy.png';

    return Scaffold(
      backgroundColor: const Color(0xFF00007E),
      body: Stack(
        children: [
          // Background and Navigation Buttons
          Positioned.fill(
            child: Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/garage_screen.jpg',
                    fit: BoxFit.fill,
                  ),
                ),
                // Back & Shop Buttons
                Positioned(
                  top: 40,
                  left: 20,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Back Button
                      // GestureDetector(
                      //   onTap: () => Navigator.pop(context),
                      //   child: ClipRRect(
                      //     borderRadius: BorderRadius.circular(12),
                      //     child: BackdropFilter(
                      //       filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      //       child: Container(
                      //         width: 48,
                      //         height: 48,
                      //         alignment: Alignment.center,
                      //         // color: Colors.white.withOpacity(0.15),
                      //         child: const Icon(
                      //           Icons.arrow_back,
                      //           color: Colors.white,
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),

                      // const SizedBox(width: 12),

                      // Shop Button
                      // // Shop Button
                      // Material(
                      //   color: Colors.transparent,
                      //   borderRadius: BorderRadius.circular(12),
                      //   child: InkWell(
                      //     borderRadius: BorderRadius.circular(12),
                      //     onTap: () {
                      //       print(
                      //         '[GarageScreen] Shop icon tapped → Navigating to RoadShopScreen',
                      //       );

                      //       // Defensive: ensure only one navigation happens
                      //       if (Navigator.canPop(context)) {
                      //         // Optionally pop overlays/dialogs
                      //         Navigator.pop(context);
                      //       }

                      //       if (context.mounted) {
                      //         Navigator.of(context, rootNavigator: true).push(
                      //           MaterialPageRoute(
                      //             builder: (_) => const RoadShopScreen(),
                      //           ),
                      //         );
                      //       } else {
                      //         print(
                      //           '[GarageScreen] Context is not mounted. Navigation aborted.',
                      //         );
                      //       }
                      //     },
                      //     // child: Ink(
                      //     //   decoration: BoxDecoration(
                      //     //     borderRadius: BorderRadius.circular(12),
                      //     //     color: Colors.white.withOpacity(0.15),
                      //     //     backgroundBlendMode: BlendMode.overlay,
                      //     //   ),
                      //     //   width: 48,
                      //     //   height: 48,
                      //     //   child: const Center(
                      //     //     child: Icon(Icons.store, color: Colors.white),
                      //     //   ),
                      //     // ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Coin HUD
          Positioned(
            top: 20,
            right: 20,
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: (_hudAnim == null || _hudTicker == null)
                      ? const SizedBox.shrink()
                      : SpriteAnimationWidget(
                          animation: _hudAnim!,
                          animationTicker: _hudTicker!,
                          playing: true,
                        ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$_coins',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Akira',
                    fontSize: 18,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),

          // Car Carousel
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              height: 800,
              child: PageView.builder(
                controller: _pageController,
                itemBuilder: (context, index) {
                  final actual = index % widget.carAssets.length;
                  final diff = index - _pageOffset;
                  final scale = 1 - (diff.abs() * .2).clamp(.1, .2);
                  final rotY = diff.clamp(-1, 1) * .4;

                  if ((_pageController!.page?.round() ?? _initialPage) ==
                          index &&
                      selectedIndex != actual) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        // Play swipe sound
                        SfxManager.playSwipe();
                        setState(() {
                          selectedIndex = actual;
                          _refreshStats(actual);
                        });
                      }
                    });
                  }

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(2, 2, .0005)
                      ..rotateY(rotY)
                      ..translate(0.0, diff.abs() * 50),
                    child: Transform.scale(
                      scale: scale,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            widget.carAssets[actual],
                            key: ValueKey(actual),
                          ),
                          if (!_isOwned(widget.carAssets[actual]))
                            Positioned.fill(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withOpacity(
                                        0.3,
                                      ), // semi-transparent background
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 0,
                                      ),
                                    ),
                                    child: Center(
                                      child: Image.asset(
                                        'assets/images/lock.png',
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),

                                  Text(
                                    '${carPerformanceMap[widget.carAssets[actual].split('/').last.replaceAll('.png', '')]!.cost}  COINS',
                                    style: const TextStyle(
                                      color: Colors.cyanAccent,
                                      fontFamily: 'Akira',
                                      fontSize: 18,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Max Speed Label
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Text(
              'MAX SPEED\n${_stats.maxSpeed.toInt()} KM',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Akira',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.15,
                color: Colors.cyanAccent,
                decoration: TextDecoration.none,
              ),
            ),
          ),

          // Buy/Select Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SlideTransition(
                position: _slideAnimation,
                child: GestureDetector(
                  onTap: () {
                    // AdManager.showInterstitialAd(
                    //   onAdClosed: () {
                    _handleBuyOrSelect();
                    //   },
                    // );
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final sw = MediaQuery.of(context).size.width;
                      final btnW = sw * 0.55;
                      final btnH = btnW * 0.3;
                      return Image.asset(
                        buttonAsset,
                        width: btnW,
                        height: btnH,
                        fit: BoxFit.contain,
                      );
                    },
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

// class _AnimatedCarImage extends StatelessWidget {
//   final String imagePath;
//   final bool isSelected;

//   const _AnimatedCarImage({required this.imagePath, required this.isSelected});

//   @override
//   Widget build(BuildContext context) {
//     final imageWidget = Image.asset(imagePath);

//     return AnimatedRotation(
//       duration: const Duration(milliseconds: 500),
//       turns: isSelected ? 0.02 : 0.0,
//       curve: Curves.easeInOut,
//       child: AnimatedScale(
//         duration: const Duration(milliseconds: 500),
//         scale: isSelected ? 0.9 : 0.6,
//         curve: Curves.easeInOut,
//         child: isSelected
//             ? Hero(tag: 'selected-car', child: imageWidget)
//             : imageWidget,
//       ),
//     );
//   }
// }
