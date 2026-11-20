import 'package:flutter/foundation.dart';

import '../core/calendar_date.dart';
import '../models/pay.dart';
import 'countdown_engine.dart';
import 'day_classifier.dart';

/// The days that pay per [period] is spread over, for a shift on [day]:
/// the day itself, its week from Monday to Sunday, or its calendar month.
/// Pay every two weeks goes half to each week. Null for hourly pay.
({CalendarDate first, CalendarDate last})? paySpan(
  PayPeriod period,
  CalendarDate day,
) => switch (period) {
  PayPeriod.hour => null,
  PayPeriod.day => (first: day, last: day),
  PayPeriod.week || PayPeriod.twoWeeks => (
    first: day.addDays(DateTime.monday - day.weekday),
    last: day.addDays(DateTime.sunday - day.weekday),
  ),
  PayPeriod.month => (
    first: CalendarDate(day.year, day.month, 1),
    last: CalendarDate.fromDateTime(DateTime.utc(day.year, day.month + 1, 0)),
  ),
};

/// Scheduled work hours from [first] to [last], both included. Holidays,
/// vacation and other days off don't count.
double workHours(
  DayClassifier classifier,
  CalendarDate first,
  CalendarDate last,
) {
  final schedule = classifier.schedule;
  var minutes = 0;
  for (var date = first; date <= last; date = date.addDays(1)) {
    if (classifier.classify(date).isOff) continue;
    minutes += schedule
        .shiftEndOn(date)
        .difference(schedule.shiftStartOn(date))
        .inMinutes;
  }
  return minutes / 60;
}

/// Pay for one hour of work. Other pay is spread over the [spanHours] of
/// work in its [paySpan].
double hourlyRate(Pay pay, double spanHours) => switch (pay.period) {
  PayPeriod.hour => pay.amount,
  _ when spanHours <= 0 => 0,
  PayPeriod.twoWeeks => pay.amount / 2 / spanHours,
  _ => pay.amount / spanHours,
};

/// Money earned in [shift] by [now] at [perHour]: nothing before it starts,
/// all of it once it ends.
double earnedIn(DayShift shift, DateTime now, double perHour) =>
    perHour *
    shift.progress(now) *
    shift.end.difference(shift.start).inSeconds /
    Duration.secondsPerHour;

/// Money earned in today's shift so far.
@immutable
class Earned {
  const Earned({
    required this.amount,
    required this.perHour,
    required this.currency,
  });

  final double amount;
  final double perHour;
  final String currency;

  /// Under 1000 an hour a whole unit takes more than 3.6 seconds to earn, so
  /// cents keep the ticker moving.
  bool get cents => perHour < 1000;
}
