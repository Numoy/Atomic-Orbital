import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';
import 'package:atomic_orbital/services/settings_service.dart';

class AudioService {
  static AudioService? _instance;
  static AudioService get instance => _instance ??= AudioService._();
  
  AudioService._();
  
  AudioPlayer? _backgroundMusicPlayer;
  AudioPlayer? _soundEffectPlayer;
  
  bool _isInitialized = false;
  bool _isMuted = false;
  bool _audioAvailable = true;
  
  static Future<void> initialize() async {
    await instance._initialize();
  }
  
  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    try {
      log('Initializing audio service...');
      
      _backgroundMusicPlayer = AudioPlayer();
      _soundEffectPlayer = AudioPlayer();
      
      // Try to load background music with error handling
      try {
        log('Attempting to load background music...');
        await _backgroundMusicPlayer!.setSource(AssetSource('audio/bg_music.ogg'));
        await _backgroundMusicPlayer!.setReleaseMode(ReleaseMode.loop);
        log('Background music loaded successfully');
      } catch (e) {
        log('Failed to load background music: $e');
        log('Audio will be disabled for this session');
        _audioAvailable = false;
        // Don't throw here, just disable audio
      }
      
      _isInitialized = true;
      
      // Load mute setting
      _isMuted = SettingsService.instance.isMuted;
      
      if (_audioAvailable) {
        log('Audio service initialized successfully');
      } else {
        log('Audio service initialized with audio disabled due to loading errors');
      }
      
    } catch (e) {
      log('Audio initialization failed completely: $e');
      log('Audio will be disabled for this session');
      _audioAvailable = false;
      _isInitialized = true; // Mark as initialized to prevent retries
    }
  }
  
  Future<void> playBackgroundMusic() async {
    if (!_isInitialized || _isMuted || !_audioAvailable || _backgroundMusicPlayer == null) {
      if (!_audioAvailable) {
        log('Background music not available (audio disabled)');
      } else if (_isMuted) {
        log('Background music muted');
      }
      return;
    }
    
    try {
      await _backgroundMusicPlayer!.resume();
      log('Background music started');
    } catch (e) {
      log('Error playing background music: $e');
    }
  }
  
  Future<void> pauseBackgroundMusic() async {
    if (!_isInitialized || _backgroundMusicPlayer == null) return;
    
    try {
      await _backgroundMusicPlayer!.pause();
    } catch (e) {
      log('Error pausing background music: $e');
    }
  }
  
  Future<void> playSoundEffect(String soundName) async {
    if (!_isInitialized || _isMuted || !_audioAvailable || _soundEffectPlayer == null) return;
    
    try {
      await _soundEffectPlayer!.play(AssetSource('audio/$soundName.ogg'));
    } catch (e) {
      log('Error playing sound effect $soundName: $e');
    }
  }
  
  void setMuted(bool muted) {
    _isMuted = muted;
    SettingsService.instance.setMuted(muted);
    
    if (muted) {
      pauseBackgroundMusic();
    } else {
      playBackgroundMusic();
    }
  }
  
  bool get isMuted => _isMuted;
  bool get isAudioAvailable => _audioAvailable;
  
  void dispose() {
    _backgroundMusicPlayer?.dispose();
    _soundEffectPlayer?.dispose();
    _backgroundMusicPlayer = null;
    _soundEffectPlayer = null;
    _isInitialized = false;
  }
} 