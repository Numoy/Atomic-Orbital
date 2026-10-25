import 'dart:io';
import 'dart:ui' as ui;
import 'package:atomic_orbital/game/practice_screen.dart';
import 'package:atomic_orbital/game/progress_screen.dart';
import 'package:atomic_orbital/game/settings_screen.dart';
import 'package:atomic_orbital/l10n/strings.dart';
import 'package:atomic_orbital/main.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  if (!const bool.fromEnvironment('GENERATE_TUTORIAL_EVIDENCE')) return;
  final boundaryKey = GlobalKey();
  setUpAll(() async {
    await (FontLoader('Roboto')
          ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.initialize();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('atomic_orbital/platform'),
            (call) async => call.method == 'appInfo'
                ? {'version': '2.3.0', 'build': '44'}
                : null);
  });

  Future<void> mount(WidgetTester tester, Widget screen, String language,
      {Size size = const Size(393, 852), double scale = 1}) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    await tester.pumpWidget(RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            debugShowCheckedModeBanner: false,
            theme: AtomicOrbitalApp.themeData,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: screen)));
    await tester.pump();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    final boundary = boundaryKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File('docs/evidence/tutorial-anywhere-2026-10-25/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    });
    expect(tester.takeException(), isNull);
  }

  Future<void> frames(WidgetTester tester, int count) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 17));
    }
  }

  for (final language in ['en', 'de']) {
    testWidgets('capture $language practice and simple utility screens',
        (tester) async {
      addTearDown(tester.view.reset);
      await mount(tester, const PracticeScreen(), language);
      await capture(tester, 'practice-hold-$language');
      final arena = find.byKey(const ValueKey('practiceArena'));
      final hold = await tester.startGesture(tester.getCenter(arena));
      await frames(tester, 10);
      await capture(tester, 'practice-holding-$language');
      await frames(tester, 60);
      await capture(tester, 'practice-release-$language');
      await hold.up();
      await frames(tester, 10);
      await capture(tester, 'practice-released-$language');
      await frames(tester, 150);
      await capture(tester, 'practice-done-$language');
      await tester.pumpWidget(const SizedBox());
      for (final entry in <String, Widget>{
        'progress': const ProgressScreen(),
        'settings': SettingsScreen(onPractice: () {})
      }.entries) {
        await mount(tester, entry.value, language);
        await capture(tester, '${entry.key}-$language');
        await tester.pumpWidget(const SizedBox());
      }
    });
  }
  testWidgets('capture landscape and narrow large-text practice',
      (tester) async {
    addTearDown(tester.view.reset);
    await mount(tester, const PracticeScreen(), 'de',
        size: const Size(852, 393));
    await capture(tester, 'practice-landscape-de');
    await tester.pumpWidget(const SizedBox());
    await mount(tester, const PracticeScreen(), 'de',
        size: const Size(256, 600), scale: 2);
    await capture(tester, 'practice-large-text-de');
    final hold = await tester.startGesture(const Offset(8, 300));
    await frames(tester, 180);
    await capture(tester, 'practice-large-text-release-de');
    await hold.up();
    await frames(tester, 180);
    await capture(tester, 'practice-large-text-done-de');
    await tester.pumpWidget(const SizedBox());
  });
}
