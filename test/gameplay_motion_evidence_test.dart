import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:atomic_orbital/game/game_engine.dart';
import 'package:atomic_orbital/game/game_screen.dart';
import 'package:atomic_orbital/game/game_skin.dart';
import 'package:atomic_orbital/game/original_text.dart';
import 'package:atomic_orbital/models/components.dart';
import 'package:atomic_orbital/models/vector2d.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  if (!const bool.fromEnvironment('GENERATE_GAMEPLAY_MOTION')) return;
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Roboto')
          ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  for (final skin in [GameSkin.cowAbduction, GameSkin.deepBlue]) {
    testWidgets('record ${skin.id} gameplay with real hold/release input',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'cosmetics_wallet_v1': jsonEncode({
          'version': 1,
          'stardust': 100,
          'owned': ['classic', 'cow_abduction', 'deep_blue'],
          'equipped': skin.id,
        }),
      });
      await tester.runAsync(SettingsService.initialize);
      tester.view
        ..physicalSize = const Size(393, 852)
        ..devicePixelRatio = 1
        ..padding = const FakeViewPadding(top: 59, bottom: 34);
      addTearDown(tester.view.reset);
      final engine = GameEngine(random: Random(17))..startGame();
      // A controlled first target makes the pickup/reversal reproducible.
      // Movement, later targets, hazards, collisions and damage run normally.
      (engine.energy.logic as EnergyLogicComponent)
        ..onOrbit = 0
        ..angle = 180;
      engine.energy.position.setPosition(Vector2D(540, 712));
      const capture = ValueKey('gameplayMotionCapture');
      await tester.pumpWidget(RepaintBoundary(
        key: capture,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark().copyWith(
              textTheme:
                  ThemeData.dark().textTheme.apply(fontFamily: 'Roboto')),
          home: GameScreen(
              engine: engine, textCache: OriginalTextCache(enabled: false)),
        ),
      ));
      await tester.pump();
      final frames = await tester.runAsync(
          () => Directory.systemTemp.createTemp('atomic-gameplay-motion-'));
      final output = Directory('docs/evidence/gameplay-feedback-2026-10-24');
      TestGesture? gesture;
      try {
        for (var frame = 0; frame < 100; frame++) {
          if ([4, 28, 56, 86].contains(frame)) {
            gesture = await tester.startGesture(
                tester.getCenter(find.byKey(const ValueKey('gameViewport'))));
          } else if ([5, 40, 68, 98].contains(frame)) {
            await gesture!.up();
            gesture = null;
          }
          await tester.pump(const Duration(milliseconds: 50));
          expect(tester.takeException(), isNull);
          final boundary =
              tester.renderObject<RenderRepaintBoundary>(find.byKey(capture));
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            try {
              final bytes =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              await File(
                      '${frames!.path}/frame-${frame.toString().padLeft(3, '0')}.png')
                  .writeAsBytes(bytes!.buffer.asUint8List());
              if ([0, 24, 60].contains(frame)) {
                await output.create(recursive: true);
                await File('${output.path}/${skin.id}-frame-$frame.png')
                    .writeAsBytes(bytes.buffer.asUint8List());
              }
            } finally {
              image.dispose();
            }
          });
        }
        expect(engine.score, greaterThanOrEqualTo(1),
            reason: 'The clip must include a real pickup and reversal');
        await tester.runAsync(() async {
          await output.create(recursive: true);
          final result = await Process.run('ffmpeg', [
            '-hide_banner',
            '-loglevel',
            'error',
            '-y',
            '-framerate',
            '20',
            '-i',
            '${frames!.path}/frame-%03d.png',
            '-filter_complex',
            '[0:v]split[a][b];[a]palettegen=max_colors=128:stats_mode=diff[p];'
                '[b][p]paletteuse=dither=sierra2_4a',
            '-loop',
            '0',
            '${output.path}/${skin.id}-gameplay.gif',
          ]);
          expect(result.exitCode, 0, reason: result.stderr.toString());
        });
      } finally {
        await gesture?.up();
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() => frames!.delete(recursive: true));
      }
    });
  }
}
