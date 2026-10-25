import 'dart:io';
import 'package:atomic_orbital/main.dart';
import 'dart:ui' as ui;
import 'package:atomic_orbital/game/achievement_badge.dart';
import 'package:atomic_orbital/game/progress_screen.dart';
import 'package:atomic_orbital/game/settings_screen.dart';
import 'package:atomic_orbital/l10n/strings.dart';
import 'package:atomic_orbital/models/achievement.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  if (!const bool.fromEnvironment('GENERATE_COMPLETION_EVIDENCE')) return;
  setUpAll(() async {
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    await (FontLoader('Roboto')
          ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf')))
        .load();
    SharedPreferences.setMockInitialValues({});
    await SettingsService.initialize();
  });
  Future<void> capture(WidgetTester tester, Widget child, String path) async {
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: key, child: child));
    await tester.pump();
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    });
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('export achievement badges from production widgets',
      (tester) async {
    addTearDown(tester.view.reset);
    for (final pixels in [512, 1024]) {
      tester.view
        ..physicalSize = Size.square(pixels.toDouble())
        ..devicePixelRatio = 1;
      for (final a in OrbitalAchievement.all) {
        await capture(
            tester,
            Directionality(
                textDirection: TextDirection.ltr,
                child: AchievementBadge(
                    achievement: a, unlocked: true, size: pixels.toDouble())),
            'store-assets/2.3.0/${pixels == 512 ? "achievements" : "achievements-ios"}/${a.id}.png');
      }
    }
  });
  for (final locale in ['en', 'de']) {
    testWidgets('export $locale progress and settings', (tester) async {
      tester.view
        ..physicalSize = const Size(393, 852)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final entry in <String, Widget>{
        'progress': const ProgressScreen(),
        'settings': SettingsScreen(onPractice: () {})
      }.entries) {
        await capture(
            tester,
            MaterialApp(
                locale: Locale(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                debugShowCheckedModeBanner: false,
                theme: AtomicOrbitalApp.themeData,
                home: entry.value),
            'docs/evidence/completion-2026-10-24/${entry.key}-$locale.png');
      }
    });
  }
}
