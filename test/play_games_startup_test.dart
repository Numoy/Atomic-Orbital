import 'dart:io';

import 'package:atomic_orbital/services/play_games_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'native Application gates early SDK startup with the actual Dart preference',
      () async {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(
        RegExp(r'<application[^>]*android:name=".AtomicOrbitalApplication"')
            .hasMatch(manifest),
        isTrue);
    expect(
        RegExp(r'PlayGamesInitProvider"[^>]*android:enabled="false"')
            .hasMatch(manifest),
        isTrue);
    final source = File(
            'android/app/src/main/kotlin/de/numpy/orbital/atomic_orbital/AtomicOrbitalApplication.kt')
        .readAsStringSync();
    expect(source, contains('override fun onCreate()'));
    expect(
        source,
        contains(
            'getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)'));
    expect(source, contains('LegacySettingsMigration.migrate('));
    expect(source, contains('automaticPlayGamesAllowed = allowPlayGames'));
    expect(
        source,
        matches(RegExp(
            r'if \(allowPlayGames\) \{\s*PlayGamesSdk.initialize\(this\)')));
    final migration = File(
            'android/app/src/main/kotlin/de/numpy/orbital/atomic_orbital/LegacySettingsMigration.kt')
        .readAsStringSync();
    final key = RegExp(r'const val DISCONNECTED = "([^"]+)"')
        .firstMatch(migration)
        ?.group(1);
    expect(key, startsWith('flutter.'));
    final bridge = File(
            'android/app/src/main/kotlin/de/numpy/orbital/atomic_orbital/PlayGamesBridge.kt')
        .readAsStringSync();
    expect(bridge,
        contains('!AtomicOrbitalApplication.automaticPlayGamesAllowed'));
    expect(bridge, contains('call.method != "signIn"'));
    SharedPreferences.setMockInitialValues({});
    final service = PlayGamesService();
    await service.disconnect();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(key!.substring('flutter.'.length)), isTrue);
    service.dispose();
  });
}
