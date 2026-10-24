import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:week_counter/app.dart';
import 'package:week_counter/services/holiday_api.dart';
import 'package:week_counter/services/holiday_repository.dart';
import 'package:week_counter/services/local_store.dart';
import 'package:week_counter/services/prefs_repository.dart';
import 'package:week_counter/services/settings_repository.dart';
import 'package:week_counter/services/widget_sync.dart';
import 'package:week_counter/state/app_controller.dart';

/// Russia's New Year holidays, 1–8 January 2027.
final _newYear = MockClient((request) async {
  final segments = request.url.pathSegments;
  final holidays = segments[segments.length - 2] != '2027'
      ? const []
      : [
          for (var day = 1; day <= 8; day++)
            {
              'date': '2027-01-0$day',
              'localName': 'Новогодние каникулы',
              'name': 'New Year holiday',
              'countryCode': 'RU',
              'global': true,
              'types': ['Public'],
            },
        ];
  return http.Response.bytes(utf8.encode(jsonEncode(holidays)), 200);
});

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('the New Year holidays are not called mid-week', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final store = InMemoryLocalStore();
    final controller = AppController(
      settingsRepository: SettingsRepository(store),
      holidayRepository: HolidayRepository(
        store,
        NagerDateApi(client: _newYear),
      ),
      prefsRepository: PrefsRepository(store),
      widgetSync: NoopWidgetSync(),
      // Monday 4 January, in the middle of the holidays.
      clock: () => DateTime(2027, 1, 4, 12),
    );
    await controller.init();
    await controller.completeOnboarding();
    await controller.setCountry('RU');
    await controller.refreshHolidays();

    await tester.pumpWidget(
      WeekCounterApp(controller: controller, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    expect(find.text('New Year holiday'), findsOneWidget);
    expect(find.text('Back to work Jan 11, 09:00'), findsOneWidget);
    expect(find.textContaining('mid-week'), findsNothing);
  });
}
