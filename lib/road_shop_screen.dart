// Cleaned-up RoadShopScreen with safe constraints and decoupled selection tracking

import 'dart:ui';

import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_game_1/game/utils/road_catalog.dart';
import 'package:flame/widgets.dart';
import 'package:flame/components.dart' hide Matrix4;
import 'package:simple_game_1/game/utils/sfx_manager.dart';
import 'package:simple_game_1/mode_select_screen.dart';
import 'package:simple_game_1/garage_screen.dart';
import 'package:simple_game_1/onboardingScreen.dart';
import 'package:simple_game_1/supporting/adservice.dart';

class RoadShopScreen extends StatefulWidget {
  const RoadShopScreen({super.key});

  @override
  State<RoadShopScreen> createState() => _RoadShopScreenState();
}

class _RoadShopScreenState extends State<RoadShopScreen>
    with TickerProviderStateMixin {
  late AnimationController _buttonController;
  late Animation<Offset> _slideAnimation;
  late PageController _pageController;
  int _initialPageIndex = 0;
  bool _loading = true;
  double _pageOffset = 0.0;
  int selectedIndex = 0;
  int _coins = 0;
  Set<String> _owned = {};

  SpriteAnimation? _hudAnim;
  SpriteAnimationTicker? _hudTicker;

  // @override
  // void initState() {
  //   super.initState();
  //   // _pageController = PageController(viewportFraction: 0.6, initialPage: 10000);

  //   _pageOffset = 10000.0;

  //   _pageController.addListener(() {
  //     setState(() => _pageOffset = _pageController.page ?? 0.0);
  //   });

  //   _buttonController = AnimationController(
  //     vsync: this,
  //     duration: const Duration(milliseconds: 600),
  //   );

  //   _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
  //       .animate(
  //         CurvedAnimation(parent: _buttonController, curve: Curves.easeOutBack),
  //       );

  //   Future.delayed(const Duration(milliseconds: 400), () {
  //     _buttonController.forward();
  //   });

  //   _loadHud();
  //   _loadPlayerData();
  // }

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
    _pageController = PageController(viewportFraction: 0.6, initialPage: 0);
    _loadHud();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadPlayerData();

    // Now initialize the page controller with proper index
    final initialPage = 10000 - (10000 % allRoads.length) + _initialPageIndex;
    _pageController = PageController(
      viewportFraction: 0.6,
      initialPage: initialPage,
    );

    _pageOffset = initialPage.toDouble();

    _pageController.addListener(() {
      if (mounted) {
        setState(() => _pageOffset = _pageController.page ?? 0.0);
      }
    });

    if (mounted) setState(() {});

    // Kick off the button animation
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _buttonController.forward();
    });
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadHud() async {
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
    if (mounted) setState(() {});
  }

  Future<void> _loadPlayerData() async {
    final prefs = await SharedPreferences.getInstance();
    _coins = prefs.getInt('coin_count') ?? 0;
    _owned = (prefs.getStringList('owned_roads') ?? ['roads/road.png']).toSet();
    final selectedRoadId =
        prefs.getInt('selected_road_id') ?? allRoads.first.id;

    // Determine the index of the selected road
    final indexInAllRoads = allRoads.indexWhere((r) => r.id == selectedRoadId);
    _initialPageIndex = indexInAllRoads >= 0 ? indexInAllRoads : 0;

    if (mounted) setState(() {});
  }

  bool _isOwned(String spritePath, {int? cost}) {
    if (cost != null && cost == 0) return true;
    return _owned.contains(spritePath);
  }

  Future<void> _handleBuyOrSelect() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedRoad = allRoads[selectedIndex];
    final fileKey = selectedRoad.centerSprite;

    // DEBUG LOGS
    debugPrint('[ROAD SELECT] Selected road: ${selectedRoad.name}');
    debugPrint('[ROAD SELECT] Road ID: ${selectedRoad.id}');
    debugPrint('[ROAD SELECT] Sprite key: $fileKey');
    debugPrint('[ROAD SELECT] Road cost: ${selectedRoad.cost}');
    debugPrint('[ROAD SELECT] _owned list: $_owned');

    final bool owned = _isOwned(fileKey, cost: selectedRoad.cost);
    final bool affordable = _coins >= selectedRoad.cost;

    // More logs
    debugPrint('[ROAD SELECT] Is owned? $owned');
    debugPrint('[ROAD SELECT] Coins available: $_coins');
    debugPrint('[ROAD SELECT] Affordable? $affordable');

    // Case 1: Not Owned
    if (!owned) {
      if (!affordable) {
        debugPrint('[ROAD SELECT] Not enough coins. Showing dialog.');
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
              'You need more coins to buy this road.',
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

      debugPrint('[ROAD SELECT] Showing ad before purchase...');
      // AdManager.showInterstitialAd(
      //   onAdClosed: () async {
          setState(() {
            _coins -= selectedRoad.cost;
            _owned.add(fileKey);
          });

          await prefs.setInt('coin_count', _coins);
          await prefs.setStringList('owned_roads', _owned.toList());
          await prefs.setInt('selected_road_id', selectedRoad.id);

          debugPrint('[ROAD SELECT] PURCHASE COMPLETE: ${selectedRoad.name}');
          debugPrint('[ROAD SELECT] Remaining coins: $_coins');
          debugPrint('[ROAD SELECT] Updated _owned list: $_owned');

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Purchased ${selectedRoad.name.toUpperCase()}!',
                style: const TextStyle(fontFamily: 'Akira'),
              ),
              backgroundColor: Colors.cyan,
              duration: const Duration(seconds: 2),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ModeSelectScreen()),
          );
      //   },
      // );

      return;
    }

    // Case 2: Already owned — just select
    debugPrint('[ROAD SELECT] Already owned. Selecting and navigating.');
    await prefs.setInt('selected_road_id', selectedRoad.id);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ModeSelectScreen()),
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
    final selectedRoad = allRoads[selectedIndex];
    final bool owned = _isOwned(
      selectedRoad.centerSprite,
      cost: selectedRoad.cost,
    );

    final bool affordable = _coins >= selectedRoad.cost;

    final String buttonAsset = owned
        ? 'assets/images/selectcar.png'
        : affordable
        ? 'assets/images/buy.png'
        : 'assets/images/buy.png';

    return Scaffold(
      backgroundColor: const Color(0xFF003366),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/location_screen.png',
              fit: BoxFit.fill,
            ),
          ),

          // Top Buttons
          Positioned(
            top: 40,
            left: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              // children: [
              //   GestureDetector(
              //     onTap: () => Navigator.pop(context),
              //     child: const Icon(
              //       Icons.arrow_back,
              //       color: Colors.white,
              //       size: 32,
              //     ),
              //   ),
              // const SizedBox(width: 12),
              // GestureDetector(
              //   onTap: () => Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (_) => const GarageScreen(
              //         carAssets: [
              //           'assets/images/hero1.png',
              //           'assets/images/hero2.png',
              //           'assets/images/hero3.png',
              //           'assets/images/hero4.png',
              //           'assets/images/hero5.png',
              //           'assets/images/hero6.png',
              //           'assets/images/hero7.png',
              //           'assets/images/hero8.png',
              //         ],
              //       ),
              //     ),
              //   ),
              //   child: const Icon(Icons.store, color: Colors.white, size: 32),
              // ),
              // ],
            ),
          ),

          // Coin HUD
          Positioned(
            top: 20,
            right: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
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

          // Road Carousel
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              height: 800,
              child: PageView.builder(
                controller: _pageController,
                itemBuilder: (context, index) {
                  final actual = index % allRoads.length;
                  final road = allRoads[actual];
                  final diff = index - _pageOffset;
                  final scale = 1 - (diff.abs() * .2).clamp(.1, .2);
                  final rotY = diff.clamp(-1, 1) * .4;

                  if ((_pageController.page?.round() ?? 10000) == index &&
                      selectedIndex != actual) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        SfxManager.playSwipe();
                        setState(() => selectedIndex = actual);
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
                            'assets/images/${road.centerSprite}',
                            key: ValueKey(actual),
                          ),
                          if (!_isOwned(road.centerSprite, cost: road.cost))
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
                                    '${road.cost} COINS',
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

          // Road Name
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Text(
              selectedRoad.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Akira',
                fontSize: 22,
                fontWeight: FontWeight.w900,
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
                    _handleBuyOrSelect();
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final sw = MediaQuery.of(context).size.width;
                      final btnW = sw * 0.55;
                      final btnH = btnW * 0.25;
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
