import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:atomic_orbital/models/entity.dart';
import 'package:atomic_orbital/models/vector2d.dart';

final _floatBuffer = Float32List(1);

// The released Java game stores every motion value as a 32-bit float.
double float32(num value) {
  _floatBuffer[0] = value.toDouble();
  return _floatBuffer[0];
}

final double javaDegreesToRadians = float32(0.017453292);

class PositionComponent {
  Vector2D position;

  PositionComponent({Vector2D? position})
      : position = position ?? Vector2D.zero();

  void add(Vector2D offset) => position.add(offset);
  void setPosition(Vector2D value) => position = value;
  double distanceTo(PositionComponent other) =>
      position.distanceTo(other.position);
}

class SizeComponent {
  final double width;
  final double height;

  const SizeComponent(this.width, this.height);
  double get radius => (width + height) / 4;
}

class VelocityComponent {
  Vector2D velocity;
  VelocityComponent({Vector2D? velocity})
      : velocity = velocity ?? Vector2D.zero();
}

class GraphicComponent {
  Color color;
  bool isVisible;

  GraphicComponent({this.color = Colors.white, this.isVisible = true});

  void render(Canvas canvas, Entity entity, Offset center) {
    if (!isVisible) return;
    canvas.drawCircle(
      Offset(entity.position.position.x, entity.position.position.y),
      entity.size.radius,
      Paint()..color = color,
    );
  }
}

class LogicComponent {
  void update(Entity entity, double deltaTime) {}
}

class CollisionComponent {
  bool isCollidable;
  CollisionComponent({this.isCollidable = true});

  void update(Entity entity, double deltaTime) {}

  bool collidesWith(Entity first, Entity second) {
    if (!isCollidable || !second.collision.isCollidable) return false;
    final distance = first.position.position - second.position.position;
    final extent = float32(first.size.radius + second.size.radius);
    return float32(distance.x).abs() < extent &&
        float32(distance.y).abs() < extent;
  }
}

class PlayerLogicComponent extends LogicComponent {
  final int screenWidth;
  final int screenHeight;
  late final double minRadius;
  late final double maxRadius;
  late final double speedRadiusBasis;
  late final double accRadius;
  late double speedRadiusLimit;
  late double currentRadius;
  double currentAngle = 0;
  double speedRadius = 0;
  double speedOrbit = 3;
  int direction = 1;
  bool isTouching = false;
  bool animation = false;
  int animCount = 0;

  PlayerLogicComponent({required num screenWidth, required num screenHeight})
      : screenWidth = screenWidth.toInt(),
        screenHeight = screenHeight.toInt() {
    minRadius = (this.screenWidth ~/ 5).toDouble();
    maxRadius = ((this.screenWidth * 9) ~/ 20).toDouble();
    speedRadiusBasis = (this.screenWidth ~/ 50).toDouble();
    speedRadiusLimit = float32(speedRadiusBasis / 2);
    accRadius = (this.screenWidth ~/ 200).toDouble();
    currentRadius = float32(float32(minRadius + maxRadius) / 2);
  }

  void positionPlayer(Entity entity) {
    final angle = float32(currentAngle * javaDegreesToRadians);
    entity.position.setPosition(Vector2D(
      float32(screenWidth ~/ 2 + float32(currentRadius * float32(sin(angle)))),
      float32(screenHeight ~/ 2 + float32(currentRadius * float32(cos(angle)))),
    ));
  }

  @override
  void update(Entity entity, double deltaTime) {
    currentAngle = float32(currentAngle + float32(direction * speedOrbit));
    if (currentAngle < 0) currentAngle = float32(currentAngle + 360);
    if (currentAngle >= 360) currentAngle = float32(currentAngle - 360);
    if (isTouching) {
      speedRadius = float32(speedRadius + accRadius);
      if (speedRadius > speedRadiusLimit) speedRadius = speedRadiusLimit;
    } else {
      speedRadius = float32(speedRadius - accRadius);
      if (speedRadius < -speedRadiusLimit) speedRadius = -speedRadiusLimit;
    }
    currentRadius = float32(currentRadius + speedRadius);
    currentRadius = currentRadius.clamp(minRadius, maxRadius);
    positionPlayer(entity);
    if (animation) {
      final radius = float32(entity.size.radius * float32(0.99));
      entity.size = SizeComponent(radius * 2, radius * 2);
      animCount++;
      if (animCount > 30) {
        animation = false;
        animCount = 0;
      }
    }
  }

  void setTouching(bool touching) => isTouching = touching;
  void reverseDirection() => direction = -direction;
  void updateSpeed(int orbits) =>
      speedRadiusLimit = float32(speedRadiusBasis / orbits);
  void shrink() => animation = true;
}

class Orbit {
  double radius;
  double rotation = 0;
  final int direction;

  Orbit(this.radius, this.direction);
}

enum PhotonTrajectory { straight, sinus, spiral }

class PhotonLogicComponent extends LogicComponent {
  final int screenWidth;
  final int screenHeight;
  final PhotonTrajectory trajectory;
  final int direction;
  late final double radialVelocity;
  double polarRadius;
  double polarAngle;
  double radius = 0;
  bool growing = true;
  double angularVelocity = 1;

  PhotonLogicComponent({
    required num screenWidth,
    required num screenHeight,
    required this.trajectory,
    required double angle,
    this.direction = 1,
  })  : screenWidth = screenWidth.toInt(),
        screenHeight = screenHeight.toInt(),
        polarAngle = float32(angle),
        polarRadius = float32(screenWidth.toInt() * float32(0.125)) {
    final factor = switch (trajectory) {
      PhotonTrajectory.straight => float32(0.008333334),
      PhotonTrajectory.sinus => float32(0.0055555557),
      PhotonTrajectory.spiral => float32(0.006666667),
    };
    radialVelocity = float32(this.screenWidth * factor);
  }

  void positionPhoton(Entity entity) {
    final radians = polarAngle * 0.017453292519943295;
    entity.position.setPosition(Vector2D(
      (screenWidth ~/ 2 + polarRadius * sin(radians)).toInt().toDouble(),
      (screenHeight ~/ 2 + polarRadius * cos(radians)).toInt().toDouble(),
    ));
  }

  @override
  void update(Entity entity, double deltaTime) {
    if (growing) return;
    polarRadius = float32(polarRadius + radialVelocity);
    if (polarRadius > screenHeight) {
      entity.markForDeletion();
      return;
    }
    switch (trajectory) {
      case PhotonTrajectory.sinus:
        polarAngle = float32(
          polarAngle + 1.5 * sin(float32(polarRadius / 50)),
        );
      case PhotonTrajectory.spiral:
        polarAngle = float32(polarAngle + float32(direction * angularVelocity));
        if (polarAngle >= 360) polarAngle = float32(polarAngle - 360);
        if (polarAngle < 0) polarAngle = float32(polarAngle + 360);
      case PhotonTrajectory.straight:
        break;
    }
    positionPhoton(entity);
  }
}

class EnergyLogicComponent extends LogicComponent {
  int onOrbit;
  double angle;
  double rotation = 0;

  EnergyLogicComponent({required this.onOrbit, required this.angle});

  @override
  void update(Entity entity, double deltaTime) {
    rotation = float32(rotation + 2);
    if (rotation > 90) rotation = float32(rotation - 90);
  }
}
