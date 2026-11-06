import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:atomic_orbital/constants/game_constants.dart';
import 'package:atomic_orbital/game/game_engine.dart';
import 'package:atomic_orbital/game/game_screen.dart';
import 'package:atomic_orbital/game/game_skin.dart';
import 'package:atomic_orbital/game/original_text.dart';
import 'package:atomic_orbital/game/world_backdrop.dart';
import 'package:atomic_orbital/main.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _capture = ValueKey('backgroundCapture');
const _export = bool.fromEnvironment('GENERATE_FULLSCREEN_EVIDENCE');

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

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'cosmetics_wallet_v1': jsonEncode({
        'version': 1,
        'stardust': 188,
        'owned': GameSkin.values.map((skin) => skin.id).toList(),
        'equipped': 'volcano_hop',
      }),
    });
    await SettingsService.initialize();
  });

  for (final window in [
    (
      name: 'portrait',
      size: const Size(393, 852),
      padding: const EdgeInsets.only(top: 59, bottom: 34)
    ),
    (
      name: 'landscape',
      size: const Size(852, 393),
      padding: const EdgeInsets.only(left: 59, right: 59, bottom: 21)
    ),
  ]) {
    testWidgets('${window.name}: every world fills home and gameplay edges',
        (tester) async {
      addTearDown(tester.view.reset);
      final padding = FakeViewPadding(
          left: window.padding.left,
          top: window.padding.top,
          right: window.padding.right,
          bottom: window.padding.bottom);
      tester.view
        ..physicalSize = window.size
        ..devicePixelRatio = 1
        ..padding = padding
        ..viewPadding = padding;

      for (final skin in GameSkin.values.where((s) => s != GameSkin.classic)) {
        await tester.runAsync(() => SettingsService.instance.selectSkin(skin));
        final engine = GameEngine(random: math.Random(7));
        await tester.pumpWidget(RepaintBoundary(
          key: _capture,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AtomicOrbitalApp.themeData,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: GameScreen(
                cosmeticsEnabled: true,
                engine: engine,
                textCache: OriginalTextCache(enabled: false)),
          ),
        ));
        await tester.pump();

        final edgeSamples = <Offset>[
          const Offset(6, 6),
          Offset(window.size.width / 2, 6),
          Offset(6, window.size.height - 6),
          Offset(window.size.width - 6, window.size.height - 6),
        ];
        Future<void> check(String state, List<Offset> samples) async {
          expect(tester.takeException(), isNull);
          final boundary =
              tester.renderObject<RenderRepaintBoundary>(find.byKey(_capture));
          await tester.runAsync(() async {
            final actual = await boundary.toImage();
            final recorder = ui.PictureRecorder();
            WorldBackdrop(skin: skin).paint(Canvas(recorder), window.size);
            final picture = recorder.endRecording();
            final expected = await picture.toImage(
                window.size.width.toInt(), window.size.height.toInt());
            try {
              final pixels = (await actual.toByteData())!;
              final reference = (await expected.toByteData())!;
              for (final sample in samples) {
                final index =
                    (sample.dy.floor() * actual.width + sample.dx.floor()) * 4;
                for (var channel = 0; channel < 4; channel++) {
                  expect(pixels.getUint8(index + channel),
                      closeTo(reference.getUint8(index + channel), 1),
                      reason: '${skin.id} $state at $sample must continue '
                          'the same full-window backdrop');
                }
              }
              if (_export &&
                  [GameSkin.deepBlue, GameSkin.volcanoHop, GameSkin.jungleJam]
                      .contains(skin)) {
                final bytes =
                    (await actual.toByteData(format: ui.ImageByteFormat.png))!;
                final file = File('build/fullscreen-preview/'
                    '${window.name}-${skin.id}-$state.png');
                await file.parent.create(recursive: true);
                await file.writeAsBytes(bytes.buffer.asUint8List());
              }
            } finally {
              actual.dispose();
              expected.dispose();
              picture.dispose();
            }
          });
        }

        await check('home', edgeSamples);
        final style = tester
            .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
                find.byType(AnnotatedRegion<SystemUiOverlayStyle>))
            .value;
        expect(style.statusBarColor, Colors.transparent);
        expect(style.systemNavigationBarColor, Colors.transparent);
        expect(style.systemNavigationBarContrastEnforced, isFalse);

        engine.startGame(recordProgress: false);
        engine.onTouchDown();
        engine.advanceFrame();
        engine.onTouchUp();
        await tester.pump();
        expect(engine.state, GameState.playing);
        final frame =
            tester.getRect(find.byKey(const ValueKey('gameViewport')));
        final safe = Rect.fromLTRB(
            window.padding.left,
            window.padding.top,
            window.size.width - window.padding.right,
            window.size.height - window.padding.bottom);
        final scale = math.min(safe.width / 1080, safe.height / 1794);
        expect(frame.width, closeTo(1080 * scale, .001));
        expect(frame.height, closeTo(1794 * scale, .001));
        expect(frame.center.dx, closeTo(safe.center.dx, .001));
        expect(frame.center.dy, closeTo(safe.center.dy, .001));
        final samples = [...edgeSamples];
        if (window.name == 'portrait') {
          samples.addAll([
            Offset(6, frame.top - 4),
            Offset(6, frame.top + 4),
            Offset(6, frame.bottom - 4),
            Offset(6, frame.bottom + 4),
          ]);
        } else {
          samples.addAll([
            Offset(frame.left - 4, 6),
            Offset(frame.left + 4, 6),
            Offset(frame.right - 4, 6),
            Offset(frame.right + 4, 6),
          ]);
        }
        await check('game', samples);
        final painter = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((widget) => widget.painter)
            .whereType<GamePainter>()
            .single;
        expect(painter.drawBackground, isFalse);
        expect(painter.devicePixelRatio, GameConstants.referencePixelRatio);
        await tester.pumpWidget(const SizedBox());
      }
    });
  }
}
