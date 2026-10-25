import 'dart:math';
import 'dart:ui' as ui;

import 'package:atomic_orbital/game/game_engine.dart';
import 'package:atomic_orbital/game/game_screen.dart';
import 'package:atomic_orbital/game/original_text.dart';
import 'package:atomic_orbital/models/components.dart';
import 'package:atomic_orbital/models/vector2d.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Released reference: 1080 physical pixels wide, 1794 visible Canvas pixels.
const _referenceFrame = Size(1080 / 2.625, 1794 / 2.625);
const _viewportKey = ValueKey('gameViewport');
const _captureKey = ValueKey('capture');
const _hardcoreKey = ValueKey('modeHardcore');
const _startKey = ValueKey('startRun');
const _replayKey = ValueKey('replayRun');
const _homeKey = ValueKey('home');

class _DeviceCase {
  const _DeviceCase(this.name, this.size, this.ratio,
      {this.padding = EdgeInsets.zero,
      this.fontScale = 1,
      this.platform = TargetPlatform.iOS});

  final String name;
  final Size size;
  final double ratio;
  final EdgeInsets padding;
  final double fontScale;
  final TargetPlatform platform;

  Rect get safeRect => Rect.fromLTRB(padding.left, padding.top,
      size.width - padding.right, size.height - padding.bottom);
}

const _devices = [
  _DeviceCase(
      'released Android reference', Size(1080 / 2.625, 1920 / 2.625), 2.625,
      padding: EdgeInsets.symmetric(vertical: 24),
      platform: TargetPlatform.android),
  _DeviceCase('narrow phone', Size(320, 568), 2,
      padding: EdgeInsets.only(top: 20)),
  _DeviceCase('tall Android phone', Size(360, 800), 3,
      padding: EdgeInsets.symmetric(vertical: 24),
      platform: TargetPlatform.android),
  _DeviceCase('iPhone cutout', Size(393, 852), 3,
      padding: EdgeInsets.only(top: 59, bottom: 34)),
  _DeviceCase('wide phone', Size(430, 932), 3,
      padding: EdgeInsets.only(top: 59, bottom: 34)),
  _DeviceCase('four by three tablet', Size(768, 1024), 2,
      padding: EdgeInsets.only(top: 24, bottom: 20)),
  _DeviceCase('tall tablet', Size(834, 1194), 2,
      padding: EdgeInsets.only(top: 24, bottom: 20)),
  _DeviceCase('large tablet', Size(1024, 1366), 2,
      padding: EdgeInsets.only(top: 24, bottom: 20)),
  _DeviceCase('landscape tablet', Size(1366, 1024), 2,
      padding: EdgeInsets.only(top: 24, bottom: 20)),
  _DeviceCase('landscape cutout phone', Size(852, 393), 3,
      padding: EdgeInsets.only(left: 59, right: 59, bottom: 21)),
  _DeviceCase('narrow split screen', Size(256, 1024), 2,
      padding: EdgeInsets.only(top: 24, bottom: 20)),
  _DeviceCase('square split screen', Size(600, 600), 2,
      padding: EdgeInsets.only(top: 24, bottom: 20)),
  _DeviceCase('large font narrow phone', Size(320, 568), 2,
      padding: EdgeInsets.only(top: 20), fontScale: 3.2),
];

void _setDevice(WidgetTester tester, _DeviceCase device) {
  final padding = FakeViewPadding(
      left: device.padding.left * device.ratio,
      top: device.padding.top * device.ratio,
      right: device.padding.right * device.ratio,
      bottom: device.padding.bottom * device.ratio);
  tester.view
    ..physicalSize = Size(
        device.size.width * device.ratio, device.size.height * device.ratio)
    ..devicePixelRatio = device.ratio
    ..viewPadding = padding
    ..padding = padding;
}

Widget _host(WidgetTester tester, _DeviceCase device, GameEngine engine,
        OriginalTextCache cache) =>
    RepaintBoundary(
      key: _captureKey,
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQueryData.fromView(tester.view)
              .copyWith(textScaler: TextScaler.linear(device.fontScale)),
          child: child!,
        ),
        home: GameScreen(
            key: const ValueKey('screen'), engine: engine, textCache: cache),
      ),
    );

Rect _globalRect(WidgetTester tester, Finder finder) {
  final box = tester.renderObject<RenderBox>(finder);
  return Rect.fromPoints(box.localToGlobal(Offset.zero),
      box.localToGlobal(Offset(box.size.width, box.size.height)));
}

Rect _expectedFrame(_DeviceCase device) {
  final safe = device.safeRect;
  final scale = min(
      safe.width / _referenceFrame.width, safe.height / _referenceFrame.height);
  final size = _referenceFrame * scale;
  return Rect.fromCenter(
      center: safe.center, width: size.width, height: size.height);
}

void _expectInside(Rect child, Rect parent) {
  const epsilon = 0.001;
  expect(child.left, greaterThanOrEqualTo(parent.left - epsilon));
  expect(child.top, greaterThanOrEqualTo(parent.top - epsilon));
  expect(child.right, lessThanOrEqualTo(parent.right + epsilon));
  expect(child.bottom, lessThanOrEqualTo(parent.bottom + epsilon));
}

Rect _expectFrame(WidgetTester tester, _DeviceCase device) {
  final actual = _globalRect(tester, find.byKey(_viewportKey));
  final expected = _expectedFrame(device);
  expect(actual.left, closeTo(expected.left, 0.001));
  expect(actual.top, closeTo(expected.top, 0.001));
  expect(actual.width, closeTo(expected.width, 0.001));
  expect(actual.height, closeTo(expected.height, 0.001));
  expect(actual.width / actual.height, closeTo(1080 / 1794, 1e-10));
  _expectInside(actual, device.safeRect);
  return actual;
}

Finder get _gamePaint => find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.painter is GamePainter);

Offset _holdPoint(_DeviceCase device, Rect frame) {
  final safe = device.safeRect;
  if (frame.left - safe.left > 1) {
    return Offset((safe.left + frame.left) / 2, safe.center.dy);
  }
  if (frame.top - safe.top > 1) {
    return Offset(safe.center.dx, (safe.top + frame.top) / 2);
  }
  return frame.center;
}

Map<String, Object?> _snapshot(GameEngine engine) {
  final player = engine.player.logic as PlayerLogicComponent;
  final energy = engine.energy.logic as EnergyLogicComponent;
  return {
    'world': [engine.width, engine.height],
    'state': engine.state,
    'score': engine.score,
    'health': engine.health,
    'time': engine.gameTime,
    'flash': engine.backgroundRed,
    'player': [
      player.currentAngle,
      player.currentRadius,
      player.speedRadius,
      player.direction,
      player.isTouching,
    ],
    'energy': [energy.onOrbit, energy.angle, energy.rotation],
    'orbits': [
      for (final orbit in engine.orbits)
        [orbit.radius, orbit.rotation, orbit.direction]
    ],
    'entities': [
      for (final entity in engine.entities)
        [
          entity.id,
          entity.type,
          entity.position.position.x,
          entity.position.position.y,
          entity.size.radius,
          if (entity.logic case final PhotonLogicComponent photon) ...[
            photon.polarRadius,
            photon.polarAngle,
            photon.radius,
            photon.growing,
          ],
        ]
    ],
  };
}

void _hardcoreDeath(GameEngine engine) {
  engine.onTouchDown();
  engine.advanceFrame();
  engine.onTouchUp();
  engine.photons.single.position
      .setPosition(engine.player.position.position.copy());
  engine.advanceFrame();
  expect(engine.state, GameState.gameOver);
}

Future<void> _unmount(WidgetTester tester) async {
  try {
    await tester.pumpWidget(const SizedBox.shrink());
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.initialize();
    await (FontLoader('Roboto')
          ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Roboto-Medium.ttf')))
        .load();
  });
  setUp(() => SettingsService.instance.resetSettings());

  for (final device in _devices) {
    testWidgets('${device.name}: adaptive menus and fixed gameplay world',
        (tester) async {
      debugDefaultTargetPlatformOverride = device.platform;
      _setDevice(tester, device);
      addTearDown(tester.view.reset);
      final engine = GameEngine(random: Random(7));
      final cache = OriginalTextCache(enabled: false);
      try {
        await tester.pumpWidget(_host(tester, device, engine, cache));
        expect(find.byKey(_viewportKey), findsNothing);
        expect(engine.width, 1080);
        expect(engine.height, 1857);
        await tester.ensureVisible(find.byKey(_hardcoreKey));
        final modeBounds = _globalRect(tester, find.byKey(_hardcoreKey));
        expect(modeBounds.left, greaterThanOrEqualTo(device.safeRect.left));
        expect(modeBounds.right, lessThanOrEqualTo(device.safeRect.right));
        expect(modeBounds.intersect(device.safeRect).height,
            greaterThanOrEqualTo(44));
        expect(find.byKey(_hardcoreKey).hitTestable(), findsOneWidget);
        await tester.tap(find.byKey(_hardcoreKey));
        await tester.pump();
        await tester.ensureVisible(find.byKey(_startKey));
        _expectInside(
            _globalRect(tester, find.byKey(_startKey)), device.safeRect);
        await tester.tap(find.byKey(_startKey));
        await tester.pump();
        _expectFrame(tester, device);
        expect(engine.state, GameState.ready);
        expect(engine.hardcore, isTrue);
        final painter =
            tester.widget<CustomPaint>(_gamePaint).painter! as GamePainter;
        expect(painter.gameEngine, same(engine));
        expect(painter.devicePixelRatio, 2.625);
        expect(tester.getSize(_gamePaint), _referenceFrame);
        expect(
            MediaQuery.textScalerOf(tester.element(_gamePaint)).scale(70), 70,
            reason: 'Fixed game art must keep the same world geometry');

        final pause = find.byTooltip('Pause game');
        _expectInside(_globalRect(tester, pause), device.safeRect);
        expect(tester.getSize(pause).shortestSide, greaterThanOrEqualTo(48));
        await tester.tap(pause);
        await tester.pump();
        expect(engine.state, GameState.paused);
        _expectFrame(tester, device);
        expect(find.text('Hardcore · Score 0'), findsOneWidget);
        final help = find.byTooltip('How to play');
        await tester.ensureVisible(help);
        await tester.tap(help);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(engine.state, GameState.paused);
        expect(
            MediaQuery.textScalerOf(tester.element(find.text('HOW TO PLAY')))
                .scale(16),
            16 * device.fontScale);
        final close = find.byKey(const ValueKey('closeHelp'));
        await tester.ensureVisible(close);
        expect(close.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(close);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(engine.state, GameState.paused);
        final resume = find.byKey(const ValueKey('resumeRun'));
        await tester.ensureVisible(resume);
        expect(resume.hitTestable(), findsOneWidget);
        expect(tester.getSize(resume).height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
        await tester.tap(resume);
        await tester.pump();
        expect(engine.state, GameState.ready);
        _expectFrame(tester, device);

        _hardcoreDeath(engine);
        await tester.pump();
        await tester.ensureVisible(find.byKey(_replayKey));
        _expectInside(
            _globalRect(tester, find.byKey(_replayKey)), device.safeRect);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(_replayKey));
        await tester.pump();
        expect(engine.state, GameState.ready);
        expect(engine.score, 0);
        _expectFrame(tester, device);
        _hardcoreDeath(engine);
        await tester.pump();
        await tester.ensureVisible(find.byKey(_homeKey));
        _expectInside(
            _globalRect(tester, find.byKey(_homeKey)), device.safeRect);
        await tester.tap(find.byKey(_homeKey));
        await tester.pump();
        expect(engine.state, GameState.menu);
        expect(find.byKey(_viewportKey), findsNothing);
      } finally {
        await _unmount(tester);
      }
    });
  }

  testWidgets('equal hold/release time has identical results on every device',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(tester.view.reset);
    Map<String, Object?>? reference;
    try {
      for (final device in _devices) {
        _setDevice(tester, device);
        final engine = GameEngine(random: Random(83));
        final cache = OriginalTextCache(enabled: false);
        await tester.pumpWidget(_host(tester, device, engine, cache));
        await tester.ensureVisible(find.byKey(_startKey));
        await tester.tap(find.byKey(_startKey));
        await tester.pump();
        final frame = _expectFrame(tester, device);
        final gesture =
            await tester.startGesture(_holdPoint(device, frame), pointer: 5);
        await tester.pump(const Duration(milliseconds: 500));
        expect(engine.state, GameState.playing, reason: device.name);
        expect((engine.player.logic as PlayerLogicComponent).isTouching, isTrue,
            reason: 'Letterbox bars accept the same hold: ${device.name}');
        await gesture.moveTo(frame.topLeft + const Offset(3, 3));
        await tester.pump(const Duration(milliseconds: 250));
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 250));
        final state = _snapshot(engine);
        reference ??= state;
        expect(state, reference, reason: device.name);
        expect(engine.gameTime, closeTo(1, 1e-10));
        await tester.pumpWidget(const SizedBox.shrink());
      }
    } finally {
      await _unmount(tester);
    }
  });

  testWidgets(
      'resize, DPR and inset changes preserve a live damaged scored world',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(tester.view.reset);
    final engine = GameEngine(random: Random(9))..startGame();
    engine.onTouchDown();
    engine.advanceFrame();
    engine.onTouchUp();
    final player = engine.player.logic as PlayerLogicComponent;
    player
      ..speedOrbit = 0
      ..currentAngle = 0
      ..currentRadius = player.minRadius
      ..speedRadius = 0;
    player.positionPlayer(engine.player);
    (engine.energy.logic as EnergyLogicComponent)
      ..onOrbit = 0
      ..angle = 0;
    engine.advanceFrame();
    engine.photons.single.position
        .setPosition(engine.player.position.position.copy());
    engine.advanceFrame();
    for (var tick = 0; tick < 105; tick++) {
      engine.advanceFrame();
    }
    expect(engine.score, 1);
    expect(engine.health, lessThan(100));
    expect(engine.photons, isNotEmpty);
    final cache = OriginalTextCache(enabled: false);
    try {
      _setDevice(tester, _devices[3]);
      await tester.pumpWidget(_host(tester, _devices[3], engine, cache));
      final before = _snapshot(engine);
      final entities = engine.entities;
      for (final device in [
        _devices[8],
        _devices[10],
        _devices[12],
        _devices[0]
      ]) {
        _setDevice(tester, device);
        await tester.pumpWidget(_host(tester, device, engine, cache));
        _expectFrame(tester, device);
        expect(_snapshot(engine), before, reason: device.name);
        expect(engine.entities, orderedEquals(entities), reason: device.name);
        expect(tester.takeException(), isNull);
      }
      final releasedState = _snapshot(engine);
      final held = await tester.startGesture(
          _holdPoint(_devices[0], _expectFrame(tester, _devices[0])));
      expect(player.isTouching, isTrue);
      _setDevice(tester, _devices[3]);
      await tester.pumpWidget(_host(tester, _devices[3], engine, cache));
      expect(player.isTouching, isFalse,
          reason: 'A changed window cancels the old physical pointer safely');
      expect(_snapshot(engine), releasedState);
      await held.up();
    } finally {
      await _unmount(tester);
    }
  });

  testWidgets(
      'wide-screen bars never reveal photons outside the reference view',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    const device = _DeviceCase('wide field test', Size(1366, 1024), 2,
        padding: EdgeInsets.only(top: 24, bottom: 20));
    _setDevice(tester, device);
    addTearDown(tester.view.reset);
    final engine = GameEngine(random: Random(6))..startGame();
    engine.onTouchDown();
    engine.advanceFrame();
    engine.onTouchUp();
    final photon = engine.photons.single;
    (photon.logic as PhotonLogicComponent).radius = 35;
    final cache = OriginalTextCache(enabled: false);
    try {
      await tester.pumpWidget(_host(tester, device, engine, cache));
      final frame = _expectFrame(tester, device);
      Future<List<int>> sample(Offset world) async {
        photon.position.setPosition(Vector2D(world.dx, world.dy));
        await tester.pumpWidget(_host(tester, device, engine, cache));
        final boundary =
            tester.renderObject<RenderRepaintBoundary>(find.byKey(_captureKey));
        return (await tester.runAsync(() async {
          final image = await boundary.toImage();
          try {
            final pixels = (await image.toByteData())!;
            final point = Offset(frame.left + world.dx / 1080 * frame.width,
                frame.top + world.dy / 1794 * frame.height);
            final offset =
                (point.dy.floor() * image.width + point.dx.floor()) * 4;
            return [for (var i = 0; i < 4; i++) pixels.getUint8(offset + i)];
          } finally {
            image.dispose();
          }
        }))!;
      }

      expect(await sample(const Offset(900, 400)), [255, 79, 100, 255],
          reason: 'The real photon must first be visible inside the scene');
      expect(await sample(const Offset(1200, 400)), [8, 13, 20, 255],
          reason:
              'A wider display must not reveal additional world coordinates');
    } finally {
      await _unmount(tester);
    }
  });

  test('painting ready and active games cannot change simulation state', () {
    for (final hardcore in [false, true]) {
      final engine = GameEngine(random: Random(83))
        ..startGame(hardcore: hardcore);
      for (final playing in [false, true]) {
        if (playing) {
          engine.onTouchDown();
          for (var i = 0; i < 140; i++) {
            engine.advanceFrame();
          }
        }
        final before = _snapshot(engine);
        final presentation = [
          engine.fps,
          engine.startAlpha,
          engine.scoreTextX,
          engine.scoreTextY
        ];
        for (var paint = 0; paint < 3; paint++) {
          final recorder = ui.PictureRecorder();
          GamePainter(engine, devicePixelRatio: 2.625)
              .paint(Canvas(recorder), _referenceFrame);
          recorder.endRecording().dispose();
        }
        expect(_snapshot(engine), before);
        expect([
          engine.fps,
          engine.startAlpha,
          engine.scoreTextX,
          engine.scoreTextY
        ], presentation);
      }
      engine.dispose();
    }
  });

  testWidgets('repeated resizing preserves elapsed simulation time',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(tester.view.reset);
    Future<Map<String, Object?>> trace({required bool resize}) async {
      final engine = GameEngine(random: Random(83))..startGame();
      engine.onTouchDown();
      engine.advanceFrame();
      engine.onTouchUp();
      final initialTime = engine.gameTime;
      final cache = OriginalTextCache(enabled: false);
      _setDevice(tester, _devices[3]);
      await tester.pumpWidget(_host(tester, _devices[3], engine, cache));
      await tester.pump(); // Establish the ticker's zero-time first callback.
      for (var chunk = 0; chunk < 10; chunk++) {
        final device = resize ? _devices[chunk % _devices.length] : _devices[3];
        if (resize) _setDevice(tester, device);
        await tester.pumpWidget(_host(tester, device, engine, cache),
            duration: const Duration(milliseconds: 100));
      }
      expect(engine.gameTime - initialTime, closeTo(1, 1e-10));
      final result = _snapshot(engine);
      await tester.pumpWidget(const SizedBox.shrink());
      return result;
    }

    try {
      final unchangedWindow = await trace(resize: false);
      expect(await trace(resize: true), unchangedWindow,
          reason: 'Window metrics must not discard elapsed ticker intervals');
    } finally {
      await _unmount(tester);
    }
  });

  testWidgets('Apple controls share the selected best and current run scores',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final device = _devices[3];
    _setDevice(tester, device);
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    const platform = MethodChannel('atomic_orbital/platform');
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(platform,
        (call) async {
      calls.add(call);
      return null;
    });
    SettingsService.instance
      ..setHighScore(42)
      ..setHighScore(17, hardcore: true);
    final engine = GameEngine(random: Random(7));
    final cache = OriginalTextCache(enabled: false);
    try {
      await tester.pumpWidget(_host(tester, device, engine, cache));

      Future<void> openMenu() async {
        final menu = find.byKey(const ValueKey('homeMenu'));
        await tester.ensureVisible(menu);
        await tester.tap(menu);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      }

      Future<void> shareFromHome() async {
        await openMenu();
        await tester.tap(find.text('Share Atomic Orbital'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      }

      await openMenu();
      for (final label in ['Achievements', 'Leaderboard', 'Sign in']) {
        expect(find.widgetWithText(PopupMenuItem<VoidCallback>, label),
            findsOneWidget);
      }
      expect(find.text('Share Atomic Orbital'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.ensureVisible(find.byTooltip('Enable sound'));
      await tester.tap(find.byTooltip('Enable sound'));
      await tester.pump();
      expect(SettingsService.instance.isMuted, isFalse);
      await tester.tap(find.byTooltip('Mute sound'));
      await tester.pump();
      expect(SettingsService.instance.isMuted, isTrue);

      await shareFromHome();
      expect(calls.last.method, 'share');
      expect(calls.last.arguments, {
        'score': 42,
        'hardcore': false,
        'message': 'I got 42 points in Atomic Orbital. Can you do better?'
      });
      await tester.ensureVisible(find.byKey(_hardcoreKey));
      await tester.tap(find.byKey(_hardcoreKey));
      await tester.pump();
      await shareFromHome();
      expect(calls.last.arguments, {
        'score': 17,
        'hardcore': true,
        'message': 'I got 17 points in Atomic Orbital. Can you do better?'
      });

      await tester.ensureVisible(find.byKey(_startKey));
      await tester.tap(find.byKey(_startKey));
      await tester.pump();
      engine.onTouchDown();
      engine.advanceFrame();
      engine.onTouchUp();
      final player = engine.player.logic as PlayerLogicComponent;
      player
        ..speedOrbit = 0
        ..currentAngle = 0
        ..currentRadius = player.minRadius
        ..speedRadius = 0;
      player.positionPlayer(engine.player);
      (engine.energy.logic as EnergyLogicComponent)
        ..onOrbit = 0
        ..angle = 0;
      engine.advanceFrame();
      engine.photons.single.position
          .setPosition(engine.player.position.position.copy());
      engine.advanceFrame();
      expect(engine.state, GameState.gameOver);
      expect(engine.score, 1);
      expect(SettingsService.instance.hardcoreHighScore, 17);
      await tester.pump();
      for (final label in ['Rate', 'Leaderboard', 'NO ADS']) {
        expect(find.text(label), findsNothing);
      }
      expect(find.byTooltip('Enable sound'), findsOneWidget);
      expect(find.byKey(_homeKey), findsOneWidget);
      final resultMenu = find.byKey(const ValueKey('resultMenu'));
      await tester.ensureVisible(resultMenu);
      await tester.tap(resultMenu);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.widgetWithText(PopupMenuItem<VoidCallback>, 'Rate'),
          findsNothing);
      await tester.tap(find.text('Share score'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(calls.last.method, 'share');
      expect(calls.last.arguments, {
        'score': 1,
        'hardcore': true,
        'message': 'I got 1 point in Atomic Orbital. Can you do better?'
      });
      expect(calls.where((call) => call.method == 'share'), hasLength(3),
          reason: 'The test records native share requests without a recipient');
    } finally {
      await _unmount(tester);
      semantics.dispose();
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(platform, null);
    }
  });

  testWidgets('keyboard and touch share one hold, focus loss releases it',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final device = _devices[8];
    _setDevice(tester, device);
    addTearDown(tester.view.reset);
    final engine = GameEngine(random: Random(5));
    final cache = OriginalTextCache(enabled: false);
    try {
      await tester.pumpWidget(_host(tester, device, engine, cache));
      await tester.ensureVisible(find.byKey(_startKey));
      await tester.tap(find.byKey(_startKey));
      await tester.pump();
      final player = engine.player.logic as PlayerLogicComponent;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.space);
      await tester.pump(const Duration(milliseconds: 67));
      expect(engine.state, GameState.playing);
      expect(player.isTouching, isTrue);
      final gesture = await tester.startGesture(
          _holdPoint(device, _expectFrame(tester, device)),
          pointer: 3);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      expect(player.isTouching, isTrue,
          reason: 'Releasing a key must not release an active finger');
      await gesture.up();
      expect(player.isTouching, isFalse);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      expect(player.isTouching, isTrue);
      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pump();
      expect(player.isTouching, isFalse);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    } finally {
      await _unmount(tester);
    }
  });

  testWidgets('Tab and Space activate focused menu controls without starting',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final device = _devices[8];
    _setDevice(tester, device);
    addTearDown(tester.view.reset);
    final engine = GameEngine(random: Random(5));
    final cache = OriginalTextCache(enabled: false);
    try {
      await tester.pumpWidget(_host(tester, device, engine, cache));
      await tester.pump();
      final hardcoreText = find.descendant(
          of: find.byKey(_hardcoreKey), matching: find.text('Hardcore'));
      final modeFocus = Focus.of(tester.element(hardcoreText));
      modeFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(modeFocus.hasPrimaryFocus, isFalse);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(modeFocus.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(engine.state, GameState.menu,
          reason: 'The ancestor gameplay listener must defer to menu buttons');

      final soundIcon = find.descendant(
          of: find.byTooltip('Enable sound'), matching: find.byType(Icon));
      Focus.of(tester.element(soundIcon)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(SettingsService.instance.isMuted, isFalse);
      expect(engine.state, GameState.menu);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(SettingsService.instance.isMuted, isTrue);

      final startText = find.descendant(
          of: find.byKey(_startKey), matching: find.byType(Text));
      Focus.of(tester.element(startText)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(engine.state, GameState.ready);
      expect(engine.hardcore, isTrue,
          reason: 'Space selected the focused Hardcore mode before starting');
    } finally {
      await _unmount(tester);
    }
  });
}
