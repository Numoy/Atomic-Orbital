import 'dart:async';
import 'dart:convert';

import 'package:atomic_orbital/models/achievement.dart';

import 'package:atomic_orbital/game/game_skin.dart';
import 'package:atomic_orbital/services/daily_challenge_service.dart';
import 'package:atomic_orbital/services/save_backup_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  SettingsService._();

  static final instance = SettingsService._();
  static const _walletKey = 'cosmetics_wallet_v1';
  static const _maxStardust = 9007199254740991;
  SharedPreferences? _prefs;
  Future<void>? _walletWrites;
  int _stardust = 100;
  Set<String> _ownedSkins = {GameSkin.classic.id};
  GameSkin _selectedSkin = GameSkin.classic;
  String? _walletFailure;
  final Map<String, int> _stats = {};
  final Map<String, int> _milestones = {};
  final Map<String, int> _worldBest = {};
  final Map<String, Object> _options = {};
  final languageListenable = ValueNotifier<String>('system');
  final progressSaving = ValueNotifier<bool>(false);
  static const _progressKey = 'player_progress_v1';
  String? _progressFailure;
  bool _progressReadable = true;
  int _revision = 0;
  int _savedRevision = 0;
  Future<void>? _progressWrite;
  static const _previousSaveKey = 'previous_save_v1';
  static const _importJournalKey = 'save_import_journal_v1';
  bool _importing = false;
  bool backupRecoveryFailed = false;
  Map<String, dynamic>? _backupFallback;

  Object? _savedValue(String key) => _backupFallback?.containsKey(key) == true
      ? _backupFallback![key]
      : _prefs?.get(key);

  String? get progressFailure => _progressFailure;
  bool get progressPending => _revision != _savedRevision;
  bool get musicEnabled => _options['music'] as bool? ?? true;
  bool get effectsEnabled => _options['effects'] as bool? ?? true;
  bool get hapticsEnabled => _options['haptics'] as bool? ?? false;
  String get language => _options['language'] as String? ?? 'system';
  bool get tutorialSeen => _options['tutorial'] as bool? ?? false;
  bool get hardcoreExplained => _options['hardcoreHint'] as bool? ?? false;

  void setOption(String key, Object value) {
    if ((key == 'language' && !const ['system', 'en', 'de'].contains(value)) ||
        (key != 'language' &&
            (value is! bool ||
                !const [
                  'music',
                  'effects',
                  'haptics',
                  'tutorial',
                  'hardcoreHint',
                  'muted'
                ].contains(key)))) {
      throw ArgumentError.value(value, key);
    }
    if (_options[key] == value) return;
    _options[key] = value;
    if (key == 'language') languageListenable.value = language;
    _changedProgress();
  }

  int achievementProgress(OrbitalAchievement achievement) =>
      (_milestones[achievement.id] ?? 0).clamp(0, achievement.target);
  bool achievementUnlocked(OrbitalAchievement achievement) =>
      achievementProgress(achievement) >= achievement.target;
  int get unlockedCount =>
      OrbitalAchievement.all.where(achievementUnlocked).length;

  void _loadProgress() {
    _stats.clear();
    _milestones.clear();
    _worldBest.clear();
    _options.clear();
    _revision = _savedRevision = 0;
    progressSaving.value = false;
    _progressFailure = null;
    _progressReadable = true;
    final raw = _savedValue(_progressKey);
    try {
      if (raw != null) {
        if (raw is! String) throw const FormatException('Invalid progress');
        final value = jsonDecode(raw);
        if (value is! Map<String, dynamic> || value['version'] != 1) {
          throw const FormatException('Invalid progress');
        }
        Map<String, int> integers(Object? input) {
          if (input is! Map<String, dynamic> ||
              input.values.any((v) => v is! int || v < 0 || v > _maxStardust)) {
            throw const FormatException('Invalid counters');
          }
          return input.cast<String, int>();
        }

        final stats = integers(value['stats']);
        final milestones = integers(value['milestones']);
        final worlds = integers(value['worlds']);
        final options = value['options'];
        if (options is! Map<String, dynamic> ||
            options.entries.any((e) => e.key == 'language'
                ? !const ['system', 'en', 'de'].contains(e.value)
                : !const [
                      'music',
                      'effects',
                      'haptics',
                      'tutorial',
                      'hardcoreHint',
                      'muted'
                    ].contains(e.key) ||
                    e.value is! bool)) {
          throw const FormatException('Invalid settings');
        }
        _stats.addAll(stats);
        _milestones.addAll(milestones);
        _worldBest.addAll(worlds);
        _options.addAll(options.cast<String, Object>());
      }
      for (final key in [
        'high_score',
        'hardcore_high_score',
        'games_played',
        'total_points',
        'total_play_time'
      ]) {
        final legacy = _prefs?.get(key);
        if (!_stats.containsKey(key) &&
            legacy != null &&
            (legacy is! int || legacy < 0 || legacy > _maxStardust)) {
          throw const FormatException('Invalid legacy counter');
        }
      }
      _backfillAchievements();
    } catch (_) {
      _progressReadable = false;
      _progressFailure =
          'Saved progress could not be read. The original save is preserved.';
    }
    languageListenable.value = language;
  }

  void _advance(AchievementMetric metric, int value) {
    for (final a in OrbitalAchievement.all.where((a) => a.metric == metric)) {
      final amount = value.clamp(0, a.target);
      if (amount > (_milestones[a.id] ?? 0)) _milestones[a.id] = amount;
    }
  }

  void _backfillAchievements() {
    _advance(AchievementMetric.normal, highScore);
    _advance(AchievementMetric.hardcore, hardcoreHighScore);
    _advance(AchievementMetric.points, totalPoints);
    _advance(AchievementMetric.games, gamesPlayed);
    _advance(AchievementMetric.first,
        highScore > 0 || hardcoreHighScore > 0 || totalPoints > 0 ? 1 : 0);
    _advance(AchievementMetric.earlyNormal, highScore);
    _advance(AchievementMetric.earlyHardcore, hardcoreHighScore);
    _advance(
        AchievementMetric.worlds,
        _ownedSkins
            .where((id) =>
                id != GameSkin.classic.id &&
                GameSkin.values.any((s) => s.id == id))
            .length);
  }

  void recordPickup(
      {required int score,
      required bool hardcore,
      required bool clean,
      required GameSkin skin}) {
    if (score < 1) throw ArgumentError.value(score, 'score');
    final before = Map<String, int>.of(_milestones);
    _advance(AchievementMetric.first, 1);
    _advance(
        hardcore
            ? AchievementMetric.earlyHardcore
            : AchievementMetric.earlyNormal,
        score);
    if (!hardcore && clean) _advance(AchievementMetric.clean, score);
    var worldChanged = false;
    const tourWorlds = ['classic', 'cow_abduction', 'deep_blue'];
    if (tourWorlds.contains(skin.id) && score > (_worldBest[skin.id] ?? 0)) {
      _worldBest[skin.id] = score;
      worldChanged = true;
    }
    _advance(AchievementMetric.tour,
        tourWorlds.where((id) => (_worldBest[id] ?? 0) >= 5).length);
    if (worldChanged || !mapEquals(before, _milestones)) _changedProgress();
  }

  void mergePlatformAchievements(Iterable<String> ids) {
    var changed = false;
    for (final a in OrbitalAchievement.all
        .where((a) => ids.contains(a.id) || ids.contains(a.googleId))) {
      if (!achievementUnlocked(a)) {
        _milestones[a.id] = a.target;
        changed = true;
      }
    }
    if (changed) _changedProgress();
  }

  void completeGame(
      {required int score, required bool hardcore, required int seconds}) {
    if (score < 0 || seconds < 0) throw ArgumentError('Invalid completed run');
    final key = hardcore ? 'hardcore_high_score' : 'high_score';
    _stats[key] = score > (hardcore ? hardcoreHighScore : highScore)
        ? score
        : (hardcore ? hardcoreHighScore : highScore);
    _stats['games_played'] = gamesPlayed + 1;
    _stats['total_points'] = totalPoints + score;
    _stats['total_play_time'] = totalPlayTime + seconds;
    _backfillAchievements();
    _changedProgress();
  }

  void _changedProgress() {
    _revision++;
    progressSaving.value = true;
    unawaited(flushProgress());
    notifyListeners();
  }

  Future<void> flushProgress() => _progressWrite ??=
      _saveProgress().whenComplete(() => _progressWrite = null);

  Future<void> _saveProgress() async {
    if (!_progressReadable || _importing || backupRecoveryFailed) return;
    final previousFailure = _progressFailure;
    try {
      while (_savedRevision != _revision) {
        final revision = _revision;
        final snapshot = jsonEncode({
          'version': 1,
          'stats': _stats,
          'milestones': _milestones,
          'worlds': _worldBest,
          'options': _options
        });
        final prefs = _prefs;
        if (prefs == null || !await prefs.setString(_progressKey, snapshot)) {
          throw StateError('Progress could not be saved');
        }
        _savedRevision = revision;
      }
      _progressFailure = null;
    } catch (_) {
      _progressFailure =
          'Progress could not be saved. Retry before closing the game.';
    }
    progressSaving.value = progressPending;
    if (_progressFailure != previousFailure) notifyListeners();
  }

  int _stat(String key) {
    final value = _stats[key] ?? _prefs?.get(key);
    return value is int && value >= 0 && value <= _maxStardust ? value : 0;
  }

  void _setStat(String key, int value) {
    if (value < 0 || value > _maxStardust) {
      throw ArgumentError.value(value, key);
    }
    _stats[key] = value;
    _backfillAchievements();
    _changedProgress();
  }

  static Future<void> initialize() async {
    await instance._progressWrite;
    await instance._queueWallet(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (instance._prefs != null) await prefs.reload();
        instance._prefs = prefs;
        try {
          await instance._recoverBackup();
        } catch (_) {/* Read the journal's original snapshot below. */}
        instance._loadWallet();
      } catch (_) {
        instance._walletFailure = 'Saved Stars could not be read. '
            'Your saved progress has not been changed.';
        instance._stardust = 0;
        instance._ownedSkins = {GameSkin.classic.id};
        instance._selectedSkin = GameSkin.classic;
      }
      instance._loadProgress();
      if (instance.backupRecoveryFailed) {
        instance._progressReadable = false;
        instance._progressFailure = 'Saved import could not be recovered.';
        instance._walletFailure = 'Saved import could not be recovered.';
      }
      instance.notifyListeners();
    });
  }

  int get stardust => _stardust;
  GameSkin get selectedSkin => _selectedSkin;
  String? get walletFailure => _walletFailure;
  bool ownsSkin(GameSkin skin) => _ownedSkins.contains(skin.id);

  void _loadWallet() {
    final raw = _savedValue(_walletKey);
    if (raw == null) {
      _resetWallet();
      return;
    }
    if (raw is! String) throw const FormatException('Invalid wallet');
    final value = jsonDecode(raw);
    if (value is! Map<String, dynamic> ||
        value['version'] != 1 ||
        value['stardust'] is! int ||
        (value['stardust'] as int) < 0 ||
        (value['stardust'] as int) > _maxStardust ||
        value['owned'] is! List<dynamic> ||
        !(value['owned'] as List<dynamic>).every((id) => id is String) ||
        value['equipped'] is! String) {
      throw const FormatException('Invalid wallet');
    }
    final owned = {
      GameSkin.classic.id,
      ...(value['owned'] as List<dynamic>).cast<String>(),
    };
    final requested = GameSkin.byId(value['equipped'] as String);
    final selected =
        owned.contains(requested.id) ? requested : GameSkin.classic;
    _stardust = value['stardust'] as int;
    _ownedSkins = owned;
    _selectedSkin = selected;
    _walletFailure = null;
  }

  Future<T> _queueWallet<T>(Future<T> Function() action) {
    final previous = _walletWrites;
    final work = previous == null
        ? Future<T>.sync(action)
        : previous.then((_) => action());
    late final Future<void> tail;
    final result = work.whenComplete(() {
      if (identical(_walletWrites, tail)) _walletWrites = null;
    });
    tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    _walletWrites = tail;
    return result;
  }

  void _checkWallet() {
    if (_walletFailure != null ||
        _prefs == null ||
        _importing ||
        backupRecoveryFailed) {
      throw StateError(_walletFailure ?? 'Stars are not ready yet.');
    }
  }

  Future<void> _saveWallet(
      int balance, Set<String> owned, GameSkin selected) async {
    final prefs = _prefs!;
    try {
      final saved = await prefs.setString(
          _walletKey,
          jsonEncode({
            'version': 1,
            'stardust': balance,
            'owned': owned.toList(),
            'equipped': selected.id,
          }));
      if (!saved) {
        throw StateError('Stars could not be saved. Please try again.');
      }
    } catch (_) {
      // SharedPreferences changes its cache before the platform confirms a write.
      try {
        await prefs.reload();
      } catch (_) {}
      rethrow;
    }
    _stardust = balance;
    _ownedSkins = owned;
    _selectedSkin = selected;
    final before = Map<String, int>.of(_milestones);
    _backfillAchievements();
    if (!mapEquals(before, _milestones)) {
      _changedProgress();
    } else {
      notifyListeners();
    }
  }

  Future<void> earnStardust(int amount) => _queueWallet(() async {
        _checkWallet();
        if (amount < 0 || amount > _maxStardust - _stardust) {
          throw ArgumentError.value(amount, 'amount');
        }
        if (amount == 0) return;
        await _saveWallet(_stardust + amount, _ownedSkins, _selectedSkin);
      });

  Future<bool> buySkin(GameSkin skin) => _queueWallet(() async {
        _checkWallet();
        if (ownsSkin(skin)) return true;
        if (_stardust < skin.price) return false;
        await _saveWallet(
            _stardust - skin.price, {..._ownedSkins, skin.id}, skin);
        return true;
      });

  Future<void> selectSkin(GameSkin skin) => _queueWallet(() async {
        _checkWallet();
        if (!ownsSkin(skin)) throw StateError('Unlock this world first.');
        if (_selectedSkin == skin) return;
        await _saveWallet(_stardust, _ownedSkins, skin);
      });

  void _resetWallet() {
    _stardust = 100;
    _ownedSkins = {GameSkin.classic.id};
    _selectedSkin = GameSkin.classic;
    _walletFailure = null;
  }

  int get highScore => _stat('high_score');
  int get hardcoreHighScore => _stat('hardcore_high_score');
  void setHighScore(int score, {bool hardcore = false}) {
    if (score < 0) throw ArgumentError.value(score, 'score');
    if (score > (hardcore ? hardcoreHighScore : highScore)) {
      _setStat(hardcore ? 'hardcore_high_score' : 'high_score', score);
    }
  }

  int get currentScore => _stat('current_score');
  void setCurrentScore(int score) => _setStat('current_score', score);
  bool get isMuted =>
      _options['muted'] as bool? ?? _prefs?.getBool('is_muted') ?? true;
  void setMuted(bool muted) => setOption('muted', muted);
  int get gamesPlayed => _stat('games_played');
  void incrementGamesPlayed() => _setStat('games_played', gamesPlayed + 1);
  int get totalPoints => _stat('total_points');
  void addTotalPoints(int score) =>
      _setStat('total_points', totalPoints + score);
  int get totalPlayTime => _stat('total_play_time');
  void addPlayTime(int seconds) =>
      _setStat('total_play_time', totalPlayTime + seconds);

  Future<void> resetSettings() => _queueWallet(() async {
        await _progressWrite;
        final prefs = _prefs;
        if (prefs != null) {
          try {
            if (!await prefs.clear()) {
              throw StateError('Settings could not be reset.');
            }
          } catch (_) {
            try {
              await prefs.reload();
            } catch (_) {}
            rethrow;
          }
        }
        _resetWallet();
        _backupFallback = null;
        backupRecoveryFailed = false;
        _loadProgress();
        notifyListeners();
      });

  String? get previousSave {
    final raw = _savedValue(_previousSaveKey);
    if (raw is! String) return null;
    try {
      final value = jsonDecode(raw);
      final save = value is Map<String, dynamic> ? value['save'] : null;
      if (save is! String) return null;
      SaveBackup.decode(save);
      return save;
    } catch (_) {
      return null;
    }
  }

  String _saveSnapshot() {
    if (!_progressReadable || _walletFailure != null || backupRecoveryFailed) {
      throw StateError('The original unreadable save is preserved.');
    }
    final wallet = _savedValue(_walletKey);
    final snapshot = jsonEncode({
      'format': 'atomic-orbital-save',
      'version': 1,
      'progress': {
        'version': 1,
        'stats': {
          ..._stats,
          for (final key in SaveBackup.statisticKeys) key: _stat(key)
        },
        'milestones': _milestones,
        'worlds': _worldBest,
        'options': {
          ...SaveBackup.optionDefaults,
          ..._options,
          'muted': isMuted
        },
      },
      'wallet': wallet is String
          ? jsonDecode(wallet)
          : {
              'version': 1,
              'stardust': _stardust,
              'owned': _ownedSkins.toList(),
              'equipped': _selectedSkin.id,
            },
      'daily': _prefs?.get(DailyChallengeService.storageKey),
    });
    return jsonEncode(SaveBackup.decode(snapshot));
  }

  Future<String> exportSave() => _queueWallet(() async {
        await flushProgress();
        await DailyChallengeService.instance.flush();
        await _prefs!.reload();
        return _saveSnapshot();
      });

  Future<void> _writeRaw(String key, Object? value) async {
    final prefs = _prefs!;
    final saved = switch (value) {
      null => await prefs.remove(key),
      String value => await prefs.setString(key, value),
      int value => await prefs.setInt(key, value),
      bool value => await prefs.setBool(key, value),
      double value => await prefs.setDouble(key, value),
      List<Object?> value when value.every((v) => v is String) =>
        await prefs.setStringList(key, value.cast<String>()),
      _ => false,
    };
    if (!saved) throw StateError('Save could not be written.');
  }

  Future<void> _recoverBackup() async {
    backupRecoveryFailed = false;
    _backupFallback = null;
    final raw = _prefs!.get(_importJournalKey);
    if (raw == null) return;
    try {
      if (raw is! String) throw const FormatException('Invalid import journal');
      final value = jsonDecode(raw);
      const keys = [
        _progressKey,
        _walletKey,
        _previousSaveKey,
        DailyChallengeService.storageKey
      ];
      if (value is! Map<String, dynamic> ||
          value.length != keys.length ||
          keys.any((key) => !value.containsKey(key))) {
        throw const FormatException('Invalid import journal');
      }
      _backupFallback = value;
      for (final key in keys) {
        await _writeRaw(key, value[key]);
      }
      await _writeRaw(_importJournalKey, null);
      _backupFallback = null;
    } catch (_) {
      backupRecoveryFailed = true;
      rethrow;
    }
  }

  Future<void> importSave(String contents) => _queueWallet(() async {
        final save = SaveBackup.decode(contents);
        if (backupRecoveryFailed) {
          await _recoverBackup();
          _loadImportedState();
          await DailyChallengeService.instance.initialize(reload: true);
        }
        await flushProgress();
        var dailyReadable = true;
        try {
          DailyChallengeService.validateSnapshot(
              _prefs?.get(DailyChallengeService.storageKey));
        } on FormatException {
          dailyReadable = false;
        }
        if (dailyReadable) await DailyChallengeService.instance.flush();
        if (_progressReadable && progressPending) {
          throw StateError('Save existing progress before importing.');
        }
        final prefs = _prefs!;
        await prefs.reload();
        final before = {
          for (final key in [
            _progressKey,
            _walletKey,
            _previousSaveKey,
            DailyChallengeService.storageKey
          ])
            key: prefs.get(key),
        };
        String? portableBefore;
        try {
          portableBefore = _saveSnapshot();
        } catch (_) {/* Preserve unreadable originals below. */}
        _importing = true;
        try {
          // Removing this journal commits all keys; a crash before that rolls back.
          await _writeRaw(_importJournalKey, jsonEncode(before));
          await _writeRaw(_progressKey, jsonEncode(save['progress']));
          await _writeRaw(_walletKey, jsonEncode(save['wallet']));
          await _writeRaw(DailyChallengeService.storageKey, save['daily']);
          await _writeRaw(
              _previousSaveKey,
              jsonEncode({
                'save': portableBefore,
                'raw': {
                  for (final entry in before.entries)
                    if (entry.key != _previousSaveKey) entry.key: entry.value
                }
              }));
          await _writeRaw(_importJournalKey, null);
          _loadImportedState();
        } catch (_) {
          _backupFallback = before;
          backupRecoveryFailed = true;
          try {
            await prefs.reload();
            await _recoverBackup();
          } catch (_) {/* Keep the journal and block writes until recovery. */}
          _loadImportedState();
          rethrow;
        } finally {
          _importing = false;
          await DailyChallengeService.instance.initialize(reload: true);
          notifyListeners();
        }
      });

  void _loadImportedState() {
    try {
      _loadWallet();
    } catch (_) {
      _walletFailure =
          'Saved Stars could not be read. The original save is preserved.';
    }
    _loadProgress();
    if (backupRecoveryFailed) {
      _progressReadable = false;
      _progressFailure = 'Saved import could not be recovered.';
      _walletFailure = 'Saved import could not be recovered.';
    }
  }

  Future<void> restorePreviousSave() {
    final previous = previousSave;
    if (previous == null) throw StateError('No readable previous save.');
    return importSave(previous);
  }
}
