import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:atomic_orbital/constants/game_constants.dart';
import 'package:atomic_orbital/game/game_engine.dart';
import 'package:atomic_orbital/game/game_screen.dart';
import 'package:atomic_orbital/game/game_skin.dart';
import 'package:atomic_orbital/game/world_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _VisualClockEngine extends GameEngine {
  _VisualClockEngine() : super(random: math.Random(5));

  double seconds = 0;
  @override
  double get gameTime => seconds;
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

Future<Uint8List> _pixels(Size size, void Function(Canvas) draw) async {
  final image = await _image(size, draw);
  try {
    return (await image.toByteData())!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

int _differentPixels(Uint8List a, Uint8List b, {int tolerance = 2}) {
  var count = 0;
  for (var offset = 0; offset < a.length; offset += 4) {
    for (var channel = 0; channel < 4; channel++) {
      if ((a[offset + channel] - b[offset + channel]).abs() > tolerance) {
        count++;
        break;
      }
    }
  }
  return count;
}

void _label(Canvas canvas, String text, Offset at,
    {required Color color, required double size, double? width}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
          fontSize: size,
          height: 1.2,
          color: color),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width ?? double.infinity);
  painter.paint(canvas, at);
  painter.dispose();
}

void _gallery(Canvas canvas, Size size, double time) {
  canvas.save();
  canvas.scale(size.width / 1260, size.height / 1940);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 1260, 1940),
      Paint()..color = GameConstants.backgroundColor);
  _label(canvas, 'ATOMIC ORBITAL · LIVING WORLDS', const Offset(24, 27),
      color: const Color(0xFFE4EBE8), size: 30);
  for (var i = 0; i < GameSkin.values.length; i++) {
    final skin = GameSkin.values[i];
    final origin = Offset(24 + (i % 3) * 410.0, 100 + (i ~/ 3) * 456.0);
    const tileSize = Size(392, 438);
    final tile = RRect.fromRectAndRadius(
        Offset.zero & tileSize, const Radius.circular(18));
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.save();
    canvas.clipRRect(tile);
    WorldBackdrop(skin: skin, time: time).paint(canvas, tileSize);
    canvas.save();
    canvas.translate(24, 12);
    SkinPreview(skin: skin, hero: true, time: time)
        .paint(canvas, const Size(344, 344));
    canvas.restore();
    _label(canvas, skin.name, const Offset(22, 380),
        color: skin.accent, size: 24, width: 348);
    canvas.restore();
    canvas.drawRRect(
        tile,
        Paint()
          ..color = skin.accent.withValues(alpha: .2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    canvas.restore();
  }
  canvas.restore();
}

Future<void> _saveGallery(File file, Size size, double time) async {
  final image = await _image(size, (canvas) => _gallery(canvas, size, time));
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  } finally {
    image.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every themed core animates locally and loops after eight seconds',
      () async {
    for (final skin in GameSkin.values.skip(1)) {
      Future<Uint8List> frame(double time) => _pixels(
          const Size(128, 128),
          (canvas) =>
              skin.drawCore(canvas, const Offset(64, 64), 49, time: time));
      final still = await frame(0);
      expect(_differentPixels(still, await frame(1.3)), greaterThan(8),
          reason: '${skin.id} must visibly animate at phone core size');
      expect(_differentPixels(still, await frame(8)), lessThanOrEqualTo(12),
          reason: '${skin.id} must loop without a visible jump');
    }
  });

  test('animated cores and hazards retain circular bounds and core occlusion',
      () async {
    for (final skin in GameSkin.values.skip(1)) {
      for (final time in [1.3, 5.9]) {
        final pixels = await _pixels(const Size(176, 96), (canvas) {
          skin.drawCore(canvas, const Offset(48, 48), 36, time: time);
          skin.drawHazard(canvas, const Offset(136, 48), 22, time: time);
        });
        var outsideAlpha = 0;
        var coreAlpha = 255;
        var hazardPixels = 0;
        for (var y = 0; y < 96; y++) {
          for (var x = 0; x < 176; x++) {
            final at = Offset(x + .5, y + .5);
            final coreDistance = (at - const Offset(48, 48)).distance;
            final hazardDistance = (at - const Offset(136, 48)).distance;
            final alpha = pixels[(y * 176 + x) * 4 + 3];
            if (coreDistance > 37 && hazardDistance > 23) {
              outsideAlpha = math.max(outsideAlpha, alpha);
            }
            if (coreDistance < 34.5) coreAlpha = math.min(coreAlpha, alpha);
            if (hazardDistance < 22 && alpha > 0) hazardPixels++;
          }
        }
        expect(outsideAlpha, 0, reason: '${skin.id} bounds at $time seconds');
        expect(coreAlpha, 255,
            reason: '${skin.id} must still hide photons behind the core');
        expect(hazardPixels, greaterThan(100),
            reason: '${skin.id} hazard must remain visible');
      }
    }
  });

  test('reduced motion freezes world scenery and core animation in gameplay',
      () async {
    final engine = _VisualClockEngine()..startGame();
    addTearDown(engine.dispose);
    const size = Size(360, 598);
    for (final skin in GameSkin.values.skip(1)) {
      Future<Uint8List> frame(bool reduceMotion) => _pixels(
          size,
          (canvas) => GamePainter(engine,
                  skin: skin, devicePixelRatio: 3, reduceMotion: reduceMotion)
              .paint(canvas, size));
      engine.seconds = 0;
      final still = await frame(true);
      engine.seconds = 1.3;
      expect(_differentPixels(still, await frame(true), tolerance: 0), 0,
          reason: '${skin.id} must freeze decorative motion');
      expect(_differentPixels(still, await frame(false)), greaterThan(8),
          reason: '${skin.id} must animate when reduced motion is off');
    }
  });

  test('each world has its own dark opaque backdrop with a seamless loop',
      () async {
    final previous = <({GameSkin skin, Uint8List pixels})>[];
    const size = Size(160, 220);
    for (final skin in GameSkin.values) {
      final pixels = await _pixels(
          size, (canvas) => WorldBackdrop(skin: skin).paint(canvas, size));
      var brightness = 0;
      var minimumAlpha = 255;
      for (var i = 0; i < pixels.length; i += 4) {
        brightness += pixels[i] + pixels[i + 1] + pixels[i + 2];
        minimumAlpha = math.min(minimumAlpha, pixels[i + 3]);
      }
      expect(minimumAlpha, 255, reason: '${skin.id} backdrop opacity');
      final meanBrightness = brightness / (size.width * size.height * 3 * 255);
      expect(meanBrightness, lessThan(.2),
          reason: '${skin.id} backdrop must leave characters readable');
      for (final other in previous) {
        expect(_differentPixels(pixels, other.pixels), greaterThan(100),
            reason: '${skin.id} and ${other.skin.id} need distinct scenery');
      }
      final loop = await _pixels(size,
          (canvas) => WorldBackdrop(skin: skin, time: 8).paint(canvas, size));
      expect(_differentPixels(pixels, loop), 0,
          reason: '${skin.id} backdrop must loop seamlessly');
      previous.add((skin: skin, pixels: pixels));
    }
  });

  if (const bool.fromEnvironment('GENERATE_LIVING_WORLD_EVIDENCE')) {
    test('export every living world and an eight-second animation gallery',
        () async {
      await (FontLoader('Roboto')
            ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
            ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf')))
          .load();
      final directory = Directory('build/living-world-preview');
      await directory.create(recursive: true);
      await _saveGallery(
          File('${directory.path}/gallery.png'), const Size(1260, 1940), 1.3);
      for (var frame = 0; frame < 64; frame++) {
        await _saveGallery(
            File(
                '${directory.path}/frame-${frame.toString().padLeft(2, '0')}.png'),
            const Size(756, 1164),
            frame / 8);
      }
    });
  }
}
