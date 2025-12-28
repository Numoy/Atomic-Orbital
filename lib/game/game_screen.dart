import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:atomic_orbital/game/game_engine.dart';
import 'package:atomic_orbital/constants/game_constants.dart';
import 'package:atomic_orbital/services/audio_service.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:atomic_orbital/services/asset_manager.dart';
import 'package:atomic_orbital/models/entity.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameEngine _gameEngine;
  late AnimationController _gameAnimationController;
  GameState _gameState = GameState.menu;
  int _score = 0;
  int _lives = 3;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();

    // Set screen dimensions for dynamic sizing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      GameConstants.screenWidth = size.width;
      GameConstants.screenHeight = size.height;
    });

    _gameEngine = GameEngine();
    _gameEngine = GameEngine();
    _gameEngine.initialize().then((_) {
      if (mounted) setState(() {});
    });

    // Set up callbacks
    _gameEngine.onStateChanged = (state) {
      setState(() {
        _gameState = state;
      });
    };

    _gameEngine.onScoreChanged = (score) {
      setState(() {
        _score = score;
      });
    };

    _gameEngine.onLivesChanged = (lives) {
      setState(() {
        _lives = lives;
      });
    };

    _gameAnimationController = AnimationController(
      duration: const Duration(milliseconds: 16), // ~60 FPS
      vsync: this,
    );
    _gameAnimationController.addListener(() {
      if (_gameState == GameState.playing) {
        _gameEngine.update();
      }
    });
    _gameAnimationController.repeat();

    _isMuted = SettingsService.instance.isMuted;
  }

  @override
  void dispose() {
    _gameAnimationController.dispose();
    super.dispose();
  }

  void _handleTap(TapDownDetails details) {
    if (_gameState == GameState.menu) {
      _gameEngine.startGame();
    } else if (_gameState == GameState.playing) {
      _gameEngine.onTouchDown();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_gameState == GameState.playing) {
      _gameEngine.onTouchUp();
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_gameState == GameState.playing) {
      _gameEngine.onTouchMove(details.delta.dx);
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      SettingsService.instance.setMuted(_isMuted);
      AudioService.instance.setMuted(_isMuted);
    });
  }

  void _spawnEnergy() {
    _gameEngine.spawnEnergy();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _gameState == GameState.menu ? _buildMenu() : _buildGame(),
    );
  }

  Widget _buildMenu() {
    return GestureDetector(
      onTapDown: _handleTap,
      child: Container(
        color: Colors.black,
        child: Column(
          children: [
            // Top section with NORMAL/HARDCORE buttons (12.5% of height)
            Expanded(
              flex: 125,
              child: Container(
                margin: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    // NORMAL button
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 2.5),
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Implement normal mode
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF023043), // darkerBlue
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'NORMAL',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // HARDCORE button
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 2.5),
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Implement hardcore mode
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD50000), // red
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'HARDCORE',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Score section (10% of height)
            Expanded(
              flex: 100,
              child: Container(
                margin: const EdgeInsets.only(bottom: 50),
                child: Row(
                  children: [
                    // Normal score icon
                    Container(
                      width: 25,
                      height: 25,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 15,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    // Normal score
                    Container(
                      width: 25,
                      height: 25,
                      alignment: Alignment.center,
                      child: const Text(
                        '0',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    // Spacer
                    const Expanded(child: SizedBox()),
                    // Hardcore score
                    Container(
                      width: 25,
                      height: 25,
                      alignment: Alignment.center,
                      child: const Text(
                        '0',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    // Hardcore score icon
                    Container(
                      width: 25,
                      height: 25,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Video/Game preview area (58% of height)
            Expanded(
              flex: 580,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.grey[800]!, width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Atom visualization
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.circle,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'ATOMIC ORBITAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tap to start',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom section with START button and action buttons (30% of height)
            Expanded(
              flex: 300,
              child: Container(
                margin: const EdgeInsets.only(top: 30),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // START button background (blue triangle)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: CustomPaint(
                        painter: StartButtonPainter(),
                      ),
                    ),
                    // START text
                    Positioned(
                      top: 20,
                      child: const Text(
                        'START',
                        style: TextStyle(
                          color: Color(0xFFcaf0fd), // lightBlue
                          fontSize: 70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Action buttons at bottom
                    Positioned(
                      bottom: 10,
                      child: Row(
                        children: [
                          // Achievement button
                          Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: const Icon(
                              Icons.emoji_events,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 30),
                          // Leaderboard button
                          Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: const Icon(
                              Icons.leaderboard,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 30),
                          // Login button
                          Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGame() {
    return GestureDetector(
      onTapDown: _handleTap,
      onTapUp: _handleTapUp,
      onPanUpdate: _handlePanUpdate,
      child: Stack(
        children: [
          // Game canvas
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _gameAnimationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: GamePainter(_gameEngine),
                  size: Size.infinite,
                );
              },
            ),
          ),
          // Game overlay
          if (_gameState == GameState.playing) ...[
            // Score
            Positioned(
              top: 50,
              left: 20,
              child: Text(
                'Score: $_score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Lives
            Positioned(
              top: 50,
              right: 20,
              child: Row(
                children: List.generate(
                  3,
                  (index) => Container(
                    margin: const EdgeInsets.only(left: 5),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: index < _lives ? Colors.red : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            // Mute button
            Positioned(
              top: 100,
              right: 20,
              child: GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
          // Game over overlay
          if (_gameState == GameState.gameOver) ...[
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'GAME OVER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Final Score: $_score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        _gameEngine.resetGame();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF023043),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                      ),
                      child: const Text(
                        'RESTART',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Custom painter for the START button background (blue triangle)
class StartButtonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF023043) // darkerBlue
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.22); // 68/302 ≈ 0.22
    path.quadraticBezierTo(
      size.width * 0.32, // 258.4/803 ≈ 0.32
      size.height * -0.29, // -89.1/302 ≈ -0.29
      size.width,
      size.height * 0.22,
    );
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for the game rendering
class GamePainter extends CustomPainter {
  final GameEngine gameEngine;

  GamePainter(this.gameEngine);

  @override
  @override
  void paint(Canvas canvas, Size size) {
    if (!AssetManager.instance.isLoaded) return;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw background (Stars)
    final bgPaint = Paint();
    if (AssetManager.instance.backgroundImage != null) {
      final bgImage = AssetManager.instance.backgroundImage!;
      // Scale to cover screen
      final srcRect = Rect.fromLTWH(
          0, 0, bgImage.width.toDouble(), bgImage.height.toDouble());
      final dstRect = Offset.zero & size;
      canvas.drawImageRect(bgImage, srcRect, dstRect, bgPaint);
    } else {
      // Fallback
      bgPaint
        ..color = GameConstants.backgroundColor
        ..style = PaintingStyle.fill;
      canvas.drawRect(Offset.zero & size, bgPaint);
    }

    // Draw orbital rings
    _drawOrbitalRings(canvas, center);

    // Draw all entities
    for (final entity in gameEngine.entities) {
      if (!entity.graphic.isVisible) continue;

      final pos = entity.position.position;
      // Convert vector to screen coordinates relative to center
      final drawPos = center + Offset(pos.x, pos.y);

      final width = entity.size.width;
      final height = entity.size.height;
      // Define destination rectangle
      final dstRect =
          Rect.fromCenter(center: drawPos, width: width, height: height);

      final paint = Paint()..filterQuality = FilterQuality.medium;

      // Determine Image and Tint
      ui.Image? image;
      Color tint;

      if (entity.type == EntityType.photon) {
        image = AssetManager.instance.photonImage;
        tint = GameConstants.photonColor;
      } else {
        // Atom, Player, Energy use std_atom.png
        image = AssetManager.instance.atomImage;
        if (entity.type == EntityType.atom)
          tint = GameConstants.atomColor;
        else if (entity.type == EntityType.player)
          tint = GameConstants.playerColor;
        else
          tint = GameConstants.energyColor; // Energy
      }

      if (image != null) {
        paint.colorFilter = ColorFilter.mode(tint, BlendMode.modulate);
        canvas.drawImageRect(
            image,
            Rect.fromLTWH(
                0, 0, image.width.toDouble(), image.height.toDouble()),
            dstRect,
            paint);
      }
    }
  }

  void _drawOrbitalRings(Canvas canvas, Offset center) {
    final ringPaint = Paint()
      ..color = const Color(0xFF222222) // Subtle dark gray
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final radii = [
      GameConstants.screenWidth * 0.1, // Inner bound (Player Min)
      GameConstants.screenWidth * 0.4, // Outer bound (Player Max)
    ];

    for (final radius in radii) {
      canvas.drawCircle(center, radius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Always repaint when animation controller triggers
    return true;
  }
}
