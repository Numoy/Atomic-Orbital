import 'dart:async';
import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AudioService {
  AudioService._();

  static final instance = AudioService._();
  AudioPlayer? _music;
  final Map<String, AudioPool> _sounds = {};
  final List<StopFunction> _streams = [];
  Future<void> _effects = Future.value();
  bool _initialized = false;
  Future<void>? _initialization;
  bool _musicReady = false;
  bool _muted = true;
  bool _musicRequested = false;
  bool _nativeEffects = false;
  bool _nativeMusic = false;
  static const _platform = MethodChannel('atomic_orbital/platform');

  static Future<void> initialize() => instance._initialize();

  String _asset(String name) {
    final apple = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    if (apple) {
      return name == 'bg_music'
          ? 'audio/ios/bg_music.m4a'
          : 'audio/ios/$name.wav';
    }
    return 'audio/$name.ogg';
  }

  Future<void> _initialize() => _initialization ??=
      _loadAudio().whenComplete(() => _initialization = null);

  Future<void> _loadAudio() async {
    if (_initialized) return;
    _muted = SettingsService.instance.isMuted;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        // One native owner keeps music pauses from deactivating active effects.
        await _platform.invokeMethod<void>('loadSoundEffects');
        _nativeEffects = true;
        _nativeMusic = true;
        _initialized = true;
      } catch (error) {
        log('Apple audio initialization failed', error: error);
      }
      return;
    }
    try {
      if (!_musicReady) {
        _music ??= AudioPlayer();
        await _music!.setSource(AssetSource(_asset('bg_music')));
        await _music!.setReleaseMode(ReleaseMode.loop);
        _musicReady = true;
      }
    } catch (error) {
      log('Music initialization failed', error: error);
    }
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        if (!_nativeEffects) {
          await _platform.invokeMethod<void>('loadSoundEffects');
          _nativeEffects = true;
        }
        _initialized = _musicReady;
        return;
      }
      for (final sound in ['hit', 'collect', 'shoot']) {
        _sounds[sound] ??= await AudioPool.createFromAsset(
          path: _asset(sound),
          minPlayers: 1,
          maxPlayers: 10,
        );
      }
      _initialized = _musicReady;
    } catch (error) {
      log('Audio initialization failed', error: error);
    }
  }

  Future<void> playBackgroundMusic() async {
    _musicRequested = true;
    if (_muted) return;
    await _initialize();
    if (!_musicRequested || _muted || !SettingsService.instance.musicEnabled) {
      return;
    }
    try {
      if (_nativeMusic) {
        await _platform.invokeMethod<void>('playBackgroundMusic');
      } else {
        await _music?.resume();
      }
    } catch (error) {
      log('Music playback failed', error: error);
    }
  }

  Future<void> pauseBackgroundMusic() async {
    _musicRequested = false;
    await _pauseMusic(rewind: true);
  }

  Future<void> _pauseMusic({required bool rewind}) async {
    try {
      if (_nativeMusic) {
        await _platform
            .invokeMethod<void>('pauseBackgroundMusic', {'rewind': rewind});
      } else {
        await _music?.pause();
        // Leaving a run restarts the track; muting preserves its position.
        if (rewind) await _music?.seek(Duration.zero);
      }
    } catch (error) {
      log('Music stop failed', error: error);
    }
  }

  Future<void> playSoundEffect(String soundName) {
    if (_muted ||
        !SettingsService.instance.effectsEnabled ||
        (!_nativeEffects && !_sounds.containsKey(soundName))) {
      return Future.value();
    }
    _effects = _effects.then((_) async {
      if (_muted || !SettingsService.instance.effectsEnabled) return;
      try {
        if (_nativeEffects) {
          await _platform
              .invokeMethod<void>('playSoundEffect', {'name': soundName});
          return;
        }
        if (_streams.length == 10) await _streams.removeAt(0)();
        _streams.add(await _sounds[soundName]!.start());
      } catch (error) {
        log('Sound playback failed', error: error);
      }
    });
    return _effects;
  }

  void setMuted(bool muted) {
    _muted = muted;
    SettingsService.instance.setMuted(muted);
    if (muted) {
      unawaited(_pauseMusic(rewind: false));
    } else if (_musicRequested) {
      unawaited(playBackgroundMusic());
    } else {
      unawaited(_initialize());
    }
  }

  void refreshMusic() {
    if (!_muted) unawaited(_initialize());
    if (_muted || !SettingsService.instance.musicEnabled) {
      unawaited(_pauseMusic(rewind: false));
    } else if (_musicRequested) {
      unawaited(playBackgroundMusic());
    }
  }

  bool get isMuted => _muted;
  bool get isAudioAvailable => _nativeMusic || _musicReady;

  Future<void> dispose() async {
    _musicRequested = false;
    await _initialization;
    await _effects;
    if (_nativeEffects) {
      try {
        await _platform.invokeMethod<void>('disposeSoundEffects');
      } catch (error) {
        log('Sound disposal failed', error: error);
      }
      _nativeEffects = false;
      _nativeMusic = false;
    }
    for (final stop in _streams) {
      await stop();
    }
    _streams.clear();
    for (final pool in _sounds.values) {
      await pool.dispose();
    }
    _sounds.clear();
    await _music?.dispose();
    _music = null;
    _initialized = false;
    _musicReady = false;
  }
}
