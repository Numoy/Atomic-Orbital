import 'dart:convert';

import 'package:atomic_orbital/game/daily_challenge.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyChallengeService extends ChangeNotifier {
  static final instance = DailyChallengeService();
  static const storageKey = 'daily_challenges_v1';
  static const _maxValue = 0x7fffffff;
  SharedPreferences? _prefs;
  final _records = <String, ({int score, int seconds})>{};
  final _pending = <String, ({int score, int seconds})>{};
  Future<void>? _writes;
  bool _readable = false;
  String? failure;

  bool get pending => _pending.isNotEmpty;
  int bestFor(DailyChallenge challenge) =>
      (_pending[challenge.identity] ?? _records[challenge.identity])?.score ??
      0;
  Future<void> flush() => _queue(_savePending);

  Future<void> initialize({bool reload = false}) async {
    await _writes;
    if (_readable && !reload) return;
    _records.clear();
    _pending.clear();
    _readable = false;
    try {
      final prefs = _prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      if (prefs.containsKey('save_import_journal_v1')) {
        throw StateError('Save recovery is pending.');
      }
      _records.addAll(_parseSnapshot(prefs.get(storageKey)));
      _readable = true;
      failure = null;
    } catch (_) {
      failure = 'Saved daily results could not be read. The save is preserved.';
    }
    notifyListeners();
  }

  static void validateSnapshot(Object? raw) {
    _parseSnapshot(raw);
  }

  static Map<String, ({int score, int seconds})> _parseSnapshot(Object? raw) {
    final parsed = <String, ({int score, int seconds})>{};
    if (raw == null) return parsed;
    if (raw is! String) throw const FormatException('Invalid daily save');
    final value = jsonDecode(raw);
    if (value is! Map<String, dynamic> ||
        value['version'] != 1 ||
        value['records'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid daily save');
    }
    final records = value['records'] as Map<String, dynamic>;
    if (records.length > 30) {
      throw const FormatException('Invalid daily record count');
    }
    for (final entry in records.entries) {
      final record = entry.value;
      final day = entry.key.split('/').first;
      final date = DateTime.tryParse('${day}T00:00:00Z');
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}/rules-[1-9]\d*/xorshift32-[1-9]\d*$')
              .hasMatch(entry.key) ||
          date == null ||
          date.year < 1 ||
          date.toIso8601String().substring(0, 10) != day ||
          record is! Map<String, dynamic> ||
          !_validCounter(record['score']) ||
          !_validCounter(record['seconds'])) {
        throw const FormatException('Invalid daily record');
      }
      parsed[entry.key] =
          (score: record['score'] as int, seconds: record['seconds'] as int);
    }
    return parsed;
  }

  static bool _validCounter(Object? value) =>
      value is int && value >= 0 && value <= _maxValue;

  Future<void> recordResult(DailyChallenge challenge,
      {required int score, required int seconds}) {
    if (!_validCounter(score) || !_validCounter(seconds)) {
      throw ArgumentError('Invalid daily result');
    }
    return _queue(() async {
      final previous =
          _pending[challenge.identity] ?? _records[challenge.identity];
      if (previous == null || score > previous.score) {
        _pending.remove(challenge.identity);
        _pending[challenge.identity] = (score: score, seconds: seconds);
        notifyListeners();
      }
      await _savePending();
    });
  }

  Future<void> _savePending() async {
    if (_pending.isEmpty) return;
    final prefs = _prefs;
    if (!_readable || prefs == null) {
      throw StateError(failure ?? 'Daily results are not ready.');
    }
    final records = Map<String, ({int score, int seconds})>.of(_records);
    for (final entry in _pending.entries) {
      records.remove(entry.key);
      records[entry.key] = entry.value;
    }
    // Keep the 30 most recently saved challenges, including clock rollbacks.
    while (records.length > 30) {
      records.remove(records.keys.first);
    }
    try {
      await prefs.reload();
      if (prefs.containsKey('save_import_journal_v1')) {
        throw StateError('Save recovery is pending.');
      }
      if (!await prefs.setString(
          storageKey,
          jsonEncode({
            'version': 1,
            'records': records.map((key, value) =>
                MapEntry(key, {'score': value.score, 'seconds': value.seconds}))
          }))) {
        throw StateError('Daily result could not be saved.');
      }
    } catch (_) {
      try {
        await prefs.reload();
      } catch (_) {}
      failure = 'Daily result could not be saved. Please retry.';
      notifyListeners();
      rethrow;
    }
    _records
      ..clear()
      ..addAll(records);
    _pending.clear();
    failure = null;
    notifyListeners();
  }

  Future<void> _queue(Future<void> Function() action) {
    final previous = _writes;
    final work = previous == null
        ? Future<void>.sync(action)
        : previous.then((_) => action());
    late final Future<void> tail;
    final result = work.whenComplete(() {
      if (identical(_writes, tail)) _writes = null;
    });
    tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    _writes = tail;
    return result;
  }
}
