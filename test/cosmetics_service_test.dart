import 'dart:async';
import 'dart:convert';

import 'package:atomic_orbital/game/game_skin.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The existing preferences dependency exposes its testing store through this package.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

const _walletKey = 'flutter.cosmetics_wallet_v1';

class _Store extends InMemorySharedPreferencesStore {
  _Store() : super.empty();

  bool rejectWrite = false;
  bool throwWrite = false;
  bool rejectClear = false;
  bool failReads = false;
  Completer<void>? holdWrite;
  int walletWrites = 0;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == _walletKey) {
      walletWrites++;
      await holdWrite?.future;
      if (throwWrite) throw StateError('Disk write failed');
      if (rejectWrite) return false;
    }
    return super.setValue(valueType, key, value);
  }

  @override
  Future<Map<String, Object>> getAll() async {
    if (failReads) throw StateError('Disk read failed');
    return super.getAll();
  }

  @override
  Future<bool> clear() async => rejectClear ? false : await super.clear();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsService.instance;
  late _Store store;

  Future<Map<String, dynamic>> savedWallet() async =>
      jsonDecode((await store.getAll())[_walletKey]! as String)
          as Map<String, dynamic>;

  Future<void> restart() async {
    SharedPreferences.resetStatic();
    await SettingsService.initialize();
  }

  setUp(() async {
    store = _Store();
    SharedPreferencesStorePlatform.instance = store;
    await restart();
  });

  test('fresh wallets grant 100 once and preserve existing scores and stats',
      () async {
    expect(settings.stardust, 100);
    expect(settings.selectedSkin, GameSkin.classic);
    expect(settings.ownsSkin(GameSkin.classic), isTrue);
    expect(settings.ownsSkin(GameSkin.cowAbduction), isFalse);
    expect(settings.walletFailure, isNull);
    settings.setHighScore(42);
    settings.setHighScore(17, hardcore: true);
    settings.incrementGamesPlayed();
    settings.addTotalPoints(1000);
    settings.setMuted(false);

    await settings.earnStardust(50);
    expect(await settings.buySkin(GameSkin.cowAbduction), isTrue);
    expect(settings.stardust, 0);
    expect(settings.selectedSkin, GameSkin.cowAbduction);
    expect(settings.ownsSkin(GameSkin.cowAbduction), isTrue);
    await restart();
    expect(settings.stardust, 0);
    expect(settings.selectedSkin, GameSkin.cowAbduction);
    expect(settings.ownsSkin(GameSkin.cowAbduction), isTrue);
    expect(settings.highScore, 42);
    expect(settings.hardcoreHighScore, 17);
    expect(settings.gamesPlayed, 1);
    expect(settings.totalPoints, 1000);
    expect(settings.isMuted, isFalse);
    expect(store.walletWrites, 2);
  });

  for (final skin
      in GameSkin.values.where((skin) => skin != GameSkin.classic)) {
    test('${skin.id} unlocks once and stays equipped after restart', () async {
      await settings.earnStardust(skin.price - settings.stardust);
      expect(await settings.buySkin(skin), isTrue);
      expect(settings.stardust, 0);
      await restart();
      expect(settings.ownsSkin(skin), isTrue);
      expect(settings.selectedSkin, skin);
      final writes = store.walletWrites;
      expect(await settings.buySkin(skin), isTrue);
      expect(settings.stardust, 0);
      expect(store.walletWrites, writes);
    });
  }

  test('zero earnings, insufficient funds and repeat purchases never deduct',
      () async {
    await settings.earnStardust(0);
    expect(await settings.buySkin(GameSkin.cowAbduction), isFalse);
    expect(settings.stardust, 100);
    expect(store.walletWrites, 0);
    await settings.earnStardust(50);
    expect(await settings.buySkin(GameSkin.cowAbduction), isTrue);
    expect(await settings.buySkin(GameSkin.cowAbduction), isTrue);
    expect(await settings.buySkin(GameSkin.classic), isTrue);
    expect(settings.stardust, 0);
    expect(store.walletWrites, 2);
    await expectLater(settings.earnStardust(-1), throwsArgumentError);
    await expectLater(
        settings.earnStardust(9007199254740992), throwsArgumentError);
    expect(settings.stardust, 0);
  });

  test(
      'rapid purchases and earning serialize without lost credit or double spend',
      () async {
    await settings.earnStardust(50);
    final results = await Future.wait([
      settings.buySkin(GameSkin.cowAbduction),
      settings.buySkin(GameSkin.cowAbduction),
    ]);
    expect(results, [true, true]);
    expect(settings.stardust, 0);
    expect(store.walletWrites, 2);

    final earn = settings.earnStardust(160);
    final purchase = settings.buySkin(GameSkin.deepBlue);
    final extraEarn = settings.earnStardust(10);
    await earn;
    expect(await purchase, isTrue);
    await extraEarn;
    expect(settings.stardust, 20);
    expect(settings.ownsSkin(GameSkin.deepBlue), isTrue);
    expect(settings.selectedSkin, GameSkin.deepBlue);
    final snapshot = await savedWallet();
    expect(snapshot['stardust'], 20);
    expect(
        snapshot['owned'],
        containsAll(
            ['classic', GameSkin.cowAbduction.id, GameSkin.deepBlue.id]));
    expect(snapshot['equipped'], GameSkin.deepBlue.id);
  });

  test('selection requires ownership and persists without charging again',
      () async {
    await expectLater(settings.selectSkin(GameSkin.deepBlue), throwsStateError);
    await settings.earnStardust(50);
    await settings.buySkin(GameSkin.cowAbduction);
    await settings.selectSkin(GameSkin.classic);
    expect(settings.selectedSkin, GameSkin.classic);
    await settings.selectSkin(GameSkin.cowAbduction);
    await restart();
    expect(settings.selectedSkin, GameSkin.cowAbduction);
    expect(settings.stardust, 0);
  });

  test('publishes balance and ownership only after saving succeeds', () async {
    await settings.earnStardust(50);
    store.holdWrite = Completer<void>();
    var notifications = 0;
    void changed() => notifications++;
    settings.addListener(changed);
    addTearDown(() => settings.removeListener(changed));
    final purchase = settings.buySkin(GameSkin.cowAbduction);
    await Future<void>.delayed(Duration.zero);
    expect(settings.stardust, 150);
    expect(settings.ownsSkin(GameSkin.cowAbduction), isFalse);
    expect(settings.selectedSkin, GameSkin.classic);
    expect(notifications, 0);
    store.holdWrite!.complete();
    expect(await purchase, isTrue);
    expect(settings.stardust, 0);
    expect(settings.ownsSkin(GameSkin.cowAbduction), isTrue);
    expect(notifications, 1);
  });

  for (final throwsWrite in [false, true]) {
    test('failed save ($throwsWrite) keeps the old wallet and queue recovers',
        () async {
      await settings.earnStardust(50);
      final before = await savedWallet();
      store
        ..rejectWrite = !throwsWrite
        ..throwWrite = throwsWrite;
      await expectLater(
          settings.buySkin(GameSkin.cowAbduction), throwsStateError);
      expect(settings.stardust, 150);
      expect(settings.ownsSkin(GameSkin.cowAbduction), isFalse);
      expect(settings.selectedSkin, GameSkin.classic);
      expect(await savedWallet(), before);
      await restart();
      expect(settings.stardust, 150);
      expect(settings.ownsSkin(GameSkin.cowAbduction), isFalse);
      store
        ..rejectWrite = false
        ..throwWrite = false;
      await settings.earnStardust(5);
      expect(await settings.buySkin(GameSkin.cowAbduction), isTrue);
      expect(settings.stardust, 5);
      expect(settings.walletFailure, isNull);
    });
  }

  test('bad saved wallets fail closed without replacing data or blocking play',
      () async {
    for (final invalid in <Object>[
      '{broken',
      12,
      jsonEncode({
        'version': 2,
        'stardust': 100,
        'owned': <String>[],
        'equipped': 'classic'
      }),
      jsonEncode({
        'version': 1,
        'stardust': -1,
        'owned': <String>[],
        'equipped': 'classic'
      }),
      jsonEncode({
        'version': 1,
        'stardust': 2.5,
        'owned': <String>[],
        'equipped': 'classic'
      }),
      jsonEncode({
        'version': 1,
        'stardust': 9007199254740992,
        'owned': <String>[],
        'equipped': 'classic'
      }),
      jsonEncode({
        'version': 1,
        'stardust': 100,
        'owned': [7],
        'equipped': 'classic'
      }),
    ]) {
      await store.setValue(
          invalid is int ? 'Int' : 'String', _walletKey, invalid);
      await restart();
      expect(settings.walletFailure, isNotNull);
      expect(settings.stardust, 0);
      expect(settings.selectedSkin, GameSkin.classic);
      await expectLater(settings.earnStardust(5), throwsStateError);
      await expectLater(
          settings.buySkin(GameSkin.cowAbduction), throwsStateError);
      expect((await store.getAll())[_walletKey], invalid);
      settings.setHighScore(42);
      expect(settings.highScore, 42);
    }
    await settings.resetSettings();
    expect(settings.walletFailure, isNull);
    expect(settings.stardust, 100);
    await settings.earnStardust(1);
    expect(settings.stardust, 101);
  });

  test('read failures preserve saved data and a later initialize can recover',
      () async {
    await settings.earnStardust(80);
    final saved = await savedWallet();
    store.failReads = true;
    await restart();
    expect(settings.walletFailure, isNotNull);
    await expectLater(settings.earnStardust(5), throwsStateError);
    store.failReads = false;
    expect(await savedWallet(), saved);
    await restart();
    expect(settings.walletFailure, isNull);
    expect(settings.stardust, 180);
  });

  test('unknown future skins remain owned while the equipped skin falls back',
      () async {
    await store.setValue(
        'String',
        _walletKey,
        jsonEncode({
          'version': 1,
          'stardust': 50,
          'owned': ['future_world'],
          'equipped': 'future_world',
        }));
    await restart();
    expect(settings.walletFailure, isNull);
    expect(settings.selectedSkin, GameSkin.classic);
    await settings.earnStardust(1);
    expect((await savedWallet())['owned'], contains('future_world'));
  });

  test('an unowned equipped world falls back without blocking the balance',
      () async {
    await store.setValue(
        'String',
        _walletKey,
        jsonEncode({
          'version': 1,
          'stardust': 50,
          'owned': <String>[],
          'equipped': GameSkin.cowAbduction.id,
        }));
    await restart();
    expect(settings.walletFailure, isNull);
    expect(settings.selectedSkin, GameSkin.classic);
    expect(settings.stardust, 50);
    expect(settings.ownsSkin(GameSkin.cowAbduction), isFalse);
    await settings.earnStardust(1);
    expect(settings.stardust, 51);
  });

  test('failed reset keeps the saved wallet and statistics', () async {
    settings.setHighScore(42);
    await settings.earnStardust(50);
    await settings.buySkin(GameSkin.cowAbduction);
    store.rejectClear = true;
    await expectLater(settings.resetSettings(), throwsStateError);
    expect(settings.stardust, 0);
    expect(settings.ownsSkin(GameSkin.cowAbduction), isTrue);
    expect(settings.highScore, 42);
    store.rejectClear = false;
    await settings.earnStardust(3);
    expect(settings.stardust, 3);
  });

  test(
      'reset serializes after pending mutations and clears ownership and stats',
      () async {
    settings.setHighScore(42);
    final earn = settings.earnStardust(50);
    final purchase = settings.buySkin(GameSkin.cowAbduction);
    final reset = settings.resetSettings();
    final freshEarn = settings.earnStardust(3);
    await earn;
    expect(await purchase, isTrue);
    await reset;
    await freshEarn;
    expect(settings.stardust, 103);
    expect(settings.selectedSkin, GameSkin.classic);
    expect(settings.ownsSkin(GameSkin.cowAbduction), isFalse);
    expect(settings.highScore, 0);
    await restart();
    expect(settings.stardust, 103);
  });
}
