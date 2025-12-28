import 'dart:ui';
import 'package:atomic_orbital/models/components.dart';

enum EntityType {
  player,
  atom,
  energy,
  photon,
  misc,
}

class Entity {
  final int id;
  final EntityType type;
  bool isDeleted = false;
  
  // Components
  PositionComponent position;
  SizeComponent size;
  VelocityComponent velocity;
  GraphicComponent graphic;
  LogicComponent logic;
  CollisionComponent collision;
  
  Entity({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    VelocityComponent? velocity,
    GraphicComponent? graphic,
    LogicComponent? logic,
    CollisionComponent? collision,
  }) : velocity = velocity ?? VelocityComponent(),
       graphic = graphic ?? GraphicComponent(),
       logic = logic ?? LogicComponent(),
       collision = collision ?? CollisionComponent();

  void update(double deltaTime) {
    if (isDeleted) return;
    
    // Update logic
    logic.update(this, deltaTime);
    
    // Update position based on velocity
    position.add(velocity.velocity * deltaTime);
    
    // Update collision
    collision.update(this, deltaTime);
  }

  void render(Canvas canvas, Offset center) {
    if (isDeleted) return;
    graphic.render(canvas, this, center);
  }

  bool collidesWith(Entity other) {
    if (isDeleted || other.isDeleted) return false;
    return collision.collidesWith(this, other);
  }

  void markForDeletion() {
    isDeleted = true;
  }

  @override
  String toString() => 'Entity(id: $id, type: $type, position: $position)';
} 