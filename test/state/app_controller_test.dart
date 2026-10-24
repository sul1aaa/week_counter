import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:week_counter/core/calendar_date.dart';
import 'package:week_counter/domain/countdown_engine.dart';
import 'package:week_counter/models/app_settings.dart';
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
      deviceLocales: () => const [Locale('ru', 'RU')],
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

  test('the widget falls back to the next language, like the app', () async {
    final widgetSync = NoopWidgetSync();
    final c = AppController(
      settingsRepository: SettingsRepository(store),
      holidayRepository: HolidayRepository(
        store,
        NagerDateApi(client: FakeNager().client),
      ),
      widgetSync: widgetSync,
      clock: () => now,
      // There's no Kazakh translation, so the app shows Russian.
      deviceLocales: () => const [Locale('kk', 'KZ'), Locale('ru', 'RU')],
    );
    await c.init();
    expect(c.settings.countryCode, 'KZ');
    expect(widgetSync.lastPayload!.locale, 'ru');
    expect(widgetSync.lastPayload!.segments.first.title, 'До выходных');
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

  test(
    'a holiday on the Monday after the weekend makes a short week',
    () async {
      now = DateTime(2027, 3, 3, 12); // Wednesday
      await (await create()).refreshHolidays();
      // Women's Day on Monday 8 March: the weekend starts Friday as usual
      // and runs to Tuesday morning.
      now = DateTime(2027, 3, 8, 12);
      final c = await create();
      expect(c.prefs.weeks, 1);
      expect(c.prefs.earned.keys, contains('shortWeek'));
    },
  );

  test('a week that ends at midnight on Friday the 13th counts', () async {
    now = DateTime(2026, 11, 11, 12); // Wednesday
    final c = await create();
    await c.updateSchedule(
      WorkSchedule.standard.copyWith(
        defaultShift: const Shift(ShiftTime(16, 0), ShiftTime(0, 0)),
      ),
    );
    // The last shift of the week runs Friday 13 November 16:00–24:00.
    now = DateTime(2026, 11, 14, 12);
    c.recompute();
    expect(c.prefs.weeks, 1);
    expect(c.prefs.earned.keys, contains('friday13'));
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

  test('marking days off keeps the notes and vacation already there', () async {
    final c = await create();
    await c.planVacation(const CalendarDate(2026, 10, 26), 14, 'Отпуск');
    const dentist = CalendarDate(2026, 11, 10);
    await c.setOverride([
      dentist,
    ], const DayOverride(OverrideKind.dayOff, note: 'Dentist'));

    await c.markDaysOff([
      for (var day = 7; day <= 11; day++) CalendarDate(2026, 11, day),
    ]);

    expect(c.vacation, (
      first: const CalendarDate(2026, 10, 26),
      last: const CalendarDate(2026, 11, 8),
    ));
    expect(c.settings.overrides[dentist]!.note, 'Dentist');
    expect(
      c.settings.overrides[const CalendarDate(2026, 11, 9)]!.kind,
      OverrideKind.dayOff,
    );
    expect(
      c.settings.overrides[const CalendarDate(2026, 11, 11)]!.kind,
      OverrideKind.dayOff,
    );

    // The whole vacation is still one, so cancelling clears all of it.
    await c.cancelVacation();
    expect(c.vacation, isNull);
    expect(c.settings.overrides.keys, {
      const CalendarDate(2026, 11, 9),
      dentist,
      const CalendarDate(2026, 11, 11),
    });
  });
}
