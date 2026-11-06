part of 'game_skin.dart';

Offset _orbitPoint(double radius, double angle) =>
    Offset(math.cos(angle), math.sin(angle)) * radius;

void _drawWorldOrbit(Canvas canvas, GameSkin skin, Offset center, double radius,
    {double rotation = 0,
    double time = 0,
    double strokeWidth = 1,
    bool active = false}) {
  if (radius <= 0 || skin == GameSkin.classic) return;
  var width = math.min(math.max(.25, strokeWidth), radius / 12);
  final phase = (time % 8) * math.pi / 4;
  final color = skin.accent;
  final strength = active ? 1.0 : .7;
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(rotation);
  canvas.drawCircle(
      Offset.zero,
      radius,
      _line(
          (active ? Color.lerp(color, Colors.white, .2)! : color)
              .withValues(alpha: active ? .82 : .04),
          width * (active ? 1.1 : .5)));
  if (active) width *= .6;
  canvas.clipPath(Path()
    ..fillType = PathFillType.evenOdd
    ..addOval(Rect.fromCircle(center: Offset.zero, radius: radius + width * 4))
    ..addOval(
        Rect.fromCircle(center: Offset.zero, radius: radius - width * 4)));
  final line = _line(color.withValues(alpha: .6 * strength), width * .9);
  final quiet = _line(color.withValues(alpha: .38 * strength), width * .7);
  for (var i = 0; i < 12; i++) {
    if (active && i.isOdd) continue;
    final angle = i * math.pi / 6;
    final next = angle + math.pi / 6;
    final point = _orbitPoint(radius, angle);
    switch (skin) {
      case GameSkin.cowAbduction:
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: radius),
            angle + .08, .3, false, quiet);
        canvas.save();
        canvas.translate(point.dx, point.dy);
        canvas.rotate(angle + .4);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset.zero, width: width * 3, height: width * 1.4),
            _fill(color.withValues(alpha: .5 * strength)));
        canvas.restore();
        canvas.drawCircle(_orbitPoint(radius + width * 2, angle + .18),
            width * .55, _fill(color.withValues(alpha: .38 * strength)));
      case GameSkin.deepBlue:
        final start = _orbitPoint(radius - width, angle + .04);
        final end = _orbitPoint(radius + width, next - .04);
        final current = _orbitPoint(
            radius / math.cos((math.pi / 6 - .08) / 2), angle + math.pi / 12);
        canvas.drawPath(
            Path()
              ..moveTo(start.dx, start.dy)
              ..quadraticBezierTo(current.dx, current.dy, end.dx, end.dy),
            line);
        canvas.drawCircle(
            _orbitPoint(radius + math.sin(phase + i) * width, angle),
            width * 1.3,
            quiet);
      case GameSkin.spiderWeb:
        for (final inset in [-width, width]) {
          final start = _orbitPoint(radius - inset, angle);
          final end = _orbitPoint(radius - inset, next);
          final middle = _orbitPoint(
              (radius - inset) / math.cos(math.pi / 12) - width * 4,
              angle + math.pi / 12);
          canvas.drawPath(
              Path()
                ..moveTo(start.dx, start.dy)
                ..quadraticBezierTo(middle.dx, middle.dy, end.dx, end.dy),
              line);
        }
        canvas.drawLine(_orbitPoint(radius - width * 3.5, angle),
            _orbitPoint(radius + width * 2, angle), line);
      case GameSkin.dragonHoard:
        canvas.drawArc(
            Rect.fromCircle(center: Offset.zero, radius: radius),
            angle + .06,
            .4,
            false,
            _line(const Color(0xFFA89E86).withValues(alpha: .4 * strength),
                width * 2.8));
        canvas.save();
        canvas.translate(point.dx, point.dy);
        canvas.rotate(angle);
        canvas.drawPath(
            Path()
              ..moveTo(-width * 1.5, 0)
              ..lineTo(width, -width)
              ..lineTo(width, width)
              ..close(),
            line);
        canvas.restore();
      case GameSkin.sunflower:
        canvas.drawArc(
            Rect.fromCircle(center: Offset.zero, radius: radius),
            angle,
            .5,
            false,
            _line(const Color(0xFF8BAF74).withValues(alpha: .48 * strength),
                width));
        canvas.save();
        canvas.translate(point.dx, point.dy);
        canvas.rotate(angle);
        if (i.isEven) {
          for (var petal = 0; petal < 5; petal++) {
            canvas.drawCircle(
                _orbitPoint(width * 1.35, petal * math.pi * 2 / 5),
                width * .8,
                _fill(
                    const Color(0xFFF1D993).withValues(alpha: .7 * strength)));
          }
          canvas.drawCircle(Offset.zero, width * .65,
              _fill(const Color(0xFFC79D62).withValues(alpha: .85 * strength)));
        } else {
          for (final pollen in [
            const Offset(-1.1, -.4),
            const Offset(.9, -.8),
            const Offset(.2, 1.1)
          ]) {
            canvas.drawCircle(
                pollen * width,
                width * .6,
                _fill(
                    const Color(0xFFF7DE96).withValues(alpha: .7 * strength)));
          }
        }
        canvas.restore();
      case GameSkin.frostBite:
        final bend = _orbitPoint(radius + width, angle + .23);
        canvas.drawPath(
            Path()
              ..arcTo(Rect.fromCircle(center: Offset.zero, radius: radius),
                  angle + .04, .18, true)
              ..lineTo(bend.dx, bend.dy)
              ..arcTo(
                  Rect.fromCircle(center: Offset.zero, radius: radius + width),
                  angle + .23,
                  math.pi / 6 - .26,
                  false),
            line);
        canvas.drawLine(_orbitPoint(radius - width * 1.7, angle),
            _orbitPoint(radius + width * 1.7, angle + .008), quiet);
      case GameSkin.hauntedHarvest:
        final mist = Path();
        final sweep = .3 + .08 * math.sin(i * 1.7);
        final start = angle + .02 + i % 3 * .035;
        for (final side in [-1.0, 1.0]) {
          for (var step = 0; step <= 10; step++) {
            final t = side < 0 ? step / 10 : 1 - step / 10;
            final drift = math.sin(phase + i + t * math.pi) * width * .7;
            final thickness = width * (.12 + math.sin(t * math.pi) * 1.25);
            final at = _orbitPoint(
                radius + drift + side * thickness, start + t * sweep);
            if (side < 0 && step == 0) {
              mist.moveTo(at.dx, at.dy);
            } else {
              mist.lineTo(at.dx, at.dy);
            }
          }
        }
        mist.close();
        canvas.drawPath(mist,
            _fill(const Color(0xFFC4B8DD).withValues(alpha: .34 * strength)));
      case GameSkin.junkyardDash:
        final corner = _orbitPoint(radius + width * 1.4, next - .08);
        canvas.drawPath(
            Path()
              ..arcTo(Rect.fromCircle(center: Offset.zero, radius: radius),
                  angle + .08, math.pi / 6 - .18, true)
              ..lineTo(corner.dx, corner.dy)
              ..arcTo(
                  Rect.fromCircle(
                      center: Offset.zero, radius: radius + width * 1.4),
                  next - .08,
                  .08,
                  false),
            line);
        canvas.drawCircle(point, width * 1.3, line);
      case GameSkin.volcanoHop:
        canvas.drawArc(
            Rect.fromCircle(center: Offset.zero, radius: radius),
            angle + .03,
            .43,
            false,
            _line(const Color(0xFF84716D).withValues(alpha: .6 * strength),
                width * 3.2));
        canvas.drawPath(
            Path()
              ..moveTo(point.dx, point.dy)
              ..lineTo(_orbitPoint(radius - width * 2.2, angle + .006).dx,
                  _orbitPoint(radius - width * 2.2, angle + .006).dy)
              ..lineTo(_orbitPoint(radius + width * 2.2, angle - .006).dx,
                  _orbitPoint(radius + width * 2.2, angle - .006).dy),
            _line(const Color(0xFFFFB17C).withValues(alpha: .7 * strength),
                width * .9));
      case GameSkin.cheeseChase:
        for (final side in [-1.0, 1.0]) {
          final start = _orbitPoint(radius, angle);
          final middle = _orbitPoint(radius, angle + math.pi / 12);
          final first = _orbitPoint(
              radius / math.cos(math.pi / 24) + side * width * 3,
              angle + math.pi / 24);
          final second = _orbitPoint(
              radius / math.cos(math.pi / 24) - side * width * 3,
              angle + math.pi / 8);
          final end = _orbitPoint(radius, next);
          canvas.drawPath(
              Path()
                ..moveTo(start.dx, start.dy)
                ..quadraticBezierTo(first.dx, first.dy, middle.dx, middle.dy)
                ..quadraticBezierTo(second.dx, second.dy, end.dx, end.dy),
              _line(
                  (side < 0 ? const Color(0xFF88C5BB) : const Color(0xFFC4DBB7))
                      .withValues(alpha: .65 * strength),
                  width * 1.1));
        }
      case GameSkin.jungleJam:
        canvas.drawArc(
            Rect.fromCircle(center: Offset.zero, radius: radius),
            angle,
            .51,
            false,
            _line(const Color(0xFF96BE80).withValues(alpha: .5 * strength),
                width));
        canvas.save();
        canvas.translate(point.dx, point.dy);
        canvas.rotate(angle + (i.isEven ? .7 : .45));
        canvas.drawPath(
            Path()
              ..moveTo(-width * 1.9, 0)
              ..quadraticBezierTo(width, -width * 3.8, width * 3.5, 0)
              ..quadraticBezierTo(width, width * 3.8, -width * 1.9, 0)
              ..close(),
            _fill(const Color(0xFF8BAA71).withValues(alpha: .6 * strength)));
        canvas.drawLine(
            Offset(-width * 1.3, 0),
            Offset(width * 2.9, 0),
            _line(const Color(0xFFD3DFAC).withValues(alpha: .5 * strength),
                width * .4));
        canvas.restore();
      case GameSkin.classic:
        break;
    }
  }
  canvas.restore();
}

void _drawCoreSetting(Canvas canvas, GameSkin skin, double time) {
  if (skin == GameSkin.classic || skin == GameSkin.cowAbduction) return;
  final (light, dark) = switch (skin) {
    GameSkin.deepBlue => (const Color(0xFF143741), const Color(0xFF0B202C)),
    GameSkin.spiderWeb => (const Color(0xFF292337), const Color(0xFF161A27)),
    GameSkin.dragonHoard => (const Color(0xFF36362E), const Color(0xFF23252A)),
    GameSkin.sunflower => (const Color(0xFF2A4030), const Color(0xFF172A24)),
    GameSkin.frostBite => (const Color(0xFF284454), const Color(0xFF142B3B)),
    GameSkin.hauntedHarvest => (
        const Color(0xFF332A40),
        const Color(0xFF1A1E2C)
      ),
    GameSkin.junkyardDash => (const Color(0xFF294040), const Color(0xFF162B32)),
    GameSkin.volcanoHop => (const Color(0xFF422D2C), const Color(0xFF2B232B)),
    GameSkin.cheeseChase => (const Color(0xFF353A35), const Color(0xFF232B2D)),
    GameSkin.jungleJam => (const Color(0xFF26442D), const Color(0xFF132B23)),
    _ => (GameConstants.backgroundColor, GameConstants.backgroundColor),
  };
  canvas.save();
  canvas.clipPath(Path()..addOval(_disc));
  canvas.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = RadialGradient(
            center: const Alignment(-.3, -.3),
            radius: 1.3,
            colors: [light, dark]).createShader(_disc));
  final phase = (time % 8) * math.pi / 4;
  final line = _line(skin.accent.withValues(alpha: .13), .018);
  switch (skin) {
    case GameSkin.deepBlue:
      for (var i = 0; i < 5; i++) {
        final radius = .43 + i * .115;
        canvas.drawArc(
            Rect.fromCircle(center: const Offset(.025, .025), radius: radius),
            i * 1.25 + math.sin(phase) * .045,
            math.pi * 1.3,
            false,
            line);
      }
    case GameSkin.spiderWeb:
      for (var i = 0; i < 12; i++) {
        final angle = i * math.pi / 6;
        canvas.drawLine(Offset.zero, _orbitPoint(.98, angle), line);
        for (final radius in [.42, .66, .89]) {
          final start = _orbitPoint(radius, angle);
          final middle = _orbitPoint(radius * .84, angle + math.pi / 12);
          final end = _orbitPoint(radius, angle + math.pi / 6);
          canvas.drawPath(
              Path()
                ..moveTo(start.dx, start.dy)
                ..quadraticBezierTo(middle.dx, middle.dy, end.dx, end.dy),
              line);
        }
      }
    case GameSkin.dragonHoard:
      canvas.drawCircle(Offset.zero, .88, line);
      for (var i = 0; i < 8; i++) {
        canvas.save();
        canvas.rotate(i * math.pi / 4);
        canvas.drawPath(
            Path()
              ..moveTo(-.045, -.95)
              ..lineTo(.035, -.88)
              ..lineTo(-.025, -.78)
              ..moveTo(.035, -.88)
              ..lineTo(.08, -.89),
            line);
        canvas.restore();
      }
    case GameSkin.sunflower:
    case GameSkin.jungleJam:
      final jungle = skin == GameSkin.jungleJam;
      for (var i = 0; i < 10; i++) {
        canvas.save();
        canvas.rotate(i * math.pi / 5 + math.sin(phase) * .015);
        final leaf = Path()
          ..moveTo(-.11, -.67)
          ..quadraticBezierTo(-.24, -.9, jungle ? .14 : .05, -.99)
          ..quadraticBezierTo(.2, -.79, -.11, -.67)
          ..close();
        canvas.drawPath(
            leaf,
            _fill((jungle ? const Color(0xFF719A63) : const Color(0xFF8EA860))
                .withValues(alpha: .19)));
        canvas.drawLine(
            const Offset(-.08, -.72), const Offset(.035, -.91), line);
        canvas.restore();
      }
    case GameSkin.frostBite:
      for (var i = 0; i < 7; i++) {
        canvas.save();
        canvas.rotate(i * math.pi * 2 / 7);
        canvas.drawPath(
            Path()
              ..moveTo(0, -.98)
              ..lineTo(-.035, -.83)
              ..lineTo(.05, -.7)
              ..lineTo(.015, -.58)
              ..moveTo(-.035, -.83)
              ..lineTo(-.15, -.75),
            line);
        canvas.restore();
      }
    case GameSkin.hauntedHarvest:
      for (var i = 0; i < 4; i++) {
        final y = -.65 + i * .43;
        canvas.drawPath(
            Path()
              ..moveTo(-1, y)
              ..cubicTo(-.45, y - .13, .18,
                  y + .13 + math.sin(phase + i) * .025, 1, y - .06),
            _line(const Color(0xFFC2B2D6).withValues(alpha: .09), .08));
      }
    case GameSkin.junkyardDash:
      canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTRB(-.84, -.75, .84, .75),
              const Radius.circular(.12)),
          line);
      for (final x in [-.72, .72]) {
        for (final y in [-.62, .62]) {
          canvas.drawCircle(Offset(x, y), .04, line);
          canvas.drawLine(Offset(x - .02, y), Offset(x + .02, y), line);
        }
        canvas.drawPath(
            Path()
              ..moveTo(x, -.42)
              ..lineTo(x, -.15)
              ..lineTo(x * .87, -.06)
              ..lineTo(x * .87, .4),
            line);
      }
    case GameSkin.volcanoHop:
      canvas.drawCircle(Offset.zero, .89,
          _line(const Color(0xFFAB7E63).withValues(alpha: .13), .08));
      for (var i = 0; i < 8; i++) {
        canvas.save();
        canvas.rotate(i * math.pi / 4);
        canvas.drawPath(
            Path()
              ..moveTo(-.05, -.99)
              ..lineTo(.04, -.84)
              ..lineTo(-.02, -.73)
              ..lineTo(.09, -.62),
            _line(const Color(0xFFF6A26D).withValues(alpha: .18), .018));
        canvas.restore();
      }
    case GameSkin.cheeseChase:
      for (var i = 0; i < 6; i++) {
        canvas.save();
        canvas.rotate(i * math.pi / 6);
        canvas.drawOval(const Rect.fromLTRB(-.48, -.94, .48, .94), line);
        canvas.restore();
      }
    case GameSkin.classic:
    case GameSkin.cowAbduction:
      break;
  }
  canvas.restore();
}
