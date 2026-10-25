import 'dart:async';

import 'package:atomic_orbital/services/audio_service.dart';
import 'package:atomic_orbital/services/settings_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('iOS startup recovery', () {
    const native = MethodChannel('atomic_orbital/platform');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    late List<String> methods;
    late int loads;
    Completer<void>? hold;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SettingsService.initialize();
      SettingsService.instance.setMuted(false);
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      methods = [];
      loads = 0;
      hold = null;
      messenger.setMockMethodCallHandler(native, (call) async {
        methods.add(call.method);
        if (call.method == 'loadSoundEffects') {
          if (++loads == 1) throw PlatformException(code: 'audio_failed');
          await hold?.future;
        }
        return null;
      });
    });
    tearDown(() async {
      await AudioService.instance.dispose();
      await SettingsService.instance.flushProgress();
      messenger.setMockMethodCallHandler(native, null);
      debugDefaultTargetPlatformOverride = null;
    });

    test(
        'retry after a failed native load is shared and successful loads are idempotent',
        () async {
      await AudioService.initialize();
      expect(AudioService.instance.isAudioAvailable, isFalse);
      hold = Completer<void>();
      final retries = [AudioService.initialize(), AudioService.initialize()];
      await Future<void>.value();
      expect(loads, 2);
      hold!.complete();
      await Future.wait(retries);
      expect(AudioService.instance.isAudioAvailable, isTrue);
      await AudioService.initialize();
      expect(loads, 2);
    });

    test('unmuting retries a failed startup without needing an app restart',
        () async {
      await AudioService.initialize();
      AudioService.instance.setMuted(true);
      AudioService.instance.setMuted(false);
      await AudioService.initialize();
      expect(loads, 2);
      expect(AudioService.instance.isAudioAvailable, isTrue);
      await AudioService.instance.playSoundEffect('collect');
      expect(methods.last, 'playSoundEffect');
    });

    test('starting a run retries effects even with music disabled', () async {
      SettingsService.instance.setOption('music', false);
      await AudioService.initialize();
      await AudioService.instance.playBackgroundMusic();
      expect(loads, 2);
      expect(methods, isNot(contains('playBackgroundMusic')));
      await AudioService.instance.playSoundEffect('hit');
      expect(methods.last, 'playSoundEffect');
    });

    test('pausing while retry is pending prevents a late music start',
        () async {
      await AudioService.initialize();
      hold = Completer<void>();
      final start = AudioService.instance.playBackgroundMusic();
      await Future<void>.value();
      await AudioService.instance.pauseBackgroundMusic();
      hold!.complete();
      await start;
      expect(AudioService.instance.isAudioAvailable, isTrue);
      expect(methods, isNot(contains('playBackgroundMusic')));
    });
  });

  for (final target in [
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.macOS
  ]) {
    test('$target uses supported audio formats and respects mute', () async {
      final android = target == TargetPlatform.android;
      final ios = target == TargetPlatform.iOS;
      final nativeEffects = android || ios;
      SharedPreferences.setMockInitialValues({});
      await SettingsService.initialize();
      debugDefaultTargetPlatformOverride = target;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const native = MethodChannel('atomic_orbital/platform');
      const music = MethodChannel('xyz.luan/audioplayers');
      const global = MethodChannel('xyz.luan/audioplayers.global');
      const globalEvents = MethodChannel('xyz.luan/audioplayers.global/events');
      final calls = <MethodCall>[];
      final globalCalls = <MethodCall>[];
      final musicCalls = <String>[];
      final sources = <String>[];
      final eventChannels = <MethodChannel>[];
      messenger.setMockMethodCallHandler(native, (call) async {
        calls.add(call);
        return null;
      });
      messenger.setMockMethodCallHandler(global, (call) async {
        globalCalls.add(call);
        return null;
      });
      messenger.setMockMethodCallHandler(globalEvents, (_) async => null);
      messenger.setMockMethodCallHandler(music, (call) async {
        musicCalls.add(call.method);
        final arguments = call.arguments as Map;
        final playerId = arguments['playerId'] as String;
        final events = MethodChannel('xyz.luan/audioplayers/events/$playerId');
        if (call.method == 'create') {
          eventChannels.add(events);
          messenger.setMockMethodCallHandler(events, (_) async => null);
        }
        if (call.method == 'setSourceUrl') {
          sources.add(arguments['url'] as String);
          scheduleMicrotask(() {
            ServicesBinding.instance.channelBuffers.push(
              events.name,
              const StandardMethodCodec().encodeSuccessEnvelope({
                'event': 'audio.onPrepared',
                'value': true,
              }),
              (_) {},
            );
          });
        }
        if (call.method == 'getDuration') return 1000;
        if (call.method == 'getCurrentPosition') return 0;
        return null;
      });
      // Avoid filesystem/platform work in the music plugin's asset cache.
      final paths = android
          ? ['audio/bg_music.ogg']
          : ios
              ? <String>[]
              : [
                  'audio/ios/bg_music.m4a',
                  if (!nativeEffects)
                    for (final sound in ['hit', 'collect', 'shoot'])
                      'audio/ios/$sound.wav'
                ];
      for (final path in paths) {
        AudioCache.instance.loadedFiles[path] = Uri.file('/tmp/$path');
      }
      addTearDown(() async {
        await AudioService.instance.dispose();
        for (final channel in [
          native,
          music,
          global,
          globalEvents,
          ...eventChannels
        ]) {
          messenger.setMockMethodCallHandler(channel, null);
        }
        for (final path in paths) {
          AudioCache.instance.loadedFiles.remove(path);
        }
      });

      await AudioService.initialize();
      if (ios) {
        expect(globalCalls, isEmpty,
            reason: 'Native Apple audio owns the session without AVPlayer');
        expect(musicCalls, isEmpty);
        expect(AudioService.instance.isAudioAvailable, isTrue);
      }
      expect(sources, containsAll(paths.map((path) => '/tmp/$path')));
      expect(calls.map((call) => call.method),
          nativeEffects ? ['loadSoundEffects'] : isEmpty);
      await AudioService.instance.playSoundEffect('hit');
      final mutedResumes =
          musicCalls.where((method) => method == 'resume').length;
      expect(mutedResumes, 0);
      AudioService.instance.setMuted(false);
      await AudioService.instance.playSoundEffect('hit');
      await AudioService.instance.playSoundEffect('collect');
      if (nativeEffects) {
        expect(calls.map((call) => call.method),
            ['loadSoundEffects', 'playSoundEffect', 'playSoundEffect']);
        expect(calls[1].arguments, {'name': 'hit'});
        expect(calls[2].arguments, {'name': 'collect'});
      } else {
        expect(calls, isEmpty);
        expect(musicCalls.where((method) => method == 'resume'), hasLength(2));
      }
      expect(musicCalls.where((method) => method == 'create'),
          hasLength(ios ? 0 : (android ? 1 : 4)));
      if (ios) {
        await AudioService.instance.playBackgroundMusic();
        expect(calls.last.method, 'playBackgroundMusic');
        AudioService.instance.setMuted(true);
        await AudioService.instance.playSoundEffect('collect');
        expect(calls.last.method, 'pauseBackgroundMusic');
        expect(calls.last.arguments, {'rewind': false});
        AudioService.instance.setMuted(false);
        await Future<void>.value();
        expect(calls.last.method, 'playBackgroundMusic');
        await AudioService.instance.pauseBackgroundMusic();
        expect(calls.last.arguments, {'rewind': true});
      }
      AudioService.instance.setMuted(true);
      final callsBeforeMutedEffect = musicCalls.length;
      await AudioService.instance.playSoundEffect('collect');
      expect(musicCalls.skip(callsBeforeMutedEffect),
          everyElement(isNot('resume')));
      await AudioService.instance.dispose();
      if (nativeEffects) expect(calls.last.method, 'disposeSoundEffects');
    });
  }
}
