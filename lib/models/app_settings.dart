import 'package:flutter/foundation.dart';

import '../core/calendar_date.dart';
import 'work_schedule.dart';

enum OverrideKind { dayOff, workday }

/// The user's own decision for one calendar day, replacing the automatic
/// weekend/holiday classification.
@immutable
class DayOverride {
  const DayOverride(this.kind, {this.note, this.vacation = false});

  factory DayOverride.fromJson(Map<String, dynamic> json) => DayOverride(
    OverrideKind.values.byName(json['kind'] as String),
    note: json['note'] as String?,
    vacation: json['vacation'] as bool? ?? false,
  );

  final OverrideKind kind;
  final String? note;

  /// Part of a vacation planned on the Vacation screen.
  final bool vacation;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    if (note != null && note!.isNotEmpty) 'note': note,
    if (vacation) 'vacation': true,
  };
}

@immutable
class AppSettings {
  const AppSettings({
    this.countryCode,
    this.schedule = WorkSchedule.standard,
    this.overrides = const {},
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    countryCode: json['countryCode'] as String?,
    schedule: WorkSchedule.fromJson(json['schedule'] as Map<String, dynamic>),
    overrides: {
      for (final e in (json['overrides'] as Map<String, dynamic>? ?? {})
          .entries)
        CalendarDate.parse(e.key): DayOverride.fromJson(
          e.value as Map<String, dynamic>,
        ),
    },
  );

  /// ISO 3166-1 alpha-2 code used for public holidays; null means none.
  final String? countryCode;
  final WorkSchedule schedule;
  final Map<CalendarDate, DayOverride> overrides;

  AppSettings copyWith({
    ValueGetter<String?>? countryCode,
    WorkSchedule? schedule,
    Map<CalendarDate, DayOverride>? overrides,
  }) => AppSettings(
    countryCode: countryCode != null ? countryCode() : this.countryCode,
    schedule: schedule ?? this.schedule,
    overrides: overrides ?? this.overrides,
  );

  Map<String, dynamic> toJson() => {
    'countryCode': countryCode,
    'schedule': schedule.toJson(),
    'overrides': {
      for (final e in overrides.entries) e.key.toIso(): e.value.toJson(),
    },
  };
}
