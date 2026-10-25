import 'dart:async';
import 'dart:io';
import 'package:atomic_orbital/game/daily_challenge.dart';
import 'package:atomic_orbital/game/practice_screen.dart';
import 'package:atomic_orbital/game/progress_screen.dart';
import 'package:atomic_orbital/game/settings_screen.dart';
import 'package:atomic_orbital/l10n/strings.dart';
import 'package:atomic_orbital/models/achievement.dart';
import 'dart:math' as math;

import 'package:atomic_orbital/constants/game_constants.dart';
import 'package:atomic_orbital/game/game_engine.dart';
import 'package:atomic_orbital/game/gameplay_feedback.dart';
import 'package:atomic_orbital/game/game_skin.dart';
import 'package:atomic_orbital/game/menu_scene.dart';
import 'package:atomic_orbital/game/original_text.dart';
import 'package:atomic_orbital/game/skin_shop.dart';
import 'package:atomic_orbital/models/components.dart';
import 'package:atomic_orbital/services/audio_service.dart';
import 'package:atomic_orbital/services/daily_challenge_service.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:atomic_orbital/services/play_games_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

const _platform = MethodChannel('atomic_orbital/platform');

class GameScreen extends StatefulWidget {
  const GameScreen(
      {super.key,
      this.engine,
      this.textCache,
      this.introduce = false,
      this.cosmeticsEnabled = false});
  final bool introduce;
  final bool cosmeticsEnabled;
  final GameEngine? engine;
  final OriginalTextCache? textCache;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final GameEngine _engine;
  final _feedback = GameplayFeedback();
  late final Ticker _ticker;
  final _gameFocus = FocusNode();
  Duration? _lastTick;
  bool _hardcore = false;
  bool _startingRun = false;
  final Set<String> _seenAchievements = {};
  final List<String> _earnedAchievements = [];
  final Set<int> _pointers = {};
  final Set<LogicalKeyboardKey> _heldKeys = {};
  late final OriginalTextCache _textCache;
  bool _textReady = false;
  String? _preparedPrompt;
  DailyChallenge? _dailyChallenge;
  int _dailyPreviousBest = 0;
  bool _openingDaily = false;
  int _seenScore = 0;
  int _runEarned = 0;
  int _unbankedStardust = 0;
  bool _savingStardust = false;
  bool _openingShop = false;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _stardustWarning;
  static const _ratio = GameConstants.referencePixelRatio;
  static const _frameSize = Size(GameConstants.referenceLogicalWidth,
      GameConstants.referenceLogicalCanvasHeight);
  GameSkin get _skin => widget.cosmeticsEnabled && _dailyChallenge == null
      ? SettingsService.instance.selectedSkin
      : GameSkin.classic;

  @override
  void initState() {
    super.initState();
    _textCache = (widget.textCache ??
        OriginalTextCache(enabled: !kIsWeb && Platform.isAndroid))
      ..addListener(_redraw);
    PlayGamesService.instance.addListener(_redraw);
    SettingsService.instance.addListener(_redraw);
    DailyChallengeService.instance.addListener(_redraw);
    _textReady = !_textCache.available;
    _engine = widget.engine ?? GameEngine();
    _engine.skin = _skin;
    _seenAchievements.addAll(OrbitalAchievement.all
        .where(SettingsService.instance.achievementUnlocked)
        .map((a) => a.id));
    _seenScore = _engine.score;
    _feedback.sync(_engine);
    _engine.onScoreChanged = _scoreChanged;
    _engine.onGameOver = () => unawaited(_saveDailyResult());
    _engine.onStateChanged = (state) {
      if (state == GameState.ready || state == GameState.menu) {
        _feedback.sync(_engine);
      }
      if (state != GameState.ready && state != GameState.playing) _clearInput();
      if (mounted) setState(() {});
    };
    _ticker = createTicker((elapsed) {
      final previous = _lastTick;
      _lastTick = elapsed;
      if (previous != null && _acceptsInput) {
        final health = _engine.health;
        _engine.update((elapsed - previous).inMicroseconds / 1000000);
        if (_engine.health < health &&
            SettingsService.instance.hapticsEnabled) {
          unawaited(HapticFeedback.mediumImpact());
        }
        _feedback.sync(_engine);
        if (mounted) setState(() {});
      }
    })
      ..start();
    WidgetsBinding.instance.addObserver(this);
  }

  void _redraw() {
    final fresh = OrbitalAchievement.all
        .where((a) =>
            (widget.cosmeticsEnabled || !a.requiresWorlds) &&
            SettingsService.instance.achievementUnlocked(a) &&
            !_seenAchievements.contains(a.id))
        .map((a) => a.id)
        .toList();
    if (fresh.isNotEmpty) {
      _seenAchievements.addAll(fresh);
      _earnedAchievements.addAll(fresh);
      unawaited(PlayGamesService.instance.syncLocalAchievements());
      if (_engine.state == GameState.menu) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _message(context.l10n
                .achievementEarned(context.l10n.achievementTitle(fresh.first)));
          }
        });
      }
    }
    if (_textCache.failure != null) _clearInput();
    if (mounted) setState(() {});
  }

  Iterable<OriginalTextSpec> _scoreSpecs(int score) sync* {
    yield OriginalTextSpec('$score', 135, canvas: true, color: Colors.black);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final prompt = context.l10n.touchToStart;
    if (_preparedPrompt == prompt || !_textCache.available) return;
    _preparedPrompt = prompt;
    _textReady = false;
    _clearInput();
    _lastTick = null;
    unawaited(_textCache.prepare([
      if (GameConstants.debug)
        for (var fps = 0; fps <= 60; fps++)
          OriginalTextSpec('FPS: $fps', 40, canvas: true, color: Colors.white),
      OriginalTextSpec(prompt, 60, canvas: true, color: Colors.white),
      for (var score = 0; score <= 10; score++) ..._scoreSpecs(score),
      ..._scoreSpecs(SettingsService.instance.highScore),
      ..._scoreSpecs(SettingsService.instance.hardcoreHighScore),
    ], pin: true).then((_) {
      if (mounted && _preparedPrompt == prompt) {
        setState(() => _textReady = true);
      }
    }));
  }

  Future<void> _startRun({DailyChallenge? challenge}) async {
    if (_startingRun) return;
    _startingRun = true;
    try {
      final s = SettingsService.instance;
      if (widget.introduce && !s.tutorialSeen) {
        await _practice();
        if (!mounted || !s.tutorialSeen) return;
      }
      if (challenge == null &&
          widget.introduce &&
          _hardcore &&
          !s.hardcoreExplained) {
        final accepted = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text(context.l10n.hardcore),
                  content: Text(context.l10n.hardcoreIntro),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(context.l10n.play))
                  ],
                ));
        if (!mounted || accepted != true) return;
        s.setOption('hardcoreHint', true);
      }
      _clearInput();
      _dailyChallenge = challenge;
      _dailyPreviousBest = challenge == null
          ? 0
          : DailyChallengeService.instance.bestFor(challenge);
      _seenScore = 0;
      _earnedAchievements.clear();
      _runEarned = 0;
      _engine.skin = challenge == null ? _skin : GameSkin.classic;
      _engine.startGame(
          hardcore: challenge == null && _hardcore,
          random: challenge?.createRandom(),
          recordProgress: challenge == null);
      _gameFocus.requestFocus();
    } finally {
      _startingRun = false;
    }
  }

  Future<void> _openDailyChallenge() async {
    if (_openingDaily) return;
    if (SettingsService.instance.backupRecoveryFailed) {
      _message(context.l10n.backupRecoveryFailed);
      return;
    }
    _openingDaily = true;
    try {
      final daily = DailyChallengeService.instance;
      await daily.flush();
      await daily.initialize(reload: true);
      if (!mounted) return;
      final challenge = DailyChallenge.forDate(DateTime.now());
      final l = context.l10n;
      final reset = DateFormat.yMMMd(l.localeName)
          .add_jm()
          .format(challenge.resetUtc.toLocal());
      final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                scrollable: true,
                title: Text(l.dailyChallenge),
                content: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.dailyDate(challenge.date)),
                        const SizedBox(height: 16),
                        Text(l.dailyIntro),
                        const SizedBox(height: 16),
                        Text(l.dailyBestAnnouncement(daily.bestFor(challenge))),
                        Text(l.dailyReset(reset)),
                        const SizedBox(height: 16),
                        Text(l.dailyLocalNote),
                        if (daily.failure != null) Text(l.dailySaveFailed),
                      ]),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l.cancel)),
                  FilledButton(
                      key: const ValueKey('startDailyChallenge'),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l.play)),
                ],
              ));
      if (mounted && accepted == true) await _startRun(challenge: challenge);
    } catch (_) {
      if (mounted) _message(context.l10n.dailySaveFailed);
    } finally {
      _openingDaily = false;
    }
  }

  Future<void> _saveDailyResult() async {
    final challenge = _dailyChallenge;
    if (challenge == null) return;
    try {
      await DailyChallengeService.instance.recordResult(challenge,
          score: _engine.score, seconds: _engine.gameTime.round());
    } catch (_) {
      // The service retains the pending best so another attempt cannot lose it.
    }
  }

  Widget _dailySaveStatus() {
    final daily = DailyChallengeService.instance;
    if (daily.failure == null && !daily.pending) return const SizedBox.shrink();
    final unreadable = daily.failure?.startsWith('Saved') ?? false;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(
          unreadable
              ? context.l10n.dailyUnreadable
              : daily.failure == null
                  ? context.l10n.savePending
                  : context.l10n.dailySaveFailed,
          textAlign: TextAlign.center),
      if (daily.failure != null && !unreadable)
        TextButton(
            onPressed: () async {
              try {
                await daily.flush();
              } catch (_) {}
            },
            child: Text(context.l10n.retry)),
    ]);
  }

  Future<void> _practice() => Navigator.of(context)
      .push<void>(MaterialPageRoute(builder: (_) => const PracticeScreen()));

  Future<void> _openProgress() =>
      Navigator.of(context).push<void>(MaterialPageRoute(
          builder: (_) => ProgressScreen(
              cosmeticsEnabled: widget.cosmeticsEnabled,
              onPlatformTrophies: PlayGamesService.instance.supported
                  ? () => _external('achievements')
                  : null)));

  Future<void> _openSettings() =>
      Navigator.of(context).push<void>(MaterialPageRoute(
          builder: (_) => SettingsScreen(
              onPractice: _practice,
              onSaveRestored: () {
                _earnedAchievements.clear();
                _seenAchievements
                  ..clear()
                  ..addAll(OrbitalAchievement.all
                      .where(SettingsService.instance.achievementUnlocked)
                      .map((a) => a.id));
                _home();
                Navigator.of(context).pop();
              })));

  void _scoreChanged(int score) {
    if (score <= _seenScore) return;
    final earned = score - _seenScore;
    if (SettingsService.instance.hapticsEnabled) {
      unawaited(HapticFeedback.selectionClick());
    }
    _feedback.collect(
        Offset(_engine.energy.position.position.x,
            _engine.energy.position.position.y),
        _engine.gameTime);
    _seenScore = score;
    if (widget.cosmeticsEnabled && _dailyChallenge == null) {
      _runEarned += earned;
      _unbankedStardust += earned;
      unawaited(_bankStardust());
    }
  }

  Future<void> _bankStardust() async {
    if (_savingStardust || _unbankedStardust == 0) return;
    _savingStardust = true;
    try {
      while (_unbankedStardust > 0) {
        final amount = _unbankedStardust;
        await SettingsService.instance.earnStardust(amount);
        _unbankedStardust -= amount;
      }
      if (mounted) {
        _stardustWarning?.close();
        _stardustWarning = null;
      }
    } catch (_) {
      if (mounted && _stardustWarning == null) {
        final warning = ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(days: 1),
          content: Text(context.l10n.fluxFailed),
          action: SnackBarAction(
              label: context.l10n.retry,
              onPressed: () {
                _stardustWarning = null;
                unawaited(_bankStardust());
              }),
        ));
        _stardustWarning = warning;
        unawaited(warning.closed.then((_) {
          if (identical(_stardustWarning, warning)) _stardustWarning = null;
        }));
      }
    } finally {
      _savingStardust = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _openShop() async {
    if (_openingShop) return;
    _openingShop = true;
    try {
      await _bankStardust();
      if (!mounted) return;
      await Navigator.of(context)
          .push<void>(MaterialPageRoute(builder: (_) => const SkinShop()));
      if (mounted) _gameFocus.requestFocus();
    } finally {
      _openingShop = false;
    }
  }

  void _toggleSound() {
    setState(() =>
        AudioService.instance.setMuted(!SettingsService.instance.isMuted));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _gameFocus.dispose();
    _engine.onStateChanged = null;
    _engine.onScoreChanged = null;
    _engine.onGameOver = null;
    _engine.dispose();
    _textCache.removeListener(_redraw);
    PlayGamesService.instance.removeListener(_redraw);
    SettingsService.instance.removeListener(_redraw);
    DailyChallengeService.instance.removeListener(_redraw);
    _textCache.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lastTick = null;
    if (state == AppLifecycleState.resumed) {
      unawaited(PlayGamesService.instance.refreshAuthentication());
    } else {
      _pauseRun();
      unawaited(SettingsService.instance.flushProgress());
      unawaited(
          DailyChallengeService.instance.flush().catchError((Object _) {}));
    }
  }

  void _pauseRun() {
    _clearInput();
    _lastTick = null;
    _engine.pauseGame();
    unawaited(AudioService.instance.pauseBackgroundMusic());
  }

  void _resumeRun() {
    if (_engine.state != GameState.paused) return;
    _clearInput();
    _lastTick = null;
    _engine.resumeGame();
    _gameFocus.requestFocus();
    if (_acceptsInput) unawaited(AudioService.instance.playBackgroundMusic());
  }

  void _back() {
    if (_engine.state == GameState.paused) {
      _resumeRun();
    } else if (_engine.state == GameState.ready ||
        _engine.state == GameState.playing) {
      _pauseRun();
    } else {
      _home();
    }
  }

  void _selectMode(bool hardcore) {
    setState(() {
      _hardcore = hardcore;
    });
  }

  void _home() {
    _clearInput();
    _dailyChallenge = null;
    unawaited(AudioService.instance.pauseBackgroundMusic());
    _engine.resetGame();
  }

  void _clearInput() {
    _pointers.clear();
    _heldKeys.clear();
    _engine.onTouchUp();
  }

  void _syncInput() {
    if (_pointers.isNotEmpty || _heldKeys.isNotEmpty) {
      _engine.onTouchDown();
    } else {
      _engine.onTouchUp();
    }
  }

  bool get _acceptsInput =>
      _textReady &&
      _textCache.failure == null &&
      (_engine.state == GameState.ready || _engine.state == GameState.playing);

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;
    if (event is KeyDownEvent &&
        (key == LogicalKeyboardKey.escape ||
            (key == LogicalKeyboardKey.keyP &&
                (_acceptsInput || _engine.state == GameState.paused)))) {
      _back();
      return KeyEventResult.handled;
    }
    if (key != LogicalKeyboardKey.space && key != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent) {
      if (!_acceptsInput) return KeyEventResult.ignored;
      _heldKeys.add(key);
      _syncInput();
    } else if (event is KeyUpEvent) {
      if (!_heldKeys.remove(key)) return KeyEventResult.ignored;
      _syncInput();
    }
    return KeyEventResult.handled;
  }

  @override
  void didChangeMetrics() {
    _clearInput();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _external(String action) async {
    try {
      final games = PlayGamesService.instance;
      if (action == 'achievements' ||
          action == 'leaderboard' ||
          action == 'signIn') {
        if (action == 'signIn' && games.authenticated) {
          final message = context.l10n.offline;
          await games.disconnect();
          if (games.isApple) {
            if (mounted) _message(message);
          } else {
            await _platform.invokeMethod<void>(
                'playGamesDisconnected', {'message': message});
          }
        } else {
          final completed = switch (action) {
            'achievements' => await games.showAchievements(),
            'leaderboard' => await games.showLeaderboards(hardcore: _hardcore),
            _ => await games.signIn(),
          };
          if (!completed && mounted) {
            _message(games.lastError == 'profile_changed'
                ? context.l10n.profileChanged
                : games.isApple
                    ? context.l10n.nativeSignInCancelled
                    : context.l10n.signInCancelled);
          }
        }
        return;
      }
      await _platform.invokeMethod<void>(action, {
        'score': _engine.state == GameState.gameOver
            ? _engine.score
            : (_hardcore
                ? SettingsService.instance.hardcoreHighScore
                : SettingsService.instance.highScore),
        'hardcore': _hardcore,
        'message': _dailyChallenge != null
            ? context.l10n
                .dailyShareMessage(_engine.score, _dailyChallenge!.date)
            : context.l10n.shareMessage(_engine.state == GameState.gameOver
                ? _engine.score
                : (_hardcore
                    ? SettingsService.instance.hardcoreHighScore
                    : SettingsService.instance.highScore)),
      });
    } on MissingPluginException {
      if (mounted) _message(context.l10n.notAvailable);
    } on PlatformException {
      if (mounted) _message(context.l10n.actionFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final menu = _engine.state == GameState.menu;
    final over = _engine.state == GameState.gameOver;
    const statusColor = GameConstants.backgroundColor;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: statusColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: statusColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: menu,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: Scaffold(
          backgroundColor: statusColor,
          body: Stack(fit: StackFit.expand, children: [
            Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.paddingOf(context).top,
                child: const ColoredBox(color: statusColor)),
            SafeArea(
              child: Focus(
                focusNode: _gameFocus,
                autofocus: true,
                onKeyEvent: _onKey,
                onFocusChange: (focused) {
                  if (!focused) _clearInput();
                },
                child: menu
                    ? _menu()
                    : Stack(fit: StackFit.expand, children: [
                        Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: (event) {
                            if (!_acceptsInput) return;
                            _pointers.add(event.pointer);
                            _syncInput();
                          },
                          onPointerUp: (event) {
                            _pointers.remove(event.pointer);
                            _syncInput();
                          },
                          onPointerCancel: (_) => _clearInput(),
                          child: _playfield(),
                        ),
                        if (_acceptsInput)
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: IconButton(
                              tooltip: context.l10n.pauseGame,
                              onPressed: _pauseRun,
                              style: IconButton.styleFrom(
                                  foregroundColor: GameConstants.atomColor,
                                  backgroundColor:
                                      GameConstants.backgroundColor,
                                  minimumSize: const Size(48, 48)),
                              icon: const Icon(Icons.pause_rounded),
                            ),
                          ),
                        if (_engine.state == GameState.paused &&
                            _textReady &&
                            _textCache.failure == null)
                          OrbitPause(
                            hardcore: _engine.hardcore,
                            challengeDate: _dailyChallenge?.date,
                            score: _engine.score,
                            muted: SettingsService.instance.isMuted,
                            onResume: _resumeRun,
                            onSettings: _openSettings,
                            onHome: _home,
                            onToggleSound: _toggleSound,
                          ),
                        if (over) _gameOver(),
                      ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _menu() {
    final games = PlayGamesService.instance;
    final settings = SettingsService.instance;
    return OrbitMenu(
      hardcore: _hardcore,
      normalBest: settings.highScore,
      hardcoreBest: settings.hardcoreHighScore,
      muted: settings.isMuted,
      gamesAvailable: games.supported,
      providerName: games.providerName,
      signedIn: games.authenticated,
      skin: _skin,
      stardust: settings.stardust,
      onShop: widget.cosmeticsEnabled ? _openShop : null,
      onProgress: _openProgress,
      onSettings: _openSettings,
      onPractice: _practice,
      onDailyChallenge: _openDailyChallenge,
      status: Column(
          mainAxisSize: MainAxisSize.min,
          children: [const SaveStatus(), _dailySaveStatus()]),
      onModeChanged: _selectMode,
      onPlay: _startRun,
      onToggleSound: _toggleSound,
      onShare: () => _external('share'),
      onAchievements: games.supported ? () => _external('achievements') : null,
      onLeaderboard: games.supported ? () => _external('leaderboard') : null,
      onSignIn: games.supported ? () => _external('signIn') : null,
      onRate:
          games.supported && !games.isApple ? () => _external('rate') : null,
    );
  }

  Widget _gameOver() {
    final games = PlayGamesService.instance;
    final settings = SettingsService.instance;
    final challenge = _dailyChallenge;
    return OrbitGameOver(
      score: _engine.score,
      best: challenge != null
          ? math.max(_dailyPreviousBest, _engine.score)
          : _engine.hardcore
              ? settings.hardcoreHighScore
              : settings.highScore,
      newBest: challenge != null
          ? _engine.score > _dailyPreviousBest
          : _engine.isNewHighScore,
      seconds: _engine.gameTime.round(),
      challengeDate: challenge?.date,
      skin: challenge == null ? _skin : GameSkin.classic,
      stardust: settings.stardust,
      stardustEarned:
          widget.cosmeticsEnabled && challenge == null ? _runEarned : null,
      stardustPending: _unbankedStardust > 0,
      onShop: widget.cosmeticsEnabled && challenge == null ? _openShop : null,
      onProgress: _openProgress,
      onSettings: _openSettings,
      status: Column(mainAxisSize: MainAxisSize.min, children: [
        _dailySaveStatus(),
        for (final id
            in challenge == null ? _earnedAchievements.take(3) : <String>[])
          Text(
              context.l10n.achievementEarned(context.l10n.achievementTitle(id)),
              textAlign: TextAlign.center),
        const SaveStatus()
      ]),
      hardcore: _engine.hardcore,
      muted: settings.isMuted,
      onReplay: () => _startRun(
          challenge: challenge == null
              ? null
              : DailyChallenge.forDate(DateTime.now())),
      onHome: _home,
      onToggleSound: _toggleSound,
      onShare: () => _external('share'),
      onAchievements: games.supported ? () => _external('achievements') : null,
      onLeaderboard: games.supported && challenge == null
          ? () => _external('leaderboard')
          : null,
      onRate:
          games.supported && !games.isApple ? () => _external('rate') : null,
    );
  }

  Widget _playfield() {
    final skin = _skin;
    if (!_textReady) return const Center(child: CircularProgressIndicator());
    if (_textCache.failure != null) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(context.l10n.textFailed),
        TextButton(onPressed: _home, child: Text(context.l10n.returnMenu)),
      ]));
    }
    unawaited(_textCache.prepare([
      ..._scoreSpecs(_engine.score),
      ..._scoreSpecs(_engine.score + 1),
    ]));
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.contain,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          key: const ValueKey('gameViewport'),
          width: _frameSize.width,
          height: _frameSize.height,
          child: MediaQuery.withNoTextScaling(
            child: Semantics(
              label: _engine.state == GameState.ready
                  ? context.l10n.readyLabel
                  : context.l10n.holdLabel,
              child: ClipRect(
                  child: CustomPaint(
                      painter: GamePainter(_engine,
                          devicePixelRatio: _ratio,
                          textCache: _textCache,
                          skin: skin,
                          feedback: _feedback,
                          strings: context.l10n,
                          reduceMotion:
                              MediaQuery.disableAnimationsOf(context)))),
            ),
          ),
        ),
      ),
    );
  }
}

class GamePainter extends CustomPainter {
  const GamePainter(this.gameEngine,
      {this.devicePixelRatio = 1,
      this.textCache,
      this.skin = GameSkin.classic,
      this.feedback,
      this.reduceMotion = false,
      this.strings});
  final GameEngine gameEngine;
  final double devicePixelRatio;
  final OriginalTextCache? textCache;
  final GameSkin skin;
  final GameplayFeedback? feedback;
  final bool reduceMotion;
  final AppLocalizations? strings;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final accent = gameEngine.hardcore
        ? GameConstants.hardcoreAccent
        : GameConstants.normalAccent;
    // Keep the original quantized hit-flash envelope and controller timing.
    final backgroundRed = ((gameEngine.backgroundRed >> 3) * 255 / 31).round();
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = Color.lerp(GameConstants.backgroundColor,
              const Color(0xFFFF1029), backgroundRed / 255)!);
    canvas.scale(1 / devicePixelRatio);
    final center = Offset((gameEngine.width ~/ 2).toDouble(),
        (gameEngine.height ~/ 2).toDouble());
    final paint = Paint();
    final glowBounds =
        Rect.fromCircle(center: center, radius: gameEngine.width * .6);
    canvas.drawCircle(
        center,
        glowBounds.width / 2,
        Paint()
          ..shader = RadialGradient(colors: [
            accent.withValues(alpha: .10),
            accent.withValues(alpha: 0)
          ]).createShader(glowBounds));
    if (skin != GameSkin.classic && !reduceMotion) {
      _motionFeedback(canvas);
    }
    paint.color = GameConstants.photonColor;
    for (final photon in gameEngine.photons) {
      final logic = photon.logic as PhotonLogicComponent;
      final position =
          Offset(photon.position.position.x, photon.position.position.y);
      if (skin == GameSkin.classic) {
        canvas.drawCircle(position, logic.radius, paint);
      } else {
        skin.drawHazard(canvas, position, logic.radius);
      }
    }
    paint
      ..color = GameConstants.quietColor
          .withValues(alpha: skin == GameSkin.classic ? .6 : .3)
      ..strokeWidth = skin == GameSkin.classic ? 5 : 3
      ..style = PaintingStyle.stroke;
    final minRadius = (gameEngine.width ~/ 5).toDouble();
    for (final orbit in gameEngine.orbits) {
      final bounds = Rect.fromCircle(center: center, radius: orbit.radius);
      for (var angle = 0; angle < 360; angle += 30) {
        canvas.drawArc(
            bounds,
            (angle + orbit.rotation * orbit.direction) * math.pi / 180,
            (30 - 6 * minRadius / orbit.radius) * math.pi / 180,
            false,
            paint);
      }
    }
    paint
      ..color = GameConstants.atomColor
      ..style = PaintingStyle.fill;
    if (skin == GameSkin.classic) {
      canvas.drawCircle(center, gameEngine.atom.size.radius, paint);
    } else {
      skin.drawCore(canvas, center, gameEngine.atom.size.radius);
    }
    if (skin == GameSkin.classic) {
      _text(
          canvas,
          '${gameEngine.score}',
          Offset(gameEngine.scoreTextX, gameEngine.scoreTextY),
          gameEngine.atom.size.radius,
          Colors.black);
    }
    final energy = gameEngine.energy;
    final position =
        Offset(energy.position.position.x, energy.position.position.y);
    if (energy.collision.isCollidable) {
      if (skin == GameSkin.classic) {
        final rotation = (energy.logic as EnergyLogicComponent).rotation;
        final sin = float32(
            energy.size.radius * float32(math.sin(rotation * math.pi / 180)));
        final cos = float32(
            energy.size.radius * float32(math.cos(rotation * math.pi / 180)));
        final corners = [
          Offset(cos, sin),
          Offset(-sin, cos),
          Offset(-cos, -sin),
          Offset(sin, -cos)
        ];
        final vertices = corners
            .map((corner) => Offset(float32(position.dx + corner.dx),
                float32(position.dy + corner.dy)))
            .toList();
        paint
          ..color = GameConstants.energyColor
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke;
        for (var i = 0; i < 4; i++) {
          canvas.drawLine(vertices[i], vertices[(i + 1) % 4], paint);
        }
      } else {
        _pickupMarker(canvas, position, energy.size.radius);
        skin.drawPickup(canvas, position, energy.size.radius);
      }
    }
    final player = gameEngine.player;
    paint
      ..color = GameConstants.atomColor
          .withValues(alpha: skin == GameSkin.classic ? .68 : .30)
      ..strokeWidth = skin == GameSkin.classic ? 5 : 3
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(
        center, (player.logic as PlayerLogicComponent).currentRadius, paint);
    paint
      ..color = GameConstants.playerColor
      ..style = PaintingStyle.fill;
    final playerPosition =
        Offset(player.position.position.x, player.position.position.y);
    if (skin == GameSkin.classic) {
      canvas.drawCircle(playerPosition, player.size.radius, paint);
    } else {
      canvas.drawCircle(playerPosition, player.size.radius,
          Paint()..color = GameConstants.normalAccent.withValues(alpha: .10));
      canvas.drawCircle(
          playerPosition,
          player.size.radius,
          Paint()
            ..color = GameConstants.normalAccent.withValues(alpha: .8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
      skin.drawPlayer(canvas, playerPosition, player.size.radius);
      if (gameEngine.state == GameState.ready) {
        _sceneText(
            canvas,
            (strings?.you ?? 'YOU'),
            playerPosition - Offset(0, player.size.radius + 16),
            28,
            GameConstants.normalAccent,
            center: true);
      }
    }
    if (GameConstants.debug) {
      _text(canvas, 'FPS: ${gameEngine.fps}', const Offset(50, 125), 40,
          Colors.white);
    }
    if (!gameEngine.practice && gameEngine.state != GameState.gameOver) {
      if (skin == GameSkin.classic) {
        _health(canvas, accent);
      } else {
        _themedHud(canvas, accent);
      }
    }
    if (!gameEngine.practice && gameEngine.state == GameState.ready) {
      if (skin == GameSkin.classic) {
        _text(
            canvas,
            (strings?.touchToStart ?? 'TOUCH TO START'),
            Offset(gameEngine.width ~/ 2 - 225,
                (gameEngine.height * float32(0.9)).toInt().toDouble()),
            60,
            Color.fromARGB(gameEngine.startAlpha.toInt(), 255, 255, 255));
      } else {
        _sceneText(
            canvas,
            (strings?.holdToStart ?? 'HOLD TO START'),
            Offset(gameEngine.width / 2, gameEngine.height * .9),
            44,
            GameConstants.atomColor
                .withValues(alpha: gameEngine.startAlpha / 255),
            center: true);
      }
    }
    canvas.restore();
  }

  void _pickupMarker(Canvas canvas, Offset position, double radius) {
    final alpha = reduceMotion
        ? .75
        : .7 + .15 * math.cos(gameEngine.gameTime * math.pi * 2 / 1.2);
    final paint = Paint()
      ..color = const Color(0xFFD9BD7C).withValues(alpha: alpha)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final edge = radius * .96;
    final length = radius * .24;
    for (final x in [-1.0, 1.0]) {
      for (final y in [-1.0, 1.0]) {
        final corner = position + Offset(x * edge, y * edge);
        canvas.drawPath(
            Path()
              ..moveTo(corner.dx - x * length, corner.dy)
              ..lineTo(corner.dx, corner.dy)
              ..lineTo(corner.dx, corner.dy - y * length),
            paint);
      }
    }
  }

  void _motionFeedback(Canvas canvas) {
    final visual = feedback;
    if (visual == null) return;
    final trail = visual.trail;
    for (var i = 1; i < trail.length; i++) {
      final age = gameEngine.gameTime - trail[i].time;
      final opacity = (1 - age / .18).clamp(0.0, 1.0).toDouble();
      canvas.drawLine(
          trail[i - 1].position,
          trail[i].position,
          Paint()
            ..color =
                GameConstants.normalAccent.withValues(alpha: opacity * .55)
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 6);
    }
    final collection = visual.collection;
    if (collection != null) {
      final progress = ((gameEngine.gameTime - collection.time) / .55)
          .clamp(0.0, 1.0)
          .toDouble();
      final opacity = 1 - progress;
      canvas.drawCircle(
          collection.position,
          40 + progress * 45,
          Paint()
            ..color =
                GameConstants.normalAccent.withValues(alpha: opacity * .85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4 * opacity + 1);
      _sceneText(
          canvas,
          '+1',
          collection.position - Offset(0, 48 + progress * 40),
          36,
          GameConstants.atomColor.withValues(alpha: opacity),
          center: true);
    }
    final hit = visual.hit;
    if (hit != null) {
      final progress =
          ((gameEngine.gameTime - hit.time) / .35).clamp(0.0, 1.0).toDouble();
      canvas.drawCircle(
          hit.position,
          32 + progress * 48,
          Paint()
            ..color =
                GameConstants.photonColor.withValues(alpha: (1 - progress) * .8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4);
    }
  }

  void _themedHud(Canvas canvas, Color accent) {
    _health(canvas, accent);
    _sceneText(canvas, '${gameEngine.score}', Offset(gameEngine.width / 2, 210),
        104, GameConstants.atomColor,
        center: true);
  }

  void _sceneText(Canvas canvas, String value, Offset baseline, double fontSize,
      Color color,
      {bool center = false}) {
    final text = TextPainter(
      text: TextSpan(
          text: value,
          style: TextStyle(
              color: color,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              fontSize: fontSize,
              height: 1)),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
    final ascent =
        text.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    text.paint(canvas, baseline - Offset(center ? text.width / 2 : 0, ascent));
    text.dispose();
  }

  void _health(Canvas canvas, Color accent) {
    _hudLabel(
        canvas,
        gameEngine.hardcore
            ? (strings?.hardcore.toUpperCase() ?? 'HARDCORE')
            : (strings?.normal.toUpperCase() ?? 'NORMAL'),
        const Offset(34, 31),
        accent);
    _hudLabel(
        canvas,
        gameEngine.hardcore
            ? (strings?.oneHitLabel ?? 'ONE HIT')
            : (strings?.health ?? 'HEALTH'),
        Offset(gameEngine.width - 34, 31),
        GameConstants.quietColor,
        right: true);
    final rail = Rect.fromLTRB(34, 50, gameEngine.width - 34, 74);
    final shape = BeveledRectangleBorder(borderRadius: BorderRadius.circular(6))
        .getOuterPath(rail);
    canvas.drawPath(shape,
        Paint()..color = GameConstants.quietColor.withValues(alpha: .13));
    canvas.save();
    canvas.clipPath(shape);
    canvas.drawRect(
        Rect.fromLTWH(rail.left, rail.top,
            rail.width * gameEngine.health.clamp(0, 100) / 100, rail.height),
        Paint()..color = accent);
    canvas.restore();
    canvas.drawPath(
        shape,
        Paint()
          ..color = GameConstants.quietColor.withValues(alpha: .6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  void _hudLabel(Canvas canvas, String value, Offset baseline, Color color,
      {bool right = false}) {
    final text = TextPainter(
      text: TextSpan(
          text: value,
          style: TextStyle(
              color: color,
              fontFamily: 'Roboto',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: 3)),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
    final ascent =
        text.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    text.paint(canvas, baseline - Offset(right ? text.width : 0, ascent));
    text.dispose();
  }

  void _text(Canvas canvas, String value, Offset baseline, double fontSize,
      Color color) {
    final stamp = textCache?[OriginalTextSpec(value, fontSize,
        canvas: true,
        color: color == Colors.black ? Colors.black : Colors.white)];
    if (stamp != null) {
      stamp.paint(canvas, baseline,
          alpha: color.a == 1 ? 255 : (color.a * 255).round());
      return;
    }
    final painter = TextPainter(
      text: TextSpan(
          text: value,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w400,
            height: 1,
          )),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
    final ascent =
        painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    painter.paint(canvas, baseline - Offset(0, ascent));
    painter.dispose();
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}
