import 'dart:math' as math;

import 'package:atomic_orbital/constants/game_constants.dart';
import 'package:atomic_orbital/game/game_skin.dart';
import 'package:flutter/material.dart';

class WorldBackdrop extends CustomPainter {
  const WorldBackdrop({
    required this.skin,
    this.time = 0,
    this.motion,
  }) : super(repaint: motion);

  final GameSkin skin;
  final double time;
  final Animation<double>? motion;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = Offset.zero & size;
    if (skin == GameSkin.classic) {
      canvas.drawRect(bounds, _fill(GameConstants.backgroundColor));
      return;
    }
    final (top, bottom) = switch (skin) {
      GameSkin.cowAbduction => (
          const Color(0xFF10192D),
          const Color(0xFF07121B)
        ),
      GameSkin.deepBlue => (const Color(0xFF0B2935), const Color(0xFF06131F)),
      GameSkin.spiderWeb => (const Color(0xFF1B1429), const Color(0xFF0C111A)),
      GameSkin.dragonHoard => (
          const Color(0xFF191B20),
          const Color(0xFF231714)
        ),
      GameSkin.sunflower => (const Color(0xFF172521), const Color(0xFF101A16)),
      GameSkin.frostBite => (const Color(0xFF122333), const Color(0xFF0B1524)),
      GameSkin.hauntedHarvest => (
          const Color(0xFF20182C),
          const Color(0xFF11151E)
        ),
      GameSkin.junkyardDash => (
          const Color(0xFF152327),
          const Color(0xFF0B141C)
        ),
      GameSkin.volcanoHop => (const Color(0xFF1C161E), const Color(0xFF2A1718)),
      GameSkin.cheeseChase => (
          const Color(0xFF24201E),
          const Color(0xFF17151A)
        ),
      GameSkin.jungleJam => (const Color(0xFF10261F), const Color(0xFF091813)),
      GameSkin.classic => (
          GameConstants.backgroundColor,
          GameConstants.backgroundColor
        ),
    };
    canvas.save();
    canvas.clipRect(bounds);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(bounds),
    );
    final phase = ((time + (motion?.value ?? 0) * 8) % 8) * math.pi / 4;
    switch (skin) {
      case GameSkin.cowAbduction:
        _space(canvas, size, phase);
      case GameSkin.deepBlue:
        _sea(canvas, size, phase);
      case GameSkin.spiderWeb:
        _webs(canvas, size);
      case GameSkin.dragonHoard:
        _cavern(canvas, size, phase);
      case GameSkin.sunflower:
        _meadow(canvas, size, phase);
      case GameSkin.frostBite:
        _frost(canvas, size, phase);
      case GameSkin.hauntedHarvest:
        _haunted(canvas, size, phase);
      case GameSkin.junkyardDash:
        _circuits(canvas, size, phase);
      case GameSkin.volcanoHop:
        _volcano(canvas, size, phase);
      case GameSkin.cheeseChase:
        _pantry(canvas, size);
      case GameSkin.jungleJam:
        _jungle(canvas, size, phase);
      case GameSkin.classic:
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(WorldBackdrop oldDelegate) =>
      skin != oldDelegate.skin ||
      time != oldDelegate.time ||
      motion != oldDelegate.motion;
}

Paint _fill(Color color) => Paint()..color = color;

Paint _line(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

void _glow(Canvas canvas, Offset center, double radius, Color color) {
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: center, radius: radius)),
  );
}

void _space(Canvas canvas, Size size, double phase) {
  final u = size.shortestSide;
  final planet = Offset(-u * .13, size.height * .15);
  _glow(canvas, planet, u * .49, const Color(0x164896B9));
  canvas.drawCircle(planet, u * .32, _fill(const Color(0xFF152B3E)));
  canvas.drawCircle(planet, u * .328, _line(const Color(0x2854B0BE), u * .006));
  canvas.drawArc(Rect.fromCircle(center: planet, radius: u * .25), -.5, 1.5,
      false, _line(const Color(0x126CB5C2), u * .015));
  for (var i = 0; i < 20; i++) {
    final x = size.width * ((i * 37 % 97) / 97);
    var y = size.height * ((i * 23 % 89) / 89);
    if (x > size.width * .2 && x < size.width * .8) {
      y = i.isEven ? size.height * .08 : size.height * .94;
    }
    final center = Offset(x, y);
    final alpha = .13 + .025 * math.sin(phase + i);
    canvas.drawCircle(center, u * (i % 3 == 0 ? .0025 : .0014),
        _fill(const Color(0xFFBBD8DF).withValues(alpha: alpha)));
    if (i % 5 == 0) {
      canvas.drawLine(
          center - Offset(u * .006, 0),
          center + Offset(u * .006, 0),
          _line(const Color(0x226FC1CB), u * .001));
    }
  }
}

void _sea(Canvas canvas, Size size, double phase) {
  final w = size.width, h = size.height, u = size.shortestSide;
  for (var i = 0; i < 3; i++) {
    final x = w * (.1 + i * .39);
    final drift = math.sin(phase + i) * u * .008;
    canvas.drawPath(
      Path()
        ..moveTo(x, 0)
        ..lineTo(x + u * .035, 0)
        ..lineTo(x + drift + u * .17, h * .52)
        ..lineTo(x + drift - u * .08, h * .52)
        ..close(),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x0D8FD8D3), Color(0x008FD8D3)],
        ).createShader(Rect.fromLTWH(0, 0, w, h * .52)),
    );
  }
  canvas.drawPath(
      Path()
        ..moveTo(0, h * .91)
        ..cubicTo(w * .2, h * .95, w * .23, h * .94, w * .46, h * .97)
        ..cubicTo(w * .7, h * .96, w * .86, h * .91, w, h * .93)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      _fill(const Color(0xFF0B252A)));
  for (var i = 0; i < 8; i++) {
    final side = i.isEven ? .04 : .96;
    final x = w * side + math.sin(phase + i) * u * .005;
    final y = h * (.2 + (i % 4) * .18) + math.cos(phase + i) * u * .008;
    canvas.drawCircle(Offset(x, y), u * (.008 + i % 3 * .004),
        _line(const Color(0x245BBDC3), u * .0015));
  }
  for (final side in [0.0, 1.0]) {
    for (var i = 0; i < 4; i++) {
      final x = w * side + (side == 0 ? 1 : -1) * u * (.025 + i * .023);
      final tip = h - u * (.12 + i % 3 * .045);
      canvas.drawPath(
          Path()
            ..moveTo(x, h)
            ..cubicTo(x - u * .03, h - u * .08, x + u * .035, tip + u * .04,
                x + math.sin(phase + i) * u * .008, tip),
          _line(const Color(0xFF143D3D), u * .012));
    }
  }
}

void _webs(Canvas canvas, Size size) {
  final u = size.shortestSide;
  for (final corner in [
    Offset.zero,
    Offset(size.width, 0),
    Offset(0, size.height),
    Offset(size.width, size.height)
  ]) {
    canvas.save();
    canvas.translate(corner.dx, corner.dy);
    canvas.scale(corner.dx == 0 ? 1 : -1, corner.dy == 0 ? 1 : -1);
    final length = u * (corner.dy == 0 ? .29 : .21);
    final thread = _line(const Color(0x237D799B), u * .0015);
    for (var ray = 0; ray <= 5; ray++) {
      final angle = ray * math.pi / 10;
      canvas.drawLine(Offset.zero,
          Offset(math.cos(angle), math.sin(angle)) * length, thread);
    }
    for (var ring = 1; ring <= 4; ring++) {
      final r = length * ring / 4;
      final path = Path()..moveTo(r, 0);
      for (var ray = 1; ray <= 5; ray++) {
        final angle = ray * math.pi / 10;
        final middle = angle - math.pi / 20;
        path.quadraticBezierTo(
            math.cos(middle) * r * .83,
            math.sin(middle) * r * .83,
            math.cos(angle) * r,
            math.sin(angle) * r);
      }
      canvas.drawPath(path, thread);
    }
    canvas.restore();
  }
}

void _embers(Canvas canvas, Size size, double phase, Color color) {
  final u = size.shortestSide;
  for (var i = 0; i < 10; i++) {
    final x = size.width * (i.isEven ? .04 + i % 3 * .027 : .96 - i % 3 * .027);
    final y = size.height * (.28 + i % 5 * .14);
    final center = Offset(x + math.sin(phase + i) * u * .007,
        y + math.cos(phase + i * 2) * u * .012);
    canvas.drawOval(
        Rect.fromCenter(center: center, width: u * .004, height: u * .009),
        _fill(color.withValues(alpha: .16 + .03 * math.sin(phase + i))));
  }
}

void _cavern(Canvas canvas, Size size, double phase) {
  final w = size.width, h = size.height, u = size.shortestSide;
  _glow(canvas, Offset(w * .08, h), u * .65, const Color(0x226F3C1B));
  _glow(canvas, Offset(w * .96, h * .85), u * .4, const Color(0x165B3923));
  for (final right in [false, true]) {
    canvas.save();
    if (right) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }
    final rock = Path()
      ..moveTo(0, 0)
      ..lineTo(u * .16, 0)
      ..lineTo(u * .06, h * .22)
      ..lineTo(u * .11, h * .35)
      ..lineTo(u * .025, h * .61)
      ..lineTo(u * .09, h * .8)
      ..lineTo(u * .14, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(rock, _fill(const Color(0xFF292725)));
    canvas.drawPath(
        Path()
          ..moveTo(u * .14, 0)
          ..lineTo(u * .035, h * .23)
          ..lineTo(u * .09, h * .35),
        _line(const Color(0x204D4A44), u * .004));
    for (var i = 0; i < 3; i++) {
      final x = u * (.08 + i * .09);
      canvas.drawPath(
          Path()
            ..moveTo(x, 0)
            ..lineTo(x + u * .035, u * (.12 + i % 2 * .07))
            ..lineTo(x + u * .07, 0)
            ..close(),
          _fill(const Color(0xFF252523)));
    }
    canvas.restore();
  }
  _embers(canvas, size, phase, const Color(0xFFD9A65E));
}

void _meadow(Canvas canvas, Size size, double phase) {
  final w = size.width, h = size.height, u = size.shortestSide;
  _glow(canvas, Offset(w * .12, -u * .1), u * .7, const Color(0x286B7640));
  for (final right in [false, true]) {
    final edge = right ? w : 0.0;
    final direction = right ? -1.0 : 1.0;
    for (var i = 0; i < 5; i++) {
      final x = edge + direction * u * (.02 + i * .027);
      final tip = h - u * (.08 + i % 3 * .035);
      canvas.drawPath(
          Path()
            ..moveTo(x, h)
            ..quadraticBezierTo(x + direction * u * .03, tip + u * .025,
                x + direction * u * .015, tip),
          _line(const Color(0xFF284333), u * .006));
    }
    final center = Offset(edge + direction * u * .09, h - u * .13);
    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      canvas.drawOval(
          Rect.fromCenter(
              center:
                  center + Offset(math.cos(angle), math.sin(angle)) * u * .022,
              width: u * .026,
              height: u * .024),
          _fill(const Color(0x285B7341)));
    }
    canvas.drawCircle(center, u * .015, _fill(const Color(0x305F5334)));
  }
  for (var i = 0; i < 8; i++) {
    final x = w * (i.isEven ? .07 : .94) + math.sin(phase + i) * u * .012;
    final y = h * (.16 + i % 4 * .21) + math.cos(phase + i) * u * .007;
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(.4 + i);
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: u * .014, height: u * .006),
        _fill(const Color(0x387E8553)));
    canvas.restore();
  }
}

void _frost(Canvas canvas, Size size, double phase) {
  final w = size.width, h = size.height, u = size.shortestSide;
  for (var i = 0; i < 2; i++) {
    final y = h * (.1 + i * .07);
    final drift = math.sin(phase + i) * u * .009;
    canvas.drawPath(
        Path()
          ..moveTo(-u * .1, y)
          ..cubicTo(w * .24, y - u * .14 + drift, w * .55, y + u * .1,
              w + u * .1, y - u * .04)
          ..lineTo(w + u * .1, y + u * .035)
          ..cubicTo(w * .5, y + u * .16, w * .2, y - u * .06 + drift, -u * .1,
              y + u * .055)
          ..close(),
        _fill(i == 0 ? const Color(0x1866CEB7) : const Color(0x137E7BBE)));
  }
  canvas.drawPath(
      Path()
        ..moveTo(0, h)
        ..lineTo(0, h - u * .1)
        ..lineTo(w * .12, h - u * .15)
        ..lineTo(w * .29, h - u * .055)
        ..lineTo(w * .72, h - u * .03)
        ..lineTo(w * .92, h - u * .12)
        ..lineTo(w, h - u * .07)
        ..lineTo(w, h)
        ..close(),
      _fill(const Color(0xFF192D3C)));
  for (var i = 0; i < 12; i++) {
    final center = Offset(
        w * (i.isEven ? .045 + i % 3 * .025 : .96 - i % 3 * .025),
        h * (.08 + i % 6 * .16) + math.sin(phase + i) * u * .006);
    final stroke = _line(const Color(0x357FABB9), u * .0018);
    final r = u * (i % 3 == 0 ? .007 : .003);
    canvas.drawLine(center - Offset(r, 0), center + Offset(r, 0), stroke);
    canvas.drawLine(center - Offset(0, r), center + Offset(0, r), stroke);
  }
}

void _haunted(Canvas canvas, Size size, double phase) {
  final w = size.width, h = size.height, u = size.shortestSide;
  final moon = Offset(w - u * .12, u * .13);
  _glow(canvas, moon, u * .22, const Color(0x1D908C9F));
  canvas.drawCircle(moon, u * .06, _fill(const Color(0x386F727E)));
  canvas.drawCircle(moon + Offset(u * .026, -u * .01), u * .056,
      _fill(const Color(0xFF20192C)));
  for (var i = 0; i < 3; i++) {
    final shift = math.sin(phase + i) * u * .025;
    canvas.drawOval(
        Rect.fromCenter(
            center:
                Offset(w * (.2 + i * .33) + shift, h - u * (.04 + i % 2 * .07)),
            width: w * .9,
            height: u * .13),
        _fill(const Color(0x0F83879A)));
  }
  for (final right in [false, true]) {
    final x = right ? w - u * .035 : u * .035;
    final direction = right ? -1.0 : 1.0;
    final branches = Path()
      ..moveTo(x, h)
      ..lineTo(x + direction * u * .015, h - u * .31)
      ..lineTo(x - direction * u * .005, h - u * .4)
      ..moveTo(x + direction * u * .012, h - u * .24)
      ..lineTo(x + direction * u * .09, h - u * .32)
      ..lineTo(x + direction * u * .08, h - u * .38)
      ..moveTo(x + direction * u * .06, h - u * .29)
      ..lineTo(x + direction * u * .13, h - u * .3);
    canvas.drawPath(branches, _line(const Color(0xFF302B39), u * .008));
  }
}

void _circuits(Canvas canvas, Size size, double phase) {
  final w = size.width, h = size.height, u = size.shortestSide;
  for (final right in [false, true]) {
    final edge = right ? w : 0.0;
    final direction = right ? -1.0 : 1.0;
    for (var i = 0; i < 4; i++) {
      final y = h * (.12 + i * .23);
      final x = edge + direction * u * (.04 + i % 2 * .035);
      final end = Offset(x + direction * u * .055, y + u * .11);
      canvas.drawPath(
          Path()
            ..moveTo(edge, y)
            ..lineTo(x, y)
            ..lineTo(x, y + u * .055)
            ..lineTo(end.dx, y + u * .055)
            ..lineTo(end.dx, end.dy),
          _line(const Color(0xFF20403E), u * .0025));
      canvas.drawCircle(
          end, u * .007, _line(const Color(0xFF2A514B), u * .002));
      canvas.drawCircle(
          end,
          u * .0025,
          _fill(const Color(0xFF8FE3D3)
              .withValues(alpha: .10 + .025 * math.sin(phase + i))));
    }
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(edge + (right ? -u * .12 : u * .015), h * .91,
                u * .105, u * .045),
            Radius.circular(u * .005)),
        _line(const Color(0xFF233A3D), u * .003));
  }
}

void _volcano(Canvas canvas, Size size, double phase) {
  final w = size.width, h = size.height, u = size.shortestSide;
  _glow(canvas, Offset(w * .5, h + u * .15), u * .8, const Color(0x357B3024));
  for (final right in [false, true]) {
    final edge = right ? w : 0.0;
    final direction = right ? -1.0 : 1.0;
    final crack = Path()
      ..moveTo(edge, h * .18)
      ..lineTo(edge + direction * u * .07, h * .3)
      ..lineTo(edge + direction * u * .025, h * .43)
      ..lineTo(edge + direction * u * .11, h * .58)
      ..lineTo(edge + direction * u * .045, h * .74)
      ..lineTo(edge + direction * u * .14, h)
      ..moveTo(edge + direction * u * .11, h * .58)
      ..lineTo(edge + direction * u * .17, h * .54)
      ..lineTo(edge + direction * u * .19, h * .49);
    canvas.drawPath(crack, _line(const Color(0xFF3C2625), u * .017));
    canvas.drawPath(crack, _line(const Color(0x347B4335), u * .003));
  }
  canvas.drawPath(
      Path()
        ..moveTo(0, h)
        ..lineTo(0, h - u * .025)
        ..quadraticBezierTo(w * .25, h - u * .075, w * .5, h - u * .025)
        ..quadraticBezierTo(w * .8, h - u * .005, w, h - u * .06)
        ..lineTo(w, h)
        ..close(),
      _fill(const Color(0xFF3E2421)));
  _embers(canvas, size, phase, const Color(0xFFDB7154));
}

void _pantry(Canvas canvas, Size size) {
  final w = size.width, h = size.height, u = size.shortestSide;
  final wood = _line(const Color(0xFF36302C), u * .009);
  for (final x in [u * .025, w - u * .025]) {
    canvas.drawLine(Offset(x, 0), Offset(x, h), wood);
    canvas.drawLine(Offset(x + u * .012, 0), Offset(x + u * .012, h),
        _line(const Color(0x124B3C31), u * .002));
  }
  final shelfY = h - u * .07;
  canvas.drawLine(Offset(0, shelfY), Offset(w, shelfY), wood);
  for (final right in [false, true]) {
    for (var i = 0; i < 2; i++) {
      final x = right ? w - u * (.08 + i * .067) : u * (.035 + i * .067);
      final jarHeight = u * (.08 + i * .03);
      final jar = Rect.fromLTWH(x, shelfY - jarHeight, u * .048, jarHeight);
      canvas.drawRRect(RRect.fromRectAndRadius(jar, Radius.circular(u * .009)),
          _fill(i == 0 ? const Color(0xFF303735) : const Color(0xFF38302C)));
      canvas.drawLine(
          jar.topLeft + Offset(0, u * .005),
          jar.topRight + Offset(0, u * .005),
          _line(const Color(0xFF484137), u * .008));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: jar.center,
                  width: jar.width * .65,
                  height: jar.height * .35),
              Radius.circular(u * .003)),
          _fill(const Color(0x164E483C)));
    }
  }
  for (var i = 0; i < 5; i++) {
    final x = w * (i + .5) / 5;
    canvas.drawLine(Offset(x, shelfY + u * .015), Offset(x + u * .015, h),
        _line(const Color(0xFF242020), u * .002));
  }
}

void _jungle(Canvas canvas, Size size, double phase) {
  final w = size.width, h = size.height, u = size.shortestSide;
  _glow(canvas, Offset(w, 0), u * .75, const Color(0x244E6C38));
  for (final right in [false, true]) {
    canvas.save();
    if (right) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }
    final drift = math.sin(phase + (right ? 1 : 0)) * u * .004;
    canvas.drawPath(
        Path()
          ..moveTo(u * .04, -u * .05)
          ..cubicTo(
              u * .12, h * .16, u * .015 + drift, h * .3, u * .045, h * .48),
        _line(const Color(0xFF294732), u * .006));
    for (var i = 0; i < 5; i++) {
      final x = u * (.01 + i % 2 * .045);
      final y = u * (.07 + i * .075);
      final leaf = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + u * .1, y - u * .075, x + u * .18, y - u * .025)
        ..quadraticBezierTo(x + u * .09, y + u * .04, x, y)
        ..close();
      canvas.drawPath(leaf,
          _fill(i.isEven ? const Color(0xFF193A29) : const Color(0xFF20412E)));
      canvas.drawLine(Offset(x, y), Offset(x + u * .15, y - u * .02),
          _line(const Color(0xFF294D33), u * .002));
    }
    for (var i = 0; i < 3; i++) {
      final tip = Offset(u * (.05 + i * .045), h - u * (.12 + i * .06));
      canvas.drawPath(
          Path()
            ..moveTo(0, h)
            ..quadraticBezierTo(
                tip.dx - u * .045, tip.dy - u * .02, tip.dx, tip.dy)
            ..quadraticBezierTo(tip.dx + u * .045, tip.dy + u * .08, 0, h)
            ..close(),
          _fill(i.isEven ? const Color(0xFF173D28) : const Color(0xFF21452E)));
    }
    canvas.restore();
  }
}
