import 'dart:ui';

import 'package:atomic_orbital/game/game_engine.dart';

class GameplayFeedback {
  final _trail = <({Offset position, double time})>[];
  ({Offset position, double time})? _collection;
  ({Offset position, double time})? _hit;
  double? _lastTime;
  double? _lastHealth;

  List<({Offset position, double time})> get trail => List.unmodifiable(_trail);
  ({Offset position, double time})? get collection => _collection;
  ({Offset position, double time})? get hit => _hit;

  void reset() {
    _trail.clear();
    _collection = null;
    _hit = null;
    _lastTime = null;
    _lastHealth = null;
  }

  void collect(Offset position, double time) {
    _collection = (position: position, time: time);
    _trail.clear();
  }

  void sync(GameEngine engine) {
    final time = engine.gameTime;
    if (engine.state == GameState.menu || engine.state == GameState.ready) {
      reset();
      _lastTime = time;
      _lastHealth = engine.health;
      return;
    }
    if (_lastTime != null && time < _lastTime!) reset();
    if (engine.state != GameState.playing &&
        engine.state != GameState.gameOver) {
      return;
    }
    if (time == _lastTime) return;
    final player = engine.player.position.position;
    final position = Offset(player.x, player.y);
    if (_lastHealth != null && engine.health < _lastHealth!) {
      _hit = (position: position, time: time);
    }
    if (_collection != null && time - _collection!.time >= .55 - 1e-9) {
      _collection = null;
    }
    if (_hit != null && time - _hit!.time >= .35 - 1e-9) _hit = null;
    _trail.removeWhere((sample) => time - sample.time > .18);
    if (engine.state == GameState.playing &&
        (_trail.isEmpty || time - _trail.last.time >= 1 / 60 - 1e-9)) {
      _trail.add((position: position, time: time));
      if (_trail.length > 12) _trail.removeAt(0);
    }
    _lastTime = time;
    _lastHealth = engine.health;
  }
}
