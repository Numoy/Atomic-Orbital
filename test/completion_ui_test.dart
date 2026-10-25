import 'package:atomic_orbital/game/practice_screen.dart';
import 'package:atomic_orbital/game/game_engine.dart';
import 'package:atomic_orbital/game/game_screen.dart';
import 'package:atomic_orbital/game/progress_screen.dart';
import 'package:atomic_orbital/game/settings_screen.dart';
import 'package:atomic_orbital/l10n/strings.dart';
import 'package:atomic_orbital/main.dart';
import 'package:atomic_orbital/models/components.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget home, {String language = 'en', double scale = 1}) =>
    MaterialApp(
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AtomicOrbitalApp.themeData,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: home,
    );

Future<void> _frames(WidgetTester tester, int count) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 17));
  }
}

GameEngine _practiceEngine(WidgetTester tester) => (tester
        .widget<CustomPaint>(find.byKey(const ValueKey('practiceArena')))
        .painter! as GamePainter)
    .gameEngine;

void main() {
  final s = SettingsService.instance;
  setUp(() async {
    await s.flushProgress();
    SharedPreferences.setMockInitialValues({});
    await SettingsService.initialize();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('atomic_orbital/platform'),
            (call) async => call.method == 'appInfo'
                ? {'version': '2.3.0', 'build': '44'}
                : null);
  });

  testWidgets(
      'local achievements and honest statistics are available without sign-in',
      (tester) async {
    s.completeGame(score: 5, hardcore: false, seconds: 120);
    await tester.pumpWidget(_app(const ProgressScreen()));
    await tester.pump();
    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('2 of 16 unlocked'), findsOneWidget);
    expect(find.text('First Contact'), findsOneWidget);
    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();
    expect(find.text('Completed runs'), findsOneWidget);
    expect(find.text('0 h 2 min'), findsOneWidget);
    expect(find.text('Worlds owned'), findsNothing);
  });

  testWidgets(
      'settings save independent sound controls and show native build version',
      (tester) async {
    await tester.pumpWidget(_app(SettingsScreen(onPractice: () {})));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Music'));
    await tester.pump();
    expect(s.musicEnabled, isFalse);
    expect(s.effectsEnabled, isTrue);
    await tester.scrollUntilVisible(find.text('Version 2.3.0 (44)'), 250);
    expect(find.text('Version 2.3.0 (44)'), findsOneWidget);
    await s.flushProgress();
    await tester.pumpWidget(const SizedBox());
    await SettingsService.initialize();
    expect(s.musicEnabled, isFalse);
  });

  testWidgets(
      'changing language updates the existing app and keeps its saved records',
      (tester) async {
    s.setHighScore(17);
    await tester.pumpWidget(const AtomicOrbitalApp());
    await tester.pump();
    expect(find.text('PLAY'), findsOneWidget);
    s.setOption('language', 'de');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('SPIELEN'), findsOneWidget);
    expect(find.text('Fortschritt'), findsOneWidget);
    expect(find.textContaining('Welten-Shop'), findsOneWidget);
    expect(s.highScore, 17);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'first Play opens skippable practice and skip starts the real ready screen',
      (tester) async {
    await tester.pumpWidget(const AtomicOrbitalApp());
    await tester.ensureVisible(find.byKey(const ValueKey('startRun')));
    await tester.tap(find.byKey(const ValueKey('startRun')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(PracticeScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('skipPractice')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(s.tutorialSeen, isTrue);
    expect(find.byKey(const ValueKey('gameViewport')), findsOneWidget);
    expect(s.gamesPlayed, 0);
    expect(s.totalPoints, 0);
    expect(s.stardust, 100);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('practice requires both controls and two real reversing pickups',
      (tester) async {
    await tester.pumpWidget(_app(const PracticeScreen()));
    final engine = _practiceEngine(tester);
    final player = engine.player.logic as PlayerLogicComponent;
    await _frames(tester, 120);
    expect(find.text('Hold anywhere'), findsOneWidget);
    expect(engine.score, 0);
    expect(engine.energy.collision.isCollidable, isTrue);
    expect((engine.energy.logic as EnergyLogicComponent).onOrbit, 1);
    // Instructions and empty space accept input too.
    final hold =
        await tester.startGesture(tester.getCenter(find.text('Hold anywhere')));
    await _frames(tester, 180);
    expect(engine.score, 1);
    expect(player.currentRadius, player.maxRadius);
    expect(player.direction, -1);
    expect(find.text('Now let go'), findsOneWidget);
    expect(find.text('Holding · moving out'), findsOneWidget);
    expect(find.byKey(const ValueKey('finishPractice')), findsNothing);
    await hold.up();
    await _frames(tester, 1);
    expect(find.text('Released · moving in'), findsOneWidget);
    await _frames(tester, 180);
    expect(engine.score, 2);
    expect(player.direction, 1);
    expect(find.text('GOT IT'), findsOneWidget);
    expect(engine.state, GameState.paused);
    expect(engine.photons, isEmpty);
    expect(s.unlockedCount, 0);
    expect(s.gamesPlayed, 0);
    expect(s.totalPoints, 0);
    expect(s.highScore, 0);
    expect(s.stardust, 100);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('home How to play reopens practice without starting a real run',
      (tester) async {
    s.setOption('tutorial', true);
    await tester.pumpWidget(const AtomicOrbitalApp());
    await tester.tap(find.byKey(const ValueKey('homeMenu')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('How to play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(PracticeScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('skipPractice')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('startRun')), findsOneWidget);
    expect(find.byKey(const ValueKey('gameViewport')), findsNothing);
    expect(s.gamesPlayed, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('practice accepts screen edges, safe areas, text and empty space',
      (tester) async {
    tester.view
      ..physicalSize = const Size(393, 852)
      ..devicePixelRatio = 1
      ..padding = const FakeViewPadding(top: 32, bottom: 24);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const PracticeScreen()));
    final player = _practiceEngine(tester).player.logic as PlayerLogicComponent;
    final points = [
      const Offset(2, 2),
      const Offset(196, 20),
      const Offset(2, 400),
      const Offset(391, 400),
      const Offset(196, 850),
      tester.getCenter(find.text('Hold anywhere')),
      tester.getCenter(find.byKey(const ValueKey('practiceArena'))),
      tester
          .getCenter(find.text("You don't need to tap the dot or the square.")),
    ];
    for (final point in points) {
      final hold = await tester.startGesture(point);
      expect(player.isTouching, isTrue, reason: 'Hold at $point');
      await _frames(tester, 1);
      expect(find.text('Holding · moving out'), findsOneWidget);
      await hold.up();
      expect(player.isTouching, isFalse, reason: 'Release at $point');
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an early release can be retried and mixed inputs stay held',
      (tester) async {
    await tester.pumpWidget(_app(const PracticeScreen()));
    final engine = _practiceEngine(tester);
    final player = engine.player.logic as PlayerLogicComponent;
    final point = tester.getCenter(find.text('Hold anywhere'));
    final early = await tester.startGesture(point);
    await _frames(tester, 3);
    await early.up();
    await _frames(tester, 180);
    expect(engine.score, 0);
    expect(find.text('Hold anywhere'), findsOneWidget);
    expect(find.text('Released · moving in'), findsOneWidget);

    final first = await tester.startGesture(point, pointer: 1);
    final second = await tester.startGesture(point, pointer: 2);
    await first.cancel();
    expect(player.isTouching, isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await second.up();
    expect(player.isTouching, isTrue);
    await _frames(tester, 180);
    expect(engine.score, 1);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    expect(player.isTouching, isFalse);
    await _frames(tester, 180);
    expect(engine.score, 2);
    expect(find.byKey(const ValueKey('finishPractice')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('finishing practice returns first Play to the real ready screen',
      (tester) async {
    await tester.pumpWidget(const AtomicOrbitalApp());
    await tester.ensureVisible(find.byKey(const ValueKey('startRun')));
    await tester.tap(find.byKey(const ValueKey('startRun')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final hold = await tester.startGesture(const Offset(8, 300));
    await _frames(tester, 180);
    await hold.up();
    await _frames(tester, 180);
    final route = ModalRoute.of(tester.element(find.byType(PracticeScreen)))!;
    await tester.tap(find.byKey(const ValueKey('finishPractice')));
    await tester.pump();
    await tester.pump(route.reverseTransitionDuration);
    await tester.pump(const Duration(milliseconds: 17));
    expect(s.tutorialSeen, isTrue);
    expect(find.byType(PracticeScreen), findsNothing);
    expect(find.byKey(const ValueKey('gameViewport')), findsOneWidget);
    expect(s.gamesPlayed, 0);
    expect(s.totalPoints, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('practice releases cancelled input and pauses in the background',
      (tester) async {
    await tester.pumpWidget(_app(const PracticeScreen()));
    final engine = _practiceEngine(tester);
    final player = engine.player.logic as PlayerLogicComponent;
    final arena = find.byKey(const ValueKey('practiceArena'));
    final hold = await tester.startGesture(tester.getCenter(arena));
    await _frames(tester, 3);
    expect(player.isTouching, isTrue);
    await hold.cancel();
    expect(player.isTouching, isFalse);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await _frames(tester, 3);
    expect(player.isTouching, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final beforePause = engine.gameTime;
    final angle = player.currentAngle;
    await tester.pump(const Duration(seconds: 30));
    expect(engine.state, GameState.paused);
    expect(player.isTouching, isFalse);
    expect(engine.gameTime, beforePause);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump(const Duration(seconds: 30));
    expect(player.currentAngle, angle);
    await _frames(tester, 1);
    expect(engine.gameTime, closeTo(beforePause + 1 / 60, .001));
    await tester.pumpWidget(const SizedBox());
  });

  for (final language in ['en', 'de']) {
    testWidgets('$language practice can be completed at 200% on a narrow phone',
        (tester) async {
      tester.view
        ..physicalSize = const Size(256, 600)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
          _app(const PracticeScreen(), language: language, scale: 2));
      final touchPoint =
          tester.getTopLeft(find.byType(PracticeScreen)) + const Offset(8, 300);
      final hold = await tester.startGesture(touchPoint);
      await _frames(tester, 180);
      expect(tester.takeException(), isNull);
      expect(_practiceEngine(tester).score, 1);
      await hold.up();
      await _frames(tester, 180);
      expect(tester.takeException(), isNull);
      expect(_practiceEngine(tester).score, 2);
      final finish = find.byKey(const ValueKey('finishPractice'));
      expect(finish.hitTestable(), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final language in ['en', 'de']) {
    for (final size in [
      const Size(256, 600),
      const Size(852, 393),
      const Size(768, 1024)
    ]) {
      testWidgets('$language new screens fit $size with large text',
          (tester) async {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        for (final screen in <Widget>[
          const ProgressScreen(),
          SettingsScreen(onPractice: () {}),
          const PracticeScreen()
        ]) {
          await tester.pumpWidget(_app(screen, language: language, scale: 2));
          await tester.pump();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        }
      });
    }
  }
}
