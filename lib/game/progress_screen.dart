import 'package:atomic_orbital/game/arcade_style.dart';
import 'package:atomic_orbital/constants/game_constants.dart';
import 'package:atomic_orbital/l10n/strings.dart';
import 'package:atomic_orbital/models/achievement.dart';
import 'package:atomic_orbital/game/game_skin.dart';
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
        listenable: SettingsService.instance,
        builder: (context, _) {
          final s = SettingsService.instance;
          final l = context.l10n;
          final achievements = [
            ...OrbitalAchievement.all.skip(12),
            ...OrbitalAchievement.all.take(12)
          ].where((a) => cosmeticsEnabled || !a.requiresWorlds).toList();
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: Text(l.progress),
                bottom: TabBar(
                    tabs: [Tab(text: l.achievements), Tab(text: l.statistics)]),
              ),
              body: TabBarView(children: [
                for (final rows in <List<Widget>>[
                  [
                    Text(
                        l.unlockedCount(
                            achievements.where(s.achievementUnlocked).length,
                            achievements.length),
                        style: Theme.of(context).textTheme.titleLarge),
                    if (onPlatformTrophies != null)
                      TextButton(
                          onPressed: onPlatformTrophies,
                          child: Text(l.platformTrophies)),
                    const SizedBox(height: 8),
                    for (final a in achievements)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(
                                  height: 1, color: ArcadePalette.edge),
                              const SizedBox(height: 16),
                              Text(l.achievementTitle(a.id),
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Text(l.achievementDescription(a.id),
                                  style: const TextStyle(
                                      color: ArcadePalette.quiet)),
                              const SizedBox(height: 8),
                              Text(
                                  s.achievementUnlocked(a)
                                      ? l.unlocked
                                      : l.progressCount(
                                          s.achievementProgress(a), a.target),
                                  style: TextStyle(
                                      color: s.achievementUnlocked(a)
                                          ? ArcadePalette.gold
                                          : ArcadePalette.quiet,
                                      fontSize: 12)),
                            ]),
                      ),
                    const SizedBox(height: 12),
                    Text(l.progressLocalNote,
                        style: const TextStyle(color: ArcadePalette.quiet)),
                    const SaveStatus(),
                  ],
                  [
                    for (final row in <(String, String)>[
                      (l.normalBest, '${s.highScore}'),
                      (l.hardcoreBest, '${s.hardcoreHighScore}'),
                      (l.completedRuns, '${s.gamesPlayed}'),
                      (l.totalPoints, '${s.totalPoints}'),
                      (
                        l.playTime,
                        l.hoursMinutes(s.totalPlayTime ~/ 3600,
                            s.totalPlayTime % 3600 ~/ 60)
                      ),
                      if (cosmeticsEnabled)
                        (
                          l.worldsOwned,
                          '${GameSkin.values.where(s.ownsSkin).length} / ${GameSkin.values.length}'
                        ),
                    ])
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                                const SizedBox(height: 16),
                                const Divider(
                                    height: 1, color: ArcadePalette.edge),
                              ])),
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
