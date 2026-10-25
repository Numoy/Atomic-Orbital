import 'dart:math' as math;

import 'package:flutter/material.dart';

const _disc = Rect.fromLTRB(-1, -1, 1, 1);
const _ink = Color(0xFF283742);

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

void drawCheeseCore(Canvas canvas) {
  final head = Path()
    ..moveTo(-.68, -.2)
    ..lineTo(-.65, -.72)
    ..quadraticBezierTo(-.62, -.8, -.53, -.7)
    ..lineTo(-.3, -.5)
    ..quadraticBezierTo(0, -.64, .3, -.5)
    ..lineTo(.53, -.7)
    ..quadraticBezierTo(.62, -.8, .65, -.72)
    ..lineTo(.68, -.2)
    ..cubicTo(.9, .18, .61, .73, 0, .76)
    ..cubicTo(-.61, .73, -.9, .18, -.68, -.2)
    ..close();
  canvas.drawPath(
      head, _shade(const Color(0xFFFFCB7D), const Color(0xFFD98A4D)));
  for (final side in [-1.0, 1.0]) {
    canvas.save();
    canvas.scale(side, 1);
    canvas.drawPath(
        Path()
          ..moveTo(.4, -.42)
          ..lineTo(.57, -.63)
          ..lineTo(.58, -.26)
          ..close(),
        _fill(const Color(0xFFC67C72)));
    canvas.drawPath(
        Path()
          ..moveTo(.67, -.07)
          ..lineTo(.43, .01)
          ..lineTo(.7, .1)
          ..close()
          ..moveTo(.66, .2)
          ..lineTo(.48, .22)
          ..lineTo(.6, .35)
          ..close(),
        _fill(const Color(0xFFB86B3E)));
    canvas.drawOval(
        Rect.fromCenter(
            center: const Offset(.27, -.09), width: .32, height: .29),
        _fill(const Color(0xFFF4EDB9)));
    canvas.drawOval(const Rect.fromLTRB(.18, -.22, .34, .04),
        _fill(const Color(0xFF638F6F)));
    canvas.drawOval(const Rect.fromLTRB(.23, -.21, .28, .04), _fill(_ink));
    canvas.drawCircle(
        const Offset(.22, -.15), .03, _fill(const Color(0xFFFFF9DB)));
    canvas.drawPath(
        Path()
          ..moveTo(.14, -.26)
          ..quadraticBezierTo(.3, -.33, .42, -.27),
        _line(const Color(0xFFAF683F), .055));
    canvas.drawOval(const Rect.fromLTRB(.02, .18, .39, .46),
        _fill(const Color(0xFFFFE8BF)));
    for (final y in [.17, .31]) {
      canvas.drawLine(Offset(.36, y), Offset(.89, y - .04),
          _line(const Color(0xFFFFE9CB), .035));
    }
    canvas.restore();
  }
  for (final x in [-.18, 0.0, .18]) {
    canvas.drawPath(
        Path()
          ..moveTo(x - .07, -.5)
          ..lineTo(x + .07, -.5)
          ..lineTo(x, -.28)
          ..close(),
        _fill(const Color(0xFFB86B3E)));
  }
  canvas.drawPath(
      Path()
        ..moveTo(-.11, .2)
        ..quadraticBezierTo(0, .14, .11, .2)
        ..lineTo(0, .32)
        ..close(),
      _fill(const Color(0xFFB7736F)));
  canvas.drawPath(
      Path()
        ..moveTo(0, .31)
        ..lineTo(0, .4)
        ..quadraticBezierTo(-.09, .51, -.21, .42)
        ..moveTo(0, .4)
        ..quadraticBezierTo(.09, .51, .21, .42),
      _line(const Color(0xFF7C5749), .035));
}

void drawCheesePlayer(Canvas canvas) {
  canvas.drawPath(
      Path()
        ..moveTo(-.22, .5)
        ..cubicTo(-.82, .76, -.99, .19, -.7, .12),
      _line(const Color(0xFFDAA3A7), .09));
  canvas.drawOval(const Rect.fromLTRB(-.55, -.15, .43, .7),
      _shade(const Color(0xFFCED9DC), const Color(0xFF8499A8)));
  canvas.drawOval(
      const Rect.fromLTRB(-.12, .48, .48, .71), _fill(const Color(0xFFDAA3A7)));
  for (final ear in [const Offset(.02, -.48), const Offset(-.38, -.42)]) {
    canvas.drawCircle(ear, .31, _fill(const Color(0xFFB4C5CB)));
    canvas.drawCircle(ear, .22, _fill(const Color(0xFFEDBEC0)));
  }
  final face = Path()
    ..moveTo(-.38, -.18)
    ..quadraticBezierTo(-.3, -.51, .12, -.36)
    ..quadraticBezierTo(.42, -.28, .81, .06)
    ..quadraticBezierTo(.42, .42, -.07, .39)
    ..quadraticBezierTo(-.47, .32, -.38, -.18)
    ..close();
  canvas.drawPath(
      face, _shade(const Color(0xFFE7EBE8), const Color(0xFFA5B6BF)));
  canvas.drawCircle(const Offset(.31, -.11), .09, _fill(_ink));
  canvas.drawCircle(
      const Offset(.285, -.14), .027, _fill(const Color(0xFFFFF8DE)));
  canvas.drawCircle(
      const Offset(.77, .07), .095, _fill(const Color(0xFFDC9DAB)));
  canvas.drawLine(const Offset(.54, .15), const Offset(.77, .25),
      _line(const Color(0xFF667C8C), .04));
}

void drawCheesePickup(Canvas canvas) {
  canvas.drawPath(
      Path()
        ..moveTo(-.75, -.29)
        ..lineTo(.74, .18)
        ..lineTo(.74, .57)
        ..lineTo(-.75, .13)
        ..close(),
      _fill(const Color(0xFFE4A448)));
  canvas.drawPath(
      Path()
        ..moveTo(.12, -.77)
        ..lineTo(.74, .18)
        ..lineTo(.74, .57)
        ..lineTo(.12, -.32)
        ..close(),
      _fill(const Color(0xFFBD7A32)));
  canvas.drawPath(
      Path()
        ..moveTo(-.75, -.29)
        ..lineTo(.12, -.77)
        ..lineTo(.74, .18)
        ..close(),
      _shade(const Color(0xFFFFEA91), const Color(0xFFFFCD62)));
  for (final hole in [
    (at: const Offset(-.22, -.34), radius: .12),
    (at: const Offset(.16, -.38), radius: .08),
    (at: const Offset(.28, -.06), radius: .1),
  ]) {
    canvas.drawOval(
        Rect.fromCenter(
            center: hole.at, width: hole.radius * 2, height: hole.radius * 1.5),
        _fill(const Color(0xFFE5AA49)));
  }
  for (final hole in [const Offset(-.43, -.01), const Offset(.4, .26)]) {
    canvas.drawCircle(hole, .085, _fill(const Color(0xFFBA7E37)));
    canvas.drawArc(Rect.fromCircle(center: hole, radius: .085), .1, math.pi,
        false, _line(const Color(0xFFFFDB75), .025));
  }
}

void drawCheeseHazard(Canvas canvas) {
  canvas.drawCircle(Offset.zero, .8,
      _shade(const Color(0xFFAC4962), const Color(0xFF622F4A)));
  final thread = _line(const Color(0xFFF7A6A5), .085);
  for (final x in [-.34, 0.0, .34]) {
    canvas.drawPath(
        Path()
          ..moveTo(x - .21, -.5)
          ..quadraticBezierTo(x - .4, .01, x + .21, .52),
        thread);
  }
  canvas.drawPath(
      Path()
        ..moveTo(-.71, .02)
        ..quadraticBezierTo(.04, .39, .71, -.06)
        ..moveTo(-.65, -.23)
        ..quadraticBezierTo(.03, .12, .63, -.4),
      thread);
}

void drawJungleCore(Canvas canvas) {
  for (final x in [-.69, .69]) {
    canvas.drawCircle(Offset(x, .02), .25, _fill(const Color(0xFFA77449)));
    canvas.drawCircle(Offset(x, .02), .16, _fill(const Color(0xFFDEAA76)));
  }
  canvas.drawOval(const Rect.fromLTRB(-.64, -.7, .64, .76),
      _shade(const Color(0xFFBC8A55), const Color(0xFF80563D)));
  canvas.drawPath(
      Path()
        ..moveTo(-.32, -.55)
        ..lineTo(-.22, -.86)
        ..lineTo(-.06, -.7)
        ..lineTo(.09, -.91)
        ..lineTo(.19, -.64)
        ..lineTo(.37, -.74)
        ..lineTo(.35, -.48)
        ..close(),
      _fill(const Color(0xFFB88450)));
  final face = Path()
    ..moveTo(0, -.33)
    ..cubicTo(-.35, -.72, -.73, -.16, -.43, .15)
    ..cubicTo(-.75, .62, -.22, .77, 0, .72)
    ..cubicTo(.4, .78, .72, .49, .43, .15)
    ..cubicTo(.73, -.16, .35, -.72, 0, -.33)
    ..close();
  canvas.drawPath(
      face, _shade(const Color(0xFFF6D89E), const Color(0xFFDFAB75)));
  for (final x in [-.23, .23]) {
    canvas.drawOval(
        Rect.fromCenter(center: Offset(x, -.1), width: .17, height: .24),
        _fill(_ink));
    canvas.drawCircle(
        Offset(x - .035, -.15), .035, _fill(const Color(0xFFFFFAE2)));
  }
  canvas.drawOval(
      const Rect.fromLTRB(-.13, .12, .13, .26), _fill(const Color(0xFFA9714E)));
  canvas.drawPath(
      Path()
        ..moveTo(-.3, .34)
        ..quadraticBezierTo(.02, .68, .33, .31)
        ..quadraticBezierTo(.02, .43, -.3, .34)
        ..close(),
      _fill(const Color(0xFF754C3C)));
  canvas.drawPath(
      Path()
        ..moveTo(-.16, .39)
        ..quadraticBezierTo(.02, .45, .18, .38)
        ..lineTo(.13, .46)
        ..lineTo(-.1, .49)
        ..close(),
      _fill(const Color(0xFFFFF1CD)));
  for (final x in [-.4, .4]) {
    canvas.drawOval(
        Rect.fromCenter(center: Offset(x, .23), width: .13, height: .08),
        _fill(const Color(0xFFD29367)));
  }
}

void drawJunglePlayer(Canvas canvas) {
  canvas.drawPath(
      Path()
        ..moveTo(-.38, .27)
        ..lineTo(-.63, .76)
        ..lineTo(-.18, .71)
        ..lineTo(.03, .37)
        ..close(),
      _fill(const Color(0xFF49A3A0)));
  canvas.drawOval(const Rect.fromLTRB(-.6, -.48, .2, .62),
      _shade(const Color(0xFF437D81), const Color(0xFF234C62)));
  canvas.drawOval(const Rect.fromLTRB(-.26, -.43, .25, .46),
      _fill(const Color(0xFFFFE7B1)));
  canvas.drawOval(const Rect.fromLTRB(-.51, -.02, -.05, .45),
      _fill(const Color(0xFF50B4AA)));
  final beak = Path()
    ..moveTo(-.01, -.44)
    ..quadraticBezierTo(.66, -.72, .88, -.05)
    ..quadraticBezierTo(.58, .13, -.01, .05)
    ..close();
  canvas.drawPath(
      beak, _shade(const Color(0xFFFFD17A), const Color(0xFFE88B49)));
  canvas.drawPath(
      Path()
        ..moveTo(.58, -.44)
        ..quadraticBezierTo(.81, -.31, .88, -.05)
        ..lineTo(.61, .01)
        ..quadraticBezierTo(.69, -.22, .58, -.44)
        ..close(),
      _fill(const Color(0xFF8A584B)));
  canvas.drawLine(const Offset(.1, -.1), const Offset(.7, -.08),
      _line(const Color(0xFFBD7144), .035));
  canvas.drawCircle(const Offset(-.18, -.24), .11, _fill(_ink));
  canvas.drawCircle(
      const Offset(-.2, -.27), .032, _fill(const Color(0xFFFFFAE2)));
  canvas.drawLine(const Offset(-.08, .54), const Offset(.16, .66),
      _line(const Color(0xFFE1A76D), .08));
}

void drawJunglePickup(Canvas canvas) {
  final peel = Path()
    ..moveTo(-.68, -.63)
    ..cubicTo(-.59, .02, -.19, .51, .63, .08)
    ..lineTo(.76, -.11)
    ..cubicTo(.59, .83, -.14, .94, -.57, .45)
    ..quadraticBezierTo(-.86, .11, -.68, -.63)
    ..close();
  canvas.drawPath(
      peel, _shade(const Color(0xFFFFE99A), const Color(0xFFE6B34C)));
  canvas.drawPath(
      Path()
        ..moveTo(-.61, -.29)
        ..cubicTo(-.55, .5, .07, .76, .59, .25),
      _line(const Color(0xFFFFF0AD), .075));
  canvas.drawLine(const Offset(-.67, -.62), const Offset(-.53, -.74),
      _line(const Color(0xFF8E8750), .13));
  canvas.drawLine(const Offset(.65, .07), const Offset(.74, -.08),
      _line(const Color(0xFF9D7941), .095));
}

void drawJungleHazard(Canvas canvas) {
  canvas.drawCircle(Offset.zero, .79,
      _shade(const Color(0xFFBD875C), const Color(0xFF704A3B)));
  for (final x in [-.33, .22]) {
    canvas.drawPath(
        Path()
          ..moveTo(x, -.58)
          ..quadraticBezierTo(x - .22, 0, x + .08, .59),
        _line(const Color(0xFFD9AB7B), .055));
  }
  canvas.drawPath(
      Path()
        ..moveTo(-.11, -.73)
        ..lineTo(.06, -.4)
        ..lineTo(-.08, -.08)
        ..lineTo(.16, .14)
        ..lineTo(.03, .46)
        ..lineTo(.15, .71),
      _line(const Color(0xFFFFE5B9), .085));
  for (final eye in [
    const Offset(-.38, -.28),
    const Offset(-.19, -.37),
    const Offset(-.25, -.12),
  ]) {
    canvas.drawCircle(eye, .07, _fill(const Color(0xFF654335)));
  }
}
