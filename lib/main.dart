// lib/main.dart
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_game_1/game/utils/sfx_manager.dart';
import 'package:simple_game_1/global_tap_detector.dart';
import 'package:simple_game_1/splash_screen.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:simple_game_1/app_lifecycle_observer.dart';
import 'package:simple_game_1/services/local_player_service.dart';

/// Global observer for screens mixing in RouteAware
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await logAllSharedPreferences();
  // await logAllHiveData();
  // ── System UI: portrait only, hide overlays ──
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.light,
    ),
  );

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

  // Preload audio assets
  await FlameAudio.audioCache.loadAll(['sounds/coin_collect.mp3']);

  // Hive initialization
  await Hive.initFlutter();
  await Hive.openBox('scores');

  // Audio / SFX
  await SfxManager.init();

  // App lifecycle observer
  AppLifecycleObserver.init();

  // Ensure default PlayerLeaderboardEntry exists
  // debugPrint('[main.dart] Checking if player record exists...');
  // final existingRecord = await LocalPlayerService.loadMyRecord();
  // if (existingRecord == null) {
  //   debugPrint(
  //     '[main.dart] No record found. Creating default player record...',
  //   );
  //   await LocalPlayerService.saveMyRecord(
  //     LocalPlayerService.createRecord(
  //       username: 'You',
  //       profilePic: 'https://i.pravatar.cc/150?img=69',
  //       coins: 0,
  //       classicScore: 0,
  //       endlessScore: 0,
  //       highestLevel: 0,
  //       ownedCars: ['hero1'],
  //       ownedRoads: [1],
  //     ),
  //   );
  //   debugPrint('[main.dart] Default player record saved.');
  // } else {
  //   debugPrint(
  //     '[main.dart] Existing player record found: ${existingRecord.toJson()}',
  //   );
  // }

  // Run the app
  runApp(const MyApp());

  // runApp(GlobalTapDetector(child: const MyApp()));

  // Keep the screen awake
  if (!kIsWeb) {
    await Future.delayed(Duration.zero);
    try {
      await WakelockPlus.enable();
    } catch (_) {
      // Non-critical, ignore
    }
  }
}

Future<void> logAllSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys();

  print("🔹 SharedPreferences - All Data:");
  for (final key in keys) {
    final value = prefs.get(key);
    print("   $key = $value");
  }
}

Future<void> logAllHiveData() async {
  final box = await Hive.openBox('playerBox');
  print("🔹 Hive - All Data in playerBox:");
  for (final key in box.keys) {
    final value = box.get(key);
    print("   $key = $value");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lane Racer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF00007E),
        fontFamily: 'Roboto',
      ),
      navigatorObservers: [appRouteObserver],
      home: const WebPortraitWrapper(child: SplashScreen()),
    );
  }
}

/// Keeps the web build in portrait aspect
class WebPortraitWrapper extends StatelessWidget {
  const WebPortraitWrapper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final isPortrait = height >= width;
        const targetWidth = 480.0;

        return Center(
          child: Container(
            width: isPortrait ? targetWidth : height * 0.6,
            height: double.infinity,
            color: const Color(0xFF00007E),
            child: child,
          ),
        );
      },
    );
  }
}
