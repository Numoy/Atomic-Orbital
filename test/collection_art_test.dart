import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:atomic_orbital/constants/game_constants.dart';
import 'package:atomic_orbital/game/game_skin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = Size(224, 224);
const _center = Offset(112, 112);

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

Future<Uint8List> _pixels(GameSkin skin, double radius, double progress) async {
  final image = await _image(
      _size,
      (canvas) =>
          skin.drawCollection(canvas, _center, radius, progress: progress));
  try {
    return (await image.toByteData())!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

({int ink, int alpha, double extent}) _measure(Uint8List pixels) {
  var ink = 0;
  var alpha = 0;
  var extentSquared = 0.0;
  for (var y = 0; y < _size.height.toInt(); y++) {
    for (var x = 0; x < _size.width.toInt(); x++) {
      final value = pixels[(y * _size.width.toInt() + x) * 4 + 3];
      if (value == 0) continue;
      ink++;
      alpha += value;
      extentSquared = math.max(
          extentSquared, (Offset(x + .5, y + .5) - _center).distanceSquared);
    }
  }
  return (ink: ink, alpha: alpha, extent: math.sqrt(extentSquared));
}

void _label(Canvas canvas, String text, Offset at, double size, Color color) {
  final painter = TextPainter(
    text: TextSpan(
        text: text,
        style: TextStyle(fontFamily: 'Roboto', fontSize: size, color: color)),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: 360);
  painter.paint(canvas, at);
  painter.dispose();
}

void _gallery(Canvas canvas, double progress) {
  canvas.drawPaint(Paint()..color = GameConstants.backgroundColor);
  _label(canvas, 'PICKUP CELEBRATIONS', const Offset(24, 20), 28, Colors.white);
  _label(canvas, 'Collectible · effect at arena scale · effect at phone scale',
      const Offset(24, 58), 16, const Color(0xFF9AA6B5));
  final skins = GameSkin.values.skip(1).toList();
  for (var i = 0; i < skins.length; i++) {
    final skin = skins[i];
    final origin = Offset(24 + (i % 3) * 396.0, 108 + (i ~/ 3) * 220.0);
    _label(canvas, skin.name, origin, 22, skin.accent);
    skin.drawPickup(canvas, origin + const Offset(36, 110), 27);
    skin.drawCollection(canvas, origin + const Offset(176, 110), 43,
        progress: progress);
    skin.drawCollection(canvas, origin + const Offset(316, 110), 16,
        progress: progress);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final skins = GameSkin.values.skip(1);

  test('collection endpoints, Classic and invalid geometry paint nothing',
      () async {
    final image = await _image(_size, (canvas) {
      for (final skin in GameSkin.values) {
        for (final progress in [
          -1.0,
          0.0,
          1.0,
          2.0,
          double.nan,
          double.infinity
        ]) {
          skin.drawCollection(canvas, _center, 43, progress: progress);
        }
        for (final radius in [-1.0, 0.0, double.nan, double.infinity]) {
          skin.drawCollection(canvas, _center, radius, progress: .4);
        }
        skin.drawCollection(canvas, const Offset(double.nan, 0), 43,
            progress: .4);
        skin.drawCollection(canvas, const Offset(0, double.infinity), 43,
            progress: .4);
      }
      GameSkin.classic.drawCollection(canvas, _center, 43, progress: .4);
    });
    try {
      final bytes = (await image.toByteData())!.buffer.asUint8List();
      expect(bytes.every((value) => value == 0), isTrue);
    } finally {
      image.dispose();
    }
  });

  test('all collection effects move, fade and stay within two pickup radii',
      () async {
    for (final skin in skins) {
      for (final radius in [16.0, 43.0]) {
        final early = await _pixels(skin, radius, .12);
        final middle = await _pixels(skin, radius, .4);
        final late = await _pixels(skin, radius, .85);
        for (final pixels in [early, middle, late]) {
          final stats = _measure(pixels);
          expect(stats.ink, greaterThan(10),
              reason: '${skin.id}, radius $radius');
          expect(stats.extent, lessThanOrEqualTo(radius * 2 + 1),
              reason: '${skin.id} must stay local to the collected item');
        }
        expect(early, isNot(equals(middle)),
            reason: '${skin.id} particles must travel');
        expect(_measure(late).alpha, lessThan(_measure(middle).alpha),
            reason:
                '${skin.id} must fade before the 0.55-second event expires');
        expect(await _pixels(skin, radius, .4), middle,
            reason: '${skin.id} must not use per-frame randomness');
      }
    }
  });

  test('each world has a distinct collection payoff at phone scale', () async {
    final previous = <({GameSkin skin, Uint8List pixels})>[];
    for (final skin in skins) {
      final pixels = await _pixels(skin, 16, .3);
      for (final other in previous) {
        expect(pixels, isNot(equals(other.pixels)),
            reason: '${skin.id} and ${other.skin.id} need distinct pickup art');
      }
      previous.add((skin: skin, pixels: pixels));
    }
  });

  if (const bool.fromEnvironment('GENERATE_COLLECTION_EVIDENCE')) {
    test('export every pickup celebration at arena and phone scale', () async {
      await (FontLoader('Roboto')
            ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf')))
          .load();
      final directory = Directory(const String.fromEnvironment(
          'COLLECTION_EVIDENCE_DIRECTORY',
          defaultValue: 'build/collection-preview'));
      await directory.create(recursive: true);
      for (var frame = 0; frame <= 11; frame++) {
        final image = await _image(
            const Size(1200, 1000), (canvas) => _gallery(canvas, frame / 11));
        try {
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
                  '${directory.path}/frame-${frame.toString().padLeft(2, '0')}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
        } finally {
          image.dispose();
        }
      }
    });
  }
}
