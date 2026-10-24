import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:week_counter/core/calendar_date.dart';
import 'package:week_counter/domain/countdown_engine.dart';
import 'package:week_counter/domain/day_classifier.dart';
import 'package:week_counter/l10n/app_localizations.dart';
import 'package:week_counter/l10n/jokes.dart';
import 'package:week_counter/models/holiday.dart';
import 'package:week_counter/models/work_schedule.dart';

CountdownState stateAt(
  DateTime now, [
  WorkSchedule s = WorkSchedule.standard,
]) => CountdownEngine(
  DayClassifier(schedule: s, holidays: const {}, overrides: const {}),
).snapshot(now).state;

List<JokePool> poolsAt(
  DateTime now, [
  WorkSchedule s = WorkSchedule.standard,
]) => jokePools(stateAt(now, s), s, now);

void main() {
  setUpAll(initializeDateFormatting);

  test('weekday pools follow the five-day week', () {
    expect(poolsAt(DateTime(2026, 10, 19, 9, 30)), [JokePool.monMorning]);
    expect(poolsAt(DateTime(2026, 10, 19, 15)), [JokePool.mon]);
    expect(poolsAt(DateTime(2026, 10, 22, 13)), [JokePool.thu]);
    expect(poolsAt(DateTime(2026, 10, 23, 12)), [JokePool.fri]);
    expect(poolsAt(DateTime(2026, 10, 23, 17, 30)), [JokePool.lastHour]);
  });

  test('time off pools', () {
    expect(poolsAt(DateTime(2026, 10, 24, 12)), [JokePool.weekend]);
    expect(poolsAt(DateTime(2026, 10, 25, 20)), [JokePool.sunEvening]);
    // Monday 01:30 is under eight hours from the shift, not Sunday evening.
    expect(poolsAt(DateTime(2026, 10, 26, 1, 30)), [JokePool.preWork]);
  });

  test('only a holiday inside the work week is mid-week', () {
    Map<CalendarDate, List<Holiday>> holidays(List<CalendarDate> dates) => {
      for (final date in dates)
        date: [
          Holiday(date: date, name: 'H', localName: 'H', countryCode: 'RU'),
        ],
    };
    List<JokePool> poolsWith(List<CalendarDate> dates, DateTime now) {
      final state = CountdownEngine(
        DayClassifier(
          schedule: WorkSchedule.standard,
          holidays: holidays(dates),
          overrides: const {},
        ),
      ).snapshot(now).state;
      return jokePools(state, WorkSchedule.standard, now);
    }

    // Unity Day, Wednesday 4 November.
    expect(
      poolsWith([const CalendarDate(2026, 11, 4)], DateTime(2026, 11, 4, 12)),
      [JokePool.midweekHoliday, JokePool.holiday],
    );
    // The New Year holidays run 1–8 January, through two weekends.
    expect(
      poolsWith([
        for (var day = 1; day <= 8; day++) CalendarDate(2027, 1, day),
      ], DateTime(2027, 1, 4, 12)),
      [JokePool.holiday, JokePool.daysOff],
    );
  });

  test('a Tuesday–Saturday week ends on Saturday, not Friday', () {
    final tueSat = WorkSchedule.standard.copyWith(workdays: {2, 3, 4, 5, 6});
    expect(poolsAt(DateTime(2026, 10, 23, 12), tueSat), [JokePool.work]);
    expect(poolsAt(DateTime(2026, 10, 24, 12), tueSat), [JokePool.lastDay]);
  });

  test('every pool has lines in both languages', () {
    for (final pool in JokePool.values) {
      expect(jokeLines('en', pool), isNotEmpty, reason: '$pool en');
      expect(jokeLines('ru', pool), isNotEmpty, reason: '$pool ru');
    }
  });

  test('placeholders are filled', () {
    final now = DateTime(2026, 10, 23, 17, 30);
    final l10n = lookupAppLocalizations(const Locale('en'));
    final lines = jokes(l10n, stateAt(now), WorkSchedule.standard, now);
    expect(lines, contains(startsWith('30 min to go.')));
    expect(lines.where((l) => l.contains('{')), isEmpty);
  });
}
