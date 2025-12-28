import 'dart:async';
import 'dart:math';
import 'package:atomic_orbital/models/entity.dart';
import 'package:atomic_orbital/models/components.dart';
import 'package:atomic_orbital/models/vector2d.dart';
import 'package:atomic_orbital/constants/game_constants.dart';
import 'package:atomic_orbital/services/audio_service.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:atomic_orbital/services/asset_manager.dart';
import 'package:flutter/material.dart';

enum GameState {
  menu,
  playing,
  paused,
  gameOver,
}

class GameEngine {
  // Game state
  GameState _state = GameState.menu;
  GameState get state => _state;

  // Entities
  final List<Entity> _entities = [];
  final List<Entity> _entityQueue = [];
  final List<Entity> _entitiesToDelete = [];

  // Game objects
  Entity? _atom;
  Entity? _player;
  Entity? _photonSpawner;
  Entity? _currentEnergy;

  // Game variables
  int _score = 0;
  int _lives = 3;
  double _gameTime = 0.0;
  int _entityId = 1;

  // Player controls
  bool _isTouching = false;
  double _touchStartTime = 0.0;

  // Timer
  Timer? _gameTimer;
  static const double _targetFPS = 60.0;
  static const double _frameTime = 1.0 / _targetFPS;

  // Callbacks
  Function(GameState)? onStateChanged;
  Function(int)? onScoreChanged;
  Function(int)? onLivesChanged;
  Function()? onGameOver;
  VoidCallback? onUpdate;

  // Getters
  int get score => _score;
  int get lives => _lives;
  double get gameTime => _gameTime;
  List<Entity> get entities => List.unmodifiable(_entities);

  Future<void> initialize() async {
    await AssetManager.instance.loadAssets();
    _createInitialEntities();
    AudioService.instance.playBackgroundMusic();
  }

  void _createInitialEntities() {
    // Create atom (center)
    _atom = Entity(
      id: _getNextId(),
      type: EntityType.atom,
      position: PositionComponent(),
      size: SizeComponent(GameConstants.atomSize, GameConstants.atomSize),
      graphic: GraphicComponent(color: GameConstants.atomColor),
      collision: CollisionComponent(isCollidable: false),
    );
    _entities.add(_atom!);

    // Create player
    _player = Entity(
      id: _getNextId(),
      type: EntityType.player,
      position: PositionComponent(
        position: Vector2D.fromPolar(GameConstants.atomSize * 1.5,
            pi), // Match original: ATOM_SIZE * 1.5f
      ),
      size: SizeComponent(GameConstants.playerSize, GameConstants.playerSize),
      graphic: GraphicComponent(color: GameConstants.playerColor),
      logic: PlayerLogicComponent(),
      collision: CollisionComponent(),
    );
    _entities.add(_player!);

    // Create photon spawner
    _photonSpawner = Entity(
      id: _getNextId(),
      type: EntityType.misc,
      position: PositionComponent(),
      size: const SizeComponent(0, 0),
      logic: PhotonSpawnerLogicComponent(
        entityQueue: _entityQueue,
        getCurrentScore: () => _score, // Return current score
      ),
      collision: CollisionComponent(isCollidable: false),
    );
    _entities.add(_photonSpawner!);
  }

  void startGame() {
    _state = GameState.playing;
    _score = 0;
    _lives = 3;
    _gameTime = 0.0;
    _currentEnergy = null;
    onStateChanged?.call(_state);
    onScoreChanged?.call(_score);
    onLivesChanged?.call(_lives);

    // Spawn initial energy
    spawnEnergy();
  }

  void pauseGame() {
    if (_state == GameState.playing) {
      _state = GameState.paused;
      onStateChanged?.call(_state);
    }
  }

  void resumeGame() {
    if (_state == GameState.paused) {
      _state = GameState.playing;
      onStateChanged?.call(_state);
    }
  }

  void update() {
    if (_state != GameState.playing) return;

    const deltaTime = _frameTime;
    _gameTime += deltaTime;

    // Update all entities
    for (final entity in _entities) {
      entity.update(deltaTime);
    }

    // Add new entities from queue
    _entities.addAll(_entityQueue);
    _entityQueue.clear();

    // Check collisions
    _checkCollisions();

    // Remove deleted entities
    _entities.removeWhere((entity) => entity.isDeleted);

    // Check game over conditions
    if (_lives <= 0) {
      _gameOver();
    }

    // Notify listeners that the game has updated
    onUpdate?.call();
  }

  void _checkCollisions() {
    for (int i = 0; i < _entities.length; i++) {
      for (int j = i + 1; j < _entities.length; j++) {
        final entity1 = _entities[i];
        final entity2 = _entities[j];

        if (entity1.collidesWith(entity2)) {
          _handleCollision(entity1, entity2);
        }
      }
    }
  }

  void _handleCollision(Entity entity1, Entity entity2) {
    // Player vs Photon collision
    if ((entity1.type == EntityType.player &&
            entity2.type == EntityType.photon) ||
        (entity1.type == EntityType.photon &&
            entity2.type == EntityType.player)) {
      final player = entity1.type == EntityType.player ? entity1 : entity2;
      final photon = entity1.type == EntityType.photon ? entity1 : entity2;

      _lives--;
      onLivesChanged?.call(_lives);

      photon.markForDeletion();
      AudioService.instance.playSoundEffect('hit');

      // Flash player red
      player.graphic = GraphicComponent(
        color: Colors.red,
        isVisible: true,
      );

      // Reset player color after a short delay
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!player.isDeleted) {
          player.graphic = GraphicComponent(
            color: GameConstants.playerColor,
            isVisible: true,
          );
        }
      });
    }

    // Player vs Energy collision
    if ((entity1.type == EntityType.player &&
            entity2.type == EntityType.energy) ||
        (entity1.type == EntityType.energy &&
            entity2.type == EntityType.player)) {
      final energy = entity1.type == EntityType.energy ? entity1 : entity2;

      _score += 1; // Increment by 1 like original game
      onScoreChanged?.call(_score);

      // Change player direction when energy is collected
      final playerLogic = _player?.logic as PlayerLogicComponent?;
      playerLogic?.reverseDirection();

      // Remove current energy
      energy.markForDeletion();
      _currentEnergy = null;

      AudioService.instance.playSoundEffect('collect');

      // Spawn new energy after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_state == GameState.playing) {
          spawnEnergy();
        }
      });
    }
  }

  void _gameOver() {
    _state = GameState.gameOver;

    SettingsService.instance.setHighScore(_score);
    SettingsService.instance.incrementGamesPlayed();
    SettingsService.instance.addPlayTime(_gameTime.round());

    onStateChanged?.call(_state);
    onGameOver?.call();
  }

  void resetGame() {
    // Clear all entities except atom
    _entities.clear();
    _entityQueue.clear();
    _entitiesToDelete.clear();

    // Reset game variables
    _score = 0;
    _lives = 3;
    _gameTime = 0.0;
    _entityId = 1;
    _currentEnergy = null;

    // Recreate initial entities
    _createInitialEntities();

    _state = GameState.menu;
    onStateChanged?.call(_state);
  }

  // Player input methods
  void onTouchDown() {
    if (_state != GameState.playing) return;
    _isTouching = true;
    _touchStartTime = _gameTime;

    // Set player to touching state
    final playerLogic = _player?.logic as PlayerLogicComponent?;
    playerLogic?.setTouching(true);
  }

  void onTouchUp() {
    if (_state != GameState.playing) return;
    _isTouching = false;

    // Set player to not touching state
    final playerLogic = _player?.logic as PlayerLogicComponent?;
    playerLogic?.setTouching(false);

    // Note: Direction change only happens when collecting energy, not on tap
  }

  void onTouchMove(double deltaX) {
    if (_state != GameState.playing || !_isTouching) return;

    // Long press and drag changes speed
    final touchDuration = _gameTime - _touchStartTime;
    if (touchDuration > 0.3) {
      final playerLogic = _player?.logic as PlayerLogicComponent?;
      if (playerLogic != null) {
        final speedChange = deltaX * 0.01;
        final newSpeed =
            (playerLogic.orbitSpeed + speedChange).clamp(-5.0, 5.0);
        playerLogic.changeOrbitSpeed(newSpeed);
      }
    }
  }

  void spawnEnergy() {
    // Only spawn if no energy currently exists
    if (_currentEnergy != null) return;

    final random = Random();
    final angle = random.nextDouble() * 2 * pi;
    // Spawn energy within reachable orbit area:
    // Min: Player Min Radius (0.2 width) + margin
    // Max: Player Max Radius (0.45 width) - margin
    final maxRadius = GameConstants.screenWidth * 0.43;
    final minRadius = GameConstants.screenWidth * 0.22;

    final radius = minRadius + random.nextDouble() * (maxRadius - minRadius);

    final energy = Entity(
      id: _getNextId(),
      type: EntityType.energy,
      position: PositionComponent(
        position: Vector2D.fromPolar(radius, angle),
      ),
      size: const SizeComponent(15, 15),
      graphic: GraphicComponent(color: GameConstants.energyColor),
      logic: EnergyLogicComponent(), // Add logic for rotation
      collision: CollisionComponent(),
    );

    _currentEnergy = energy;
    _entities.add(energy);
  }

  int _getNextId() => _entityId++;

  void dispose() {
    AudioService.instance.pauseBackgroundMusic();
  }
}
