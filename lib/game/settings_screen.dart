import 'dart:async';
import 'dart:convert';
import 'package:atomic_orbital/game/arcade_style.dart';
import 'package:atomic_orbital/game/progress_screen.dart';
import 'package:atomic_orbital/l10n/strings.dart';
import 'package:atomic_orbital/services/audio_service.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:atomic_orbital/services/save_backup_service.dart';
import 'package:atomic_orbital/models/achievement.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen(
      {super.key, required this.onPractice, this.onSaveRestored});
  final VoidCallback onPractice;
  final VoidCallback? onSaveRestored;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const platform = MethodChannel('atomic_orbital/platform');
  late final Future<Map<String, Object?>?> _appInfo;
  bool _backupBusy = false;
  @override
  void initState() {
    super.initState();
    _appInfo = platform
        .invokeMapMethod<String, Object?>('appInfo')
        .catchError((Object _) => <String, Object?>{});
  }

  Future<void> _open(String path) async {
    try {
      await platform.invokeMethod<void>(
          'openUrl', {'url': 'https://marvinmaerz.com/atomic-orbital/$path/'});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.actionFailed)));
      }
    }
  }

  Future<void> _backup(String action) async {
    if (_backupBusy) return;
    setState(() => _backupBusy = true);
    try {
      final s = SettingsService.instance;
      if (action == 'export') {
        if (await SaveBackup.exportFile(await s.exportSave()) && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.backupExported)));
        }
        return;
      }
      final contents =
          action == 'previous' ? s.previousSave : await SaveBackup.importFile();
      if (contents == null || !mounted) return;
      final save = SaveBackup.decode(contents);
      final stats = save['progress']['stats'] as Map<String, dynamic>;
      final wallet = save['wallet'] as Map<String, dynamic>;
      final l = context.l10n;
      int dailyCount(Object? raw) => raw is String
          ? ((jsonDecode(raw) as Map<String, dynamic>)['records'] as Map).length
          : 0;
      final prefs = await s
          .exportSave()
          .then<Map<String, dynamic>?>(SaveBackup.decode)
          .catchError((Object _) => null);
      if (!mounted) return;
      final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(l.backupPreviewTitle),
                scrollable: true,
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.backupReplaceWarning),
                      for (final row in <(String, Object, Object)>[
                        (l.normalBest, s.highScore, stats['high_score']),
                        (
                          l.hardcoreBest,
                          s.hardcoreHighScore,
                          stats['hardcore_high_score']
                        ),
                        (l.completedRuns, s.gamesPlayed, stats['games_played']),
                        (l.totalPoints, s.totalPoints, stats['total_points']),
                        (
                          l.achievements,
                          s.unlockedCount,
                          OrbitalAchievement.all
                              .where((a) =>
                                  (save['progress']['milestones'][a.id]
                                          as int? ??
                                      0) >=
                                  a.target)
                              .length
                        ),
                        (
                          l.backupStoredItems,
                          (prefs?['wallet']['owned'] as List?)?.length ?? 0,
                          (wallet['owned'] as List).toSet().length
                        ),
                        (l.backupStars, s.stardust, wallet['stardust']),
                        (
                          l.dailyChallenge,
                          dailyCount(prefs?['daily']),
                          dailyCount(save['daily'])
                        ),
                        (
                          l.language,
                          s.language,
                          save['progress']['options']['language']
                        ),
                      ])
                        Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                                '${row.$1}\n${l.backupCurrent}: ${row.$2}\n${l.backupIncoming}: ${row.$3}')),
                    ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l.cancel)),
                  FilledButton(
                      key: const ValueKey('confirmSaveImport'),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l.backupConfirm))
                ],
              ));
      if (accepted != true || !mounted) return;
      await s.importSave(contents);
      AudioService.instance.setMuted(s.isMuted);
      AudioService.instance.refreshMusic();
      widget.onSaveRestored?.call();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.backupImported)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(SettingsService.instance.backupRecoveryFailed
                ? context.l10n.backupRecoveryFailed
                : error is FormatException
                    ? context.l10n.backupInvalid
                    : context.l10n.backupFailed)));
      }
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        final s = SettingsService.instance;
        final l = context.l10n;
        return Scaffold(
          appBar: AppBar(title: Text(l.settings)),
          body: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: AbsorbPointer(
                      absorbing: _backupBusy,
                      child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(s.isMuted ? l.soundOff : l.soundOn),
                                value: !s.isMuted,
                                onChanged: (enabled) =>
                                    AudioService.instance.setMuted(!enabled)),
                            SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(l.music),
                                value: s.musicEnabled,
                                onChanged: (enabled) {
                                  s.setOption('music', enabled);
                                  AudioService.instance.refreshMusic();
                                }),
                            SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(l.effects),
                                value: s.effectsEnabled,
                                onChanged: (enabled) {
                                  s.setOption('effects', enabled);
                                  if (enabled) {
                                    AudioService.instance.refreshMusic();
                                  }
                                }),
                            SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(l.haptics),
                                value: s.hapticsEnabled,
                                onChanged: (enabled) {
                                  s.setOption('haptics', enabled);
                                  if (enabled) {
                                    unawaited(HapticFeedback.selectionClick());
                                  }
                                }),
                            const SizedBox(height: 16),
                            const Divider(color: ArcadePalette.edge),
                            DropdownButtonFormField<String>(
                              key: ValueKey('language-${s.language}'),
                              initialValue: s.language,
                              isExpanded: true,
                              decoration:
                                  InputDecoration(labelText: l.language),
                              items: [
                                DropdownMenuItem(
                                    value: 'system',
                                    child: Text(l.systemLanguage)),
                                const DropdownMenuItem(
                                    value: 'en', child: Text('English')),
                                const DropdownMenuItem(
                                    value: 'de', child: Text('Deutsch'))
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  s.setOption('language', value);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(l.saveBackup,
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(l.backupExplanation,
                                style: const TextStyle(
                                    color: ArcadePalette.quiet)),
                            ListTile(
                                key: const ValueKey('exportSave'),
                                contentPadding: EdgeInsets.zero,
                                enabled: !_backupBusy,
                                title: Text(l.exportSave),
                                onTap: () => _backup('export')),
                            ListTile(
                                key: const ValueKey('importSave'),
                                contentPadding: EdgeInsets.zero,
                                enabled: !_backupBusy,
                                title: Text(l.importSave),
                                onTap: () => _backup('import')),
                            if (s.previousSave != null)
                              ListTile(
                                  key: const ValueKey('restorePreviousSave'),
                                  contentPadding: EdgeInsets.zero,
                                  enabled: !_backupBusy,
                                  title: Text(l.restorePreviousSave),
                                  onTap: () => _backup('previous')),
                            if (s.backupRecoveryFailed)
                              Text(l.backupRecoveryFailed),
                            const Divider(color: ArcadePalette.edge),
                            ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(l.practice),
                                onTap: widget.onPractice),
                            ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(l.privacy),
                                onTap: () => _open('privacy')),
                            ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(l.support),
                                onTap: () => _open('support')),
                            ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(l.deleteData),
                                onTap: () => _open('delete-data')),
                            const Divider(color: ArcadePalette.edge),
                            const ConnectionStatus(),
                            const SaveStatus(),
                            const SizedBox(height: 16),
                            Text(l.localProgress,
                                style: const TextStyle(
                                    color: ArcadePalette.quiet, fontSize: 12)),
                            const SizedBox(height: 16),
                            FutureBuilder(
                                future: _appInfo,
                                builder: (context, snapshot) => Text(
                                    '${l.version} ${snapshot.data?["version"] ?? "—"} (${snapshot.data?["build"] ?? "—"})',
                                    style: const TextStyle(
                                        color: ArcadePalette.quiet,
                                        fontSize: 12))),
                          ])))),
        );
      });
}
