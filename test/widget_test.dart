import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:atomic_orbital/constants/game_constants.dart';
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

class _FailingTextCache extends OriginalTextCache {
  _FailingTextCache() : super(enabled: false);

  void fail() {
    failure = 'Test text failure';
    notifyListeners();
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.initialize();
    await (FontLoader('Roboto')
          ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  setUp(() async => SettingsService.instance.resetSettings());

  testWidgets('adaptive mode selection starts the same canonical game world',
      (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 1920)
      ..devicePixelRatio = 2.625
      ..padding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.reset);
    final engine = GameEngine(random: Random(1));
    await tester.pumpWidget(MaterialApp(home: GameScreen(engine: engine)));
    await tester.pump();

    expect(engine.width, 1080);
    expect(engine.height, 1857);
    expect(engine.state, GameState.menu);
    expect(find.byKey(const ValueKey('gameViewport')), findsNothing);
    await tester.ensureVisible(find.byKey(const ValueKey('modeHardcore')));
    await tester.tap(find.byKey(const ValueKey('modeHardcore')));
    await tester.pump();
    expect(engine.state, GameState.menu);
    await tester.ensureVisible(find.byKey(const ValueKey('startRun')));
    await tester.tap(find.byKey(const ValueKey('startRun')));
    await tester.pump();
    expect(engine.state, GameState.ready);
    expect(engine.hardcore, isTrue);
    expect(engine.player.size.radius, 30);
    expect(engine.atom.size.radius, 135);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'drag and second-finger release keep the hold; cancellation releases',
      (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 1920)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final engine = GameEngine(random: Random(1));
    await tester.pumpWidget(MaterialApp(home: GameScreen(engine: engine)));
    await tester.ensureVisible(find.byKey(const ValueKey('startRun')));
    await tester.tap(find.byKey(const ValueKey('startRun')));
    await tester.pump();
    final first = await tester.startGesture(const Offset(100, 100), pointer: 1);
    await tester.pump(const Duration(milliseconds: 34));
    final player = engine.player.logic as PlayerLogicComponent;
    expect(engine.state, GameState.playing);
    expect(player.isTouching, isTrue);
    final second =
        await tester.startGesture(const Offset(200, 100), pointer: 2);
    await first.moveBy(const Offset(100, 150));
    await second.up();
    await tester.pump(const Duration(milliseconds: 17));
    expect(player.isTouching, isTrue);
    expect(player.speedRadius, greaterThan(0));
    await first.cancel();
    await tester.pump(const Duration(milliseconds: 67));
    expect(player.isTouching, isFalse);
    expect(player.speedRadius, lessThan(0));
    await tester.pumpWidget(const SizedBox());
  });

  test('normal and hardcore records remain separate and never decrease', () {
    final settings = SettingsService.instance;
    expect(settings.isMuted, isTrue);
    settings.setHighScore(12);
    settings.setHighScore(4, hardcore: true);
    settings.setHighScore(3);
    expect(settings.highScore, 12);
    expect(settings.hardcoreHighScore, 4);
  });

  testWidgets(
      'interruptions freeze held input until the player explicitly resumes',
      (tester) async {
    final engine = GameEngine(random: Random(1));
    await tester.pumpWidget(MaterialApp(home: GameScreen(engine: engine)));
    await tester.ensureVisible(find.byKey(const ValueKey('startRun')));
    await tester.tap(find.byKey(const ValueKey('startRun')));
    await tester.pump();
    final gesture = await tester.startGesture(const Offset(100, 100));
    await tester.pump(const Duration(milliseconds: 34));
    final player = engine.player.logic as PlayerLogicComponent;
    expect(player.isTouching, isTrue);
    final before = engine.gameTime;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(engine.state, GameState.paused);
    expect(player.isTouching, isFalse);
    await tester.pump(const Duration(seconds: 20));
    expect(engine.gameTime, before);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(engine.state, GameState.paused);
    expect(find.text('PAUSED'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(engine.gameTime, before);
    await gesture.up();
    expect(player.isTouching, isFalse);
    await tester.tap(find.byKey(const ValueKey('resumeRun')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 17));
    expect(engine.state, GameState.playing);
    expect(engine.gameTime - before, lessThan(0.034));
    expect(player.isTouching, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('pause controls preserve a run and never count as gameplay input',
      (tester) async {
    tester.view
      ..physicalSize = const Size(393, 852)
      ..devicePixelRatio = 1
      ..padding = const FakeViewPadding(top: 59, bottom: 34);
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    try {
      final engine = GameEngine(random: Random(1));
      const capture = ValueKey('pauseCapture');
      await tester.pumpWidget(RepaintBoundary(
          key: capture,
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(fontFamily: 'Roboto'),
              home: GameScreen(engine: engine))));
      await tester.ensureVisible(find.byKey(const ValueKey('startRun')));
      await tester.tap(find.byKey(const ValueKey('startRun')));
      await tester.pump();
      final player = engine.player.logic as PlayerLogicComponent;
      final pause = find.byTooltip('Pause game');
      final press = await tester.startGesture(tester.getCenter(pause));
      await tester.pump(const Duration(milliseconds: 200));
      expect(engine.state, GameState.ready);
      expect(player.isTouching, isFalse);
      await press.up();
      await tester.pump();
      expect(engine.state, GameState.paused);
      expect(find.bySemanticsLabel('RESUME'), findsOneWidget);
      expect(
          find.bySemanticsLabel(RegExp('Hold to move outward')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('resumeRun')));
      await tester.pump();
      expect(engine.state, GameState.ready);
      expect(player.isTouching, isFalse);

      final hold = await tester.startGesture(const Offset(100, 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(engine.state, GameState.playing);
      expect(player.isTouching, isTrue);
      await tester.tap(pause);
      await tester.pump();
      expect(engine.state, GameState.paused);
      expect(player.isTouching, isFalse);
      if (const bool.fromEnvironment('GENERATE_PAUSE_EVIDENCE')) {
        final boundary =
            tester.renderObject<RenderRepaintBoundary>(find.byKey(capture));
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          try {
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            final directory = Directory('docs/evidence/pause-2026-10-23');
            await directory.create(recursive: true);
            await File('${directory.path}/paused.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
          } finally {
            image.dispose();
          }
        });
      }
      final before = engine.gameTime;
      final health = engine.health;
      final radius = player.currentRadius;
      final energy = engine.energy;
      await tester.pump(const Duration(seconds: 10));
      expect(engine.gameTime, before);
      expect(engine.health, health);
      expect(player.currentRadius, radius);
      await hold.up();
      await tester.tap(find.text('Sound off'));
      await tester.pump();
      expect(SettingsService.instance.isMuted, isFalse);
      expect(engine.state, GameState.paused);
      await tester.tap(find.byKey(const ValueKey('resumeRun')));
      await tester.pump();
      expect(engine.state, GameState.playing);
      expect(engine.energy, same(energy));
      expect(player.isTouching, isFalse);
      await tester.pump(const Duration(milliseconds: 17));
      expect(engine.gameTime - before, lessThan(0.034));
      await tester.tap(pause);
      await tester.pump();
      await tester.tap(find.text('End run'));
      await tester.pump();
      expect(engine.state, GameState.menu);
      expect(SettingsService.instance.gamesPlayed, 0);
      await tester.pumpWidget(const SizedBox());
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
      'ready and manually paused runs stay paused through interruptions',
      (tester) async {
    final engine = GameEngine(random: Random(1));
    await tester.pumpWidget(MaterialApp(home: GameScreen(engine: engine)));
    await tester.ensureVisible(find.byKey(const ValueKey('startRun')));
    await tester.tap(find.byKey(const ValueKey('startRun')));
    await tester.pump();
    for (final manual in [false, true]) {
      if (manual) {
        await tester.tap(find.byTooltip('Pause game'));
        await tester.pump();
      }
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      expect(engine.state, GameState.paused);
      await tester.pump(const Duration(seconds: 10));
      expect(engine.gameTime, 0);
      await tester.tap(find.byKey(const ValueKey('resumeRun')));
      await tester.pump();
      expect(engine.state, GameState.ready);
      expect((engine.player.logic as PlayerLogicComponent).isTouching, isFalse);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Escape, P and Android back pause without discarding the run',
      (tester) async {
    final engine = GameEngine(random: Random(1));
    await tester.pumpWidget(MaterialApp(home: GameScreen(engine: engine)));
    await tester.ensureVisible(find.byKey(const ValueKey('startRun')));
    await tester.tap(find.byKey(const ValueKey('startRun')));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump(const Duration(milliseconds: 34));
    final before = engine.gameTime;
    final player = engine.player.logic as PlayerLogicComponent;
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(engine.state, GameState.paused);
    expect(player.isTouching, isFalse);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.space);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(engine.state, GameState.paused);
    expect(engine.gameTime, before);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyP);
    await tester.pump();
    expect(engine.state, GameState.playing);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyP);
    expect(engine.state, GameState.playing);
    expect(player.isTouching, isFalse);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(engine.state, GameState.paused);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(engine.state, GameState.playing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(engine.state, GameState.playing);
    expect(player.isTouching, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('help dismissals preserve a paused run and keep input released',
      (tester) async {
    final engine = GameEngine(random: Random(1));
    await tester.pumpWidget(MaterialApp(home: GameScreen(engine: engine)));
    await tester.ensureVisible(find.byKey(const ValueKey('startRun')));
    await tester.tap(find.byKey(const ValueKey('startRun')));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump(const Duration(milliseconds: 34));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump();
    final before = engine.gameTime;
    final energy = engine.energy;
    final player = engine.player.logic as PlayerLogicComponent;
    for (final dismissal in ['button', 'back', 'escape']) {
      await tester.tap(find.byTooltip('How to play'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('HOW TO PLAY'), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
      expect(engine.gameTime, before);
      expect(engine.state, GameState.paused);
      expect(player.isTouching, isFalse);
      if (dismissal == 'button') {
        await tester.tap(find.byKey(const ValueKey('closeHelp')));
      } else if (dismissal == 'back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('HOW TO PLAY'), findsNothing);
      expect(engine.state, GameState.paused);
      expect(engine.energy, same(energy));
      expect(engine.gameTime, before);
      expect(player.isTouching, isFalse);
    }
    await tester.tap(find.byKey(const ValueKey('resumeRun')));
    await tester.pump();
    expect(engine.state, GameState.playing);
    expect(player.isTouching, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('text failure releases a held player and freezes the hidden run',
      (tester) async {
    final engine = GameEngine(random: Random(1));
    final textCache = _FailingTextCache();
    await tester.pumpWidget(
        MaterialApp(home: GameScreen(engine: engine, textCache: textCache)));
    await tester.ensureVisible(find.byKey(const ValueKey('startRun')));
    await tester.tap(find.byKey(const ValueKey('startRun')));
    await tester.pump();
    final gesture = await tester.startGesture(const Offset(100, 100));
    await tester.pump(const Duration(milliseconds: 34));
    final player = engine.player.logic as PlayerLogicComponent;
    expect(engine.state, GameState.playing);
    expect(player.isTouching, isTrue);
    final before = engine.gameTime;

    textCache.fail();
    await tester.pump();
    expect(player.isTouching, isFalse);
    expect(find.text('Game text could not be prepared.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(engine.gameTime, before);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 2));
    expect(engine.gameTime, before);
    await gesture.up();
    await tester.tap(find.text('Return to menu'));
    await tester.pump();
    expect(engine.state, GameState.menu);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'both redesigned death screens support sound, share, replay and home',
      (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 1920)
      ..devicePixelRatio = 2.625
      ..padding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.reset);
    final externalCalls = <MethodCall>[];
    const platform = MethodChannel('atomic_orbital/platform');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(platform,
        (call) async {
      externalCalls.add(call);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(platform, null));
    for (final hardcore in [false, true]) {
      final engine = GameEngine(random: Random(1));
      await tester.pumpWidget(MaterialApp(home: GameScreen(engine: engine)));
      if (hardcore) {
        await tester.ensureVisible(find.byKey(const ValueKey('modeHardcore')));
        await tester.tap(find.byKey(const ValueKey('modeHardcore')));
      }
      await tester.ensureVisible(find.byKey(const ValueKey('startRun')));
      await tester.tap(find.byKey(const ValueKey('startRun')));
      await tester.pump();
      expect(engine.state, GameState.ready);

      void collideWithPhoton() {
        if (engine.state == GameState.ready) {
          engine.onTouchDown();
          engine.advanceFrame();
          engine.onTouchUp();
        }
        for (var frame = 0; engine.photons.isEmpty && frame < 102; frame++) {
          engine.advanceFrame();
        }
        expect(engine.photons, isNotEmpty);
        engine.photons.first.position
            .setPosition(engine.player.position.position.copy());
        engine.advanceFrame();
      }

      void finishGame() {
        for (var hit = 0; hit < (hardcore ? 1 : 3); hit++) {
          collideWithPhoton();
        }
      }

      engine.onTouchDown();
      engine.advanceFrame();
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
      engine.advanceFrame();
      energy.angle = 180;
      expect(engine.score, 1);
      finishGame();
      await tester.pump();
      expect(engine.state, GameState.gameOver);
      expect(find.text('GAME OVER'), findsOneWidget);
      expect(find.text('NEW BEST!'), findsOneWidget);
      expect(find.text('COMING SOON'), findsNothing);
      expect(find.text('NO ADS'), findsNothing);
      expect(find.byKey(const ValueKey('gameViewport')), findsOneWidget);
      await tester.tap(find.byTooltip('Enable sound'));
      await tester.pump();
      expect(SettingsService.instance.isMuted, isFalse);
      await tester.tap(find.byTooltip('Mute sound'));
      await tester.pump();
      expect(SettingsService.instance.isMuted, isTrue);
      final resultMenu = find.byKey(const ValueKey('resultMenu'));
      await tester.ensureVisible(resultMenu);
      await tester.tap(resultMenu);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Share score'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(externalCalls.last.method, 'share');
      expect((externalCalls.last.arguments as Map)['score'], engine.score);

      await tester.ensureVisible(find.byKey(const ValueKey('replayRun')));
      await tester.tap(find.byKey(const ValueKey('replayRun')));
      await tester.pump();
      expect(engine.state, GameState.ready);
      expect(engine.hardcore, hardcore);
      expect(engine.isNewHighScore, isFalse);
      finishGame();
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('home')));
      await tester.tap(find.byKey(const ValueKey('home')));
      await tester.pump();
      expect(engine.state, GameState.menu);
      expect(find.byKey(const ValueKey('startRun')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });

  test('renderer retains surface clipping, colors, score and instruction ink',
      () async {
    final engine = GameEngine(random: Random(1), width: 1080, height: 1857);
    engine.startGame();
    // SurfaceView clips moving objects before they can touch the status bar.
    engine.player.position.setPosition(Vector2D(20, -20));
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const statusBlue = Color(0xFF023043);
    canvas.drawColor(statusBlue, BlendMode.src);
    canvas.save();
    canvas.translate(0, 63);
    GamePainter(engine).paint(canvas, const Size(1080, 1794));
    canvas.restore();
    final image = await recorder.endRecording().toImage(1080, 1857);
    final pixels = (await image.toByteData())!;
    Color pixel(int x, int y) {
      final offset = (y * 1080 + x) * 4;
      return Color.fromARGB(
          pixels.getUint8(offset + 3),
          pixels.getUint8(offset),
          pixels.getUint8(offset + 1),
          pixels.getUint8(offset + 2));
    }

    int countColor(Rect bounds, Color color, Color Function(int, int) at) {
      var count = 0;
      for (var y = bounds.top.toInt(); y < bounds.bottom; y++) {
        for (var x = bounds.left.toInt(); x < bounds.right; x++) {
          if (at(x, y) == color) count++;
        }
      }
      return count;
    }

    expect(pixel(20, 20), statusBlue);
    expect(pixel(20, 200), GameConstants.backgroundColor);
    expect(pixel(450, 991), GameConstants.atomColor);
    expect(pixel(100, 123), GameConstants.normalAccent);
    expect(pixel(540, 1342).computeLuminance(), greaterThan(.35));
    expect(pixel(540, 1383).computeLuminance(), lessThan(.1));
    expect(
        countColor(
            const Rect.fromLTRB(470, 920, 610, 1050), Colors.black, pixel),
        greaterThan(100));
    expect(
        countColor(const Rect.fromLTRB(300, 1650, 900, 1740),
            const Color.fromARGB(255, 251, 251, 251), pixel),
        greaterThan(1000));
    image.dispose();

    engine.startGame(hardcore: true);
    engine.onTouchDown();
    for (var frame = 0; engine.photons.isEmpty && frame < 102; frame++) {
      engine.advanceFrame();
    }
    engine.photons.first.position
        .setPosition(engine.player.position.position.copy());
    engine.advanceFrame();
    expect(engine.state, GameState.gameOver);
    final deathRecorder = ui.PictureRecorder();
    GamePainter(engine).paint(Canvas(deathRecorder), const Size(1080, 1794));
    final deathImage = await deathRecorder.endRecording().toImage(1080, 1794);
    final deathPixels = (await deathImage.toByteData())!;
    expect(
        countColor(const Rect.fromLTRB(50, 10, 240, 55), Colors.white, (x, y) {
          final offset = (y * 1080 + x) * 4;
          return Color.fromARGB(
              deathPixels.getUint8(offset + 3),
              deathPixels.getUint8(offset),
              deathPixels.getUint8(offset + 1),
              deathPixels.getUint8(offset + 2));
        }),
        0,
        reason: 'Production gameplay must not expose an FPS debug label');
    deathImage.dispose();
  });

  test('renderer preserves entity silhouettes and nucleus occlusion', () async {
    final engine = GameEngine(random: Random(1))..startGame();
    engine.onTouchDown();
    engine.advanceFrame();
    engine.player.position.setPosition(Vector2D(800, 1100));
    engine.energy.position.setPosition(Vector2D(800, 500));
    (engine.energy.logic as EnergyLogicComponent).rotation = 0;
    final photon = engine.photons.single;
    final logic = photon.logic as PhotonLogicComponent;
    photon.position.setPosition(Vector2D(300, 600));
    logic.radius = 15;
    Future<ui.Image> render() async {
      final recorder = ui.PictureRecorder();
      GamePainter(engine).paint(Canvas(recorder), const Size(1080, 1794));
      final picture = recorder.endRecording();
      try {
        return await picture.toImage(1080, 1794);
      } finally {
        picture.dispose();
      }
    }

    final image = await render();
    final pixels = (await image.toByteData())!;
    Color at(int x, int y) {
      final offset = (y * 1080 + x) * 4;
      return Color.fromARGB(
          pixels.getUint8(offset + 3),
          pixels.getUint8(offset),
          pixels.getUint8(offset + 1),
          pixels.getUint8(offset + 2));
    }

    expect(at(828, 1100), GameConstants.playerColor);
    expect(at(832, 1100), isNot(GameConstants.playerColor));
    expect(at(313, 600), GameConstants.photonColor);
    expect(at(317, 600), isNot(GameConstants.photonColor));
    expect(at(800, 458).computeLuminance(), greaterThan(.5));
    expect(at(800, 453).computeLuminance(), lessThan(.1));
    expect(at(800, 500).computeLuminance(), lessThan(.1),
        reason: 'The pickup must retain its hollow diamond silhouette');
    image.dispose();
    photon.position.setPosition(Vector2D(650, 928));
    logic.radius = 15;
    final covered = await render();
    final coveredPixels = (await covered.toByteData())!;
    const offset = (928 * 1080 + 650) * 4;
    expect([
      for (var i = 0; i < 4; i++) coveredPixels.getUint8(offset + i)
    ], [
      243,
      245,
      243,
      255
    ], reason: 'The same opaque nucleus must hide emerging hazards');
    covered.dispose();
    engine.dispose();
  });

  test('damage rail shows actual health and flash retains a clear hazard',
      () async {
    final engine = GameEngine(random: Random(1))..startGame();
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
    expect(engine.health, closeTo(55.1, .001));
    expect(engine.backgroundRed, 125);
    final photon = engine.photons.single;
    photon.position.setPosition(Vector2D(300, 600));
    (photon.logic as PhotonLogicComponent).radius = 15;
    final recorder = ui.PictureRecorder();
    GamePainter(engine).paint(Canvas(recorder), const Size(1080, 1794));
    final picture = recorder.endRecording();
    final image = await picture.toImage(1080, 1794);
    picture.dispose();
    final pixels = (await image.toByteData())!;
    List<int> at(int x, int y) {
      final offset = (y * 1080 + x) * 4;
      return [for (var i = 0; i < 4; i++) pixels.getUint8(offset + i)];
    }

    expect(at(100, 60), [155, 233, 239, 255]);
    expect(at(900, 60), isNot([155, 233, 239, 255]));
    expect(at(300, 600), [255, 79, 100, 255]);
    expect(at(20, 200)[0], greaterThan(120));
    expect(at(20, 200)[0], lessThan(135));
    image.dispose();
    engine.dispose();
  });
}
