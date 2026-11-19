import 'package:flutter/foundation.dart';

import '../core/calendar_date.dart';

/// A time of day, e.g. 09:00.
@immutable
class ShiftTime {
  const ShiftTime(this.hour, this.minute);

  factory ShiftTime.parse(String value) {
    final parts = value.split(':');
    return ShiftTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  final int hour;
  final int minute;

  int get minutesOfDay => hour * 60 + minute;

  String toJson() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is ShiftTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => toJson();
}

/// Working hours on one day. A shift belongs to the day it starts on.
@immutable
class Shift {
  const Shift(this.start, this.end);

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
    ShiftTime.parse(json['start'] as String),
    ShiftTime.parse(json['end'] as String),
  );

  final ShiftTime start;
  final ShiftTime end;

  /// The shift ends on the next calendar day (e.g. 22:00–06:00).
  /// Equal start and end means a 24-hour shift.
  bool get isOvernight => end.minutesOfDay <= start.minutesOfDay;

  Map<String, dynamic> toJson() => {
    'start': start.toJson(),
    'end': end.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is Shift && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// What one day of a [ShiftRotation] holds.
enum RotationDay { day, night, off }

/// The rotations offered in Schedule.
enum RotationPreset {
  twoTwo([.day, .day, .off, .off]),
  threeThree([.day, .day, .day, .off, .off, .off]),
  fourFour([.day, .day, .day, .day, .off, .off, .off, .off]),
  dayNight([.day, .night, .off, .off]),
  dayTwoOff([.day, .off, .off]),
  dayThreeOff([.day, .off, .off, .off]);

  const RotationPreset(this.cycle);

  final List<RotationDay> cycle;

  /// One 24-hour shift, then days off.
  bool get roundTheClock => this == dayTwoOff || this == dayThreeOff;
}

/// Shifts and days off that repeat in a cycle whatever the weekday, e.g.
/// two days on, two days off.
@immutable
class ShiftRotation {
  const ShiftRotation({
    required this.cycle,
    required this.start,
    this.dayShift = const Shift(ShiftTime(8, 0), ShiftTime(20, 0)),
    this.nightShift = const Shift(ShiftTime(20, 0), ShiftTime(8, 0)),
    this.holidaysOff = false,
  });

  factory ShiftRotation.fromJson(Map<String, dynamic> json) => ShiftRotation(
    cycle: [
      for (final d in json['cycle'] as List)
        RotationDay.values.byName(d as String),
    ],
    start: CalendarDate.parse(json['start'] as String),
    dayShift: Shift.fromJson(json['dayShift'] as Map<String, dynamic>),
    nightShift: Shift.fromJson(json['nightShift'] as Map<String, dynamic>),
    holidaysOff: json['holidaysOff'] as bool? ?? false,
  );

  final List<RotationDay> cycle;

  /// A day the cycle's first day falls on.
  final CalendarDate start;
  final Shift dayShift;
  final Shift nightShift;

  /// Public holidays are days off. Most rotations run through them.
  final bool holidaysOff;

  RotationPreset? get preset => RotationPreset.values
      .where((p) => listEquals(p.cycle, cycle))
      .firstOrNull;

  bool get hasNight => cycle.contains(RotationDay.night);

  /// Which day of the cycle [date] is, from 0.
  int indexOn(CalendarDate date) => start.daysUntil(date) % cycle.length;

  RotationDay dayOn(CalendarDate date) => cycle[indexOn(date)];

  /// The shift on [date]. Days off get the day shift, for when they're
  /// marked as workdays.
  Shift shiftOn(CalendarDate date) =>
      dayOn(date) == RotationDay.night ? nightShift : dayShift;

  /// Switches to [preset]. Today keeps its place in the cycle if the new
  /// one is long enough, else it becomes the first workday. A 24-hour
  /// preset stretches the day shift to 24 hours, and leaving one brings
  /// it back to 12.
  ShiftRotation withPreset(RotationPreset preset, CalendarDate today) {
    final index = indexOn(today);
    final from = dayShift.start;
    final roundTheClock = dayShift.start == dayShift.end;
    return copyWith(
      cycle: preset.cycle,
      start: today.addDays(index < preset.cycle.length ? -index : 0),
      dayShift: preset.roundTheClock == roundTheClock
          ? dayShift
          : preset.roundTheClock
          ? Shift(from, from)
          : Shift(from, ShiftTime((from.hour + 12) % 24, from.minute)),
    );
  }

  ShiftRotation copyWith({
    List<RotationDay>? cycle,
    CalendarDate? start,
    Shift? dayShift,
    Shift? nightShift,
    bool? holidaysOff,
  }) => ShiftRotation(
    cycle: cycle ?? this.cycle,
    start: start ?? this.start,
    dayShift: dayShift ?? this.dayShift,
    nightShift: nightShift ?? this.nightShift,
    holidaysOff: holidaysOff ?? this.holidaysOff,
  );

  Map<String, dynamic> toJson() => {
    'cycle': [for (final d in cycle) d.name],
    'start': start.toIso(),
    'dayShift': dayShift.toJson(),
    'nightShift': nightShift.toJson(),
    'holidaysOff': holidaysOff,
  };

  @override
  bool operator ==(Object other) =>
      other is ShiftRotation &&
      listEquals(other.cycle, cycle) &&
      other.start == start &&
      other.dayShift == dayShift &&
      other.nightShift == nightShift &&
      other.holidaysOff == holidaysOff;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(cycle),
    start,
    dayShift,
    nightShift,
    holidaysOff,
  );
}

/// Which days are workdays and when the shifts run: the same weekdays every
/// week, or a [rotation] when there is one.
@immutable
class WorkSchedule {
  const WorkSchedule({
    required this.workdays,
    required this.defaultShift,
    this.customShifts = const {},
    this.rotation,
  });

  factory WorkSchedule.fromJson(Map<String, dynamic> json) => WorkSchedule(
    workdays: {for (final d in json['workdays'] as List) d as int},
    defaultShift: Shift.fromJson(json['defaultShift'] as Map<String, dynamic>),
    customShifts: {
      for (final e in (json['customShifts'] as Map<String, dynamic>? ?? {})
          .entries)
        int.parse(e.key): Shift.fromJson(e.value as Map<String, dynamic>),
    },
    rotation: json['rotation'] == null
        ? null
        : ShiftRotation.fromJson(json['rotation'] as Map<String, dynamic>),
  );

  /// Monday to Friday, 09:00–18:00.
  static const standard = WorkSchedule(
    workdays: {
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
    },
    defaultShift: Shift(ShiftTime(9, 0), ShiftTime(18, 0)),
  );

  /// [DateTime.monday] (1) through [DateTime.sunday] (7). Kept while a
  /// [rotation] is on, so switching back restores the week.
  final Set<int> workdays;
  final Shift defaultShift;

  /// Per-weekday hours that replace [defaultShift]. Empty means the same
  /// hours every workday.
  final Map<int, Shift> customShifts;

  /// Replaces [workdays] and the weekly hours when set.
  final ShiftRotation? rotation;

  bool get hasCustomShifts => customShifts.isNotEmpty;

  bool get hasWorkdays => switch (rotation) {
    final r? => r.cycle.any((d) => d != RotationDay.off),
    null => workdays.isNotEmpty,
  };

  /// Whether public holidays are days off. A rotation decides for itself.
  bool get holidaysOff => rotation?.holidaysOff ?? true;

  bool isScheduledWorkday(CalendarDate date) => switch (rotation) {
    final r? => r.dayOn(date) != RotationDay.off,
    null => workdays.contains(date.weekday),
  };

  /// The weekly hours on [weekday], ignoring any rotation.
  Shift shiftFor(int weekday) => customShifts[weekday] ?? defaultShift;

  Shift shiftOn(CalendarDate date) =>
      rotation?.shiftOn(date) ?? shiftFor(date.weekday);

  DateTime shiftStartOn(CalendarDate date) {
    final shift = shiftOn(date);
    return date.at(shift.start.hour, shift.start.minute);
  }

  DateTime shiftEndOn(CalendarDate date) {
    final shift = shiftOn(date);
    final endDay = shift.isOvernight ? date.addDays(1) : date;
    return endDay.at(shift.end.hour, shift.end.minute);
  }

  WorkSchedule copyWith({
    Set<int>? workdays,
    Shift? defaultShift,
    Map<int, Shift>? customShifts,
    ValueGetter<ShiftRotation?>? rotation,
  }) => WorkSchedule(
    workdays: workdays ?? this.workdays,
    defaultShift: defaultShift ?? this.defaultShift,
    customShifts: customShifts ?? this.customShifts,
    rotation: rotation != null ? rotation() : this.rotation,
  );

  Map<String, dynamic> toJson() => {
    'workdays': workdays.toList()..sort(),
    'defaultShift': defaultShift.toJson(),
    'customShifts': {
      for (final e in customShifts.entries) '${e.key}': e.value.toJson(),
    },
    if (rotation != null) 'rotation': rotation!.toJson(),
  };
}
