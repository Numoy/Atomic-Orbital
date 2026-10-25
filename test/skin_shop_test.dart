import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:atomic_orbital/game/game_engine.dart';
import 'package:atomic_orbital/game/game_screen.dart';
import 'package:atomic_orbital/game/game_skin.dart';
import 'package:atomic_orbital/game/original_text.dart';
import 'package:atomic_orbital/game/progress_screen.dart';
import 'package:atomic_orbital/game/skin_shop.dart';
import 'package:atomic_orbital/l10n/strings.dart';
import 'package:atomic_orbital/models/components.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The existing preferences dependency provides this in-memory test store.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

const _capture = ValueKey('shopCapture');

class _RejectingStore extends InMemorySharedPreferencesStore {
  _RejectingStore() : super.empty();
  bool reject = true;
  Completer<void>? holdWrite;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key.endsWith('cosmetics_wallet_v1')) {
      await holdWrite?.future;
      if (reject) return false;
    }
    return super.setValue(type, key, value);
  }
}

Widget _host(WidgetTester tester, Widget home,
        {double textScale = 1, Locale locale = const Locale('en')}) =>
    RepaintBoundary(
      key: _capture,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData.dark(useMaterial3: true).copyWith(
            textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto')),
        builder: (context, child) => MediaQuery(
          data: MediaQueryData.fromView(tester.view).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true),
          child: child!,
        ),
        home: home,
      ),
    );

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _preview(WidgetTester tester, GameSkin skin) async {
  final pager = find.byKey(const ValueKey('worldPager'));
  for (var step = 0; step < GameSkin.values.length; step++) {
    if (tester.widget<PageView>(pager).controller!.page?.round() ==
        skin.index) {
      return;
    }
    await _tap(tester, find.byKey(const ValueKey('nextWorld')));
  }
  expect(tester.widget<PageView>(pager).controller!.page,
      closeTo(skin.index.toDouble(), .001));
}

void _collect(GameEngine engine, int count) {
  if (engine.state == GameState.ready) {
    engine.onTouchDown();
    engine.advanceFrame();
    engine.onTouchUp();
  }
  final player = engine.player.logic as PlayerLogicComponent;
  final energy = engine.energy.logic as EnergyLogicComponent;
  for (var i = 0; i < count; i++) {
    for (final photon in engine.photons) {
      photon.collision.isCollidable = false;
    }
    player
      ..speedOrbit = 0
      ..currentAngle = 0
      ..currentRadius = player.minRadius
      ..speedRadius = 0;
    player.positionPlayer(engine.player);
    energy
      ..onOrbit = 0
      ..angle = 0;
    engine.advanceFrame();
  }
  energy.angle = 180;
}

Future<void> _save(WidgetTester tester, String name) async {
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_capture));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory(const String.fromEnvironment(
          'SKIN_EVIDENCE_DIRECTORY',
          defaultValue: 'docs/evidence/world-polish-2026-10-24'));
      await directory.create(recursive: true);
      await File('${directory.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  final settings = SettingsService.instance;
  setUpAll(() async {
    await (FontLoader('Roboto')
          ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.initialize();
  });

  testWidgets('default design hides cosmetics and preserves the saved wallet',
      (tester) async {
    tester.view
      ..physicalSize = const Size(393, 852)
      ..devicePixelRatio = 1
      ..padding = const FakeViewPadding(top: 59, bottom: 34);
    addTearDown(tester.view.reset);
    await settings.earnStardust(50);
    await settings.buySkin(GameSkin.cowAbduction);
    await settings.earnStardust(17);
    final prefs = await SharedPreferences.getInstance();
    final wallet = prefs.getString('cosmetics_wallet_v1');
    final engine = GameEngine(random: Random(1));
    await tester.pumpWidget(_host(
        tester,
        GameScreen(
            engine: engine, textCache: OriginalTextCache(enabled: false))));

    void expectNoCosmetics() {
      expect(find.byKey(const ValueKey('openShop')), findsNothing);
      expect(find.byKey(const ValueKey('runStardust')), findsNothing);
      expect(
          find.textContaining(RegExp(
              r'Stars|Stardust|Flux|World shop|Hangar|Cow Abduction|Deep Blue')),
          findsNothing);
    }

    expectNoCosmetics();
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.text('Progress'), findsOneWidget);
    if (const bool.fromEnvironment('GENERATE_CLASSIC_UI_EVIDENCE')) {
      await _save(tester, 'phone-home');
    }
    await _tap(tester, find.byKey(const ValueKey('startRun')));
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<GamePainter>()
        .single;
    expect(painter.skin, GameSkin.classic);
    _collect(engine, 5);
    for (final photon in engine.photons) {
      photon.collision.isCollidable = true;
    }
    for (var hit = 0; hit < 3; hit++) {
      for (var frame = 0; engine.photons.isEmpty && frame < 102; frame++) {
        engine.advanceFrame();
      }
      engine.photons.first.position
          .setPosition(engine.player.position.position.copy());
      engine.advanceFrame();
    }
    await tester.pump();
    await tester.runAsync(settings.flushProgress);
    await tester.pump();
    expect(engine.state, GameState.gameOver);
    expect(engine.score, 5);
    expectNoCosmetics();
    expect(settings.stardust, 17);
    expect(settings.selectedSkin, GameSkin.cowAbduction);
    expect(prefs.getString('cosmetics_wallet_v1'), wallet);
    final progress = jsonDecode(prefs.getString('player_progress_v1')!)
        as Map<String, dynamic>;
    expect(progress['worlds'], {'classic': 5});
    if (const bool.fromEnvironment('GENERATE_CLASSIC_UI_EVIDENCE')) {
      await _save(tester, 'phone-result');
    }
    await _tap(tester, find.byKey(const ValueKey('openProgress')));
    expect(find.byType(ProgressScreen), findsOneWidget);
    expect(find.text('New Horizons'), findsNothing);
    expect(find.text('World Tour'), findsNothing);
    expect(find.text('2 of 16 unlocked'), findsOneWidget);
    if (const bool.fromEnvironment('GENERATE_CLASSIC_UI_EVIDENCE')) {
      await _save(tester, 'phone-progress');
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shop previews locked worlds, buys once, equips and persists',
      (tester) async {
    await tester.pumpWidget(_host(tester, const SkinShop()));
    final cow = find.byKey(const ValueKey('choose-cow_abduction'));
    expect(tester.widget<FilledButton>(cow).onPressed, isNull);
    expect(find.text('50 more Stars to unlock'), findsOneWidget);
    await _preview(tester, GameSkin.deepBlue);
    expect(
        tester.widget<Text>(find.byKey(const ValueKey('featuredWorld'))).data,
        'Deep Blue');
    expect(settings.selectedSkin, GameSkin.classic,
        reason: 'Browsing must not equip a world');
    await _preview(tester, GameSkin.cowAbduction);
    await tester.runAsync(() => settings.earnStardust(50));
    await tester.pump();
    await _tap(tester, cow);
    expect(settings.stardust, 0);
    expect(settings.selectedSkin, GameSkin.cowAbduction);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.widget<FilledButton>(cow).onPressed, isNull);
    await _preview(tester, GameSkin.classic);
    await _tap(tester, find.byKey(const ValueKey('choose-classic')));
    expect(settings.selectedSkin, GameSkin.classic);
    await _preview(tester, GameSkin.cowAbduction);
    await _tap(tester, cow);
    expect(settings.selectedSkin, GameSkin.cowAbduction);
    expect(settings.stardust, 0);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(SettingsService.initialize);
    expect(settings.selectedSkin, GameSkin.cowAbduction);
    expect(settings.stardust, 0);
  });

  testWidgets(
      'every world can be previewed, unlocked and equipped from the selector',
      (tester) async {
    final totalPrice =
        GameSkin.values.fold<int>(0, (total, skin) => total + skin.price);
    await tester
        .runAsync(() => settings.earnStardust(totalPrice - settings.stardust));
    await tester.pumpWidget(_host(tester, const SkinShop()));
    for (final skin in GameSkin.values) {
      final balance = settings.stardust;
      final equipped = settings.selectedSkin;
      await _preview(tester, skin);
      expect(settings.selectedSkin, equipped);
      expect(settings.stardust, balance);
      expect(
          tester.widget<Text>(find.byKey(const ValueKey('featuredWorld'))).data,
          skin.name);
      if (skin != GameSkin.classic) {
        await _tap(tester, find.byKey(ValueKey('choose-${skin.id}')));
        expect(settings.selectedSkin, skin);
        expect(settings.stardust, balance - skin.price);
        expect(settings.ownsSkin(skin), isTrue);
      }
    }
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(SettingsService.initialize);
    expect(settings.selectedSkin, GameSkin.values.last);
    expect(GameSkin.values.every(settings.ownsSkin), isTrue);
    expect(settings.stardust, 0);
  });

  testWidgets(
      'swipes browse one world at a time and unlock only the current page',
      (tester) async {
    tester.view
      ..physicalSize = const Size(393, 852)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => settings.earnStardust(50));
    await tester.pumpWidget(_host(tester, const SkinShop()));
    final pager = find.byKey(const ValueKey('worldPager'));
    final ownedBefore = GameSkin.values.map(settings.ownsSkin).toList();
    for (final step in [
      (distance: -300.0, skin: GameSkin.deepBlue),
      (distance: 300.0, skin: GameSkin.cowAbduction),
      (distance: -300.0, skin: GameSkin.deepBlue),
    ]) {
      await tester.drag(pager, Offset(step.distance, 0));
      await tester.pumpAndSettle();
      expect(
          tester.widget<Text>(find.byKey(const ValueKey('featuredWorld'))).data,
          step.skin.name);
      expect(tester.widget<PageView>(pager).controller!.page,
          closeTo(step.skin.index.toDouble(), .001));
      expect(settings.stardust, 150);
      expect(settings.selectedSkin, GameSkin.classic);
      expect(GameSkin.values.map(settings.ownsSkin).toList(), ownedBefore);
    }
    await _tap(tester, find.byKey(const ValueKey('choose-deep_blue')));
    expect(settings.selectedSkin, GameSkin.deepBlue);
    expect(settings.ownsSkin(GameSkin.deepBlue), isTrue);
    expect(settings.ownsSkin(GameSkin.cowAbduction), isFalse);
    expect(settings.stardust, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'last world swipes stop at the end and arrows wrap the full catalog',
      (tester) async {
    tester.view
      ..physicalSize = const Size(393, 852)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(tester, const SkinShop()));
    final pager = find.byKey(const ValueKey('worldPager'));
    final last = GameSkin.values.last;
    final previous = GameSkin.values[GameSkin.values.length - 2];
    void expectPreview(GameSkin skin) {
      expect(
          tester.widget<Text>(find.byKey(const ValueKey('featuredWorld'))).data,
          skin.name);
      expect(tester.widget<PageView>(pager).controller!.page,
          closeTo(skin.index.toDouble(), .001));
    }

    await _preview(tester, previous);
    await tester.drag(pager, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expectPreview(last);
    await tester.drag(pager, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expectPreview(last);
    await _tap(tester, find.byKey(const ValueKey('nextWorld')));
    expectPreview(GameSkin.classic);
    await _tap(tester, find.byKey(const ValueKey('previousWorld')));
    expectPreview(last);
    await tester.drag(pager, const Offset(300, 0));
    await tester.pumpAndSettle();
    expectPreview(previous);
    expect(settings.stardust, 100);
    expect(settings.selectedSkin, GameSkin.classic);
    expect(
        GameSkin.values.where(settings.ownsSkin).toList(), [GameSkin.classic]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('pending unlock blocks swipes, arrows and keyboard browsing',
      (tester) async {
    tester.view
      ..physicalSize = const Size(393, 852)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = _RejectingStore()..reject = false;
    SharedPreferencesStorePlatform.instance = store;
    SharedPreferences.resetStatic();
    await tester.runAsync(SettingsService.initialize);
    await tester.runAsync(() => settings.earnStardust(50));
    final write = Completer<void>();
    store.holdWrite = write;
    addTearDown(() {
      if (!write.isCompleted) write.complete();
    });
    await tester.pumpWidget(_host(tester, const SkinShop()));
    await _tap(tester, find.byKey(const ValueKey('choose-cow_abduction')));
    final pager = find.byKey(const ValueKey('worldPager'));
    await tester.drag(pager, const Offset(-300, 0));
    await tester.pump(const Duration(milliseconds: 400));
    await _tap(tester, find.byKey(const ValueKey('nextWorld')));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(
        tester.widget<Text>(find.byKey(const ValueKey('featuredWorld'))).data,
        GameSkin.cowAbduction.name);
    expect(tester.widget<PageView>(pager).controller!.page,
        closeTo(GameSkin.cowAbduction.index.toDouble(), .001));
    expect(settings.selectedSkin, GameSkin.classic);
    expect(settings.stardust, 150);
    expect(
        tester
            .widget<FilledButton>(
                find.byKey(const ValueKey('choose-cow_abduction')))
            .onPressed,
        isNull);
    write.complete();
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 400));
    expect(settings.selectedSkin, GameSkin.cowAbduction);
    expect(settings.stardust, 0);
    await tester.drag(pager, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(
        tester.widget<Text>(find.byKey(const ValueKey('featuredWorld'))).data,
        GameSkin.deepBlue.name);
    await tester.pumpWidget(const SizedBox());
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('browsing and equipping keep the shop anchored at $scale scale',
        (tester) async {
      tester.view
        ..physicalSize = const Size(393, 852)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester
          .pumpWidget(_host(tester, const SkinShop(), textScale: scale));
      List<Offset> anchors() => [
            tester.getCenter(find.byType(FilledButton)),
            tester.getCenter(find.byKey(const ValueKey('previousWorld'))),
            tester.getCenter(find.byKey(const ValueKey('nextWorld'))),
            tester.getCenter(find.byKey(const ValueKey('worldPageIndicators'))),
          ];
      final before = anchors();
      for (var i = 0; i < GameSkin.values.length; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(anchors(), before, reason: 'Browsing step $i');
      }
      if (scale == 1) {
        for (final skin in [
          GameSkin.deepBlue,
          GameSkin.classic,
          GameSkin.cowAbduction
        ]) {
          await _preview(tester, skin);
          expect(anchors(), before, reason: 'Browsing to ${skin.name}');
        }
      }
      await tester.runAsync(() => settings.earnStardust(50));
      await tester.pump();
      expect(anchors(), before, reason: 'Becoming affordable');
      final choose = find.byKey(const ValueKey('choose-cow_abduction'));
      if (scale == 1) {
        await tester.tap(choose);
      } else {
        // Exercise the offscreen action without scrolling the larger-text view.
        tester.widget<FilledButton>(choose).onPressed!();
      }
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 400));
      expect(settings.selectedSkin, GameSkin.cowAbduction);
      expect(anchors(), before, reason: 'Equipping a world');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Stars field guide belongs to the game and preserves the wallet',
      (tester) async {
    await tester.pumpWidget(_host(tester, const SkinShop()));
    await _tap(tester, find.byKey(const ValueKey('shopInfo')));
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('FIELD GUIDE'), findsOneWidget);
    expect(find.text('1 pickup = 1 Star'), findsOneWidget);
    expect(find.textContaining('Stardust'), findsNothing);
    await _tap(tester, find.text('BACK TO HANGAR'));
    expect(find.text('FIELD GUIDE'), findsNothing);
    expect(settings.stardust, 100);
    expect(settings.selectedSkin, GameSkin.classic);
    await tester.pumpWidget(const SizedBox());
  });

  for (final size in [const Size(256, 568), const Size(852, 393)]) {
    testWidgets('field guide scrolls at large text size on $size',
        (tester) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(tester, const SkinShop(), textScale: 3.2));
      await _tap(tester, find.byKey(const ValueKey('shopInfo')));
      await _tap(tester, find.text('BACK TO HANGAR'));
      expect(find.text('FIELD GUIDE'), findsNothing);
      expect(settings.stardust, 100);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('unavailable wallet does not show a made-up unlock progress',
      (tester) async {
    SharedPreferences.setMockInitialValues({'cosmetics_wallet_v1': 'invalid'});
    await tester.runAsync(SettingsService.initialize);
    await tester.pumpWidget(_host(tester, const SkinShop()));
    expect(find.byKey(const ValueKey('shopError')), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(
        tester.widget<Text>(find.byKey(const ValueKey('stardustBalance'))).data,
        '—');
    expect(
        tester
            .widget<FilledButton>(
                find.byKey(const ValueKey('choose-cow_abduction')))
            .onPressed,
        isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('earned pickups survive End run and can buy a playable world',
      (tester) async {
    final engine = GameEngine(random: Random(1));
    await tester.pumpWidget(_host(
        tester,
        GameScreen(
            cosmeticsEnabled: true,
            engine: engine,
            textCache: OriginalTextCache(enabled: false))));
    await _tap(tester, find.byKey(const ValueKey('startRun')));
    _collect(engine, 50);
    engine.pauseGame();
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(engine.score, 50);
    expect(settings.stardust, 150);
    await _tap(tester, find.text('End run'));
    expect(engine.state, GameState.menu);
    expect(settings.stardust, 150);
    await _tap(tester, find.byKey(const ValueKey('openShop')));
    await _tap(tester, find.byKey(const ValueKey('choose-cow_abduction')));
    expect(settings.stardust, 0);
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 400));
    await _tap(tester, find.byKey(const ValueKey('startRun')));
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((widget) => widget.painter)
        .whereType<GamePainter>()
        .single;
    expect(painter.skin, GameSkin.cowAbduction);
    engine.pauseGame();
    await tester.pumpWidget(const SizedBox());
  });

  for (final hardcore in [false, true]) {
    testWidgets(
        'mode $hardcore banks once across death, rebuild, replay and Home',
        (tester) async {
      final engine = GameEngine(random: Random(1));
      await tester.pumpWidget(_host(
          tester,
          GameScreen(
              cosmeticsEnabled: true,
              engine: engine,
              textCache: OriginalTextCache(enabled: false))));
      if (hardcore) {
        await _tap(tester, find.byKey(const ValueKey('modeHardcore')));
      }
      await _tap(tester, find.byKey(const ValueKey('startRun')));
      _collect(engine, 2);
      for (final photon in engine.photons) {
        photon.collision.isCollidable = true;
      }
      final player = engine.player.logic as PlayerLogicComponent;
      player.speedOrbit = 0;
      for (var hit = 0; hit < (hardcore ? 1 : 3); hit++) {
        for (var frame = 0; engine.photons.isEmpty && frame < 102; frame++) {
          engine.advanceFrame();
        }
        expect(engine.photons, isNotEmpty,
            reason: 'State ${engine.state} before hit $hit');
        engine.photons.first.position
            .setPosition(engine.player.position.position.copy());
        engine.advanceFrame();
      }
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      expect(engine.state, GameState.gameOver);
      expect(settings.stardust, 102);
      expect(find.text('+2 Stars saved'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(settings.stardust, 102);
      await _tap(tester, find.byKey(const ValueKey('replayRun')));
      engine.pauseGame();
      await tester.pump();
      await _tap(tester, find.text('End run'));
      expect(settings.stardust, 102);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('failed earnings stay pending and retry banks exactly once',
      (tester) async {
    final store = _RejectingStore();
    SharedPreferencesStorePlatform.instance = store;
    SharedPreferences.resetStatic();
    await tester.runAsync(SettingsService.initialize);
    final engine = GameEngine(random: Random(1));
    await tester.pumpWidget(_host(
        tester,
        GameScreen(
            cosmeticsEnabled: true,
            engine: engine,
            textCache: OriginalTextCache(enabled: false))));
    await _tap(tester, find.byKey(const ValueKey('startRun')));
    _collect(engine, 1);
    engine.pauseGame();
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(settings.stardust, 100);
    expect(find.textContaining('Stars could not be saved'), findsOneWidget);
    engine.resumeGame();
    _collect(engine, 1);
    engine.pauseGame();
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Stars could not be saved'), findsOneWidget);
    store.reject = false;
    await _tap(tester, find.text('Retry'));
    expect(settings.stardust, 102);
    expect(find.textContaining('Stars could not be saved'), findsNothing);
    await _tap(tester, find.text('End run'));
    expect(settings.stardust, 102);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('rapid shop taps during a save retry open one route',
      (tester) async {
    final store = _RejectingStore();
    SharedPreferencesStorePlatform.instance = store;
    SharedPreferences.resetStatic();
    await tester.runAsync(SettingsService.initialize);
    final engine = GameEngine(random: Random(1));
    await tester.pumpWidget(_host(
        tester,
        GameScreen(
            cosmeticsEnabled: true,
            engine: engine,
            textCache: OriginalTextCache(enabled: false))));
    await _tap(tester, find.byKey(const ValueKey('startRun')));
    _collect(engine, 1);
    engine.pauseGame();
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await _tap(tester, find.text('End run'));
    store
      ..reject = false
      ..holdWrite = Completer<void>();
    final shop = find.byKey(const ValueKey('openShop'));
    await tester.ensureVisible(shop);
    await tester.tap(shop);
    await tester.pump();
    await tester.tap(shop);
    await tester.pump();
    expect(find.byType(SkinShop), findsNothing);
    store.holdWrite!.complete();
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SkinShop), findsOneWidget);
    expect(find.byType(SkinShop, skipOffstage: false), findsOneWidget);
    expect(settings.stardust, 101);
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pageBack();
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(SkinShop), findsNothing);
    expect(find.byKey(const ValueKey('openShop')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  for (final size in [
    const Size(256, 568),
    const Size(393, 852),
    const Size(852, 393),
    const Size(1024, 768)
  ]) {
    for (final scale in [1.0, 2.0, 3.2]) {
      testWidgets('shop fits $size at $scale text scale', (tester) async {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester
            .pumpWidget(_host(tester, const SkinShop(), textScale: scale));
        expect(tester.getSize(find.byType(SingleChildScrollView)).height,
            greaterThan(size.height * .4));
        await _preview(tester, GameSkin.deepBlue);
        if (const bool.fromEnvironment('GENERATE_SKIN_UI_EVIDENCE') &&
            size.width == 256 &&
            scale == 3.2) {
          await _save(tester, 'narrow-large-text-chooser');
        }
        await tester
            .ensureVisible(find.byKey(const ValueKey('choose-deep_blue')));
        await tester.pump();
        expect(tester.takeException(), isNull);
        final button =
            tester.getSize(find.byKey(const ValueKey('choose-deep_blue')));
        expect(button.height, greaterThanOrEqualTo(48));
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  for (final scenario in [
    (size: const Size(393, 852), scale: 1.0),
    (size: const Size(256, 568), scale: 3.2),
  ]) {
    testWidgets(
        'German selector fits ${scenario.size} at ${scenario.scale} scale',
        (tester) async {
      tester.view
        ..physicalSize = scenario.size
        ..devicePixelRatio = 1
        ..padding = scenario.scale == 1
            ? const FakeViewPadding(top: 59, bottom: 34)
            : const FakeViewPadding();
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(tester, const SkinShop(),
          textScale: scenario.scale, locale: const Locale('de')));
      await tester.pump();
      for (final world in [
        (skin: GameSkin.dragonHoard, name: 'Drachen\u00adschatz'),
        (skin: GameSkin.sunflower, name: 'Pollen\u00adpatrouille'),
        (skin: GameSkin.jungleJam, name: 'Dschungelspaß'),
      ]) {
        await _preview(tester, world.skin);
        expect(
            tester
                .widget<Text>(find.byKey(const ValueKey('featuredWorld')))
                .data,
            world.name);
        final action = find.byKey(ValueKey('choose-${world.skin.id}'));
        await tester.ensureVisible(action);
        await tester.pump();
        final rect = tester.getRect(action);
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.top, greaterThanOrEqualTo(scenario.scale == 1 ? 59 : 0));
        expect(
            rect.bottom,
            lessThanOrEqualTo(
                scenario.size.height - (scenario.scale == 1 ? 34 : 0)));
        expect(tester.takeException(), isNull);
      }
      if (const bool.fromEnvironment('GENERATE_SKIN_UI_EVIDENCE')) {
        tester
            .state<ScrollableState>(find.byWidgetPredicate((widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down))
            .position
            .jumpTo(0);
        await tester.pump();
        await _save(
            tester,
            scenario.scale == 1
                ? 'german-shop-phone'
                : 'german-shop-large-text');
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('world browsing supports arrows, Tab and accessible navigation',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.runAsync(() => settings.earnStardust(50));
      await tester.pumpWidget(_host(tester, const SkinShop()));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(
          tester.widget<Text>(find.byKey(const ValueKey('featuredWorld'))).data,
          'Deep Blue');
      expect(settings.selectedSkin, GameSkin.classic);
      for (final control in [
        (key: 'previousWorld', label: 'Previous world'),
        (key: 'nextWorld', label: 'Next world'),
      ]) {
        final node = tester.getSemantics(find.byKey(ValueKey(control.key)));
        expect(node.flagsCollection.isButton, isTrue);
        expect(
            node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
        expect(node.getSemanticsData().tooltip, control.label);
      }
      expect(find.bySemanticsLabel(RegExp(r'^Deep Blue\..*kraken')),
          findsOneWidget);
      final unlock =
          tester.getSemantics(find.byKey(const ValueKey('choose-deep_blue')));
      expect(unlock.flagsCollection.isButton, isTrue);
      expect(
          unlock.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, isNotNull);
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(
          tester.widget<Text>(find.byKey(const ValueKey('featuredWorld'))).data,
          'Cow Abduction');
      await tester.pumpWidget(const SizedBox());
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('full catalog indicators fit a narrow phone without overflow',
      (tester) async {
    tester.view
      ..physicalSize = const Size(256, 568)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(tester, const SkinShop()));
    await _preview(tester, GameSkin.values.last);
    final indicators =
        tester.getRect(find.byKey(const ValueKey('worldPageIndicators')));
    expect(indicators.width, lessThan(200));
    expect(indicators.left, greaterThanOrEqualTo(16));
    expect(indicators.right, lessThanOrEqualTo(256 - 16));
    expect(indicators.top, greaterThanOrEqualTo(0));
    expect(indicators.bottom, lessThanOrEqualTo(568));
    final action = find.byKey(ValueKey('choose-${GameSkin.values.last.id}'));
    await tester.ensureVisible(action);
    await tester.pump();
    expect(tester.getRect(action).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('GENERATE_SKIN_UI_EVIDENCE')) {
      await _save(tester, 'last-world-narrow-phone');
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'notched phone shows arrows, compact indicators and action without scrolling',
      (tester) async {
    tester.view
      ..physicalSize = const Size(393, 852)
      ..devicePixelRatio = 1
      ..padding = const FakeViewPadding(top: 59, bottom: 34);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(tester, const SkinShop()));
    for (final key in ['previousWorld', 'nextWorld']) {
      final rect = tester.getRect(find.byKey(ValueKey(key)));
      expect(rect.width, greaterThanOrEqualTo(48));
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.top, greaterThanOrEqualTo(59));
      expect(rect.bottom, lessThanOrEqualTo(852 - 34));
    }
    final indicators =
        tester.getRect(find.byKey(const ValueKey('worldPageIndicators')));
    expect(indicators.width, lessThan(200));
    expect(indicators.top, greaterThanOrEqualTo(59));
    expect(indicators.bottom, lessThanOrEqualTo(852 - 34));
    final action = tester.getRect(find.byType(FilledButton));
    expect(action.top, greaterThanOrEqualTo(59));
    expect(action.bottom, lessThanOrEqualTo(852 - 34));
    expect(action.height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  if (const bool.fromEnvironment('GENERATE_SKIN_UI_EVIDENCE')) {
    testWidgets('render insufficient funds and equipped state', (tester) async {
      tester.view
        ..physicalSize = const Size(393, 852)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(tester, const SkinShop()));
      await _save(tester, 'shop-progress-phone');
      await tester.runAsync(() => settings.earnStardust(50));
      await tester.pump();
      await _tap(tester, find.byKey(const ValueKey('choose-cow_abduction')));
      tester
          .state<ScrollableState>(find.byWidgetPredicate((widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down))
          .position
          .jumpTo(0);
      await tester.pump();
      await _save(tester, 'shop-equipped-phone');
      await _tap(tester, find.byKey(const ValueKey('shopInfo')));
      await _save(tester, 'flux-field-guide-phone');
      await _tap(tester, find.text('BACK TO HANGAR'));
      await tester.pumpWidget(const SizedBox());
    });
    for (final skin in GameSkin.values) {
      for (final tablet in [false, true]) {
        testWidgets('render ${skin.id} shop ${tablet ? 'tablet' : 'phone'}',
            (tester) async {
          tester.view
            ..physicalSize =
                tablet ? const Size(1024, 768) : const Size(393, 852)
            ..devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.runAsync(() async {
            await settings.earnStardust(50);
          });
          await tester.pumpWidget(_host(tester, const SkinShop()));
          if (skin != GameSkin.cowAbduction) {
            await _preview(tester, skin);
            tester
                .state<ScrollableState>(find.byWidgetPredicate((widget) =>
                    widget is Scrollable &&
                    widget.axisDirection == AxisDirection.down))
                .position
                .jumpTo(0);
          }
          await tester.pump();
          await _save(tester, '${skin.id}-shop-${tablet ? 'tablet' : 'phone'}');
          if (skin == GameSkin.cowAbduction) {
            await _save(tester, 'shop-${tablet ? 'tablet' : 'phone'}');
          }
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
    for (final skin
        in GameSkin.values.where((skin) => skin != GameSkin.classic)) {
      testWidgets('render ${skin.id} phone gameplay', (tester) async {
        tester.view
          ..physicalSize = const Size(393, 852)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.runAsync(() async {
          await settings.earnStardust(50);
          await settings.buySkin(skin);
        });
        final engine = GameEngine(random: Random(1))..startGame();
        _collect(engine, 8);
        // Isolated visual fixture; these positions never enter a real save.
        final player = engine.player.logic as PlayerLogicComponent;
        player
          ..currentAngle = 45
          ..currentRadius = player.maxRadius;
        player.positionPlayer(engine.player);
        (engine.energy.logic as EnergyLogicComponent)
          ..onOrbit = 1
          ..angle = 220;
        engine.advanceFrame();
        engine.photons.first.position
            .setPosition(engine.atom.position.position.copy()
              ..x += 240
              ..y -= 260);
        (engine.photons.first.logic as PhotonLogicComponent).radius = 15;
        await tester.pumpWidget(_host(
            tester,
            GameScreen(
                cosmeticsEnabled: true,
                engine: engine,
                textCache: OriginalTextCache(enabled: false))));
        await tester.pump();
        await _save(tester, '${skin.id}-gameplay-phone');
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
