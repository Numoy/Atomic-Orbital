import 'dart:convert';

import 'package:atomic_orbital/game/daily_challenge.dart';
import 'package:atomic_orbital/game/game_skin.dart';
import 'package:atomic_orbital/services/daily_challenge_service.dart';
import 'package:atomic_orbital/services/save_backup_service.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _BackupStore extends InMemorySharedPreferencesStore {
  _BackupStore() : super.empty();
  String? rejectKey;
  bool rejectRemoval = false;
  bool persistent = false;
  bool failReloadAfterRejection = false;
  bool _failNextRead = false;
  bool _reject(String key) {
    if (key != rejectKey) return false;
    _failNextRead = failReloadAfterRejection;
    if (!persistent) rejectKey = null;
    return true;
  }

  @override
  Future<bool> setValue(String type, String key, Object value) async =>
      !rejectRemoval && _reject(key)
          ? false
          : await super.setValue(type, key, value);
  @override
  Future<bool> remove(String key) async =>
      rejectRemoval && _reject(key) ? false : await super.remove(key);
  @override
  Future<Map<String, Object>> getAll() async {
    if (_failNextRead) {
      _failNextRead = false;
      throw StateError('Storage read failed');
    }
    return super.getAll();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final s = SettingsService.instance;
  final daily = DailyChallengeService.instance;
  final challenge = DailyChallenge.forDate(DateTime.utc(2026, 10, 25));
  late _BackupStore store;
  Future<void> restart() async {
    SharedPreferences.resetStatic();
    await SettingsService.initialize();
    await daily.initialize(reload: true);
  }

  Future<String> candidate() async {
    s.completeGame(score: 35, hardcore: false, seconds: 120);
    await s.earnStardust(200);
    await s.buySkin(GameSkin.deepBlue);
    s.setOption('language', 'de');
    await daily.recordResult(challenge, score: 9, seconds: 42);
    return s.exportSave();
  }

  setUp(() async {
    await s.flushProgress();
    store = _BackupStore();
    SharedPreferencesStorePlatform.instance = store;
    await restart();
  });

  test(
      'export materializes legacy records and mute without exporting platform identity',
      () async {
    await store.setValue('Int', 'flutter.high_score', 22);
    await store.setValue('Int', 'flutter.games_played', 7);
    await store.setValue('Boolean', 'flutter.is_muted', false);
    await store.setValue(
        'String', 'flutter.play_games_profile', 'owner-secret');
    await store.setValue(
        'String', 'flutter.play_games_pending', 'private-queue');
    await restart();
    final text = await s.exportSave();
    final value = SaveBackup.decode(text);
    expect(value['progress']['stats']['high_score'], 22);
    expect(value['progress']['stats']['games_played'], 7);
    expect(value['progress']['options']['muted'], isFalse);
    expect(text, isNot(contains('owner-secret')));
    expect(text, isNot(contains('private-queue')));
  });

  test(
      'replaces progress wallet and daily results; previous save restores without summing',
      () async {
    final incoming = await candidate();
    s.completeGame(score: 50, hardcore: true, seconds: 60);
    await s.earnStardust(11);
    final before = await s.exportSave();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('play_games_profile', 'installation-owner');
    await prefs.setString('play_games_pending', 'installation-queue');
    await s.importSave(incoming);
    await s.importSave(incoming);
    expect(s.gamesPlayed, 1);
    expect(s.stardust, 150);
    expect(s.ownsSkin(GameSkin.deepBlue), isTrue);
    expect(s.language, 'de');
    expect(daily.bestFor(challenge), 9);
    expect(prefs.getString('play_games_profile'), 'installation-owner');
    expect(prefs.getString('play_games_pending'), 'installation-queue');
    await s.importSave(before);
    await s.restorePreviousSave();
    expect(s.gamesPlayed, 1);
    await s.restorePreviousSave();
    expect(s.gamesPlayed, 2);
    expect(s.hardcoreHighScore, 50);
    expect(s.stardust, 161);
    await restart();
    expect(s.gamesPlayed, 2);
    expect(s.hardcoreHighScore, 50);
  });

  test(
      'empty imported stats mask legacy counters and missing options use defaults',
      () async {
    final value = SaveBackup.decode(await s.exportSave());
    await store.setValue('Int', 'flutter.high_score', 100);
    await store.setValue('Int', 'flutter.games_played', 150);
    await store.setValue('Boolean', 'flutter.is_muted', false);
    await restart();
    value['progress']['stats'] = <String, dynamic>{};
    value['progress']['options'] = <String, dynamic>{};
    await s.importSave(jsonEncode(value));
    await restart();
    expect(s.highScore, 0);
    expect(s.gamesPlayed, 0);
    expect(s.isMuted, isTrue);
  });

  test('preserves bounded future inventory IDs and unknown world counters',
      () async {
    final value = SaveBackup.decode(await s.exportSave());
    value['wallet']['owned'] = ['classic', 'future_world'];
    value['wallet']['equipped'] = 'future_world';
    value['progress']['worlds']['future_world'] = 7;
    await s.importSave(jsonEncode(value));
    final exported = SaveBackup.decode(await s.exportSave());
    expect(exported['wallet']['owned'], ['classic', 'future_world']);
    expect(exported['wallet']['equipped'], 'future_world');
    expect(exported['progress']['worlds']['future_world'], 7);
  });

  test(
      'rejects unsupported versions, wrong types, negative and oversized values before writing',
      () async {
    final original = await s.exportSave();
    final before = await store.getAll();
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (v) => v['version'] = 2,
      (v) => v['progress']['stats']['high_score'] = -1,
      (v) => v['progress']['stats']['high_score'] = 1.5,
      (v) => v['wallet']['stardust'] = 9007199254740992,
      (v) => v['wallet']['owned'] = [''],
      (v) => v['progress']['options']['muted'] = 'false',
      (v) => v['daily'] = '{bad',
      (v) => v['play_games_profile'] = 'foreign-owner',
    ]) {
      final value = jsonDecode(original) as Map<String, dynamic>;
      mutate(value);
      await expectLater(s.importSave(jsonEncode(value)), throwsFormatException);
      expect(await store.getAll(), before);
    }
    await expectLater(s.importSave(' ' * (SaveBackup.maximumBytes + 1)),
        throwsFormatException);
  });

  for (final key in [
    'save_import_journal_v1',
    'player_progress_v1',
    'cosmetics_wallet_v1',
    'daily_challenges_v1',
    'previous_save_v1'
  ]) {
    test(
        'write failure at $key rolls back every key and retains original memory and restart state',
        () async {
      final incoming = await candidate();
      s.completeGame(score: 51, hardcore: false, seconds: 3);
      await s.flushProgress();
      final before = await store.getAll();
      store.rejectKey = 'flutter.$key';
      await expectLater(s.importSave(incoming), throwsStateError);
      expect(await store.getAll(), before);
      expect(s.highScore, 51);
      expect(s.backupRecoveryFailed, isFalse);
      await restart();
      expect(s.highScore, 51);
    });
  }

  test('failed final journal removal rolls the whole replacement back',
      () async {
    final incoming = await candidate();
    s.completeGame(score: 51, hardcore: false, seconds: 3);
    await s.flushProgress();
    final before = await store.getAll();
    store.rejectKey = 'flutter.save_import_journal_v1';
    store.rejectRemoval = true;
    await expectLater(s.importSave(incoming), throwsStateError);
    expect(await store.getAll(), before);
    expect(s.highScore, 51);
    expect(s.backupRecoveryFailed, isFalse);
  });

  test('failed rollback blocks writes until restart can recover the journal',
      () async {
    final incoming = await candidate();
    s.completeGame(score: 51, hardcore: false, seconds: 3);
    await s.flushProgress();
    final before = await store.getAll();
    store.rejectKey = 'flutter.save_import_journal_v1';
    store.rejectRemoval = true;
    // Let journal creation succeed and fail only its commit removal.
    store.persistent = true;
    final prefs = await SharedPreferences.getInstance();
    store.rejectKey = null;
    await prefs.setString(
        'save_import_journal_v1',
        jsonEncode({
          'player_progress_v1': prefs.get('player_progress_v1'),
          'cosmetics_wallet_v1': prefs.get('cosmetics_wallet_v1'),
          'daily_challenges_v1': prefs.get('daily_challenges_v1'),
          'previous_save_v1': prefs.get('previous_save_v1'),
        }));
    await prefs.setString('player_progress_v1',
        jsonEncode(SaveBackup.decode(incoming)['progress']));
    store.rejectKey = 'flutter.save_import_journal_v1';
    await restart();
    expect(s.backupRecoveryFailed, isTrue);
    expect(s.highScore, 51);
    expect(s.progressFailure, isNotNull);
    final persisted = await store.getAll();
    s.completeGame(score: 80, hardcore: false, seconds: 1);
    await s.flushProgress();
    await expectLater(s.earnStardust(1), throwsStateError);
    expect(await store.getAll(), persisted);
    store.rejectKey = null;
    await restart();
    expect(s.backupRecoveryFailed, isFalse);
    expect(s.highScore, 51);
    expect(await store.getAll(), before);
  });

  test(
      'crash journal restores old progress wallet daily and previous snapshot on startup',
      () async {
    final incoming = await candidate();
    final prefs = await SharedPreferences.getInstance();
    final before = await store.getAll();
    await prefs.setString(
        'save_import_journal_v1',
        jsonEncode({
          'player_progress_v1': prefs.get('player_progress_v1'),
          'cosmetics_wallet_v1': prefs.get('cosmetics_wallet_v1'),
          'daily_challenges_v1': prefs.get('daily_challenges_v1'),
          'previous_save_v1': prefs.get('previous_save_v1'),
        }));
    await prefs.setString('player_progress_v1',
        jsonEncode(SaveBackup.decode(incoming)['progress']));
    await prefs.setString('cosmetics_wallet_v1', '{partial');
    await prefs.remove(DailyChallengeService.storageKey);
    await restart();
    expect(await store.getAll(), before);
    expect(s.stardust, 150);
    expect(daily.bestFor(challenge), 9);
  });

  test(
      'a failed reload after a write failure keeps original memory and blocks writes until recovery',
      () async {
    final incoming = await candidate();
    s.completeGame(score: 51, hardcore: false, seconds: 3);
    await s.flushProgress();
    store.rejectKey = 'flutter.player_progress_v1';
    store.failReloadAfterRejection = true;
    await expectLater(s.importSave(incoming), throwsStateError);
    expect(s.backupRecoveryFailed, isTrue);
    expect(s.highScore, 51);
    expect(s.progressFailure, isNotNull);
    expect((await store.getAll()).containsKey('flutter.save_import_journal_v1'),
        isTrue);
    await s.importSave(incoming);
    expect(s.backupRecoveryFailed, isFalse);
    expect(s.highScore, 35);
  });

  test(
      'valid import recovers corrupt progress wallet and daily with pending daily result',
      () async {
    final incoming = await candidate();
    await store.setValue(
        'String', 'flutter.player_progress_v1', '{bad-progress');
    await store.setValue(
        'String', 'flutter.cosmetics_wallet_v1', '{bad-wallet');
    await store.setValue('String', 'flutter.daily_challenges_v1', '{bad-daily');
    await restart();
    await expectLater(
        daily.recordResult(challenge, score: 1, seconds: 2), throwsStateError);
    await s.importSave(incoming);
    expect(s.highScore, 35);
    expect(s.stardust, 150);
    expect(daily.bestFor(challenge), 9);
    final previous = jsonDecode((await SharedPreferences.getInstance())
        .getString('previous_save_v1')!) as Map<String, dynamic>;
    expect(previous['raw']['player_progress_v1'], '{bad-progress');
    expect(previous['raw']['cosmetics_wallet_v1'], '{bad-wallet');
    expect(previous['raw']['daily_challenges_v1'], '{bad-daily');
  });
}
