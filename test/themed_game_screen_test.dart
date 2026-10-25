import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:atomic_orbital/constants/game_constants.dart';
import 'package:atomic_orbital/game/game_engine.dart';
import 'package:atomic_orbital/game/game_screen.dart';
import 'package:atomic_orbital/game/game_skin.dart';
import 'package:atomic_orbital/game/gameplay_feedback.dart';
import 'package:atomic_orbital/models/components.dart';
import 'package:atomic_orbital/main.dart';
import 'package:atomic_orbital/l10n/strings.dart';
import 'package:atomic_orbital/game/original_text.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'cosmetics_wallet_v1': jsonEncode({
        'version': 1,
        'stardust': 100,
        'owned': GameSkin.values.map((skin) => skin.id).toList(),
        'equipped': 'cow_abduction',
      }),
    });
    await SettingsService.initialize();
  });

  setUpAll(() async {
    await (FontLoader('Roboto')
          ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf')))
        .load();
  });

  testWidgets('production app opens the world shop with the saved theme',
      (tester) async {
    SettingsService.instance.setOption('tutorial', true);
    await tester.pumpWidget(const AtomicOrbitalApp());
    await tester.pump();
    expect(tester.widget<GameScreen>(find.byType(GameScreen)).cosmeticsEnabled,
        isTrue);
    await tester.ensureVisible(find.byKey(const ValueKey('openShop')));
    await tester.tap(find.byKey(const ValueKey('openShop')));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('skinShop')), findsOneWidget);
    expect(find.byKey(const ValueKey('featuredWorld')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final language in ['en', 'de']) {
    test('$language names and explains every collectible world', () async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      final names = GameSkin.values.map((skin) => strings.worldName(skin.id));
      expect(names.toSet().length, GameSkin.values.length);
      for (final skin in GameSkin.values) {
        expect(strings.worldDescription(skin.id),
            isNot('Choose your next world.'));
        expect(strings.worldDescription(skin.id),
            isNot('Wähle deine nächste Welt.'));
      }
    });
  }

  testWidgets(
      'every themed world starts immediately with scores above the character',
      (tester) async {
    addTearDown(tester.view.reset);
    for (final skin
        in GameSkin.values.where((skin) => skin != GameSkin.classic)) {
      for (final hardcore in [false, true]) {
        await tester.runAsync(() => SettingsService.instance.selectSkin(skin));
        final engine = GameEngine(random: Random(1))
          ..startGame(hardcore: hardcore);
        tester.view
          ..physicalSize = const Size(393, 852)
          ..devicePixelRatio = 1;
        await tester.pumpWidget(MaterialApp(
            home: GameScreen(
                cosmeticsEnabled: true,
                engine: engine,
                textCache: OriginalTextCache(enabled: false))));
        await tester.pump();
        expect(find.byKey(const ValueKey('gameViewport')), findsOneWidget);
        expect(engine.gameTime, 0);
        expect(tester.takeException(), isNull);

        final rendered = ui.PictureRecorder();
        GamePainter(engine, skin: skin)
            .paint(Canvas(rendered), const Size(1080, 1794));
        final expected = ui.PictureRecorder();
        skin.drawCore(Canvas(expected), const Offset(540, 928), 135);
        await tester.runAsync(() async {
          final picture = rendered.endRecording();
          final corePicture = expected.endRecording();
          final image = await picture.toImage(1080, 1794);
          final core = await corePicture.toImage(1080, 1794);
          try {
            final pixels = (await image.toByteData())!;
            final reference = (await core.toByteData())!;
            for (var y = 810; y < 1046; y++) {
              for (var x = 422; x < 658; x++) {
                if ((Offset(x + .5, y + .5) - const Offset(540, 928)).distance >
                    118) {
                  continue;
                }
                final index = (y * 1080 + x) * 4;
                expect(pixels.getUint32(index), reference.getUint32(index),
                    reason: 'The score must not cover the central character');
              }
            }
            var scoreInk = 0;
            for (var y = 100; y < 220; y++) {
              for (var x = 450; x < 630; x++) {
                final index = (y * 1080 + x) * 4;
                if (pixels.getUint8(index) ==
                        (GameConstants.atomColor.r * 255).round() &&
                    pixels.getUint8(index + 1) ==
                        (GameConstants.atomColor.g * 255).round()) {
                  scoreInk++;
                }
              }
            }
            expect(scoreInk, greaterThan(100));
          } finally {
            image.dispose();
            core.dispose();
            picture.dispose();
            corePicture.dispose();
          }
        });
        final gesture = await tester.startGesture(
            tester.getCenter(find.byKey(const ValueKey('gameViewport'))));
        await tester.pump(const Duration(milliseconds: 34));
        expect(engine.state, GameState.playing);
        expect(engine.gameTime, greaterThan(0));
        await gesture.up();
        expect(SettingsService.instance.stardust, 100);
        expect(SettingsService.instance.totalPoints, 0);
        await tester.pumpWidget(const SizedBox());
      }
    }
  });

  testWidgets('collect feedback uses the pickup location and banks only once',
      (tester) async {
    final engine = GameEngine(random: Random(1))..startGame();
    await tester.pumpWidget(MaterialApp(
        home: GameScreen(
            cosmeticsEnabled: true,
            engine: engine,
            textCache: OriginalTextCache(enabled: false))));
    await tester.pump();
    final player = engine.player.logic as PlayerLogicComponent;
    player
      ..speedOrbit = 0
      ..currentAngle = 0
      ..currentRadius = player.minRadius
      ..speedRadius = 0;
    player.positionPlayer(engine.player);
    (engine.energy.logic as EnergyLogicComponent)
      ..onOrbit = 0
      ..angle = 0;
    final pickup = Offset(
        engine.width / 2, (engine.height ~/ 2) + engine.orbits.first.radius);
    engine.onTouchDown();
    engine.advanceFrame();
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((widget) => widget.painter)
        .whereType<GamePainter>()
        .single;
    expect(painter.feedback!.collection!.position, pickup);
    expect(engine.score, 1);
    expect(SettingsService.instance.stardust, 101);
    expect(player.direction, -1);
    engine.pauseGame();
    final collection = painter.feedback!.collection;
    await tester.pump(const Duration(seconds: 1));
    expect(painter.feedback!.collection, collection);
    expect(SettingsService.instance.stardust, 101);
    await tester.pumpWidget(const SizedBox());
  });

  test(
      'feedback preserves Classic and respects reduced motion without engine writes',
      () async {
    final engine = GameEngine(random: Random(1))..startGame();
    engine.player.collision.isCollidable = false;
    final visual = GameplayFeedback()..sync(engine);
    engine.onTouchDown();
    for (var i = 0; i < 16; i++) {
      engine.advanceFrame();
      visual.sync(engine);
    }
    visual.collect(const Offset(500, 700), engine.gameTime);
    for (var i = 0; i < 3; i++) {
      engine.advanceFrame();
      visual.sync(engine);
    }
    final before = (
      engine.score,
      engine.health,
      engine.gameTime,
      engine.player.position.position.x,
      engine.player.position.position.y
    );
    Future<List<int>> render(GameSkin skin, bool motion, bool effects) async {
      final recorder = ui.PictureRecorder();
      GamePainter(engine,
              skin: skin,
              reduceMotion: !motion,
              feedback: effects ? visual : null)
          .paint(Canvas(recorder), const Size(1080, 1794));
      final picture = recorder.endRecording();
      final image = await picture.toImage(1080, 1794);
      try {
        return (await image.toByteData())!.buffer.asUint8List();
      } finally {
        image.dispose();
        picture.dispose();
      }
    }

    expect(await render(GameSkin.classic, true, true),
        await render(GameSkin.classic, true, false));
    expect(await render(GameSkin.cowAbduction, false, true),
        await render(GameSkin.cowAbduction, false, false));
    expect(await render(GameSkin.cowAbduction, true, true),
        isNot(await render(GameSkin.cowAbduction, true, false)));
    expect((
      engine.score,
      engine.health,
      engine.gameTime,
      engine.player.position.position.x,
      engine.player.position.position.y
    ), before);
    engine.dispose();
  });
}
