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
  testWidgets('Game Center disconnect keeps offline play without Android toast',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final semantics = tester.ensureSemantics();
    final messenger = tester.binding.defaultBinaryMessenger;
    const gamesChannel = MethodChannel('atomic_orbital/play_games');
    const platform = MethodChannel('atomic_orbital/platform');
    final nativeActions = <String>[];
    try {
      SharedPreferences.setMockInitialValues({});
      await SettingsService.initialize();
      messenger.setMockMethodCallHandler(gamesChannel, (call) async {
        if (call.method == 'status' || call.method == 'signIn') {
          return {'authenticated': true, 'displayName': 'Pilot'};
        }
        if (call.method == 'loadAchievements') return <String>[];
        return null;
      });
      messenger.setMockMethodCallHandler(platform, (call) async {
        nativeActions.add(call.method);
        return null;
      });
      await PlayGamesService.instance.initialize();
      await tester.pumpWidget(MaterialApp(
          home: GameScreen(textCache: OriginalTextCache(enabled: false))));
      await tester.tap(find.byKey(const ValueKey('homeMenu')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.bySemanticsLabel('Disconnect Game Center'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(PlayGamesService.instance.authenticated, isFalse);
      expect(find.text('Playing offline'), findsOneWidget);
      expect(nativeActions, isNot(contains('playGamesDisconnected')));
      await tester.pumpWidget(const SizedBox());
    } finally {
      messenger.setMockMethodCallHandler(gamesChannel, null);
      messenger.setMockMethodCallHandler(platform, null);
      semantics.dispose();
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
