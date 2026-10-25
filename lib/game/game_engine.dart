import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:atomic_orbital/constants/game_constants.dart';
import 'package:atomic_orbital/game/game_skin.dart';
import 'package:atomic_orbital/models/components.dart';
import 'package:atomic_orbital/models/entity.dart';
import 'package:atomic_orbital/models/vector2d.dart';
import 'package:atomic_orbital/services/audio_service.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:atomic_orbital/services/play_games_service.dart';

enum GameState { menu, ready, playing, paused, gameOver }

class GameEngine {
  final Random _random;
  Random? _runRandom;
  bool _recordProgress = true;
  GameState _state = GameState.menu;
  GameState _stateBeforePause = GameState.playing;
  final List<Entity> _entities = [];
  final List<Orbit> _orbits = [];
  late Entity _atom;
  late Entity _player;
  late Entity _energy;
  int _score = 0;
  double _health = 100;
  double _gameTime = 0;
  double _accumulator = 0;
  int _entityId = 0;
  int _photonTimer = 100;
  int _orbitAnimationFrame = 0;
  bool _orbitAnimationPlaying = false;
  bool _isTouching = false;
  bool _hardcore = false;
  bool _isNewHighScore = false;
  bool _tookHit = false;
  final bool practice;
  GameSkin? skin;
  int _redPart = 0;
  int _backgroundRed = 0;
  double _startAlpha = 251;
  bool _startAppearing = true;
  final int _width;
  final int _height;
  int _fps = 0;
  int _framesThisSecond = 0;
  double _fpsTimer = 0;
  double _scoreTextX = 0;
  double _scoreTextY = 0;

  void Function(GameState)? onStateChanged;
  void Function(int)? onScoreChanged;
  VoidCallback? onGameOver;
  VoidCallback? onUpdate;

  // Explicit dimensions are retained for comparisons with the released Java.
  // Device layout must scale the reference canvas without resizing this world.
  GameEngine({
    Random? random,
    this.practice = false,
    double width = GameConstants.referenceWidth,
    double height = GameConstants.referenceHeight,
  })  : assert(width.isFinite && height.isFinite && width >= 1 && height >= 1),
        _random = random ?? Random(),
        _width = width.toInt(),
        _height = height.toInt() {
    _resetWorld();
  }

  GameState get state => _state;
  int get score => _score;
  double get health => _health;
  double get gameTime => _gameTime;
  int get fps => _fps;
  int get width => _width;
  int get height => _height;
  bool get hardcore => _hardcore;
  bool get tookHit => _tookHit;
  bool get isNewHighScore => _isNewHighScore;
  bool get recordProgress => _recordProgress;
  int get backgroundRed => _backgroundRed;
  double get startAlpha => _startAlpha;
  double get scoreTextX => _scoreTextX;
  double get scoreTextY => _scoreTextY;
  Entity get player => _player;
  Entity get energy => _energy;
  Entity get atom => _atom;
  List<Entity> get entities => List.unmodifiable(_entities);
  List<Entity> get photons =>
      _entities.where((entity) => entity.type == EntityType.photon).toList();
  List<Orbit> get orbits => List.unmodifiable(_orbits);

  Entity _entity(EntityType type, double radius, {LogicComponent? logic}) {
    return Entity(
      id: _entityId++,
      type: type,
      position: PositionComponent(),
      size: SizeComponent(radius * 2, radius * 2),
      logic: logic,
      collision: CollisionComponent(isCollidable: type != EntityType.atom),
    );
  }

  void _resetWorld() {
    _entities.clear();
    _orbits
      ..clear()
      ..add(Orbit((_width ~/ 5).toDouble(), 1))
      ..add(Orbit(((_width * 9) ~/ 20).toDouble(), -1));
    _score = 0;
    _isNewHighScore = false;
    _tookHit = false;
    _health = 100;
    _gameTime = 0;
    _fps = 0;
    _framesThisSecond = 0;
    _fpsTimer = 0;
    _accumulator = 0;
    _entityId = 0;
    _photonTimer = 100;
    _orbitAnimationFrame = 0;
    _orbitAnimationPlaying = false;
    _isTouching = false;
    _redPart = 0;
    _backgroundRed = 0;
    _startAlpha = 251;
    _startAppearing = true;
    _atom = _entity(EntityType.atom, (_width ~/ 8).toDouble());
    _atom.position.setPosition(Vector2D(
      (_width ~/ 2).toDouble(),
      (_height ~/ 2).toDouble(),
    ));
    final playerLogic = PlayerLogicComponent(
      screenWidth: _width,
      screenHeight: _height,
    );
    _player = _entity(
      EntityType.player,
      (_width ~/ 35).toDouble(),
      logic: playerLogic,
    );
    playerLogic.positionPlayer(_player);
    _energy = _entity(
      EntityType.energy,
      (_width ~/ 25).toDouble(),
      logic: EnergyLogicComponent(
        onOrbit: _currentRandom.nextInt(_orbits.length),
        angle: float32(360 * _nextFloat()),
      ),
    );
    _updateEnergyPosition();
    _entities.addAll([_atom, _energy, _player]);
    _updateScorePosition();
  }

  Random get _currentRandom => _runRandom ?? _random;
  double _nextFloat() => _currentRandom.nextInt(1 << 24) / (1 << 24);

  void startGame(
      {bool hardcore = false, Random? random, bool recordProgress = true}) {
    _hardcore = hardcore;
    _runRandom = random;
    _recordProgress = recordProgress;
    _resetWorld();
    _setState(GameState.ready);
    onScoreChanged?.call(_score);
    AudioService.instance.playBackgroundMusic();
  }

  void _setState(GameState state) {
    _state = state;
    onStateChanged?.call(state);
  }

  void pauseGame() {
    if (_state != GameState.playing && _state != GameState.ready) return;
    _stateBeforePause = _state;
    _releaseTouch();
    _accumulator = 0;
    _setState(GameState.paused);
  }

  void resumeGame() {
    if (_state != GameState.paused) return;
    _accumulator = 0;
    _setState(_stateBeforePause);
  }

  void resetGame() {
    _resetWorld();
    _setState(GameState.menu);
  }

  // Preserve the original S10's 60 Hz cadence independently of display refresh.
  void update(double elapsedSeconds) {
    if (!elapsedSeconds.isFinite || elapsedSeconds < 0) return;
    if (_state != GameState.playing && _state != GameState.ready) return;
    _accumulator += elapsedSeconds;
    while (_accumulator + 1e-12 >= GameConstants.frameTime) {
      _accumulator -= GameConstants.frameTime;
      advanceFrame();
      if (_state != GameState.playing && _state != GameState.ready) {
        _accumulator = 0;
        break;
      }
    }
    onUpdate?.call();
  }

  /// One update of the released Java controllers, independent of display Hz.
  void advanceFrame() {
    if (_state == GameState.ready) {
      if (_isTouching) {
        _setState(GameState.playing);
      } else {
        _updateStartPrompt();
        return;
      }
    }
    if (_state != GameState.playing) return;
    _gameTime += GameConstants.frameTime;
    _fpsTimer += GameConstants.frameTime * 1000;
    if (_fpsTimer >= 1000) {
      _fps = _framesThisSecond;
      _framesThisSecond = 0;
      _fpsTimer = 0;
    } else {
      _framesThisSecond++;
    }
    if (_health < 100) _health = float32(_health + float32(0.1));
    _updateScorePosition();
    _updateOrbits();
    _updateEnergyPosition();
    _energy.update(GameConstants.frameTime);
    _player.update(GameConstants.frameTime);
    _updatePhotons();
    _redPart = (_redPart - 0.25 * GameConstants.frameTime * 1000).toInt();
    if (_redPart < 0) _redPart = 0;
    _backgroundRed = _redPart;
    if (_player.collidesWith(_energy)) _collectEnergy();
    _checkPhotonCollisions();
  }

  void _updateStartPrompt() {
    if (_startAlpha < 255 && _startAppearing) {
      _startAlpha += 3;
      if (_startAlpha >= 255) {
        _startAppearing = false;
        _startAlpha = 255;
      }
    }
    if (_startAlpha > 0 && !_startAppearing) {
      _startAlpha -= 3;
      if (_startAlpha <= 0) {
        _startAppearing = true;
        _startAlpha = 0;
      }
    }
  }

  void _updateScorePosition() {
    final radius = _atom.size.radius;
    _scoreTextX = float32(
      _width ~/ 2 -
          float32(
              float32(radius * (_score < 10 ? 6 : (_score < 100 ? 11 : 17))) /
                  20),
    );
    _scoreTextY = float32(_height ~/ 2 + float32(radius / 3));
  }

  void _updateOrbits() {
    if (_orbitAnimationPlaying) {
      final count = _orbits.length;
      final minRadius = (_width ~/ 5).toDouble();
      final maxRadius = ((_width * 9) ~/ 20).toDouble();
      for (var i = 1; i < count; i++) {
        final a = float32(i / count);
        final b = float32(i / (count - 1));
        final newRadius =
            float32(minRadius + float32((maxRadius - minRadius) * a));
        final oldRadius =
            float32(minRadius + float32((maxRadius - minRadius) * b));
        final step = float32(float32(oldRadius - newRadius) / 60);
        _orbits[i].radius = float32(_orbits[i].radius - step);
      }
      _orbitAnimationFrame++;
      if (_orbitAnimationFrame == 60) {
        _orbitAnimationPlaying = false;
        _orbits.add(Orbit(maxRadius, _orbits.length.isEven ? 1 : -1));
      }
    }
    for (final orbit in _orbits) {
      orbit.rotation = float32(float32(orbit.rotation + float32(0.2)) % 360);
    }
  }

  void _updateEnergyPosition() {
    final logic = _energy.logic as EnergyLogicComponent;
    final radius = _orbits[logic.onOrbit].radius;
    final angle = float32(logic.angle * javaDegreesToRadians);
    _energy.position.setPosition(Vector2D(
      float32(_width ~/ 2 + float32(radius * float32(sin(angle)))),
      float32(_height ~/ 2 + float32(radius * float32(cos(angle)))),
    ));
  }

  void _collectEnergy() {
    _score++;
    if (!practice && _recordProgress) {
      SettingsService.instance.recordPickup(
          score: _score,
          hardcore: _hardcore,
          clean: !_tookHit,
          skin: skin ?? SettingsService.instance.selectedSkin);
    }
    onScoreChanged?.call(_score);
    AudioService.instance.playSoundEffect('collect');
    final playerLogic = _player.logic as PlayerLogicComponent;
    playerLogic.reverseDirection();
    final energyLogic = _energy.logic as EnergyLogicComponent;
    energyLogic.onOrbit = _currentRandom.nextInt(_orbits.length);
    energyLogic.angle = float32(
      float32(90 + playerLogic.currentAngle) + float32(180 * _nextFloat()),
    );
    _updateEnergyPosition();
    if (_score == 5 || _score == 10 || _score == 20) {
      _orbitAnimationPlaying = true;
      _orbitAnimationFrame = 0;
    }
  }

  void _updatePhotons() {
    _photonTimer++;
    for (final photon in photons) {
      final logic = photon.logic as PhotonLogicComponent;
      if (logic.growing) {
        logic.radius =
            float32(float32(_photonTimer / 100) * photon.size.radius);
      }
    }
    if (_photonTimer > 100) {
      for (final photon in photons) {
        final logic = photon.logic as PhotonLogicComponent;
        if (logic.growing) {
          logic.radius = photon.size.radius;
          logic.growing = false;
        }
      }
      _spawnPhotons();
      _photonTimer = 0;
    }
    for (final photon in photons) {
      photon.update(GameConstants.frameTime);
    }
    _entities.removeWhere((entity) => entity.isDeleted);
  }

  void _spawnPhotons() {
    if (practice) return;
    final count = _score ~/ 5 + 1;
    final groups = _currentRandom.nextInt(min(4, count)) + 1;
    final type = PhotonTrajectory.values[_currentRandom.nextInt(3)];
    final direction = _currentRandom.nextBool() ? 1 : -1;
    var angle = float32(360 * _nextFloat());
    for (var i = 0; i < count; i++) {
      if (i % groups == 0) angle = float32(angle + 10);
      final logic = PhotonLogicComponent(
        screenWidth: _width,
        screenHeight: _height,
        trajectory: type,
        angle: angle,
        direction: direction,
      );
      final photon = _entity(
        EntityType.photon,
        float32(_width * float32(0.014285714)),
        logic: logic,
      );
      logic.positionPhoton(photon);
      _entities.add(photon);
      angle = float32(angle + 360 ~/ groups);
    }
  }

  void _checkPhotonCollisions() {
    final currentPhotons = photons;
    for (var i = 0; i < currentPhotons.length; i++) {
      final photon = currentPhotons[i];
      if (!_player.collidesWith(photon)) continue;
      _tookHit = true;
      _entities.remove(photon);
      currentPhotons.removeAt(i);
      _redPart = GameConstants.redFlashOnHit;
      AudioService.instance.playSoundEffect('hit');
      _health = float32(_health - (_hardcore ? 130 : 45));
      if (_health < 0) {
        _gameOver();
        return;
      }
      // Java increments i after removal; preserve its same-frame hit ordering.
    }
  }

  void _gameOver() {
    _releaseTouch();
    final settings = SettingsService.instance;
    final previousHighScore =
        _hardcore ? settings.hardcoreHighScore : settings.highScore;
    _isNewHighScore =
        _recordProgress && _score > 0 && _score > previousHighScore;
    _setState(GameState.gameOver);
    if (!practice && _recordProgress) {
      settings.completeGame(
          score: _score, hardcore: _hardcore, seconds: _gameTime.round());
      unawaited(PlayGamesService.instance.recordCompletedGame(
        score: _score,
        hardcore: _hardcore,
        previousHighScore: previousHighScore,
        gamesPlayed: settings.gamesPlayed,
        totalPoints: settings.totalPoints,
      ));
    }
    AudioService.instance.pauseBackgroundMusic();
    onGameOver?.call();
  }

  void onTouchDown() {
    if (_state != GameState.ready && _state != GameState.playing) return;
    _isTouching = true;
    (_player.logic as PlayerLogicComponent).setTouching(true);
  }

  void _releaseTouch() {
    _isTouching = false;
    (_player.logic as PlayerLogicComponent).setTouching(false);
  }

  void onTouchUp() => _releaseTouch();
  void onTouchCancel() => _releaseTouch();

  void dispose() {
    _releaseTouch();
    AudioService.instance.pauseBackgroundMusic();
  }
}
