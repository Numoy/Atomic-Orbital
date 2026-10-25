import 'dart:math' as math;

import 'package:atomic_orbital/constants/game_constants.dart';
import 'package:atomic_orbital/game/adventure_world_art.dart';
import 'package:atomic_orbital/game/animal_world_art.dart';
import 'package:atomic_orbital/game/earth_art.dart';
import 'package:atomic_orbital/game/extra_world_art.dart';
import 'package:flutter/material.dart';

enum GameSkin {
  classic('classic', 'Classic', 'The original atomic arena.', 0),
  cowAbduction('cow_abduction', 'Cow Abduction',
      'Fly the MOO-1. Beam up cows. Dodge Earth’s defenses.', 150),
  deepBlue(
      'deep_blue',
      'Deep Blue',
      'Pilot the Bathyscout. Collect treasure chests. Dodge the kraken’s ink.',
      150),
  spiderWeb('spider_web', 'Web Escape',
      'Be a tiny fly. Snatch sugar cubes. Slip past the spider’s webs.', 150),
  dragonHoard('dragon_hoard', 'Dragon’s Hoard',
      'Guard your little knight. Gather gems. Dodge dragon fire.', 150),
  sunflower('sunflower', 'Pollen Patrol',
      'Fly a busy bee. Gather pollen. Dodge the sunflower’s seeds.', 150),
  frostBite('frost_bite', 'Frost Bite',
      'Guide a penguin. Catch fish. Dodge the snow monster’s ice.', 150),
  hauntedHarvest('haunted_harvest', 'Haunted Harvest',
      'Float a little ghost. Collect candy. Dodge the pumpkin’s bats.', 150),
  junkyardDash('junkyard_dash', 'Junkyard Dash',
      'Pilot a repair drone. Collect bolts. Dodge the robot’s sparks.', 150),
  volcanoHop('volcano_hop', 'Volcano Hop',
      'Fly a pterosaur. Rescue eggs. Dodge flying lava.', 150),
  cheeseChase('cheese_chase', 'Cheese Chase',
      'Scurry as a mouse. Snatch cheese. Dodge the cat’s yarn.', 150),
  jungleJam('jungle_jam', 'Jungle Jam',
      'Fly a toucan. Gather bananas. Dodge the monkey’s coconuts.', 150);

  const GameSkin(this.id, this.name, this.description, this.price);
  final String id;
  final String name;
  final String description;
  final int price;

  Color get accent => switch (this) {
        classic => const Color(0xFFCFDCE6),
        cowAbduction => const Color(0xFFA8E7C6),
        deepBlue => const Color(0xFF78DDE0),
        spiderWeb => const Color(0xFFC7AAF2),
        dragonHoard => const Color(0xFFFFB77D),
        sunflower => const Color(0xFFFFDC77),
        frostBite => const Color(0xFFAADFF8),
        hauntedHarvest => const Color(0xFFFFBF83),
        junkyardDash => const Color(0xFF8FE3D3),
        volcanoHop => const Color(0xFFFFA289),
        cheeseChase => const Color(0xFFFFDB86),
        jungleJam => const Color(0xFFB8DD86),
      };

  static GameSkin byId(String? id) =>
      values.firstWhere((skin) => skin.id == id, orElse: () => classic);

  void drawCore(Canvas canvas, Offset center, double radius) {
    if (radius <= 0) return;
    if (this == classic) {
      canvas.drawCircle(center, radius, _fill(GameConstants.atomColor));
      return;
    }
    final draw = switch (this) {
      deepBlue => _drawKraken,
      spiderWeb => _drawSpiderCore,
      dragonHoard => drawDragonCore,
      sunflower => drawSunflowerCore,
      frostBite => drawFrostCore,
      hauntedHarvest => drawHauntedCore,
      junkyardDash => drawJunkyardCore,
      volcanoHop => drawVolcanoCore,
      cheeseChase => drawCheeseCore,
      jungleJam => drawJungleCore,
      _ => null,
    };
    if (draw != null) {
      canvas.drawCircle(center, radius, _fill(GameConstants.backgroundColor));
      _inside(canvas, center, radius, () => draw(canvas));
      canvas.drawCircle(center, radius * .985,
          _line(accent.withValues(alpha: .3), radius * .025));
      return;
    }
    _inside(canvas, center, radius, () {
      _sphere(canvas,
          const [Color(0xFF5BB6DF), Color(0xFF276A9C), Color(0xFF102F52)]);
      if (this == cowAbduction) {
        final land = Paint()
          ..shader = const LinearGradient(
            begin: Alignment(-.8, -.7),
            end: Alignment(.8, .8),
            colors: [Color(0xFFB1DDAC), Color(0xFF67AD91), Color(0xFF34766F)],
          ).createShader(_disc);
        drawEarthLand(canvas, land);
        final clouds = Path()
          ..moveTo(-.9, -.14)
          ..cubicTo(-.74, -.29, -.51, -.3, -.36, -.21)
          ..cubicTo(-.56, -.23, -.64, -.12, -.84, -.1)
          ..close()
          ..moveTo(.08, -.74)
          ..cubicTo(.31, -.87, .55, -.81, .73, -.61)
          ..cubicTo(.5, -.73, .34, -.73, .12, -.67)
          ..close()
          ..moveTo(-.18, .56)
          ..cubicTo(.07, .45, .24, .48, .46, .63)
          ..cubicTo(.2, .56, .06, .61, -.12, .62)
          ..close();
        canvas.drawPath(clouds, _fill(Colors.white.withValues(alpha: .48)));
      }
      canvas.drawCircle(
          Offset.zero,
          1,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment(-.8, -.7),
              end: Alignment(.85, .75),
              colors: [
                Color(0x10FFFFFF),
                Colors.transparent,
                Color(0xA5071930)
              ],
              stops: [0, .37, 1],
            ).createShader(_disc));
      canvas.drawCircle(
          Offset.zero,
          1,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(-.25, -.25),
              radius: .9,
              colors: [Colors.transparent, Color(0x550C2136)],
              stops: [.58, 1],
            ).createShader(_disc));
      canvas.drawCircle(Offset.zero, .985,
          _line(const Color(0xFF102B43).withValues(alpha: .3), .025));
      canvas.drawArc(
          const Rect.fromLTRB(-.985, -.985, .985, .985),
          math.pi * .94,
          math.pi * .69,
          false,
          _line(const Color(0xFFB3E9E8).withValues(alpha: .5), .022));
    });
  }

  void drawPlayer(Canvas canvas, Offset center, double radius) {
    if (radius <= 0) return;
    if (this == classic) {
      canvas.drawCircle(center, radius, _fill(GameConstants.playerColor));
      return;
    }
    final draw = switch (this) {
      spiderWeb => _drawSpiderPlayer,
      dragonHoard => drawDragonPlayer,
      sunflower => drawSunflowerPlayer,
      frostBite => drawFrostPlayer,
      hauntedHarvest => drawHauntedPlayer,
      junkyardDash => drawJunkyardPlayer,
      volcanoHop => drawVolcanoPlayer,
      cheeseChase => drawCheesePlayer,
      jungleJam => drawJunglePlayer,
      _ => null,
    };
    if (draw != null) {
      _inside(canvas, center, radius, () => draw(canvas));
      return;
    }
    _inside(canvas, center, radius, () {
      if (this == cowAbduction) {
        canvas.drawPath(
            Path()
              ..moveTo(-.87, .14)
              ..cubicTo(-.61, .94, .58, .94, .87, .14)
              ..close(),
            Paint()
              ..shader = const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF689D9E),
                  Color(0xFF305865),
                  Color(0xFF183342)
                ],
              ).createShader(const Rect.fromLTRB(-.9, .1, .9, .7)));
        for (final x in [-.52, .52]) {
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromCenter(
                      center: Offset(x, .49), width: .25, height: .38),
                  const Radius.circular(.09)),
              _fill(const Color(0xFFD17F56)));
          canvas.drawOval(
              Rect.fromCenter(center: Offset(x, .64), width: .19, height: .11),
              _fill(const Color(0xFFFFDA9D)));
        }
        canvas.drawOval(
            const Rect.fromLTRB(-.51, -.78, .51, .2),
            Paint()
              ..shader = const RadialGradient(
                center: Alignment(-.45, -.55),
                radius: 1.25,
                colors: [
                  Color(0xFFD8F9E8),
                  Color(0xFF77C5B4),
                  Color(0xFF2E7380)
                ],
              ).createShader(const Rect.fromLTRB(-.51, -.78, .51, .2)));
        canvas.drawPath(
            Path()
              ..moveTo(-.3, .04)
              ..quadraticBezierTo(-.3, -.17, 0, -.17)
              ..quadraticBezierTo(.3, -.17, .3, .04)
              ..close(),
            _fill(const Color(0xFF47998B)));
        canvas.drawPath(
            Path()
              ..moveTo(0, -.62)
              ..cubicTo(-.29, -.65, -.34, -.35, -.05, -.13)
              ..quadraticBezierTo(0, -.08, .05, -.13)
              ..cubicTo(.34, -.35, .29, -.65, 0, -.62)
              ..close(),
            Paint()
              ..shader = const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFD5E8A8), Color(0xFF73B894)])
                  .createShader(const Rect.fromLTRB(-.3, -.65, .3, -.1)));
        canvas.drawPath(
            Path()
              ..moveTo(-.2, -.43)
              ..quadraticBezierTo(-.07, -.46, -.045, -.26)
              ..quadraticBezierTo(-.19, -.26, -.2, -.43)
              ..close()
              ..moveTo(.2, -.43)
              ..quadraticBezierTo(.07, -.46, .045, -.26)
              ..quadraticBezierTo(.19, -.26, .2, -.43)
              ..close(),
            _fill(const Color(0xFF173D47)));
        canvas.drawArc(
            const Rect.fromLTRB(-.37, -.64, .34, .03),
            math.pi * 1.12,
            math.pi * .5,
            false,
            _line(Colors.white.withValues(alpha: .55), .055));
        final hull = Path()
          ..moveTo(-.97, .12)
          ..lineTo(-.67, -.08)
          ..quadraticBezierTo(-.36, -.2, .02, -.12)
          ..lineTo(.69, -.04)
          ..lineTo(.97, .14)
          ..lineTo(.76, .39)
          ..quadraticBezierTo(.06, .56, -.76, .36)
          ..close();
        canvas.drawPath(
            hull,
            Paint()
              ..shader = const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF9E8),
                    Color(0xFFDEE9D9),
                    Color(0xFF83AAA5)
                  ],
                  stops: [
                    0,
                    .5,
                    1
                  ]).createShader(const Rect.fromLTRB(-1, -.2, 1, .5)));
        canvas.save();
        canvas.clipPath(hull);
        canvas.drawPath(
            Path()
              ..moveTo(-.81, -.05)
              ..cubicTo(-.45, -.21, -.27, .03, -.47, .19)
              ..quadraticBezierTo(-.68, .31, -.86, .19)
              ..close()
              ..moveTo(.43, -.1)
              ..quadraticBezierTo(.23, .16, .51, .23)
              ..quadraticBezierTo(.75, .23, .83, .03)
              ..close(),
            _fill(const Color(0xFF284C54)));
        canvas.restore();
        canvas.drawPath(hull, _line(const Color(0xFFBCD9CD), .025));
        canvas.drawLine(const Offset(-.76, .3), const Offset(.76, .32),
            _line(const Color(0xFFD17F56), .055));
        canvas.drawPath(
            Path()
              ..moveTo(-.2, .4)
              ..lineTo(0, .32)
              ..lineTo(.22, .41)
              ..lineTo(0, .51)
              ..close(),
            _fill(const Color(0xFFB9F5CE)));
        for (final x in [-.75, .73]) {
          canvas.drawCircle(
              Offset(x, .16), .055, _fill(const Color(0xFFFFDF9D)));
        }
      } else {
        canvas.drawLine(const Offset(-.72, .045), const Offset(-.96, .045),
            _line(const Color(0xFF92B9BA), .09));
        canvas.drawOval(const Rect.fromLTRB(-.99, -.21, -.9, .29),
            _fill(const Color(0xFF72B8B6)));
        canvas.drawOval(const Rect.fromLTRB(-.99, -.29, -.64, .36),
            _line(const Color(0xFF95C7C1), .045));
        canvas.drawPath(
            Path()
              ..moveTo(-.62, -.1)
              ..lineTo(-.78, -.34)
              ..lineTo(-.85, -.28)
              ..lineTo(-.75, .06)
              ..close(),
            _fill(const Color(0xFFD6A75B)));
        canvas.drawLine(const Offset(-.12, -.31), const Offset(-.12, -.7),
            _line(const Color(0xFF9AB9BE), .13));
        canvas.drawLine(const Offset(-.12, -.7), const Offset(.16, -.7),
            _line(const Color(0xFFB2CFD0), .13));
        canvas.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTRB(-.35, -.48, .15, -.16),
                const Radius.circular(.08)),
            _fill(const Color(0xFFEAB96A)));
        final hull = Path()
          ..moveTo(-.75, -.27)
          ..lineTo(.26, -.34)
          ..cubicTo(.91, -.4, 1, .19, .55, .4)
          ..lineTo(-.62, .39)
          ..quadraticBezierTo(-.89, .16, -.75, -.27)
          ..close();
        canvas.drawPath(
            hull,
            Paint()
              ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFD78B),
                    Color(0xFFE89A52),
                    Color(0xFFAC573C)
                  ]).createShader(const Rect.fromLTRB(-.85, -.35, .9, .45)));
        canvas.save();
        canvas.clipPath(hull);
        canvas.drawPath(
            Path()
              ..moveTo(.24, -.39)
              ..lineTo(.08, .43)
              ..lineTo(.37, .45)
              ..lineTo(.57, -.39)
              ..close(),
            _fill(const Color(0xFFFFEED0)));
        canvas.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTRB(-.63, -.1, -.23, .08),
                const Radius.circular(.06)),
            _fill(const Color(0xFF315B65)));
        canvas.restore();
        canvas.drawArc(
            const Rect.fromLTRB(-.74, -.23, .75, .3),
            math.pi * 1.1,
            math.pi * .72,
            false,
            _line(const Color(0xFFFFEAC0).withValues(alpha: .75), .04));
        canvas.drawCircle(
            const Offset(.42, .02), .28, _fill(const Color(0xFF5B7E87)));
        canvas.drawCircle(
            const Offset(.42, .02),
            .22,
            Paint()
              ..shader = const RadialGradient(
                center: Alignment(-.4, -.5),
                radius: 1.1,
                colors: [
                  Color(0xFFBAEDE5),
                  Color(0xFF3C8795),
                  Color(0xFF21465D)
                ],
              ).createShader(const Rect.fromLTRB(.2, -.2, .64, .24)));
        canvas.drawCircle(const Offset(.35, -.06), .055,
            _fill(Colors.white.withValues(alpha: .7)));
        canvas.drawLine(const Offset(-.45, .45), const Offset(.3, .45),
            _line(const Color(0xFF8FC1BD), .08));
        canvas.drawPath(
            Path()
              ..moveTo(.54, .36)
              ..lineTo(.57, .57)
              ..lineTo(.73, .64)
              ..moveTo(.57, .57)
              ..lineTo(.43, .69),
            _line(const Color(0xFF9ACDC4), .075));
        canvas.drawCircle(
            const Offset(.57, .57), .065, _fill(const Color(0xFF315B65)));
        canvas.drawCircle(
            const Offset(.78, .22), .055, _fill(const Color(0xFFEBF9DF)));
      }
    });
  }

  void drawPickup(Canvas canvas, Offset center, double radius) {
    if (radius <= 0) return;
    if (this == classic) {
      canvas.drawPath(
          Path()
            ..moveTo(center.dx, center.dy - radius * .94)
            ..lineTo(center.dx + radius * .94, center.dy)
            ..lineTo(center.dx, center.dy + radius * .94)
            ..lineTo(center.dx - radius * .94, center.dy)
            ..close(),
          _line(GameConstants.energyColor, radius * .08));
      return;
    }
    final draw = switch (this) {
      spiderWeb => _drawSpiderPickup,
      dragonHoard => drawDragonPickup,
      sunflower => drawSunflowerPickup,
      frostBite => drawFrostPickup,
      hauntedHarvest => drawHauntedPickup,
      junkyardDash => drawJunkyardPickup,
      volcanoHop => drawVolcanoPickup,
      cheeseChase => drawCheesePickup,
      jungleJam => drawJunglePickup,
      _ => null,
    };
    if (draw != null) {
      _inside(canvas, center, radius, () => draw(canvas));
      return;
    }
    _inside(canvas, center, radius, () {
      if (this == cowAbduction) {
        canvas.drawPath(
            Path()
              ..moveTo(-.67, -.14)
              ..quadraticBezierTo(-.91, -.32, -.78, -.57),
            _line(const Color(0xFFE5ECE8), .075));
        canvas.drawOval(const Rect.fromLTRB(-.88, -.65, -.72, -.48),
            _fill(const Color(0xFF344D57)));
        for (final leg in [
          (x: -.31, far: true),
          (x: .29, far: true),
          (x: -.55, far: false),
          (x: .08, far: false),
        ]) {
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromLTWH(leg.x, .21, .105, leg.far ? .37 : .49),
                  const Radius.circular(.04)),
              _fill(
                  leg.far ? const Color(0xFFB5CAC3) : const Color(0xFFE9EFDF)));
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromLTWH(leg.x, leg.far ? .52 : .61, .105, .12),
                  const Radius.circular(.025)),
              _fill(const Color(0xFF344D57)));
        }
        final body = Path()
          ..moveTo(-.71, -.22)
          ..cubicTo(-.7, -.43, -.45, -.46, -.2, -.4)
          ..cubicTo(.07, -.42, .33, -.33, .41, -.15)
          ..lineTo(.35, .2)
          ..cubicTo(.22, .43, -.47, .43, -.65, .27)
          ..quadraticBezierTo(-.78, .13, -.71, -.22)
          ..close();
        final coat = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFEF2), Color(0xFFE3EADF), Color(0xFFA6BFB7)],
            stops: [0, .5, 1],
          ).createShader(const Rect.fromLTRB(-.8, -.6, .9, .75));
        canvas.drawPath(body, coat);
        canvas.save();
        canvas.clipPath(body);
        canvas.drawPath(
            Path()
              ..moveTo(-.62, -.38)
              ..cubicTo(-.47, -.48, -.2, -.37, -.21, -.19)
              ..cubicTo(-.2, -.08, -.37, -.1, -.41, .02)
              ..cubicTo(-.55, .07, -.65, -.15, -.62, -.38)
              ..close()
              ..moveTo(.01, -.01)
              ..cubicTo(.2, -.08, .32, .12, .2, .3)
              ..cubicTo(.05, .43, -.13, .17, .01, -.01)
              ..close(),
            Paint()
              ..shader = const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4E6870), Color(0xFF263D49)],
              ).createShader(_disc));
        canvas.restore();
        canvas.drawPath(
            Path()
              ..moveTo(-.59, -.32)
              ..cubicTo(-.4, -.43, .1, -.34, .31, -.15),
            _line(const Color(0xFFDAF2DD).withValues(alpha: .55), .035));
        canvas.drawOval(const Rect.fromLTRB(.23, -.47, .53, -.31),
            _fill(const Color(0xFF738D80)));
        canvas.drawOval(const Rect.fromLTRB(.63, -.46, .93, -.30),
            _fill(const Color(0xFF738D80)));
        canvas.drawOval(const Rect.fromLTRB(.27, -.43, .47, -.35),
            _fill(const Color(0xFFE7C4B4)));
        canvas.drawLine(const Offset(.43, -.39), const Offset(.42, -.59),
            _line(const Color(0xFFE1D5B4), .065));
        canvas.drawLine(const Offset(.72, -.39), const Offset(.74, -.58),
            _line(const Color(0xFFE1D5B4), .065));
        canvas.drawPath(
            Path()
              ..moveTo(.22, -.1)
              ..cubicTo(.16, -.35, .43, -.57, .65, -.4)
              ..quadraticBezierTo(.78, -.32, .84, -.06)
              ..lineTo(.91, .08)
              ..quadraticBezierTo(.79, .32, .56, .21)
              ..quadraticBezierTo(.35, .22, .22, -.1)
              ..close(),
            coat);
        canvas.drawPath(
            Path()
              ..moveTo(.33, -.28)
              ..quadraticBezierTo(.36, -.48, .55, -.36)
              ..quadraticBezierTo(.59, -.22, .44, -.15)
              ..close(),
            _fill(const Color(0xFF3C5660)));
        canvas.drawOval(
            const Rect.fromLTRB(.55, -.01, .96, .26),
            Paint()
              ..shader = const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF0C3B2), Color(0xFFC18C87)])
                  .createShader(const Rect.fromLTRB(.55, -.01, .96, .26)));
        canvas.drawCircle(
            const Offset(.63, -.2), .042, _fill(const Color(0xFF263E48)));
        for (final x in [.69, .86]) {
          canvas.drawOval(
              Rect.fromCenter(
                  center: Offset(x, .11), width: .047, height: .065),
              _fill(const Color(0xFF8C6B68)));
        }
      } else {
        final gold = _line(const Color(0xFFF4D383), .065);
        final side = Path()
          ..moveTo(.48, -.06)
          ..lineTo(.84, -.25)
          ..lineTo(.84, .43)
          ..lineTo(.48, .65)
          ..close();
        canvas.drawPath(side, _fill(const Color(0xFF795036)));
        canvas.drawPath(side, gold);
        final lidSide = Path()
          ..moveTo(.48, -.06)
          ..lineTo(.84, -.25)
          ..lineTo(.84, -.48)
          ..cubicTo(.8, -.76, .53, -.81, .22, -.67)
          ..lineTo(.48, -.3)
          ..close();
        canvas.drawPath(lidSide, _fill(const Color(0xFFB77A47)));
        canvas.drawPath(lidSide, gold);
        final front = RRect.fromRectAndRadius(
            const Rect.fromLTRB(-.76, -.08, .48, .65),
            const Radius.circular(.035));
        canvas.drawRRect(
            front,
            Paint()
              ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFBD824B), Color(0xFF865331)],
              ).createShader(_disc));
        canvas.drawRRect(front, gold);
        final lid = Path()
          ..moveTo(-.76, -.06)
          ..lineTo(-.76, -.3)
          ..cubicTo(-.76, -.75, .48, -.75, .48, -.3)
          ..lineTo(.48, -.06)
          ..close();
        canvas.drawPath(
            lid,
            Paint()
              ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE8B879), Color(0xFFA3693F)],
              ).createShader(_disc));
        canvas.drawPath(lid, gold);
        canvas.drawLine(const Offset(-.72, .35), const Offset(.44, .35),
            _line(const Color(0xFF6B422D), .035));
        for (final x in [-.54, .26]) {
          canvas.drawLine(Offset(x, -.46), Offset(x, .61),
              _line(const Color(0xFFF4D383), .11));
        }
        canvas.drawLine(const Offset(-.73, -.06), const Offset(.45, -.06),
            _line(const Color(0xFF5B3C2C), .065));
        canvas.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTRB(-.28, -.14, -.02, .18),
                const Radius.circular(.035)),
            _fill(const Color(0xFFFFE5A0)));
        canvas.drawCircle(
            const Offset(-.15, -.005), .046, _fill(const Color(0xFF5B3C2C)));
        canvas.drawLine(const Offset(-.15, .015), const Offset(-.15, .09),
            _line(const Color(0xFF5B3C2C), .04));
      }
    });
  }

  void drawHazard(Canvas canvas, Offset center, double radius) {
    if (radius <= 0) return;
    canvas.drawCircle(center, radius, _fill(GameConstants.photonColor));
    if (this == classic) return;
    final draw = switch (this) {
      deepBlue => _drawInk,
      spiderWeb => _drawWeb,
      dragonHoard => drawDragonHazard,
      sunflower => drawSunflowerHazard,
      frostBite => drawFrostHazard,
      hauntedHarvest => drawHauntedHazard,
      junkyardDash => drawJunkyardHazard,
      volcanoHop => drawVolcanoHazard,
      cheeseChase => drawCheeseHazard,
      jungleJam => drawJungleHazard,
      _ => null,
    };
    if (draw != null) {
      _inside(canvas, center, radius, () => draw(canvas));
      return;
    }
    _inside(canvas, center, radius, () {
      canvas.drawCircle(Offset.zero, .64, _fill(const Color(0xFFA9324E)));
      canvas.drawCircle(
          const Offset(-.13, -.12), .35, _fill(const Color(0xFFFFB7BE)));
      canvas.drawCircle(
          const Offset(-.2, -.2), .13, _fill(const Color(0xFFFFE0DC)));
    });
  }
}

void _drawKraken(Canvas canvas) {
  final arms = [
    Path()
      ..moveTo(-.37, -.04)
      ..cubicTo(-.82, -.2, -.57, -.69, -.87, -.4)
      ..cubicTo(-1.02, -.11, -.85, .15, -.61, .24),
    Path()
      ..moveTo(-.4, .1)
      ..cubicTo(-.85, .1, -.95, .5, -.7, .58)
      ..quadraticBezierTo(-.51, .63, -.56, .43),
    Path()
      ..moveTo(-.29, .27)
      ..cubicTo(-.5, .5, -.62, .88, -.3, .85)
      ..quadraticBezierTo(-.12, .81, -.24, .65),
    Path()
      ..moveTo(-.12, .3)
      ..cubicTo(-.14, .54, .04, .76, -.04, .95),
  ];
  for (final side in [-1.0, 1.0]) {
    canvas.save();
    canvas.scale(side, 1);
    for (var i = 0; i < arms.length; i++) {
      canvas.drawPath(arms[i], _line(const Color(0xFF164A5E), .23));
      canvas.drawPath(
          arms[i],
          _line(i.isEven ? const Color(0xFF55C4BD) : const Color(0xFF319B9F),
              .16));
    }
    for (final sucker in [
      const Offset(-.83, -.13),
      const Offset(-.73, .02),
      const Offset(-.79, .39),
      const Offset(-.67, .49),
      const Offset(-.42, .57),
      const Offset(-.38, .73),
    ]) {
      canvas.drawCircle(sucker, .034, _fill(const Color(0xFFF2B3BD)));
    }
    canvas.restore();
  }
  final mantle = Path()
    ..moveTo(0, -.91)
    ..cubicTo(-.49, -.91, -.58, -.42, -.48, -.07)
    ..quadraticBezierTo(-.43, .4, 0, .42)
    ..quadraticBezierTo(.43, .4, .48, -.07)
    ..cubicTo(.58, -.42, .49, -.91, 0, -.91)
    ..close();
  canvas.drawPath(
      mantle,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF92E2CB), Color(0xFF46AFAE), Color(0xFF216877)],
        ).createShader(_disc));
  canvas.drawPath(
      Path()
        ..moveTo(-.31, -.53)
        ..quadraticBezierTo(-.25, -.74, -.08, -.76),
      _line(const Color(0xFFBFF2DC), .055));
  for (final x in [-.21, .21]) {
    canvas.drawOval(
        Rect.fromCenter(center: Offset(x, -.02), width: .29, height: .32),
        _fill(const Color(0xFFFFEDC3)));
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(x * .82, .015), width: .095, height: .17),
        _fill(const Color(0xFF102D42)));
    canvas.drawCircle(Offset(x * .82 - .02, -.025), .023, _fill(Colors.white));
  }
  canvas.drawPath(
      Path()
        ..moveTo(-.37, -.2)
        ..lineTo(-.08, -.12)
        ..moveTo(.37, -.2)
        ..lineTo(.08, -.12),
      _line(const Color(0xFF23717B), .065));
  canvas.drawOval(
      const Rect.fromLTRB(-.07, .22, .07, .35), _fill(const Color(0xFF173C52)));
}

void _drawInk(Canvas canvas) {
  canvas.drawCircle(Offset.zero, .88, _fill(const Color(0xFF51426F)));
  for (final spot in [
    const Offset(-.4, .31),
    const Offset(.43, .16),
    const Offset(.1, .47),
  ]) {
    canvas.drawCircle(spot, .25, _fill(const Color(0xFFB681CB)));
  }
  final drop = Path()
    ..moveTo(0, -.79)
    ..cubicTo(-.11, -.45, -.5, -.24, -.46, .11)
    ..cubicTo(-.44, .7, .49, .68, .46, .11)
    ..cubicTo(.47, -.24, .1, -.45, 0, -.79)
    ..close();
  canvas.drawPath(drop, _fill(const Color(0xFFE6A5DA)));
  canvas.drawOval(
      const Rect.fromLTRB(-.28, -.1, -.1, .19), _fill(const Color(0xFFFFD4E9)));
}

void _drawSpiderCore(Canvas canvas) {
  for (final side in [-1.0, 1.0]) {
    canvas.save();
    canvas.scale(side, 1);
    final legs = [
      Path()
        ..moveTo(.28, -.29)
        ..lineTo(.62, -.58)
        ..lineTo(.64, -.73),
      Path()
        ..moveTo(.37, -.16)
        ..lineTo(.83, -.3)
        ..lineTo(.93, -.1),
      Path()
        ..moveTo(.36, .08)
        ..lineTo(.83, .2)
        ..lineTo(.86, .45),
      Path()
        ..moveTo(.28, .28)
        ..lineTo(.59, .52)
        ..lineTo(.46, .81),
    ];
    for (final leg in legs) {
      canvas.drawPath(leg, _line(const Color(0xFF322C43), .15));
      canvas.drawPath(leg, _line(const Color(0xFFA28ACB), .085));
    }
    canvas.restore();
  }
  canvas.drawOval(
      const Rect.fromLTRB(-.49, -.83, .49, .17),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB59ADD), Color(0xFF786294), Color(0xFF413650)],
        ).createShader(_disc));
  canvas.drawPath(
      Path()
        ..moveTo(-.16, -.53)
        ..lineTo(.16, -.53)
        ..lineTo(0, -.34)
        ..lineTo(.16, -.16)
        ..lineTo(-.16, -.16)
        ..lineTo(0, -.34)
        ..close(),
      _fill(const Color(0xFFF3AD93)));
  canvas.drawOval(
      const Rect.fromLTRB(-.4, -.13, .4, .55),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9B80BD), Color(0xFF4E4164)],
        ).createShader(_disc));
  for (final x in [-.18, .18]) {
    canvas.drawOval(
        Rect.fromCenter(center: Offset(x, .2), width: .25, height: .29),
        _fill(const Color(0xFFFFD99D)));
    canvas.drawOval(
        Rect.fromCenter(center: Offset(x * .85, .23), width: .09, height: .14),
        _fill(const Color(0xFF302A3F)));
    canvas.drawCircle(Offset(x * .85 - .018, .19), .022, _fill(Colors.white));
    canvas.drawCircle(
        Offset(x * .7, -.045), .046, _fill(const Color(0xFFFFD99D)));
    canvas.drawPath(
        Path()
          ..moveTo(x * .8, .45)
          ..quadraticBezierTo(x * 1.1, .68, x * .3, .6),
        _line(const Color(0xFFFFE8C8), .065));
  }
}

void _drawSpiderPlayer(Canvas canvas) {
  for (final side in [-1.0, 1.0]) {
    canvas.save();
    canvas.scale(side, 1);
    for (final y in [-.08, .16, .4]) {
      canvas.drawPath(
          Path()
            ..moveTo(.15, y)
            ..lineTo(.48, y + .1)
            ..lineTo(.6, y + .3),
          _line(const Color(0xFFB1CBB6), .07));
    }
    final wing = Path()
      ..moveTo(.12, -.1)
      ..cubicTo(.29, -.89, .83, -.88, .82, -.35)
      ..quadraticBezierTo(.73, -.02, .13, .22)
      ..close();
    canvas.drawPath(wing, _fill(const Color(0xFFD9F4ED)));
    canvas.drawPath(wing, _line(const Color(0xFF8CB5BB), .045));
    canvas.drawLine(const Offset(.23, .02), const Offset(.65, -.51),
        _line(const Color(0xFFAFD3D4), .045));
    canvas.restore();
  }
  canvas.drawOval(const Rect.fromLTRB(-.28, -.18, .28, .79),
      _fill(const Color(0xFF355B5E)));
  for (final y in [.25, .43, .6]) {
    canvas.drawLine(
        Offset(-.2, y), Offset(.2, y), _line(const Color(0xFF8AC0A6), .07));
  }
  canvas.drawCircle(const Offset(0, -.25), .31, _fill(const Color(0xFF456B66)));
  for (final side in [-1.0, 1.0]) {
    canvas.drawCircle(
        Offset(side * .19, -.31), .18, _fill(const Color(0xFFF2AF8C)));
    canvas.drawCircle(
        Offset(side * .19 - .04, -.36), .045, _fill(const Color(0xFFFFE5BD)));
    canvas.drawLine(Offset(side * .09, -.5), Offset(side * .15, -.72),
        _line(const Color(0xFFB4DBBB), .06));
  }
}

void _drawSpiderPickup(Canvas canvas) {
  final top = Path()
    ..moveTo(0, -.86)
    ..lineTo(.73, -.46)
    ..lineTo(0, -.04)
    ..lineTo(-.73, -.46)
    ..close();
  final left = Path()
    ..moveTo(-.73, -.46)
    ..lineTo(0, -.04)
    ..lineTo(0, .84)
    ..lineTo(-.73, .42)
    ..close();
  final right = Path()
    ..moveTo(0, -.04)
    ..lineTo(.73, -.46)
    ..lineTo(.73, .42)
    ..lineTo(0, .84)
    ..close();
  canvas.drawPath(top, _fill(const Color(0xFFFFFAE6)));
  canvas.drawPath(left, _fill(const Color(0xFFE7DBB2)));
  canvas.drawPath(right, _fill(const Color(0xFFBEAA87)));
  for (final dot in [
    const Offset(-.43, -.4),
    const Offset(-.18, -.48),
    const Offset(.23, -.43),
    const Offset(-.47, -.08),
    const Offset(-.23, .33),
    const Offset(.23, .21),
    const Offset(.49, .36),
  ]) {
    canvas.drawCircle(dot, .035, _fill(const Color(0xFFFFF7D5)));
  }
}

void _drawWeb(Canvas canvas) {
  canvas.drawCircle(Offset.zero, .88, _fill(const Color(0xFF554365)));
  final silk = _line(const Color(0xFFFFE2E8), .065);
  for (var spoke = 0; spoke < 6; spoke++) {
    final angle = spoke * math.pi / 3;
    canvas.drawLine(
        Offset.zero, Offset(math.cos(angle), math.sin(angle)) * .86, silk);
  }
  for (final radius in [.32, .61]) {
    final ring = Path();
    for (var spoke = 0; spoke < 6; spoke++) {
      final angle = spoke * math.pi / 3;
      final next = angle + math.pi / 3;
      final start = Offset(math.cos(angle), math.sin(angle)) * radius;
      if (spoke == 0) ring.moveTo(start.dx, start.dy);
      final middle =
          Offset(math.cos(angle + math.pi / 6), math.sin(angle + math.pi / 6)) *
              radius *
              .67;
      final end = Offset(math.cos(next), math.sin(next)) * radius;
      ring.quadraticBezierTo(middle.dx, middle.dy, end.dx, end.dy);
    }
    canvas.drawPath(ring, silk);
  }
  canvas.drawCircle(Offset.zero, .08, _fill(const Color(0xFFFFE2E8)));
}

const _disc = Rect.fromLTRB(-1, -1, 1, 1);
Paint _fill(Color color) => Paint()..color = color;
Paint _line(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..strokeWidth = width;

void _inside(Canvas canvas, Offset center, double radius, VoidCallback draw) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(radius);
  canvas.clipPath(Path()..addOval(_disc));
  draw();
  canvas.restore();
}

void _sphere(Canvas canvas, List<Color> colors) => canvas.drawCircle(
    Offset.zero,
    1,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.45, -.4),
        radius: 1.45,
        colors: colors,
        stops: const [0, .53, 1],
      ).createShader(_disc));

class SkinPreview extends CustomPainter {
  const SkinPreview({required this.skin, this.hero = false});
  final GameSkin skin;
  final bool hero;

  @override
  void paint(Canvas canvas, Size size) {
    final extent = math.min(size.width, size.height);
    final center = size.center(Offset.zero);
    if (hero && skin != GameSkin.classic) {
      final planet = center + const Offset(-.08, .09) * extent;
      final atmosphere = skin.accent;
      final halo = Rect.fromCircle(center: planet, radius: extent * .38);
      canvas.drawCircle(
          planet,
          extent * .38,
          Paint()
            ..shader = RadialGradient(colors: [
              atmosphere.withValues(alpha: .12),
              atmosphere.withValues(alpha: .055),
              atmosphere.withValues(alpha: 0),
            ], stops: const [
              0,
              .78,
              1
            ]).createShader(halo));
      canvas.save();
      canvas.translate(planet.dx, planet.dy);
      canvas.rotate(-.3);
      final orbit = Rect.fromCenter(
          center: Offset.zero, width: extent * .74, height: extent * .27);
      canvas.drawArc(orbit, -.4, math.pi * .75, false,
          _line(GameConstants.quietColor.withValues(alpha: .22), 1));
      canvas.drawArc(orbit, math.pi * .85, math.pi * .5, false,
          _line(GameConstants.quietColor.withValues(alpha: .14), 1));
      canvas.restore();
      skin.drawCore(canvas, planet, extent * .32);
      if (skin == GameSkin.cowAbduction) {
        final beam = Path()
          ..moveTo(center.dx + extent * .215, center.dy - extent * .19)
          ..lineTo(center.dx + extent * .29, center.dy - extent * .19)
          ..lineTo(center.dx + extent * .365, center.dy + extent * .035)
          ..lineTo(center.dx + extent * .195, center.dy + extent * .035)
          ..close();
        canvas.drawPath(
            beam,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFB3F0D7).withValues(alpha: .24),
                  const Color(0xFFB3F0D7).withValues(alpha: .035)
                ],
              ).createShader(beam.getBounds()));
      } else if (skin == GameSkin.deepBlue) {
        for (final bubble in [
          (x: .4, y: -.32, radius: .014),
          (x: .42, y: -.4, radius: .009),
          (x: .35, y: -.43, radius: .006),
        ]) {
          canvas.drawCircle(
              center + Offset(bubble.x, bubble.y) * extent,
              bubble.radius * extent,
              _line(const Color(0xFFB9E5E5).withValues(alpha: .45),
                  extent * .004));
        }
      }
      skin.drawPlayer(
          canvas, center + const Offset(.25, -.26) * extent, extent * .13);
      final pickup = center + const Offset(.28, -.015) * extent;
      canvas.save();
      canvas.translate(pickup.dx, pickup.dy);
      canvas.rotate(skin == GameSkin.cowAbduction ? -.13 : 0);
      skin.drawPickup(canvas, Offset.zero, extent * .105);
      canvas.restore();
      skin.drawHazard(
          canvas, center + const Offset(.26, .24) * extent, extent * .055);
      return;
    }
    final orbit = extent * (hero ? .4 : .38);
    canvas.drawCircle(center, orbit,
        _line(GameConstants.quietColor.withValues(alpha: .55), 1));
    skin.drawCore(canvas, center, extent * (hero ? .28 : .23));
    if (skin == GameSkin.classic) {
      final score = TextPainter(
          text: const TextSpan(
              text: '0',
              style: TextStyle(
                  color: Colors.black, fontFamily: 'Roboto', fontSize: 100)),
          textDirection: TextDirection.ltr)
        ..layout();
      canvas.save();
      final scale = extent * .0023;
      canvas.translate(center.dx - score.width * scale / 2,
          center.dy - score.height * scale / 2);
      canvas.scale(scale);
      score.paint(canvas, Offset.zero);
      canvas.restore();
      score.dispose();
    }
    skin.drawPlayer(canvas, center + Offset(orbit * .71, -orbit * .71),
        extent * (hero ? .085 : .072));
    skin.drawPickup(canvas, center + Offset(-orbit * .71, orbit * .71),
        extent * (hero ? .1 : .085));
    skin.drawHazard(
        canvas, center + Offset(orbit * .9, orbit * .43), extent * .055);
  }

  @override
  bool shouldRepaint(SkinPreview oldDelegate) =>
      oldDelegate.skin != skin || oldDelegate.hero != hero;
}
