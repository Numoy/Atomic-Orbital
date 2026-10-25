import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:atomic_orbital/game/game_engine.dart';
import 'package:atomic_orbital/game/game_screen.dart';
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
  if (!const bool.fromEnvironment('GENERATE_GAME_EVIDENCE')) return;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.initialize();
    await (FontLoader('Roboto')
          ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf')))
        .load();
  });

  for (final name in [
    'ready',
    'normal',
    'hardcore',
    'hit',
    'tablet-landscape'
  ]) {
    testWidgets('render gameplay evidence $name', (tester) async {
      final tablet = name == 'tablet-landscape';
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = tablet ? const Size(1366, 1024) : const Size(393, 852)
        ..padding = tablet
            ? const FakeViewPadding(top: 24, bottom: 20)
            : const FakeViewPadding(top: 59, bottom: 34);
      addTearDown(tester.view.reset);
      final engine = GameEngine(random: Random(17))
        ..startGame(hardcore: name == 'hardcore');
      if (name == 'hit') {
        engine.player.collision.isCollidable = false;
        engine.onTouchDown();
        for (var frame = 0; frame < 102; frame++) {
          engine.advanceFrame();
        }
        engine.player.collision.isCollidable = true;
        engine.photons.last.position
            .setPosition(engine.player.position.position.copy());
        engine.advanceFrame();
        engine.advanceFrame();
        engine.photons.single.position.setPosition(Vector2D(300, 600));
        (engine.photons.single.logic as PhotonLogicComponent).radius = 15;
        engine.onTouchUp();
      } else if (name != 'ready') {
        // Isolated visual fixture: keep a populated field without a death or
        // persistent score write. Native checks use ordinary gameplay.
        engine.player.collision.isCollidable = false;
        engine.onTouchDown();
        for (var frame = 0; frame < 160; frame++) {
          engine.advanceFrame();
        }
        engine.onTouchUp();
        engine.player.collision.isCollidable = true;
      }
      const capture = ValueKey('gameVisualCapture');
      await tester.pumpWidget(RepaintBoundary(
        key: capture,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto'),
          home: GameScreen(
              engine: engine, textCache: OriginalTextCache(enabled: false)),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(capture));
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: tablet ? 1.5 : 3);
        try {
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('docs/evidence/game-visuals-2026-10-22');
          await directory.create(recursive: true);
          await File('${directory.path}/$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
        } finally {
          image.dispose();
        }
      });
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
