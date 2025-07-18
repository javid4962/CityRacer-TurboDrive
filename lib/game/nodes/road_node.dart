// road_node.dart
//
// • Draws an endlessly-scrolling 3-lane road with sidewalks.
// • Shows a start-line banner + 3-→-2-→-1 countdown in the centre.
// • Lets the parent attach a finish-line banner that scrolls down
//   with the asphalt in level mode.
//

import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class RoadNode extends Component {
  /* ───────────────────────── public config ───────────────────────── */
  final double baseScrollSpeed; // cruising speed
  final VoidCallback onCountdownComplete; // called once at t = 0
  final String controlScheme; // ‘Tilt’, ‘OnHand’, …

  /* ───────────────────────── visual sprites ──────────────────────── */
  final SpriteComponent road1, road2, road3;
  final SpriteComponent left1, left2, left3;
  final SpriteComponent right1, right2, right3;

  // start-line
  final Sprite _startLineSprite;
  SpriteComponent? _startLine;
  bool _startLineDropping = false;

  // finish-line  ← NEW
  SpriteComponent? _endLine;
  bool _endLineDropping = false;

  // countdown text
  late final TextComponent _countText;

  /* ───────────────────────── runtime state ───────────────────────── */
  int _secondsLeft = 3;
  double _accumulator = 0; // ticks up to 1 s
  bool counting = true;
  double scrollSpeed = 0; // 0 while counting
  double _scrollDeltaY = 0; // moved this frame
  double get scrollDeltaY => _scrollDeltaY;

  /* ───────────────────────── layout constants ────────────────────── */
  final double screenW, screenH;
  late final double laneWidth;

  /* ───────────────────────── ctor ────────────────────────────────── */
  RoadNode({
    required Sprite roadSprite,
    required Sprite leftSprite,
    required Sprite rightSprite,
    required Sprite startLineSprite,
    required Vector2 size,
    required this.onCountdownComplete,
    required this.controlScheme,
    this.baseScrollSpeed = 300,
  }) : screenW = size.x,
       screenH = size.y,
       _startLineSprite = startLineSprite,

       // road strips
       road1 = SpriteComponent(sprite: roadSprite, anchor: Anchor.topLeft),
       road2 = SpriteComponent(sprite: roadSprite, anchor: Anchor.topLeft),
       road3 = SpriteComponent(sprite: roadSprite, anchor: Anchor.topLeft),
       // pavements
       left1 = SpriteComponent(sprite: leftSprite, anchor: Anchor.topLeft),
       left2 = SpriteComponent(sprite: leftSprite, anchor: Anchor.topLeft),
       left3 = SpriteComponent(sprite: leftSprite, anchor: Anchor.topLeft),
       right1 = SpriteComponent(sprite: rightSprite, anchor: Anchor.topLeft),
       right2 = SpriteComponent(sprite: rightSprite, anchor: Anchor.topLeft),
       right3 = SpriteComponent(sprite: rightSprite, anchor: Anchor.topLeft);

  /* ───────────────────────── onLoad ──────────────────────────────── */
  @override
  Future<void> onLoad() async {
    super.onLoad();

    // ── sizing ─────────────────────────────────────────────
    final sideW = screenW * .15; // sidewalks 15 %
    final roadW = screenW * .70; // asphalt   70 %
    final roadSz = Vector2(roadW, screenH);
    final sideSz = Vector2(sideW, screenH);

    for (final r in [road1, road2, road3]) r.size = roadSz;
    for (final s in [left1, left2, left3, right1, right2, right3])
      s.size = sideSz;
    laneWidth = roadW / 3;

    // ── place 3 vertical tiles so we can loop them ────────
    _stackVertically(road1, road2, road3, x: sideW);
    _stackVertically(left1, left2, left3, x: 0);
    _stackVertically(right1, right2, right3, x: sideW + roadW);

    addAll([road1, road2, road3, left1, left2, left3, right1, right2, right3]);

    // ── start-line banner ─────────────────────────────────
    _startLine = _buildBanner(
      _startLineSprite,
      sideW,
      roadW,
      y: screenH / 5,
    ); // roughly top-third
    add(_startLine!);

    // ── countdown digits ─────────────────────────────────
    _countText = TextComponent(
      text: '3',
      anchor: Anchor.center,
      position: Vector2(screenW / 2, screenH / 2),
      priority: 100,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'Akira',
          fontSize: 160,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 12)],
        ),
      ),
    );
    add(_countText);
  }

  /* ───────────────────────── update ──────────────────────────────── */
  @override
  void update(double dt) {
    super.update(dt);

    /* ── 1. countdown phase ─────────────────────────────── */
    if (counting) {
      _accumulator += dt;
      if (_accumulator >= 1) {
        _accumulator -= 1;
        _secondsLeft--;

        if (_secondsLeft > 0) {
          _countText.text = '$_secondsLeft';
        } else {
          // countdown finished 🏁
          _countText.removeFromParent();

          if (_startLine != null) {
            if (controlScheme != 'OnHand') {
              _startLineDropping = true; // animate off-screen
            } else {
              _startLine!.removeFromParent(); // invisible immediately
              _startLine = null;
            }
          }

          counting = false;
          scrollSpeed = baseScrollSpeed;
          onCountdownComplete();
        }
      }

      _scrollDeltaY = 0;
      return; // skip scrolling while counting
    }

    /* ── 2. normal scrolling ────────────────────────────── */
    _scrollDeltaY = scrollSpeed * dt;

    _moveAndLoop([road1, road2, road3], _scrollDeltaY);
    _moveAndLoop([left1, left2, left3], _scrollDeltaY);
    _moveAndLoop([right1, right2, right3], _scrollDeltaY);

    // animate start-line drop (once)
    if (_startLineDropping && _startLine != null) {
      _startLine!.y += _scrollDeltaY;
      if (_startLine!.y > screenH) {
        _startLine!.removeFromParent();
        _startLine = null;
        _startLineDropping = false;
      }
    }

    // animate end-line drop (whenever attached)   ← NEW
    if (_endLineDropping && _endLine != null) {
      _endLine!.y += _scrollDeltaY;
      if (_endLine!.y > screenH) {
        _endLine!.removeFromParent();
        _endLine = null;
        _endLineDropping = false;
      }
    }
  }

  /* ───────────────────────── helpers ─────────────────────────────── */

  void _stackVertically(
    SpriteComponent a,
    SpriteComponent b,
    SpriteComponent c, {
    required double x,
  }) {
    a.position = Vector2(x, 0);
    b.position = Vector2(x, -screenH);
    c.position = Vector2(x, -2 * screenH);
  }

  void _moveAndLoop(List<SpriteComponent> col, double dy) {
    for (final c in col) c.position.y += dy;
    for (final c in col) {
      if (c.position.y >= screenH) c.position.y = _topY(col) - screenH;
    }
  }

  double _topY(List<SpriteComponent> col) =>
      col.map((c) => c.position.y).reduce(math.min);

  SpriteComponent _buildBanner(
    Sprite sprite,
    double sideW,
    double roadW, {
    required double y,
  }) {
    final double h =
        sprite.srcSize.y * (roadW / sprite.srcSize.x); // aspect-ratio scale
    return SpriteComponent(
      sprite: sprite,
      size: Vector2(roadW, h),
      anchor: Anchor.topCenter,
      position: Vector2(sideW + roadW / 2, y),
      priority: 20,
    );
  }

  /* ───────────────────────── public API ──────────────────────────── */

  /// Centre-x of lane 0, 1 or 2.
  double getLaneX(int lane) => screenW * .17 + laneWidth * lane + laneWidth / 2;

  /// Adds a finish-line banner and makes it scroll with the road.
  void attachEndLine(SpriteComponent banner) {
    _endLine = banner;
    _endLineDropping = true;
    add(banner);
  }

  void increaseSpeed(double delta) => scrollSpeed += delta;
}
