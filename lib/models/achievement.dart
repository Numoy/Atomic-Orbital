enum AchievementMetric {
  normal,
  hardcore,
  points,
  games,
  first,
  earlyNormal,
  earlyHardcore,
  clean,
  worlds,
  tour
}

class OrbitalAchievement {
  const OrbitalAchievement(this.id, this.metric, this.target, {this.googleId});
  final String id;
  final AchievementMetric metric;
  final int target;
  final String? googleId;
  bool get requiresWorlds =>
      metric == AchievementMetric.worlds || metric == AchievementMetric.tour;

  static const all = [
    OrbitalAchievement('normal20', AchievementMetric.normal, 20,
        googleId: 'CgkItOGapf0GEAIQCg'),
    OrbitalAchievement('normal35', AchievementMetric.normal, 35,
        googleId: 'CgkItOGapf0GEAIQDA'),
    OrbitalAchievement('normal50', AchievementMetric.normal, 50,
        googleId: 'CgkItOGapf0GEAIQDg'),
    OrbitalAchievement('hardcore20', AchievementMetric.hardcore, 20,
        googleId: 'CgkItOGapf0GEAIQCw'),
    OrbitalAchievement('hardcore35', AchievementMetric.hardcore, 35,
        googleId: 'CgkItOGapf0GEAIQDQ'),
    OrbitalAchievement('hardcore50', AchievementMetric.hardcore, 50,
        googleId: 'CgkItOGapf0GEAIQDw'),
    OrbitalAchievement('points500', AchievementMetric.points, 500,
        googleId: 'CgkItOGapf0GEAIQEA'),
    OrbitalAchievement('points1000', AchievementMetric.points, 1000,
        googleId: 'CgkItOGapf0GEAIQEQ'),
    OrbitalAchievement('points10000', AchievementMetric.points, 10000,
        googleId: 'CgkItOGapf0GEAIQEg'),
    OrbitalAchievement('games50', AchievementMetric.games, 50,
        googleId: 'CgkItOGapf0GEAIQBw'),
    OrbitalAchievement('games150', AchievementMetric.games, 150,
        googleId: 'CgkItOGapf0GEAIQCA'),
    OrbitalAchievement('games500', AchievementMetric.games, 500,
        googleId: 'CgkItOGapf0GEAIQCQ'),
    OrbitalAchievement('firstContact', AchievementMetric.first, 1,
        googleId: 'CgkItOGapf0GEAIQFw'),
    OrbitalAchievement('findingOrbit', AchievementMetric.earlyNormal, 5,
        googleId: 'CgkItOGapf0GEAIQFA'),
    OrbitalAchievement('hardcoreCadet', AchievementMetric.earlyHardcore, 5,
        googleId: 'CgkItOGapf0GEAIQFQ'),
    OrbitalAchievement('steadyHands', AchievementMetric.clean, 10,
        googleId: 'CgkItOGapf0GEAIQGQ'),
    OrbitalAchievement('newHorizons', AchievementMetric.worlds, 1,
        googleId: 'CgkItOGapf0GEAIQGA'),
    OrbitalAchievement('worldTour', AchievementMetric.tour, 3,
        googleId: 'CgkItOGapf0GEAIQFg'),
  ];

  static Iterable<OrbitalAchievement> legacyUnlocks(
      AchievementMetric metric, int value) {
    final reached =
        all.where((a) => a.metric == metric && value >= a.target).toList();
    // Preserve the released Java event order for three-tier unlocks.
    if (reached.length == 3) {
      final first = reached[0];
      reached[0] = reached[1];
      reached[1] = first;
    }
    return reached;
  }
}
