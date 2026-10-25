import 'dart:async';
import 'dart:ui' as ui;

import 'package:atomic_orbital/game/game_screen.dart';
import 'package:atomic_orbital/game/original_text.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingCache extends OriginalTextCache {
  _RecordingCache() : super(enabled: true);
  final recorded = <OriginalTextSpec>[];

  @override
  Future<void> prepare(Iterable<OriginalTextSpec> specs,
      {bool pin = false}) async {
    recorded.addAll(specs);
  }
}

Map<String, Object> _response(MethodCall call, Uint8List png,
    {void Function(Map<Object?, Object?>)? onItem}) {
  final args = call.arguments as Map<Object?, Object?>;
  return {
    'items': [
      for (final raw in args['items']! as List<Object?>)
        (() {
          final item = raw! as Map<Object?, Object?>;
          onItem?.call(item);
          return {
            'key': item['key'],
            'png': png,
            'originX': -2,
            'originY': -4,
          };
        })()
    ]
  };
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('atomic_orbital/platform');
  late Uint8List png;

  setUpAll(() async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 3, 3), Paint()..color = Colors.white);
    final fixture = await recorder.endRecording().toImage(3, 3);
    png = (await fixture.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
    fixture.dispose();
  });

  tearDown(() =>
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

  test('whole Canvas strings retain baseline origins and reuse cached images',
      () async {
    var calls = 0;
    final requested = <Map<Object?, Object?>>[];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      calls++;
      return _response(call, png, onItem: requested.add);
    });
    final cache = OriginalTextCache(enabled: true);
    addTearDown(cache.dispose);
    const ten = OriginalTextSpec('10', 135, canvas: true, color: Colors.black);
    const hundred =
        OriginalTextSpec('100', 135, canvas: true, color: Colors.black);
    final first = cache.prepare([ten, hundred, ten]);
    final concurrent = cache.prepare([ten]).then((_) {
      expect(cache[ten], isNotNull);
    });
    await Future.wait([first, concurrent]);
    await cache.prepare([ten, hundred]);
    expect(requested.map((item) => item['text']), ['10', '100']);
    expect(requested.first, ten.toMap());
    expect(requested.first.keys,
        unorderedEquals(['key', 'text', 'sizePx', 'kind', 'color']));
    expect(calls, 1);
    expect(cache[ten]!.origin, const Offset(-2, -4));
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..drawColor(Colors.black, BlendMode.src);
    for (var frame = 0; frame < 120; frame++) {
      cache[ten]!.paint(canvas, const Offset(10, 10));
    }
    final image = await recorder.endRecording().toImage(20, 20);
    final data = (await image.toByteData())!;
    int red(int x, int y) => data.getUint8((y * 20 + x) * 4);
    expect(red(8, 6), 255);
    expect(red(7, 6), 0);
    expect(red(8, 5), 0);
    expect(calls, 1);
    image.dispose();
  });

  test('bounded cache keeps pinned and recently painted stamps', () async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel, (call) async => _response(call, png));
    final cache = OriginalTextCache(enabled: true);
    const pinned = OriginalTextSpec('TOUCH TO START', 60);
    const oldest = OriginalTextSpec('0', 135);
    const recent = OriginalTextSpec('1', 135);
    await cache.prepare([pinned], pin: true);
    await cache.prepare([oldest, recent]);
    final oldestImage = cache[oldest]!.image;
    // Keep this as the oldest unpinned entry before adding the other 317.
    cache[recent];
    final fillers =
        List.generate(317, (index) => OriginalTextSpec('${index + 2}', 135));
    await cache.prepare(fillers.take(160));
    await cache.prepare(fillers.skip(160));
    final recentImage = cache[recent]!.image;
    await cache.prepare([const OriginalTextSpec('319', 135)]);
    expect(cache[oldest], isNull);
    expect(oldestImage.debugDisposed, isTrue);
    expect(cache[pinned], isNotNull);
    expect(cache[recent], isNotNull);
    expect(recentImage.debugDisposed, isFalse);
    final pinnedImage = cache[pinned]!.image;
    cache.dispose();
    expect(pinnedImage.debugDisposed, isTrue);
    expect(recentImage.debugDisposed, isTrue);
  });

  test('disposing during native preparation discards the decoded image',
      () async {
    final response = Completer<Map<String, Object>>();
    MethodCall? request;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) {
      request = call;
      return response.future;
    });
    final created = <ui.Image>[];
    final previousOnCreate = ui.Image.onCreate;
    ui.Image.onCreate = created.add;
    addTearDown(() => ui.Image.onCreate = previousOnCreate);
    final cache = OriginalTextCache(enabled: true);
    const spec = OriginalTextSpec('0', 135);
    final pending = cache.prepare([spec]);
    await Future<void>.delayed(Duration.zero);
    cache.dispose();
    response.complete(_response(request!, png));
    await pending;
    expect(cache[spec], isNull);
    expect(created, isNotEmpty);
    expect(created.every((image) => image.debugDisposed), isTrue);
  });

  test('native failure is explicit and prevents repeated failed requests',
      () async {
    var calls = 0;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async {
      calls++;
      throw PlatformException(
          code: 'invalid_text', message: 'Bitmap limit exceeded');
    });
    final cache = OriginalTextCache(enabled: true);
    addTearDown(cache.dispose);
    await cache.prepare([const OriginalTextSpec('TOUCH TO START', 60)]);
    expect(cache.failure, contains('Bitmap limit exceeded'));
    expect(cache.available, isFalse);
    await cache.prepare([const OriginalTextSpec('0', 135)]);
    expect(calls, 1);
  });

  testWidgets('warmup contains only canonical gameplay Canvas strings',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.initialize();
    tester.view
      ..physicalSize = const Size(720, 1280)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final cache = _RecordingCache();
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(
          size: Size(360, 640),
          devicePixelRatio: 2,
          textScaler: TextScaler.linear(1.5)),
      child: GameScreen(textCache: cache),
    )));
    await tester.pump();
    expect(cache.recorded, isNotEmpty);
    for (final spec in cache.recorded) {
      expect(spec.canvas, isTrue);
      if (spec.text == 'TOUCH TO START') {
        expect(spec.sizePx, 60);
        expect(spec.color, Colors.white);
      } else if (spec.text.startsWith('FPS: ')) {
        expect(spec.sizePx, 40);
        expect(spec.color, Colors.white);
      } else {
        expect(int.tryParse(spec.text), isNotNull);
        expect(spec.sizePx, 135);
        expect(spec.color, Colors.black);
      }
    }
    expect(cache.recorded.any((spec) => spec.text == 'TOUCH TO START'), isTrue);
    expect(
        cache.recorded.any((spec) => spec.text.startsWith('FPS: ')), isFalse);
    expect(cache.recorded.any((spec) => spec.text == '0'), isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
