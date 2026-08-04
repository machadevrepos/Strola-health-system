import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strola_health/presentation/widgets/app_error_fallback.dart';

void main() {
  testWidgets(
    'AppErrorFallback renders an on-brand message instead of the default '
    'red screen, for any widget-build error',
    (tester) async {
      final details = FlutterErrorDetails(
        exception: StateError('something broke during build'),
      );

      await tester.pumpWidget(
        MaterialApp(home: AppErrorFallback(details: details)),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      // Never shows Flutter's own crash chrome/wording on top of ours.
      expect(find.textContaining('Exception caught by'), findsNothing);
    },
  );

  testWidgets('AppErrorFallback never throws while building itself', (
    tester,
  ) async {
    // A fallback that itself throws while rendering would defeat the whole
    // point (ErrorWidget.builder recursing into another error). Regression
    // guard: pumping it must complete cleanly for a variety of exception
    // shapes, including one with no message at all.
    for (final exception in <Object>[
      Exception(),
      StateError(''),
      'a bare string thrown as an error',
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: AppErrorFallback(
            details: FlutterErrorDetails(exception: exception),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'AppErrorFallback fits inside a small fixed-height slot without '
    "overflowing (regression: a broken route map's 200px card produced a "
    "RenderFlex 'BOTTOM OVERFLOWED' error on top of the original crash)",
    (tester) async {
      final details = FlutterErrorDetails(
        exception: StateError('Unsupported operation: Infinity or NaN toInt'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: AppErrorFallback(details: details),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Something went wrong'), findsOneWidget);
    },
  );
}
