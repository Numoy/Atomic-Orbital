import 'dart:math';

import 'package:atomic_orbital/game/game_engine.dart';
import 'package:atomic_orbital/game/gameplay_feedback.dart';
import 'package:atomic_orbital/models/components.dart';
import 'package:flutter_test/flutter_test.dart';

GameEngine _playing() {
  final engine = GameEngine(random: Random(17))..startGame();
  engine.player.collision.isCollidable = false;
  engine.onTouchDown();
  engine.advanceFrame();
  return engine;
}

Offset _position(GameEngine engine) => Offset(
    engine.player.position.position.x, engine.player.position.position.y);

void _stationary(GameEngine engine) {
  engine.onTouchUp();
  final player = engine.player.logic as PlayerLogicComponent;
  player
    ..currentAngle = 0
    ..currentRadius = player.minRadius
    ..speedRadius = 0
    ..speedOrbit = 0;
  player.positionPlayer(engine.player);
  (engine.energy.logic as EnergyLogicComponent)
    ..onOrbit = 0
    ..angle = 180;
}

void _hitPlayer(GameEngine engine) {
  _stationary(engine);
  engine.player.collision.isCollidable = true;
  engine.photons.first.position
      .setPosition(engine.player.position.position.copy());
  engine.advanceFrame();
}

List<Object> _snapshot(GameEngine engine) => [
      engine.state,
      engine.gameTime,
      engine.score,
      engine.health,
      for (final entity in engine.entities)
        [
          entity.id,
          entity.type,
          entity.position.position.x,
          entity.position.position.y,
          entity.size.radius
        ],
      for (final orbit in engine.orbits)
        [orbit.radius, orbit.rotation, orbit.direction],
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'trail samples actual positions at most 60Hz and stays short and read only',
      () {
    final engine = _playing();
    addTearDown(engine.dispose);
    final feedback = GameplayFeedback()..sync(engine);
    for (var tick = 0; tick < 360; tick++) {
      engine.update(1 / 120);
      feedback
        ..sync(engine)
        ..sync(engine);
      expect(feedback.trail.length, lessThanOrEqualTo(12));
      expect(feedback.trail.last.position, _position(engine));
      expect(feedback.trail.first.time,
          greaterThanOrEqualTo(engine.gameTime - .18));
    }
    final samples = feedback.trail;
    for (var i = 1; i < samples.length; i++) {
      expect(samples[i].time - samples[i - 1].time,
          greaterThanOrEqualTo(1 / 60 - 1e-9));
    }
    expect(() => samples.clear(), throwsUnsupportedError);
    expect(feedback.trail, samples);
  });

  test('collection records pickup position and clears the old direction trail',
      () {
    final engine = _playing();
    addTearDown(engine.dispose);
    final feedback = GameplayFeedback()..sync(engine);
    for (var frame = 0; frame < 4; frame++) {
      engine.advanceFrame();
      feedback.sync(engine);
    }
    final time = engine.gameTime;
    feedback.collect(const Offset(17, 29), time);
    expect(feedback.collection, (position: const Offset(17, 29), time: time));
    expect(feedback.trail, isEmpty);
    feedback.sync(engine);
    expect(feedback.trail, isEmpty);
    engine.advanceFrame();
    feedback.sync(engine);
    expect(feedback.trail, hasLength(1));
    expect(feedback.trail.single.position, _position(engine));
    feedback.reset();
    expect(feedback.trail, isEmpty);
    expect(feedback.collection, isNull);
    expect(feedback.hit, isNull);
    expect(engine.gameTime, greaterThan(time));
  });

  test('real nonfatal damage records one hit and effects expire in game time',
      () {
    final engine = _playing();
    addTearDown(engine.dispose);
    final feedback = GameplayFeedback()..sync(engine);
    _hitPlayer(engine);
    feedback.sync(engine);
    expect(engine.state, GameState.playing);
    expect(engine.health, 55);
    final hit = feedback.hit;
    expect(hit, (position: _position(engine), time: engine.gameTime));
    feedback.collect(const Offset(10, 20), engine.gameTime);
    engine.player.collision.isCollidable = false;
    for (var frame = 0; frame < 2; frame++) {
      engine.advanceFrame();
      feedback.sync(engine);
    }
    expect(feedback.hit, hit, reason: 'Regeneration must not restart a hit');
    for (var frame = 0; frame < 20; frame++) {
      engine.advanceFrame();
      feedback.sync(engine);
    }
    expect(feedback.hit, isNull);
    expect(feedback.collection, isNotNull);
    for (var frame = 0; frame < 12; frame++) {
      engine.advanceFrame();
      feedback.sync(engine);
    }
    expect(feedback.collection, isNull);
  });

  test('a ready baseline catches damage before the first playing sync', () {
    final engine = GameEngine(random: Random(17))..startGame();
    addTearDown(engine.dispose);
    final feedback = GameplayFeedback()..sync(engine);
    expect(feedback.trail, isEmpty);
    engine.player.collision.isCollidable = false;
    engine.onTouchDown();
    engine.advanceFrame();
    _hitPlayer(engine);
    feedback.sync(engine);
    expect(feedback.hit, (position: _position(engine), time: engine.gameTime));
  });

  test('pause freezes trails and effects until simulation resumes', () {
    final engine = _playing();
    addTearDown(engine.dispose);
    final feedback = GameplayFeedback()..sync(engine);
    _hitPlayer(engine);
    feedback
      ..sync(engine)
      ..collect(const Offset(10, 20), engine.gameTime);
    engine.advanceFrame();
    feedback.sync(engine);
    final samples = feedback.trail;
    final collection = feedback.collection;
    final hit = feedback.hit;
    engine.pauseGame();
    engine.update(20);
    feedback.sync(engine);
    expect(feedback.trail, samples);
    expect(feedback.collection, collection);
    expect(feedback.hit, hit);
    engine.player.collision.isCollidable = false;
    engine.resumeGame();
    engine.update(.6);
    feedback.sync(engine);
    expect(feedback.collection, isNull);
    expect(feedback.hit, isNull);
    expect(feedback.trail, hasLength(1));
  });

  test('ready, menu and replayed time clear all presentation state', () {
    final engine = _playing();
    final replay = _playing();
    addTearDown(engine.dispose);
    addTearDown(replay.dispose);
    final feedback = GameplayFeedback();
    engine.update(.5);
    feedback
      ..sync(engine)
      ..collect(const Offset(10, 20), engine.gameTime);
    feedback.sync(replay);
    expect(feedback.collection, isNull);
    expect(feedback.hit, isNull);
    expect(feedback.trail.single.position, _position(replay));
    replay.startGame();
    feedback.sync(replay);
    expect(feedback.trail, isEmpty);
    feedback.collect(Offset.zero, 0);
    replay.resetGame();
    feedback.sync(replay);
    expect(feedback.collection, isNull);
    expect(feedback.trail, isEmpty);
  });

  test('already-playing scored fixtures baseline without a false hit', () {
    final engine = _playing();
    addTearDown(engine.dispose);
    _stationary(engine);
    for (final photon in engine.photons) {
      photon.collision.isCollidable = false;
    }
    engine.player.collision.isCollidable = true;
    (engine.energy.logic as EnergyLogicComponent).angle = 0;
    engine.advanceFrame();
    expect(engine.score, 1);
    final before = _snapshot(engine);
    final feedback = GameplayFeedback()..sync(engine);
    expect(feedback.trail, hasLength(1));
    expect(feedback.hit, isNull);
    expect(feedback.collection, isNull);
    expect(_snapshot(engine), before);
    engine.startGame();
    feedback.sync(engine);
    expect(feedback.trail, isEmpty);
  });

  test('feedback never changes simulation, score, callbacks or future spawning',
      () {
    final rendered = _playing();
    final control = _playing();
    addTearDown(rendered.dispose);
    addTearDown(control.dispose);
    final feedback = GameplayFeedback();
    void scoreChanged(int _) {}
    rendered.onScoreChanged = scoreChanged;
    for (var frame = 0; frame < 240; frame++) {
      final before = _snapshot(rendered);
      feedback.sync(rendered);
      if (frame % 30 == 0) {
        feedback.collect(const Offset(10, 20), rendered.gameTime);
      }
      expect(_snapshot(rendered), before);
      expect(rendered.onScoreChanged, same(scoreChanged));
      rendered.advanceFrame();
      control.advanceFrame();
      expect(_snapshot(rendered), _snapshot(control));
    }
  });
}
