import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:week_counter/app.dart';
import 'package:week_counter/services/holiday_api.dart';
import 'package:week_counter/services/holiday_repository.dart';
import 'package:week_counter/services/local_store.dart';
import 'package:week_counter/services/settings_repository.dart';
import 'package:week_counter/services/widget_sync.dart';
import 'package:week_counter/state/app_controller.dart';

import 'services/fake_nager.dart';

void main() {
  setUpAll(initializeDateFormatting);

  late NoopWidgetSync widgetSync;

  Future<AppController> createController() async {
    final store = InMemoryLocalStore();
    widgetSync = NoopWidgetSync();
    final controller = AppController(
      settingsRepository: SettingsRepository(store),
      holidayRepository: HolidayRepository(
        store,
        NagerDateApi(client: FakeNager().client),
      ),
      widgetSync: widgetSync,
      // Wednesday noon.
      clock: () => DateTime(2026, 10, 21, 12),
      deviceLocale: () => const Locale('ru', 'RU'),
    );
    await controller.init();
    return controller;
  }

  testWidgets('shows the countdown and navigates between tabs', (
    tester,
  ) async {
    final controller = await createController();
    await tester.pumpWidget(
      WeekCounterApp(controller: controller, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    // The country was guessed from the phone's region.
    expect(controller.settings.countryCode, 'RU');
    expect(find.text('Weekend in'), findsOneWidget);
    expect(find.text('Next weekend'), findsOneWidget);
    expect(find.text('Next holiday'), findsOneWidget);
    expect(find.text('Unity Day'), findsWidgets);
    expect(find.text('In shift until 18:00'), findsOneWidget);

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    expect(find.text('No public holidays this month'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Working time'), findsOneWidget);
    expect(find.text('Russia'), findsOneWidget);
  });

  testWidgets('renders in Russian and feeds the widget', (tester) async {
    final controller = await createController();
    await tester.pumpWidget(
      WeekCounterApp(controller: controller, locale: const Locale('ru')),
    );
    await tester.pumpAndSettle();

    expect(find.text('До выходных'), findsOneWidget);
    expect(find.text('Ближайший праздник'), findsOneWidget);

    final payload = widgetSync.lastPayload!;
    expect(payload.locale, 'ru');
    expect(payload.segments.first.title, 'До выходных');
  });

  testWidgets('unchecking every workday shows the empty state', (
    tester,
  ) async {
    final controller = await createController();
    await controller.updateSchedule(
      controller.settings.schedule.copyWith(workdays: {}),
    );
    await tester.pumpWidget(
      WeekCounterApp(controller: controller, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    expect(find.text('No workdays set'), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(find.text('Working time'), findsOneWidget);
  });
}
