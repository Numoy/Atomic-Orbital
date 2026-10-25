import 'dart:convert';

import 'package:atomic_orbital/services/daily_challenge_service.dart';
import 'package:flutter/services.dart';

/// Portable installation progress. Platform identities and upload queues stay local.
class SaveBackup {
  static const maximumBytes = 1024 * 1024;
  static const platform = MethodChannel('atomic_orbital/platform');
  static const statisticKeys = [
    'high_score',
    'hardcore_high_score',
    'games_played',
    'total_points',
    'total_play_time',
    'current_score',
  ];
  static const optionDefaults = <String, Object>{
    'music': true,
    'effects': true,
    'haptics': false,
    'tutorial': false,
    'hardcoreHint': false,
    'muted': true,
    'language': 'system',
  };

  static Map<String, dynamic> decode(String text) {
    if (text.length > maximumBytes || utf8.encode(text).length > maximumBytes) {
      throw const FormatException('Save file is too large');
    }
    final value = jsonDecode(text);
    if (value is! Map<String, dynamic> ||
        value['format'] != 'atomic-orbital-save' ||
        value['version'] != 1 ||
        value.keys.any((key) => !const [
              'format',
              'version',
              'progress',
              'wallet',
              'daily'
            ].contains(key))) {
      throw const FormatException('Unsupported save');
    }
    final progress = value['progress'];
    final wallet = value['wallet'];
    if (progress is! Map<String, dynamic> ||
        progress['version'] != 1 ||
        progress.keys.any((key) => !const [
              'version',
              'stats',
              'milestones',
              'worlds',
              'options'
            ].contains(key))) {
      throw const FormatException('Invalid progress');
    }
    void counters(Object? input) {
      if (input is! Map<String, dynamic> ||
          input.length > 128 ||
          input.entries.any((e) =>
              !_identifier(e.key) ||
              e.value is! int ||
              (e.value as int) < 0 ||
              (e.value as int) > 9007199254740991)) {
        throw const FormatException('Invalid counters');
      }
    }

    counters(progress['stats']);
    counters(progress['milestones']);
    counters(progress['worlds']);
    final options = progress['options'];
    if (options is! Map<String, dynamic> ||
        options.entries.any((e) =>
            !optionDefaults.containsKey(e.key) ||
            (e.key == 'language'
                ? !const ['system', 'en', 'de'].contains(e.value)
                : e.value is! bool))) {
      throw const FormatException('Invalid settings');
    }
    if (wallet is! Map<String, dynamic> ||
        wallet['version'] != 1 ||
        wallet.keys.any((key) => !const [
              'version',
              'stardust',
              'owned',
              'equipped'
            ].contains(key)) ||
        wallet['stardust'] is! int ||
        (wallet['stardust'] as int) < 0 ||
        (wallet['stardust'] as int) > 9007199254740991 ||
        wallet['owned'] is! List ||
        (wallet['owned'] as List).length > 128 ||
        !(wallet['owned'] as List).every(_identifier) ||
        !_identifier(wallet['equipped'])) {
      throw const FormatException('Invalid stored inventory');
    }
    DailyChallengeService.validateSnapshot(value['daily']);
    wallet['owned'] =
        {'classic', ...(wallet['owned'] as List).cast<String>()}.toList();
    // A replacement must not fall back to this installation's legacy counters.
    for (final key in statisticKeys) {
      (progress['stats'] as Map<String, dynamic>).putIfAbsent(key, () => 0);
    }
    for (final entry in optionDefaults.entries) {
      options.putIfAbsent(entry.key, () => entry.value);
    }
    return value;
  }

  static bool _identifier(Object? value) =>
      value is String && value.isNotEmpty && value.length <= 128;

  static Future<bool> exportFile(String contents) async {
    decode(contents);
    return await platform
            .invokeMethod<bool>('exportSave', {'contents': contents}) ??
        false;
  }

  static Future<String?> importFile() async {
    final contents = await platform.invokeMethod<String>('importSave');
    if (contents != null) decode(contents);
    return contents;
  }
}
