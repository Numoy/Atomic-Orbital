import 'package:atomic_orbital/game/achievement_badge.dart';
import 'package:atomic_orbital/game/arcade_style.dart';
import 'package:atomic_orbital/constants/game_constants.dart';
import 'package:atomic_orbital/l10n/strings.dart';
import 'package:atomic_orbital/models/achievement.dart';
import 'package:atomic_orbital/game/game_skin.dart';
import 'package:atomic_orbital/services/daily_challenge_service.dart';
import 'package:atomic_orbital/services/play_games_service.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter/material.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen(
      {super.key, this.onPlatformTrophies, this.cosmeticsEnabled = false});
  final VoidCallback? onPlatformTrophies;
  final bool cosmeticsEnabled;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge(
            [SettingsService.instance, DailyChallengeService.instance]),
        builder: (context, _) {
          final s = SettingsService.instance;
          final daily = DailyChallengeService.instance;
          final l = context.l10n;
          final achievements = [
            ...OrbitalAchievement.all.skip(12),
            ...OrbitalAchievement.all.take(12)
          ].where((a) => cosmeticsEnabled || !a.requiresWorlds).toList();
          final unlockedTotal =
              achievements.where(s.achievementUnlocked).length;
          final nextGoal =
              achievements.where((a) => !s.achievementUnlocked(a)).firstOrNull;
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: Text(l.progress),
                bottom: TabBar(
                    tabs: [Tab(text: l.achievements), Tab(text: l.statistics)]),
              ),
              body: CustomPaint(
                painter: const SpaceStars(),
                child: TabBarView(children: [
                  for (final rows in <List<Widget>>[
                    [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: ArcadePalette.panel,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: ArcadePalette.edge),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                l.unlockedCount(
                                    unlockedTotal, achievements.length),
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: achievements.isEmpty
                                    ? 0
                                    : unlockedTotal / achievements.length,
                                minHeight: 6,
                                backgroundColor: ArcadePalette.ink,
                                color: ArcadePalette.gold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              nextGoal == null
                                  ? l.allComplete
                                  : '${l.nextGoal}: ${l.achievementTitle(nextGoal.id)} '
                                      '(${l.progressCount(s.achievementProgress(nextGoal), nextGoal.target)})',
                              key: const ValueKey('achievementSummaryStatus'),
                              style: TextStyle(
                                color: nextGoal == null
                                    ? ArcadePalette.gold
                                    : ArcadePalette.quiet,
                                fontSize: 13,
                                fontWeight: nextGoal == null
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            if (onPlatformTrophies != null) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                  onPressed: onPlatformTrophies,
                                  child: Text(l.platformTrophies)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final a in achievements)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: ArcadePalette.panel.withValues(alpha: .78),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: s.achievementUnlocked(a)
                                    ? ArcadePalette.gold.withValues(alpha: .45)
                                    : ArcadePalette.edge,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AchievementBadge(
                                  achievement: a,
                                  unlocked: s.achievementUnlocked(a),
                                  size: 44,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(l.achievementTitle(a.id),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      const SizedBox(height: 4),
                                      Text(l.achievementDescription(a.id),
                                          style: const TextStyle(
                                              color: ArcadePalette.quiet)),
                                      const SizedBox(height: 8),
                                      Text(
                                          s.achievementUnlocked(a)
                                              ? l.unlocked
                                              : l.progressCount(
                                                  s.achievementProgress(a),
                                                  a.target),
                                          style: TextStyle(
                                              color: s.achievementUnlocked(a)
                                                  ? ArcadePalette.gold
                                                  : ArcadePalette.quiet,
                                              fontWeight:
                                                  s.achievementUnlocked(a)
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                              fontSize: 12)),
                                      if (!s.achievementUnlocked(a) &&
                                          a.target > 1) ...[
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: (s.achievementProgress(a) /
                                                    a.target)
                                                .clamp(0.0, 1.0),
                                            minHeight: 4,
                                            backgroundColor: ArcadePalette.ink,
                                            color: ArcadePalette.ice,
                                          ),
                                        ),
                                      ],
                                      if (cosmeticsEnabled)
                                        for (final rewardWorlds in [
                                          GameSkin.values
                                              .where((skin) =>
                                                  skin.requiredAchievementId ==
                                                  a.id)
                                              .toList()
                                        ])
                                          if (rewardWorlds.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: ArcadePalette.ink
                                                    .withValues(alpha: .65),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                    color: ArcadePalette.edge),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.public_rounded,
                                                      size: 13,
                                                      color: rewardWorlds
                                                          .first.accent),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      '${l.unlock}: ${rewardWorlds.map((skin) => l.worldName(skin.id)).join(', ')}',
                                                      style: const TextStyle(
                                                        color:
                                                            ArcadePalette.quiet,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(l.progressLocalNote,
                          style: const TextStyle(color: ArcadePalette.quiet)),
                      const SaveStatus(),
                    ],
                    [
                      for (final row in <(String, String, IconData)>[
                        (l.normalBest, '${s.highScore}', Icons.radar_rounded),
                        (
                          l.hardcoreBest,
                          '${s.hardcoreHighScore}',
                          Icons.whatshot_rounded
                        ),
                        if (daily.completedDaysCount > 0)
                          (
                            l.dailyBest,
                            '${daily.allTimeDailyBest}',
                            Icons.today_outlined
                          ),
                        (
                          l.completedRuns,
                          '${s.gamesPlayed}',
                          Icons.rocket_launch_outlined
                        ),
                      (
                        l.totalPoints,
                        '${s.totalPoints}',
                        Icons.bolt_rounded
                      ),
                      (
                        l.playTime,
                        l.hoursMinutes(s.totalPlayTime ~/ 3600,
                            s.totalPlayTime % 3600 ~/ 60),
                        Icons.schedule_rounded
                      ),
                      if (cosmeticsEnabled)
                        (
                          l.worldsOwned,
                          '${GameSkin.values.where(s.ownsSkin).length} / ${GameSkin.values.length}',
                          Icons.public_rounded
                        ),
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 16),
                          decoration: BoxDecoration(
                            color: ArcadePalette.panel.withValues(alpha: .78),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: ArcadePalette.edge),
                          ),
                          child: Row(
                            children: [
                              ExcludeSemantics(
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: ArcadePalette.ink,
                                    border:
                                        Border.all(color: ArcadePalette.edge),
                                  ),
                                  child: Icon(row.$3,
                                      size: 20, color: ArcadePalette.ice),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(row.$1,
                                        style: const TextStyle(
                                            color: ArcadePalette.quiet)),
                                    const SizedBox(height: 4),
                                    Text(row.$2,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (cosmeticsEnabled) ...[
                      const SizedBox(height: 12),
                      for (final skin in GameSkin.values.where(s.ownsSkin))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: ArcadePalette.panel.withValues(alpha: .6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: skin.accent.withValues(alpha: .35)),
                            ),
                            child: Row(
                              children: [
                                ExcludeSemantics(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: skin.accent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(l.worldName(skin.id),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      Text(l.worldTier('${skin.tier}'),
                                          style: TextStyle(
                                              color: skin.accent,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                Text(l.bestLabel(s.worldBest(skin)),
                                    style: const TextStyle(
                                        color: ArcadePalette.quiet,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 12),
                    Text(l.progressLocalNote,
                        style: const TextStyle(color: ArcadePalette.quiet)),
                    const SaveStatus(),
                  ],
                ])
                  Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: ListView(
                              padding: const EdgeInsets.all(24),
                              children: rows))),
              ]),
              ),
            ),
          );
        },
      );
}

class SaveStatus extends StatelessWidget {
  const SaveStatus({super.key});
  @override
  Widget build(BuildContext context) {
    final s = SettingsService.instance;
    return ValueListenableBuilder<bool>(
        valueListenable: s.progressSaving,
        builder: (context, pending, _) {
          if (s.progressFailure == null) {
            return pending
                ? Text(context.l10n.savePending, textAlign: TextAlign.center)
                : const SizedBox.shrink();
          }
          return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(children: [
                Text(
                    s.progressFailure!.startsWith('Saved')
                        ? context.l10n.saveUnreadable
                        : context.l10n.saveFailed,
                    style:
                        const TextStyle(color: GameConstants.hardcoreAccent)),
                if (!s.progressFailure!.startsWith('Saved'))
                  TextButton(
                      onPressed: s.flushProgress,
                      child: Text(context.l10n.retry)),
              ]));
        });
  }
}

class ConnectionStatus extends StatelessWidget {
  const ConnectionStatus({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: PlayGamesService.instance,
      builder: (context, _) {
        final g = PlayGamesService.instance;
        if (!g.supported) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(g.authenticated
              ? '${context.l10n.connected} · ${g.displayName ?? ""}'
              : context.l10n.offline),
          if (g.pendingCount > 0)
            Text(context.l10n.syncPending(g.pendingCount)),
          if (g.lastError != null)
            Text(g.lastError == 'profile_changed'
                ? context.l10n.profileChanged
                : g.lastError!.contains('cannot accept')
                    ? context.l10n.rangeWarning
                    : context.l10n.syncFailed),
          if (g.authenticated && (g.pendingCount > 0 || g.lastError != null))
            TextButton(
                onPressed: g.refreshAuthentication,
                child: Text(context.l10n.retrySync)),
        ]);
      });
}
