// lib/app_lifecycle_observer.dart
//
// One-shot observer that pauses and resumes background music when
// the app loses or regains focus.

import 'package:flutter/widgets.dart';
import 'game/utils/sfx_manager.dart';

class AppLifecycleObserver with WidgetsBindingObserver {
  AppLifecycleObserver._() {
    // Register this object as a lifecycle listener
    WidgetsBinding.instance.addObserver(this);
  }

  /// Call exactly once (e.g., in main()) to install the observer.
  static void init() => AppLifecycleObserver._();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused: // Home-button, multitasking
      case AppLifecycleState.inactive: // Incoming call, PiP
        SfxManager.pauseBgm();
        break;
      case AppLifecycleState.resumed:
        SfxManager.resumeBgm();
        break;
      default:
        break;
    }
  }

  /// Optional cleanup (not strictly required for a process-lifetime singleton)
  void dispose() => WidgetsBinding.instance.removeObserver(this);
}
