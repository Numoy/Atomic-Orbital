import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:atomic_orbital/game/game_engine.dart';
import 'package:atomic_orbital/models/components.dart';
import 'package:atomic_orbital/models/entity.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

GameEngine _startEngine(
    {double width = 1080, double height = 1920, bool hardcore = false}) {
  final engine = GameEngine(width: width, height: height, random: Random(41));
  engine.startGame(hardcore: hardcore);
  (engine.energy.logic as EnergyLogicComponent).angle = 180;
  engine.onTouchDown();
  engine.advanceFrame();
  engine.onTouchUp();
  final player = engine.player.logic as PlayerLogicComponent;
  player.speedOrbit = 0;
  player.currentAngle = 0;
  player.currentRadius = player.minRadius;
  player.speedRadius = 0;
  player.positionPlayer(engine.player);
  expect(engine.score, 0);
  return engine;
}

void _advance(GameEngine engine) {
  for (final photon in engine.photons) {
    photon.collision.isCollidable = false;
  }
  engine.advanceFrame();
}

void _pickup(GameEngine engine) {
  final score = engine.score;
  final energy = engine.energy.logic as EnergyLogicComponent;
  energy.onOrbit = 0;
  energy.angle = 0;
  _advance(engine);
  expect(engine.score, score + 1);
  energy.angle = 180;
}

// These expectations are emitted by the APK's unmodified Java controllers.
// Regenerate with scripts/generate_release_oracle.py, never from Dart output.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.initialize();
  });
  final oracle = jsonDecode(
    File('test/oracle/release_41.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  for (final trace in oracle['players'] as List<dynamic>) {
    final width = trace['width'] as int;
    final height = trace['height'] as int;
    test('release 41 player input and shrink trace at ${width}x$height', () {
      final logic = PlayerLogicComponent(
        screenWidth: width,
        screenHeight: height,
      );
      final radius = (width ~/ 35).toDouble();
      final player = Entity(
        id: 1,
        type: EntityType.player,
        position: PositionComponent(),
        size: SizeComponent(radius * 2, radius * 2),
        logic: logic,
      );
      logic.positionPlayer(player);

      void compare(Map<String, dynamic> sample) {
        final actual = {
          'angle': logic.currentAngle,
          'radius': logic.currentRadius,
          'radialVelocity': logic.speedRadius,
          'x': player.position.position.x,
          'y': player.position.position.y,
          'size': player.size.radius,
          'direction': logic.direction,
        };
        for (final entry in actual.entries) {
          expect(
            entry.value,
            float32(sample[entry.key] as num),
            reason: '${entry.key} at original tick ${sample['tick']}',
          );
        }
      }

      compare(trace['initial'] as Map<String, dynamic>);
      final samples = {
        for (final sample in trace['samples'] as List<dynamic>)
          sample['tick'] as int: sample as Map<String, dynamic>,
      };
      for (var tick = 0; tick < 120; tick++) {
        logic.setTouching(
          tick < 18 || (tick >= 36 && tick < 60) || tick >= 90,
        );
        if (tick == 45 || tick == 80) logic.reverseDirection();
        if (tick == 70) logic.shrink();
        if (tick == 95) logic.updateSpeed(3);
        logic.update(player, 1 / 60);
        final sample = samples[tick];
        if (sample != null) compare(sample);
      }
    });
  }

  for (final trace in oracle['photons'] as List<dynamic>) {
    final width = trace['width'] as int;
    final height = trace['height'] as int;
    final name = (trace['type'] as String).toLowerCase();
    final direction = trace['direction'] as int;
    test('release 41 $name photon direction $direction at ${width}x$height',
        () {
      final logic = PhotonLogicComponent(
        screenWidth: width,
        screenHeight: height,
        trajectory: PhotonTrajectory.values.byName(name),
        angle: 358,
        direction: direction,
      )..growing = false;
      final photon = Entity(
        id: 1,
        type: EntityType.photon,
        position: PositionComponent(),
        size: const SizeComponent(0, 0),
        logic: logic,
      );
      final samples = {
        for (final sample in trace['samples'] as List<dynamic>)
          sample['tick'] as int: sample as Map<String, dynamic>,
      };
      for (var tick = 0; tick < 120; tick++) {
        logic.update(photon, 1 / 60);
        final sample = samples[tick];
        if (sample == null) continue;
        final actual = {
          'angle': logic.polarAngle,
          'radius': logic.polarRadius,
          'x': photon.position.position.x,
          'y': photon.position.position.y,
        };
        for (final entry in actual.entries) {
          expect(
            entry.value,
            float32(sample[entry.key] as num),
            reason: '${entry.key} at original tick $tick',
          );
        }
        expect(photon.isDeleted, isFalse);
      }
    });
  }

  for (final trace in oracle['orbits'] as List<dynamic>) {
    final width = trace['width'] as int;
    test('release 41 orbit expansion at width $width', () {
      final engine =
          _startEngine(width: width.toDouble(), height: width * 16 / 9);
      addTearDown(engine.dispose);
      final samples = {
        for (final sample in trace['samples'] as List<dynamic>)
          sample['tick'] as int: sample as Map<String, dynamic>,
      };
      for (var milestone = 0; milestone < 3; milestone++) {
        final targetScore = [5, 10, 20][milestone];
        while (engine.score < targetScore) {
          _pickup(engine);
        }
        for (var tick = 0; tick < 60; tick++) {
          _advance(engine);
          final sample = samples[milestone * 60 + tick];
          if (sample == null) continue;
          expect(
            engine.orbits.map((orbit) => orbit.radius),
            (sample['radii'] as List<dynamic>)
                .map((value) => float32(value as num)),
            reason: 'milestone $targetScore, animation tick $tick',
          );
        }
      }
    });
  }

  for (final trace in oracle['health'] as List<dynamic>) {
    final hardcore = trace['hardcore'] as bool;
    test('release 41 health regeneration and damage, hardcore $hardcore', () {
      final engine = _startEngine(hardcore: hardcore);
      addTearDown(engine.dispose);
      while (engine.score < 10) {
        _pickup(engine);
      }
      for (var tick = 11; tick <= 101; tick++) {
        _advance(engine);
      }
      expect(engine.photons.length, 4);
      final samples = {
        for (final sample in trace['samples'] as List<dynamic>)
          sample['tick'] as int: sample as Map<String, dynamic>,
      };
      final finalTick = hardcore ? 0 : 90;
      for (var tick = 0; tick <= finalTick; tick++) {
        for (final photon in engine.photons) {
          photon.collision.isCollidable = false;
        }
        if (tick == 0 || tick == 30 || tick == 90) {
          final photon = engine.photons.first;
          (photon.logic as PhotonLogicComponent).growing = true;
          photon.position.setPosition(engine.player.position.position.copy());
          photon.collision.isCollidable = true;
        }
        engine.advanceFrame();
        final sample = samples[tick];
        if (sample != null) {
          expect(engine.health, float32(sample['health'] as num),
              reason: 'tick $tick');
        }
      }
      expect(engine.state, GameState.gameOver);
    });
  }

  test('release 41 wave counts and 101-update growth cadence', () {
    final engine = _startEngine();
    addTearDown(engine.dispose);
    final samples = {
      for (final sample in oracle['waves'] as List<dynamic>)
        sample['tick'] as int: sample as Map<String, dynamic>,
    };
    for (var tick = 0; tick <= 202; tick++) {
      if (tick > 0 && tick <= 10) {
        _pickup(engine);
      } else if (tick > 0) {
        _advance(engine);
      }
      final sample = samples[tick];
      if (sample == null) continue;
      final photons = engine.photons;
      expect(photons.length, sample['count'], reason: 'tick $tick');
      expect(
        photons
            .where((photon) => (photon.logic as PhotonLogicComponent).growing)
            .length,
        sample['growing'],
        reason: 'growing at tick $tick',
      );
      expect(
        (photons.first.logic as PhotonLogicComponent).radius,
        float32(sample['firstRadius'] as num),
        reason: 'growth radius at tick $tick',
      );
    }
  });
}
