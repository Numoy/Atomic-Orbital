import 'dart:io';
import 'dart:ui' as ui;

import 'package:atomic_orbital/constants/game_constants.dart';
import 'package:atomic_orbital/game/game_skin.dart';
import 'package:atomic_orbital/game/world_backdrop.dart';
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

  test('treasure chest has a connected roof, front and side at both sizes',
      () async {
    for (final radius in [16.0, 100.0]) {
      final image = await _image(const Size(256, 256), (canvas) {
        GameSkin.deepBlue.drawPickup(canvas, const Offset(128, 128), radius);
      });
      try {
        final pixels = (await image.toByteData())!;
        for (final surface in [
          const Offset(-.08, -.66),
          const Offset(-.1, -.5),
          const Offset(.05, .3),
          const Offset(.6, -.3),
          const Offset(.65, .1),
        ]) {
          final x = (128 + surface.dx * radius).floor();
          final y = (128 + surface.dy * radius).floor();
          expect(pixels.getUint8((y * 256 + x) * 4 + 3), 255,
              reason: 'Chest surface $surface must join at radius $radius');
        }
      } finally {
        image.dispose();
      }
    }
  });

  test('treasure chest gold outline stays clear of the circular pickup clip',
      () async {
    final image = await _image(const Size(256, 256), (canvas) {
      GameSkin.deepBlue.drawPickup(canvas, const Offset(128, 128), 100);
    });
    try {
      final pixels = (await image.toByteData())!;
      final edgePixels = <Offset>[];
      for (var y = 0; y < 256; y++) {
        for (var x = 0; x < 256; x++) {
          if ((Offset(x + .5, y + .5) - const Offset(128, 128)).distance > 99 &&
              pixels.getUint8((y * 256 + x) * 4 + 3) > 0) {
            edgePixels.add(Offset(x.toDouble(), y.toDouble()));
          }
        }
      }
      expect(edgePixels, isEmpty,
          reason: 'The chest corners must not be cut off by the pickup circle');
    } finally {
      image.dispose();
    }
  });

  if (const bool.fromEnvironment('GENERATE_TREASURE_CHEST_EVIDENCE')) {
    test('export complete treasure chest at preview and gameplay sizes',
        () async {
      await (FontLoader('Roboto')
            ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf')))
          .load();
      final labels = <TextPainter>[];
      addTearDown(() {
        for (final label in labels) {
          label.dispose();
        }
      });
      final image = await _image(const Size(1024, 560), (canvas) {
        canvas.drawRect(const Rect.fromLTWH(0, 0, 1024, 560),
            Paint()..color = GameConstants.backgroundColor);
        void label(String value, Offset at, double size) {
          final text = TextPainter(
              text: TextSpan(
                  text: value,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: size,
                      color: GameConstants.atomColor)),
              textDirection: TextDirection.ltr)
            ..layout();
          labels.add(text);
          text.paint(canvas, at);
        }

        canvas.save();
        canvas.translate(24, 24);
        canvas.clipRRect(RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, 440, 512), const Radius.circular(20)));
        const WorldBackdrop(skin: GameSkin.deepBlue)
            .paint(canvas, const Size(440, 512));
        canvas.translate(10, 30);
        const SkinPreview(skin: GameSkin.deepBlue, hero: true)
            .paint(canvas, const Size(420, 420));
        canvas.restore();
        label('Deep Blue', const Offset(48, 478), 28);
        label('Complete treasure chest', const Offset(530, 38), 26);
        GameSkin.deepBlue.drawPickup(canvas, const Offset(760, 225), 142);
        label('Shop pickup', const Offset(556, 395), 18);
        GameSkin.deepBlue.drawPickup(canvas, const Offset(614, 468), 35);
        label('Phone gameplay', const Offset(766, 395), 18);
        GameSkin.deepBlue.drawPickup(canvas, const Offset(835, 468), 16);
      });
      try {
        final directory = Directory('build/themed-orbits-preview');
        await directory.create(recursive: true);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${directory.path}/treasure-chest.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    });
  }
}
