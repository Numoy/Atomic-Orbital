import 'package:atomic_orbital/game/game_screen.dart';
import 'package:atomic_orbital/game/original_text.dart';
import 'package:atomic_orbital/services/play_games_service.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
      'Play Games menu signs in, dispatches mode boards and respects disconnect',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final semantics = tester.ensureSemantics();
    try {
      tester.view
        ..physicalSize = const Size(1080, 1920)
        ..devicePixelRatio = 2.625
        ..padding = const FakeViewPadding(top: 63, bottom: 63);
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      await SettingsService.initialize();

      const playGames = MethodChannel('atomic_orbital/play_games');
      const platform = MethodChannel('atomic_orbital/platform');
      final messenger = tester.binding.defaultBinaryMessenger;
      final gameCalls = <MethodCall>[];
      final platformCalls = <MethodCall>[];
      var serverAuthenticated = false;
      var acceptSignIn = true;
      messenger.setMockMethodCallHandler(playGames, (call) async {
        gameCalls.add(call);
        if (call.method == 'signIn') serverAuthenticated = acceptSignIn;
        if (call.method == 'status' || call.method == 'signIn') {
          return {
            'authenticated': serverAuthenticated,
            if (serverAuthenticated) 'displayName': 'Test player',
          };
        }
        return null;
      });
      messenger.setMockMethodCallHandler(platform, (call) async {
        platformCalls.add(call);
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(playGames, null);
        messenger.setMockMethodCallHandler(platform, null);
      });
      final games = PlayGamesService.instance;
      await games.initialize();
      await tester.pumpWidget(MaterialApp(
          home: GameScreen(textCache: OriginalTextCache(enabled: false))));

      // Orbital artwork animates; pump bounded frames between interactions.
      Future<void> redraw() async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      }

      Future<void> tapControl(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await redraw();
      }

      Future<void> chooseAction(String label) async {
        await tapControl(find.byKey(const ValueKey('homeMenu')));
        await tapControl(find.bySemanticsLabel(label));
      }

      expect(games.authenticated, isFalse);
      await chooseAction('Sign in');
      expect(games.authenticated, isTrue);
      await tapControl(find.byKey(const ValueKey('homeMenu')));
      expect(find.bySemanticsLabel('Disconnect Play Games'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await redraw();

      await chooseAction('Leaderboard');
      await tapControl(find.byKey(const ValueKey('modeHardcore')));
      await chooseAction('Leaderboard');
      expect(
        gameCalls
            .where((call) => call.method == 'showLeaderboards')
            .map((call) => (call.arguments as Map)['leaderboardId']),
        [
          PlayGamesService.normalLeaderboard,
          PlayGamesService.hardcoreLeaderboard
        ],
      );

      await chooseAction('Disconnect Play Games');
      expect(games.authenticated, isFalse);
      expect(games.disconnected, isTrue);
      expect(platformCalls.single.method, 'playGamesDisconnected');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('play_games_disconnected'), isTrue);

      // PGS itself still has a session; app disconnect must block automatic calls.
      expect(serverAuthenticated, isTrue);
      final callsBeforeResume = gameCalls.length;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await redraw();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await redraw();
      expect(gameCalls, hasLength(callsBeforeResume));
      expect(games.authenticated, isFalse);
      await tapControl(find.byKey(const ValueKey('homeMenu')));
      expect(find.bySemanticsLabel('Sign in'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await redraw();

      acceptSignIn = false;
      for (final label in ['Sign in', 'Achievements', 'Leaderboard']) {
        await chooseAction(label);
        expect(games.authenticated, isFalse);
        expect(games.disconnected, isTrue);
        expect(prefs.getBool('play_games_disconnected'), isTrue);
        expect(
            find.text('Google Play Games sign-in did not complete. '
                'You can keep playing offline.'),
            findsOneWidget);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(seconds: 5));
        await tester.pump(const Duration(milliseconds: 400));
      }

      acceptSignIn = true;
      await chooseAction('Sign in');
      expect(games.authenticated, isTrue);
      expect(games.disconnected, isFalse);
      expect(prefs.getBool('play_games_disconnected'), isFalse);
      expect(gameCalls.where((call) => call.method == 'signIn'), hasLength(5));

      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      semantics.dispose();
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
