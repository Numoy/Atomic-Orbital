import 'package:atomic_orbital/game/arcade_style.dart';
import 'package:atomic_orbital/models/achievement.dart';
import 'package:flutter/material.dart';

class AchievementBadge extends StatelessWidget {
  const AchievementBadge(
      {super.key,
      required this.achievement,
      required this.unlocked,
      this.size = 48});
  final OrbitalAchievement achievement;
  final bool unlocked;
  final double size;
  static const _icons = [
    Icons.explore_outlined,
    Icons.track_changes_rounded,
    Icons.auto_awesome,
    Icons.bolt_rounded,
    Icons.local_fire_department_outlined,
    Icons.whatshot_rounded,
    Icons.electric_bolt_rounded,
    Icons.battery_charging_full_rounded,
    Icons.solar_power_outlined,
    Icons.sports_esports_outlined,
    Icons.flight_outlined,
    Icons.military_tech_outlined,
    Icons.star_outline_rounded,
    Icons.radar_rounded,
    Icons.rocket_launch_outlined,
    Icons.shield_outlined,
    Icons.travel_explore_rounded,
    Icons.public_rounded,
  ];
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
          child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: unlocked
                    ? const [Color(0xFF34404B), ArcadePalette.panel]
                    : const [ArcadePalette.panel, ArcadePalette.ink]),
            border: Border.all(
                width: size / 32,
                color: unlocked ? ArcadePalette.gold : ArcadePalette.edge)),
        child: Icon(_icons[OrbitalAchievement.all.indexOf(achievement)],
            size: size * .52,
            color: unlocked ? ArcadePalette.gold : ArcadePalette.quiet),
      ));
}
