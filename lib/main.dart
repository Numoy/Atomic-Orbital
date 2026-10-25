import 'dart:async';
import 'package:atomic_orbital/l10n/strings.dart';

import 'package:flutter/material.dart';
import 'package:atomic_orbital/game/game_screen.dart';
import 'package:atomic_orbital/services/audio_service.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:atomic_orbital/services/play_games_service.dart';
import 'package:atomic_orbital/services/daily_challenge_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await SettingsService.initialize();
  await DailyChallengeService.instance.initialize();
  await AudioService.initialize();

  runApp(const AtomicOrbitalApp());
  unawaited(PlayGamesService.instance.initialize());
}

class AtomicOrbitalApp extends StatelessWidget {
  const AtomicOrbitalApp({super.key});
  static final themeData = ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF9BE9EF),
      onPrimary: Color(0xFF080D14),
      secondary: Color(0xFFFF8674),
      surface: Color(0xFF080D14),
      onSurface: Color(0xFFF3F5F3),
    ),
    scaffoldBackgroundColor: const Color(0xFF080D14),
    appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF080D14), foregroundColor: Color(0xFFF3F5F3)),
    cardTheme: CardThemeData(
        color: const Color(0xFF101A26),
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF344353)))),
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
        valueListenable: SettingsService.instance.languageListenable,
        builder: (context, language, _) => MaterialApp(
              title: 'Atomic Orbital',
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: language == 'system' ? null : Locale(language),
              theme: themeData,
              home: const GameScreen(introduce: true, cosmeticsEnabled: true),
              debugShowCheckedModeBanner: false,
            ));
  }
}
