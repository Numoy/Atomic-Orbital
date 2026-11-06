import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:atomic_orbital/game/game_skin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> _core(GameSkin skin,
    {double charge = 0, double fire = 0}) async {
  final recorder = ui.PictureRecorder();
  skin.drawCore(Canvas(recorder), const Offset(64, 64), 49,
      charge: charge, fire: fire);
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(128, 128);
    try {
      return (await image.toByteData())!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}

int _changedPixels(Uint8List a, Uint8List b) {
  var changed = 0;
  for (var i = 0; i < a.length; i += 4) {
    for (var channel = 0; channel < 4; channel++) {
      if ((a[i + channel] - b[i + channel]).abs() > 2) {
        changed++;
        break;
      }
    }
  }
  return changed;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all eleven characters visibly prepare and react to a released wave',
      () async {
    for (final skin in GameSkin.values.skip(1)) {
      final idle = await _core(skin);
      final charge = await _core(skin, charge: 1);
      final fire = await _core(skin, fire: 1);
      expect(_changedPixels(idle, charge), greaterThan(8),
          reason: '${skin.id} must visibly prepare at gameplay size');
      expect(_changedPixels(idle, fire), greaterThan(8),
          reason: '${skin.id} must visibly react to the released wave');
      expect(_changedPixels(charge, fire), greaterThan(8),
          reason: '${skin.id} preparation and release must read differently');
      expect(await _core(skin), orderedEquals(idle),
          reason: '${skin.id} must return to its unchanged idle pose');
    }
    expect(await _core(GameSkin.classic, charge: 1, fire: 1),
        orderedEquals(await _core(GameSkin.classic)));
  });

  test('reactions preserve opaque core cover and its original circular bounds',
      () async {
    for (final skin in GameSkin.values.skip(1)) {
      for (final reaction in [
        (charge: 1.0, fire: 0.0),
        (charge: 0.0, fire: 1.0),
        (charge: 1.0, fire: 1.0)
      ]) {
        final pixels =
            await _core(skin, charge: reaction.charge, fire: reaction.fire);
        var outsideAlpha = 0;
        var insideAlpha = 255;
        for (var y = 0; y < 128; y++) {
          for (var x = 0; x < 128; x++) {
            final distance =
                (Offset(x + .5, y + .5) - const Offset(64, 64)).distance;
            final alpha = pixels[(y * 128 + x) * 4 + 3];
            if (distance > 50) outsideAlpha = math.max(outsideAlpha, alpha);
            if (distance < 47) insideAlpha = math.min(insideAlpha, alpha);
          }
        }
        expect(outsideAlpha, 0,
            reason: '${skin.id} $reaction must stay inside the existing core');
        expect(insideAlpha, 255,
            reason: '${skin.id} $reaction must keep covered photons hidden');
      }
    }
  });

  test('public reaction strengths stay normalized', () async {
    expect(await _core(GameSkin.deepBlue, charge: -1, fire: -1),
        orderedEquals(await _core(GameSkin.deepBlue)));
    expect(await _core(GameSkin.volcanoHop, charge: 2, fire: 2),
        orderedEquals(await _core(GameSkin.volcanoHop, charge: 1, fire: 1)));
  });

  if (const bool.fromEnvironment('GENERATE_CORE_REACTION_EVIDENCE')) {
    test('export all core reactions at preview and phone sizes', () async {
      await (FontLoader('Roboto')
            ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
            ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf')))
          .load();
      final labels = <TextPainter>[];
      addTearDown(() {
        for (final label in labels) {
          label.dispose();
        }
      });
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 1320, 2188),
          Paint()..color = const Color(0xFF080D14));
      void label(String value, Offset at, double size,
          {Color color = const Color(0xFFE8EFEC), double width = 1280}) {
        final text = TextPainter(
            text: TextSpan(
                text: value,
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: size,
                    color: color,
                    fontWeight: FontWeight.w500,
                    height: 1.2)),
            textDirection: TextDirection.ltr)
          ..layout(maxWidth: width);
        labels.add(text);
        text.paint(canvas, at);
      }

      label('CORE REACTIONS', const Offset(24, 22), 30);
      label('Each pair shows the large preview and phone gameplay size.',
          const Offset(24, 66), 17,
          color: const Color(0xFF9AA6B5));
      final phases = [
        (name: 'Idle', charge: 0.0, fire: 0.0),
        (name: 'Preparing', charge: 1.0, fire: 0.0),
        (name: 'Released', charge: 0.0, fire: 1.0),
      ];
      for (var column = 0; column < phases.length; column++) {
        label(phases[column].name, Offset(298 + column * 350.0, 107), 22);
      }
      final worlds = GameSkin.values.skip(1).toList();
      for (var row = 0; row < worlds.length; row++) {
        final skin = worlds[row];
        final y = 220 + row * 184.0;
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(20, y - 82, 1280, 170),
                const Radius.circular(14)),
            Paint()..color = skin.accent.withValues(alpha: .035));
        label(skin.name, Offset(36, y - 13), 23,
            color: skin.accent, width: 202);
        for (var column = 0; column < phases.length; column++) {
          final phase = phases[column];
          final x = 246 + column * 350.0;
          skin.drawCore(canvas, Offset(x + 83, y), 75,
              charge: phase.charge, fire: phase.fire);
          skin.drawCore(canvas, Offset(x + 252, y), 49,
              charge: phase.charge, fire: phase.fire);
        }
      }
      final picture = recorder.endRecording();
      try {
        final image = await picture.toImage(1320, 2188);
        try {
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('build/reactive-worlds-preview');
          await directory.create(recursive: true);
          await File('${directory.path}/core-reactions.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
        } finally {
          image.dispose();
        }
      } finally {
        picture.dispose();
      }
    });
  }
}
