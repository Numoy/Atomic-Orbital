import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static SettingsService? _instance;
  static SettingsService get instance => _instance ??= SettingsService._();
  
  SettingsService._();
  
  late SharedPreferences _prefs;
  bool _isInitialized = false;
  
  static Future<void> initialize() async {
    await instance._initialize();
  }
  
  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }
  
  // High Score
  int get highScore => _prefs.getInt('high_score') ?? 0;
  
  void setHighScore(int score) {
    if (score > highScore) {
      _prefs.setInt('high_score', score);
    }
  }
  
  // Current Score
  int get currentScore => _prefs.getInt('current_score') ?? 0;
  
  void setCurrentScore(int score) {
    _prefs.setInt('current_score', score);
  }
  
  // Mute Setting
  bool get isMuted => _prefs.getBool('is_muted') ?? false;
  
  void setMuted(bool muted) {
    _prefs.setBool('is_muted', muted);
  }
  
  // Game Statistics
  int get gamesPlayed => _prefs.getInt('games_played') ?? 0;
  
  void incrementGamesPlayed() {
    _prefs.setInt('games_played', gamesPlayed + 1);
  }
  
  int get totalPlayTime => _prefs.getInt('total_play_time') ?? 0;
  
  void addPlayTime(int seconds) {
    _prefs.setInt('total_play_time', totalPlayTime + seconds);
  }
  
  // Reset all settings
  Future<void> resetSettings() async {
    await _prefs.clear();
  }
} 