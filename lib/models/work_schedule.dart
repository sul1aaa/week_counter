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

/// Which weekdays are workdays and when the shifts run.
@immutable
class WorkSchedule {
  const WorkSchedule({
    required this.workdays,
    required this.defaultShift,
    this.customShifts = const {},
  });

  factory WorkSchedule.fromJson(Map<String, dynamic> json) => WorkSchedule(
    workdays: {for (final d in json['workdays'] as List) d as int},
    defaultShift: Shift.fromJson(json['defaultShift'] as Map<String, dynamic>),
    customShifts: {
      for (final e in (json['customShifts'] as Map<String, dynamic>? ?? {})
          .entries)
        int.parse(e.key): Shift.fromJson(e.value as Map<String, dynamic>),
    },
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

  /// [DateTime.monday] (1) through [DateTime.sunday] (7).
  final Set<int> workdays;
  final Shift defaultShift;

  /// Per-weekday hours that replace [defaultShift]. Empty means the same
  /// hours every workday.
  final Map<int, Shift> customShifts;

  bool get hasCustomShifts => customShifts.isNotEmpty;

  bool isScheduledWorkday(int weekday) => workdays.contains(weekday);

  Shift shiftFor(int weekday) => customShifts[weekday] ?? defaultShift;

  DateTime shiftStartOn(CalendarDate date) {
    final shift = shiftFor(date.weekday);
    return date.at(shift.start.hour, shift.start.minute);
  }

  DateTime shiftEndOn(CalendarDate date) {
    final shift = shiftFor(date.weekday);
    final endDay = shift.isOvernight ? date.addDays(1) : date;
    return endDay.at(shift.end.hour, shift.end.minute);
  }

  WorkSchedule copyWith({
    Set<int>? workdays,
    Shift? defaultShift,
    Map<int, Shift>? customShifts,
  }) => WorkSchedule(
    workdays: workdays ?? this.workdays,
    defaultShift: defaultShift ?? this.defaultShift,
    customShifts: customShifts ?? this.customShifts,
  );

  Map<String, dynamic> toJson() => {
    'workdays': workdays.toList()..sort(),
    'defaultShift': defaultShift.toJson(),
    'customShifts': {
      for (final e in customShifts.entries) '${e.key}': e.value.toJson(),
    },
  };
}
