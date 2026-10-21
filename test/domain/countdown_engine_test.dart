import 'package:flutter_test/flutter_test.dart';
import 'package:week_counter/core/calendar_date.dart';
import 'package:week_counter/domain/countdown_engine.dart';
import 'package:week_counter/domain/day_classifier.dart';
import 'package:week_counter/models/app_settings.dart';
import 'package:week_counter/models/holiday.dart';
import 'package:week_counter/models/work_schedule.dart';

CountdownEngine engine({
  WorkSchedule schedule = WorkSchedule.standard,
  List<Holiday> holidays = const [],
  Map<CalendarDate, DayOverride> overrides = const {},
}) {
  final byDate = <CalendarDate, List<Holiday>>{};
  for (final h in holidays) {
    byDate.putIfAbsent(h.date, () => []).add(h);
  }
  return CountdownEngine(
    DayClassifier(schedule: schedule, holidays: byDate, overrides: overrides),
  );
}

Holiday holiday(int y, int m, int d, String name) => Holiday(
  date: CalendarDate(y, m, d),
  name: name,
  localName: name,
  countryCode: 'RU',
);

DateTime at(int y, int m, int d, int h, [int min = 0]) =>
    DateTime(y, m, d, h, min);

const unityDay = CalendarDate(2026, 11, 4); // Wednesday

void main() {
  group('Mon–Fri 09:00–18:00, no holidays', () {
    final e = engine();

    test('during a Wednesday shift counts down to Friday 18:00', () {
      final s = e.snapshot(at(2026, 10, 21, 12));
      final state = s.state as CountingDown;
      expect(state.target, at(2026, 10, 23, 18));
      expect(state.block.kind, BlockKind.weekend);
      expect(state.block.length, 2);
      expect(state.inShiftUntil, at(2026, 10, 21, 18));
      expect(s.nextWeekend, same(state.block));
      expect(s.nextHoliday, isNull);
      expect(s.validUntil, at(2026, 10, 21, 18));
    });

    test('Friday evening is already off', () {
      final state = e.snapshot(at(2026, 10, 23, 19)).state as OffNow;
      expect(state.backToWork, at(2026, 10, 26, 9));
      expect(state.dayNumber, isNull);
      expect(state.block.first, const CalendarDate(2026, 10, 24));
    });

    test('Saturday is off, day 1 of 2', () {
      final state = e.snapshot(at(2026, 10, 24, 10)).state as OffNow;
      expect(state.backToWork, at(2026, 10, 26, 9));
      expect(state.dayNumber, 1);
    });

    test('Monday before the shift is still off', () {
      final state = e.snapshot(at(2026, 10, 26, 7)).state as OffNow;
      expect(state.backToWork, at(2026, 10, 26, 9));
    });

    test('Tuesday before the shift counts down to Friday', () {
      final state = e.snapshot(at(2026, 10, 27, 7)).state as CountingDown;
      expect(state.target, at(2026, 10, 30, 18));
      expect(state.inShiftUntil, isNull);
    });

    test('exactly at the shift end is off', () {
      expect(e.snapshot(at(2026, 10, 23, 18)).state, isA<OffNow>());
    });

    test('next weekend while off is the following one', () {
      final s = e.snapshot(at(2026, 10, 24, 10));
      expect(s.nextWeekend!.first, const CalendarDate(2026, 10, 31));
    });
  });

  group('public holidays', () {
    test('Wednesday holiday counts down to Tuesday 18:00', () {
      final e = engine(holidays: [holiday(2026, 11, 4, 'Unity Day')]);
      final s = e.snapshot(at(2026, 11, 2, 10));
      final state = s.state as CountingDown;
      expect(state.target, at(2026, 11, 3, 18));
      expect(state.block.kind, BlockKind.holiday);
      expect(state.block.length, 1);
      expect(state.block.offEnd, at(2026, 11, 5, 9));
      expect(s.nextHoliday, same(state.block));
      expect(s.nextWeekend!.offStart, at(2026, 11, 6, 18));
    });

    test('Friday holiday makes a long weekend from Thursday 18:00', () {
      final e = engine(holidays: [holiday(2027, 1, 1, 'New Year')]);
      final s = e.snapshot(at(2026, 12, 30, 12));
      final state = s.state as CountingDown;
      expect(state.target, at(2026, 12, 31, 18));
      expect(state.block.kind, BlockKind.longWeekend);
      expect(state.block.length, 3);
      expect(s.nextWeekend, same(s.nextHoliday));
    });

    test('long holiday stretches are holidays, not long weekends', () {
      final e = engine(
        holidays: [
          for (var d = 1; d <= 8; d++) holiday(2027, 1, d, 'New Year break'),
        ],
      );
      final state = e.snapshot(at(2026, 12, 30, 12)).state as CountingDown;
      expect(state.block.length, 10); // Fri 1 – Sun 10 Jan
      expect(state.block.kind, BlockKind.holiday);
      expect(state.block.offEnd, at(2027, 1, 11, 9));
    });

    test('holiday on a Saturday stays a normal weekend', () {
      final e = engine(holidays: [holiday(2026, 10, 31, 'Saturday Day')]);
      final state = e.snapshot(at(2026, 10, 28, 12)).state as CountingDown;
      expect(state.block.kind, BlockKind.weekend);
      expect(state.block.hasExtraOff, isFalse);
      expect(state.block.holidays.single.name, 'Saturday Day');
    });

    test('holidays only apply for loaded years', () {
      // No holiday data for 2027: New Year is a normal Friday.
      final e = engine(holidays: [holiday(2026, 11, 4, 'Unity Day')]);
      final state = e.snapshot(at(2026, 12, 30, 12)).state as CountingDown;
      expect(state.target, at(2027, 1, 1, 18));
    });
  });

  group('overrides', () {
    test('a custom Monday off makes a three-day weekend', () {
      final e = engine(
        overrides: {
          const CalendarDate(2026, 10, 26): const DayOverride(
            OverrideKind.dayOff,
            note: 'Dentist',
          ),
        },
      );
      final s = e.snapshot(at(2026, 10, 21, 12));
      final state = s.state as CountingDown;
      expect(state.block.length, 3);
      expect(state.block.kind, BlockKind.longWeekend);
      expect(state.block.offEnd, at(2026, 10, 27, 9));
      expect(state.block.notes, ['Dentist']);
    });

    test('a vacation week with weekends is days off', () {
      final e = engine(
        overrides: {
          for (var d = 26; d <= 30; d++)
            CalendarDate(2026, 10, d): const DayOverride(OverrideKind.dayOff),
        },
      );
      final state = e.snapshot(at(2026, 10, 21, 12)).state as CountingDown;
      expect(state.block.length, 9); // Sat 24 Oct – Sun 1 Nov
      expect(state.block.kind, BlockKind.daysOff);
    });

    test('a working Saturday splits the weekend', () {
      final e = engine(
        overrides: {
          const CalendarDate(2026, 10, 24): const DayOverride(
            OverrideKind.workday,
          ),
        },
      );
      final state = e.snapshot(at(2026, 10, 21, 12)).state as CountingDown;
      expect(state.target, at(2026, 10, 24, 18));
      expect(state.block.length, 1);
      expect(state.block.first, const CalendarDate(2026, 10, 25));
    });

    test('a workday override cancels a holiday', () {
      final e = engine(
        holidays: [holiday(2026, 11, 4, 'Unity Day')],
        overrides: {unityDay: const DayOverride(OverrideKind.workday)},
      );
      final state = e.snapshot(at(2026, 11, 2, 10)).state as CountingDown;
      expect(state.target, at(2026, 11, 6, 18));
      final day = e.classifier.classify(unityDay);
      expect(day.isWork, isTrue);
      expect(day.isExtraWorkday, isTrue);
    });
  });

  group('overnight shift 22:00–06:00', () {
    final e = engine(
      schedule: WorkSchedule.standard.copyWith(
        defaultShift: const Shift(ShiftTime(22, 0), ShiftTime(6, 0)),
      ),
    );

    test('Friday night shift counts down to Saturday 06:00', () {
      final state = e.snapshot(at(2026, 10, 23, 23)).state as CountingDown;
      expect(state.target, at(2026, 10, 24, 6));
      expect(state.inShiftUntil, at(2026, 10, 24, 6));
    });

    test('Saturday 03:00 is still in the Friday shift', () {
      final state = e.snapshot(at(2026, 10, 24, 3)).state as CountingDown;
      expect(state.target, at(2026, 10, 24, 6));
    });

    test('Saturday morning is off until Monday 22:00', () {
      final state = e.snapshot(at(2026, 10, 24, 7)).state as OffNow;
      expect(state.backToWork, at(2026, 10, 26, 22));
    });

    test('shift ending across a month boundary', () {
      // Fri 30 Oct 22:00 → Sat 31 Oct 06:00; next shift Mon 2 Nov.
      final state = e.snapshot(at(2026, 10, 31, 8)).state as OffNow;
      expect(state.backToWork, at(2026, 11, 2, 22));
    });
  });

  group('degenerate schedules', () {
    test('no workdays', () {
      final e = engine(
        schedule: WorkSchedule.standard.copyWith(workdays: {}),
      );
      expect(e.snapshot(at(2026, 10, 21, 12)).state, isA<NoWorkdays>());
    });

    test('every day a workday and no holidays', () {
      final e = engine(
        schedule: WorkSchedule.standard.copyWith(
          workdays: {1, 2, 3, 4, 5, 6, 7},
        ),
      );
      final s = e.snapshot(at(2026, 10, 21, 12));
      expect(s.state, isA<NoDaysOff>());
      expect(s.blocks, isEmpty);
    });
  });

  test('per-day hours: short Friday', () {
    final e = engine(
      schedule: WorkSchedule.standard.copyWith(
        customShifts: {
          DateTime.friday: const Shift(ShiftTime(9, 0), ShiftTime(16, 30)),
        },
      ),
    );
    final state = e.snapshot(at(2026, 10, 21, 12)).state as CountingDown;
    expect(state.target, at(2026, 10, 23, 16, 30));
  });

  test('upcoming list starts after the current block', () {
    final s = engine().snapshot(at(2026, 10, 24, 10));
    expect(s.blocks.first.first, const CalendarDate(2026, 10, 24));
    expect(s.upcoming.first.first, const CalendarDate(2026, 10, 31));
  });
}
