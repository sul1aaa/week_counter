import 'package:flutter/foundation.dart';

import '../core/calendar_date.dart';
import '../models/pay.dart';
import 'countdown_engine.dart';
import 'day_classifier.dart';

/// Scheduled work hours in the calendar month of [day]. Holidays, vacation
/// and other days off don't count.
double monthWorkHours(DayClassifier classifier, CalendarDate day) {
  final schedule = classifier.schedule;
  var minutes = 0;
  for (
    var date = CalendarDate(day.year, day.month, 1);
    date.month == day.month;
    date = date.addDays(1)
  ) {
    if (classifier.classify(date).isOff) continue;
    minutes += schedule
        .shiftEndOn(date)
        .difference(schedule.shiftStartOn(date))
        .inMinutes;
  }
  return minutes / 60;
}

/// Pay for one hour of work. A monthly salary is spread over [monthHours].
double hourlyRate(Pay pay, double monthHours) => switch (pay.period) {
  PayPeriod.hour => pay.amount,
  PayPeriod.month => monthHours > 0 ? pay.amount / monthHours : 0,
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
