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

void drawHauntedCore(Canvas canvas) {
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
    canvas.drawPath(
        Path()
          ..moveTo(.18, -.13)
          ..lineTo(.36, -.22)
          ..lineTo(.4, -.015)
          ..close(),
        _fill(const Color(0xFFFFE5A0)));
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
  canvas.drawPath(
      Path()
        ..moveTo(-.28, .39)
        ..quadraticBezierTo(-.02, .58, .29, .38)
        ..quadraticBezierTo(.08, .48, -.28, .39),
      _line(const Color(0xFFFFD890), .04));
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

void drawHauntedHazard(Canvas canvas) {
  canvas.save();
  canvas.scale(.9);
  final bat = Path()
    ..moveTo(-.15, -.18)
    ..lineTo(-.73, -.48)
    ..quadraticBezierTo(-.68, -.03, -.78, .19)
    ..quadraticBezierTo(-.46, .02, -.43, .39)
    ..quadraticBezierTo(-.2, .19, 0, .54)
    ..quadraticBezierTo(.2, .19, .43, .39)
    ..quadraticBezierTo(.46, .02, .78, .19)
    ..quadraticBezierTo(.68, -.03, .73, -.48)
    ..lineTo(.15, -.18)
    ..lineTo(.12, -.48)
    ..lineTo(0, -.33)
    ..lineTo(-.12, -.48)
    ..close();
  canvas.drawPath(bat, _fill(const Color(0xFF4D365B)));
  for (final x in [-.09, .09]) {
    canvas.drawCircle(Offset(x, -.1), .055, _fill(const Color(0xFFFFDCAF)));
  }
  canvas.restore();
}

void drawJunkyardCore(Canvas canvas) {
  canvas.drawLine(const Offset(0, -.42), const Offset(0, -.82),
      _line(const Color(0xFF9AB3B4), .075));
  canvas.drawCircle(const Offset(0, -.84), .11,
      _shade(const Color(0xFFFFD693), const Color(0xFFE4A66E)));
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
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, -.08), width: .2, height: .25),
            const Radius.circular(.06)),
        _fill(const Color(0xFFFFD994)));
    canvas.drawLine(Offset(x - .06, -.13), Offset(x + .035, -.13),
        _line(const Color(0xFFFFF3CF), .035));
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

void drawJunkyardHazard(Canvas canvas) {
  canvas.drawCircle(Offset.zero, .76, _fill(const Color(0xFF79374F)));
  canvas.drawPath(
      Path()
        ..moveTo(.12, -.77)
        ..lineTo(-.51, .07)
        ..lineTo(-.04, .06)
        ..lineTo(-.15, .76)
        ..lineTo(.54, -.18)
        ..lineTo(.08, -.13)
        ..close(),
      _shade(const Color(0xFFFFE7AB), const Color(0xFFFFB483)));
}

void drawVolcanoCore(Canvas canvas) {
  canvas.drawCircle(
      const Offset(.11, -.7), .13, _fill(const Color(0xFF657380)));
  canvas.drawCircle(
      const Offset(-.12, -.82), .105, _fill(const Color(0xFF84918E)));
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
  canvas.drawOval(const Rect.fromLTRB(-.21, -.48, .21, -.33),
      _shade(const Color(0xFFFFE3A3), const Color(0xFFF49160)));
  for (final x in [-.2, .2]) {
    canvas.drawOval(
        Rect.fromCenter(center: Offset(x, .22), width: .16, height: .22),
        _fill(const Color(0xFFF4DFBE)));
    canvas.drawCircle(Offset(x + .02, .25), .053, _fill(_ink));
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

void drawVolcanoHazard(Canvas canvas) {
  final rock = Path()
    ..moveTo(-.43, -.57)
    ..lineTo(.15, -.74)
    ..lineTo(.63, -.32)
    ..lineTo(.72, .24)
    ..lineTo(.24, .7)
    ..lineTo(-.44, .56)
    ..lineTo(-.73, .05)
    ..close();
  canvas.drawPath(
      rock, _shade(const Color(0xFF805160), const Color(0xFF492F43)));
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
      _line(const Color(0xFFFFBE87), .11));
}
