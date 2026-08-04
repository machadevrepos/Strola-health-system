import 'package:flutter_test/flutter_test.dart';
import 'package:strola_health/core/utils/streak.dart';

void main() {
  group('calcStreak', () {
    test(
      'today alone meeting goal is a 1-day streak, not 0 '
      '(bug #1: hitting goal today didn\'t move the streak off 0)',
      () {
        final weekly = [0, 0, 0, 0, 0, 0, 27459];
        expect(calcStreak(weekly, 10000), 1);
      },
    );

    test(
      'today not yet meeting goal does not reset an otherwise-intact streak '
      '(bug #2: a new day starting mid-progress dropped the streak to 0 '
      'instead of still counting yesterday and earlier)',
      () {
        final weekly = [12000, 12000, 12000, 12000, 12000, 12000, 1483];
        expect(calcStreak(weekly, 10000), 6);
      },
    );

    test(
      'today not meeting goal AND yesterday not meeting goal is a genuine '
      '0-day streak',
      () {
        final weekly = [12000, 12000, 12000, 12000, 12000, 500, 1483];
        expect(calcStreak(weekly, 10000), 0);
      },
    );

    test('a full 7-day streak counts all 7, including today', () {
      final weekly = [11000, 11000, 11000, 11000, 11000, 11000, 11000];
      expect(calcStreak([...weekly], 10000), 7);
    });

    test(
      'a gap earlier in the week only counts the run ending today, '
      'not the earlier run before the gap',
      () {
        final weekly = [11000, 11000, 11000, 500, 11000, 11000, 11000];
        expect(calcStreak(weekly, 10000), 3);
      },
    );

    test(
      'a gap earlier in the week, with today still in progress, counts '
      'the run ending yesterday',
      () {
        final weekly = [11000, 500, 11000, 11000, 11000, 11000, 1483];
        expect(calcStreak(weekly, 10000), 4);
      },
    );

    test('empty history is a 0-day streak', () {
      expect(calcStreak(<int>[], 10000), 0);
    });

    test('a single-entry history where today met goal is a 1-day streak', () {
      expect(calcStreak([11000], 10000), 1);
    });

    test(
      'a single-entry history where today has not met goal yet is a 0-day '
      'streak (no earlier day to fall back to)',
      () {
        expect(calcStreak([500], 10000), 0);
      },
    );
  });
}
