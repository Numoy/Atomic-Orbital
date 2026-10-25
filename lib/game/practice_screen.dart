import 'dart:math';
import 'package:atomic_orbital/game/arcade_style.dart';
import 'package:atomic_orbital/game/game_engine.dart';
import 'package:atomic_orbital/game/game_screen.dart';
import 'package:atomic_orbital/l10n/strings.dart';
import 'package:atomic_orbital/models/components.dart';
import 'package:atomic_orbital/models/vector2d.dart';
import 'package:atomic_orbital/services/audio_service.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});
  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _engine = GameEngine(random: Random(42), practice: true);
  late final Ticker _ticker;
  Duration? _last;
  int _step = 0;
  bool _active = true;
  final _pointers = <int>{};
  final _keys = <LogicalKeyboardKey>{};
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focus.addListener(() {
      if (!_focus.hasPrimaryFocus) _clearInput();
    });
    _engine.startGame();
    _placeTarget(1);
    _ticker = createTicker((time) {
      final last = _last;
      _last = time;
      if (!_active || last == null) return;
      _engine.update(min((time - last).inMicroseconds / 1000000, .1));
      if (_step == 0 && _engine.score == 1) {
        _step = 1;
        _placeTarget(0);
      } else if (_step == 1 && _engine.score == 2) {
        _step = 2;
        _engine.energy.collision.isCollidable = false;
        _clearInput();
        _engine.pauseGame();
        _ticker.stop();
      }
      if (mounted) setState(() {});
    })
      ..start();
  }

  void _placeTarget(int orbit) {
    final player = _engine.player.logic as PlayerLogicComponent;
    final target = _engine.energy.logic as EnergyLogicComponent;
    _engine.energy.collision.isCollidable = true;
    target.onOrbit = orbit;
    target.angle = (player.currentAngle + player.direction * 120) % 360;
    final angle = target.angle * pi / 180;
    final radius = _engine.orbits[orbit].radius;
    _engine.energy.position.setPosition(Vector2D(
      _engine.width / 2 + radius * sin(angle),
      _engine.height / 2 + radius * cos(angle),
    ));
  }

  void _input() {
    if (!_active || _step == 2) return;
    if (_pointers.isNotEmpty || _keys.isNotEmpty) {
      _engine.onTouchDown();
    } else {
      _engine.onTouchUp();
    }
    setState(() {});
  }

  void _clearInput() {
    _pointers.clear();
    _keys.clear();
    _engine.onTouchCancel();
  }

  void _finish() {
    SettingsService.instance.setOption('tutorial', true);
    Navigator.of(context).pop();
  }

  @override
  void didChangeMetrics() => _clearInput();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _last = null;
    _clearInput();
    if (_active && _step < 2) {
      _engine.resumeGame();
      AudioService.instance.playBackgroundMusic();
    } else {
      _engine.pauseGame();
      AudioService.instance.pauseBackgroundMusic();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focus.dispose();
    _ticker.dispose();
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final prompts = [l.practiceHold, l.practiceRelease, l.practiceDone];
    final help = [
      l.practiceHoldHelp,
      l.practiceReleaseHelp,
      l.practiceDoneHelp
    ];
    final instruction = Semantics(
      liveRegion: true,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(prompts[_step],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(help[_step],
            textAlign: TextAlign.center,
            style: const TextStyle(color: ArcadePalette.quiet, height: 1.4)),
      ]),
    );
    final touching = (_engine.player.logic as PlayerLogicComponent).isTouching;
    final feedback = Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(
          _step == 2
              ? Icons.check_rounded
              : touching
                  ? Icons.touch_app_rounded
                  : Icons.touch_app_outlined,
          color: ArcadePalette.ice,
          size: 28),
      const SizedBox(height: 8),
      Text(
          _step == 2
              ? l.practiceDoneFeedback
              : touching
                  ? l.practiceHolding
                  : _engine.state == GameState.ready
                      ? l.practiceTouchHint
                      : l.practiceReleased,
          textAlign: TextAlign.center,
          style: const TextStyle(color: ArcadePalette.ice)),
      if (_step < 2) ...[
        const SizedBox(height: 8),
        Text(l.practiceAnywhereHelp,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ArcadePalette.quiet, height: 1.4)),
      ],
    ]);
    final arena = Semantics(
        label: l.holdLabel,
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: AspectRatio(
                aspectRatio: 1,
                child: CustomPaint(
                    key: const ValueKey('practiceArena'),
                    painter: _PracticePainter(_engine, _step, l)))));
    return Scaffold(
      backgroundColor: ArcadePalette.ink,
      body: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: (node, event) {
          if (!node.hasPrimaryFocus ||
              _step == 2 ||
              (event.logicalKey != LogicalKeyboardKey.space &&
                  event.logicalKey != LogicalKeyboardKey.enter)) {
            return KeyEventResult.ignored;
          }
          if (event is KeyDownEvent) _keys.add(event.logicalKey);
          if (event is KeyUpEvent) _keys.remove(event.logicalKey);
          _input();
          return KeyEventResult.handled;
        },
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            if (!_active || _step == 2) return;
            _focus.requestFocus();
            _pointers.add(e.pointer);
            _input();
          },
          onPointerUp: (e) {
            _pointers.remove(e.pointer);
            _input();
          },
          onPointerCancel: (e) {
            _pointers.remove(e.pointer);
            _input();
          },
          child: SafeArea(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              SizedBox(
                  width: double.infinity,
                  child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      children: [
                        Text('${l.practiceTitle} · ${min(_step + 1, 2)} / 2',
                            style: const TextStyle(color: ArcadePalette.quiet)),
                        if (_step < 2)
                          TextButton(
                              key: const ValueKey('skipPractice'),
                              onPressed: _finish,
                              style: TextButton.styleFrom(
                                  minimumSize: const Size(64, 48)),
                              child: Text(l.skip, textAlign: TextAlign.center)),
                      ])),
              const SizedBox(height: 16),
              Expanded(child: LayoutBuilder(builder: (context, constraints) {
                if (constraints.maxWidth >= 600 ||
                    constraints.maxWidth > constraints.maxHeight * 1.4) {
                  return Row(children: [
                    Expanded(
                        child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  instruction,
                                  const SizedBox(height: 32),
                                  feedback
                                ]))),
                    Expanded(child: Center(child: arena)),
                  ]);
                }
                return SingleChildScrollView(
                    child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              instruction,
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 24),
                                  child: arena),
                              feedback,
                            ])));
              })),
              if (_step == 2) ...[
                const SizedBox(height: 16),
                Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                                key: const ValueKey('finishPractice'),
                                onPressed: _finish,
                                style: FilledButton.styleFrom(
                                    minimumSize: const Size(200, 52)),
                                child: Text(l.gotIt,
                                    textAlign: TextAlign.center))))),
              ],
            ]),
          )),
        ),
      ),
    );
  }
}

class _PracticePainter extends GamePainter {
  const _PracticePainter(super.gameEngine, this.step, AppLocalizations strings)
      : super(strings: strings);
  final int step;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / gameEngine.width);
    canvas.translate(0, (gameEngine.width - gameEngine.height) / 2);
    super.paint(canvas, Size(gameEngine.width.toDouble(), 1794));
    if (step < 2) {
      final orbit = gameEngine.orbits[step == 0 ? 1 : 0];
      canvas.drawCircle(
          Offset(gameEngine.atom.position.position.x,
              gameEngine.atom.position.position.y),
          orbit.radius,
          Paint()
            ..color = ArcadePalette.ice.withValues(alpha: .55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4);
      canvas.drawCircle(
          Offset(gameEngine.energy.position.position.x,
              gameEngine.energy.position.position.y),
          gameEngine.energy.size.radius + 18,
          Paint()
            ..color = ArcadePalette.ice.withValues(alpha: .35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
    if (gameEngine.state == GameState.ready) {
      final label = TextPainter(
          text: TextSpan(
              text: strings!.you,
              style: const TextStyle(
                  color: ArcadePalette.ice,
                  fontSize: 34,
                  fontFamily: 'Roboto')),
          textDirection: TextDirection.ltr)
        ..layout();
      label.paint(
          canvas,
          Offset(gameEngine.player.position.position.x - label.width / 2,
              gameEngine.player.position.position.y + 50));
      label.dispose();
    }
    canvas.restore();
  }
}
