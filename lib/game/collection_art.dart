part of 'game_skin.dart';

void _drawCollection(Canvas canvas, GameSkin skin, Offset center, double radius,
    double progress) {
  if (skin == GameSkin.classic ||
      !radius.isFinite ||
      radius <= 0 ||
      !progress.isFinite ||
      progress <= 0 ||
      progress >= 1 ||
      !center.dx.isFinite ||
      !center.dy.isFinite) {
    return;
  }
  final colors = switch (skin) {
    GameSkin.cowAbduction => (const Color(0xFFA8F4CD), const Color(0xFFE5FFE7)),
    GameSkin.deepBlue => (const Color(0xFFFFD16B), const Color(0xFFFFEDAD)),
    GameSkin.spiderWeb => (const Color(0xFFFFF4DE), const Color(0xFFE8DDF9)),
    GameSkin.dragonHoard => (const Color(0xFFFFCA72), const Color(0xFFFFF0BD)),
    GameSkin.sunflower => (const Color(0xFFFFDD68), const Color(0xFFFFF1A6)),
    GameSkin.frostBite => (const Color(0xFFF0FDFF), const Color(0xFFBDE7F5)),
    GameSkin.hauntedHarvest => (
        const Color(0xFFFFD9A2),
        const Color(0xFFE2C2F2)
      ),
    GameSkin.junkyardDash => (const Color(0xFFB9F5CF), const Color(0xFFFFF1B0)),
    GameSkin.volcanoHop => (const Color(0xFFFFE6C7), const Color(0xFFFFCFA9)),
    GameSkin.cheeseChase => (const Color(0xFFFFD478), const Color(0xFFFFEBA6)),
    GameSkin.jungleJam => (const Color(0xFFB7E187), const Color(0xFFFFE790)),
    GameSkin.classic => (Colors.transparent, Colors.transparent),
  };
  final fade = math.min(1.0, progress / .12) * (1 - progress);
  final travel = .24 + 1.12 * (1 - math.pow(1 - progress, 3));
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(radius);
  for (var i = 0; i < 7; i++) {
    final angle = -math.pi / 2 + i * math.pi * 2 / 7;
    final spread = travel * (.82 + (i % 3) * .08);
    final beam = skin == GameSkin.cowAbduction;
    final x = math.cos(angle) * spread * (beam ? .66 : 1);
    final y = math.sin(angle) * spread * (beam ? .34 : 1) -
        progress * progress * (beam ? .65 : .22);
    final size = (.14 + (i % 3) * .02) * (1 - progress * .25);
    final color = (i.isEven ? colors.$1 : colors.$2).withValues(alpha: fade);
    final paint = _fill(color);
    final line = _line(color, .25);
    final light = _line(Colors.white.withValues(alpha: fade * .8), .22);
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(beam ? 0 : i * .73 + progress * (i.isEven ? .7 : -.7));
    canvas.scale(size);
    switch (skin) {
      case GameSkin.cowAbduction:
        _collectionGlint(canvas, paint);
        canvas.drawLine(const Offset(0, 1.2), const Offset(0, 2),
            _line(color.withValues(alpha: fade * .45), .2));
      case GameSkin.deepBlue:
        if (i.isEven) {
          canvas.drawOval(const Rect.fromLTRB(-.68, -1, .68, 1), paint);
          canvas.drawLine(
              const Offset(-.14, -.48), const Offset(-.14, .38), light);
        } else {
          _collectionGlint(canvas, paint);
        }
      case GameSkin.spiderWeb:
        if (i.isEven) {
          canvas.drawRRect(
              RRect.fromRectAndRadius(const Rect.fromLTRB(-.7, -.7, .7, .7),
                  const Radius.circular(.16)),
              paint);
          canvas.drawLine(
              const Offset(-.42, -.42), const Offset(.32, -.42), light);
        } else {
          _collectionGlint(canvas, paint);
        }
      case GameSkin.dragonHoard:
        canvas.drawPath(
            Path()
              ..moveTo(0, -1)
              ..lineTo(.78, -.28)
              ..lineTo(0, 1)
              ..lineTo(-.78, -.28)
              ..close(),
            paint);
        canvas.drawLine(
            const Offset(-.52, -.28), const Offset(.52, -.28), light);
      case GameSkin.sunflower:
        canvas.drawCircle(Offset.zero, .7, paint);
        canvas.drawCircle(const Offset(.72, -.62), .24, paint);
        canvas.drawCircle(const Offset(-.67, -.52), .19, paint);
      case GameSkin.frostBite:
        for (var axis = 0; axis < 3; axis++) {
          final direction = Offset(
              math.cos(axis * math.pi / 3), math.sin(axis * math.pi / 3));
          canvas.drawLine(-direction, direction, line);
        }
        canvas.drawCircle(Offset.zero, .22, paint);
      case GameSkin.hauntedHarvest:
        canvas.drawCircle(Offset.zero, .6, paint);
        for (final side in [-1.0, 1.0]) {
          canvas.drawPath(
              Path()
                ..moveTo(side * .5, 0)
                ..lineTo(side * 1.1, -.5)
                ..lineTo(side * 1.1, .5)
                ..close(),
              paint);
        }
        canvas.drawLine(
            const Offset(-.17, -.25), const Offset(.17, .25), light);
      case GameSkin.junkyardDash:
        canvas.drawLine(const Offset(0, -.95), const Offset(0, .85), line);
        canvas.drawLine(const Offset(-.52, -.1), const Offset(.52, -.1), light);
        canvas.drawCircle(const Offset(0, -1.25), .16, paint);
      case GameSkin.volcanoHop:
        canvas.drawPath(
            Path()
              ..moveTo(-.8, -.35)
              ..quadraticBezierTo(-.1, -1.1, .75, -.48)
              ..lineTo(.45, .64)
              ..lineTo(-.12, .35)
              ..lineTo(-.58, .73)
              ..close(),
            paint);
        canvas.drawLine(
            const Offset(-.38, -.37), const Offset(.2, -.52), light);
      case GameSkin.cheeseChase:
        canvas.drawPath(
            Path()
              ..moveTo(-.8, .57)
              ..lineTo(-.46, -.7)
              ..lineTo(.84, .17)
              ..lineTo(.35, .74)
              ..close(),
            paint);
        canvas.drawCircle(const Offset(-.12, .12), .19,
            _fill(const Color(0xFFD89544).withValues(alpha: fade)));
      case GameSkin.jungleJam:
        if (i.isEven) {
          canvas.drawPath(
              Path()
                ..moveTo(-.8, .6)
                ..quadraticBezierTo(-1, -.9, .85, -.7)
                ..quadraticBezierTo(1, .8, -.8, .6)
                ..close(),
              paint);
          canvas.drawLine(
              const Offset(-.48, .35), const Offset(.47, -.37), light);
        } else {
          canvas.drawPath(
              Path()
                ..moveTo(-.8, -.65)
                ..quadraticBezierTo(-.2, .5, .85, -.2)
                ..quadraticBezierTo(.3, 1.1, -.55, .55)
                ..quadraticBezierTo(-.94, .14, -.8, -.65)
                ..close(),
              paint);
        }
      case GameSkin.classic:
        break;
    }
    canvas.restore();
  }
  canvas.restore();
}

void _collectionGlint(Canvas canvas, Paint paint) {
  canvas.drawPath(
      Path()
        ..moveTo(0, -1)
        ..lineTo(.25, -.25)
        ..lineTo(1, 0)
        ..lineTo(.25, .25)
        ..lineTo(0, 1)
        ..lineTo(-.25, .25)
        ..lineTo(-1, 0)
        ..lineTo(-.25, -.25)
        ..close(),
      paint);
}
