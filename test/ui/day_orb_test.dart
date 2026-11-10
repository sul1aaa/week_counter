import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:week_counter/domain/countdown_engine.dart';
import 'package:week_counter/l10n/app_localizations.dart';
import 'package:week_counter/ui/kit/orb.dart';
import 'package:week_counter/ui/theme/tokens.dart';
import 'package:week_counter/ui/widgets/day_orb.dart';

void main() {
  setUpAll(initializeDateFormatting);

  final shift = DayShift(
    start: DateTime(2026, 10, 21, 9),
    end: DateTime(2026, 10, 21, 18),
  );

  Future<void> pump(
    WidgetTester tester,
    DayShift? shift,
    DateTime now, {
    String locale = 'en',
  }) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [Tokens.light]),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: DayOrb(shift: shift, now: now, size: 200),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Orb orb(WidgetTester tester) => tester.widget<Orb>(find.byType(Orb));

  testWidgets('during the shift counts down to its end', (tester) async {
    await pump(tester, shift, DateTime(2026, 10, 21, 13, 30));
    expect(find.bySemanticsLabel('4 hours 30 min'), findsOneWidget);
    expect(find.text('until the end of the shift at 18:00'), findsOneWidget);
    expect(orb(tester).fill, closeTo(0.5, 1e-9));
    expect(orb(tester).mode, OrbMode.work);
    expect(orb(tester).semanticLabel, "50% of today's shift done");
  });

  testWidgets('before the shift shows when it starts', (tester) async {
    await pump(tester, shift, DateTime(2026, 10, 21, 7));
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('your shift starts'), findsOneWidget);
    expect(orb(tester).mode, OrbMode.work);
  });

  testWidgets('after the shift is done for today', (tester) async {
    await pump(tester, shift, DateTime(2026, 10, 21, 19));
    expect(find.text('Done for today'), findsOneWidget);
    expect(find.text('the shift ended at 18:00'), findsOneWidget);
    expect(orb(tester).fill, 1);
    expect(orb(tester).mode, OrbMode.weekend);
  });

  testWidgets('a day off has no shift', (tester) async {
    await pump(tester, null, DateTime(2026, 10, 24, 12));
    expect(find.text('Day off'), findsOneWidget);
    expect(find.text('no shift today'), findsOneWidget);
    expect(orb(tester).mode, OrbMode.paused);
  });

  testWidgets('speaks Russian', (tester) async {
    await pump(tester, shift, DateTime(2026, 10, 21, 13, 30), locale: 'ru');
    expect(find.text('до конца смены в 18:00'), findsOneWidget);
    expect(orb(tester).semanticLabel, '50% смены позади');
  });
}
