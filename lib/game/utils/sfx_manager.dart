// lib/game/sfx_manager.dart

import 'dart:async';
import 'package:flame_audio/flame_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_game_1/game/utils/car_stats.dart';

class SfxManager {
  /* ──────────────────── prefs keys ───────────────────── */
  static const _kFxPref = 'sound_fx';
  static const _kMusicPref = 'music';

  /* ──────────────────── bgm rotation ─────────────────── */
  static final List<String> _bgmTracks = [
    'audio/bgm1.mp3',
    'audio/bgm2.mp3',
    'audio/bgm3.mp3',
  ];

  static final AudioPlayer _musicPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  static int _trackIndex = 0;
  static bool _isPlaying = false;
  static late StreamSubscription _bgmSub;

  /* ──────────────────── nitro wind ───────────────────── */
  static final AudioPlayer _nitroLoop = AudioPlayer();
  static bool _nitroPausedBgm = false;

  /* ──────────────────── SFX pools ────────────────────── */
  static late AudioPool _coinPool;
  static late AudioPool _fuelPool;
  static late AudioPool _brakePool;
  static late AudioPool _lightsPool;
  static late AudioPool _crashPool;
  static late AudioPool _hitPool;
  static late AudioPool _hornPool;
  static late AudioPool _nitroStartPool;
  static late AudioPool _touchPool;

  /* ──────────────────── misc state ───────────────────── */
  static bool _fxEnabled = true;
  static CarStats? _active;

  /* ─────────────────── public API ────────────────────── */

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _fxEnabled = prefs.getBool(_kFxPref) ?? true;
    final musicPref = prefs.getBool(_kMusicPref) ?? true;

    // Warm small assets
    await FlameAudio.audioCache.loadAll([
      'sounds/brake.mp3',
      'sounds/lights_click.wav',
      'sounds/nitro_start.wav',
      'sounds/crash.mp3',
      'sounds/car_hit.wav',
      'sounds/coin_collect.mp3',
      'sounds/fuel_collect.mp3',
      'sounds/car_ignition.mp3',
      'sounds/horn.wav',
      'sounds/touch.mp3',
      // 'sounds/nitro_loop.mp3',
    ]);

    // Create pools for all short sounds
    _coinPool = await FlameAudio.createPool(
      'sounds/coin_collect.mp3',
      maxPlayers: 6,
    );
    _fuelPool = await FlameAudio.createPool(
      'sounds/fuel_collect.mp3',
      maxPlayers: 6,
    );
    _brakePool = await FlameAudio.createPool('sounds/brake.mp3', maxPlayers: 3);
    _lightsPool = await FlameAudio.createPool(
      'sounds/lights_click.wav',
      maxPlayers: 3,
    );
    _crashPool = await FlameAudio.createPool('sounds/crash.mp3', maxPlayers: 3);
    _hitPool = await FlameAudio.createPool('sounds/car_hit.wav', maxPlayers: 3);
    _hornPool = await FlameAudio.createPool('sounds/horn.wav', maxPlayers: 3);
    _nitroStartPool = await FlameAudio.createPool(
      'sounds/nitro_start.wav',
      maxPlayers: 2,
    );
    _touchPool = await FlameAudio.createPool(
      'sounds/touch.mp3',
      maxPlayers: 4, // allow overlapping taps
    );
    

    // Preload nitro loop once (no re-setting at runtime)
    // await _nitroLoop.setSourceAsset('sounds/nitro_loop.mp3');
    // _nitroLoop.setReleaseMode(ReleaseMode.loop);
    // _nitroLoop.setVolume(0.65);

    if (musicPref) await _startBgmInternal();
  }

  /* ─────────────── Music helpers ─────────────── */

  static bool get isPlaying => _isPlaying;

  static Future<void> _playNextTrack() async {
    final source = AssetSource(_bgmTracks[_trackIndex]);
    await _musicPlayer.play(source, volume: 0.8);
  }

  static Future<void> _startBgmInternal() async {
    if (_isPlaying) return;

    await _playNextTrack();
    _isPlaying = true;

    _bgmSub = _musicPlayer.onPlayerComplete.listen((_) async {
      _trackIndex = (_trackIndex + 1) % _bgmTracks.length;
      await _playNextTrack();
    });
  }

  static Future<void> startBgm() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_kMusicPref) ?? true)) return;
    await _startBgmInternal();
  }

  static Future<void> stopBgm() async {
    if (!_isPlaying) return;
    _isPlaying = false;
    await _musicPlayer.stop();
    await _bgmSub.cancel();
  }

  static Future<void> pauseBgm() async {
    if (_isPlaying) await _musicPlayer.pause();
  }

  static Future<void> resumeBgm() async {
    if (_isPlaying) await _musicPlayer.resume();
  }

  static Future<void> toggleMusic() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = !(prefs.getBool(_kMusicPref) ?? true);
    await prefs.setBool(_kMusicPref, enabled);
    if (enabled) {
      await _startBgmInternal();
    } else {
      await stopBgm();
    }
  }

  /* ─────────────── SFX global toggle ─────────────── */

  static Future<void> setFxEnabled(bool on) async {
    _fxEnabled = on;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kFxPref, on);
    // if (!on) _nitroLoop.stop();
  }

  /* ─────────────── Hero switching ─────────────── */

  static Future<void> setActiveCar(CarStats stats) async {
    _active = stats;
    await FlameAudio.audioCache.load(stats.nitroStartSfx);
  }

  /* ─────────────── One-shot SFX ─────────────── */

  // static void ignition() => _play('sounds/car_ignition.mp3', .7);
  static final AudioPlayer _ignitionPlayer = AudioPlayer();
  static Future<void> ignition() async {
    if (!_fxEnabled) return;
    await _ignitionPlayer.stop(); // ensure no overlapping
    await _ignitionPlayer.play(
      AssetSource('audio/sounds/car_ignition.mp3'),
      volume: 0.7,
    );
  }

  static Future<void> stopIgnition() async {
    await _ignitionPlayer.stop();
  }

  static void brake() {
    if (_fxEnabled) _brakePool.start(volume: 0.5);
  }

  static void lightsToggle() {
    if (_fxEnabled) _lightsPool.start(volume: 0.7);
  }

  static void crash() {
    if (_fxEnabled) _crashPool.start(volume: 1.0);
  }

  static void hit() {
    if (_fxEnabled) _hitPool.start(volume: 1.0);
  }

  static void horn() {
    if (_fxEnabled) _hornPool.start(volume: 0.9);
  }

  static void coinCollect() {
    if (_fxEnabled) _coinPool.start(volume: 0.9);
  }

  static void fuelCollect() {
    if (_fxEnabled) _fuelPool.start(volume: 0.9);
  }

  /* ─────────────── Nitro helpers ─────────────── */

  static Future<void> nitroStart() async {
    if (!_fxEnabled) return;

    _nitroStartPool.start(volume: 0.9);

    if (_isPlaying) {
      _nitroPausedBgm = true;
      await _musicPlayer.setVolume(0.3);
    }

    await _nitroLoop.resume();
  }

  static Future<void> nitroStop() async {
    await _nitroLoop.stop();

    if (_nitroPausedBgm && _isPlaying) {
      _nitroPausedBgm = false;
      await _musicPlayer.setVolume(0.8);
    }
  }

  /* ─────────────── Internal play helper ─────────────── */

  static void _play(String path, double vol) {
    if (_fxEnabled) FlameAudio.play(path, volume: vol);
  }

  // ------------------ touch sound ------------------
  static void playTouch() {
    if (_fxEnabled) {
      _touchPool.start(volume: 0.5);
    }
  }
// ------------------ swipe sound ------------------
  static void playSwipe() {
  if (_fxEnabled) FlameAudio.play('sounds/swipe.mp3', volume: 0.8);
}

}
