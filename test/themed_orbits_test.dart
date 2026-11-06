import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:atomic_orbital/constants/game_constants.dart';
import 'package:atomic_orbital/game/game_engine.dart';
import 'package:atomic_orbital/game/game_screen.dart';
import 'package:atomic_orbital/game/game_skin.dart';
import 'package:atomic_orbital/game/gameplay_feedback.dart';
import 'package:atomic_orbital/models/components.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

GameEngine _start({bool practice = false}) {
  final engine = GameEngine(random: math.Random(41), practice: practice)
    ..startGame(recordProgress: false);
  (engine.energy.logic as EnergyLogicComponent).angle = 180;
  engine.onTouchDown();
  engine.advanceFrame();
  engine.onTouchUp();
  engine.energy.collision.isCollidable = false;
  final player = engine.player.logic as PlayerLogicComponent;
  player
    ..speedOrbit = 0
    ..currentAngle = 0
    ..currentRadius = player.minRadius
    ..speedRadius = 0;
  player.positionPlayer(engine.player);
  return engine;
}

void _advance(GameEngine engine) {
  for (final photon in engine.photons) {
    photon.collision.isCollidable = false;
  }
  engine.advanceFrame();
}

void _pickup(GameEngine engine) {
  engine.onTouchUp();
  final player = engine.player.logic as PlayerLogicComponent;
  player
    ..speedOrbit = 0
    ..currentAngle = 0
    ..currentRadius = player.minRadius
    ..speedRadius = 0;
  player.positionPlayer(engine.player);
  final energy = engine.energy.logic as EnergyLogicComponent;
  energy
    ..onOrbit = 0
    ..angle = 0;
  engine.energy.collision.isCollidable = true;
  final score = engine.score;
  _advance(engine);
  expect(engine.score, score + 1);
  energy.angle = 180;
  engine.energy.collision.isCollidable = false;
}

List<Object> _snapshot(GameEngine engine) {
  final player = engine.player.logic as PlayerLogicComponent;
  final energy = engine.energy.logic as EnergyLogicComponent;
  return [
    engine.state,
    engine.score,
    engine.health,
    engine.gameTime,
    engine.backgroundRed,
    player.currentAngle,
    player.currentRadius,
    player.speedRadius,
    player.direction,
    player.isTouching,
    energy.onOrbit,
    energy.angle,
    energy.rotation,
    for (final orbit in engine.orbits)
      [orbit.radius, orbit.rotation, orbit.direction],
    for (final entity in engine.entities)
      [
        entity.id,
        entity.type,
        entity.position.position.x,
        entity.position.position.y,
        entity.size.radius,
        entity.isDeleted,
        entity.collision.isCollidable,
      ],
    for (final photon in engine.photons)
      [
        (photon.logic as PhotonLogicComponent).polarRadius,
        (photon.logic as PhotonLogicComponent).polarAngle,
        (photon.logic as PhotonLogicComponent).radius,
        (photon.logic as PhotonLogicComponent).growing,
      ],
  ];
}

Future<ui.Image> _image(Size size, void Function(Canvas) draw) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(size.width.toInt(), size.height.toInt());
  } finally {
    picture.dispose();
  }
}

void _paintArena(Canvas canvas, Rect bounds, GameEngine engine, GameSkin skin,
    {bool reduceMotion = false, GameplayFeedback? feedback}) {
  canvas.save();
  canvas.clipRect(bounds);
  canvas.translate(bounds.left, bounds.top);
  canvas.scale(bounds.width / engine.width);
  canvas.translate(0, -(engine.height - engine.width) / 2);
  GamePainter(engine,
          skin: skin, reduceMotion: reduceMotion, feedback: feedback)
      .paint(canvas, Size(engine.width.toDouble(), engine.height.toDouble()));
  canvas.restore();
}

Future<List<int>> _arenaPixels(GameEngine engine, GameSkin skin,
    {required bool reduceMotion}) async {
  final image = await _image(
      const Size(360, 360),
      (canvas) => _paintArena(
          canvas, const Rect.fromLTWH(0, 0, 360, 360), engine, skin,
          reduceMotion: reduceMotion));
  try {
    return (await image.toByteData())!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.initialize();
    await (FontLoader('Roboto')
          ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf')))
        .load();
  });
  final skins = GameSkin.values.where((skin) => skin != GameSkin.classic);

  test('every themed path stays on its changing live ring and player radius',
      () async {
    final engine = _start(practice: true);
    addTearDown(engine.dispose);
    while (engine.score < 5) {
      _pickup(engine);
    }
    final player = engine.player.logic as PlayerLogicComponent;
    final samples = <({double radius, bool active})>[
      (radius: engine.orbits.last.radius, active: false),
      (radius: player.currentRadius, active: true),
    ];
    engine.onTouchDown();
    for (var frame = 1; frame <= 60; frame++) {
      if (frame == 31) engine.onTouchUp();
      _advance(engine);
      if (frame == 15 || frame == 45 || frame == 60) {
        samples.add((radius: engine.orbits[1].radius, active: false));
        samples.add((radius: player.currentRadius, active: true));
      }
    }
    expect(
        samples
            .where((sample) => sample.active)
            .map((sample) => sample.radius)
            .toSet()
            .length,
        greaterThan(2));
    for (final skin in skins) {
      for (final sample in samples) {
        final radius = sample.radius * .4;
        const strokeWidth = 2.0;
        const center = Offset(220, 220);
        final image = await _image(const Size(440, 440), (canvas) {
          skin.drawOrbit(canvas, center, radius,
              rotation: .7,
              time: 1.3,
              strokeWidth: strokeWidth,
              active: sample.active);
        });
        try {
          final pixels = (await image.toByteData())!;
          var painted = 0;
          var outsideAnnulus = 0;
          var minPaintedRadius = double.infinity;
          var maxPaintedRadius = 0.0;
          for (var y = 0; y < 440; y++) {
            for (var x = 0; x < 440; x++) {
              if (pixels.getUint8((y * 440 + x) * 4 + 3) == 0) continue;
              painted++;
              final distance = (Offset(x + .5, y + .5) - center).distance;
              minPaintedRadius = math.min(minPaintedRadius, distance);
              maxPaintedRadius = math.max(maxPaintedRadius, distance);
              if ((distance - radius).abs() > strokeWidth * 5 + 2) {
                outsideAnnulus++;
              }
            }
          }
          final subject = '${skin.id}, radius $radius, active ${sample.active}';
          expect(painted, greaterThan(80), reason: subject);
          expect(outsideAnnulus, 0, reason: subject);
          expect((minPaintedRadius + maxPaintedRadius) / 2,
              closeTo(radius, strokeWidth * 4 + 2),
              reason: subject);
        } finally {
          image.dispose();
        }
      }
    }
  });

  test(
      'themed rendering preserves seeded expansion at 5, 10 and 20 through all 60 ticks',
      () {
    final oracle =
        jsonDecode(File('test/oracle/release_41.json').readAsStringSync())
            as Map<String, dynamic>;
    final trace = (oracle['orbits'] as List<dynamic>)
        .singleWhere((entry) => entry['width'] == 1080);
    final samples = {
      for (final sample in trace['samples'] as List<dynamic>)
        sample['tick'] as int: sample as Map<String, dynamic>,
    };
    for (final skin in skins) {
      final rendered = _start();
      final control = _start();
      try {
        for (var milestone = 0; milestone < 3; milestone++) {
          final target = [5, 10, 20][milestone];
          while (rendered.score < target) {
            _pickup(rendered);
            _pickup(control);
          }
          final initialCount = rendered.orbits.length;
          final player = rendered.player.logic as PlayerLogicComponent;
          final initialPlayerRadius = player.currentRadius;
          var outerPlayerRadius = initialPlayerRadius;
          rendered.onTouchDown();
          control.onTouchDown();
          for (var tick = 0; tick < 60; tick++) {
            if (tick == 30) {
              outerPlayerRadius = player.currentRadius;
              rendered.onTouchUp();
              control.onTouchUp();
            }
            _advance(rendered);
            _advance(control);
            final beforePainting = _snapshot(rendered);
            final recorder = ui.PictureRecorder();
            GamePainter(rendered, skin: skin)
                .paint(Canvas(recorder), const Size(1080, 1794));
            recorder.endRecording().dispose();
            expect(_snapshot(rendered), beforePainting,
                reason: '${skin.id} paint at score $target tick $tick');
            expect(_snapshot(rendered), _snapshot(control),
                reason: '${skin.id} seeded state at score $target tick $tick');
            expect(rendered.orbits.length,
                tick < 59 ? initialCount : initialCount + 1);
            final sample = samples[milestone * 60 + tick];
            if (sample != null) {
              expect(
                  rendered.orbits.map((orbit) => orbit.radius),
                  (sample['radii'] as List<dynamic>)
                      .map((value) => float32(value as num)),
                  reason:
                      '${skin.id} released-Java radius at score $target tick $tick');
            }
          }
          expect(outerPlayerRadius, greaterThan(initialPlayerRadius));
          expect(player.currentRadius, lessThan(outerPlayerRadius));
        }
      } finally {
        rendered.dispose();
        control.dispose();
      }
    }
  });

  test(
      'reduced motion freezes decoration but keeps live expanding and held radii',
      () async {
    for (final skin in [
      GameSkin.deepBlue,
      GameSkin.spiderWeb,
      GameSkin.volcanoHop
    ]) {
      final engine = _start(practice: true);
      try {
        final still = await _arenaPixels(engine, skin, reduceMotion: true);
        for (var tick = 0; tick < 18; tick++) {
          _advance(engine);
        }
        expect(await _arenaPixels(engine, skin, reduceMotion: true),
            orderedEquals(still),
            reason: '${skin.id} decorative time and rotation must freeze');
        final player = engine.player.logic as PlayerLogicComponent;
        engine.onTouchDown();
        for (var tick = 0; tick < 18; tick++) {
          _advance(engine);
        }
        final held = await _arenaPixels(engine, skin, reduceMotion: true);
        final activeRadius = player.currentRadius / 3;
        final center = Offset(180,
            ((engine.height ~/ 2) - (engine.height - engine.width) / 2) / 3);
        var activePathChanges = 0;
        for (var y = 0; y < 360; y++) {
          for (var x = 0; x < 360; x++) {
            // Exclude the player itself at the bottom of its orbit.
            if (y > center.dy + activeRadius * .5 ||
                ((Offset(x + .5, y + .5) - center).distance - activeRadius)
                        .abs() >
                    7) {
              continue;
            }
            final index = (y * 360 + x) * 4;
            if (held[index] != still[index] ||
                held[index + 1] != still[index + 1] ||
                held[index + 2] != still[index + 2]) {
              activePathChanges++;
            }
          }
        }
        expect(activePathChanges, greaterThan(20),
            reason:
                '${skin.id} active path must follow the held radius even with reduced motion');
        while (engine.score < 5) {
          _pickup(engine);
        }
        final before = await _arenaPixels(engine, skin, reduceMotion: true);
        final beforeOrbit = engine.orbits[1].radius;
        final beforePlayer = player.currentRadius;
        engine.onTouchDown();
        for (var tick = 0; tick < 18; tick++) {
          _advance(engine);
        }
        expect(engine.orbits[1].radius, lessThan(beforeOrbit));
        expect(player.currentRadius, greaterThan(beforePlayer));
        expect(await _arenaPixels(engine, skin, reduceMotion: true),
            isNot(orderedEquals(before)),
            reason:
                '${skin.id} reduced motion must not freeze live game geometry');
      } finally {
        engine.dispose();
      }
    }
  });

  if (const bool.fromEnvironment('GENERATE_ORBIT_EVIDENCE')) {
    test('export actual gameplay arenas and orbit expansion animation',
        () async {
      final directory = Directory(const String.fromEnvironment(
          'ORBIT_EVIDENCE_DIRECTORY',
          defaultValue: 'build/themed-orbits-preview'));
      await directory.create(recursive: true);
      final engine = _start();
      try {
        while (engine.score < 10) {
          _pickup(engine);
          if (engine.score == 5 || engine.score == 10) {
            for (var tick = 0; tick < 60; tick++) {
              _advance(engine);
            }
          }
        }
        (engine.player.logic as PlayerLogicComponent).speedOrbit = 3;
        engine.onTouchDown();
        for (var tick = 0; tick < 14; tick++) {
          _advance(engine);
        }
        final worlds = skins.toList();
        final overview = await _image(const Size(1200, 1320), (canvas) {
          canvas.drawPaint(Paint()..color = GameConstants.backgroundColor);
          _label(canvas, 'THEMED PATHS', const Offset(20, 18), 28);
          _label(canvas, 'Four paths after 10 pickups · moving outward',
              const Offset(20, 56), 16);
          for (var i = 0; i < worlds.length; i++) {
            final origin = Offset(16 + i % 3 * 398.0, 100 + i ~/ 3 * 300.0);
            _label(canvas, worlds[i].name, origin, 19, color: worlds[i].accent);
            _paintArena(
                canvas,
                Rect.fromLTWH(origin.dx + 64, origin.dy + 26, 268, 268),
                engine,
                worlds[i]);
          }
        });
        await _saveImage(
            overview, File('${directory.path}/all-world-orbits.png'));
      } finally {
        engine.dispose();
      }

      final animated = _start();
      final feedback = GameplayFeedback()..sync(animated);
      animated.onScoreChanged = (_) {
        final pickup = animated.energy.position.position;
        feedback.collect(Offset(pickup.x, pickup.y), animated.gameTime);
      };
      final frameData = <Map<String, Object>>[];
      var frameNumber = 0;
      try {
        for (final milestone in [5, 10, 20]) {
          while (animated.score < milestone) {
            _pickup(animated);
            feedback.sync(animated);
          }
          final player = animated.player.logic as PlayerLogicComponent;
          player.speedOrbit = 3;
          animated.onTouchDown();
          for (var tick = 0; tick <= 90; tick++) {
            if (tick == 45) animated.onTouchUp();
            if (tick % 6 == 0) {
              final frame = await _image(const Size(1080, 466), (canvas) {
                canvas
                    .drawPaint(Paint()..color = GameConstants.backgroundColor);
                _label(
                    canvas,
                    'SCORE $milestone · ${tick < 45 ? 'HOLD: MOVING OUT' : 'RELEASE: MOVING IN'}',
                    const Offset(16, 12),
                    24);
                _label(
                    canvas,
                    '${animated.orbits.length} paths · the arena grows at 5, 10 and 20 pickups',
                    const Offset(16, 45),
                    15);
                final examples = [
                  GameSkin.deepBlue,
                  GameSkin.spiderWeb,
                  GameSkin.volcanoHop
                ];
                for (var column = 0; column < examples.length; column++) {
                  _label(canvas, examples[column].name,
                      Offset(16 + column * 360.0, 77), 20,
                      color: examples[column].accent);
                  _paintArena(
                      canvas,
                      Rect.fromLTWH(column * 360.0, 104, 360, 360),
                      animated,
                      examples[column],
                      feedback: feedback);
                }
              });
              await _saveImage(
                  frame,
                  File(
                      '${directory.path}/frame-${frameNumber.toString().padLeft(3, '0')}.png'));
              frameData.add({
                'frame': frameNumber++,
                'score': animated.score,
                'tick': tick,
                'orbits': animated.orbits.map((orbit) => orbit.radius).toList(),
                'playerRadius': player.currentRadius,
                'holding': tick < 45,
                'charge': feedback.charge,
                'fire': feedback.fire,
              });
            }
            if (tick < 90) {
              _advance(animated);
              feedback.sync(animated);
            }
          }
        }
      } finally {
        animated.dispose();
      }
      await File('${directory.path}/frames.json')
          .writeAsString(const JsonEncoder.withIndent('  ').convert({
        'fps': 10,
        'source':
            'GamePainter with real 60 Hz engine transitions; controlled pickups; photon collisions disabled',
        'frames': frameData,
      }));
    });
  }
}

void _label(Canvas canvas, String text, Offset position, double size,
    {Color color = const Color(0xFFE7EEEA)}) {
  final painter = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(fontFamily: 'Roboto', color: color, fontSize: size)),
      textDirection: TextDirection.ltr)
    ..layout();
  painter.paint(canvas, position);
  painter.dispose();
}

Future<void> _saveImage(ui.Image image, File file) async {
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  } finally {
    image.dispose();
  }
}
