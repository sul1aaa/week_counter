import 'package:intl/intl.dart';

import '../core/calendar_date.dart';
import '../domain/countdown_engine.dart';
import '../models/holiday.dart';
import 'app_localizations.dart';

/// Wording and date formats shared by the app and the home-screen widget.
extension Labels on AppLocalizations {
  String untilTitle(BlockKind kind) => switch (kind) {
    BlockKind.weekend => untilWeekend,
    BlockKind.longWeekend => untilLongWeekend,
    BlockKind.holiday => untilHoliday,
    BlockKind.daysOff => untilDaysOff,
  };

  String kindLabel(BlockKind kind) => switch (kind) {
    BlockKind.weekend => kindWeekend,
    BlockKind.longWeekend => kindLongWeekend,
    BlockKind.holiday => kindHoliday,
    BlockKind.daysOff => kindDaysOff,
  };

  /// Russian names for Russian holidays, English names otherwise.
  String holidayName(Holiday holiday) =>
      localeName.startsWith('ru') && holiday.countryCode == 'RU'
      ? holiday.localName
      : holiday.name;

  /// Holiday names and notes in [block], or null for a plain weekend.
  String? blockDetails(OffBlock block) {
    final names = <String>{
      for (final h in block.holidays) holidayName(h),
      ...block.notes,
    };
    return names.isEmpty ? null : names.join(', ');
  }

  /// "Fri, Oct 23".
  String date(CalendarDate date) =>
      DateFormat.MMMEd(localeName).format(date.startOfDay);

  /// "Friday, October 23, 2026".
  String longDate(CalendarDate date) =>
      DateFormat.yMMMMEEEEd(localeName).format(date.startOfDay);

  /// "Mon" for [DateTime.monday].
  String weekdayShort(int weekday) =>
      // 1 January 2024 was a Monday.
      DateFormat.E(localeName).format(DateTime(2024, 1, weekday));

  /// "Fri, Oct 23 – Sun, Oct 25", or one date for a single day.
  String dateRange(CalendarDate first, CalendarDate last) =>
      first == last ? date(first) : '${date(first)} – ${date(last)}';

  /// "18:00".
  String time(DateTime time) => DateFormat.Hm(localeName).format(time);

  /// "Fri, Oct 23, 18:00".
  String dateTime(DateTime time) =>
      '${date(CalendarDate.fromDateTime(time))}, ${this.time(time)}';

  /// "Fri 18:00" within the coming week of [from], "Oct 23, 18:00" after.
  String shortWhen(DateTime time, DateTime from) {
    final day = time.difference(from) < const Duration(days: 6)
        ? DateFormat.E(localeName).format(time)
        : DateFormat.MMMd(localeName).format(time);
    return '$day ${this.time(time)}';
  }

  /// "today, 18:00", "tomorrow, 09:00", "Friday, 18:00" within the coming
  /// week of [from], "Oct 30, 18:00" after.
  String when(DateTime time, DateTime from) {
    final days = CalendarDate.fromDateTime(
      from,
    ).daysUntil(CalendarDate.fromDateTime(time));
    final day = switch (days) {
      0 => whenToday,
      1 => whenTomorrow,
      > 1 && < 7 => DateFormat.EEEE(localeName).format(time),
      _ => DateFormat.MMMd(localeName).format(time),
    };
    return whenAt(day, this.time(time));
  }

  /// Upper-case weekday initials for the week strip and month grid: "MON".
  String weekdayCaps(int weekday) => weekdayShort(weekday).toUpperCase();

  /// "2 days 4 hours", "3 hours 20 min", "47 min" or "12 seconds".
  String humanDuration(Duration duration) {
    final d = duration.isNegative ? Duration.zero : duration;
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    if (days > 0) {
      return hours == 0
          ? durationDays(days)
          : '${durationDays(days)} ${durationHours(hours)}';
    }
    if (hours > 0) {
      return minutes == 0
          ? durationHours(hours)
          : '${durationHours(hours)} ${durationMinutes(minutes)}';
    }
    if (minutes > 0) return durationMinutes(minutes);
    return durationSeconds(d.inSeconds);
  }

  /// "2d 3h", "3h 20m" or "20m".
  String compactDuration(Duration duration) {
    final d = duration.isNegative ? Duration.zero : duration;
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    if (days > 0) return '$days$dayShort $hours$hourShort';
    if (hours > 0) return '$hours$hourShort $minutes$minuteShort';
    return '$minutes$minuteShort';
  }
}
