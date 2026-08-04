import 'package:flutter_test/flutter_test.dart';
import 'package:strola_health/core/utils/rolling_week.dart';

void main() {
  // A fixed Monday, so every case below has an unambiguous expected answer.
  final monday = DateTime(2026, 8, 3);

  group(
    'RollingWeek — regression coverage for the fixed-array day-label bug',
    () {
      test('today (last index) always resolves to today\'s real weekday, '
          'not a fixed Sunday slot', () {
        // The bug this guards: several widgets used to label index 6 of a
        // 7-entry rolling window as "Sun" unconditionally. On a Monday, that
        // was wrong every single time except by coincidence.
        expect(RollingWeek.shortLabelForIndex(6, 7, today: monday), 'Mon');
        expect(RollingWeek.letterForIndex(6, 7, today: monday), 'M');
      });

      test('oldest index (0) is 6 days before today', () {
        // Monday - 6 days = Tuesday of the previous week.
        expect(RollingWeek.shortLabelForIndex(0, 7, today: monday), 'Tue');
      });

      test(
        'full 7-day window in order matches a real calendar week ending today',
        () {
          final labels = [
            for (var i = 0; i < 7; i++)
              RollingWeek.shortLabelForIndex(i, 7, today: monday),
          ];
          expect(labels, ['Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Mon']);
        },
      );

      test('works for a 30-day window (monthly views), not just 7', () {
        // Index 29 of 30 is "today" regardless of window length.
        expect(RollingWeek.shortLabelForIndex(29, 30, today: monday), 'Mon');
      });

      test('is correct when today genuinely is Sunday — the one day the old '
          'fixed-array bug accidentally got right', () {
        final sunday = DateTime(2026, 8, 9);
        expect(RollingWeek.shortLabelForIndex(6, 7, today: sunday), 'Sun');
      });

      test('dateForIndex strips time-of-day, so an afternoon "now" still '
          'lands on the correct calendar day', () {
        final mondayAfternoon = DateTime(2026, 8, 3, 15, 42);
        final date = RollingWeek.dateForIndex(6, 7, today: mondayAfternoon);
        expect(date, DateTime(2026, 8, 3));
      });
    },
  );
}
