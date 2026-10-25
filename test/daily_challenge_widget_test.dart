import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:atomic_orbital/game/daily_challenge.dart';
import 'package:atomic_orbital/game/game_engine.dart';
import 'package:atomic_orbital/game/game_screen.dart';
import 'package:atomic_orbital/game/original_text.dart';
import 'package:atomic_orbital/game/settings_screen.dart';
import 'package:atomic_orbital/l10n/strings.dart';
import 'package:atomic_orbital/main.dart';
import 'package:atomic_orbital/models/components.dart';
import 'package:atomic_orbital/services/daily_challenge_service.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _Store extends InMemorySharedPreferencesStore {
  _Store() : super.empty();
  bool rejectDaily = false;
  @override
  Future<bool> setValue(String type, String key, Object value) async =>
      rejectDaily && key == 'flutter.${DailyChallengeService.storageKey}'
          ? false
          : await super.setValue(type, key, value);
}

const _captureKey = ValueKey('dailyCapture');
Widget _app(GameEngine engine) => RepaintBoundary(
    key: _captureKey,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AtomicOrbitalApp.themeData,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: GameScreen(
          engine: engine, textCache: OriginalTextCache(enabled: false)),
    ));

Future<void> _transition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('GENERATE_IMPROVEMENT_EVIDENCE')) return;
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_captureKey));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('docs/evidence/improvements-2026-10-25/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

Future<void> _openDaily(WidgetTester tester, {bool capture = false}) async {
  await tester.ensureVisible(find.byKey(const ValueKey('homeMenu')));
  await tester.tap(find.byKey(const ValueKey('homeMenu')));
  await _transition(tester);
  await tester.tap(find.text('Daily challenge'));
  await _transition(tester);
  expect(find.byKey(const ValueKey('startDailyChallenge')), findsOneWidget);
  if (capture) await _capture(tester, 'daily-intro');
  await tester.tap(find.byKey(const ValueKey('startDailyChallenge')));
  await _transition(tester);
}

void _collect(GameEngine engine) {
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
  (engine.energy.logic as EnergyLogicComponent)
    ..onOrbit = 0
    ..angle = 0;
  engine.advanceFrame();
  engine.energy.collision.isCollidable = false;
}

void _finish(GameEngine engine) {
  for (var frame = 0;
      frame < 1200 && engine.state != GameState.gameOver;
      frame++) {
    if (engine.photons.isNotEmpty) {
      engine.photons.first.position
          .setPosition(engine.player.position.position.copy());
    }
    engine.advanceFrame();
  }
  expect(engine.state, GameState.gameOver);
}

void main() {
  final settings = SettingsService.instance;
  final daily = DailyChallengeService.instance;
  late _Store store;
  setUpAll(() async {
    await (FontLoader('Roboto')
          ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  setUp(() async {
    await settings.flushProgress();
    try {
      await daily.flush();
    } catch (_) {}
    store = _Store();
    SharedPreferencesStorePlatform.instance = store;
    SharedPreferences.resetStatic();
    await SettingsService.initialize();
    await daily.initialize(reload: true);
  });

  testWidgets(
      'daily menu starts Normal, records separately and replays the seed',
      (tester) async {
    settings.completeGame(score: 20, hardcore: false, seconds: 80);
    await settings.flushProgress();
    final before = await settings.exportSave();
    if (const bool.fromEnvironment('GENERATE_IMPROVEMENT_EVIDENCE')) {
      tester.view
        ..physicalSize = const Size(393, 852)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    final engine = GameEngine(random: Random(1));
    await tester.pumpWidget(_app(engine));
    await tester.ensureVisible(find.byKey(const ValueKey('modeHardcore')));
    await tester.tap(find.byKey(const ValueKey('modeHardcore')));
    await _openDaily(tester, capture: true);
    expect(engine.state, GameState.ready);
    expect(engine.hardcore, isFalse);
    final target = engine.energy.logic as EnergyLogicComponent;
    final initialTarget = (target.onOrbit, target.angle);
    _collect(engine);
    expect(engine.score, 1);
    _finish(engine);
    await _transition(tester);
    await tester.runAsync(daily.flush);
    final challenge = DailyChallenge.forDate(DateTime.now());
    expect(daily.bestFor(challenge), 1);
    expect(find.textContaining(challenge.date), findsOneWidget);
    expect(find.byKey(const ValueKey('runDuration')), findsOneWidget);
    await _capture(tester, 'daily-result');
    final after =
        jsonDecode(await settings.exportSave()) as Map<String, dynamic>;
    final previous = jsonDecode(before) as Map<String, dynamic>;
    expect(after['progress'], previous['progress']);
    expect(after['wallet'], previous['wallet']);
    await tester.tap(find.byKey(const ValueKey('resultMenu')));
    await _transition(tester);
    expect(find.text('Leaderboard'), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await _transition(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('replayRun')));
    await tester.tap(find.byKey(const ValueKey('replayRun')));
    await _transition(tester);
    final replayTarget = engine.energy.logic as EnergyLogicComponent;
    expect((replayTarget.onOrbit, replayTarget.angle), initialTarget);
    await tester.tap(find.byTooltip('Pause game'));
    await _transition(tester);
    expect(find.textContaining('Daily challenge'), findsOneWidget);
    expect(
        find.text(
            'Leaving now will not save a daily result. Finish the run to record it.'),
        findsOneWidget);
    await tester.tap(find.bySemanticsLabel('End run and return to menu'));
    await _transition(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('startRun')));
    await tester.tap(find.byKey(const ValueKey('startRun')));
    await _transition(tester);
    expect(engine.hardcore, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'failed daily save is visible and Retry preserves the highest result',
      (tester) async {
    final engine = GameEngine(random: Random(1));
    await tester.pumpWidget(_app(engine));
    await _openDaily(tester);
    store.rejectDaily = true;
    _collect(engine);
    _finish(engine);
    await _transition(tester);
    final challenge = DailyChallenge.forDate(DateTime.now());
    expect(daily.pending, isTrue);
    expect(daily.bestFor(challenge), 1);
    expect(
        find.text(
            'The daily result could not be saved. Retry before closing the game.'),
        findsOneWidget);
    store.rejectDaily = false;
    await tester.ensureVisible(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    await _transition(tester);
    expect(daily.pending, isFalse);
    expect(daily.failure, isNull);
    await tester.runAsync(() => daily.initialize(reload: true));
    expect(daily.bestFor(challenge), 1);
    expect(settings.gamesPlayed, 0);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'importing from a paused daily run returns home with the restored best',
      (tester) async {
    if (const bool.fromEnvironment('GENERATE_IMPROVEMENT_EVIDENCE')) {
      tester.view
        ..physicalSize = const Size(393, 852)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    final value =
        jsonDecode(await settings.exportSave()) as Map<String, dynamic>;
    final challenge = DailyChallenge.forDate(DateTime.now());
    value['daily'] = jsonEncode({
      'version': 1,
      'records': {
        challenge.identity: {'score': 50, 'seconds': 90}
      }
    });
    const platform = MethodChannel('atomic_orbital/platform');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(platform,
        (call) async {
      if (call.method == 'appInfo') return {'version': '2.3.0', 'build': '44'};
      if (call.method == 'importSave') return jsonEncode(value);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(platform, null));
    final engine = GameEngine(random: Random(1));
    await tester.pumpWidget(_app(engine));
    await _openDaily(tester);
    _collect(engine);
    await tester.pump();
    await tester.tap(find.byTooltip('Pause game'));
    await _transition(tester);
    await tester.tap(find.byTooltip('Settings'));
    await _transition(tester);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('importSave')), 250,
        scrollable: find
            .descendant(
                of: find.byType(SettingsScreen),
                matching: find.byType(Scrollable))
            .first);
    await tester.tap(find.byKey(const ValueKey('importSave')));
    await _transition(tester);
    expect(find.byKey(const ValueKey('confirmSaveImport')), findsOneWidget);
    await _capture(tester, 'backup-preview');
    await tester.tap(find.byKey(const ValueKey('confirmSaveImport')));
    await _transition(tester);
    expect(engine.state, GameState.menu);
    expect(find.byKey(const ValueKey('startRun')), findsOneWidget);
    expect(daily.bestFor(challenge), 50);
    expect(settings.gamesPlayed, 0);
    await tester.pumpWidget(const SizedBox());
  });
}
