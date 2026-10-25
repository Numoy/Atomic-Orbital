import 'dart:io';
import 'dart:ui' as ui;

import 'package:atomic_orbital/game/menu_scene.dart';
import 'package:atomic_orbital/game/game_skin.dart';
import 'package:atomic_orbital/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Window {
  const _Window(this.name, this.size, {this.padding = EdgeInsets.zero});

  final String name;
  final Size size;
  final EdgeInsets padding;

  Rect get safeRect => Rect.fromLTRB(padding.left, padding.top,
      size.width - padding.right, size.height - padding.bottom);
}

const _windows = [
  _Window('reference Android', Size(1080 / 2.625, 1920 / 2.625),
      padding: EdgeInsets.symmetric(vertical: 24)),
  _Window('narrow phone', Size(320, 568), padding: EdgeInsets.only(top: 20)),
  _Window('tall Android', Size(360, 800),
      padding: EdgeInsets.symmetric(vertical: 24)),
  _Window('iPhone cutout', Size(393, 852),
      padding: EdgeInsets.only(top: 59, bottom: 34)),
  _Window('wide phone', Size(430, 932),
      padding: EdgeInsets.only(top: 59, bottom: 34)),
  _Window('four by three tablet', Size(768, 1024),
      padding: EdgeInsets.only(top: 24, bottom: 20)),
  _Window('tall tablet', Size(834, 1194),
      padding: EdgeInsets.only(top: 24, bottom: 20)),
  _Window('large tablet', Size(1024, 1366),
      padding: EdgeInsets.only(top: 24, bottom: 20)),
  _Window('landscape tablet', Size(1366, 1024),
      padding: EdgeInsets.only(top: 24, bottom: 20)),
  _Window('landscape cutout', Size(852, 393),
      padding: EdgeInsets.only(left: 59, right: 59, bottom: 21)),
  _Window('narrow split screen', Size(256, 1024),
      padding: EdgeInsets.only(top: 24, bottom: 20)),
  _Window('square split screen', Size(600, 600),
      padding: EdgeInsets.only(top: 24, bottom: 20)),
  _Window('short split screen', Size(600, 320),
      padding: EdgeInsets.only(bottom: 20)),
];

const _captureKey = ValueKey('menuCapture');
void _noop() {}

void _window(WidgetTester tester, _Window window) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = window.size
    ..padding = FakeViewPadding(
        left: window.padding.left,
        top: window.padding.top,
        right: window.padding.right,
        bottom: window.padding.bottom);
}

Widget _host(WidgetTester tester, Widget scene,
        {double textScale = 1,
        bool reduceMotion = true,
        String language = 'en'}) =>
    RepaintBoundary(
      key: _captureKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF9BE9EF),
            onPrimary: Color(0xFF080D14),
            secondary: Color(0xFFFF8674),
            surface: Color(0xFF080D14),
            onSurface: Color(0xFFF3F5F3),
          ),
          scaffoldBackgroundColor: Colors.black,
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQueryData.fromView(tester.view).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: child!,
        ),
        home: Scaffold(
            backgroundColor: const Color(0xFF080D14),
            body: SafeArea(child: scene)),
      ),
    );

OrbitMenu _menu({
  bool hardcore = false,
  bool muted = true,
  bool gamesAvailable = true,
  bool signedIn = false,
  GameSkin skin = GameSkin.classic,
  VoidCallback? onShop = _noop,
  VoidCallback? onProgress = _noop,
  VoidCallback? onSettings = _noop,
  ValueChanged<bool>? onModeChanged,
  VoidCallback? onPlay,
  VoidCallback? onToggleSound,
  VoidCallback? onShare,
  VoidCallback? onAchievements,
  VoidCallback? onLeaderboard,
  VoidCallback? onSignIn,
  VoidCallback? onRate,
}) =>
    OrbitMenu(
      hardcore: hardcore,
      normalBest: 42,
      hardcoreBest: 17,
      muted: muted,
      gamesAvailable: gamesAvailable,
      signedIn: signedIn,
      skin: skin,
      stardust: 100,
      onShop: onShop,
      onProgress: onProgress,
      onSettings: onSettings,
      onModeChanged: onModeChanged ?? (_) {},
      onPlay: onPlay ?? () {},
      onToggleSound: onToggleSound ?? () {},
      onShare: onShare ?? () {},
      onAchievements: onAchievements,
      onLeaderboard: onLeaderboard,
      onSignIn: onSignIn,
      onRate: onRate,
    );

OrbitGameOver _gameOver({
  bool hardcore = false,
  bool newBest = false,
  GameSkin skin = GameSkin.classic,
  int? score,
  int? best,
  int? earned,
  bool pending = false,
  VoidCallback? onShop = _noop,
  VoidCallback? onProgress = _noop,
  VoidCallback? onSettings = _noop,
  VoidCallback? onReplay,
  VoidCallback? onHome,
  VoidCallback? onToggleSound,
  VoidCallback? onShare,
  VoidCallback? onAchievements,
  VoidCallback? onLeaderboard,
  VoidCallback? onRate,
}) =>
    OrbitGameOver(
      score: score ?? (hardcore ? 7 : 23),
      best: best ?? (hardcore ? 17 : 42),
      newBest: newBest,
      skin: skin,
      stardust: 100,
      stardustEarned: earned ?? score ?? (hardcore ? 7 : 23),
      stardustPending: pending,
      onShop: onShop,
      onProgress: onProgress,
      onSettings: onSettings,
      hardcore: hardcore,
      muted: true,
      onReplay: onReplay ?? () {},
      onHome: onHome ?? () {},
      onToggleSound: onToggleSound ?? () {},
      onShare: onShare ?? () {},
      onAchievements: onAchievements,
      onLeaderboard: onLeaderboard,
      onRate: onRate,
    );

Rect _bounds(WidgetTester tester, Finder finder) {
  final box = tester.renderObject<RenderBox>(finder);
  return Rect.fromPoints(box.localToGlobal(Offset.zero),
      box.localToGlobal(Offset(box.size.width, box.size.height)));
}

Future<void> _reachable(
    WidgetTester tester, Finder finder, Rect safeRect) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  final rect = _bounds(tester, finder);
  expect(rect.left, greaterThanOrEqualTo(safeRect.left - 0.01));
  expect(rect.top, greaterThanOrEqualTo(safeRect.top - 0.01));
  expect(rect.right, lessThanOrEqualTo(safeRect.right + 0.01));
  expect(rect.bottom, lessThanOrEqualTo(safeRect.bottom + 0.01));
  expect(rect.height, greaterThanOrEqualTo(44),
      reason: 'Adaptive menus must preserve a usable touch target');
}

Future<void> _openSceneMenu(WidgetTester tester, Rect safeRect,
    {String menuKey = 'homeMenu'}) async {
  final menu = find.byKey(ValueKey(menuKey));
  await _reachable(tester, menu, safeRect);
  await tester.tap(menu);
  await tester.pumpAndSettle();
}

Finder _menuItem(String label) =>
    find.widgetWithText(PopupMenuItem<VoidCallback>, label);

Future<void> _chooseSceneAction(
    WidgetTester tester, String label, Rect safeRect,
    {String menuKey = 'homeMenu'}) async {
  await _openSceneMenu(tester, safeRect, menuKey: menuKey);
  final item = _menuItem(label);
  await _reachable(tester, item, safeRect);
  await tester.tap(item);
  await tester.pumpAndSettle();
}

Future<List<int>> _pixels(WidgetTester tester) async {
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_captureKey));
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      return (await image.toByteData())!.buffer.asUint8List().toList();
    } finally {
      image.dispose();
    }
  }))!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Roboto')
          ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  testWidgets('themed results keep the score above the artwork at large text',
      (tester) async {
    for (final skin
        in GameSkin.values.where((skin) => skin != GameSkin.classic)) {
      for (final window in [_windows[3], _windows[9], _windows[10]]) {
        _window(tester, window);
        for (final scale in [1.0, 3.2]) {
          await tester.pumpWidget(_host(
              tester, _gameOver(skin: skin, score: 123, best: 123),
              textScale: scale));
          final score =
              _bounds(tester, find.byKey(const ValueKey('themedResultScore')));
          final art =
              _bounds(tester, find.byKey(const ValueKey('menuArenaArtwork')));
          expect(score.bottom, lessThanOrEqualTo(art.top));
          await _reachable(
              tester, find.byKey(const ValueKey('replayRun')), window.safeRect);
          expect(tester.takeException(), isNull);
        }
      }
    }
    tester.view.reset();
    await tester.pumpWidget(const SizedBox());
  });

  for (final window in _windows) {
    for (final textScale in [1.0, 2.0]) {
      testWidgets('${window.name}, text $textScale: both menu modes fit',
          (tester) async {
        _window(tester, window);
        addTearDown(tester.view.reset);
        for (final hardcore in [false, true]) {
          await tester.pumpWidget(
              _host(tester, _menu(hardcore: hardcore), textScale: textScale));
          expect(tester.takeException(), isNull);
          expect(
              find.descendant(
                  of: find.byKey(const ValueKey('modeNormal')),
                  matching: find.text('Normal')),
              findsOneWidget);
          expect(
              find.descendant(
                  of: find.byKey(const ValueKey('modeHardcore')),
                  matching: find.text('Hardcore')),
              findsOneWidget);
          expect(find.text('BEST  ${hardcore ? 17 : 42}'), findsOneWidget);
          for (final key in [
            'modeNormal',
            'modeHardcore',
            'startRun',
            'openShop',
            'openProgress'
          ]) {
            await _reachable(
                tester, find.byKey(ValueKey(key)), window.safeRect);
          }
          await _chooseSceneAction(tester, 'How to play', window.safeRect);
          expect(find.text('HOW TO PLAY'), findsOneWidget);
          expect(
              MediaQuery.textScalerOf(tester.element(find.text('HOW TO PLAY')))
                  .scale(16),
              16 * textScale);
          final close = find.byKey(const ValueKey('closeHelp'));
          await _reachable(tester, close, window.safeRect);
          expect(tester.takeException(), isNull);
          await tester.tap(close);
          await tester.pumpAndSettle();
          expect(find.text('HOW TO PLAY'), findsNothing);
          expect(find.text('BEST  ${hardcore ? 17 : 42}'), findsOneWidget);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      });

      testWidgets('${window.name}, text $textScale: both result modes fit',
          (tester) async {
        _window(tester, window);
        addTearDown(tester.view.reset);
        for (final hardcore in [false, true]) {
          for (final newBest in [false, true]) {
            await tester.pumpWidget(_host(
                tester,
                _gameOver(
                    hardcore: hardcore, score: 43, best: 43, newBest: newBest),
                textScale: textScale));
            expect(tester.takeException(), isNull);
            expect(find.text('43'), findsNWidgets(2));
            expect(find.text(newBest ? 'NEW BEST!' : 'Personal best'),
                findsOneWidget);
            for (final key in [
              'resultBest',
              'replayRun',
              'home',
              'openShop',
              'openProgress'
            ]) {
              await _reachable(
                  tester, find.byKey(ValueKey(key)), window.safeRect);
            }
            await tester.pumpWidget(const SizedBox.shrink());
          }
        }
      });
    }
  }

  testWidgets('default phone shows both modes and PLAY without scrolling',
      (tester) async {
    final window = _windows[3];
    _window(tester, window);
    addTearDown(tester.view.reset);
    for (final hardcore in [false, true]) {
      await tester.pumpWidget(_host(
          tester,
          _menu(
              hardcore: hardcore,
              onAchievements: _noop,
              onLeaderboard: _noop,
              onSignIn: _noop,
              onRate: _noop)));
      await tester.pump();
      expect(find.text('PLAY'), findsOneWidget);
      for (final state
          in tester.stateList<ScrollableState>(find.byType(Scrollable))) {
        expect(state.position.pixels, closeTo(0, 0.01),
            reason: 'Initial focus must not scroll away from a mode selector');
      }
      for (final key in [
        'modeNormal',
        'modeHardcore',
        'startRun',
        'openShop',
        'openProgress'
      ]) {
        final control = find.byKey(ValueKey(key));
        final rect = _bounds(tester, control);
        expect(rect.left, greaterThanOrEqualTo(window.safeRect.left));
        expect(rect.top, greaterThanOrEqualTo(window.safeRect.top));
        expect(rect.right, lessThanOrEqualTo(window.safeRect.right));
        expect(rect.bottom, lessThanOrEqualTo(window.safeRect.bottom));
        expect(control.hitTestable(), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('default phone and landscape results keep actions visible',
      (tester) async {
    addTearDown(tester.view.reset);
    for (final window in [_windows[3], _windows[9]]) {
      _window(tester, window);
      for (final hardcore in [false, true]) {
        await tester.pumpWidget(_host(tester, _gameOver(hardcore: hardcore)));
        await tester.pump();
        for (final key in ['replayRun', 'home', 'openShop', 'openProgress']) {
          final control = find.byKey(ValueKey(key));
          expect(_bounds(tester, control).bottom,
              lessThanOrEqualTo(window.safeRect.bottom));
          expect(control.hitTestable(), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });

  testWidgets('equal result and best scores do not claim a new record',
      (tester) async {
    _window(tester, _windows[3]);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(tester, _gameOver(score: 42, best: 42)));
    expect(find.text('42'), findsNWidgets(2));
    expect(find.text('GAME OVER'), findsOneWidget);
    expect(find.text('TRY AGAIN'), findsOneWidget);
    expect(
        find.textContaining(RegExp(r'new best|record', caseSensitive: false)),
        findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('home keeps two destinations and puts secondary actions in Menu',
      (tester) async {
    _window(tester, _windows[3]);
    addTearDown(tester.view.reset);
    final actions = <String>[];
    await tester.pumpWidget(_host(
        tester,
        _menu(
          onShop: () => actions.add('worlds'),
          onProgress: () => actions.add('progress'),
          onSettings: () => actions.add('settings'),
          onPlay: () => actions.add('play'),
          onShare: () => actions.add('share'),
          onRate: () => actions.add('rate'),
        )));
    expect(find.byType(OutlinedButton), findsNWidgets(2));
    expect(find.text('100 Stars'), findsOneWidget);
    for (final label in [
      'Settings',
      'How to play',
      'Share Atomic Orbital',
      'Rate'
    ]) {
      expect(find.text(label), findsNothing);
    }
    for (final key in ['openShop', 'openProgress']) {
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pump();
    }
    await _openSceneMenu(tester, _windows[3].safeRect);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(actions, ['worlds', 'progress']);
    Focus.of(tester.element(find.byIcon(Icons.menu_rounded))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    await tester.tap(_menuItem('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuItem<VoidCallback>), findsNothing);
    expect(actions, ['worlds', 'progress', 'settings']);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final language in ['en', 'de']) {
    testWidgets('$language scene menus scroll with very large text',
        (tester) async {
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      try {
        for (final window in [_windows[1], _windows[9], _windows[10]]) {
          _window(tester, window);
          for (final result in [false, true]) {
            var rates = 0;
            await tester.pumpWidget(_host(
                tester,
                result
                    ? _gameOver(
                        earned: 1,
                        pending: true,
                        onAchievements: _noop,
                        onLeaderboard: _noop,
                        onRate: () => rates++,
                      )
                    : _menu(
                        onAchievements: _noop,
                        onLeaderboard: _noop,
                        onSignIn: _noop,
                        onRate: () => rates++,
                      ),
                textScale: 3.2,
                language: language));
            for (final key in ['openShop', 'openProgress']) {
              await _reachable(
                  tester, find.byKey(ValueKey(key)), window.safeRect);
            }
            await _openSceneMenu(tester, window.safeRect,
                menuKey: result ? 'resultMenu' : 'homeMenu');
            final rate = _menuItem(language == 'de' ? 'Bewerten' : 'Rate');
            await _reachable(tester, rate, window.safeRect);
            expect(MediaQuery.textScalerOf(tester.element(rate)).scale(16),
                16 * 3.2);
            await tester.tap(rate);
            await tester.pumpAndSettle();
            expect(rates, 1);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          }
        }
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('record results announce the best with large text in both modes',
      (tester) async {
    final window = _windows[1];
    _window(tester, window);
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    try {
      for (final hardcore in [false, true]) {
        await tester.pumpWidget(_host(tester,
            _gameOver(hardcore: hardcore, score: 43, best: 43, newBest: true),
            textScale: 3.2));
        final best = find.byKey(const ValueKey('resultBest'));
        await _reachable(tester, best, window.safeRect);
        final node = tester.getSemantics(best);
        expect(node.label, 'New personal best: 43');
        expect(node.flagsCollection.isLiveRegion, isTrue);
        expect(find.text('NEW BEST!'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('help teaches the rules without starting a game', (tester) async {
    _window(tester, _windows[3]);
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    try {
      var starts = 0;
      await tester.pumpWidget(_host(tester, _menu(onPlay: () => starts++)));
      await _chooseSceneAction(tester, 'How to play', _windows[3].safeRect);
      expect(
          tester
              .getSemantics(find.text('HOW TO PLAY'))
              .flagsCollection
              .isHeader,
          isTrue);
      expect(find.semantics.byLabel('PLAY').evaluate(), isEmpty);
      expect(find.text('Hold out, release in'), findsOneWidget);
      expect(find.textContaining('reverses your direction'), findsOneWidget);
      expect(find.textContaining('first hit'), findsOneWidget);
      expect(find.textContaining('Escape/P'), findsOneWidget);
      expect(starts, 0);
      if (const bool.fromEnvironment('GENERATE_HELP_EVIDENCE')) {
        final boundary =
            tester.renderObject<RenderRepaintBoundary>(find.byKey(_captureKey));
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          try {
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            final directory = Directory('docs/evidence/help-2026-10-23');
            await directory.create(recursive: true);
            await File('${directory.path}/how-to-play.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
          } finally {
            image.dispose();
          }
        });
      }
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('HOW TO PLAY'), findsNothing);
      expect(starts, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('menu selection, sound and enabled service callbacks work',
      (tester) async {
    _window(tester, _windows[8]);
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    final modes = <bool>[];
    final actions = <String>[];
    var hardcore = false;
    var muted = true;
    var signedIn = false;
    try {
      await tester.pumpWidget(_host(
        tester,
        StatefulBuilder(builder: (context, setState) {
          return _menu(
            hardcore: hardcore,
            muted: muted,
            signedIn: signedIn,
            onModeChanged: (value) {
              modes.add(value);
              setState(() => hardcore = value);
            },
            onPlay: () => actions.add('play'),
            onToggleSound: () {
              actions.add('sound');
              setState(() => muted = !muted);
            },
            onShare: () => actions.add('share'),
            onAchievements: () => actions.add('achievements'),
            onLeaderboard: () => actions.add('leaderboard'),
            onSignIn: () {
              actions.add('signIn');
              setState(() => signedIn = !signedIn);
            },
            onRate: () => actions.add('rate'),
          );
        }),
      ));
      bool selected(String key) =>
          tester
              .getSemantics(find.byKey(ValueKey(key)))
              .flagsCollection
              .isSelected ==
          ui.Tristate.isTrue;
      expect(selected('modeNormal'), isTrue);
      expect(selected('modeHardcore'), isFalse);
      for (final key in ['modeNormal', 'modeHardcore']) {
        expect(
            tester
                .getSemantics(find.byKey(ValueKey(key)))
                .getSemanticsData()
                .flagsCollection
                .isButton,
            isTrue,
            reason:
                'Mode, selected state and best must be one accessible button');
        expect(
            tester
                .getSemantics(find.byKey(ValueKey(key)))
                .getSemanticsData()
                .label,
            key == 'modeNormal' ? 'Normal' : 'Hardcore');
      }
      expect(
          tester.getSemantics(find.byKey(const ValueKey('modeNormal'))).value,
          'Personal best 42');
      expect(
          tester.getSemantics(find.byKey(const ValueKey('modeHardcore'))).value,
          'Personal best 17');
      expect(find.text('BEST  42'), findsOneWidget);
      expect(find.text('Health regenerates.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('modeHardcore')));
      await tester.pump();
      expect(selected('modeNormal'), isFalse);
      expect(selected('modeHardcore'), isTrue);
      expect(find.text('BEST  17'), findsOneWidget);
      expect(find.text('One hit. Game over.'), findsOneWidget);
      expect(actions, isEmpty, reason: 'Choosing a mode must not start a run');
      await tester.tap(find.byKey(const ValueKey('modeNormal')));
      await tester.pump();
      expect(modes, [true, false]);
      Focus.of(tester.element(find.text('Hardcore'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(modes, [true, false, true]);
      expect(selected('modeHardcore'), isTrue);
      expect(actions, isEmpty);

      for (final tooltip in [
        'Enable sound',
        'Mute sound',
      ]) {
        final control = find.byTooltip(tooltip);
        await _reachable(tester, control, _windows[8].safeRect);
        await tester.tap(control);
        await tester.pump();
      }
      for (final label in [
        'Share Atomic Orbital',
        'Achievements',
        'Leaderboard',
        'Sign in',
        'Disconnect Play Games',
        'Rate'
      ]) {
        await _chooseSceneAction(tester, label, _windows[8].safeRect);
      }
      await tester.ensureVisible(find.byKey(const ValueKey('startRun')));
      await tester.tap(find.byKey(const ValueKey('startRun')));
      await tester.pump();
      expect(actions, [
        'sound',
        'sound',
        'share',
        'achievements',
        'leaderboard',
        'signIn',
        'signIn',
        'rate',
        'play'
      ]);
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('result replay, home, sound and enabled services work',
      (tester) async {
    _window(tester, _windows[3]);
    addTearDown(tester.view.reset);
    final actions = <String>[];
    await tester.pumpWidget(_host(
        tester,
        _gameOver(
          onShop: () => actions.add('worlds'),
          onProgress: () => actions.add('progress'),
          onSettings: () => actions.add('settings'),
          onReplay: () => actions.add('replay'),
          onHome: () => actions.add('home'),
          onToggleSound: () => actions.add('sound'),
          onShare: () => actions.add('share'),
          onAchievements: () => actions.add('achievements'),
          onLeaderboard: () => actions.add('leaderboard'),
          onRate: () => actions.add('rate'),
        )));
    expect(find.byType(OutlinedButton), findsNWidgets(2));
    expect(find.text('Share score'), findsNothing);
    for (final key in ['replayRun', 'home', 'openShop', 'openProgress']) {
      final control = find.byKey(ValueKey(key));
      await _reachable(tester, control, _windows[3].safeRect);
      await tester.tap(control);
      await tester.pump();
    }
    final sound = find.byTooltip('Enable sound');
    await _reachable(tester, sound, _windows[3].safeRect);
    await tester.tap(sound);
    await tester.pump();
    for (final label in [
      'Share score',
      'Settings',
      'Achievements',
      'Leaderboard',
      'Rate'
    ]) {
      await _chooseSceneAction(tester, label, _windows[3].safeRect,
          menuKey: 'resultMenu');
    }
    expect(actions, [
      'replay',
      'home',
      'worlds',
      'progress',
      'sound',
      'share',
      'settings',
      'achievements',
      'leaderboard',
      'rate'
    ]);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('unavailable service controls are absent', (tester) async {
    _window(tester, _windows[3]);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(
        tester,
        _menu(
          gamesAvailable: false,
          onAchievements: _noop,
          onLeaderboard: _noop,
          onSignIn: _noop,
        )));
    expect(find.byType(PopupMenuItem<VoidCallback>), findsNothing);
    await _openSceneMenu(tester, _windows[3].safeRect);
    for (final label in [
      'Achievements',
      'Leaderboard',
      'Sign in',
      'Disconnect Play Games',
      'Rate'
    ]) {
      expect(_menuItem(label), findsNothing);
    }
    expect(_menuItem('Share Atomic Orbital'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Enable sound'), findsOneWidget);
    await tester.pumpWidget(_host(tester, _menu()));
    await _openSceneMenu(tester, _windows[3].safeRect);
    for (final label in [
      'Achievements',
      'Leaderboard',
      'Sign in',
      'Disconnect Play Games',
      'Rate'
    ]) {
      expect(_menuItem(label), findsNothing);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduced motion freezes decoration and can change at runtime',
      (tester) async {
    _window(tester, _windows[3]);
    addTearDown(tester.view.reset);
    final menu = _menu();
    await tester.pumpWidget(_host(tester, menu));
    await tester.pump();
    final still = await _pixels(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(await _pixels(tester), still);
    await tester.pumpWidget(_host(tester, menu, reduceMotion: false));
    await tester.pump();
    final moving = await _pixels(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(await _pixels(tester), isNot(moving));
    await tester.pumpWidget(_host(tester, menu));
    await tester.pump();
    final stopped = await _pixels(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(await _pixels(tester), stopped);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('arena animation crosses its loop without a visible jump',
      (tester) async {
    _window(tester, _windows[3]);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(tester, _menu(), reduceMotion: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 7970));
    final before = await _pixels(tester);
    await tester.pump(const Duration(milliseconds: 20));
    final nearEnd = await _pixels(tester);
    await tester.pump(const Duration(milliseconds: 20));
    final afterStart = await _pixels(tester);
    int difference(List<int> first, List<int> second) {
      var total = 0;
      for (var index = 0; index < first.length; index++) {
        total += (first[index] - second[index]).abs();
      }
      return total;
    }

    final ordinaryMotion = difference(before, nearEnd);
    final wrapMotion = difference(nearEnd, afterStart);
    expect(ordinaryMotion, greaterThan(100),
        reason: 'The test must observe real animated pixels');
    expect(wrapMotion, lessThan(ordinaryMotion * 1.2 + 512),
        reason: 'The 20 ms wrap transition must resemble ordinary motion; '
            'ordinary=$ordinaryMotion, wrap=$wrapMotion');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  if (const bool.fromEnvironment('GENERATE_MENU_EVIDENCE')) {
    final shots = <String, ({_Window window, Widget scene, double ratio})>{
      'phone-cow-menu': (
        window: _windows[3],
        scene: _menu(skin: GameSkin.cowAbduction, onShop: _noop),
        ratio: 3
      ),
      'phone-deep-blue-menu': (
        window: _windows[3],
        scene: _menu(skin: GameSkin.deepBlue, onShop: _noop),
        ratio: 3
      ),
      'phone-cow-result': (
        window: _windows[3],
        scene: _gameOver(
            skin: GameSkin.cowAbduction, score: 43, best: 43, newBest: true),
        ratio: 3
      ),
      'phone-normal': (
        window: _windows[3],
        scene: _menu(
            onAchievements: _noop,
            onLeaderboard: _noop,
            onSignIn: _noop,
            onRate: _noop),
        ratio: 3
      ),
      'phone-navigation': (
        window: _windows[3],
        scene: _menu(
            onAchievements: _noop,
            onLeaderboard: _noop,
            onSignIn: _noop,
            onRate: _noop),
        ratio: 3
      ),
      'phone-hardcore': (
        window: _windows[3],
        scene: _menu(
            hardcore: true,
            onAchievements: _noop,
            onLeaderboard: _noop,
            onSignIn: _noop,
            onRate: _noop),
        ratio: 3
      ),
      'tablet-landscape': (
        window: _windows[8],
        scene: _menu(
            onAchievements: _noop,
            onLeaderboard: _noop,
            onSignIn: _noop,
            onRate: _noop),
        ratio: 2
      ),
      'phone-game-over': (
        window: _windows[3],
        scene: _gameOver(
            hardcore: true,
            onAchievements: _noop,
            onLeaderboard: _noop,
            onRate: _noop),
        ratio: 3
      ),
      'phone-result': (window: _windows[3], scene: _gameOver(), ratio: 3),
      'phone-result-navigation': (
        window: _windows[3],
        scene: _gameOver(
            onAchievements: _noop, onLeaderboard: _noop, onRate: _noop),
        ratio: 3
      ),
      'phone-result-landscape': (
        window: _windows[9],
        scene: _gameOver(),
        ratio: 3
      ),
      'tablet-result': (
        window: _windows[8],
        scene: _gameOver(newBest: true, score: 43, best: 43),
        ratio: 2
      ),
      'phone-pending-reward': (
        window: _windows[3],
        scene: _gameOver(earned: 1, pending: true),
        ratio: 3
      ),
      'phone-landscape': (
        window: _windows[9],
        scene: _menu(
            onAchievements: _noop,
            onLeaderboard: _noop,
            onSignIn: _noop,
            onRate: _noop),
        ratio: 3
      ),
      'phone-apple-normal': (
        window: _windows[3],
        scene: _menu(gamesAvailable: false),
        ratio: 3
      ),
      'phone-result-equal-best': (
        window: _windows[3],
        scene: _gameOver(score: 42, best: 42),
        ratio: 3
      ),
      'phone-new-best': (
        window: _windows[3],
        scene: _gameOver(score: 43, best: 43, newBest: true),
        ratio: 2
      ),
      'phone-hardcore-new-best': (
        window: _windows[3],
        scene: _gameOver(hardcore: true, score: 43, best: 43, newBest: true),
        ratio: 2
      ),
    };
    for (final entry in shots.entries) {
      testWidgets('render evidence ${entry.key}', (tester) async {
        _window(tester, entry.value.window);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_host(tester, entry.value.scene));
        await tester.pump();
        if (entry.key == 'phone-navigation') {
          await _openSceneMenu(tester, entry.value.window.safeRect);
        }
        if (entry.key == 'phone-result-navigation') {
          await _openSceneMenu(tester, entry.value.window.safeRect,
              menuKey: 'resultMenu');
        }
        expect(tester.takeException(), isNull);
        final boundary =
            tester.renderObject<RenderRepaintBoundary>(find.byKey(_captureKey));
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: entry.value.ratio);
          try {
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            final directory = Directory(const String.fromEnvironment(
                'MENU_EVIDENCE_DIRECTORY',
                defaultValue: 'docs/evidence/arcade-menu-2026-10-22'));
            await directory.create(recursive: true);
            await File('${directory.path}/${entry.key}.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
          } finally {
            image.dispose();
          }
        });
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  if (const bool.fromEnvironment('GENERATE_MENU_MOTION')) {
    testWidgets('export actual arena loop and PLAY press feedback',
        (tester) async {
      _window(tester, _windows[3]);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(
          tester,
          _menu(
              onAchievements: _noop,
              onLeaderboard: _noop,
              onSignIn: _noop,
              onRate: _noop),
          reduceMotion: false));
      await tester.pump();
      final frames = await tester.runAsync(
          () => Directory.systemTemp.createTemp('atomic-arcade-motion-'));
      TestGesture? press;
      for (var frame = 0; frame < 128; frame++) {
        // Hold PLAY for half a second, then release. The preview callback is a
        // no-op, so the production button feedback remains in the menu scene.
        if (frame == 104) {
          press = await tester.startGesture(
              tester.getCenter(find.byKey(const ValueKey('startRun'))));
        } else if (frame == 112) {
          await press!.up();
        }
        if (frame > 0) {
          await tester.pump(const Duration(microseconds: 62500));
        }
        final boundary =
            tester.renderObject<RenderRepaintBoundary>(find.byKey(_captureKey));
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          try {
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            await File(
                    '${frames!.path}/frame-${frame.toString().padLeft(3, '0')}.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
          } finally {
            image.dispose();
          }
        });
      }
      await tester.runAsync(() async {
        final output = Directory(const String.fromEnvironment(
            'MENU_EVIDENCE_DIRECTORY',
            defaultValue: 'docs/evidence/arcade-menu-2026-10-22'));
        await output.create(recursive: true);
        final result = await Process.run('ffmpeg', [
          '-hide_banner',
          '-loglevel',
          'error',
          '-y',
          '-framerate',
          '16',
          '-i',
          '${frames!.path}/frame-%03d.png',
          '-filter_complex',
          '[0:v]split[a][b];[a]palettegen=max_colors=96:stats_mode=diff[p];'
              '[b][p]paletteuse=dither=sierra2_4a',
          '-loop',
          '0',
          '${output.path}/menu-motion.gif',
        ]);
        expect(result.exitCode, 0, reason: result.stderr.toString());
        await frames.delete(recursive: true);
      });
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
