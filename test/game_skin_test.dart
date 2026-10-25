import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:atomic_orbital/constants/game_constants.dart';
import 'package:atomic_orbital/game/game_engine.dart';
import 'package:atomic_orbital/game/game_screen.dart';
import 'package:atomic_orbital/game/game_skin.dart';
import 'package:atomic_orbital/models/components.dart';
import 'package:atomic_orbital/models/vector2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Roboto')
          ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf')))
        .load();
  });

  test('world identifiers are stable and unknown saved worlds use Classic', () {
    expect(GameSkin.values.map((skin) => skin.id).toSet().length,
        GameSkin.values.length);
    for (final skin in GameSkin.values) {
      expect(GameSkin.byId(skin.id), skin);
    }
    expect(GameSkin.byId(null), GameSkin.classic);
    expect(GameSkin.byId('removed-world'), GameSkin.classic);
    expect(GameSkin.classic.price, 0);
    expect(GameSkin.cowAbduction.price, 150);
    expect(GameSkin.deepBlue.price, 150);
    expect(GameSkin.values.length, 12);
    for (final skin in GameSkin.values.skip(1)) {
      expect(skin.price, 150);
    }
  });

  test('Earth retains Africa, South America and the Atlantic at game scale',
      () async {
    final image = await _image(const Size(160, 160), (canvas) {
      GameSkin.cowAbduction.drawCore(canvas, const Offset(80, 80), 64);
    });
    final pixels = (await image.toByteData())!;
    int channelAt(Offset position, int channel) {
      final x = (80 + position.dx * 64).round();
      final y = (80 + position.dy * 64).round();
      return pixels.getUint8((y * 160 + x) * 4 + channel);
    }

    for (final land in [const Offset(.643, 0), const Offset(-.554, .259)]) {
      expect(channelAt(land, 1), greaterThan(channelAt(land, 2)));
    }
    const atlantic = Offset(-.174, 0);
    expect(channelAt(atlantic, 2), greaterThan(channelAt(atlantic, 1)));
    image.dispose();
  });

  test('UFO pilot has two readable eyes at phone gameplay size', () async {
    final image = await _image(const Size(48, 48), (canvas) {
      GameSkin.cowAbduction.drawPlayer(canvas, const Offset(24, 24), 13);
    });
    final pixels = (await image.toByteData())!;
    for (final region in [(left: 19, right: 24), (left: 24, right: 29)]) {
      var eyeInk = 0;
      for (var y = 17; y < 21; y++) {
        for (var x = region.left; x < region.right; x++) {
          final i = (y * 48 + x) * 4;
          if (pixels.getUint8(i + 3) > 200 &&
              pixels.getUint8(i) < 85 &&
              pixels.getUint8(i + 1) < 125 &&
              pixels.getUint8(i + 2) < 135) {
            eyeInk++;
          }
        }
      }
      expect(eyeInk, greaterThan(0));
    }
    image.dispose();
  });

  test('treasure chest keeps readable wood and gold at phone pickup size',
      () async {
    final image = await _image(const Size(40, 40), (canvas) {
      GameSkin.deepBlue.drawPickup(canvas, const Offset(20, 20), 16);
    });
    try {
      final pixels = (await image.toByteData())!;
      var wood = 0;
      var gold = 0;
      for (var offset = 0; offset < pixels.lengthInBytes; offset += 4) {
        if (pixels.getUint8(offset + 3) < 200) continue;
        final r = pixels.getUint8(offset);
        final g = pixels.getUint8(offset + 1);
        final b = pixels.getUint8(offset + 2);
        if (r < 220 && r > g * 1.25 && g > b * 1.25) wood++;
        if (r > 220 && g > 170 && b < g * .8) gold++;
      }
      expect(wood, greaterThan(40));
      expect(gold, greaterThan(20));
    } finally {
      image.dispose();
    }
  });

  if (const bool.fromEnvironment('GENERATE_SKIN_EVIDENCE')) {
    for (final gallery in [
      (name: 'all-worlds', worlds: GameSkin.values),
      (name: 'new-worlds', worlds: GameSkin.values.skip(7).toList()),
    ]) {
      test('render ${gallery.name} overview', () async {
        final rows = (gallery.worlds.length / 3).ceil();
        final size = Size(1440, rows * 550);
        final image = await _image(size, (canvas) {
          canvas.drawRect(Offset.zero & size,
              Paint()..color = GameConstants.backgroundColor);
          for (var i = 0; i < gallery.worlds.length; i++) {
            final skin = gallery.worlds[i];
            final inRow = min(3, gallery.worlds.length - (i ~/ 3) * 3);
            final origin =
                Offset((i % 3) * 480.0 + (3 - inRow) * 240, (i ~/ 3) * 550.0);
            canvas.save();
            canvas.translate(origin.dx + 30, origin.dy + 35);
            SkinPreview(skin: skin, hero: true)
                .paint(canvas, const Size(420, 420));
            canvas.restore();
            final name = TextPainter(
                text: TextSpan(
                    text: skin.name,
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 28,
                        color: skin.accent,
                        fontWeight: FontWeight.w700)),
                textDirection: TextDirection.ltr)
              ..layout();
            name.paint(canvas, origin + Offset((480 - name.width) / 2, 465));
            name.dispose();
          }
        });
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory(const String.fromEnvironment(
            'SKIN_EVIDENCE_DIRECTORY',
            defaultValue: 'docs/evidence/world-review-2026-10-25'));
        await directory.create(recursive: true);
        await File('${directory.path}/${gallery.name}.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  }

  for (final skin in GameSkin.values) {
    if (skin == GameSkin.cowAbduction) {
      test('${skin.id} globe lighting carries from its lit face into shadow',
          () async {
        final image = await _image(const Size(160, 160), (canvas) {
          skin.drawCore(canvas, const Offset(80, 80), 64);
        });
        final pixels = (await image.toByteData())!;
        double lightAt(int centerX, int centerY) {
          var total = 0.0;
          for (var y = centerY - 4; y <= centerY + 4; y++) {
            for (var x = centerX - 4; x <= centerX + 4; x++) {
              final offset = (y * 160 + x) * 4;
              total += Color.fromARGB(255, pixels.getUint8(offset),
                      pixels.getUint8(offset + 1), pixels.getUint8(offset + 2))
                  .computeLuminance();
            }
          }
          return total / 81;
        }

        expect(lightAt(54, 54), greaterThan(lightAt(112, 112) * 1.5));
        image.dispose();
      });
    }

    test('${skin.id} featured scene fits its canvas', () async {
      final image = await _image(const Size(192, 192), (canvas) {
        canvas.translate(32, 32);
        SkinPreview(skin: skin, hero: true).paint(canvas, const Size(128, 128));
      });
      final pixels = (await image.toByteData())!;
      var painted = 0;
      for (var y = 0; y < 192; y++) {
        for (var x = 0; x < 192; x++) {
          final offset = (y * 192 + x) * 4;
          final alpha = pixels.getUint8(offset + 3);
          if (alpha > 0) painted++;
          if (x < 31 || x > 160 || y < 31 || y > 160) expect(alpha, 0);
        }
      }
      expect(painted, greaterThan(1000));
      image.dispose();
    });

    test('${skin.id} artwork preserves circular bounds and opaque core',
        () async {
      final parts = [
        skin.drawCore,
        skin.drawPlayer,
        skin.drawPickup,
        skin.drawHazard
      ];
      for (var part = 0; part < parts.length; part++) {
        final image = await _image(const Size(96, 96), (canvas) {
          parts[part](canvas, const Offset(48, 48), 32);
          parts[part](canvas, const Offset(4, 4), 0);
        });
        final pixels = (await image.toByteData())!;
        var painted = 0;
        var top = 96;
        var bottom = 0;
        for (var y = 0; y < 96; y++) {
          for (var x = 0; x < 96; x++) {
            final distance =
                (Offset(x + .5, y + .5) - const Offset(48, 48)).distance;
            final alpha = pixels.getUint8((y * 96 + x) * 4 + 3);
            if (alpha > 0) {
              painted++;
              top = min(top, y);
              bottom = max(bottom, y + 1);
            }
            if (distance > 33) expect(alpha, 0);
            if (part == 0 && distance < 31) expect(alpha, 255);
          }
        }
        expect(painted, greaterThan(100));
        if (skin == GameSkin.cowAbduction && part == 1) {
          expect(bottom - top, greaterThan(40),
              reason: 'The UFO dome and hull must stay readable at game size');
        }
        image.dispose();
      }
    });

    test('${skin.id} keeps hazard growth, core occlusion and engine state',
        () async {
      final engine = GameEngine(random: Random(1))..startGame();
      engine.onTouchDown();
      engine.advanceFrame();
      final photon = engine.photons.single;
      final logic = photon.logic as PhotonLogicComponent;
      photon.position.setPosition(Vector2D(300, 600));
      logic.radius = 15;
      final before = engine.entities
          .map((entity) => [
                entity.position.position.x,
                entity.position.position.y,
                entity.size.radius
              ])
          .toList();
      Future<ui.Image> render() => _image(
          const Size(1080, 1794),
          (canvas) => GamePainter(engine, skin: skin)
              .paint(canvas, const Size(1080, 1794)));
      final image = await render();
      final pixels = (await image.toByteData())!;
      List<int> at(int x, int y) =>
          [for (var i = 0; i < 4; i++) pixels.getUint8((y * 1080 + x) * 4 + i)];
      final hazard = await _image(const Size(40, 40), (canvas) {
        skin.drawHazard(canvas, const Offset(20, 20), 15);
      });
      final hazardPixels = (await hazard.toByteData())!;
      for (final x in [20, 33]) {
        expect(at(280 + x, 600), [
          for (var i = 0; i < 4; i++)
            hazardPixels.getUint8((20 * 40 + x) * 4 + i),
        ]);
      }
      expect(hazardPixels.getUint8((20 * 40 + 37) * 4 + 3), 0);
      hazard.dispose();
      final opaqueCore = at(650, 928);
      expect(
          engine.entities
              .map((entity) => [
                    entity.position.position.x,
                    entity.position.position.y,
                    entity.size.radius
                  ])
              .toList(),
          before);
      expect(logic.radius, 15);
      image.dispose();
      photon.position.setPosition(Vector2D(650, 928));
      final covered = await render();
      final coveredPixels = (await covered.toByteData())!;
      expect([
        for (var i = 0; i < 4; i++)
          coveredPixels.getUint8((928 * 1080 + 650) * 4 + i)
      ], opaqueCore);
      covered.dispose();
      engine.dispose();
    });

    test('${skin.id} rendering leaves seeded simulation and spawning identical',
        () {
      final rendered = GameEngine(random: Random(17))..startGame();
      final control = GameEngine(random: Random(17))..startGame();
      rendered.player.collision.isCollidable = false;
      control.player.collision.isCollidable = false;
      List<Object> snapshot(GameEngine engine) => [
            engine.state,
            engine.score,
            engine.health,
            engine.gameTime,
            engine.backgroundRed,
            engine.startAlpha,
            for (final entity in engine.entities)
              [
                entity.id,
                entity.type,
                entity.position.position.x,
                entity.position.position.y,
                entity.size.radius
              ],
            for (final orbit in engine.orbits)
              [orbit.radius, orbit.rotation, orbit.direction],
          ];
      for (var frame = 0; frame < 360; frame++) {
        if (frame % 80 == 0) {
          rendered.onTouchDown();
          control.onTouchDown();
        } else if (frame % 80 == 40) {
          rendered.onTouchUp();
          control.onTouchUp();
        }
        final recorder = ui.PictureRecorder();
        GamePainter(rendered, skin: skin)
            .paint(Canvas(recorder), const Size(1080, 1794));
        recorder.endRecording().dispose();
        rendered.advanceFrame();
        control.advanceFrame();
        expect(snapshot(rendered), snapshot(control), reason: 'Frame $frame');
      }
      rendered.dispose();
      control.dispose();
    });

    if (const bool.fromEnvironment('GENERATE_SKIN_EVIDENCE')) {
      test('render ${skin.id} character artwork at preview and game sizes',
          () async {
        const size = Size(1440, 610);
        final labels = <TextPainter>[];
        addTearDown(() {
          for (final label in labels) {
            label.dispose();
          }
        });
        final image = await _image(size, (canvas) {
          canvas.drawRect(Offset.zero & size,
              Paint()..color = GameConstants.backgroundColor);
          void label(
              String value, Offset position, double fontSize, Color color,
              {bool centered = false}) {
            final text = TextPainter(
                text: TextSpan(
                    text: value,
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: fontSize,
                        color: color)),
                textDirection: TextDirection.ltr)
              ..layout();
            text.paint(
                canvas, position - Offset(centered ? text.width / 2 : 0, 0));
            // Keep paragraph data alive until the picture has been rasterized.
            labels.add(text);
          }

          label(skin.name, const Offset(48, 30), 32, GameConstants.atomColor);
          final names = switch (skin) {
            GameSkin.classic => ['Atom', 'Player', 'Energy', 'Photon'],
            GameSkin.cowAbduction => ['Earth', 'Alien pilot', 'Cow', 'Defense'],
            GameSkin.deepBlue => [
                'Kraken',
                'Submarine',
                'Treasure chest',
                'Ink'
              ],
            GameSkin.spiderWeb => ['Spider', 'Fly', 'Sugar cube', 'Web'],
            GameSkin.dragonHoard => ['Dragon', 'Knight', 'Gem', 'Fireball'],
            GameSkin.sunflower => ['Sunflower', 'Bee', 'Pollen', 'Seed'],
            GameSkin.frostBite => ['Snow monster', 'Penguin', 'Fish', 'Ice'],
            GameSkin.hauntedHarvest => ['Pumpkin', 'Ghost', 'Candy', 'Bat'],
            GameSkin.junkyardDash => ['Robot', 'Repair drone', 'Bolt', 'Spark'],
            GameSkin.volcanoHop => ['Volcano', 'Pterosaur', 'Egg', 'Lava'],
            GameSkin.cheeseChase => ['Cat', 'Mouse', 'Cheese', 'Yarn'],
            GameSkin.jungleJam => ['Monkey', 'Toucan', 'Banana', 'Coconut'],
          };
          final parts = [
            skin.drawCore,
            skin.drawPlayer,
            skin.drawPickup,
            skin.drawHazard
          ];
          for (var i = 0; i < parts.length; i++) {
            final x = 180.0 + i * 360;
            parts[i](canvas, Offset(x, 240), i == 0 ? 126 : 112);
            label(names[i], Offset(x, 382), 22, GameConstants.atomColor,
                centered: true);
            parts[i](canvas, Offset(x, 525), [49.0, 11.0, 16.0, 7.0][i]);
          }
          label('Phone gameplay size', const Offset(48, 442), 16,
              GameConstants.quietColor);
          canvas.drawLine(const Offset(48, 430), const Offset(1392, 430),
              Paint()..color = GameConstants.quietColor.withValues(alpha: .2));
        });
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory(const String.fromEnvironment(
            'SKIN_EVIDENCE_DIRECTORY',
            defaultValue: 'docs/evidence/world-polish-2026-10-24'));
        await directory.create(recursive: true);
        await File('${directory.path}/${skin.id}-characters.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  }
}
