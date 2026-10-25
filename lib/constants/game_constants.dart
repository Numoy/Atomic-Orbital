import 'dart:ui';

class GameConstants {
  static const bool debug = false;
  // Every device shows the same reference playfield, scaled uniformly by the UI.
  static const double referenceWidth = 1080;
  static const double referenceHeight = 1857;
  static const double referenceCanvasHeight = 1794;
  static const double referencePixelRatio = 2.625;
  static const double referenceLogicalWidth =
      referenceWidth / referencePixelRatio;
  static const double referenceLogicalCanvasHeight =
      referenceCanvasHeight / referencePixelRatio;
  static const double simulationFPS = 60;
  static const double frameTime = 1 / simulationFPS;
  static const int redFlashOnHit = 130;
  static const Color backgroundColor = Color(0xFF080D14);
  static const Color atomColor = Color(0xFFF3F5F3);
  static const Color playerColor = atomColor;
  static const Color photonColor = Color(0xFFFF4F64);
  static const Color energyColor = atomColor;
  static const Color normalAccent = Color(0xFF9BE9EF);
  static const Color hardcoreAccent = Color(0xFFFF8674);
  static const Color quietColor = Color(0xFF9AA6B5);
}
