import 'dart:math';

import 'package:atomic_orbital/game/game_engine.dart';
import 'package:atomic_orbital/game/game_screen.dart';
import 'package:atomic_orbital/game/menu_scene.dart';
import 'package:atomic_orbital/game/original_text.dart';
import 'package:atomic_orbital/game/progress_screen.dart';
import 'package:atomic_orbital/l10n/strings.dart';
import 'package:atomic_orbital/main.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _RecordingCache extends OriginalTextCache {
  _RecordingCache() : super(enabled: true);
  final texts = <String>[];

  @override
  Future<void> prepare(Iterable<OriginalTextSpec> specs,
      {bool pin = false}) async {
    texts.addAll(specs.map((spec) => spec.text));
  }
}

class _ProgressStore extends InMemorySharedPreferencesStore {
  _ProgressStore() : super.empty();
  bool rejectProgress = false;

  @override
  Future<bool> setValue(String type, String key, Object value) {
    if (rejectProgress && key == 'flutter.player_progress_v1') {
      return Future.value(false);
    }
    return super.setValue(type, key, value);
  }
}

Widget _host(Widget child, {String language = 'en', double textScale = 1}) =>
    MaterialApp(
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AtomicOrbitalApp.themeData,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(body: child),
    );

OrbitGameOver _result({required bool newBest, String? challengeDate}) =>
    OrbitGameOver(
      score: 43,
      best: 43,
      newBest: newBest,
      hardcore: false,
      muted: true,
      seconds: 65,
      challengeDate: challengeDate,
      onReplay: () {},
      onHome: () {},
      onToggleSound: () {},
      onShare: () {},
    );

void main() {
  final settings = SettingsService.instance;
  late _ProgressStore store;

  setUp(() async {
    await settings.flushProgress();
    store = _ProgressStore();
    SharedPreferencesStorePlatform.instance = store;
    SharedPreferences.resetStatic();
    await SettingsService.initialize();
  });

  for (final language in ['en', 'de']) {
    for (final daily in [false, true]) {
      testWidgets('$language ${daily ? 'daily' : 'ordinary'} results at 200%',
          (tester) async {
        tester.view
          ..physicalSize = const Size(256, 600)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final semantics = tester.ensureSemantics();
        try {
          for (final newBest in [false, true]) {
            await tester.pumpWidget(_host(
              _result(
                  newBest: newBest, challengeDate: daily ? '2026-10-25' : null),
              language: language,
              textScale: 2,
            ));
            expect(find.text(language == 'de' ? 'Zeit: 1:05' : 'Time: 1:05'),
                findsOneWidget);
            if (daily) {
              expect(
                  find.text(language == 'de'
                      ? 'Tägliche Herausforderung · 2026-10-25 · UTC'
                      : 'Daily challenge · 2026-10-25 · UTC'),
                  findsOneWidget);
            }
            final best = find.byKey(const ValueKey('resultBest'));
            await tester.ensureVisible(best);
            final expected = language == 'de'
                ? daily
                    ? '${newBest ? 'Neuer Tagesrekord' : 'Tagesrekord'}: 43'
                    : '${newBest ? 'Neuer persönlicher Rekord' : 'Persönlicher Rekord'}: 43'
                : daily
                    ? '${newBest ? 'New daily best' : 'Daily best'}: 43'
                    : '${newBest ? 'New personal best' : 'Personal best'}: 43';
            final announcement = tester.getSemantics(best);
            expect(announcement.label, expected);
            expect(announcement.flagsCollection.isLiveRegion, newBest);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
          }
        } finally {
          semantics.dispose();
        }
      });
    }

    testWidgets('$language unreadable saves explain recovery without Retry',
        (tester) async {
      await store.setValue('String', 'flutter.player_progress_v1', '{bad');
      SharedPreferences.resetStatic();
      await SettingsService.initialize();
      await tester.pumpWidget(_host(const SaveStatus(), language: language));
      expect(
          find.textContaining(language == 'de'
              ? 'Der ursprüngliche Spielstand bleibt erhalten.'
              : 'The original save is preserved.'),
          findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
      settings.completeGame(score: 7, hardcore: false, seconds: 65);
      await settings.flushProgress();
      expect((await store.getAll())['flutter.player_progress_v1'], '{bad');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('$language failed writes retain a working Retry action',
        (tester) async {
      store.rejectProgress = true;
      settings.completeGame(score: 7, hardcore: false, seconds: 65);
      await settings.flushProgress();
      await tester.pumpWidget(_host(const SaveStatus(), language: language));
      final retry = find.text(language == 'de' ? 'Erneut versuchen' : 'Retry');
      expect(retry, findsOneWidget);
      store.rejectProgress = false;
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(settings.progressFailure, isNull);
      expect(settings.progressPending, isFalse);
      expect(find.byType(TextButton), findsNothing);
      expect(
          (await store.getAll())['flutter.player_progress_v1'], isA<String>());
      expect(settings.gamesPlayed, 1);
      expect(settings.totalPoints, 7);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('language changes prepare native prompts without resetting a run',
      (tester) async {
    settings.setOption('language', 'en');
    settings.setHighScore(17);
    final cache = _RecordingCache();
    final engine = GameEngine(random: Random(1))..startGame();
    final screen = GameScreen(engine: engine, textCache: cache);
    await tester.pumpWidget(ValueListenableBuilder<String>(
      valueListenable: settings.languageListenable,
      builder: (context, language, child) => _host(screen, language: language),
    ));
    await tester.pump();
    final state = tester.state(find.byType(GameScreen));
    expect(cache.texts, contains('TOUCH TO START'));
    expect(engine.state, GameState.ready);
    settings.setOption('language', 'de');
    await tester.pump();
    await tester.pump();
    expect(cache.texts, contains('ZUM STARTEN TIPPEN'));
    expect(identical(tester.state(find.byType(GameScreen)), state), isTrue);
    expect(engine.state, GameState.ready);
    expect(settings.highScore, 17);
    expect(settings.gamesPlayed, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('real game-over screen receives completed run duration',
      (tester) async {
    final engine = GameEngine(random: Random(1))..startGame(hardcore: true);
    await tester.pumpWidget(_host(GameScreen(
      engine: engine,
      textCache: OriginalTextCache(enabled: false),
    )));
    engine.player.collision.isCollidable = false;
    engine.onTouchDown();
    for (var frame = 0; frame < 125; frame++) {
      engine.advanceFrame();
    }
    expect(engine.photons, isNotEmpty);
    engine.player.collision.isCollidable = true;
    engine.photons.last.position
        .setPosition(engine.player.position.position.copy());
    engine.advanceFrame();
    expect(engine.state, GameState.gameOver);
    await tester.pump();
    expect(find.text('Time: 0:02'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
