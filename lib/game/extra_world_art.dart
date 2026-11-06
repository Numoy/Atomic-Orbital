import 'dart:math' as math;

import 'package:flutter/material.dart';

const _disc = Rect.fromLTRB(-1, -1, 1, 1);
const _ink = Color(0xFF172B3A);

Paint _fill(Color color) => Paint()..color = color;
Paint _line(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..strokeWidth = width;
Paint _shade(Color light, Color dark) => Paint()
  ..shader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [light, dark],
  ).createShader(_disc);

double _blink(double time) {
  final phase = time % 4;
  return phase < 3.75
      ? 1
      : math.max(.08, math.cos((phase - 3.75) * math.pi / .25).abs());
}

void _eyes(Canvas canvas, double y, {double time = 0, double spread = .22}) {
  final open = _blink(time);
  final look = math.sin(time * math.pi / 4) * .025;
  for (final x in [-spread, spread]) {
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(1, open);
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: .25, height: .3),
        _fill(const Color(0xFFFFF2D5)));
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(.025 + look, .02), width: .105, height: .19),
        _fill(_ink));
    canvas.drawCircle(Offset(.005 + look, -.035), .025, _fill(Colors.white));
    canvas.restore();
  }
}

void drawDragonCore(Canvas canvas,
    {double time = 0, double charge = 0, double fire = 0}) {
  for (final side in [-1.0, 1.0]) {
    canvas.save();
    canvas.scale(side, 1);
    canvas.save();
    canvas.translate(.35, .25);
    canvas.rotate(
        math.sin(time * math.pi / 2) * .045 - .16 * charge + .12 * fire);
    canvas.translate(-.35, -.25);
    final wing = Path()
      ..moveTo(.34, .23)
      ..lineTo(.87, -.35)
      ..quadraticBezierTo(.92, .12, .77, .48)
      ..quadraticBezierTo(.61, .25, .43, .52)
      ..close();
    canvas.drawPath(
        wing, _shade(const Color(0xFF60AA89), const Color(0xFF2A695B)));
    canvas.drawPath(
        Path()
          ..moveTo(.42, .33)
          ..lineTo(.8, -.13)
          ..lineTo(.67, .34),
        _line(const Color(0xFF9CD1A1), .035));
    canvas.restore();
    canvas.drawPath(
        Path()
          ..moveTo(.29, -.42)
          ..quadraticBezierTo(.31, -.69, .53, -.81)
          ..quadraticBezierTo(.48, -.48, .51, -.3)
          ..close(),
        _shade(const Color(0xFFFFE8A7), const Color(0xFFBA9558)));
    canvas.restore();
  }
  canvas.drawOval(const Rect.fromLTRB(-.5, -.59, .5, .68),
      _shade(const Color(0xFFACD78D), const Color(0xFF3D9779)));
  canvas.drawPath(
      Path()
        ..moveTo(-.13, -.48)
        ..lineTo(0, -.77)
        ..lineTo(.13, -.48)
        ..close(),
      _fill(const Color(0xFFE8CA77)));
  _eyes(canvas, -.19, time: time);
  for (final side in [-1.0, 1.0]) {
    canvas.drawLine(Offset(side * .1, -.4), Offset(side * .36, -.46),
        _line(const Color(0xFF377665), .065));
  }
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(-.49, .03, .49, .46), const Radius.circular(.2)),
      _shade(const Color(0xFFCDE6A1), const Color(0xFF75B47B)));
  for (final x in [-.23, .23]) {
    canvas.drawOval(
        Rect.fromCenter(center: Offset(x, .16), width: .12, height: .075),
        _fill(const Color(0xFF3E7765)));
  }
  canvas.drawArc(const Rect.fromLTRB(-.3, .17, .3, .43), 0, math.pi, false,
      _line(const Color(0xFF295E53), .045));
  for (final x in [-.26, .26]) {
    canvas.drawPath(
        Path()
          ..moveTo(x - .065, .32)
          ..lineTo(x, .47)
          ..lineTo(x + .055, .32)
          ..close(),
        _fill(const Color(0xFFFFF2CD)));
  }
  canvas.drawOval(const Rect.fromLTRB(-.29, .48, .29, .79),
      _shade(const Color(0xFFE4CE8B), const Color(0xFFB09E64)));
  canvas.drawLine(const Offset(-.18, .63), const Offset(.18, .63),
      _line(const Color(0xFF9A9C65), .035));
  if (charge > 0 || fire > 0) {
    canvas.drawOval(
        Rect.fromCenter(
            center: const Offset(0, .34),
            width: .24 + .08 * fire,
            height: .06 + .08 * charge + .14 * fire),
        _fill(const Color(0xFF294F45)));
    canvas.drawPath(
        Path()
          ..moveTo(0, .33)
          ..cubicTo(-.14, .45, -.1, .61, 0, .66)
          ..cubicTo(.1, .61, .14, .45, 0, .33)
          ..close(),
        _fill(const Color(0xFFFFD585).withValues(alpha: fire * .85)));
  }
}

void drawDragonPlayer(Canvas canvas) {
  canvas.drawPath(
      Path()
        ..moveTo(-.2, -.45)
        ..quadraticBezierTo(-.35, -.95, .2, -.94)
        ..quadraticBezierTo(.47, -.86, .35, -.64)
        ..lineTo(.08, -.45)
        ..close(),
      _fill(const Color(0xFFCE6E65)));
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(-.55, -.61, .55, .4), const Radius.circular(.27)),
      _shade(const Color(0xFFE2F1ED), const Color(0xFF7898AA)));
  canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(-.43, -.25, .43, -.02),
          const Radius.circular(.05)),
      _fill(_ink));
  canvas.drawLine(const Offset(0, -.52), const Offset(0, .1),
      _line(const Color(0xFFFBF7DC), .085));
  final shield = Path()
    ..moveTo(-.54, .13)
    ..quadraticBezierTo(0, -.03, .54, .13)
    ..lineTo(.42, .56)
    ..quadraticBezierTo(.26, .79, 0, .94)
    ..quadraticBezierTo(-.26, .79, -.42, .56)
    ..close();
  canvas.drawPath(
      shield, _shade(const Color(0xFF5CA7C0), const Color(0xFF2D637D)));
  canvas.drawPath(shield, _line(const Color(0xFFE4D092), .075));
  canvas.drawLine(const Offset(0, .21), const Offset(0, .7),
      _line(const Color(0xFFFFE4A0), .1));
  canvas.drawLine(const Offset(-.19, .4), const Offset(.19, .4),
      _line(const Color(0xFFFFE4A0), .1));
}

void drawDragonPickup(Canvas canvas) {
  final gem = Path()
    ..moveTo(-.46, -.63)
    ..lineTo(.46, -.63)
    ..lineTo(.85, -.16)
    ..lineTo(0, .91)
    ..lineTo(-.85, -.16)
    ..close();
  canvas.drawPath(
      gem, _shade(const Color(0xFFFFE9A2), const Color(0xFFD89A45)));
  canvas.drawPath(
      Path()
        ..moveTo(-.46, -.63)
        ..lineTo(-.3, -.16)
        ..lineTo(0, .91)
        ..lineTo(.3, -.16)
        ..lineTo(.46, -.63),
      _line(const Color(0xFFFFF0BB), .04));
  canvas.drawPath(
      Path()
        ..moveTo(-.85, -.16)
        ..lineTo(.85, -.16)
        ..moveTo(-.3, -.16)
        ..lineTo(0, -.63)
        ..lineTo(.3, -.16),
      _line(const Color(0xFFFFF5D4), .045));
}

void drawDragonHazard(Canvas canvas, {double time = 0}) {
  canvas.save();
  canvas.rotate(math.sin(time * math.pi) * .06);
  final flame = Path()
    ..moveTo(0, -.93)
    ..cubicTo(.16, -.48, .74, -.35, .72, .18)
    ..cubicTo(.7, .96, -.74, .96, -.72, .11)
    ..quadraticBezierTo(-.66, -.29, -.3, -.53)
    ..quadraticBezierTo(-.38, -.02, -.2, .02)
    ..quadraticBezierTo(.06, -.31, 0, -.93)
    ..close();
  canvas.drawPath(flame, _line(const Color(0xFFFF9861), .08));
  canvas.drawPath(
      flame, _shade(const Color(0xFFFFCD68), const Color(0xFFF16D3D)));
  canvas.drawPath(
      Path()
        ..moveTo(.04, -.13)
        ..quadraticBezierTo(.5, .52, .04, .63)
        ..quadraticBezierTo(-.42, .53, .04, -.13)
        ..close(),
      _fill(const Color(0xFFFFEAB0)));
  canvas.restore();
}

void drawSunflowerCore(Canvas canvas,
    {double time = 0, double charge = 0, double fire = 0}) {
  for (var i = 0; i < 12; i++) {
    canvas.save();
    canvas.rotate(i * math.pi / 6 +
        math.sin(time * math.pi / 4) * .035 +
        (i.isEven ? .035 : -.035) * fire);
    canvas.translate(0, .075 * charge - .02 * fire);
    canvas.drawOval(const Rect.fromLTRB(-.17, -.94, .17, -.29),
        _shade(const Color(0xFFFFDB83), const Color(0xFFDC9B45)));
    canvas.drawLine(const Offset(0, -.74), const Offset(0, -.5),
        _line(const Color(0xFFFFEBA4), .025));
    canvas.restore();
  }
  canvas.drawCircle(Offset.zero, .53,
      _shade(const Color(0xFF9E6B46), const Color(0xFF573D38)));
  canvas.drawCircle(Offset.zero, .47,
      _shade(const Color(0xFFD29860), const Color(0xFF9E6044)));
  for (final dot in [
    const Offset(-.34, -.22),
    const Offset(-.12, -.36),
    const Offset(.12, -.36),
    const Offset(.34, -.22),
    const Offset(-.36, .17),
    const Offset(.36, .17),
    const Offset(-.19, .35),
    const Offset(.19, .35),
  ]) {
    canvas.drawCircle(dot, .027, _fill(const Color(0xFFF0C188)));
  }
  for (final x in [-.18, .18]) {
    canvas.save();
    canvas.translate(x, -.08);
    canvas.scale(1, _blink(time));
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: .095, height: .16),
        _fill(_ink));
    canvas.drawCircle(
        const Offset(-.015, -.04), .022, _fill(const Color(0xFFFFEFC2)));
    canvas.restore();
  }
  canvas.drawArc(const Rect.fromLTRB(-.17, -.01, .17, .24), 0, math.pi, false,
      _line(const Color(0xFF643C35), .045));
  for (final x in [-.29, .29]) {
    canvas.drawOval(
        Rect.fromCenter(center: Offset(x, .1), width: .12, height: .07),
        _fill(const Color(0xFFE3A06D)));
  }
}

void drawSunflowerPlayer(Canvas canvas) {
  for (final side in [-1.0, 1.0]) {
    canvas.save();
    canvas.scale(side, 1);
    canvas.drawOval(const Rect.fromLTRB(.06, -.75, .85, .16),
        _shade(const Color(0xFFEAF8EE), const Color(0xFF96C8CA)));
    canvas.drawLine(const Offset(.24, -.55), const Offset(.62, -.32),
        _line(const Color(0xFFFFFFFF), .04));
    canvas.drawLine(const Offset(.15, -.42), const Offset(.32, -.84),
        _line(const Color(0xFF8FAFB3), .055));
    canvas.restore();
  }
  final body = Path()..addOval(const Rect.fromLTRB(-.43, -.5, .43, .83));
  canvas.drawPath(
      body, _shade(const Color(0xFFFFE298), const Color(0xFFDFA74E)));
  canvas.save();
  canvas.clipPath(body);
  for (final y in [.11, .45]) {
    canvas.drawRect(
        Rect.fromLTRB(-.5, y, .5, y + .17), _fill(const Color(0xFF35434A)));
  }
  canvas.restore();
  for (final x in [-.16, .16]) {
    canvas.drawCircle(Offset(x, -.28), .075, _fill(_ink));
    canvas.drawCircle(Offset(x - .018, -.3), .023, _fill(Colors.white));
  }
}

void drawSunflowerPickup(Canvas canvas) {
  final hexagon = Path();
  for (var i = 0; i < 6; i++) {
    final angle = i * math.pi / 3 - math.pi / 2;
    final x = math.cos(angle) * .87;
    final y = math.sin(angle) * .87;
    i == 0 ? hexagon.moveTo(x, y) : hexagon.lineTo(x, y);
  }
  hexagon.close();
  canvas.drawPath(
      hexagon, _shade(const Color(0xFFFFE8A1), const Color(0xFFD8A04B)));
  canvas.drawPath(hexagon, _line(const Color(0xFFFFF2C6), .055));
  for (final dot in [
    const Offset(-.23, .14),
    const Offset(.23, .14),
    const Offset(0, -.25)
  ]) {
    canvas.drawCircle(dot, .19, _fill(const Color(0xFFFFF1B3)));
    canvas.drawCircle(
        dot + const Offset(-.045, -.05), .055, _fill(Colors.white));
  }
}

void drawSunflowerHazard(Canvas canvas, {double time = 0}) {
  canvas.save();
  canvas.rotate(time * math.pi / 4);
  final seed = Path()
    ..moveTo(0, -.94)
    ..cubicTo(.78, -.3, .74, .58, 0, .89)
    ..cubicTo(-.74, .58, -.78, -.3, 0, -.94)
    ..close();
  canvas.drawPath(seed, _line(const Color(0xFFFFD88F), .09));
  canvas.drawPath(
      seed, _shade(const Color(0xFF9D7752), const Color(0xFF473C39)));
  for (final side in [-1.0, 1.0]) {
    canvas.drawPath(
        Path()
          ..moveTo(side * .08, -.59)
          ..quadraticBezierTo(side * .36, .09, side * .12, .63),
        _line(const Color(0xFFFFEDBF), .09));
  }
  canvas.restore();
}

void drawFrostCore(Canvas canvas,
    {double time = 0, double charge = 0, double fire = 0}) {
  for (final x in [-.61, .61]) {
    canvas.drawCircle(Offset(x, -.08), .23, _fill(const Color(0xFFC0DBE3)));
    canvas.drawCircle(Offset(x, -.08), .12, _fill(const Color(0xFF6895AC)));
  }
  canvas.drawOval(
      Rect.fromLTRB(-.62, -.67, .62, .73 + math.sin(time * math.pi / 2) * .018),
      _shade(const Color(0xFFF0F5E9), const Color(0xFFA8CBD9)));
  canvas.drawPath(
      Path()
        ..moveTo(-.25, -.55)
        ..lineTo(-.18, -.89)
        ..lineTo(.03, -.66)
        ..lineTo(.2, -.85)
        ..lineTo(.25, -.51)
        ..close(),
      _fill(const Color(0xFFE8F1E6)));
  canvas.drawOval(const Rect.fromLTRB(-.48, -.33, .48, .35),
      _shade(const Color(0xFF84B8C9), const Color(0xFF4C829C)));
  canvas.save();
  canvas.translate(0, -.08);
  canvas.scale(1, 1 - .22 * charge + .06 * fire);
  canvas.translate(0, .08);
  _eyes(canvas, -.08, time: time);
  canvas.restore();
  canvas.drawOval(
      const Rect.fromLTRB(-.13, .04, .13, .19), _fill(const Color(0xFF315971)));
  canvas.drawArc(const Rect.fromLTRB(-.28, .17, .28, .46), 0, math.pi, false,
      _line(const Color(0xFF3A697E), .07));
  for (final x in [-.23, .23]) {
    canvas.drawPath(
        Path()
          ..moveTo(x - .065, .25)
          ..lineTo(x, .44)
          ..lineTo(x + .065, .25)
          ..close(),
        _fill(const Color(0xFFFFF5DB)));
  }
  canvas.drawPath(
      Path()
        ..moveTo(-.52, .45)
        ..quadraticBezierTo(0, .69, .52, .45)
        ..lineTo(.43, .68)
        ..quadraticBezierTo(0, .9, -.43, .68)
        ..close(),
      _shade(const Color(0xFFCC817A), const Color(0xFFA44F61)));
  canvas.drawLine(const Offset(-.22, .58), const Offset(-.2, .75),
      _line(const Color(0xFFF2B8A0), .09));
  if (fire > 0) {
    for (final x in [-.12, .08]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, .39 + .05 * fire),
              width: .17 + .1 * fire,
              height: .07 + .1 * fire),
          _fill(const Color(0xFFD9F6FF).withValues(alpha: .62 * fire)));
    }
  }
}

void drawFrostPlayer(Canvas canvas) {
  for (final side in [-1.0, 1.0]) {
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(side * .24, .75), width: .44, height: .22),
        _fill(const Color(0xFFEABD72)));
    canvas.save();
    canvas.rotate(side * -.3);
    canvas.drawOval(
        Rect.fromLTRB(side > 0 ? .35 : -.82, -.13, side > 0 ? .82 : -.35, .57),
        _fill(const Color(0xFF527286)));
    canvas.restore();
  }
  canvas.drawOval(const Rect.fromLTRB(-.51, -.84, .51, .78),
      _shade(const Color(0xFF5A788C), const Color(0xFF1E3B53)));
  canvas.drawOval(const Rect.fromLTRB(-.36, -.21, .36, .66),
      _shade(const Color(0xFFFBF6E2), const Color(0xFFBED9DF)));
  for (final x in [-.2, .2]) {
    canvas.drawOval(
        Rect.fromCenter(center: Offset(x, -.39), width: .27, height: .42),
        _fill(const Color(0xFFF1F3E4)));
    canvas.drawCircle(Offset(x, -.39), .07, _fill(_ink));
  }
  canvas.drawPath(
      Path()
        ..moveTo(-.16, -.2)
        ..lineTo(.16, -.2)
        ..lineTo(0, -.015)
        ..close(),
      _fill(const Color(0xFFF0B86E)));
}

void drawFrostPickup(Canvas canvas) {
  canvas.drawPath(
      Path()
        ..moveTo(.35, 0)
        ..lineTo(.88, -.39)
        ..lineTo(.8, 0)
        ..lineTo(.88, .39)
        ..close(),
      _shade(const Color(0xFF9DDADD), const Color(0xFF5C9FBA)));
  canvas.drawOval(const Rect.fromLTRB(-.92, -.46, .58, .46),
      _shade(const Color(0xFFE1F1E5), const Color(0xFF72B9CA)));
  canvas.drawPath(
      Path()
        ..moveTo(-.17, -.12)
        ..lineTo(.17, -.38)
        ..lineTo(.21, .04)
        ..close(),
      _fill(const Color(0xFF629DB8)));
  canvas.drawCircle(const Offset(-.59, -.06), .09, _fill(_ink));
  canvas.drawCircle(const Offset(-.61, -.085), .025, _fill(Colors.white));
  canvas.drawArc(const Rect.fromLTRB(-.62, -.29, -.19, .3), -math.pi / 2,
      math.pi, false, _line(const Color(0xFF76ACBB), .035));
}

void drawFrostHazard(Canvas canvas, {double time = 0}) {
  canvas.save();
  canvas.rotate(time * math.pi / 4);
  final ice = Path()
    ..moveTo(0, -.94)
    ..lineTo(.74, -.06)
    ..lineTo(.42, .75)
    ..lineTo(-.4, .78)
    ..lineTo(-.73, -.08)
    ..close();
  canvas.drawPath(ice, _line(const Color(0xFFD8F8FF), .07));
  canvas.drawPath(
      ice, _shade(const Color(0xFFE1FAFF), const Color(0xFF5C9FC4)));
  canvas.drawPath(
      Path()
        ..moveTo(0, -.94)
        ..lineTo(-.08, .04)
        ..lineTo(.42, .75)
        ..moveTo(-.73, -.08)
        ..lineTo(-.08, .04)
        ..lineTo(.74, -.06)
        ..moveTo(-.08, .04)
        ..lineTo(-.4, .78),
      _line(const Color(0xFFF5FEFF), .07));
  canvas.restore();
}
