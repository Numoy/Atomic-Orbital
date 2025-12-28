import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:atomic_orbital/game/game_screen.dart';
import 'package:atomic_orbital/services/audio_service.dart';
import 'package:atomic_orbital/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize services
  await SettingsService.initialize();
  await AudioService.initialize();
  
  runApp(const AtomicOrbitalApp());
}

class AtomicOrbitalApp extends StatelessWidget {
  const AtomicOrbitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atomic Orbital',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
} 