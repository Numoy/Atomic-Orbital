import 'dart:async';
import 'dart:convert';
import 'package:atomic_orbital/game/game_skin.dart';
import 'package:atomic_orbital/models/achievement.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _ProgressStore extends InMemorySharedPreferencesStore {
  _ProgressStore() : super.empty();
  bool reject = false;
  Completer<void>? hold;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == 'flutter.player_progress_v1') {
      await hold?.future;
      if (reject) return false;
    }
    return super.setValue(type, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final s = SettingsService.instance;
  late _ProgressStore store;
  OrbitalAchievement achievement(String id) =>
      OrbitalAchievement.all.singleWhere((a) => a.id == id);
  Future<void> restart() async {
    await s.flushProgress();
    SharedPreferences.resetStatic();
    await SettingsService.initialize();
  }

  setUp(() async {
    await s.flushProgress();
    store = _ProgressStore();
    SharedPreferencesStorePlatform.instance = store;
    SharedPreferences.resetStatic();
    await SettingsService.initialize();
  });

  test('catalog has eighteen unique goals and preserves twelve platform IDs',
      () {
    expect(OrbitalAchievement.all, hasLength(18));
    expect(OrbitalAchievement.all.map((a) => a.id).toSet(), hasLength(18));
    expect(
        OrbitalAchievement.all
            .take(12)
            .map((a) => a.googleId)
            .whereType<String>()
            .toSet(),
        hasLength(12));
  });

  test('old saves backfill only achievements proved by their counters',
      () async {
    await store.setValue('Int', 'flutter.high_score', 35);
    await store.setValue('Int', 'flutter.hardcore_high_score', 5);
    await store.setValue('Int', 'flutter.total_points', 1000);
    await store.setValue('Int', 'flutter.games_played', 150);
    SharedPreferences.resetStatic();
    await SettingsService.initialize();
    expect(s.achievementUnlocked(achievement('normal35')), isTrue);
    expect(s.achievementUnlocked(achievement('normal50')), isFalse);
    expect(s.achievementUnlocked(achievement('games150')), isTrue);
    expect(s.achievementUnlocked(achievement('points1000')), isTrue);
    expect(s.achievementUnlocked(achievement('hardcoreCadet')), isTrue);
    expect(s.achievementUnlocked(achievement('steadyHands')), isFalse);
    expect(s.achievementUnlocked(achievement('worldTour')), isFalse);
  });

  test('live goals persist without awarding currency or completed-run goals',
      () async {
    s.recordPickup(
        score: 4, hardcore: false, clean: true, skin: GameSkin.classic);
    expect(s.achievementUnlocked(achievement('findingOrbit')), isFalse);
    s.recordPickup(
        score: 5, hardcore: false, clean: true, skin: GameSkin.classic);
    s.recordPickup(
        score: 10, hardcore: false, clean: false, skin: GameSkin.classic);
    expect(s.achievementUnlocked(achievement('steadyHands')), isFalse);
    s.recordPickup(
        score: 10, hardcore: false, clean: true, skin: GameSkin.classic);
    s.recordPickup(
        score: 5, hardcore: true, clean: true, skin: GameSkin.deepBlue);
    await restart();
    expect(s.achievementUnlocked(achievement('firstContact')), isTrue);
    expect(s.achievementUnlocked(achievement('findingOrbit')), isTrue);
    expect(s.achievementUnlocked(achievement('steadyHands')), isTrue);
    expect(s.achievementUnlocked(achievement('hardcoreCadet')), isTrue);
    expect(s.gamesPlayed, 0);
    expect(s.totalPoints, 0);
    expect(s.highScore, 0);
    expect(s.stardust, 100);
  });

  test('world tour requires actual pickups in all original worlds', () async {
    for (final skin in [GameSkin.classic, GameSkin.deepBlue]) {
      s.recordPickup(score: 5, hardcore: false, clean: true, skin: skin);
    }
    expect(s.achievementProgress(achievement('worldTour')), 2);
    s.recordPickup(
        score: 4, hardcore: false, clean: true, skin: GameSkin.cowAbduction);
    expect(s.achievementUnlocked(achievement('worldTour')), isFalse);
    s.recordPickup(
        score: 5, hardcore: false, clean: true, skin: GameSkin.cowAbduction);
    await restart();
    expect(s.achievementUnlocked(achievement('worldTour')), isTrue);
  });

  test('completed run writes one coherent snapshot and records do not decrease',
      () async {
    s.completeGame(score: 35, hardcore: false, seconds: 42);
    s.completeGame(score: 2, hardcore: false, seconds: 8);
    s.completeGame(score: 5, hardcore: true, seconds: 4);
    await restart();
    expect(s.highScore, 35);
    expect(s.hardcoreHighScore, 5);
    expect(s.gamesPlayed, 3);
    expect(s.totalPoints, 42);
    expect(s.totalPlayTime, 54);
    expect(s.achievementUnlocked(achievement('normal35')), isTrue);
  });

  test(
      'failed progress save stays pending and retry does not duplicate counters',
      () async {
    store.reject = true;
    s.completeGame(score: 7, hardcore: false, seconds: 12);
    await s.flushProgress();
    expect(s.progressFailure, isNotNull);
    expect(s.progressPending, isTrue);
    expect((await store.getAll())['flutter.player_progress_v1'], isNull);
    store.reject = false;
    await s.flushProgress();
    expect(s.progressFailure, isNull);
    await restart();
    expect(s.gamesPlayed, 1);
    expect(s.totalPoints, 7);
    expect(s.totalPlayTime, 12);
  });

  test('changes during an in-flight save are written before flush completes',
      () async {
    store.hold = Completer<void>();
    s.completeGame(score: 5, hardcore: false, seconds: 4);
    final flush = s.flushProgress();
    s.completeGame(score: 10, hardcore: false, seconds: 8);
    s.setOption('language', 'de');
    expect(s.progressSaving.value, isTrue);
    store.hold!.complete();
    await flush;
    expect(s.progressSaving.value, isFalse);
    await restart();
    expect(s.gamesPlayed, 2);
    expect(s.totalPoints, 15);
    expect(s.language, 'de');
  });

  test('corrupt progress is preserved and cannot be overwritten by new play',
      () async {
    await store.setValue('String', 'flutter.player_progress_v1', '{bad');
    SharedPreferences.resetStatic();
    await SettingsService.initialize();
    s.completeGame(score: 3, hardcore: false, seconds: 4);
    await s.flushProgress();
    expect(s.progressFailure, isNotNull);
    expect((await store.getAll())['flutter.player_progress_v1'], '{bad');
  });

  test('malformed option values fail closed without changing the saved bytes',
      () async {
    final raw = jsonEncode({
      'version': 1,
      'stats': <String, int>{},
      'milestones': <String, int>{},
      'worlds': <String, int>{},
      'options': {'language': 'xx'}
    });
    await store.setValue('String', 'flutter.player_progress_v1', raw);
    SharedPreferences.resetStatic();
    await SettingsService.initialize();
    expect(s.progressFailure, isNotNull);
    expect((await store.getAll())['flutter.player_progress_v1'], raw);
    expect(() => s.setOption('language', 'xx'), throwsArgumentError);
  });

  test('platform unlocks merge monotonically without inventing statistics',
      () async {
    s.mergePlatformAchievements(
        ['CgkItOGapf0GEAIQDg', 'steadyHands', 'unknown']);
    s.mergePlatformAchievements([]);
    await restart();
    expect(s.achievementUnlocked(achievement('normal50')), isTrue);
    expect(s.achievementUnlocked(achievement('steadyHands')), isTrue);
    expect(s.highScore, 0);
    expect(s.gamesPlayed, 0);
  });

  test('gameplay changes do not rebuild the application locale', () async {
    var changes = 0;
    void changed() => changes++;
    s.languageListenable.addListener(changed);
    addTearDown(() => s.languageListenable.removeListener(changed));
    s.recordPickup(
        score: 1, hardcore: false, clean: true, skin: GameSkin.classic);
    await s.earnStardust(1);
    expect(changes, 0);
    s.setOption('language', 'de');
    expect(changes, 1);
    await restart();
    expect(s.languageListenable.value, 'de');
  });

  test('future world counters cannot complete the original three-world tour',
      () async {
    await store.setValue(
        'String',
        'flutter.player_progress_v1',
        jsonEncode({
          'version': 1,
          'stats': <String, int>{},
          'milestones': <String, int>{},
          'worlds': {'future1': 5, 'future2': 5, 'future3': 5},
          'options': <String, Object>{},
        }));
    SharedPreferences.resetStatic();
    await SettingsService.initialize();
    s.recordPickup(
        score: 1, hardcore: false, clean: true, skin: GameSkin.classic);
    expect(s.achievementProgress(achievement('worldTour')), 0);
  });
  test(
      'corrupt legacy counters show safe values and preserve the original save',
      () async {
    SharedPreferences.setMockInitialValues({'high_score': 'broken'});
    await SettingsService.initialize();
    expect(s.highScore, 0);
    expect(s.progressFailure, isNotNull);
    s.completeGame(score: 5, hardcore: false, seconds: 2);
    await s.flushProgress();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.get('high_score'), 'broken');
    expect(prefs.get('player_progress_v1'), isNull);
  });
}
