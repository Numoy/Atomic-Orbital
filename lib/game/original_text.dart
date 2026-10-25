import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

/// A whole native string is cached, preserving native advances, kerning and hinting.
@immutable
class OriginalTextSpec {
  const OriginalTextSpec(this.text, this.sizePx,
      {this.canvas = true, this.color = const Color(0xFFFFFFFF)})
      : assert(canvas);

  final String text;
  final double sizePx;
  final bool canvas;
  final Color color;

  String get key => '$sizePx|${color.toARGB32()}|$text';

  Map<String, Object> toMap() => {
        'key': key,
        'text': text,
        'sizePx': sizePx,
        'kind': 'canvas',
        'color': color.toARGB32(),
      };
}

class OriginalTextStamp {
  const OriginalTextStamp(this.image, this.origin);
  final ui.Image image;
  final Offset origin;

  void paint(Canvas canvas, Offset position,
      {double scale = 1, int alpha = 255}) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.scale(scale);
    canvas.drawImage(
        image, origin, Paint()..color = Color.fromARGB(alpha, 255, 255, 255));
    canvas.restore();
  }
}

class OriginalTextCache extends ChangeNotifier {
  OriginalTextCache({bool? enabled})
      : _unavailable = !(enabled ??
            (!kIsWeb && defaultTargetPlatform == TargetPlatform.android));
  static const _channel = MethodChannel('atomic_orbital/platform');
  final _stamps = <String, OriginalTextStamp>{};
  final _pending = <String, Future<void>>{};
  final _pinned = <String>{};
  bool _unavailable;
  bool _disposed = false;
  String? failure;

  bool get available => !_unavailable;
  OriginalTextStamp? operator [](OriginalTextSpec spec) {
    final stamp = _stamps.remove(spec.key);
    if (stamp != null) _stamps[spec.key] = stamp;
    return stamp;
  }

  Future<void> prepare(Iterable<OriginalTextSpec> specs,
      {bool pin = false}) async {
    if (_disposed ||
        _unavailable ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    final missing = <String, OriginalTextSpec>{};
    final existing = <Future<void>>{};
    if (pin) _pinned.clear();
    for (final spec in specs) {
      if (pin) _pinned.add(spec.key);
      final pending = _pending[spec.key];
      if (pending != null) existing.add(pending);
      if (!_stamps.containsKey(spec.key) && pending == null) {
        missing[spec.key] = spec;
      }
    }
    if (missing.isEmpty) {
      await Future.wait(existing);
      return;
    }
    final done = Completer<void>();
    for (final key in missing.keys) {
      _pending[key] = done.future;
    }
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
          'renderOriginalText',
          {'items': missing.values.map((s) => s.toMap()).toList()});
      final items = result?['items'] as List<dynamic>?;
      if (items == null) {
        _fail('Android returned no original text stamps.');
        return;
      }
      for (final raw in items) {
        final item = Map<String, dynamic>.from(raw as Map<Object?, Object?>);
        final bytes = item['png'] as Uint8List;
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        codec.dispose();
        if (_disposed) {
          frame.image.dispose();
          continue;
        }
        _stamps[item['key'] as String] = OriginalTextStamp(
            frame.image,
            Offset((item['originX'] as num).toDouble(),
                (item['originY'] as num).toDouble()));
      }
      while (_stamps.length > 320) {
        final disposable = _stamps.keys.where(
            (key) => !_pinned.contains(key) && !missing.containsKey(key));
        if (disposable.isEmpty) break;
        _stamps.remove(disposable.first)!.image.dispose();
      }
      if (!_disposed) notifyListeners();
    } on MissingPluginException catch (error) {
      _fail('Original Android text renderer is missing: $error');
    } on PlatformException catch (error) {
      _fail('Original Android text rendering failed: ${error.message}');
    } catch (error, stack) {
      _fail('Cannot decode original Android text: $error');
      debugPrintStack(stackTrace: stack);
    } finally {
      for (final key in missing.keys) {
        _pending.remove(key);
      }
      done.complete();
    }
    await Future.wait(existing);
  }

  void _fail(String message) {
    _unavailable = true;
    failure = message;
    debugPrint(message);
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final stamp in _stamps.values) {
      stamp.image.dispose();
    }
    _stamps.clear();
    super.dispose();
  }
}
