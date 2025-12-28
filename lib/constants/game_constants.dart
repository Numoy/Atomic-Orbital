import 'dart:ui';

class GameConstants {
  static const bool debug = false;

  // Size factors (matching original)
  static const double atomSizeFactor =
      1 / 4; // Java: Atom=50 / World=200 = 1/4 (0.25)
  static const double photonSpawnScaleFactor = 1 / 40;

  // Java World Width = 200 units.
  static double get scaleFactor => screenWidth / 200.0;

  // Screen dimensions (will be set dynamically)
  static double screenWidth = 1080.0; // Default, will be updated
  static double screenHeight = 1920.0; // Default, will be updated

  // Game object sizes (calculated from factors like original)
  static double get atomSize => screenWidth * atomSizeFactor;
  // Java: Atom=50, Photon=5 -> Photon is 1/10 of Atom
  static double get photonSize => atomSize / 10.0;
  // Java: Atom=50, Player=10 -> Player is 1/5 of Atom.
  // Restored to original 1/5 ratio for Bitmaps
  static double get playerSize => atomSize / 5.0;

  // Game mechanics
  static const double photonPhiVelocity = 1.0;
  static const double photonWaveInterval = 2.5; // Time between waves (Seconds)
  static const double photonAppearTime =
      0.5; // Time to animate/scale up (Seconds)
  static const int redFlashOnHit = 130;

  // Colors - Updated to match typical neon vector aesthetic better
  static const Color backgroundColor = Color(0xFF000000);
  static const Color atomColor = Color(0xFF00BCD4); // Cyan Atom
  static const Color playerColor = Color(0xFF2196F3); // Blue Player
  static const Color photonColor =
      Color(0xFFFF5252); // Red/Orange Photon (Enemy)
  static const Color energyColor = Color(0xFF76FF03); // Green Energy (Collect)

  // Physics
  static const double gravity = 9.8;
  static const double friction = 0.98;

  // UI
  static const double menuButtonSize = 60.0;
  static const double scoreTextSize = 24.0;
  static const double titleTextSize = 32.0;
}
