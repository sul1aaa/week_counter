import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:week_counter/core/calendar_date.dart';
import 'package:week_counter/domain/countdown_engine.dart';
import 'package:week_counter/models/work_schedule.dart';
import 'package:week_counter/services/holiday_api.dart';
import 'package:week_counter/services/holiday_repository.dart';
import 'package:week_counter/services/local_store.dart';
import 'package:week_counter/services/prefs_repository.dart';
import 'package:week_counter/services/settings_repository.dart';
import 'package:week_counter/services/widget_sync.dart';
import 'package:week_counter/state/app_controller.dart';

import '../services/fake_nager.dart';

void main() {
  setUpAll(initializeDateFormatting);

  late DateTime now;
  late InMemoryLocalStore store;

  Future<AppController> create() async {
    final controller = AppController(
      settingsRepository: SettingsRepository(store),
      holidayRepository: HolidayRepository(
        store,
        NagerDateApi(client: FakeNager().client),
      ),
      prefsRepository: PrefsRepository(store),
      widgetSync: NoopWidgetSync(),
      clock: () => now,
      deviceLocale: () => const Locale('ru', 'RU'),
    );
    await controller.init();
    return controller;
  }

  setUp(() {
    now = DateTime(2026, 10, 21, 12); // Wednesday
    store = InMemoryLocalStore();
  });

  test('a new user starts at zero weeks and in onboarding', () async {
    final c = await create();
    expect(c.prefs.onboarded, isFalse);
    expect(c.prefs.weeks, 0);
    expect(c.celebrationDue, isNull);
  });

  test('counts weekends while the app was closed', () async {
    await (await create()).refreshHolidays();
    // Fri 23 Oct, Fri 30 Oct, Tue 3 Nov (before the Unity Day holiday) and
    // Fri 6 Nov have passed by Sunday 8 Nov.
    now = DateTime(2026, 11, 8, 12);
    final c = await create();
    expect(c.prefs.weeks, 4);
    expect(c.prefs.earned.keys, containsAll(['w1', 'w4', 'shortWeek']));
  });

  test('editing the schedule mid-week neither counts nor celebrates', () async {
    final c = await create();
    now = DateTime(2026, 10, 23, 12); // Friday noon
    c.recompute();
    // The week now "ended" at 11:00, an hour ago.
    await c.updateSchedule(
      WorkSchedule.standard.copyWith(
        defaultShift: const Shift(ShiftTime(9, 0), ShiftTime(11, 0)),
      ),
    );
    expect(c.snapshot.state, isA<OffNow>());
    expect(c.celebrationDue, isNull);
    c.recompute();
    expect(c.prefs.weeks, 0);
  });

  test('plans and cancels a vacation', () async {
    final c = await create();
    await c.planVacation(const CalendarDate(2026, 10, 26), 14, 'Отпуск');
    expect(c.vacation, (
      first: const CalendarDate(2026, 10, 26),
      last: const CalendarDate(2026, 11, 8),
    ));
    expect(c.prefs.earned, contains('vacation'));
    final state = c.snapshot.state as CountingDown;
    expect(state.block.offEnd, DateTime(2026, 11, 9, 9));

    await c.cancelVacation();
    expect(c.vacation, isNull);
  });
}
