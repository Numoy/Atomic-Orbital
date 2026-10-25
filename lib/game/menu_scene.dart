import 'dart:math' as math;
import 'package:atomic_orbital/l10n/strings.dart';

import 'package:atomic_orbital/constants/game_constants.dart';
import 'package:atomic_orbital/game/game_skin.dart';
import 'package:atomic_orbital/game/arcade_style.dart';
import 'package:flutter/material.dart';

const _ink = ArcadePalette.ink;
const _paper = ArcadePalette.paper;
const _ice = ArcadePalette.ice;
const _coral = GameConstants.hardcoreAccent;
const _quiet = ArcadePalette.quiet;

class OrbitMenu extends StatelessWidget {
  const OrbitMenu({
    super.key,
    required this.hardcore,
    required this.normalBest,
    required this.hardcoreBest,
    required this.muted,
    required this.gamesAvailable,
    required this.signedIn,
    required this.onModeChanged,
    required this.onPlay,
    required this.onToggleSound,
    required this.onShare,
    this.skin = GameSkin.classic,
    this.stardust = 0,
    this.onShop,
    this.onProgress,
    this.onSettings,
    this.onPractice,
    this.onDailyChallenge,
    this.status,
    this.providerName,
    this.onAchievements,
    this.onLeaderboard,
    this.onSignIn,
    this.onRate,
  });
  final bool hardcore;
  final int normalBest;
  final int hardcoreBest;
  final bool muted;
  final bool gamesAvailable;
  final bool signedIn;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onPlay;
  final VoidCallback onToggleSound;
  final VoidCallback onShare;
  final GameSkin skin;
  final int stardust;
  final VoidCallback? onShop;
  final VoidCallback? onProgress;
  final VoidCallback? onSettings;
  final VoidCallback? onPractice;
  final VoidCallback? onDailyChallenge;
  final Widget? status;
  final String? providerName;
  final VoidCallback? onAchievements;
  final VoidCallback? onLeaderboard;
  final VoidCallback? onSignIn;
  final VoidCallback? onRate;

  @override
  Widget build(BuildContext context) {
    final accent = hardcore ? _coral : _ice;
    return _ArcadeScene(
      accent: accent,
      muted: muted,
      best: hardcore ? hardcoreBest : normalBest,
      onToggleSound: onToggleSound,
      headerAction: _SceneMenu(
        key: const ValueKey('homeMenu'),
        accent: accent,
        actions: [
          if (onDailyChallenge != null)
            (
              context.l10n.dailyChallenge,
              Icons.today_outlined,
              onDailyChallenge!
            ),
          if (onSettings != null)
            (context.l10n.settings, Icons.settings_outlined, onSettings!),
          (
            context.l10n.howToPlay,
            Icons.help_outline_rounded,
            onPractice ?? () => _showHowToPlay(context, accent)
          ),
          if (gamesAvailable && onLeaderboard != null)
            (
              context.l10n.leaderboard,
              Icons.leaderboard_outlined,
              onLeaderboard!
            ),
          if (gamesAvailable && onAchievements != null)
            (
              context.l10n.achievements,
              Icons.emoji_events_outlined,
              onAchievements!
            ),
          if (gamesAvailable && onSignIn != null)
            (
              signedIn
                  ? context.l10n
                      .disconnectService(providerName ?? context.l10n.playGames)
                  : context.l10n.signIn,
              Icons.sports_esports_outlined,
              onSignIn!
            ),
          (context.l10n.shareGame, Icons.ios_share_rounded, onShare),
          if (onRate != null)
            (context.l10n.rate, Icons.star_outline_rounded, onRate!),
        ],
      ),
      footer: _MenuDestinations(
        accent: accent,
        stardust: stardust,
        onShop: onShop,
        onProgress: onProgress,
        status: status,
      ),
      builder: (context, wide, compact, extent, motion) {
        final arena = Column(mainAxisSize: MainAxisSize.min, children: [
          _Wordmark(accent: accent, compact: compact, wide: wide),
          const SizedBox(height: 6),
          _Arena(extent: extent, accent: accent, motion: motion, skin: skin),
          if (onShop != null) ...[
            const SizedBox(height: 4),
            Text(context.l10n.worldName(skin.id),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _paper, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
          const SizedBox(height: 8),
          Text(context.l10n.controls,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _quiet, fontSize: 12, height: 1.4)),
        ]);
        final controls = Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: Colors.black.withValues(alpha: .24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: ArcadePalette.edge),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: LayoutBuilder(builder: (context, constraints) {
                  final stack = constraints.maxWidth < 280 ||
                      MediaQuery.textScalerOf(context).scale(16) > 24;
                  final normal = _ModeButton(
                      key: const ValueKey('modeNormal'),
                      title: context.l10n.normal,
                      best: normalBest,
                      selected: !hardcore,
                      accent: _ice,
                      icon: Icons.shield_outlined,
                      onPressed: () => onModeChanged(false));
                  final hard = _ModeButton(
                      key: const ValueKey('modeHardcore'),
                      title: context.l10n.hardcore,
                      best: hardcoreBest,
                      selected: hardcore,
                      accent: _coral,
                      icon: Icons.bolt_rounded,
                      onPressed: () => onModeChanged(true));
                  return stack
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [normal, const SizedBox(height: 4), hard])
                      : Row(children: [
                          Expanded(child: normal),
                          const SizedBox(width: 4),
                          Expanded(child: hard),
                        ]);
                }),
              ),
            ),
          )),
          const SizedBox(height: 12),
          _PlayButton(
              key: const ValueKey('startRun'),
              label: context.l10n.play,
              icon: Icons.play_arrow_rounded,
              accent: accent,
              onPressed: onPlay),
          const SizedBox(height: 10),
          Text(hardcore ? context.l10n.oneHit : context.l10n.regenerates,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _quiet, fontSize: 12)),
        ]);
        return wide
            ? Row(children: [
                Expanded(flex: 6, child: arena),
                SizedBox(width: compact ? 24 : 48),
                Expanded(flex: 5, child: controls),
              ])
            : Column(mainAxisSize: MainAxisSize.min, children: [
                arena,
                const SizedBox(height: 16),
                controls,
              ]);
      },
    );
  }
}

class _SceneMenu extends StatelessWidget {
  const _SceneMenu({super.key, required this.accent, required this.actions});
  final Color accent;
  final List<(String, IconData, VoidCallback)> actions;

  @override
  Widget build(BuildContext context) => PopupMenuButton<VoidCallback>(
        tooltip: context.l10n.menu,
        icon: const Icon(Icons.menu_rounded, color: _quiet),
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
        color: ArcadePalette.panel,
        constraints: const BoxConstraints(minWidth: 240, maxWidth: 320),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: ArcadePalette.edge)),
        onSelected: (action) => action(),
        itemBuilder: (context) => [
          for (final (label, icon, callback) in actions)
            PopupMenuItem(
              value: callback,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Icon(icon, color: accent, size: 22),
                  const SizedBox(width: 14),
                  Expanded(child: Text(label)),
                ]),
              ),
            ),
        ],
      );
}

class _MenuDestinations extends StatelessWidget {
  const _MenuDestinations({
    required this.accent,
    required this.stardust,
    this.onShop,
    this.onProgress,
    this.status,
  });
  final Color accent;
  final int stardust;
  final VoidCallback? onShop;
  final VoidCallback? onProgress;
  final Widget? status;

  @override
  Widget build(BuildContext context) {
    if (onShop == null) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        if (onProgress != null)
          TextButton.icon(
            key: const ValueKey('openProgress'),
            onPressed: onProgress,
            icon: const Icon(Icons.emoji_events_outlined, size: 18),
            label: Text(context.l10n.progress),
            style: TextButton.styleFrom(
                foregroundColor: _quiet, minimumSize: const Size(48, 48)),
          ),
        if (status != null) status!,
      ]);
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          LayoutBuilder(builder: (context, constraints) {
            final links = [
              if (onShop != null)
                _MenuDestination(
                  key: const ValueKey('openShop'),
                  icon: Icons.public_rounded,
                  label: context.l10n.worldShop,
                  detail: context.l10n.fluxBalance(stardust),
                  accent: accent,
                  onPressed: onShop!,
                ),
              if (onProgress != null)
                _MenuDestination(
                  key: const ValueKey('openProgress'),
                  icon: Icons.emoji_events_outlined,
                  label: context.l10n.progress,
                  detail: context.l10n.achievements,
                  accent: accent,
                  onPressed: onProgress!,
                ),
            ];
            if (constraints.maxWidth < 280 ||
                MediaQuery.textScalerOf(context).scale(14) > 21) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 10,
                  children: links);
            }
            return Row(
                spacing: 10,
                children: [for (final link in links) Expanded(child: link)]);
          }),
          if (status != null) status!,
        ]),
      ),
    );
  }
}

class _MenuDestination extends StatelessWidget {
  const _MenuDestination({
    super.key,
    required this.icon,
    required this.label,
    required this.detail,
    required this.accent,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final String detail;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
            foregroundColor: _paper,
            backgroundColor: accent.withValues(alpha: .035),
            minimumSize: const Size(48, 72),
            padding: const EdgeInsets.all(14),
            side: const BorderSide(color: ArcadePalette.edge),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14))),
        child: Row(children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(detail,
                      style: const TextStyle(color: _quiet, fontSize: 12)),
                ]),
          ),
        ]),
      );
}

class OrbitGameOver extends StatelessWidget {
  const OrbitGameOver({
    super.key,
    required this.score,
    required this.best,
    required this.newBest,
    required this.hardcore,
    required this.muted,
    required this.onReplay,
    required this.onHome,
    required this.onToggleSound,
    required this.onShare,
    this.skin = GameSkin.classic,
    this.stardust = 0,
    this.stardustEarned,
    this.stardustPending = false,
    this.onShop,
    this.onProgress,
    this.onSettings,
    this.status,
    this.providerName,
    this.onAchievements,
    this.onLeaderboard,
    this.onRate,
    this.seconds,
    this.challengeDate,
  });
  final int score;
  final int best;
  final bool newBest;
  final bool hardcore;
  final bool muted;
  final VoidCallback onReplay;
  final VoidCallback onHome;
  final VoidCallback onToggleSound;
  final VoidCallback onShare;
  final GameSkin skin;
  final int stardust;
  final int? stardustEarned;
  final bool stardustPending;
  final VoidCallback? onShop;
  final VoidCallback? onProgress;
  final VoidCallback? onSettings;
  final Widget? status;
  final String? providerName;
  final VoidCallback? onAchievements;
  final VoidCallback? onLeaderboard;
  final VoidCallback? onRate;
  final int? seconds;
  final String? challengeDate;

  @override
  Widget build(BuildContext context) {
    final accent = hardcore ? _coral : _ice;
    return _ArcadeScene(
      accent: accent,
      muted: muted,
      best: best,
      onToggleSound: onToggleSound,
      headerAction: _SceneMenu(
        key: const ValueKey('resultMenu'),
        accent: accent,
        actions: [
          (context.l10n.shareScore, Icons.ios_share_rounded, onShare),
          if (onSettings != null)
            (context.l10n.settings, Icons.settings_outlined, onSettings!),
          if (onLeaderboard != null)
            (
              context.l10n.leaderboard,
              Icons.leaderboard_outlined,
              onLeaderboard!
            ),
          if (onAchievements != null)
            (
              context.l10n.achievements,
              Icons.emoji_events_outlined,
              onAchievements!
            ),
          if (onRate != null)
            (context.l10n.rate, Icons.star_outline_rounded, onRate!),
        ],
      ),
      footer: _MenuDestinations(
        accent: accent,
        stardust: stardust,
        onShop: onShop,
        onProgress: onProgress,
        status: status,
      ),
      builder: (context, wide, compact, extent, motion) {
        final recap = Column(mainAxisSize: MainAxisSize.min, children: [
          Text(context.l10n.gameOver,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  color: _paper,
                  fontSize: compact ? 20 : 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2)),
          const SizedBox(height: 6),
          Text(
              challengeDate != null
                  ? '${context.l10n.dailyChallenge} · ${context.l10n.dailyDate(challengeDate!)}'
                  : hardcore
                      ? context.l10n.hardcore
                      : context.l10n.normal,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: accent, fontSize: 14, fontWeight: FontWeight.w500)),
          _Arena(
              extent: compact && stardustEarned != null ? 96 : extent,
              accent: accent,
              motion: motion,
              score: score,
              skin: skin),
          Text(context.l10n.pickupsCollected,
              style: const TextStyle(
                  color: _quiet, fontSize: 10, letterSpacing: 2)),
          if (seconds != null) ...[
            const SizedBox(height: 8),
            Text(
                context.l10n.runDuration(
                    '${seconds! ~/ 60}:${(seconds! % 60).toString().padLeft(2, '0')}'),
                key: const ValueKey('runDuration'),
                style: const TextStyle(color: _quiet, fontSize: 12)),
          ],
          if (stardustEarned != null) ...[
            const SizedBox(height: 10),
            Semantics(
              liveRegion: true,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                    color: ArcadePalette.gold.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: ArcadePalette.gold.withValues(alpha: .3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const StarMark(size: 22),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                        stardustPending
                            ? context.l10n.pendingFlux(stardustEarned!)
                            : context.l10n.earnedFlux(stardustEarned!),
                        key: const ValueKey('runStardust'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: ArcadePalette.gold,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ),
          ],
        ]);
        final actions = Column(mainAxisSize: MainAxisSize.min, children: [
          Semantics(
            key: const ValueKey('resultBest'),
            liveRegion: newBest,
            label: challengeDate != null
                ? newBest
                    ? context.l10n.newDailyBestAnnouncement(best)
                    : context.l10n.dailyBestAnnouncement(best)
                : newBest
                    ? context.l10n.newBestAnnouncement(best)
                    : context.l10n.personalBestAnnouncement(best),
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                  color: accent.withValues(alpha: newBest ? .16 : .055),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: newBest
                          ? accent.withValues(alpha: .5)
                          : ArcadePalette.edge)),
              child: Row(children: [
                Icon(
                    newBest
                        ? Icons.emoji_events_rounded
                        : Icons.emoji_events_outlined,
                    color: accent,
                    size: 22),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        newBest
                            ? context.l10n.newBest
                            : challengeDate != null
                                ? context.l10n.dailyBest
                                : context.l10n.personalBest,
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            color: newBest ? accent : _quiet,
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: newBest
                                ? FontWeight.w800
                                : FontWeight.normal))),
                const SizedBox(width: 8),
                Text('$best',
                    style: TextStyle(
                        color: accent,
                        fontSize: 24,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
          SizedBox(height: compact ? 12 : 22),
          _PlayButton(
              key: const ValueKey('replayRun'),
              label: context.l10n.tryAgain,
              icon: Icons.replay_rounded,
              accent: accent,
              onPressed: onReplay),
          const SizedBox(height: 8),
          TextButton.icon(
            key: const ValueKey('home'),
            onPressed: onHome,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text(context.l10n.home),
            style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: _quiet,
                textStyle: const TextStyle(
                    fontFamily: 'Roboto', fontSize: 14, height: 1.4)),
          ),
        ]);
        return wide
            ? Row(children: [
                Expanded(flex: 6, child: recap),
                SizedBox(width: compact ? 24 : 48),
                Expanded(flex: 5, child: actions),
              ])
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [recap, const SizedBox(height: 22), actions]);
      },
    );
  }
}

class OrbitPause extends StatelessWidget {
  const OrbitPause({
    super.key,
    required this.hardcore,
    required this.score,
    required this.muted,
    required this.onResume,
    required this.onHome,
    required this.onToggleSound,
    this.onSettings,
    this.challengeDate,
  });
  final bool hardcore;
  final int score;
  final bool muted;
  final VoidCallback onResume;
  final VoidCallback onHome;
  final VoidCallback onToggleSound;
  final VoidCallback? onSettings;
  final String? challengeDate;

  @override
  Widget build(BuildContext context) => BlockSemantics(
        child: FocusScope(
          child: ColoredBox(
            color: _ink.withValues(alpha: .94),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(context.l10n.paused,
                        style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: _paper,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.2)),
                    const SizedBox(height: 8),
                    Text(
                        '${challengeDate != null ? context.l10n.dailyChallenge : hardcore ? context.l10n.hardcore : context.l10n.normal} · ${context.l10n.scoreLabel(score)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _quiet, fontSize: 14)),
                    const SizedBox(height: 24),
                    _PlayButton(
                        key: const ValueKey('resumeRun'),
                        label: context.l10n.resume,
                        icon: Icons.play_arrow_rounded,
                        accent: hardcore ? _coral : _ice,
                        onPressed: onResume),
                    const SizedBox(height: 16),
                    _Utilities(children: [
                      if (onSettings != null)
                        _Utility(context.l10n.settings, Icons.settings_outlined,
                            onSettings!),
                      _Utility(
                          context.l10n.howToPlay,
                          Icons.help_outline_rounded,
                          () => _showHowToPlay(
                              context, hardcore ? _coral : _ice)),
                      _Utility(
                          muted ? context.l10n.soundOff : context.l10n.soundOn,
                          muted
                              ? Icons.volume_off_outlined
                              : Icons.volume_up_outlined,
                          onToggleSound,
                          semanticLabel: muted
                              ? context.l10n.enableSound
                              : context.l10n.muteSound),
                      _Utility(context.l10n.endRun, Icons.home_outlined, onHome,
                          semanticLabel: context.l10n.endRunLabel),
                    ]),
                    const SizedBox(height: 12),
                    Text(
                        challengeDate != null
                            ? context.l10n.dailyEndRunHelp
                            : context.l10n.endRunHelp,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _quiet, height: 1.4)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}

Future<void> _showHowToPlay(BuildContext context, Color accent) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _ink,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: ListTileTheme(
            data: const ListTileThemeData(
                contentPadding: EdgeInsets.symmetric(vertical: 6),
                titleTextStyle: TextStyle(
                    fontFamily: 'Roboto',
                    color: _paper,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
                subtitleTextStyle: TextStyle(
                    fontFamily: 'Roboto',
                    color: _quiet,
                    fontSize: 14,
                    height: 1.4)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Semantics(
                header: true,
                child: Text(context.l10n.howToPlayTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: _paper,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.3)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.touch_app_outlined, color: accent),
                title: Text(context.l10n.holdRelease),
                subtitle: Text(context.l10n.holdHelp),
              ),
              ListTile(
                leading: const Icon(Icons.crop_square_rounded, color: _paper),
                title: Text(context.l10n.collectPickups),
                subtitle: Text(context.l10n.collectHelp),
              ),
              ListTile(
                leading: const Icon(Icons.circle,
                    color: GameConstants.photonColor, size: 22),
                title: Text(context.l10n.avoidHazards),
                subtitle: Text(context.l10n.hazardHelp),
              ),
              ListTile(
                leading: Icon(Icons.pause_rounded, color: accent),
                title: Text(context.l10n.takeBreak),
                subtitle: Text(context.l10n.pauseHelp),
              ),
              const SizedBox(height: 16),
              _PlayButton(
                  key: const ValueKey('closeHelp'),
                  label: context.l10n.gotIt,
                  icon: Icons.check_rounded,
                  accent: accent,
                  onPressed: () => Navigator.of(context).pop()),
            ]),
          ),
        ),
      ),
    );

class _ArcadeScene extends StatefulWidget {
  const _ArcadeScene({
    required this.accent,
    required this.muted,
    required this.best,
    required this.onToggleSound,
    required this.footer,
    required this.builder,
    this.headerAction,
  });
  final Color accent;
  final bool muted;
  final int best;
  final VoidCallback onToggleSound;
  final Widget footer;
  final Widget? headerAction;
  final Widget Function(BuildContext, bool, bool, double, Animation<double>)
      builder;
  @override
  State<_ArcadeScene> createState() => _ArcadeSceneState();
}

class _ArcadeSceneState extends State<_ArcadeScene>
    with SingleTickerProviderStateMixin {
  late final _motion =
      AnimationController(vsync: this, duration: const Duration(seconds: 8));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion
        ..stop()
        ..value = 0;
    } else if (!_motion.isAnimating) {
      _motion.repeat();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
        data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Roboto'),
            colorScheme: ColorScheme.fromSeed(
                seedColor: widget.accent, brightness: Brightness.dark)),
        child: Material(
          color: _ink,
          child: CustomPaint(
            painter: const SpaceStars(),
            child: LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth >= 640;
              final compact = wide && constraints.maxHeight < 480;
              final inset = compact ? 12.0 : (wide ? 28.0 : 16.0);
              final extent = compact
                  ? 124.0
                  : wide
                      ? math.min(350.0, constraints.maxHeight * .42)
                      : math.min(
                          250.0, math.max(144.0, constraints.maxHeight * .28));
              return SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Padding(
                      padding: EdgeInsets.all(inset),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            minHeight:
                                math.max(0, constraints.maxHeight - inset * 2)),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(children: [
                                Icon(Icons.emoji_events_outlined,
                                    color: widget.accent, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                      context.l10n.bestLabel(widget.best),
                                      style: const TextStyle(
                                          fontFamily: 'Roboto',
                                          color: _paper,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                          height: 1.4)),
                                ),
                                IconButton(
                                  onPressed: widget.onToggleSound,
                                  tooltip: widget.muted
                                      ? context.l10n.enableSound
                                      : context.l10n.muteSound,
                                  icon: Icon(widget.muted
                                      ? Icons.volume_off_outlined
                                      : Icons.volume_up_outlined),
                                  style: IconButton.styleFrom(
                                      foregroundColor: _quiet,
                                      minimumSize: const Size(48, 48)),
                                ),
                                if (widget.headerAction != null)
                                  widget.headerAction!,
                              ]),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: compact ? 8 : 12),
                                child: widget.builder(
                                    context, wide, compact, extent, _motion),
                              ),
                              widget.footer,
                            ]),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      );
}

class _Wordmark extends StatelessWidget {
  const _Wordmark(
      {required this.accent, required this.compact, required this.wide});
  final Color accent;
  final bool compact;
  final bool wide;
  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Atomic Orbital',
        excludeSemantics: true,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('ATOMIC',
                style: TextStyle(
                    fontFamily: 'Roboto',
                    color: _paper,
                    fontSize: compact ? 18 : (wide ? 36 : 28),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    height: 1.1)),
            Text('ORBITAL',
                style: TextStyle(
                    fontFamily: 'Roboto',
                    color: accent,
                    fontSize: compact ? 28 : (wide ? 54 : 44),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    height: 1.1)),
          ]),
        ),
      );
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    super.key,
    required this.title,
    required this.best,
    required this.selected,
    required this.accent,
    required this.icon,
    required this.onPressed,
  });
  final String title;
  final int best;
  final bool selected;
  final Color accent;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => MergeSemantics(
          child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        value: '${context.l10n.personalBest} $best',
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  foregroundColor: selected ? accent : _quiet,
                  backgroundColor: selected
                      ? accent.withValues(alpha: .12)
                      : Colors.transparent,
                  side: BorderSide(
                      color: selected
                          ? accent.withValues(alpha: .5)
                          : Colors.transparent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)))
              .copyWith(
                  animationDuration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 160)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 17),
            const SizedBox(width: 6),
            Flexible(
                child: Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.4))),
          ]),
        ),
      ));
}

class _PlayButton extends StatelessWidget {
  const _PlayButton(
      {super.key,
      required this.label,
      required this.icon,
      required this.accent,
      required this.onPressed});
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        autofocus: true,
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        label: Text(label, textAlign: TextAlign.center),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          backgroundColor: accent,
          foregroundColor: _ink,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              height: 1.3),
        ).copyWith(
            animationDuration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 120)),
      );
}

class _Utilities extends StatelessWidget {
  const _Utilities({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: children);
}

class _Utility extends StatelessWidget {
  const _Utility(this.label, this.icon, this.onPressed, {this.semanticLabel});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) => Tooltip(
        message: semanticLabel ?? label,
        excludeFromSemantics: true,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
              foregroundColor: _quiet,
              minimumSize: const Size(48, 56),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 56),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 22),
              const SizedBox(height: 5),
              Semantics(
                  label: semanticLabel ?? label,
                  excludeSemantics: true,
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontFamily: 'Roboto', fontSize: 10, height: 1.2))),
            ]),
          ),
        ),
      );
}

class _Arena extends StatelessWidget {
  const _Arena(
      {required this.extent,
      required this.accent,
      required this.motion,
      this.score,
      this.skin = GameSkin.classic});
  final double extent;
  final Color accent;
  final Animation<double> motion;
  final int? score;
  final GameSkin skin;
  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        if (score != null && skin != GameSkin.classic)
          Semantics(
            label: context.l10n.scoreLabel(score!),
            excludeSemantics: true,
            child: Text('$score',
                key: const ValueKey('themedResultScore'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: _paper,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    height: 1.2)),
          ),
        SizedBox(
          height: extent,
          child: Center(
              child: SizedBox.square(
            key: const ValueKey('menuArenaArtwork'),
            dimension: extent,
            child: Stack(alignment: Alignment.center, children: [
              ExcludeSemantics(
                  child: RepaintBoundary(
                      child: CustomPaint(
                          size: Size.square(extent),
                          painter: _ArenaPainter(accent, motion,
                              result: score != null, skin: skin)))),
              if (score != null && skin == GameSkin.classic)
                Semantics(
                  label: context.l10n.scoreLabel(score!),
                  excludeSemantics: true,
                  child: SizedBox.square(
                    dimension: extent * .40,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('$score',
                              style: const TextStyle(
                                  color: _ink,
                                  fontSize: 76,
                                  height: 1,
                                  fontWeight: FontWeight.w500))),
                    ),
                  ),
                ),
            ]),
          )),
        ),
      ]);
}

class _ArenaPainter extends CustomPainter {
  _ArenaPainter(this.accent, this.motion,
      {required this.result, required this.skin})
      : super(repaint: motion);
  final Color accent;
  final Animation<double> motion;
  final bool result;
  final GameSkin skin;
  @override
  void paint(Canvas canvas, Size size) {
    final width = math.min(size.width, size.height);
    final t = motion.value * math.pi * 2;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.stroke;
    canvas.drawCircle(
        Offset.zero,
        width * .48,
        Paint()
          ..shader = RadialGradient(colors: [
            accent.withValues(alpha: .18),
            accent.withValues(alpha: 0)
          ]).createShader(
              Rect.fromCircle(center: Offset.zero, radius: width * .48)));
    paint
      ..color = _paper.withValues(alpha: .30)
      ..strokeWidth = 1.1;
    for (final r in [width * .20, width * .44]) {
      for (var i = 0; i < 8; i++) {
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r),
            i * math.pi / 4 + .055 + t * .125, math.pi / 4 - .11, false, paint);
      }
    }
    final orbit = width * (.32 + .065 * math.sin(t * 2));
    paint
      ..color = _paper.withValues(alpha: .68)
      ..strokeWidth = 1.4;
    canvas.drawCircle(Offset.zero, orbit, paint);
    final playerAngle = t * 2 - math.pi / 2;
    paint
      ..color = accent.withValues(alpha: .65)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: orbit),
        playerAngle - .7, .7, false, paint);
    final player = Offset(math.cos(playerAngle), math.sin(playerAngle)) * orbit;
    canvas.drawCircle(
        player, width * .038, Paint()..color = accent.withValues(alpha: .18));
    if (skin == GameSkin.classic) {
      canvas.drawCircle(player, width * .027, Paint()..color = _paper);
    } else {
      skin.drawPlayer(canvas, player, width * (result ? .045 : .05));
    }
    if (!result) {
      for (var i = 0; i < 3; i++) {
        final angle = t + 1.1 + i * 2.25;
        final radius = width * (.27 + .10 * math.sin(t + i));
        final at = Offset(math.cos(angle), math.sin(angle)) * radius;
        canvas.drawCircle(at, width * .032,
            Paint()..color = GameConstants.photonColor.withValues(alpha: .14));
        if (skin == GameSkin.classic) {
          canvas.drawCircle(
              at, width * .014, Paint()..color = GameConstants.photonColor);
        } else {
          skin.drawHazard(canvas, at, width * .02);
        }
      }
      canvas.save();
      final pickup =
          Offset(math.cos(-t + 2.5), math.sin(-t + 2.5)) * width * .36;
      canvas.translate(pickup.dx, pickup.dy);
      if (skin == GameSkin.classic) {
        canvas.rotate(t + math.pi / 4);
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset.zero, width: width * .074, height: width * .074),
            Paint()
              ..color = _paper
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6);
      } else {
        skin.drawPickup(canvas, Offset.zero, width * .061);
      }
      canvas.restore();
    }
    if (skin == GameSkin.classic) {
      canvas.drawCircle(
          Offset.zero, width * (result ? .225 : .125), Paint()..color = _paper);
    } else {
      skin.drawCore(canvas, Offset.zero, width * (result ? .225 : .18));
    }
    if (!result && skin == GameSkin.classic) {
      paint
        ..color = _ink
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.butt;
      for (var i = 0; i < 3; i++) {
        canvas.save();
        canvas.rotate(i * math.pi / 3);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset.zero, width: width * .13, height: width * .052),
            paint);
        canvas.restore();
      }
      canvas.drawCircle(Offset.zero, width * .009, Paint()..color = _ink);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArenaPainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.result != result ||
      oldDelegate.skin != skin ||
      oldDelegate.motion != motion;
}
