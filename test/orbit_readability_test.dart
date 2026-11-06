import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:atomic_orbital/constants/game_constants.dart';
import 'package:atomic_orbital/game/game_skin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = 384;
const _center = Offset(192, 192);

Future<ByteData> _render(void Function(Canvas) draw) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(_size, _size);
  try {
    return (await image.toByteData())!;
  } finally {
    image.dispose();
    picture.dispose();
  }
}

double _pathBrightness(ByteData pixels, double radius) {
  var total = 0.0;
  for (var sample = 0; sample < 120; sample++) {
    final angle = (sample + .5) * math.pi * 2 / 120;
    var peak = 0.0;
    for (var offset = -5; offset <= 5; offset++) {
      final point = _center +
          Offset(math.cos(angle), math.sin(angle)) * (radius + offset);
      final index = (point.dy.floor() * _size + point.dx.floor()) * 4;
      final brightness = pixels.getUint8(index) * .2126 +
          pixels.getUint8(index + 1) * .7152 +
          pixels.getUint8(index + 2) * .0722;
      peak = math.max(peak, brightness);
    }
    total += peak;
  }
  return total / 120;
}

List<bool> _motifMask(ByteData pixels) => [
      for (var y = 180; y <= 204; y++)
        for (var x = 310; x <= 334; x++)
          pixels.getUint8((y * _size + x) * 4 + 3) >= 40,
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('active path stays brighter among five stone, lava and yarn paths',
      () async {
    const radii = [60.0, 85.0, 110.0, 135.0, 160.0];
    for (final skin in [
      GameSkin.dragonHoard,
      GameSkin.volcanoHop,
      GameSkin.cheeseChase,
    ]) {
      final pixels = await _render((canvas) {
        canvas.drawPaint(Paint()..color = GameConstants.backgroundColor);
        for (final radius in radii) {
          skin.drawOrbit(canvas, _center, radius, time: .37, strokeWidth: 1.75);
        }
        skin.drawOrbit(canvas, _center, 110,
            time: .37, strokeWidth: 1.75, active: true);
      });
      final active = _pathBrightness(pixels, 110);
      for (final radius in radii.where((radius) => radius != 110)) {
        final inactive = _pathBrightness(pixels, radius);
        expect(active, greaterThan(inactive * 1.35),
            reason:
                '${skin.id}: moving path $active, stationary $radius: $inactive');
      }
    }
  });

  test('flowers, broad leaves and wisps differ in silhouette as well as color',
      () async {
    final masks = <GameSkin, List<bool>>{};
    for (final skin in [
      GameSkin.sunflower,
      GameSkin.jungleJam,
      GameSkin.hauntedHarvest,
    ]) {
      masks[skin] = _motifMask(await _render((canvas) {
        skin.drawOrbit(canvas, _center, 130, strokeWidth: 2.5);
      }));
    }
    final skins = masks.keys.toList();
    for (var i = 0; i < skins.length; i++) {
      for (var j = i + 1; j < skins.length; j++) {
        final first = masks[skins[i]]!;
        final second = masks[skins[j]]!;
        var union = 0;
        var different = 0;
        for (var pixel = 0; pixel < first.length; pixel++) {
          if (first[pixel] || second[pixel]) union++;
          if (first[pixel] != second[pixel]) different++;
        }
        expect(union, greaterThan(15));
        expect(different / union, greaterThan(.2),
            reason:
                '${skins[i].id} and ${skins[j].id} need different material shapes');
      }
    }
  });

  test('mist moves within its ring and repeats the eight-second preview loop',
      () async {
    Future<ByteData> at(double time) => _render((canvas) {
          GameSkin.hauntedHarvest
              .drawOrbit(canvas, _center, 130, strokeWidth: 2.5, time: time);
        });
    final still = (await at(0)).buffer.asUint8List();
    expect((await at(8)).buffer.asUint8List(), orderedEquals(still));
    expect((await at(.7)).buffer.asUint8List(), isNot(orderedEquals(still)));
    final moving = await at(.7);
    for (var y = 0; y < _size; y++) {
      for (var x = 0; x < _size; x++) {
        final distance = (Offset(x + .5, y + .5) - _center).distance;
        if ((distance - 130).abs() > 11) {
          expect(moving.getUint8((y * _size + x) * 4 + 3), 0);
        }
      }
    }
  });
}
