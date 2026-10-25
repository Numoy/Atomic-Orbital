import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:atomic_orbital/constants/game_constants.dart';
import 'package:atomic_orbital/game/game_engine.dart';
import 'package:atomic_orbital/game/game_screen.dart';
import 'package:atomic_orbital/game/original_text.dart';
import 'package:atomic_orbital/game/progress_screen.dart';
import 'package:atomic_orbital/l10n/strings.dart';
import 'package:atomic_orbital/main.dart';
import 'package:atomic_orbital/models/components.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Store exports use production widgets and unmodified, seeded controller runs.
// Only normal hold/release input is supplied; no entity or collision edits.
void _input(GameEngine engine) {
  final player = engine.player.logic as PlayerLogicComponent;
  final energy = engine.energy.logic as EnergyLogicComponent;
  final target = engine.orbits[energy.onOrbit].radius;
  if (player.currentRadius + player.speedRadius * 2 < target) {
    engine.onTouchDown();
  } else {
    engine.onTouchUp();
  }
}

class _Run {
  const _Run(this.seed, this.frames, this.hardcore, this.score);
  final int seed;
  final int frames;
  final bool hardcore;
  final int score;

  GameEngine replay() {
    final engine = GameEngine(random: math.Random(seed))
      ..startGame(hardcore: hardcore);
    for (var frame = 0; frame < frames; frame++) {
      _input(engine);
      engine.advanceFrame();
    }
    return engine;
  }
}

bool _clearScene(GameEngine engine) {
  final player = engine.player.position.position;
  final energy = engine.energy.position.position;
  if ((player - energy).magnitude < 140) return false;
  final visible = engine.photons.where((photon) {
    final point = photon.position.position;
    final logic = photon.logic as PhotonLogicComponent;
    return logic.radius > 10 &&
        point.x > 25 &&
        point.x < 1055 &&
        point.y > 100 &&
        point.y < 1740 &&
        (point - engine.atom.position.position).magnitude > 175;
  });
  return engine.backgroundRed == 0 && visible.length >= 3;
}

List<_Run> _findRuns(bool hardcore) {
  _Run? early;
  _Run? later;
  _Run? over;
  var best = 0;
  for (var seed = 1; seed <= 200; seed++) {
    final engine = GameEngine(random: math.Random(seed))
      ..startGame(hardcore: hardcore);
    for (var frame = 1; frame <= 5400; frame++) {
      _input(engine);
      engine.advanceFrame();
      best = math.max(best, engine.score);
      if (engine.state == GameState.gameOver) {
        if (engine.score >= 4 && (over == null || engine.score > over.score)) {
          over = _Run(seed, frame, hardcore, engine.score);
        }
        break;
      }
      if (engine.score >= 2 && _clearScene(engine)) {
        early ??= _Run(seed, frame, hardcore, engine.score);
        if (engine.score >= 14) {
          later ??= _Run(seed, frame, hardcore, engine.score);
        }
      }
    }
    engine.dispose();
    if (early != null && later != null && over != null) break;
  }
  expect(early, isNotNull,
      reason: 'Need actual populated gameplay; best=$best');
  if (!hardcore) {
    expect(later, isNotNull, reason: 'Need a later actual run; best=$best');
    expect(over, isNotNull, reason: 'Need a real completed run; best=$best');
  }
  return [early!, if (later != null) later, if (over != null) over];
}

void main() {
  if (!const bool.fromEnvironment('GENERATE_STORE_SCREENSHOTS')) return;
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<_Run> normal;
  late List<_Run> hardcore;
  setUpAll(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    SharedPreferences.setMockInitialValues({});
    await SettingsService.initialize();
    await (FontLoader('Roboto')
          ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    normal = _findRuns(false);
    hardcore = _findRuns(true);
    await SettingsService.instance.resetSettings();
    SettingsService.instance.setHighScore(normal.last.score);
    SettingsService.instance.setHighScore(hardcore.last.score, hardcore: true);
    final manifest = <String, Object>{};
    for (final entry in {
      'normal': normal.first,
      'normal-later': normal[1],
      'hardcore': hardcore.first,
      'result': normal.last,
    }.entries) {
      final run = entry.value;
      manifest[entry.key] = {
        'seed': run.seed,
        'frames': run.frames,
        'hardcore': run.hardcore,
        'score': run.score,
        'input': 'Hold/release steers toward the current energy orbit; '
            'production controllers and collisions are unchanged.',
      };
    }
    await Directory(_root).create(recursive: true);
    await File('$_root/fixtures.json')
        .writeAsString(const JsonEncoder.withIndent('  ').convert(manifest));
    debugDefaultTargetPlatformOverride = null;
  });

  for (final locale in ['en', 'de']) {
    for (final target in _targets) {
      for (final scene in [
        '01-normal',
        '02-hardcore',
        '03-progress',
        '04-menu',
        '05-results'
      ]) {
        testWidgets('store screenshot $locale/${target.name}/$scene',
            (tester) async {
          debugDefaultTargetPlatformOverride = target.platform;
          addTearDown(() => debugDefaultTargetPlatformOverride = null);
          _setWindow(tester, target);
          addTearDown(tester.view.reset);
          final run = switch (scene) {
            '01-normal' => normal.first,
            '02-hardcore' => hardcore.first,
            '03-normal-later' => normal[1],
            '05-results' => normal.last,
            _ => null,
          };
          final engine = run?.replay() ?? GameEngine(random: math.Random(1));
          await tester.pumpWidget(_host(
              scene == '03-progress'
                  ? const ProgressScreen(cosmeticsEnabled: true)
                  : GameScreen(
                      cosmeticsEnabled: true,
                      engine: engine,
                      textCache: OriginalTextCache(enabled: false)),
              language: locale));
          await tester.pump();
          expect(tester.takeException(), isNull);
          if (run != null) {
            expect(engine.score, run.score);
            expect(engine.state,
                scene == '05-results' ? GameState.gameOver : GameState.playing);
          } else if (scene == '04-menu') {
            expect(find.text('ATOMIC'), findsOneWidget);
            expect(
                find.text(locale == 'en' ? 'PLAY' : 'SPIELEN'), findsOneWidget);
          }
          await _export(tester, '$_root/raw/$locale/${target.name}/$scene.png',
              target.ratio);
          await tester.pumpWidget(const SizedBox.shrink());
          debugDefaultTargetPlatformOverride = null;
        });
      }
    }
  }

  testWidgets('store feature graphic uses current title and actual arena',
      (tester) async {
    _setWindow(tester,
        const _Target('feature', Size(1024, 500), 1, TargetPlatform.iOS));
    addTearDown(tester.view.reset);
    final engine = normal.first.replay();
    addTearDown(engine.dispose);
    await tester.pumpWidget(_host(_FeatureGraphic(engine)));
    expect(find.text('ATOMIC'), findsOneWidget);
    expect(find.text('ORBITAL'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _export(tester, '$_root/raw/feature-1024x500.png', 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

const _root = String.fromEnvironment('STORE_ASSET_DIRECTORY',
    defaultValue: 'store-assets/2026-10-22');
const _capture = ValueKey('storeCapture');

class _Target {
  const _Target(this.name, this.size, this.ratio, this.platform,
      {this.padding = EdgeInsets.zero});
  final String name;
  final Size size;
  final double ratio;
  final TargetPlatform platform;
  final EdgeInsets padding;
}

const _targets = [
  _Target('google-play-phone', Size(1080 / 2.625, 1920 / 2.625), 2.625,
      TargetPlatform.android,
      padding: EdgeInsets.symmetric(vertical: 24)),
  _Target('google-play-tablet', Size(960, 540), 2, TargetPlatform.android,
      padding: EdgeInsets.symmetric(vertical: 24)),
  _Target('app-store-iphone-medium', Size(393, 852), 3, TargetPlatform.iOS,
      padding: EdgeInsets.only(top: 59, bottom: 34)),
  _Target('app-store-iphone-large', Size(440, 956), 3, TargetPlatform.iOS,
      padding: EdgeInsets.only(top: 62, bottom: 34)),
  _Target('app-store-ipad-13', Size(1366, 1024), 2, TargetPlatform.iOS,
      padding: EdgeInsets.only(top: 24, bottom: 20)),
];
void _setWindow(WidgetTester tester, _Target target) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = target.size
    ..padding = FakeViewPadding(
        top: target.padding.top,
        bottom: target.padding.bottom,
        left: target.padding.left,
        right: target.padding.right);
}

Widget _host(Widget screen, {String language = 'en'}) => RepaintBoundary(
      key: _capture,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AtomicOrbitalApp.themeData,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!),
        home: screen,
      ),
    );

Future<void> _export(WidgetTester tester, String path, double ratio) async {
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_capture));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: ratio);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

class _FeatureGraphic extends StatelessWidget {
  const _FeatureGraphic(this.engine);
  final GameEngine engine;
  @override
  Widget build(BuildContext context) => Material(
        color: GameConstants.backgroundColor,
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _FeatureArena(engine))),
          const Positioned(
              left: 48,
              top: 152,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ATOMIC',
                      style: TextStyle(
                          color: GameConstants.atomColor,
                          fontFamily: 'Roboto',
                          fontSize: 64,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 5,
                          height: .95)),
                  SizedBox(height: 6),
                  Text('ORBITAL',
                      style: TextStyle(
                          color: GameConstants.normalAccent,
                          fontFamily: 'Roboto',
                          fontSize: 90,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          height: .95)),
                ],
              )),
        ]),
      );
}

class _FeatureArena extends CustomPainter {
  const _FeatureArena(this.engine);
  final GameEngine engine;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(545, 0, 479, 500));
    canvas.translate(
        782 - engine.width / 2 * .42, 250 - engine.height / 2 * .42);
    canvas.scale(.42);
    GamePainter(engine).paint(canvas, const Size(1080, 1794));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FeatureArena oldDelegate) => false;
}
