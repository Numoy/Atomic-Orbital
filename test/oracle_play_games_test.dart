import 'dart:convert';
import 'dart:io';

import 'package:atomic_orbital/services/play_games_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixture = jsonDecode(
    File('test/oracle/release_41_play_games.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final provenance = fixture['provenance'] as Map<String, dynamic>;
  final corrections = provenance['approvedCorrections'] as Map<String, dynamic>;

  for (final scenario in fixture['cases'] as List<dynamic>) {
    test('released Play Games rules: ${scenario['label']}', () {
      // Expected requests come from the unmodified released Java methods.
      // Correct the broken games-board ID/count and use the replacement score boards.
      final expected = <Map<String, Object>>[];
      for (final original in scenario['events'] as List<dynamic>) {
        final arguments =
            Map<String, Object>.from(original['arguments'] as Map);
        if (original['method'] == 'submitScore' &&
            arguments['leaderboardId'] == 'gamesPlayed') {
          arguments['leaderboardId'] =
              corrections['gamesPlayedLeaderboard'] as String;
          arguments['score'] = scenario['gamesPlayed'] as int;
        }
        if (arguments['leaderboardId'] case final String id) {
          arguments['leaderboardId'] = PlayGamesService.currentLeaderboard(id);
        }
        expected.add({
          'method': original['method'] as String,
          'arguments': arguments,
        });
      }
      final events = PlayGamesService.eventsForCompletedGame(
        score: scenario['score'] as int,
        hardcore: scenario['hardcore'] as bool,
        previousHighScore: scenario['previousHighScore'] as int,
        gamesPlayed: scenario['gamesPlayed'] as int,
        totalPoints: scenario['totalPoints'] as int,
      );
      expect(
        events.map((event) => {
              'method': event.method,
              'arguments': event.arguments,
            }),
        expected,
      );
    });
  }
}
