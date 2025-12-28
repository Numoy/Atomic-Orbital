import 'dart:math';

class Vector2D {
  double x;
  double y;

  Vector2D(this.x, this.y);

  Vector2D.zero() : x = 0, y = 0;

  Vector2D.fromPolar(double radius, double angle) 
    : x = radius * cos(angle),
      y = radius * sin(angle);

  double get magnitude => sqrt(x * x + y * y);
  double get angle => atan2(y, x);

  Vector2D operator +(Vector2D other) => Vector2D(x + other.x, y + other.y);
  Vector2D operator -(Vector2D other) => Vector2D(x - other.x, y - other.y);
  Vector2D operator *(double scalar) => Vector2D(x * scalar, y * scalar);
  Vector2D operator /(double scalar) => Vector2D(x / scalar, y / scalar);

  void add(Vector2D other) {
    x += other.x;
    y += other.y;
  }

  void subtract(Vector2D other) {
    x -= other.x;
    y -= other.y;
  }

  void multiply(double scalar) {
    x *= scalar;
    y *= scalar;
  }

  void normalize() {
    double mag = magnitude;
    if (mag > 0) {
      x /= mag;
      y /= mag;
    }
  }

  double distanceTo(Vector2D other) {
    double dx = x - other.x;
    double dy = y - other.y;
    return sqrt(dx * dx + dy * dy);
  }

  Vector2D copy() => Vector2D(x, y);

  @override
  String toString() => 'Vector2D($x, $y)';
} 