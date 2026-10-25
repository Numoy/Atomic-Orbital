import 'dart:async';

import 'package:atomic_orbital/game/settings_screen.dart';
import 'package:atomic_orbital/l10n/strings.dart';
import 'package:atomic_orbital/main.dart';
import 'package:atomic_orbital/services/save_backup_service.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final s = SettingsService.instance;
  var restored = 0;
  late String incoming;
  late List<MethodCall> calls;
  Future<Object?> Function(MethodCall)? picker;
  Widget app({String language = 'en', double scale = 1}) => MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AtomicOrbitalApp.themeData,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home:
            SettingsScreen(onPractice: () {}, onSaveRestored: () => restored++),
      );
  setUp(() async {
    await s.flushProgress();
    SharedPreferences.setMockInitialValues({});
    await SettingsService.initialize();
    s.setHighScore(17);
    incoming = await s.exportSave();
    s.setHighScore(22);
    await s.flushProgress();
    restored = 0;
    calls = [];
    picker = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SaveBackup.platform, (call) async {
      calls.add(call);
      if (call.method == 'appInfo') return {'version': '2.3.0', 'build': '44'};
      if (picker != null) return picker!(call);
      if (call.method == 'importSave') return incoming;
      if (call.method == 'exportSave') return true;
      return null;
    });
  });
  tearDown(() async {
    await s.flushProgress();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SaveBackup.platform, null);
  });

  testWidgets(
      'import previews replacement, cancel preserves save, confirmation can restore the previous save',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('importSave')), 250);
    await tester.tap(find.byKey(const ValueKey('importSave')));
    await tester.pumpAndSettle();
    expect(find.text('Restore this save?'), findsOneWidget,
        reason:
            'calls=$calls; texts=${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList()}');
    expect(find.textContaining('Current save: 22'), findsOneWidget);
    expect(find.textContaining('Selected save: 17'), findsOneWidget);
    expect(s.highScore, 22);
    expect(restored, 0);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(s.highScore, 22);
    expect(s.previousSave, isNull);
    await tester.tap(find.byKey(const ValueKey('importSave')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirmSaveImport')));
    await tester.pumpAndSettle();
    expect(s.highScore, 17);
    expect(restored, 1);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('restorePreviousSave')), 150);
    await tester.tap(find.byKey(const ValueKey('restorePreviousSave')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirmSaveImport')));
    await tester.pumpAndSettle();
    expect(s.highScore, 22);
    expect(restored, 2);
  });

  testWidgets(
      'invalid file and cancelled picker preserve progress without successful-restore callback',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('importSave')), 250);
    picker = (_) async => '{bad';
    await tester.tap(find.byKey(const ValueKey('importSave')));
    await tester.pumpAndSettle();
    expect(find.text('This file is not a supported Atomic Orbital save.'),
        findsOneWidget);
    expect(s.highScore, 22);
    expect(restored, 0);
    picker = (_) async => null;
    await tester.tap(find.byKey(const ValueKey('importSave')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(s.highScore, 22);
    expect(restored, 0);
  });

  testWidgets(
      'file export contains current validated progress and disables duplicate picker requests',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('exportSave')), 250);
    final finish = Completer<bool>();
    picker = (_) => finish.future;
    await tester.tap(find.byKey(const ValueKey('exportSave')),
        warnIfMissed: false);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('exportSave')),
        warnIfMissed: false);
    await tester.pump();
    final exports = calls.where((call) => call.method == 'exportSave');
    expect(exports, hasLength(1));
    expect(
        SaveBackup.decode((exports.single.arguments as Map)['contents']
            as String)['progress']['stats']['high_score'],
        22);
    finish.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Save exported.'), findsOneWidget);
    expect(restored, 0);
  });

  testWidgets('German backup preview fits narrow large text', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(language: 'de', scale: 2));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('importSave')), 250);
    await tester.tap(find.byKey(const ValueKey('importSave')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('confirmSaveImport')));
    await tester.pumpAndSettle();
    expect(s.highScore, 17);
    expect(restored, 1);
    expect(tester.takeException(), isNull);
  });
}
