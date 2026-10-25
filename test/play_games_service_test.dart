import 'dart:async';
import 'dart:convert';

import 'package:atomic_orbital/services/play_games_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('atomic_orbital/play_games');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late PlayGamesService service;
  late List<MethodCall> calls;
  var authenticated = false;
  var acceptSignIn = true;
  var failUploads = false;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({});
    service = PlayGamesService();
    calls = [];
    authenticated = false;
    acceptSignIn = true;
    failUploads = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'signIn') authenticated = acceptSignIn;
      if (call.method == 'status' || call.method == 'signIn') {
        return {
          'authenticated': authenticated,
          if (authenticated) 'displayName': 'Player'
        };
      }
      if (failUploads &&
          (call.method == 'submitScore' ||
              call.method == 'unlockAchievement')) {
        throw PlatformException(
            code: 'play_games_7', message: 'Network unavailable.');
      }
      return null;
    });
  });

  tearDown(() {
    service.dispose();
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  Future<void> completed(
      {int score = 35, int previous = 0, int games = 1, int total = 35}) {
    return service.recordCompletedGame(
        score: score,
        hardcore: false,
        previousHighScore: previous,
        gamesPlayed: games,
        totalPoints: total);
  }

  test('fresh connected startup never submits unearned zero highscores',
      () async {
    authenticated = true;
    await service.initialize();
    expect(service.authenticated, isTrue);
    expect(service.pendingCount, 0);
    expect(calls.where((call) => call.method == 'submitScore'), isEmpty);
  });

  test(
      'persisted invalid scores do not block valid updates or erase local bests',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final saved = [
      {
        'method': 'submitScore',
        'arguments': {
          'leaderboardId': PlayGamesService.normalLeaderboard,
          'score': 0
        }
      },
      {
        'method': 'submitScore',
        'arguments': {
          'leaderboardId': PlayGamesService.normalLeaderboard,
          'score': 9007199254740992
        }
      },
      {
        'method': 'submitScore',
        'arguments': {
          'leaderboardId': PlayGamesService.hardcoreLeaderboard,
          'score': 9007199254740992
        }
      },
      {
        'method': 'submitScore',
        'arguments': {
          'leaderboardId': PlayGamesService.gamesLeaderboard,
          'score': 9
        }
      },
      {
        'method': 'unlockAchievement',
        'arguments': {'achievementId': 'CgkItOGapf0GEAIQCg'}
      },
    ];
    await prefs.setInt('high_score', 9007199254740992);
    await prefs.setInt('hardcore_high_score', 9007199254740992);
    await prefs.setString('play_games_pending', jsonEncode(saved));
    await service.initialize();
    expect(service.pendingCount, 2);
    expect(prefs.getInt('high_score'), 9007199254740992);
    expect(prefs.getInt('hardcore_high_score'), 9007199254740992);
    expect(
        prefs.getInt(
            'play_games_unsubmitted_${PlayGamesService.normalLeaderboard}'),
        9007199254740992);
    expect(
        prefs.getInt(
            'play_games_unsubmitted_${PlayGamesService.hardcoreLeaderboard}'),
        9007199254740992);
    expect(jsonDecode(prefs.getString('play_games_pending')!) as List,
        hasLength(2));
    await service.signIn();
    expect(service.pendingCount, 0);
    expect(service.lastError, contains('local high score is preserved'));
    final submitted =
        calls.where((call) => call.method == 'submitScore').toList();
    expect(submitted, hasLength(1));
    expect((submitted.single.arguments as Map)['score'], 9);
    expect(calls.any((call) => call.method == 'unlockAchievement'), isTrue);
  });

  test('a newly earned over-limit best is archived while valid rewards upload',
      () async {
    await service.initialize();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('high_score', 9007199254740992);
    await completed(
        score: 9007199254740992,
        previous: 200,
        games: 1,
        total: 9007199254740992);
    expect(service.pendingCount, 7);
    await service.signIn();
    expect(service.pendingCount, 0);
    expect(prefs.getInt('high_score'), 9007199254740992);
    expect(
        prefs.getInt(
            'play_games_unsubmitted_${PlayGamesService.normalLeaderboard}'),
        9007199254740992);
    expect(
        calls.where((call) =>
            call.method == 'submitScore' &&
            (call.arguments as Map)['leaderboardId'] ==
                PlayGamesService.normalLeaderboard),
        isEmpty);
    expect(calls.where((call) => call.method == 'unlockAchievement'),
        hasLength(6));
    expect(
        calls.any((call) =>
            call.method == 'submitScore' &&
            (call.arguments as Map)['leaderboardId'] ==
                PlayGamesService.gamesLeaderboard &&
            (call.arguments as Map)['score'] == 1),
        isTrue);
  });

  test('published cloud bounds accept exact endpoints without clamping scores',
      () {
    expect(
        PlayGamesService.cloudScoreAllowed(
            PlayGamesService.normalLeaderboard, 0),
        isFalse);
    expect(
        PlayGamesService.cloudScoreAllowed(
            PlayGamesService.normalLeaderboard, 1),
        isTrue);
    expect(
        PlayGamesService.cloudScoreAllowed(
            PlayGamesService.normalLeaderboard, 200),
        isTrue);
    expect(
        PlayGamesService.cloudScoreAllowed(
            PlayGamesService.normalLeaderboard, 9007199254740992),
        isFalse);
    expect(
        PlayGamesService.cloudScoreAllowed(
            PlayGamesService.hardcoreLeaderboard, 1),
        isTrue);
    expect(
        PlayGamesService.cloudScoreAllowed(
            PlayGamesService.hardcoreLeaderboard, 100),
        isTrue);
    expect(
        PlayGamesService.cloudScoreAllowed(
            PlayGamesService.hardcoreLeaderboard, 9007199254740992),
        isFalse);
    expect(
        PlayGamesService.cloudScoreAllowed(
            PlayGamesService.gamesLeaderboard, 0),
        isFalse);
    expect(
        PlayGamesService.cloudScoreAllowed(
            PlayGamesService.gamesLeaderboard, 1),
        isTrue);
    expect(
        PlayGamesService.cloudScoreAllowed(
            PlayGamesService.gamesLeaderboard, 1000000),
        isTrue);
  });

  test(
      'offline completion persists every earned event until real authentication',
      () async {
    await service.initialize();
    await completed();
    expect(service.authenticated, isFalse);
    expect(service.pendingCount, 4);
    expect(calls.where((c) => c.method == 'submitScore'), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('play_games_pending')!) as List,
        hasLength(4));
    expect(await service.signIn(), isTrue);
    expect(service.authenticated, isTrue);
    expect(service.displayName, 'Player');
    expect(service.pendingCount, 0);
    final scores = calls.where((c) => c.method == 'submitScore').toList();
    expect(scores.first.arguments, {
      'leaderboardId': PlayGamesService.normalLeaderboard,
      'score': 35,
    });
    expect(
        scores.any((c) =>
            (c.arguments as Map)['leaderboardId'] ==
                PlayGamesService.gamesLeaderboard &&
            (c.arguments as Map)['score'] == 1),
        isTrue);
  });

  test('cancelled sign-in keeps results pending and gameplay usable', () async {
    await service.initialize();
    await completed();
    acceptSignIn = false;
    expect(await service.showAchievements(), isFalse);
    expect(service.authenticated, isFalse);
    expect(service.pendingCount, 4);
    expect(calls.where((c) => c.method == 'showAchievements'), isEmpty);
    acceptSignIn = true;
    expect(await service.showAchievements(), isTrue);
    expect(service.pendingCount, 0);
    expect(calls.last.method, 'showAchievements');
  });

  test('server failure survives service recreation and retries after reconnect',
      () async {
    await service.initialize();
    await completed();
    failUploads = true;
    expect(await service.signIn(), isTrue);
    expect(service.lastError, 'Network unavailable.');
    expect(service.pendingCount, greaterThan(0));
    service.dispose();
    service = PlayGamesService();
    failUploads = false;
    await service.initialize();
    expect(service.authenticated, isTrue);
    expect(service.pendingCount, 0);
    expect(service.lastError, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('play_games_pending')!) as List, isEmpty);
  });

  test('pending events deduplicate and retain the best score', () async {
    await service.initialize();
    await completed();
    await completed(score: 50, previous: 35, games: 2, total: 85);
    await completed(score: 20, previous: 50, games: 3, total: 105);
    expect(service.pendingCount, 5);
    await service.signIn();
    final normal = calls.where((c) =>
        c.method == 'submitScore' &&
        (c.arguments as Map)['leaderboardId'] ==
            PlayGamesService.normalLeaderboard);
    expect(normal, hasLength(1));
    expect((normal.single.arguments as Map)['score'], 50);
    final games = calls.where((c) =>
        c.method == 'submitScore' &&
        (c.arguments as Map)['leaderboardId'] ==
            PlayGamesService.gamesLeaderboard);
    expect((games.single.arguments as Map)['score'], 3);
  });

  test('leaderboard UI opens the selected original mode after authentication',
      () async {
    await service.initialize();
    expect(await service.showLeaderboards(hardcore: true), isTrue);
    expect(calls.last.method, 'showLeaderboards');
    expect(calls.last.arguments,
        {'leaderboardId': PlayGamesService.hardcoreLeaderboard});
  });

  test('an in-flight older score cannot clear a newly earned higher score',
      () async {
    await service.initialize();
    await completed();
    final uploadStarted = Completer<void>();
    final finishOldUpload = Completer<void>();
    var held = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'signIn') return {'authenticated': true};
      if (call.method == 'submitScore' && !held) {
        held = true;
        uploadStarted.complete();
        await finishOldUpload.future;
      }
      return null;
    });
    final signingIn = service.signIn();
    await uploadStarted.future;
    final newer = completed(score: 50, previous: 35, games: 2, total: 85);
    await Future<void>.delayed(Duration.zero);
    finishOldUpload.complete();
    await Future.wait([signingIn, newer]);
    final scores = calls
        .where((c) =>
            c.method == 'submitScore' &&
            (c.arguments as Map)['leaderboardId'] ==
                PlayGamesService.normalLeaderboard)
        .map((c) => (c.arguments as Map)['score'])
        .toList();
    expect(scores, [35, 50]);
    expect(service.pendingCount, 0);
  });

  test(
      'disconnect persists and blocks startup/resume cloud calls until reconnect',
      () async {
    await service.initialize();
    await completed();
    await service.disconnect();
    expect(service.disconnected, isTrue);
    expect(service.authenticated, isFalse);
    final pending = service.pendingCount;
    service.dispose();
    service = PlayGamesService();
    authenticated = true;
    calls.clear();
    await service.initialize();
    await service.refreshAuthentication();
    await service.flushPending();
    expect(calls, isEmpty);
    expect(service.disconnected, isTrue);
    expect(service.authenticated, isFalse);
    expect(service.pendingCount, pending);
    await completed(score: 50, previous: 35, games: 2, total: 85);
    expect(calls, isEmpty);
    expect(await service.signIn(), isTrue);
    expect(service.disconnected, isFalse);
    expect(service.pendingCount, 0);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('play_games_disconnected'), isFalse);
  });

  test('cancelled reconnect retains the explicit disconnect preference',
      () async {
    await service.initialize();
    await service.disconnect();
    acceptSignIn = false;
    expect(await service.signIn(), isFalse);
    expect(service.disconnected, isTrue);
    calls.clear();
    authenticated = true;
    await service.refreshAuthentication();
    expect(calls, isEmpty);
    expect(service.authenticated, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('play_games_disconnected'), isTrue);
  });

  test('disconnect stops the next queued upload after an in-flight request',
      () async {
    await service.initialize();
    await completed();
    final started = Completer<void>();
    final finish = Completer<void>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'signIn') return {'authenticated': true};
      if (call.method == 'submitScore') {
        started.complete();
        await finish.future;
      }
      return null;
    });
    final signingIn = service.signIn();
    await started.future;
    await service.disconnect();
    finish.complete();
    await signingIn;
    expect(service.authenticated, isFalse);
    expect(service.disconnected, isTrue);
    expect(calls.where((call) => call.method == 'submitScore'), hasLength(1));
    expect(calls.where((call) => call.method == 'unlockAchievement'), isEmpty);
    expect(service.pendingCount, greaterThan(0));
  });

  test('unsupported platforms do not claim authentication or submit results',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await service.initialize();
    await completed();
    expect(service.authenticated, isFalse);
    expect(calls, isEmpty);
    expect(service.signIn(), throwsA(isA<PlatformException>()));
  });

  test('one corrupt saved event preserves and retries every valid event',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final valid = {
      'method': 'submitScore',
      'arguments': {
        'leaderboardId': PlayGamesService.normalLeaderboard,
        'score': 42,
      }
    };
    final raw = jsonEncode([
      valid,
      {'method': 'unknown'},
      {
        'method': 'unlockAchievement',
        'arguments': {'achievementId': 'CgkItOGapf0GEAIQCg'},
      }
    ]);
    await prefs.setString('play_games_pending', raw);
    await service.initialize();
    expect(service.pendingCount, 2);
    expect(service.lastError, contains('could not be read'));
    expect(prefs.getString('play_games_pending_unreadable'), raw);
    expect(await service.signIn(), isTrue);
    expect(service.pendingCount, 0);
    expect(
        calls.any((call) =>
            call.method == 'submitScore' &&
            (call.arguments as Map)['score'] == 42),
        isTrue);
    expect(
        calls.any((call) =>
            call.method == 'unlockAchievement' &&
            (call.arguments as Map)['achievementId'] == 'CgkItOGapf0GEAIQCg'),
        isTrue);
  });

  test('corrupted pending data is retained for recovery without crashing',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('play_games_pending', 'not json');
    await service.initialize();
    expect(prefs.getString('play_games_pending_unreadable'), 'not json');
    await completed();
    expect(service.pendingCount, 4);
  });
}
