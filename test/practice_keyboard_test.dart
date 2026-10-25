import 'package:atomic_orbital/game/game_engine.dart';
import 'package:atomic_orbital/game/game_screen.dart';
import 'package:atomic_orbital/game/practice_screen.dart';
import 'package:atomic_orbital/l10n/strings.dart';
import 'package:atomic_orbital/models/components.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _openPractice(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const PracticeScreen()),
          ),
          child: const Text('Open practice'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Open practice'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

GameEngine _engine(WidgetTester tester) => (tester
        .widget<CustomPaint>(find.byKey(const ValueKey('practiceArena')))
        .painter! as GamePainter)
    .gameEngine;

Future<void> _frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 17));
  }
}

Future<void> _completePractice(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
  await _frames(tester, 180);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
  await _frames(tester, 180);
  expect(_engine(tester).score, 2);
}

void main() {
  setUp(() async {
    await SettingsService.instance.flushProgress();
    SharedPreferences.setMockInitialValues({});
    await SettingsService.initialize();
  });

  for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
    final label = key == LogicalKeyboardKey.enter ? 'Enter' : 'Space';
    testWidgets('focused Skip activates with $label', (tester) async {
      await _openPractice(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(key);
      expect(SettingsService.instance.tutorialSeen, isTrue);
      await tester.pumpAndSettle();
      expect(find.byType(PracticeScreen), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('focused completion activates with $label', (tester) async {
      await _openPractice(tester);
      await _completePractice(tester);
      expect(find.text('GOT IT'), findsOneWidget);
      Focus.of(tester.element(find.text('GOT IT'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(key);
      expect(SettingsService.instance.tutorialSeen, isTrue);
      await tester.pumpAndSettle();
      expect(find.byType(PracticeScreen), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('multiple held keys release on Tab focus transfer',
      (tester) async {
    await _openPractice(tester);
    final player = _engine(tester).player.logic as PlayerLogicComponent;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    expect(player.isTouching, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(player.isTouching, isFalse);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    expect(find.byType(PracticeScreen), findsOneWidget);
    expect(player.isTouching, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('touching the lesson restores keyboard control after Tab',
      (tester) async {
    await _openPractice(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final player = _engine(tester).player.logic as PlayerLogicComponent;
    final touch = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('practiceArena'))));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await touch.up();
    expect(player.isTouching, isTrue);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    expect(player.isTouching, isFalse);
    expect(SettingsService.instance.tutorialSeen, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('resizing cancels a hold without completing the lesson',
      (tester) async {
    addTearDown(tester.view.reset);
    await _openPractice(tester);
    final player = _engine(tester).player.logic as PlayerLogicComponent;
    final touch = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('practiceArena'))));
    expect(player.isTouching, isTrue);
    tester.view.physicalSize = const Size(600, 800);
    await tester.pump();
    expect(player.isTouching, isFalse);
    await touch.up();
    expect(_engine(tester).score, 0);
    await tester.pumpWidget(const SizedBox());
  });
}
