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

    test('progress runs from Monday 09:00 to Friday 18:00', () {
      final now = at(2026, 10, 21, 12);
      final state = e.snapshot(now).state as CountingDown;
      expect(state.since, at(2026, 10, 19, 9));
      final total = at(2026, 10, 23, 18).difference(at(2026, 10, 19, 9));
      final done = now.difference(at(2026, 10, 19, 9));
      expect(
        state.progress(now),
        closeTo(done.inMinutes / total.inMinutes, 1e-9),
      );
    });

    test('weekend progress is half done on Sunday 01:30', () {
      final now = at(2026, 10, 25, 1, 30);
      final state = e.snapshot(now).state as OffNow;
      // Friday 18:00 to Monday 09:00 is 63 hours; 31.5 have passed.
      expect(state.progress(now), closeTo(0.5, 1e-9));
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
      expect(state.since, at(2026, 11, 2, 9));
      expect(s.nextHoliday, same(state.block));
      expect(s.nextWeekend!.offStart, at(2026, 11, 6, 18));
    });

    test('after a Wednesday holiday the week restarts on Thursday', () {
      final e = engine(holidays: [holiday(2026, 11, 4, 'Unity Day')]);
      final state = e.snapshot(at(2026, 11, 5, 12)).state as CountingDown;
      expect(state.since, at(2026, 11, 5, 9));
      expect(state.target, at(2026, 11, 6, 18));
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
      final e = engine(schedule: WorkSchedule.standard.copyWith(workdays: {}));
      expect(e.snapshot(at(2026, 10, 21, 12)).state, isA<NoWorkdays>());
    });

    test('no workdays, and a working Saturday that is over', () {
      final e = engine(
        schedule: WorkSchedule.standard.copyWith(workdays: {}),
        overrides: {
          const CalendarDate(2026, 3, 7): const DayOverride(
            OverrideKind.workday,
          ),
        },
      );
      expect(e.snapshot(at(2026, 10, 21, 12)).state, isA<NoWorkdays>());
    });

    test('no workdays but a working Saturday ahead', () {
      final e = engine(
        schedule: WorkSchedule.standard.copyWith(workdays: {}),
        overrides: {
          const CalendarDate(2026, 10, 24): const DayOverride(
            OverrideKind.workday,
          ),
        },
      );
      final state = e.snapshot(at(2026, 10, 21, 12)).state;
      expect((state as OffNow).backToWork, at(2026, 10, 24, 9));
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

  group('day shift', () {
    final e = engine(holidays: [holiday(2026, 11, 4, 'Unity Day')]);

    test('during a shift is that shift, half done at 13:30', () {
      final now = at(2026, 10, 21, 13, 30);
      final shift = e.snapshot(now).dayShift!;
      expect(shift.start, at(2026, 10, 21, 9));
      expect(shift.end, at(2026, 10, 21, 18));
      expect(shift.progress(now), closeTo(0.5, 1e-9));
    });

    test("before the shift is today's, not started", () {
      final now = at(2026, 10, 21, 7);
      final shift = e.snapshot(now).dayShift!;
      expect(shift.start, at(2026, 10, 21, 9));
      expect(shift.progress(now), 0);
    });

    test("after the shift is still today's, done", () {
      final now = at(2026, 10, 21, 20);
      final shift = e.snapshot(now).dayShift!;
      expect(shift.end, at(2026, 10, 21, 18));
      expect(shift.progress(now), 1);
    });

    test('none on a weekend or a holiday', () {
      expect(e.snapshot(at(2026, 10, 24, 12)).dayShift, isNull);
      expect(e.snapshot(at(2026, 11, 4, 12)).dayShift, isNull);
    });

    test('follows per-day hours', () {
      final e = engine(
        schedule: WorkSchedule.standard.copyWith(
          customShifts: {
            DateTime.friday: const Shift(ShiftTime(9, 0), ShiftTime(16, 30)),
          },
        ),
      );
      expect(
        e.snapshot(at(2026, 10, 23, 12)).dayShift!.end,
        at(2026, 10, 23, 16, 30),
      );
    });

    test('a workday override has a shift', () {
      final e = engine(
        overrides: {
          const CalendarDate(2026, 10, 24): const DayOverride(
            OverrideKind.workday,
          ),
        },
      );
      expect(
        e.snapshot(at(2026, 10, 24, 12)).dayShift!.end,
        at(2026, 10, 24, 18),
      );
    });

    test('with every day a workday', () {
      final e = engine(
        schedule: WorkSchedule.standard.copyWith(
          workdays: {1, 2, 3, 4, 5, 6, 7},
        ),
      );
      final s = e.snapshot(at(2026, 10, 24, 12));
      expect(s.state, isA<NoDaysOff>());
      expect(s.dayShift!.end, at(2026, 10, 24, 18));
    });

    group('overnight 22:00–06:00', () {
      final e = engine(
        schedule: WorkSchedule.standard.copyWith(
          defaultShift: const Shift(ShiftTime(22, 0), ShiftTime(6, 0)),
        ),
      );

      test("after midnight is yesterday's shift", () {
        final s = e.snapshot(at(2026, 10, 22, 3));
        expect(s.dayShift!.start, at(2026, 10, 21, 22));
        expect(s.dayShift!.end, at(2026, 10, 22, 6));
        expect(s.validUntil, at(2026, 10, 22, 6));
      });

      test("after it ends is today's shift tonight", () {
        final s = e.snapshot(at(2026, 10, 22, 6));
        expect(s.dayShift!.start, at(2026, 10, 22, 22));
      });

      test('Saturday 03:00 is still the Friday shift', () {
        final s = e.snapshot(at(2026, 10, 24, 3));
        expect(s.dayShift!.end, at(2026, 10, 24, 6));
        expect(e.snapshot(at(2026, 10, 24, 7)).dayShift, isNull);
      });
    });
  });

  group('2/2 rotation, 08:00–20:00, from Monday 19 October', () {
    final rotation = ShiftRotation(
      cycle: RotationPreset.twoTwo.cycle,
      start: const CalendarDate(2026, 10, 19),
    );
    final e = engine(
      schedule: WorkSchedule.standard.copyWith(rotation: () => rotation),
    );

    test('works Monday and Tuesday, then has two days off', () {
      final state = e.snapshot(at(2026, 10, 19, 12)).state as CountingDown;
      expect(state.target, at(2026, 10, 20, 20));
      expect(state.since, at(2026, 10, 19, 8));
      expect(state.block.first, const CalendarDate(2026, 10, 21));
      expect(state.block.length, 2);
      expect(state.block.kind, BlockKind.weekend);
      expect(state.block.offEnd, at(2026, 10, 23, 8));
    });

    test('runs through the weekend like any other days', () {
      expect(
        e.classifier.classify(const CalendarDate(2026, 10, 24)).isWork,
        isTrue,
      );
      expect(
        e.classifier.classify(const CalendarDate(2026, 10, 26)).isOff,
        isTrue,
      );
    });

    test('runs back before the day it starts on', () {
      expect(
        e.classifier.classify(const CalendarDate(2026, 10, 16)).isWork,
        isTrue,
      );
      expect(
        e.classifier.classify(const CalendarDate(2026, 10, 17)).isOff,
        isTrue,
      );
      expect(
        e.classifier.classify(const CalendarDate(2026, 10, 18)).isOff,
        isTrue,
      );
    });

    test('counts without any weekly workdays', () {
      final e = engine(
        schedule: WorkSchedule.standard.copyWith(
          workdays: {},
          rotation: () => rotation,
        ),
      );
      expect(e.snapshot(at(2026, 10, 19, 12)).state, isA<CountingDown>());
    });
  });

  group('day/night rotation from Monday 19 October', () {
    final e = engine(
      schedule: WorkSchedule.standard.copyWith(
        rotation: () => ShiftRotation(
          cycle: RotationPreset.dayNight.cycle,
          start: const CalendarDate(2026, 10, 19),
        ),
      ),
    );

    test("Tuesday's night shift ends the run on Wednesday morning", () {
      final s = e.snapshot(at(2026, 10, 20, 23));
      final state = s.state as CountingDown;
      expect(state.target, at(2026, 10, 21, 8));
      expect(state.inShiftUntil, at(2026, 10, 21, 8));
      expect(
        s.dayShift,
        DayShift(start: at(2026, 10, 20, 20), end: at(2026, 10, 21, 8)),
      );
    });

    test("back to work with Friday's day shift", () {
      final state = e.snapshot(at(2026, 10, 21, 12)).state as OffNow;
      expect(state.backToWork, at(2026, 10, 23, 8));
    });
  });

  test('24 hours on, 3 days off', () {
    final e = engine(
      schedule: WorkSchedule.standard.copyWith(
        rotation: () => ShiftRotation(
          cycle: RotationPreset.dayThreeOff.cycle,
          start: const CalendarDate(2026, 10, 19),
          dayShift: const Shift(ShiftTime(8, 0), ShiftTime(8, 0)),
        ),
      ),
    );
    final working = e.snapshot(at(2026, 10, 19, 12)).state as CountingDown;
    expect(working.target, at(2026, 10, 20, 8));
    expect(working.block.length, 3);
    final off = e.snapshot(at(2026, 10, 20, 9)).state as OffNow;
    expect(off.backToWork, at(2026, 10, 23, 8));
  });

  group('a holiday on a rotation workday', () {
    // Unity Day falls on the second workday of the run.
    WorkSchedule rotation({required bool holidaysOff}) =>
        WorkSchedule.standard.copyWith(
          rotation: () => ShiftRotation(
            cycle: RotationPreset.twoTwo.cycle,
            start: const CalendarDate(2026, 11, 3),
            holidaysOff: holidaysOff,
          ),
        );
    final holidays = [holiday(2026, 11, 4, 'Unity Day')];

    test('is worked by default', () {
      final e = engine(
        schedule: rotation(holidaysOff: false),
        holidays: holidays,
      );
      final day = e.classifier.classify(unityDay);
      expect(day.isWork, isTrue);
      expect(day.isExtraWorkday, isFalse);
      expect(day.holidays.single.name, 'Unity Day');
      final state = e.snapshot(at(2026, 11, 3, 12)).state as CountingDown;
      expect(state.target, at(2026, 11, 4, 20));
    });

    test('is a day off when holidays are', () {
      final e = engine(
        schedule: rotation(holidaysOff: true),
        holidays: holidays,
      );
      final day = e.classifier.classify(unityDay);
      expect(day.isOff, isTrue);
      expect(day.reasons, contains(OffReason.publicHoliday));
      final state = e.snapshot(at(2026, 11, 3, 12)).state as CountingDown;
      expect(state.target, at(2026, 11, 3, 20));
      expect(state.block.length, 3);
    });
  });

  test('upcoming list starts after the current block', () {
    final s = engine().snapshot(at(2026, 10, 24, 10));
    expect(s.blocks.first.first, const CalendarDate(2026, 10, 24));
    expect(s.upcoming.first.first, const CalendarDate(2026, 10, 31));
  });
}
