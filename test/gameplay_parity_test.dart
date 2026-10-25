import 'dart:math';

import 'package:atomic_orbital/constants/game_constants.dart';
import 'package:atomic_orbital/game/game_engine.dart';
import 'package:atomic_orbital/models/components.dart';
import 'package:atomic_orbital/models/entity.dart';
import 'package:atomic_orbital/models/vector2d.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FixedRandom implements Random {
  @override
  bool nextBool() => true;
  @override
  double nextDouble() => 0;
  @override
  int nextInt(int max) => 0;
}

GameEngine _engine({bool hardcore = false}) {
  final engine = GameEngine(random: _FixedRandom());
  engine.startGame(hardcore: hardcore);
  return engine;
}

void _stationaryPlayer(GameEngine engine) {
  final player = engine.player.logic as PlayerLogicComponent;
  engine.onTouchUp();
  player
    ..speedOrbit = 0
    ..currentAngle = 0
    ..currentRadius = player.minRadius
    ..speedRadius = 0;
  player.positionPlayer(engine.player);
}

void _collectEnergy(GameEngine engine) {
  final energy = engine.energy.logic as EnergyLogicComponent;
  energy
    ..onOrbit = 0
    ..angle = 0;
  engine.advanceFrame();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.initialize();
  });

  test('default world uses the accepted reference geometry on every run', () {
    final engine = _engine();
    addTearDown(engine.dispose);
    expect(engine.width, 1080);
    expect(engine.height, 1857);
    expect(engine.atom.position.position.x, 540);
    expect(engine.atom.position.position.y, 928);
    expect(engine.player.position.position.y, 1279);
    expect(engine.orbits.map((orbit) => orbit.radius), [216, 486]);
    expect(GameConstants.referenceCanvasHeight, 1794);
    expect(
        GameConstants.referenceLogicalWidth * GameConstants.referencePixelRatio,
        1080);
    expect(
        GameConstants.referenceLogicalCanvasHeight *
            GameConstants.referencePixelRatio,
        1794);

    engine.onTouchDown();
    engine.update(1);
    engine.startGame(hardcore: true);
    expect(engine.width, 1080);
    expect(engine.height, 1857);
    expect(engine.player.position.position.y, 1279);
    expect(engine.gameTime, 0);
  });

  test('explicit Java oracle dimensions cannot resize another live engine', () {
    final engine = _engine()..onTouchDown();
    addTearDown(engine.dispose);
    engine.update(0.5);
    final player = engine.player;
    final energy = engine.energy;
    final photon = engine.photons.single;
    final gameTime = engine.gameTime;
    final position = player.position.position.copy();
    final other = GameEngine(width: 360, height: 640);
    addTearDown(other.dispose);
    other.startGame();
    final anotherReference = GameEngine();
    addTearDown(anotherReference.dispose);

    expect(other.width, 360);
    expect(other.height, 640);
    expect(anotherReference.width, 1080);
    expect(anotherReference.height, 1857);
    expect(engine.player, same(player));
    expect(engine.energy, same(energy));
    expect(engine.photons.single, same(photon));
    expect(engine.gameTime, gameTime);
    expect(engine.player.position.position.x, position.x);
    expect(engine.player.position.position.y, position.y);
    expect(engine.width, 1080);
    expect(engine.height, 1857);
    engine.update(1 / 60);
    expect(engine.gameTime, greaterThan(gameTime));
  });

  test(
      'ready freezes game until pointer down and retains original prompt pulse',
      () {
    final engine = _engine();
    expect(engine.state, GameState.ready);
    expect(engine.player.position.position.y, 1279);
    engine.advanceFrame();
    expect(engine.startAlpha, 254);
    engine.advanceFrame();
    expect(engine.startAlpha, 252);
    expect(engine.gameTime, 0);
    expect(engine.photons, isEmpty);
    engine.onTouchDown();
    engine.advanceFrame();
    expect(engine.state, GameState.playing);
    final logic = engine.player.logic as PlayerLogicComponent;
    expect(logic.currentAngle, 3);
    expect(logic.currentRadius, 356);
    expect(logic.speedRadius, 5);
    expect(engine.photons, hasLength(1));
  });

  test('30, 60, 90 and 120 Hz produce identical gameplay after equal time', () {
    final reference = _engine()..onTouchDown();
    for (var i = 0; i < 120; i++) {
      reference.update(1 / 60);
    }
    for (final refreshRate in [30, 60, 90, 120]) {
      final engine = _engine()..onTouchDown();
      for (var i = 0; i < refreshRate * 2; i++) {
        engine.update(1 / refreshRate);
      }
      expect(engine.player.position.position.x,
          reference.player.position.position.x,
          reason: '$refreshRate Hz');
      expect(engine.player.position.position.y,
          reference.player.position.position.y,
          reason: '$refreshRate Hz');
      expect(engine.gameTime, reference.gameTime, reason: '$refreshRate Hz');
      expect(engine.score, reference.score);
      expect(engine.health, reference.health);
      expect(engine.photons.length, reference.photons.length);
      for (var i = 0; i < reference.photons.length; i++) {
        expect(engine.photons[i].position.position.x,
            reference.photons[i].position.position.x);
        expect(engine.photons[i].position.position.y,
            reference.photons[i].position.position.y);
      }
    }
  });

  test('a stall preserves simulation order when catching up elapsed time', () {
    final regular = _engine()..onTouchDown();
    final stalled = _engine()..onTouchDown();
    for (var i = 0; i < 120; i++) {
      regular.update(1 / 60);
    }
    stalled.update(2);
    expect(stalled.gameTime, regular.gameTime);
    expect(
        stalled.player.position.position.x, regular.player.position.position.x);
    expect(
        stalled.player.position.position.y, regular.player.position.position.y);
    expect(stalled.health, regular.health);
    expect(stalled.photons.length, regular.photons.length);
    expect((stalled.photons.first.logic as PhotonLogicComponent).polarRadius,
        (regular.photons.first.logic as PhotonLogicComponent).polarRadius);
  });

  test('pause and cancel release hold without advancing simulation time', () {
    final engine = _engine()..onTouchDown();
    engine.update(1 / 60);
    final player = engine.player.logic as PlayerLogicComponent;
    engine.pauseGame();
    final pausedTime = engine.gameTime;
    final radius = player.currentRadius;
    engine.update(10);
    expect(engine.gameTime, pausedTime);
    expect(player.currentRadius, radius);
    expect(player.isTouching, isFalse);
    engine.resumeGame();
    engine.update(1 / 60);
    expect(player.speedRadius, 0);
    engine.onTouchDown();
    engine.onTouchCancel();
    engine.update(1 / 60);
    expect(player.speedRadius, -5);
  });

  test('photons grow for 101 ticks and start moving on their release tick', () {
    final engine = _engine()..onTouchDown();
    engine.advanceFrame();
    final first = engine.photons.single;
    final logic = first.logic as PhotonLogicComponent;
    expect(logic.radius, 0);
    expect(logic.growing, isTrue);
    final initialRadius = logic.polarRadius;
    for (var i = 0; i < 100; i++) {
      engine.advanceFrame();
    }
    expect(engine.photons, hasLength(1));
    expect(logic.radius, first.size.radius);
    expect(logic.growing, isTrue);
    expect(logic.polarRadius, initialRadius);
    engine.advanceFrame();
    expect(engine.photons, hasLength(2));
    expect(logic.growing, isFalse);
    expect(logic.polarRadius, float32(initialRadius + logic.radialVelocity));
    expect((engine.photons.last.logic as PhotonLogicComponent).radius, 0);
  });

  test('energy instantly respawns on an orbit and reverses direction', () {
    final engine = _engine()..onTouchDown();
    engine.advanceFrame();
    _stationaryPlayer(engine);
    final identity = engine.energy;
    _collectEnergy(engine);
    final player = engine.player.logic as PlayerLogicComponent;
    final energy = engine.energy.logic as EnergyLogicComponent;
    expect(engine.score, 1);
    expect(player.direction, -1);
    expect(engine.energy, same(identity));
    expect(energy.onOrbit, 0);
    expect(energy.angle, 90);
    expect(engine.entities.where((e) => e.type == EntityType.energy),
        hasLength(1));
    engine.pauseGame();
    engine.update(1);
    engine.resumeGame();
    expect(engine.energy, same(identity));
  });

  test('score 5 animates the existing orbit for exactly 60 ticks', () {
    final engine = _engine()..onTouchDown();
    engine.advanceFrame();
    _stationaryPlayer(engine);
    for (var i = 0; i < 5; i++) {
      _collectEnergy(engine);
    }
    expect(engine.score, 5);
    expect(engine.orbits, hasLength(2));
    final energy = engine.energy.logic as EnergyLogicComponent;
    energy.angle = 180;
    for (var i = 0; i < 59; i++) {
      engine.advanceFrame();
    }
    expect(engine.orbits, hasLength(2));
    engine.advanceFrame();
    expect(engine.orbits, hasLength(3));
    expect(engine.orbits.map((o) => o.radius), [216.0, 351.0, 486.0]);
    expect(engine.orbits.map((o) => o.direction), [1, -1, 1]);
  });

  test('released game uses strict square bounds including diagonal overlaps',
      () {
    Entity entity(double x, double y, double radius) => Entity(
          id: 1,
          type: EntityType.photon,
          position: PositionComponent(position: Vector2D(x, y)),
          size: SizeComponent(radius * 2, radius * 2),
        );
    final player = entity(0, 0, 10);
    expect(player.collidesWith(entity(24, 24, 15)), isTrue);
    expect(player.collidesWith(entity(25, 0, 15)), isFalse);
  });

  test('normal damage regenerates, hardcore ends on its first hit', () {
    for (final hardcore in [false, true]) {
      final engine = _engine(hardcore: hardcore)..onTouchDown();
      engine.advanceFrame();
      _stationaryPlayer(engine);
      engine.photons.single.position.setPosition(Vector2D(
          engine.player.position.position.x,
          engine.player.position.position.y));
      engine.advanceFrame();
      expect(engine.health, hardcore ? -30 : 55);
      expect(engine.state, hardcore ? GameState.gameOver : GameState.playing);
      if (!hardcore) {
        engine.advanceFrame();
        expect(engine.health, float32(55 + float32(0.1)));
        expect(engine.backgroundRed, 125);
      }
    }
  });

  test('adjacent photon hits retain the release removal order', () {
    final engine = _engine()..onTouchDown();
    for (var frame = 0; frame < 102; frame++) {
      engine.advanceFrame();
    }
    expect(engine.photons, hasLength(2));
    _stationaryPlayer(engine);
    for (final photon in engine.photons) {
      (photon.logic as PhotonLogicComponent).growing = true;
      photon.position.setPosition(Vector2D(
        engine.player.position.position.x,
        engine.player.position.position.y,
      ));
    }
    engine.advanceFrame();
    expect(engine.health, 55);
    expect(engine.photons, hasLength(1));
    engine.advanceFrame();
    expect(engine.health, float32(float32(55 + float32(0.1)) - 45));
    expect(engine.photons, isEmpty);
  });

  test('restart clears timers, particles, health, input and progression', () {
    final engine = _engine()..onTouchDown();
    engine.update(0.5);
    engine.startGame(hardcore: true);
    expect(engine.state, GameState.ready);
    expect(engine.health, 100);
    expect(engine.score, 0);
    expect(engine.gameTime, 0);
    expect(engine.photons, isEmpty);
    expect(engine.orbits, hasLength(2));
    expect((engine.player.logic as PlayerLogicComponent).isTouching, isFalse);
    expect((engine.player.logic as PlayerLogicComponent).currentRadius, 351);
  });

  test(
      'new records use the previous mode best, exclude ties and reset on replay',
      () async {
    final settings = SettingsService.instance;
    for (final hardcore in [false, true]) {
      for (final result in [
        (score: 0, best: 0, record: false),
        (score: 1, best: 0, record: true),
        (score: 2, best: 1, record: true),
        (score: 1, best: 1, record: false),
        (score: 1, best: 2, record: false),
      ]) {
        await settings.resetSettings();
        settings.setHighScore(result.best, hardcore: hardcore);
        settings.setHighScore(99, hardcore: !hardcore);
        final engine = _engine(hardcore: hardcore)..onTouchDown();
        engine.advanceFrame();
        _stationaryPlayer(engine);
        for (var point = 0; point < result.score; point++) {
          _collectEnergy(engine);
        }
        (engine.energy.logic as EnergyLogicComponent).angle = 180;
        expect(engine.score, result.score);
        expect(engine.isNewHighScore, isFalse);
        var observedRecord = false;
        engine.onStateChanged = (state) {
          if (state == GameState.gameOver) {
            observedRecord = engine.isNewHighScore;
          }
        };
        for (var hit = 0; hit < (hardcore ? 1 : 3); hit++) {
          for (var frame = 0; engine.photons.isEmpty && frame < 102; frame++) {
            engine.advanceFrame();
          }
          expect(engine.photons, isNotEmpty);
          final photon = engine.photons.first;
          (photon.logic as PhotonLogicComponent).growing = true;
          photon.position.setPosition(engine.player.position.position.copy());
          engine.advanceFrame();
        }
        expect(engine.state, GameState.gameOver);
        expect(engine.isNewHighScore, result.record);
        expect(observedRecord, result.record,
            reason: 'The result must be ready when the screen is notified');
        expect(hardcore ? settings.hardcoreHighScore : settings.highScore,
            max(result.score, result.best));
        expect(hardcore ? settings.highScore : settings.hardcoreHighScore, 99);
        engine.startGame(hardcore: hardcore);
        expect(engine.isNewHighScore, isFalse);
        engine.resetGame();
        expect(engine.isNewHighScore, isFalse);
        engine.dispose();
      }
    }
  });
}
