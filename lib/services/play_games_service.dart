import 'dart:convert';
import 'package:atomic_orbital/models/achievement.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atomic_orbital/services/settings_service.dart';

class PlayGamesEvent {
  const PlayGamesEvent(this.method, this.arguments);
  final String method;
  final Map<String, Object> arguments;

  String get key =>
      '$method:${arguments['leaderboardId'] ?? arguments['achievementId']}';
  Map<String, Object> toJson() => {'method': method, 'arguments': arguments};

  factory PlayGamesEvent.fromJson(Object? value) {
    switch (value) {
      case {
            'method': 'submitScore',
            'arguments': {'leaderboardId': String id, 'score': int score},
          }
          when PlayGamesService.leaderboardIds.contains(id) && score >= 0:
        return PlayGamesEvent('submitScore', {
          'leaderboardId': PlayGamesService.currentLeaderboard(id),
          'score': score
        });
      case {
            'method': 'unlockAchievement',
            'arguments': {'achievementId': String id},
          }
          when PlayGamesService.achievementIds.contains(id):
        return PlayGamesEvent('unlockAchievement', {'achievementId': id});
      default:
        throw const FormatException('Invalid saved Google Play Games event.');
    }
  }
}

class PlayGamesService extends ChangeNotifier {
  PlayGamesService(
      {MethodChannel channel =
          const MethodChannel('atomic_orbital/play_games')})
      : _channel = channel;

  static final instance = PlayGamesService();
  static const legacyNormalLeaderboard = 'CgkItOGapf0GEAIQAQ';
  static const legacyHardcoreLeaderboard = 'CgkItOGapf0GEAIQAg';
  static const normalLeaderboard = 'CgkItOGapf0GEAIQGg';
  static const hardcoreLeaderboard = 'CgkItOGapf0GEAIQGw';
  static const maxCloudScore = 9007199254740991;
  static const gamesLeaderboard = 'CgkItOGapf0GEAIQAw';
  static const leaderboardIds = {
    normalLeaderboard,
    hardcoreLeaderboard,
    gamesLeaderboard,
    legacyNormalLeaderboard,
    legacyHardcoreLeaderboard
  };
  static final achievementIds =
      OrbitalAchievement.all.map((a) => a.googleId).whereType<String>().toSet();
  static const _pendingKey = 'play_games_pending';
  static const _disconnectedKey = 'play_games_disconnected';

  final MethodChannel _channel;
  final List<PlayGamesEvent> _pending = [];
  final Map<String, int> _unsubmittedScores = {};
  SharedPreferences? _prefs;
  Future<void>? _sync;
  Future<void>? _achievementSync;
  bool _achievementSyncRequested = false;
  bool _initialized = false;
  Future<void>? _loading;
  bool _authenticated = false;
  bool _disconnected = false;
  String? _displayName;
  String? _lastError;
  String? _rangeWarning;
  String? _profileId;

  bool get isApple => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  String get providerName => isApple ? 'Game Center' : 'Play Games';
  bool get supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || isApple);
  bool get authenticated => _authenticated;
  bool get disconnected => _disconnected;
  String? get displayName => _displayName;
  String? get lastError => _lastError;
  int get pendingCount => _pending.length;

  static String currentLeaderboard(String id) => switch (id) {
        legacyNormalLeaderboard => normalLeaderboard,
        legacyHardcoreLeaderboard => hardcoreLeaderboard,
        _ => id,
      };

  static bool cloudScoreAllowed(String leaderboardId, int score) {
    if (score < 1) return false;
    return switch (leaderboardId) {
      normalLeaderboard || hardcoreLeaderboard => score <= maxCloudScore,
      legacyNormalLeaderboard => score <= 200,
      legacyHardcoreLeaderboard => score <= 100,
      gamesLeaderboard => score <= 0x7FFFFFFFFFFFFFFF,
      _ => false,
    };
  }

  static List<PlayGamesEvent> eventsForCompletedGame({
    required int score,
    required bool hardcore,
    required int previousHighScore,
    required int gamesPlayed,
    required int totalPoints,
  }) {
    if (score < 0 ||
        previousHighScore < 0 ||
        gamesPlayed < 1 ||
        totalPoints < score) {
      throw ArgumentError('Invalid completed-game statistics.');
    }
    final events = <PlayGamesEvent>[];
    if (score > previousHighScore) {
      events.add(PlayGamesEvent('submitScore', {
        'leaderboardId': hardcore ? hardcoreLeaderboard : normalLeaderboard,
        'score': score,
      }));
    }
    void unlock(AchievementMetric metric, int value) {
      for (final a in OrbitalAchievement.legacyUnlocks(metric, value)) {
        events.add(PlayGamesEvent(
            'unlockAchievement', {'achievementId': a.googleId!}));
      }
    }

    unlock(hardcore ? AchievementMetric.hardcore : AchievementMetric.normal,
        score);
    // Release 41 passed the preference key "gamesPlayed" and the old count.
    // Use the configured leaderboard and this completed game's updated count.
    events.add(PlayGamesEvent('submitScore', {
      'leaderboardId': gamesLeaderboard,
      'score': gamesPlayed,
    }));
    unlock(AchievementMetric.points, totalPoints);
    unlock(AchievementMetric.games, gamesPlayed);
    return events;
  }

  Future<void> _loadPending() =>
      _loading ??= _readPending().catchError((Object error, StackTrace stack) {
        _loading = null;
        Error.throwWithStackTrace(error, stack);
      });

  Future<void> _readPending() async {
    _prefs = await SharedPreferences.getInstance();
    _disconnected = _prefs!.getBool(_disconnectedKey) ?? false;
    _profileId = _prefs!.getString('play_games_profile');
    final saved = _prefs!.get(_pendingKey);
    if (saved == null) return;
    var unreadable = false;
    var invalidScore = false;
    try {
      if (saved is! String) {
        throw const FormatException('Invalid saved Google Play Games queue.');
      }
      final Object? decoded = jsonDecode(saved);
      if (decoded is! List) {
        throw const FormatException('Invalid saved Google Play Games queue.');
      }
      for (final value in decoded) {
        try {
          final event = PlayGamesEvent.fromJson(value);
          if (event.method == 'submitScore' &&
              !cloudScoreAllowed(event.arguments['leaderboardId']! as String,
                  event.arguments['score']! as int)) {
            invalidScore = true;
          }
          _merge(event);
        } on FormatException {
          unreadable = true;
        }
      }
    } on FormatException {
      unreadable = true;
    }
    if (invalidScore) await _persist();
    if (unreadable) {
      await _prefs!.setString('${_pendingKey}_unreadable',
          saved is String ? saved : jsonEncode(saved));
      _lastError =
          'Some saved Play Games updates could not be read. Local scores are unaffected.';
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    try {
      await _loadPending();
      _initialized = true;
      if (supported) await refreshAuthentication();
    } on PlatformException catch (error) {
      _loading = null;
      _authenticationFailed(error.message ?? error.code);
    }
  }

  Future<void> refreshAuthentication() async {
    if (!supported) return;
    try {
      await _loadPending();
      _initialized = true;
      if (_disconnected) {
        _authenticated = false;
        _displayName = null;
        notifyListeners();
        return;
      }
      final status = await _channel.invokeMapMethod<String, Object?>('status');
      if (!await _acceptProfile(status)) return;
      _applyStatus(status);
      if (_authenticated) {
        await _restoreAchievements();
        await syncLocalAchievements();
        await _queueStoredHighscores();
        await flushPending();
      }
    } on PlatformException catch (error) {
      _authenticationFailed(error.message ?? error.code);
    } on MissingPluginException {
      _authenticationFailed(
          'Google Play Games is available in the Android app.');
    }
  }

  void _authenticationFailed(String message) {
    _authenticated = false;
    _displayName = null;
    _lastError = message;
    notifyListeners();
  }

  Future<bool> _acceptProfile(Map<String, Object?>? status) async {
    final id = status?['playerId'];
    if (status?['authenticated'] != true || id is! String || id.isEmpty) {
      return true;
    }
    if (_profileId != null && id != _profileId) {
      _authenticationFailed('profile_changed');
      return false;
    }
    if (_profileId == null) {
      if (!await _prefs!.setString('play_games_profile', id)) {
        throw PlatformException(
            code: 'save_failed', message: 'The profile could not be saved.');
      }
      _profileId = id;
    }
    return true;
  }

  Future<void> _restoreAchievements() async {
    try {
      final ids = await _channel.invokeListMethod<String>('loadAchievements',
          _profileId == null ? null : {'playerId': _profileId!});
      if (ids != null) SettingsService.instance.mergePlatformAchievements(ids);
    } on PlatformException {
      // A failed read must not revoke local unlocks or stop queued score uploads.
    } on MissingPluginException {
      // Older native runners can still submit the original achievements.
    }
  }

  void _applyStatus(Map<String, Object?>? status) {
    _authenticated = !_disconnected && status?['authenticated'] == true;
    _displayName = _authenticated ? (status?['displayName'] as String?) : null;
    if (_authenticated) _lastError = _rangeWarning;
    notifyListeners();
  }

  Future<bool> signIn() async {
    _requireAndroid();
    await _loadPending();
    _initialized = true;
    try {
      final status = await _channel.invokeMapMethod<String, Object?>('signIn');
      if (!await _acceptProfile(status)) return false;
      if (status?['authenticated'] == true) {
        _disconnected = false;
        if (!await _prefs!.setBool(_disconnectedKey, false)) {
          throw PlatformException(code: 'save_failed');
        }
      }
      _applyStatus(status);
      if (_authenticated) {
        await _restoreAchievements();
        await syncLocalAchievements();
        await _queueStoredHighscores();
        await flushPending();
      }
      return _authenticated;
    } on PlatformException catch (error) {
      _authenticationFailed(error.message ?? error.code);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await _loadPending();
    _disconnected = true;
    _authenticated = false;
    _displayName = null;
    _lastError = null;
    if (!await _prefs!.setBool(_disconnectedKey, true)) {
      _lastError = 'save_failed';
      notifyListeners();
      throw PlatformException(code: 'save_failed');
    }
    notifyListeners();
  }

  void _requireAndroid() {
    if (!supported) {
      throw PlatformException(
          code: 'unsupported_platform',
          message: 'Google Play Games is available on Android.');
    }
  }

  Future<bool> showAchievements() async {
    _requireAndroid();
    if (!_authenticated && !await signIn()) return false;
    await _channel.invokeMethod<void>('showAchievements');
    return true;
  }

  Future<bool> showLeaderboards({bool hardcore = false}) async {
    _requireAndroid();
    if (!_authenticated && !await signIn()) return false;
    await _channel.invokeMethod<void>('showLeaderboards', {
      'leaderboardId': hardcore ? hardcoreLeaderboard : normalLeaderboard,
    });
    return true;
  }

  Future<void> _queueStoredHighscores() async {
    final settings = SettingsService.instance;
    _merge(PlayGamesEvent('submitScore', {
      'leaderboardId': normalLeaderboard,
      'score': settings.highScore,
    }));
    _merge(PlayGamesEvent('submitScore', {
      'leaderboardId': hardcoreLeaderboard,
      'score': settings.hardcoreHighScore,
    }));
    await _persist();
  }

  Future<void> syncLocalAchievements() {
    if (!supported || !_initialized) return Future.value();
    _achievementSyncRequested = true;
    return _achievementSync ??=
        _syncLocalAchievements().whenComplete(() => _achievementSync = null);
  }

  Future<void> _syncLocalAchievements() async {
    while (_achievementSyncRequested) {
      _achievementSyncRequested = false;
      try {
        await _loadPending();
        for (final a in OrbitalAchievement.all
            .where(SettingsService.instance.achievementUnlocked)) {
          final id = a.googleId ?? (isApple ? 'ao.${a.id}' : null);
          if (id != null) {
            _merge(PlayGamesEvent('unlockAchievement', {'achievementId': id}));
          }
        }
        await _persist();
        if (_authenticated) await flushPending();
      } on PlatformException catch (error) {
        _lastError = error.message ?? error.code;
        notifyListeners();
      }
    }
  }

  Future<void> recordCompletedGame({
    required int score,
    required bool hardcore,
    required int previousHighScore,
    required int gamesPlayed,
    required int totalPoints,
  }) async {
    if (!supported) return;
    final events = eventsForCompletedGame(
      score: score,
      hardcore: hardcore,
      previousHighScore: previousHighScore,
      gamesPlayed: gamesPlayed,
      totalPoints: totalPoints,
    );
    try {
      await _loadPending();
      for (final event in events) {
        _merge(event);
      }
      await _persist();
      notifyListeners();
      if (_initialized && _authenticated) await flushPending();
    } on PlatformException catch (error) {
      for (final event in events) {
        _merge(event);
      }
      _lastError = error.message ?? error.code;
      notifyListeners();
    }
  }

  void _merge(PlayGamesEvent event) {
    if (event.method == 'submitScore') {
      final id = event.arguments['leaderboardId']! as String;
      final score = event.arguments['score']! as int;
      if (!cloudScoreAllowed(id, score)) {
        if (score > 0) {
          final previous = _unsubmittedScores[id] ?? 0;
          if (score > previous) _unsubmittedScores[id] = score;
          _rangeWarning =
              "This game's published leaderboard cannot accept that score. Your local high score is preserved.";
          _lastError = _rangeWarning;
        }
        return;
      }
    }
    final index = _pending.indexWhere((existing) => existing.key == event.key);
    if (index < 0) {
      _pending.add(event);
    } else if (event.method == 'submitScore' &&
        (event.arguments['score']! as int) >
            (_pending[index].arguments['score']! as int)) {
      _pending[index] = event;
    }
  }

  Future<void> _persist() async {
    for (final entry in _unsubmittedScores.entries.toList()) {
      final key = 'play_games_unsubmitted_${entry.key}';
      if (entry.value > (_prefs!.getInt(key) ?? 0)) {
        if (!await _prefs!.setInt(key, entry.value)) {
          throw PlatformException(code: 'save_failed');
        }
      }
    }
    if (!await _prefs!.setString(_pendingKey,
        jsonEncode(_pending.map((event) => event.toJson()).toList()))) {
      throw PlatformException(
          code: 'save_failed', message: 'Updates could not be saved.');
    }
  }

  Future<void> flushPending() =>
      _sync ??= _flush().whenComplete(() => _sync = null);

  Future<void> _flush() async {
    if (!supported || !_authenticated || _disconnected) return;
    while (_pending.isNotEmpty && _authenticated && !_disconnected) {
      final event = _pending.first;
      try {
        await _channel.invokeMethod<void>(event.method, {
          ...event.arguments,
          if (_profileId != null) 'playerId': _profileId!
        });
      } on PlatformException catch (error) {
        _lastError = error.code == 'profile_changed'
            ? error.code
            : error.message ?? error.code;
        if (error.code == 'sign_in_required' || error.code == 'profile_changed') {
          _authenticated = false;
        }
        notifyListeners();
        return;
      } on MissingPluginException {
        _lastError = 'Google Play Games is available in the Android app.';
        notifyListeners();
        return;
      }
      // A newer score can replace the in-flight event before its server response.
      if (identical(_pending.first, event)) _pending.removeAt(0);
      try {
        await _persist();
      } on PlatformException catch (error) {
        _lastError = error.message ?? error.code;
        notifyListeners();
        return;
      }
    }
    _lastError = _rangeWarning;
    notifyListeners();
  }
}
