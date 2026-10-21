import 'package:flutter/foundation.dart';

/// Returns the current time. Injected so tests can freeze "now".
typedef Clock = DateTime Function();

/// A calendar day with no time of day and no time zone.
///
/// Day arithmetic goes through UTC so daylight-saving changes never skip or
/// repeat a day. Wall-clock times are built in local time with [at].
@immutable
class CalendarDate implements Comparable<CalendarDate> {
  const CalendarDate(this.year, this.month, this.day);

  factory CalendarDate.fromDateTime(DateTime dateTime) =>
      CalendarDate(dateTime.year, dateTime.month, dateTime.day);

  /// Parses `yyyy-MM-dd`.
  factory CalendarDate.parse(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) {
      throw FormatException('Expected yyyy-MM-dd', iso);
    }
    return CalendarDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  /// [DateTime.monday] (1) through [DateTime.sunday] (7).
  int get weekday => _utc.weekday;

  CalendarDate addDays(int days) =>
      CalendarDate.fromDateTime(DateTime.utc(year, month, day + days));

  /// Whole days from this date to [other]; negative if [other] is earlier.
  int daysUntil(CalendarDate other) => other._utc.difference(_utc).inDays;

  /// Local wall-clock time on this day.
  DateTime at(int hour, int minute) => DateTime(year, month, day, hour, minute);

  /// Local midnight at the start of this day.
  DateTime get startOfDay => DateTime(year, month, day);

  bool operator <(CalendarDate other) => compareTo(other) < 0;
  bool operator <=(CalendarDate other) => compareTo(other) <= 0;
  bool operator >(CalendarDate other) => compareTo(other) > 0;
  bool operator >=(CalendarDate other) => compareTo(other) >= 0;

  @override
  int compareTo(CalendarDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is CalendarDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  String toIso() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  String toString() => toIso();
}
