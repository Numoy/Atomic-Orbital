import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:atomic_orbital/game/daily_challenge.dart';
import 'package:atomic_orbital/game/game_engine.dart';
import 'package:atomic_orbital/models/components.dart';
import 'package:atomic_orbital/services/daily_challenge_service.dart';
import 'package:atomic_orbital/services/play_games_service.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _DailyStore extends InMemorySharedPreferencesStore {
  _DailyStore() : super.empty();
  bool reject = false;
  Completer<void>? hold;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == 'flutter.${DailyChallengeService.storageKey}') {
      await hold?.future;
      if (reject) return false;
    }
    return super.setValue(type, key, value);
  }
}

class _CountingRandom implements Random {
  int calls = 0;
  @override
  int nextInt(int max) {
    calls++;
    return 0;
  }

  @override
  bool nextBool() {
    calls++;
    return true;
  }

  @override
  double nextDouble() {
    calls++;
    return 0;
  }
}

List<Object> _snapshot(GameEngine engine) => [
      engine.state,
      engine.gameTime,
      engine.score,
      engine.health,
      for (final entity in engine.entities)
        [entity.type, entity.position.position.x, entity.position.position.y],
      for (final orbit in engine.orbits) [orbit.radius, orbit.rotation],
    ];

void _stationary(GameEngine engine) {
  engine.onTouchUp();
  final player = engine.player.logic as PlayerLogicComponent;
  player
    ..speedOrbit = 0
    ..currentAngle = 0
    ..currentRadius = player.minRadius
    ..speedRadius = 0;
  player.positionPlayer(engine.player);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _DailyStore store;
  late DailyChallengeService daily;
  final challenge = DailyChallenge.forDate(DateTime.utc(2026, 10, 25));

  setUp(() async {
    await SettingsService.instance.flushProgress();
    store = _DailyStore();
    SharedPreferencesStorePlatform.instance = store;
    SharedPreferences.resetStatic();
    await SettingsService.initialize();
    daily = DailyChallengeService();
    await daily.initialize();
    await daily.flush();
  });
  tearDown(() => daily.dispose());

  testWidgets('an idle write queue can move from setup into the widget zone',
      (tester) async {
    await daily.flush();
    await daily.initialize(reload: true);
    await daily.recordResult(challenge, score: 3, seconds: 30);
    await daily.flush();
    expect(daily.bestFor(challenge), 3);
    expect(daily.pending, isFalse);
  });

  test('UTC identity includes date, rules and PRNG and stays fixed at midnight',
      () {
    final before =
        DailyChallenge.forDate(DateTime.parse('2026-10-26T01:59:59+02:00'));
    final after =
        DailyChallenge.forDate(DateTime.parse('2026-10-26T02:00:00+02:00'));
    expect(before.identity, '2026-10-25/rules-1/xorshift32-1');
    expect(after.identity, '2026-10-26/rules-1/xorshift32-1');
    expect(before.dateUtc, DateTime.utc(2026, 10, 25));
    expect(before.resetUtc, DateTime.utc(2026, 10, 26));
    expect(before.identity, '2026-10-25/rules-1/xorshift32-1');
    expect(DailyChallenge.forDate(DateTime.utc(2026, 12, 31)).resetUtc,
        DateTime.utc(2027));
  });

  test('Xorshift32 uses the specified known-answer word stream', () {
    final random = DailyChallengeRandom(1);
    expect(List.generate(5, (_) => random.nextInt(0x100000000)),
        [270369, 67634689, 2647435461, 307599695, 2398689233]);
    expect(() => DailyChallengeRandom(0), throwsRangeError);
    expect(() => random.nextInt(0), throwsRangeError);
    expect(() => random.nextInt(0x100000001), throwsRangeError);
    expect(random.nextDouble(), allOf(greaterThanOrEqualTo(0), lessThan(1)));
  });

  test('bounded PRNG rejects words outside an equal-size range', () {
    final random = DailyChallengeRandom(1);
    // Third word 2647435461 is rejected for max=2147483649; fourth is used.
    random.nextInt(0x100000000);
    random.nextInt(0x100000000);
    expect(random.nextInt(0x80000001), 307599695);
  });

  test('daily seed mapping has a fixed known-answer stream', () {
    final random = challenge.createRandom();
    expect(List.generate(5, (_) => random.nextInt(0x100000000)),
        [1621412750, 3279657956, 2968469255, 3069273216, 3594788784]);
    expect(DailyChallengeRandom(1).nextBool(), isTrue);
  });

  test(
      'daily fresh attempts replay the same simulation without normal progress',
      () async {
    final first = GameEngine(random: Random(7));
    final second = GameEngine(random: Random(400));
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    void start(GameEngine engine) {
      engine.startGame(random: challenge.createRandom(), recordProgress: false);
      engine.player.collision.isCollidable = false;
      engine.onTouchDown();
    }

    start(first);
    start(second);
    for (var frame = 0; frame < 720; frame++) {
      if (frame % 45 == 0) {
        if (frame % 90 == 0) {
          first.onTouchDown();
          second.onTouchDown();
        } else {
          first.onTouchUp();
          second.onTouchUp();
        }
      }
      first.advanceFrame();
      second.advanceFrame();
      expect(_snapshot(first), _snapshot(second));
    }
    final replay = _snapshot(first);
    start(first);
    for (var frame = 0; frame < 720; frame++) {
      if (frame % 45 == 0) {
        frame % 90 == 0 ? first.onTouchDown() : first.onTouchUp();
      }
      first.advanceFrame();
    }
    expect(_snapshot(first), replay);
    expect(SettingsService.instance.gamesPlayed, 0);
    expect(SettingsService.instance.unlockedCount, 0);
  });

  test('daily pickup and completed run leave normal data and cloud queue alone',
      () async {
    final settings = SettingsService.instance;
    final engine = GameEngine();
    addTearDown(engine.dispose);
    final queued = PlayGamesService.instance.pendingCount;
    engine.startGame(random: challenge.createRandom(), recordProgress: false);
    engine.onTouchDown();
    engine.advanceFrame();
    _stationary(engine);
    for (var score = 0; score < 10; score++) {
      (engine.energy.logic as EnergyLogicComponent)
        ..onOrbit = 0
        ..angle = 0;
      engine.advanceFrame();
    }
    (engine.energy.logic as EnergyLogicComponent).angle = 180;
    expect(engine.score, 10);
    for (var hit = 0; hit < 3; hit++) {
      while (engine.photons.isEmpty) {
        engine.advanceFrame();
      }
      final photon = engine.photons.first;
      (photon.logic as PhotonLogicComponent).growing = true;
      photon.position.setPosition(engine.player.position.position.copy());
      engine.advanceFrame();
    }
    expect(engine.state, GameState.gameOver);
    expect(engine.isNewHighScore, isFalse);
    expect(settings.highScore, 0);
    expect(settings.hardcoreHighScore, 0);
    expect(settings.gamesPlayed, 0);
    expect(settings.totalPoints, 0);
    expect(settings.totalPlayTime, 0);
    expect(settings.unlockedCount, 0);
    expect(settings.stardust, 100);
    expect(PlayGamesService.instance.pendingCount, queued);
    await daily.recordResult(challenge,
        score: engine.score, seconds: engine.gameTime.round());
    expect(daily.bestFor(challenge), 10);
  });

  test('ordinary start restores original RNG and progress setting after daily',
      () {
    final normalRandom = _CountingRandom();
    final engine = GameEngine(random: normalRandom);
    addTearDown(engine.dispose);
    final before = normalRandom.calls;
    engine.startGame(random: challenge.createRandom(), recordProgress: false);
    engine.onTouchDown();
    engine.advanceFrame();
    expect(normalRandom.calls, before);
    expect(engine.recordProgress, isFalse);
    engine.startGame();
    expect(normalRandom.calls, before + 2);
    expect(engine.recordProgress, isTrue);
    engine.onTouchDown();
    engine.advanceFrame();
    _stationary(engine);
    (engine.energy.logic as EnergyLogicComponent)
      ..onOrbit = 0
      ..angle = 0;
    engine.advanceFrame();
    expect(SettingsService.instance.unlockedCount, 1);
  });

  test('daily bests persist separately by frozen challenge identity', () async {
    final next = DailyChallenge.forDate(DateTime.utc(2026, 10, 26));
    await daily.recordResult(challenge, score: 8, seconds: 90);
    await daily.recordResult(next, score: 2, seconds: 30);
    await daily.recordResult(challenge, score: 3, seconds: 40);
    await daily.recordResult(challenge, score: 8, seconds: 120);
    final restarted = DailyChallengeService();
    addTearDown(restarted.dispose);
    await restarted.initialize();
    expect(restarted.bestFor(challenge), 8);
    expect(restarted.bestFor(next), 2);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.get('player_progress_v1'), isNull);
    final raw = prefs.getString(DailyChallengeService.storageKey)!;
    expect(() => DailyChallengeService.validateSnapshot(raw), returnsNormally);
    expect(raw, contains('"seconds":90'));
  });

  test('a failed save retains the best pending attempt and retries it',
      () async {
    await daily.recordResult(challenge, score: 4, seconds: 40);
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(DailyChallengeService.storageKey);
    store.reject = true;
    await expectLater(
        daily.recordResult(challenge, score: 9, seconds: 80), throwsStateError);
    expect(daily.bestFor(challenge), 9);
    expect(daily.pending, isTrue);
    expect(daily.failure, isNotNull);
    expect(prefs.getString(DailyChallengeService.storageKey), saved);
    await daily.initialize();
    expect(daily.bestFor(challenge), 9);
    store.reject = false;
    await daily.recordResult(challenge, score: 5, seconds: 50);
    expect(daily.bestFor(challenge), 9);
    expect(daily.pending, isFalse);
    expect(daily.failure, isNull);
    await daily.initialize(reload: true);
    expect(daily.bestFor(challenge), 9);
  });

  test('flush retries a rejected pending snapshot and drains queued saves',
      () async {
    store.reject = true;
    await expectLater(
        daily.recordResult(challenge, score: 7, seconds: 70), throwsStateError);
    await expectLater(daily.flush(), throwsStateError);
    store.reject = false;
    store.hold = Completer<void>();
    final flushing = daily.flush();
    await Future<void>.delayed(Duration.zero);
    expect(daily.pending, isTrue);
    store.hold!.complete();
    await flushing;
    expect(daily.pending, isFalse);
    await daily.initialize(reload: true);
    expect(daily.bestFor(challenge), 7);
  });

  test('concurrent attempts keep the greatest score', () async {
    store.hold = Completer<void>();
    final first = daily.recordResult(challenge, score: 9, seconds: 90);
    final second = daily.recordResult(challenge, score: 3, seconds: 30);
    store.hold!.complete();
    await Future.wait([first, second]);
    expect(daily.bestFor(challenge), 9);
    await daily.initialize(reload: true);
    expect(daily.bestFor(challenge), 9);
  });

  test('only the 30 most recently saved identities are retained', () async {
    for (var offset = 0; offset < 35; offset++) {
      await daily.recordResult(
          DailyChallenge.forDate(DateTime.utc(2026, 1, 1 + offset)),
          score: offset + 1,
          seconds: 10);
    }
    expect(daily.bestFor(DailyChallenge.forDate(DateTime.utc(2026))), 0);
    expect(daily.bestFor(DailyChallenge.forDate(DateTime.utc(2026, 1, 6))), 6);
    // A clock rollback must still retain the just-played date.
    await daily.recordResult(challenge, score: 5, seconds: 20);
    final old = DailyChallenge.forDate(DateTime.utc(2020));
    await daily.recordResult(old, score: 4, seconds: 20);
    await daily.initialize(reload: true);
    expect(daily.bestFor(old), 4);
    expect(daily.bestFor(challenge), 5);
  });

  test('invalid and unsupported saves are preserved and block writes',
      () async {
    final prefs = await SharedPreferences.getInstance();
    for (final raw in [
      'not json',
      jsonEncode({'version': 2, 'records': <String, Object>{}}),
      jsonEncode({
        'version': 1,
        'records': {
          '2026-02-31/rules-1/xorshift32-1': {'score': 1, 'seconds': 1}
        }
      }),
      jsonEncode({
        'version': 1,
        'records': {
          challenge.identity: {'score': -1, 'seconds': 1}
        }
      }),
      jsonEncode({
        'version': 1,
        'records': {
          challenge.identity: {'score': 1, 'seconds': 1.5}
        }
      }),
    ]) {
      await prefs.setString(DailyChallengeService.storageKey, raw);
      await daily.initialize(reload: true);
      expect(daily.failure, isNotNull);
      expect(daily.bestFor(challenge), 0);
      await expectLater(daily.recordResult(challenge, score: 9, seconds: 20),
          throwsStateError);
      expect(prefs.getString(DailyChallengeService.storageKey), raw);
      expect(() => DailyChallengeService.validateSnapshot(raw),
          throwsFormatException);
    }
    expect(() => DailyChallengeService.validateSnapshot(null), returnsNormally);
    expect(() => daily.recordResult(challenge, score: -1, seconds: 2),
        throwsArgumentError);
  });

  test('an import recovery journal prevents overwriting the daily snapshot',
      () async {
    await daily.recordResult(challenge, score: 3, seconds: 30);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(DailyChallengeService.storageKey);
    await prefs.setString('save_import_journal_v1', 'pending recovery');
    await expectLater(
        daily.recordResult(challenge, score: 8, seconds: 80), throwsStateError);
    expect(prefs.getString(DailyChallengeService.storageKey), raw);
    await prefs.remove('save_import_journal_v1');
    await daily.flush();
    expect(daily.bestFor(challenge), 8);
  });
}
