import 'dart:math';

class DailyChallenge {
  DailyChallenge.forDate(DateTime instant)
      : dateUtc = DateTime.utc(
            instant.toUtc().year, instant.toUtc().month, instant.toUtc().day) {
    if (dateUtc.year < 1 || dateUtc.year > 9999) {
      throw RangeError.range(dateUtc.year, 1, 9999, 'year');
    }
  }

  static const rulesVersion = 1;
  static const randomVersion = 1;
  final DateTime dateUtc;

  String get date => dateUtc.toIso8601String().substring(0, 10);
  String get identity => '$date/rules-$rulesVersion/xorshift32-$randomVersion';
  DateTime get resetUtc => dateUtc.add(const Duration(days: 1));
  // The seed mapping is part of xorshift32-1's replay contract.
  Random createRandom() => DailyChallengeRandom(
      (dateUtc.year * 10000 + dateUtc.month * 100 + dateUtc.day) ^ 0x6d2b79f5);
}

/// Xorshift32 (13, 17, 5), with rejection sampling for bounded integers.
class DailyChallengeRandom implements Random {
  DailyChallengeRandom(int seed) : _state = seed {
    if (seed < 1 || seed > 0xffffffff) {
      throw RangeError.range(seed, 1, 0xffffffff, 'seed');
    }
  }

  int _state;

  int _nextWord() {
    _state = (_state ^ (_state << 13)) & 0xffffffff;
    _state = (_state ^ (_state >>> 17)) & 0xffffffff;
    _state = (_state ^ (_state << 5)) & 0xffffffff;
    return _state;
  }

  @override
  int nextInt(int max) {
    if (max < 1 || max > 0x100000000) {
      throw RangeError.range(max, 1, 0x100000000, 'max');
    }
    final limit = 0x100000000 - 0x100000000 % max;
    int value;
    do {
      value = _nextWord();
    } while (value >= limit);
    return value % max;
  }

  @override
  bool nextBool() => nextInt(2) == 1;

  @override
  double nextDouble() => _nextWord() / 0x100000000;
}
