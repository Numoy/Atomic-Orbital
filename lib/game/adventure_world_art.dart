import 'dart:math' as math;

import 'package:flutter/material.dart';

const _disc = Rect.fromLTRB(-1, -1, 1, 1);
const _ink = Color(0xFF213448);

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

void drawHauntedCore(Canvas canvas,
    {double time = 0, double charge = 0, double fire = 0}) {
  final idleGlow = Color.lerp(const Color(0xFFFFCC6C), const Color(0xFFFFF0BD),
      .5 + .5 * math.cos(time * math.pi / 2))!;
  final glow = Color.lerp(
      Color.lerp(idleGlow, const Color(0xFFFFA34D), charge * .65),
      const Color(0xFFFFFFE1),
      fire)!;
  canvas.drawPath(
      Path()
        ..moveTo(-.12, -.45)
        ..lineTo(-.17, -.84)
        ..quadraticBezierTo(-.07, -.94, .12, -.87)
        ..lineTo(.1, -.46)
        ..close(),
      _shade(const Color(0xFFB6CC85), const Color(0xFF5E8060)));
  canvas.drawPath(
      Path()
        ..moveTo(.05, -.62)
        ..quadraticBezierTo(.19, -.89, .5, -.75)
        ..quadraticBezierTo(.43, -.52, .05, -.62)
        ..close(),
      _shade(const Color(0xFF88BB83), const Color(0xFF477B64)));
  canvas.drawOval(const Rect.fromLTRB(-.88, -.55, .31, .72),
      _shade(const Color(0xFFEAA160), const Color(0xFFB56343)));
  canvas.drawOval(const Rect.fromLTRB(-.28, -.55, .88, .72),
      _shade(const Color(0xFFE8A363), const Color(0xFFAA533F)));
  canvas.drawOval(const Rect.fromLTRB(-.59, -.6, .59, .81),
      _shade(const Color(0xFFFFC878), const Color(0xFFD77C4C)));
  for (final side in [-1.0, 1.0]) {
    canvas.save();
    canvas.scale(side, 1);
    canvas.drawPath(
        Path()
          ..moveTo(.27, -.5)
          ..cubicTo(.47, -.25, .51, .3, .3, .7),
        _line(const Color(0xFFBD6D46).withValues(alpha: .6), .035));
    final eye = Path()
      ..moveTo(.11, -.16)
      ..lineTo(.39, -.29)
      ..lineTo(.45, .04)
      ..quadraticBezierTo(.25, .06, .11, -.16)
      ..close();
    canvas.drawPath(eye, _fill(const Color(0xFF613E3E)));
    canvas.save();
    canvas.translate(.29, -.1);
    canvas.scale(1, .92 + .08 * math.cos(time * math.pi / 2));
    canvas.translate(-.29, .1);
    canvas.drawPath(
        Path()
          ..moveTo(.18, -.13)
          ..lineTo(.36, -.22)
          ..lineTo(.4, -.015)
          ..close(),
        _fill(glow));
    canvas.restore();
    canvas.restore();
  }
  canvas.drawPath(
      Path()
        ..moveTo(0, -.03)
        ..lineTo(-.09, .13)
        ..lineTo(.09, .13)
        ..close(),
      _fill(const Color(0xFF75463C)));
  final grin = Path()
    ..moveTo(-.46, .23)
    ..lineTo(-.18, .32)
    ..lineTo(-.16, .23)
    ..lineTo(-.02, .25)
    ..lineTo(0, .34)
    ..lineTo(.22, .3)
    ..lineTo(.24, .22)
    ..lineTo(.46, .19)
    ..quadraticBezierTo(.31, .65, -.08, .56)
    ..quadraticBezierTo(-.34, .51, -.46, .23)
    ..close();
  canvas.drawPath(grin, _fill(const Color(0xFF613E3E)));
  if (fire > 0) {
    canvas.drawPath(grin, _fill(glow.withValues(alpha: fire * .38)));
  }
  canvas.drawPath(
      Path()
        ..moveTo(-.28, .39)
        ..quadraticBezierTo(-.02, .58, .29, .38)
        ..quadraticBezierTo(.08, .48, -.28, .39),
      _line(glow, .06));
}

void drawHauntedPlayer(Canvas canvas) {
  final ghost = Path()
    ..moveTo(-.54, -.1)
    ..cubicTo(-.59, -.98, .54, -1, .56, -.13)
    ..quadraticBezierTo(.65, .1, .85, .28)
    ..quadraticBezierTo(.64, .45, .48, .27)
    ..lineTo(.48, .77)
    ..quadraticBezierTo(.24, .97, .04, .65)
    ..quadraticBezierTo(-.18, .97, -.4, .76)
    ..lineTo(-.49, .27)
    ..quadraticBezierTo(-.66, .46, -.83, .26)
    ..quadraticBezierTo(-.57, .13, -.54, -.1)
    ..close();
  canvas.drawPath(
      ghost, _shade(const Color(0xFFFFF6D9), const Color(0xFFD8D5CB)));
  for (final x in [-.2, .2]) {
    canvas.drawOval(
        Rect.fromCenter(center: Offset(x, -.12), width: .16, height: .23),
        _fill(_ink));
  }
  canvas.drawOval(
      const Rect.fromLTRB(-.09, .12, .09, .3), _fill(const Color(0xFF8F9199)));
}

void drawHauntedPickup(Canvas canvas) {
  for (final side in [-1.0, 1.0]) {
    canvas.save();
    canvas.scale(side, 1);
    canvas.drawPath(
        Path()
          ..moveTo(.34, 0)
          ..lineTo(.81, -.44)
          ..lineTo(.9, -.06)
          ..lineTo(.82, .43)
          ..close(),
        _shade(const Color(0xFFCAB7E2), const Color(0xFF9478BC)));
    canvas.drawLine(const Offset(.49, 0), const Offset(.78, .03),
        _line(const Color(0xFFEADCF5), .045));
    canvas.restore();
  }
  canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(-.53, -.48, .53, .48),
          const Radius.circular(.24)),
      _shade(const Color(0xFFFFE7A5), const Color(0xFFEAB56D)));
  canvas.drawPath(
      Path()
        ..moveTo(-.32, -.37)
        ..quadraticBezierTo(-.05, 0, -.12, .38)
        ..moveTo(.06, -.38)
        ..quadraticBezierTo(.37, 0, .27, .34),
      _line(const Color(0xFFAF7FAF), .13));
}

void drawHauntedHazard(Canvas canvas, {double time = 0}) {
  canvas.save();
  final flap = math.sin(time * math.pi * 2) * .1;
  final bat = Path()
    ..moveTo(-.15, -.18)
    ..lineTo(-.77, -.42 + flap)
    ..quadraticBezierTo(-.68, -.03, -.78, .19)
    ..quadraticBezierTo(-.46, .02, -.43, .39)
    ..quadraticBezierTo(-.2, .19, 0, .54)
    ..quadraticBezierTo(.2, .19, .43, .39)
    ..quadraticBezierTo(.46, .02, .78, .19)
    ..quadraticBezierTo(.68, -.03, .77, -.42 + flap)
    ..lineTo(.15, -.18)
    ..lineTo(.12, -.48)
    ..lineTo(0, -.33)
    ..lineTo(-.12, -.48)
    ..close();
  canvas.drawPath(bat, _line(const Color(0xFFD8BCEB), .08));
  canvas.drawPath(
      bat, _shade(const Color(0xFF9B80BA), const Color(0xFF574466)));
  for (final x in [-.09, .09]) {
    canvas.drawCircle(Offset(x, -.1), .055, _fill(const Color(0xFFFFDCAF)));
  }
  canvas.restore();
}

void drawJunkyardCore(Canvas canvas,
    {double time = 0, double charge = 0, double fire = 0}) {
  final antenna = Offset(math.sin(time * math.pi / 2) * .035, -.84);
  canvas.drawLine(
      const Offset(0, -.42), antenna, _line(const Color(0xFF9AB3B4), .075));
  canvas.drawCircle(
      antenna,
      .11 + .025 * charge,
      _fill(Color.lerp(const Color(0xFFE9AD6D), const Color(0xFFFFEAB0),
          .5 + .5 * math.cos(time * math.pi))!));
  for (final x in [-.75, .75]) {
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, .06), width: .28, height: .5),
            const Radius.circular(.1)),
        _shade(const Color(0xFFA7C2BF), const Color(0xFF536F7A)));
    canvas.drawLine(
        Offset(x, -.04), Offset(x, .16), _line(const Color(0xFFE2E9D6), .05));
  }
  canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(-.63, -.61, .63, .65),
          const Radius.circular(.24)),
      _shade(const Color(0xFF98CBC0), const Color(0xFF4B8D8E)));
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(-.49, -.36, .49, .2), const Radius.circular(.16)),
      _shade(const Color(0xFF315363), const Color(0xFF1D354A)));
  for (final x in [-.23, .23]) {
    canvas.save();
    canvas.translate(x + math.sin(time * math.pi / 4) * .035, -.08);
    canvas.scale(1, _blink(time));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: .2, height: .25),
            const Radius.circular(.06)),
        _fill(const Color(0xFFFFD994)));
    canvas.drawLine(const Offset(-.06, -.05), const Offset(.035, -.05),
        _line(const Color(0xFFFFF3CF), .035));
    canvas.restore();
  }
  canvas.drawLine(const Offset(-.35, -.45), const Offset(-.13, -.4),
      _line(const Color(0xFF456E75), .04));
  canvas.drawLine(const Offset(.13, -.4), const Offset(.35, -.47),
      _line(const Color(0xFF456E75), .04));
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(-.31, .34, .31, .49), const Radius.circular(.05)),
      _fill(const Color(0xFF335866)));
  for (final x in [-.17, 0.0, .17]) {
    canvas.drawLine(
        Offset(x, .37), Offset(x, .46), _line(const Color(0xFFCAE3D1), .04));
  }
  for (final x in [-.46, .46]) {
    canvas.drawCircle(Offset(x, .44), .055, _fill(const Color(0xFFDBDEC6)));
  }
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(-.32, .66, .32, .83), const Radius.circular(.06)),
      _shade(const Color(0xFF9FB7B3), const Color(0xFF65818C)));
  if (fire > 0) {
    canvas.drawCircle(antenna, .14,
        _line(const Color(0xFFFFF3C4).withValues(alpha: .8 * fire), .025));
    for (final side in [-1.0, 1.0]) {
      canvas.drawPath(
          Path()
            ..moveTo(side * .64, -.15)
            ..lineTo(side * .74, -.04)
            ..lineTo(side * .66, .04)
            ..lineTo(side * .74, .17),
          _line(const Color(0xFFD9FFE2).withValues(alpha: .9 * fire), .04));
    }
  }
}

void drawJunkyardPlayer(Canvas canvas) {
  canvas.drawLine(const Offset(-.64, -.2), const Offset(.64, -.2),
      _line(const Color(0xFF6F9B9E), .16));
  for (final x in [-.63, .63]) {
    canvas.drawOval(
        Rect.fromCenter(center: Offset(x, -.25), width: .62, height: .36),
        _shade(const Color(0xFFC0DCD2), const Color(0xFF5F969D)));
    canvas.drawLine(Offset(x - .2, -.26), Offset(x + .2, -.26),
        _line(const Color(0xFFF4EBC8), .07));
  }
  canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(-.43, -.62, .43, .52),
          const Radius.circular(.25)),
      _shade(const Color(0xFFFFCD8A), const Color(0xFFD78958)));
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(-.29, -.3, .29, .03), const Radius.circular(.12)),
      _fill(const Color(0xFF2B5364)));
  canvas.drawCircle(const Offset(0, -.14), .09, _fill(const Color(0xFFB8E8DD)));
  for (final side in [-1.0, 1.0]) {
    canvas.drawPath(
        Path()
          ..moveTo(side * .21, .41)
          ..lineTo(side * .31, .7)
          ..lineTo(side * .12, .77),
        _line(const Color(0xFFB4CECD), .11));
  }
}

void drawJunkyardPickup(Canvas canvas) {
  final head = Path();
  for (var i = 0; i < 6; i++) {
    final angle = math.pi / 3 * i - math.pi / 6;
    final x = math.cos(angle) * .85;
    final y = math.sin(angle) * .85;
    i == 0 ? head.moveTo(x, y) : head.lineTo(x, y);
  }
  head.close();
  canvas.drawPath(
      head, _shade(const Color(0xFFF1F5E8), const Color(0xFF8FAFBD)));
  canvas.drawPath(head, _line(const Color(0xFFC9DDDD), .055));
  canvas.drawCircle(Offset.zero, .38, _fill(const Color(0xFF537486)));
  canvas.drawCircle(Offset.zero, .28, _fill(const Color(0xFFD6E6E1)));
  canvas.drawLine(const Offset(-.16, -.16), const Offset(.16, .16),
      _line(const Color(0xFF4C6A7E), .12));
}

void drawJunkyardHazard(Canvas canvas, {double time = 0}) {
  final spark = Path()
    ..moveTo(.15, -.91)
    ..lineTo(-.64, .08)
    ..lineTo(-.06, .07)
    ..lineTo(-.19, .9)
    ..lineTo(.64, -.22)
    ..lineTo(.1, -.15)
    ..close();
  canvas.drawPath(spark, _line(const Color(0xFFEAA04E), .09));
  canvas.drawPath(
      spark, _shade(const Color(0xFFFFF1AB), const Color(0xFFFFCE60)));
  final shine = .75 + .25 * math.cos(time * math.pi * 2);
  canvas.drawLine(const Offset(.04, -.56), const Offset(-.32, -.04),
      _line(const Color(0xFFFFFFDF).withValues(alpha: shine), .09));
}

void drawVolcanoCore(Canvas canvas,
    {double time = 0, double charge = 0, double fire = 0}) {
  for (var i = 0; i < 3; i++) {
    final rise = (time / 4 + i / 3) % 1;
    canvas.drawCircle(
        Offset(math.sin(rise * math.pi * 1.7 + i * 2.1) * .075 * rise,
            -.52 - .32 * rise),
        .06 + .045 * rise + .018 * charge + .025 * fire,
        _fill(const Color(0xFFAFBCB5).withValues(
            alpha: math.sin(rise * math.pi) * (.7 + .1 * charge + .2 * fire))));
  }
  final mountain = Path()
    ..moveTo(-.26, -.48)
    ..quadraticBezierTo(0, -.59, .26, -.48)
    ..lineTo(.45, .03)
    ..quadraticBezierTo(.57, .3, .77, .55)
    ..quadraticBezierTo(0, .99, -.77, .55)
    ..quadraticBezierTo(-.54, .22, -.43, -.02)
    ..close();
  canvas.drawPath(
      mountain, _shade(const Color(0xFFA28F83), const Color(0xFF5B5967)));
  canvas.drawPath(
      Path()
        ..moveTo(-.28, -.4)
        ..lineTo(-.46, .2)
        ..lineTo(-.57, .47)
        ..moveTo(.3, -.24)
        ..lineTo(.49, .43),
      _line(const Color(0xFFBDA492), .035));
  canvas.drawPath(
      Path()
        ..moveTo(-.24, -.43)
        ..quadraticBezierTo(0, -.51, .24, -.43)
        ..lineTo(.32, -.18)
        ..quadraticBezierTo(.14, -.21, .16, .04)
        ..quadraticBezierTo(.04, .17, -.01, -.02)
        ..lineTo(-.06, -.2)
        ..quadraticBezierTo(-.16, -.06, -.24, -.15)
        ..close(),
      _shade(const Color(0xFFFFB36E), const Color(0xFFE57859)));
  canvas.drawOval(const Rect.fromLTRB(-.28, -.55, .28, -.31),
      _fill(const Color(0xFF6A3F47)));
  canvas.drawOval(
      const Rect.fromLTRB(-.21, -.48, .21, -.33),
      _shade(
          Color.lerp(const Color(0xFFFFE3A3), const Color(0xFFFFFFDC),
              .2 * charge + .7 * fire)!,
          Color.lerp(const Color(0xFFF49160), const Color(0xFFFFD585), fire)!));
  if (fire > 0) {
    for (final puff in [
      const Offset(-.15, -.65),
      const Offset(.03, -.75),
      const Offset(.16, -.59)
    ]) {
      canvas.drawCircle(puff, .05 + .04 * fire,
          _fill(const Color(0xFFD8D9BB).withValues(alpha: .55 * fire)));
    }
  }
  for (final x in [-.2, .2]) {
    canvas.save();
    canvas.translate(x, .22);
    canvas.scale(1, _blink(time));
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: .2, height: .22),
        _fill(const Color(0xFFF4DFBE)));
    canvas.drawCircle(
        Offset(math.sin(time * math.pi / 4) * .035, .025), .053, _fill(_ink));
    canvas.restore();
  }
  canvas.drawOval(
      const Rect.fromLTRB(-.13, .4, .13, .62), _fill(const Color(0xFF553C48)));
  canvas.drawOval(
      const Rect.fromLTRB(-.07, .48, .08, .6), _fill(const Color(0xFFEF9A6E)));
}

void drawVolcanoPlayer(Canvas canvas) {
  final wings = Path()
    ..moveTo(0, -.04)
    ..lineTo(-.91, -.3)
    ..quadraticBezierTo(-.71, .08, -.74, .39)
    ..quadraticBezierTo(-.3, .17, 0, .5)
    ..quadraticBezierTo(.3, .17, .74, .39)
    ..quadraticBezierTo(.71, .08, .91, -.3)
    ..close();
  canvas.drawPath(
      wings, _shade(const Color(0xFFAFE3C8), const Color(0xFF629F98)));
  canvas.drawLine(const Offset(-.73, -.18), const Offset(-.18, .17),
      _line(const Color(0xFFDAF2D7), .04));
  canvas.drawLine(const Offset(.73, -.18), const Offset(.18, .17),
      _line(const Color(0xFFDAF2D7), .04));
  canvas.drawPath(
      Path()
        ..moveTo(-.14, -.33)
        ..lineTo(-.33, -.83)
        ..lineTo(.13, -.49)
        ..lineTo(.22, .37)
        ..lineTo(0, .81)
        ..lineTo(-.17, .36)
        ..close(),
      _shade(const Color(0xFFC3E9C8), const Color(0xFF84BDAB)));
  canvas.drawOval(const Rect.fromLTRB(-.22, -.62, .28, -.18),
      _fill(const Color(0xFFB8E2BE)));
  canvas.drawPath(
      Path()
        ..moveTo(.17, -.49)
        ..lineTo(.73, -.3)
        ..lineTo(.2, -.2)
        ..close(),
      _fill(const Color(0xFFEACA8B)));
  canvas.drawCircle(const Offset(.055, -.44), .063, _fill(_ink));
}

void drawVolcanoPickup(Canvas canvas) {
  final egg = Path()
    ..moveTo(0, -.89)
    ..cubicTo(.33, -.89, .71, -.2, .67, .33)
    ..cubicTo(.61, 1.03, -.61, 1.03, -.67, .33)
    ..cubicTo(-.71, -.2, -.33, -.89, 0, -.89)
    ..close();
  canvas.drawPath(
      egg, _shade(const Color(0xFFFFEBC1), const Color(0xFFD5BE8B)));
  for (final spot in [
    (position: const Offset(-.13, -.43), radius: .14),
    (position: const Offset(.29, -.03), radius: .18),
    (position: const Offset(-.3, .2), radius: .15),
    (position: const Offset(.04, .51), radius: .13),
  ]) {
    canvas.drawCircle(
        spot.position, spot.radius, _fill(const Color(0xFF83AC8D)));
  }
}

void drawVolcanoHazard(Canvas canvas, {double time = 0}) {
  canvas.save();
  canvas.rotate(time * math.pi / 4);
  canvas.scale(1.12);
  final rock = Path()
    ..moveTo(-.43, -.57)
    ..lineTo(.15, -.74)
    ..lineTo(.63, -.32)
    ..lineTo(.72, .24)
    ..lineTo(.24, .7)
    ..lineTo(-.44, .56)
    ..lineTo(-.73, .05)
    ..close();
  canvas.drawPath(rock, _line(const Color(0xFFF49A63), .08));
  canvas.drawPath(
      rock, _shade(const Color(0xFF79584D), const Color(0xFF453D41)));
  canvas.drawPath(
      Path()
        ..moveTo(.15, -.7)
        ..lineTo(-.02, -.19)
        ..lineTo(.3, .11)
        ..lineTo(.22, .63)
        ..moveTo(-.02, -.19)
        ..lineTo(-.57, -.3)
        ..moveTo(.3, .11)
        ..lineTo(.65, .23),
      _line(const Color(0xFFFFCF88), .12));
  canvas.restore();
}
