import 'dart:convert';
import 'dart:io';

import 'package:atomic_orbital/l10n/strings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (language, singular, plural) in [
    ('en', 'Star', 'Stars'),
    ('de', 'Stern', 'Sterne'),
  ]) {
    test('$language uses Stars consistently, including singular rewards',
        () async {
      final l = await AppLocalizations.delegate.load(Locale(language));
      expect(l.stars, plural);
      expect(l.fluxBalance(0), '0 $plural');
      expect(l.fluxBalance(1), '1 $singular');
      expect(l.fluxBalance(2), '2 $plural');
      expect(l.earnedFlux(1), contains('+1 $singular '));
      expect(l.pendingFlux(1), contains('+1 $singular ·'));
      expect(l.earnedFlux(2), contains('+2 $plural '));
      expect(l.pendingFlux(2), contains('+2 $plural ·'));
      expect(
          l.moreFlux(1),
          language == 'en'
              ? '1 more Star to unlock'
              : 'Noch 1 Stern zum Freischalten');
      final catalog =
          jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync())
              as Map<String, dynamic>;
      expect(
          catalog.values.whereType<String>().where((s) => s.contains('Flux')),
          isEmpty);
    });
  }
}
