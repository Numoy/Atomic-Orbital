import 'package:atomic_orbital/constants/game_constants.dart';
import 'package:flutter/material.dart';

abstract final class ArcadePalette {
  static const ink = GameConstants.backgroundColor;
  static const panel = Color(0xFF101A26);
  static const paper = GameConstants.atomColor;
  static const ice = GameConstants.normalAccent;
  static const gold = Color(0xFFD9BD7C);
  static const edge = Color(0xFF344353);
  static const quiet = GameConstants.quietColor;
}

class SpaceStars extends CustomPainter {
  const SpaceStars();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = ArcadePalette.ink);
    for (var i = 0; i < 45; i++) {
      final x = ((i * 127 + 37) % 997) / 997 * size.width;
      final y = ((i * 233 + 71) % 991) / 991 * size.height;
      final bright = i % 7 == 0;
      final paint = Paint()
        ..color = ArcadePalette.paper.withValues(alpha: bright ? .24 : .08);
      canvas.drawCircle(Offset(x, y), bright ? .95 : .55, paint);
    }
  }

  @override
  bool shouldRepaint(SpaceStars oldDelegate) => false;
}

class StarMark extends StatelessWidget {
  const StarMark({super.key, this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: Icon(Icons.star_rounded, size: size, color: ArcadePalette.gold));
}
