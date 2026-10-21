import 'package:flutter/foundation.dart';

import '../core/calendar_date.dart';
import '../models/app_settings.dart';
import '../models/holiday.dart';
import '../models/work_schedule.dart';

enum OffReason {
  /// Not one of the user's workdays (a normal weekend).
  scheduled,

  /// A national public holiday.
  publicHoliday,

  /// Marked as a day off by the user.
  custom,
}

/// Whether a calendar day is a workday or a day off, and why.
@immutable
class DayInfo {
  const DayInfo({
    required this.date,
    required this.isOff,
    required this.isScheduledWorkday,
    this.reasons = const {},
    this.holidays = const [],
    this.override,
  });

  final CalendarDate date;
  final bool isOff;
  final bool isScheduledWorkday;
  final Set<OffReason> reasons;

  /// Holidays on this day, including ones a workday override cancels.
  final List<Holiday> holidays;
  final DayOverride? override;

  bool get isWork => !isOff;

  /// A day off that falls on a normal workday, i.e. it adds rest.
  bool get isExtraOff => isOff && !reasons.contains(OffReason.scheduled);

  /// Forced workday on what would otherwise be a day off.
  bool get isExtraWorkday =>
      isWork && (!isScheduledWorkday || holidays.isNotEmpty);
}

class DayClassifier {
  DayClassifier({
    required this.schedule,
    required Map<CalendarDate, List<Holiday>> holidays,
    required this.overrides,
  }) : _holidays = holidays;

  final WorkSchedule schedule;
  final Map<CalendarDate, List<Holiday>> _holidays;
  final Map<CalendarDate, DayOverride> overrides;

  final Map<CalendarDate, DayInfo> _cache = {};

  DayInfo classify(CalendarDate date) =>
      _cache.putIfAbsent(date, () => _classify(date));

  DayInfo _classify(CalendarDate date) {
    final holidays = _holidays[date] ?? const <Holiday>[];
    final scheduled = schedule.isScheduledWorkday(date.weekday);
    final override = overrides[date];

    DayInfo off(Set<OffReason> reasons) => DayInfo(
      date: date,
      isOff: true,
      isScheduledWorkday: scheduled,
      reasons: {...reasons, if (!scheduled) OffReason.scheduled},
      holidays: holidays,
      override: override,
    );

    switch (override?.kind) {
      case OverrideKind.workday:
        return DayInfo(
          date: date,
          isOff: false,
          isScheduledWorkday: scheduled,
          holidays: holidays,
          override: override,
        );
      case OverrideKind.dayOff:
        return off({
          OffReason.custom,
          if (holidays.isNotEmpty) OffReason.publicHoliday,
        });
      case null:
        if (holidays.isNotEmpty) return off({OffReason.publicHoliday});
        if (!scheduled) return off({});
        return DayInfo(date: date, isOff: false, isScheduledWorkday: true);
    }
  }
}
