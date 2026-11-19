import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:week_counter/core/calendar_date.dart';
import 'package:week_counter/models/work_schedule.dart';

void main() {
  const today = CalendarDate(2026, 10, 21);

  test('a rotation survives a save', () {
    final schedule = WorkSchedule.standard.copyWith(
      rotation: () => ShiftRotation(
        cycle: RotationPreset.dayNight.cycle,
        start: today,
        holidaysOff: true,
      ),
    );
    final restored = WorkSchedule.fromJson(
      jsonDecode(jsonEncode(schedule.toJson())) as Map<String, dynamic>,
    );
    expect(restored.rotation, schedule.rotation);
    expect(restored.workdays, schedule.workdays);
  });

  test('settings saved before rotations load as a weekly schedule', () {
    final json = WorkSchedule.standard.toJson();
    expect(json.containsKey('rotation'), isFalse);
    expect(WorkSchedule.fromJson(json).rotation, isNull);
  });

  test('a hand-made cycle is no preset', () {
    final rotation = ShiftRotation(
      cycle: const [RotationDay.day, RotationDay.off],
      start: today,
    );
    expect(rotation.preset, isNull);
  });

  group('switching presets', () {
    // Today is the second workday of a 2/2.
    final twoTwo = ShiftRotation(
      cycle: RotationPreset.twoTwo.cycle,
      start: today.addDays(-1),
    );

    test('keeps today in its place', () {
      final rotation = twoTwo.withPreset(RotationPreset.threeThree, today);
      expect(rotation.preset, RotationPreset.threeThree);
      expect(rotation.indexOn(today), 1);
      expect(rotation.dayShift, twoTwo.dayShift);
    });

    test('starts over when today no longer fits', () {
      final secondDayOff = twoTwo.copyWith(start: today.addDays(-3));
      final rotation = secondDayOff.withPreset(RotationPreset.dayTwoOff, today);
      expect(rotation.indexOn(today), 0);
    });

    test('24/48 makes the shift 24 hours, and leaving it makes it 12', () {
      final roundTheClock = twoTwo.withPreset(RotationPreset.dayTwoOff, today);
      expect(
        roundTheClock.dayShift,
        const Shift(ShiftTime(8, 0), ShiftTime(8, 0)),
      );
      expect(
        roundTheClock.withPreset(RotationPreset.fourFour, today).dayShift,
        const Shift(ShiftTime(8, 0), ShiftTime(20, 0)),
      );
    });
  });
}
