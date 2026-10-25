import 'dart:async';
import 'package:atomic_orbital/services/play_games_service.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel('atomic_orbital/play_games');
  late PlayGamesService games;
  late List<MethodCall> calls;
  var profile = 'original';
  var reject = false;
  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({});
    await SettingsService.initialize();
    games = PlayGamesService();
    calls = [];
    profile = 'original';
    reject = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'status' || call.method == 'signIn') {
        return {
          'authenticated': true,
          'playerId': profile,
          'displayName': profile
        };
      }
      if (call.method == 'loadAchievements') return <String>[];
      if (reject) throw PlatformException(code: 'network_error');
      return null;
    });
  });
  tearDown(() {
    games.dispose();
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test(
      'pending updates stay bound to the original profile after an account switch',
      () async {
    await games.initialize();
    reject = true;
    await games.recordCompletedGame(
        score: 5,
        hardcore: false,
        previousHighScore: 0,
        gamesPlayed: 1,
        totalPoints: 5);
    expect(games.pendingCount, 2);
    profile = 'other';
    reject = false;
    calls.clear();
    await games.refreshAuthentication();
    expect(games.authenticated, isFalse);
    expect(games.lastError, 'profile_changed');
    expect(games.pendingCount, 2);
    expect(calls.where((c) => c.method == 'submitScore'), isEmpty);
    profile = 'original';
    await games.refreshAuthentication();
    expect(games.pendingCount, 0);
    for (final call in calls.where((c) => c.method == 'submitScore')) {
      expect((call.arguments as Map<Object?, Object?>)['playerId'], 'original');
    }
  });

  test('iOS uses Game Center and can queue local milestones while offline',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(games.supported, isTrue);
    expect(games.providerName, 'Game Center');
    expect(
        PlayGamesService.cloudScoreAllowed(
            PlayGamesService.normalLeaderboard, 201),
        isTrue);
    await games.initialize();
    SettingsService.instance.mergePlatformAchievements(['firstContact']);
    await games.disconnect();
    calls.clear();
    await games.syncLocalAchievements();
    expect(games.pendingCount, 1);
    expect(calls, isEmpty);
    await games.signIn();
    expect(
        calls.where((c) => c.method == 'unlockAchievement').map(
            (c) => (c.arguments as Map<Object?, Object?>)['achievementId']),
        contains('CgkItOGapf0GEAIQFw'));
  });

  test('legacy score queues migrate to the replacement boards without clamping',
      () {
    final event = PlayGamesEvent.fromJson({
      'method': 'submitScore',
      'arguments': {
        'leaderboardId': PlayGamesService.legacyNormalLeaderboard,
        'score': 201
      },
    });
    expect(
        event.arguments['leaderboardId'], PlayGamesService.normalLeaderboard);
    expect(event.arguments['score'], 201);
    expect(
        PlayGamesService.cloudScoreAllowed(
            PlayGamesService.normalLeaderboard, 201),
        isTrue);
    expect(
        PlayGamesService.cloudScoreAllowed(
            PlayGamesService.hardcoreLeaderboard, 101),
        isTrue);
    expect(
        PlayGamesService.cloudScoreAllowed(
            PlayGamesService.legacyNormalLeaderboard, 201),
        isFalse);
    expect(
        PlayGamesService.cloudScoreAllowed(
            PlayGamesService.normalLeaderboard, PlayGamesService.maxCloudScore),
        isTrue);
    expect(
        PlayGamesService.cloudScoreAllowed(PlayGamesService.normalLeaderboard,
            PlayGamesService.maxCloudScore + 1),
        isFalse);
  });

  test(
      'earned scores above both legacy ceilings reach the new boards unchanged',
      () async {
    await games.initialize();
    await games.recordCompletedGame(
        score: 201,
        hardcore: false,
        previousHighScore: 0,
        gamesPlayed: 1,
        totalPoints: 201);
    await games.recordCompletedGame(
        score: 101,
        hardcore: true,
        previousHighScore: 0,
        gamesPlayed: 2,
        totalPoints: 302);
    final submitted = calls
        .where((c) => c.method == 'submitScore')
        .map((c) => c.arguments as Map<Object?, Object?>);
    expect(
        submitted.any((a) =>
            a['leaderboardId'] == PlayGamesService.normalLeaderboard &&
            a['score'] == 201),
        isTrue);
    expect(
        submitted.any((a) =>
            a['leaderboardId'] == PlayGamesService.hardcoreLeaderboard &&
            a['score'] == 101),
        isTrue);
  });

  test('a goal earned during an in-flight achievement sync is also reported',
      () async {
    await games.initialize();
    final started = Completer<void>();
    final finish = Completer<void>();
    var unlocked = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'unlockAchievement' && ++unlocked == 1) {
        started.complete();
        await finish.future;
      }
      return null;
    });
    SettingsService.instance.mergePlatformAchievements(['firstContact']);
    final first = games.syncLocalAchievements();
    await started.future;
    SettingsService.instance.mergePlatformAchievements(['findingOrbit']);
    final second = games.syncLocalAchievements();
    finish.complete();
    await Future.wait([first, second]);
    final ids = calls
        .where((c) => c.method == 'unlockAchievement')
        .map((c) => (c.arguments as Map<Object?, Object?>)['achievementId']);
    expect(ids, containsAll(['CgkItOGapf0GEAIQFw', 'CgkItOGapf0GEAIQFA']));
    expect(games.pendingCount, 0);
  });
}
