import 'dart:math';
import 'package:flutter/material.dart';
import 'package:atomic_orbital/models/entity.dart';
import 'package:atomic_orbital/models/vector2d.dart';
import 'package:atomic_orbital/constants/game_constants.dart';

// Position Component
class PositionComponent {
  Vector2D position;

  PositionComponent({Vector2D? position})
      : position = position ?? Vector2D.zero();

  void add(Vector2D offset) {
    position.add(offset);
  }

  void setPosition(Vector2D newPosition) {
    position.x = newPosition.x;
    position.y = newPosition.y;
  }

  double distanceTo(PositionComponent other) {
    return position.distanceTo(other.position);
  }
}

// Size Component
class SizeComponent {
  final double width;
  final double height;

  const SizeComponent(this.width, this.height);

  double get radius => (width + height) / 4;
  double get area => width * height;
}

// Velocity Component
class VelocityComponent {
  Vector2D velocity;

  VelocityComponent({Vector2D? velocity})
      : velocity = velocity ?? Vector2D.zero();

  void add(Vector2D acceleration) {
    velocity.add(acceleration);
  }

  void setVelocity(Vector2D newVelocity) {
    velocity.x = newVelocity.x;
    velocity.y = newVelocity.y;
  }

  void applyFriction(double friction) {
    velocity.multiply(friction);
  }
}

// Graphic Component
class GraphicComponent {
  Color color;
  bool isVisible;

  GraphicComponent({
    this.color = Colors.white,
    this.isVisible = true,
  });

  void render(Canvas canvas, Entity entity, Offset center) {
    if (!isVisible) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final position = Offset(
      center.dx + entity.position.position.x,
      center.dy + entity.position.position.y,
    );

    switch (entity.type) {
      case EntityType.atom:
        canvas.drawCircle(position, entity.size.radius, paint);
        break;
      case EntityType.player:
        canvas.drawCircle(position, entity.size.radius, paint);
        break;
      case EntityType.photon:
        canvas.drawCircle(position, entity.size.radius, paint);
        break;
      case EntityType.energy:
        final rect = Rect.fromCenter(
          center: position,
          width: entity.size.width,
          height: entity.size.height,
        );
        canvas.drawRect(rect, paint);
        break;
      default:
        canvas.drawCircle(position, entity.size.radius, paint);
    }
  }
}

// Logic Component
class LogicComponent {
  LogicComponent();

  void update(Entity entity, double deltaTime) {
    // Base logic - can be overridden by specific components
  }
}

// Collision Component
class CollisionComponent {
  bool isCollidable;

  CollisionComponent({this.isCollidable = true});

  void update(Entity entity, double deltaTime) {
    // Base collision update logic
  }

  bool collidesWith(Entity entity1, Entity entity2) {
    if (!isCollidable || !entity2.collision.isCollidable) return false;

    final distance = entity1.position.distanceTo(entity2.position);
    final combinedRadius = entity1.size.radius + entity2.size.radius;

    return distance <= combinedRadius;
  }
}

// Player Logic Component
class PlayerLogicComponent extends LogicComponent {
  double orbitRadius;
  double orbitSpeed;
  double currentAngle;
  double targetRadius;
  double currentRadius;
  bool isTouching = false;

  // Match original radius constraints
  double get minRadius =>
      GameConstants.screenWidth * 0.2; // 1/5 of screen width
  double get maxRadius =>
      GameConstants.screenWidth * 0.8; // 80% of screen width

  PlayerLogicComponent({
    this.orbitRadius = 0.0, // Will be set dynamically
    this.orbitSpeed = 2.0,
  })  : currentAngle = pi, // Start at bottom
        targetRadius = 0.0, // Will be set dynamically
        currentRadius = 0.0; // Will be set dynamically

  @override
  void update(Entity entity, double deltaTime) {
    // Orbital movement around the atom
    currentAngle += orbitSpeed * deltaTime;

    // Update radius based on touch state
    if (isTouching) {
      // Matches Java: MAX_RADIUS = Display.WIDTH * 0.8 (Original constants)
      // We clamp to 0.45 to ensure it stays on screen (Radius < 0.5)
      targetRadius = GameConstants.screenWidth * 0.45;
    } else {
      // Matches Java: MIN_RADIUS = Display.WIDTH * 1/5 (0.2)
      targetRadius = GameConstants.screenWidth * 0.2;
    }

    // Smoothly interpolate to target radius
    final radiusSpeed = 100.0 * GameConstants.scaleFactor; // pixels per second
    final radiusDiff = targetRadius - currentRadius;
    if (radiusDiff.abs() > 1.0) {
      final radiusChange = radiusSpeed * deltaTime;
      if (radiusDiff > 0) {
        currentRadius += radiusChange;
        if (currentRadius > targetRadius) currentRadius = targetRadius;
      } else {
        currentRadius -= radiusChange;
        if (currentRadius < targetRadius) currentRadius = targetRadius;
      }
    }

    entity.position
        .setPosition(Vector2D.fromPolar(currentRadius, currentAngle));
  }

  void setTouching(bool touching) {
    isTouching = touching;
  }

  void changeOrbitSpeed(double newSpeed) {
    orbitSpeed = newSpeed;
  }

  void reverseDirection() {
    orbitSpeed = -orbitSpeed;
  }
}

// Photon Type Interface
abstract class PhotonType {
  void init(PositionComponent position);
  void update(double deltaTime);
}

// Straight Photon Type
class StraightPhotonType extends PhotonType {
  late PositionComponent position;
  final double speed = 100.0 * GameConstants.scaleFactor;
  late double direction;

  @override
  void init(PositionComponent position) {
    this.position = position;
    direction = position.position.angle;
  }

  @override
  void update(double deltaTime) {
    final velocity = Vector2D.fromPolar(speed, direction);
    position.add(velocity * deltaTime);
  }
}

// Spiral Photon Type
class SpiralPhotonType extends PhotonType {
  late PositionComponent position;
  final double radialSpeed = 60.0 * GameConstants.scaleFactor;
  final double angularSpeed = 80.0 * GameConstants.scaleFactor;
  final int direction; // 1 or -1
  late double initialAngle;

  SpiralPhotonType(this.direction);

  @override
  void init(PositionComponent position) {
    this.position = position;
    initialAngle = position.position.angle;
  }

  @override
  void update(double deltaTime) {
    final currentAngle = position.position.angle;
    final radialVelocity = Vector2D.fromPolar(radialSpeed, currentAngle);
    final angularVelocity =
        Vector2D.fromPolar(angularSpeed * direction, currentAngle + pi / 2);

    final totalVelocity = radialVelocity + angularVelocity;
    position.add(totalVelocity * deltaTime);
  }
}

// Sinus Photon Type
class SinusPhotonType extends PhotonType {
  late PositionComponent position;
  final double radialSpeed = 60.0 * GameConstants.scaleFactor;
  // Reduced angular speed and frequency for smoother curve
  final double angularSpeed = 100.0 * GameConstants.scaleFactor;
  final double frequency = 3.0; // Was 6.0, reduced for less frantic waving
  late double initialAngle;
  double time = 0.0;

  @override
  void init(PositionComponent position) {
    this.position = position;
    initialAngle = position.position.angle;
  }

  @override
  void update(double deltaTime) {
    time += deltaTime;
    final currentAngle = position.position.angle;
    final distance = position.position.magnitude;

    final radialVelocity = Vector2D.fromPolar(radialSpeed, currentAngle);
    final angularVelocity = Vector2D.fromPolar(
        angularSpeed * cos(frequency * time) * distance / 100,
        currentAngle + pi / 2);

    final totalVelocity = radialVelocity + angularVelocity;
    position.add(totalVelocity * deltaTime);
  }
}

// Photon Logic Component
class PhotonLogicComponent extends LogicComponent {
  late PhotonType photonType;
  double spawnTimer;
  bool isSpawning;

  PhotonLogicComponent({required this.photonType})
      : spawnTimer =
            GameConstants.photonAppearTime, // Use appear time for animation
        isSpawning = true;

  @override
  void update(Entity entity, double deltaTime) {
    if (isSpawning) {
      spawnTimer -= deltaTime;

      // Scale up during spawn phase
      final scale = 1.0 - (spawnTimer / GameConstants.photonAppearTime);
      entity.size = SizeComponent(
          GameConstants.photonSize * scale, GameConstants.photonSize * scale);

      if (spawnTimer <= 0) {
        isSpawning = false;
        photonType.init(entity.position);
        // Set final size
        entity.size =
            SizeComponent(GameConstants.photonSize, GameConstants.photonSize);
      }
    } else {
      photonType.update(deltaTime);
    }

    // Delete if too far out (like original: > 200 units)
    // 200 units = Screen Width in scaling logic
    if (entity.position.position.magnitude > 200 * GameConstants.scaleFactor) {
      entity.markForDeletion();
    }
  }
}

// Photon Spawner Logic Component
class PhotonSpawnerLogicComponent extends LogicComponent {
  final List<Entity> entityQueue;
  final int Function() getCurrentScore;
  double spawnTimer = 0.0; // Start at 0 like original
  int entityId = 1;
  final Random random = Random();

  PhotonSpawnerLogicComponent({
    required this.entityQueue,
    required this.getCurrentScore,
  });

  @override
  void update(Entity entity, double deltaTime) {
    // Only spawn when game is active (like original)
    // The game engine will control when this is called

    // Decrement timer (like original)
    spawnTimer -= deltaTime;

    if (spawnTimer <= 0) {
      spawnPhotons();
      // Add interval to timer (like original)
      spawnTimer += GameConstants.photonWaveInterval;
    }
  }

  void spawnPhotons() {
    final score = getCurrentScore();
    // User request: Start with 1, increase with score.
    // Balancing: 1 + score ~/ 3 to avoid screen clutter too fast.
    final count = 1 + score ~/ 3;
    final groupCount = 1 + random.nextInt(min(4, count).toInt());

    // Random type and direction for this batch
    final type = random.nextInt(3);
    final direction = random.nextBool() ? 1 : -1;

    var startPos = 2 * pi * random.nextDouble();

    for (int i = 1; i <= count; i++) {
      // Create photon with current start position
      final photon = Entity(
        id: entityId++,
        type: EntityType.photon,
        position: PositionComponent(
            position: Vector2D.fromPolar(GameConstants.atomSize / 2,
                startPos)), // Match original: ATOM_SIZE / 2
        size: SizeComponent(GameConstants.photonSize, GameConstants.photonSize),
        velocity: VelocityComponent(),
        graphic: GraphicComponent(color: GameConstants.photonColor),
        logic: PhotonLogicComponent(
            photonType: _createPhotonType(type, direction)),
        collision: CollisionComponent(),
      );

      entityQueue.add(photon);

      // Update position for next photon
      startPos += (2 * pi / groupCount); // 360 / groupCount in radians

      // Add spacing between groups like original
      if (i % groupCount == 0) {
        // Add 10 degrees spacing between groups
        startPos += 10 * pi / 180; // Convert degrees to radians
      }

      // Keep within 0..2pi for cleanliness (optional but good practice)
      if (startPos > 2 * pi) startPos -= 2 * pi;
    }
  }

  PhotonType _createPhotonType(int type, int direction) {
    switch (type) {
      case 0:
        return StraightPhotonType();
      case 1:
        return SpiralPhotonType(direction);
      case 2:
        return SinusPhotonType();
      default:
        return StraightPhotonType();
    }
  }
}

// Energy Logic Component (for individual energy entities)
class EnergyLogicComponent extends LogicComponent {
  double time = 0.0;

  @override
  void update(Entity entity, double deltaTime) {
    time += deltaTime;

    // Make energy pulse/glow by changing color intensity
    final intensity = 0.5 + 0.5 * sin(time * 3.0); // Pulse every ~2 seconds
    final color = Color.fromARGB(
      255,
      (GameConstants.energyColor.red * intensity).round(),
      (GameConstants.energyColor.green * intensity).round(),
      (GameConstants.energyColor.blue * intensity).round(),
    );

    entity.graphic = GraphicComponent(
      color: color,
    );
  }
}

// Energy Spawner Logic Component
class EnergySpawnerLogicComponent extends LogicComponent {
  final List<Entity> entityQueue;
  double spawnTimer = 0.0;
  int entityId = 1;
  final Random random = Random();

  EnergySpawnerLogicComponent({
    required this.entityQueue,
  });

  @override
  void update(Entity entity, double deltaTime) {
    spawnTimer += deltaTime;

    // Spawn energy every 3-5 seconds
    if (spawnTimer >= 3.0 + random.nextDouble() * 2.0) {
      spawnTimer = 0.0;
      spawnEnergy();
    }
  }

  void spawnEnergy() {
    final angle = random.nextDouble() * 2 * pi;
    final radius = GameConstants.atomSize + random.nextDouble() * 100;

    final energy = Entity(
      id: entityId++,
      type: EntityType.energy,
      position: PositionComponent(position: Vector2D.fromPolar(radius, angle)),
      size: const SizeComponent(15, 15),
      graphic: GraphicComponent(color: GameConstants.energyColor),
      collision: CollisionComponent(),
    );

    entityQueue.add(energy);
  }
}
