import 'package:atomic_orbital/l10n/strings.dart';
import 'package:atomic_orbital/game/game_skin.dart';
import 'package:atomic_orbital/game/arcade_style.dart';
import 'package:atomic_orbital/game/world_backdrop.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SkinShop extends StatefulWidget {
  const SkinShop({super.key});
  @override
  State<SkinShop> createState() => _SkinShopState();
}

class _SkinShopState extends State<SkinShop>
    with SingleTickerProviderStateMixin {
  bool _busy = false;
  String? _error;
  late GameSkin _preview;
  late final PageController _pages;
  late final _motion =
      AnimationController(vsync: this, duration: const Duration(seconds: 8));

  @override
  void initState() {
    super.initState();
    final equipped = SettingsService.instance.selectedSkin;
    _preview = equipped == GameSkin.classic ? GameSkin.cowAbduction : equipped;
    _pages = PageController(initialPage: _preview.index);
  }

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
    _pages.dispose();
    super.dispose();
  }

  void _browse(GameSkin skin) {
    if (!_busy) {
      setState(() {
        _preview = skin;
        _error = null;
      });
      _pages.jumpToPage(skin.index);
    }
  }

  void _step(int direction) => _browse(
      GameSkin.values[(_preview.index + direction) % GameSkin.values.length]);

  Future<void> _choose(GameSkin skin) async {
    if (_busy) return;
    _pages.jumpToPage(skin.index);
    setState(() {
      _busy = true;
      _error = null;
    });
    final settings = SettingsService.instance;
    try {
      if (settings.ownsSkin(skin)) {
        await settings.selectSkin(skin);
      } else if (!settings.meetsSkinRequirement(skin)) {
        if (mounted) {
          setState(() => _error = context.l10n.requiresAchievement(
              context.l10n.achievementTitle(skin.requiredAchievementId!)));
        }
      } else if (!await settings.buySkin(skin)) {
        if (mounted) {
          setState(() => _error = context.l10n.collectMore);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.l10n.walletFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;
    return Scaffold(
      key: const ValueKey('skinShop'),
      backgroundColor: ArcadePalette.ink,
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _step(-1),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () => _step(1),
        },
        child: Focus(
          autofocus: true,
          child: FocusTraversalGroup(
            child: ListenableBuilder(
              listenable: settings,
              builder: (context, _) => CustomPaint(
                painter: _preview == GameSkin.classic
                    ? const SpaceStars()
                    : WorldBackdrop(skin: _preview, motion: _motion),
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: Column(children: [
                        _header(settings),
                        Expanded(
                          child: LayoutBuilder(builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 760;
                            final artHeight =
                                (constraints.maxHeight * (wide ? .82 : .42))
                                    .clamp(160.0, wide ? 500.0 : 320.0);
                            return SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    minHeight: (constraints.maxHeight - 24)
                                        .clamp(0, double.infinity)),
                                child: wide
                                    ? Row(children: [
                                        Expanded(
                                            flex: 6, child: _art(artHeight)),
                                        const SizedBox(width: 24),
                                        Expanded(
                                            flex: 5, child: _details(settings)),
                                      ])
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _art(artHeight),
                                          const SizedBox(height: 6),
                                          _details(settings),
                                        ],
                                      ),
                              ),
                            );
                          }),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(SettingsService settings) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(children: [
          BackButton(
              color: ArcadePalette.paper,
              onPressed: () => Navigator.maybePop(context)),
          Expanded(
            child: Semantics(
              liveRegion: true,
              label: settings.walletFailure == null
                  ? context.l10n.fluxBalance(settings.stardust)
                  : context.l10n.walletUnavailable,
              excludeSemantics: true,
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const StarMark(size: 21),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                      settings.walletFailure == null
                          ? '${settings.stardust}'
                          : '—',
                      key: const ValueKey('stardustBalance'),
                      style: const TextStyle(
                          color: ArcadePalette.paper,
                          fontSize: 17,
                          fontWeight: FontWeight.w600)),
                ),
                if (MediaQuery.sizeOf(context).width >= 360) ...[
                  const SizedBox(width: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ArcadePalette.panel.withValues(alpha: .85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ArcadePalette.edge),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.public_rounded,
                          size: 13, color: ArcadePalette.ice),
                      const SizedBox(width: 5),
                      Text(
                        '${settings.ownedSkinCount}/${GameSkin.values.length}',
                        key: const ValueKey('ownedWorldsBadge'),
                        style: const TextStyle(
                            color: ArcadePalette.quiet,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ),
                ],
              ]),
            ),
          ),
          IconButton(
            key: const ValueKey('shopInfo'),
            onPressed: _showInfo,
            tooltip: context.l10n.fieldGuide,
            color: ArcadePalette.quiet,
            icon: const Icon(Icons.info_outline_rounded, size: 22),
          ),
        ]),
      );

  Widget _art(double height) => SizedBox(
        key: const ValueKey('worldPreview'),
        height: height,
        child: Stack(children: [
          PageView.builder(
            key: const ValueKey('worldPager'),
            controller: _pages,
            itemCount: GameSkin.values.length,
            physics: _busy ? const NeverScrollableScrollPhysics() : null,
            onPageChanged: (index) {
              if (!_busy) {
                setState(() {
                  _preview = GameSkin.values[index];
                  _error = null;
                });
              }
            },
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: ExcludeSemantics(
                child: CustomPaint(
                  key: ValueKey('world-${GameSkin.values[index].id}'),
                  painter: SkinPreview(
                      skin: GameSkin.values[index],
                      hero: true,
                      motion: _motion),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              key: const ValueKey('previousWorld'),
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              onPressed: _busy ? null : () => _step(-1),
              tooltip: context.l10n.previousWorld,
              color: ArcadePalette.quiet,
              icon: const Icon(Icons.chevron_left_rounded, size: 26),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              key: const ValueKey('nextWorld'),
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              onPressed: _busy ? null : () => _step(1),
              tooltip: context.l10n.nextWorld,
              color: ArcadePalette.quiet,
              icon: const Icon(Icons.chevron_right_rounded, size: 26),
            ),
          ),
        ]),
      );

  Widget _details(SettingsService settings) {
    final owned = settings.ownsSkin(_preview);
    final equipped = settings.selectedSkin == _preview;
    final meetsRequirement = settings.meetsSkinRequirement(_preview);
    final affordable = settings.stardust >= _preview.price;
    final available = !_busy && settings.walletFailure == null;
    final canChoose =
        available && !equipped && (owned || (meetsRequirement && affordable));
    final label = _busy
        ? context.l10n.saving
        : equipped
            ? context.l10n.equipped
            : owned
                ? context.l10n.useWorld
                : context.l10n.unlockPrice(_preview.price);
    final bestInWorld = settings.worldBest(_preview);
    final readyBase =
        equipped ? context.l10n.equippedReady : context.l10n.worldReady;
    final readyText = bestInWorld > 0
        ? '$readyBase · ${context.l10n.bestLabel(bestInWorld)}'
        : readyBase;
    final statusText = settings.walletFailure != null
        ? ''
        : owned
            ? readyText
            : !meetsRequirement
                ? context.l10n.requiresAchievement(context.l10n
                    .achievementTitle(_preview.requiredAchievementId!))
                : !affordable
                    ? context.l10n.moreFlux(_preview.price - settings.stardust)
                    : '';
    return Column(children: [
      ExcludeSemantics(
        child: _steadyText(
          context.l10n.worldTier('${_preview.tier}'),
          [for (var t = 0; t <= 4; t++) context.l10n.worldTier('$t')],
          style: TextStyle(
            color: _preview.accent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            height: 1.2,
          ),
        ),
      ),
      const SizedBox(height: 4),
      Semantics(
        header: true,
        liveRegion: true,
        label: '${context.l10n.worldName(_preview.id)}. '
            '${context.l10n.worldDescription(_preview.id)}',
        excludeSemantics: true,
        child: _steadyText(context.l10n.worldName(_preview.id),
            GameSkin.values.map((skin) => context.l10n.worldName(skin.id)),
            textKey: const ValueKey('featuredWorld'),
            style: const TextStyle(
                color: ArcadePalette.paper,
                fontSize: 25,
                fontWeight: FontWeight.w700,
                height: 1.2)),
      ),
      const SizedBox(height: 4),
      ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: _steadyText(
            context.l10n.worldDescription(_preview.id),
            GameSkin.values
                .map((skin) => context.l10n.worldDescription(skin.id)),
            style: const TextStyle(
                color: ArcadePalette.quiet, fontSize: 12, height: 1.35),
          ),
        ),
      ),
      const SizedBox(height: 6),
      ExcludeSemantics(
        child: SizedBox(
          key: const ValueKey('worldPageIndicators'),
          height: 22,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (final skin in GameSkin.values)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: skin == _preview
                        ? skin.accent
                        : settings.ownsSkin(skin)
                            ? ArcadePalette.paper.withValues(alpha: .65)
                            : ArcadePalette.quiet.withValues(alpha: .28),
                  ),
                ),
              ),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Semantics(
          selected: equipped,
          button: true,
          enabled: canChoose,
          onTap: canChoose ? () => _choose(_preview) : null,
          label: '${context.l10n.worldName(_preview.id)} · $label',
          excludeSemantics: true,
          child: FilledButton.icon(
            key: ValueKey('choose-${_preview.id}'),
            onPressed: canChoose ? () => _choose(_preview) : null,
            icon: Icon(
                equipped
                    ? Icons.check_rounded
                    : owned
                        ? Icons.play_arrow_rounded
                        : meetsRequirement
                            ? Icons.lock_open_rounded
                            : Icons.lock_outline_rounded,
                size: 18),
            label: _steadyText(label, [
              context.l10n.saving,
              context.l10n.equipped,
              context.l10n.useWorld,
              for (final skin in GameSkin.values)
                context.l10n.unlockPrice(skin.price),
            ]),
            style: FilledButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                backgroundColor: _preview.accent,
                foregroundColor: ArcadePalette.ink,
                disabledBackgroundColor: _preview.accent.withValues(alpha: .10),
                disabledForegroundColor:
                    equipped ? _preview.accent : ArcadePalette.quiet,
                textStyle: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24))),
          ),
        ),
      ),
      const SizedBox(height: 10),
      _steadyText(
          statusText,
          [
            context.l10n.walletUnavailable,
            context.l10n.equippedReady,
            context.l10n.worldReady,
            for (final skin in GameSkin.values) ...[
              if (settings.worldBest(skin) > 0) ...[
                '${context.l10n.equippedReady} · ${context.l10n.bestLabel(settings.worldBest(skin))}',
                '${context.l10n.worldReady} · ${context.l10n.bestLabel(settings.worldBest(skin))}',
              ],
              context.l10n.moreFlux(
                  (skin.price - settings.stardust).clamp(0, skin.price)),
              if (skin.requiredAchievementId != null)
                context.l10n.requiresAchievement(context.l10n
                    .achievementTitle(skin.requiredAchievementId!)),
            ],
          ],
          style: TextStyle(
              color: !owned && !meetsRequirement
                  ? ArcadePalette.gold
                  : ArcadePalette.quiet,
              fontSize: 12,
              height: 1.4)),
      if (settings.walletFailure != null || _error != null) ...[
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Text(
              settings.walletFailure != null
                  ? context.l10n.walletUnavailable
                  : _error!,
              key: const ValueKey('shopError'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFFFA09D), height: 1.5)),
        ),
      ],
    ]);
  }

  Widget _steadyText(String text, Iterable<String> alternatives,
          {TextStyle? style, Key? textKey}) =>
      Stack(
        alignment: Alignment.center,
        children: [
          for (final value in {text, ...alternatives})
            Visibility(
              visible: value == text,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Text(value,
                  key: value == text ? textKey : null,
                  textAlign: TextAlign.center,
                  style: style),
            ),
        ],
      );

  void _showInfo() => showDialog<void>(
      context: context,
      builder: (context) => Dialog(
            backgroundColor: ArcadePalette.ink,
            insetPadding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                    color: ArcadePalette.gold.withValues(alpha: .35))),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: CustomPaint(
                painter: const SpaceStars(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(context.l10n.fieldGuideTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: ArcadePalette.gold,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.5)),
                        const SizedBox(height: 24),
                        const Center(child: StarMark(size: 64)),
                        const SizedBox(height: 12),
                        Text(context.l10n.stars,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: ArcadePalette.paper,
                                fontSize: 32,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(context.l10n.fluxTagline,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: ArcadePalette.quiet, height: 1.5)),
                        const SizedBox(height: 24),
                        _guideRow('01', context.l10n.fluxEarnTitle,
                            context.l10n.fluxEarnHelp),
                        _guideRow('02', context.l10n.fluxSpendTitle,
                            context.l10n.fluxSpendHelp),
                        _guideRow('03', context.l10n.fluxSaveTitle,
                            context.l10n.fluxSaveHelp),
                        const SizedBox(height: 16),
                        FilledButton(
                            onPressed: () => Navigator.pop(context),
                            style: FilledButton.styleFrom(
                                backgroundColor: ArcadePalette.gold,
                                foregroundColor: ArcadePalette.ink,
                                minimumSize: const Size(48, 52),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.all(16),
                                textStyle: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 14,
                                    height: 1.4,
                                    fontWeight: FontWeight.w800)),
                            child: Text(context.l10n.backHangar,
                                textAlign: TextAlign.center)),
                      ]),
                ),
              ),
            ),
          ));

  Widget _guideRow(String number, String title, String description) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(number,
              style: const TextStyle(
                  color: ArcadePalette.gold,
                  fontSize: 12,
                  height: 1.7,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        color: ArcadePalette.paper,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.4)),
                const SizedBox(height: 4),
                Text(description,
                    style: const TextStyle(
                        color: ArcadePalette.quiet, fontSize: 13, height: 1.5)),
              ])),
        ]),
      );
}
