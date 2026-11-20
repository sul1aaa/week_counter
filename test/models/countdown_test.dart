import 'package:flutter_test/flutter_test.dart';
import 'package:week_counter/core/calendar_date.dart';
import 'package:week_counter/models/app_settings.dart';
import 'package:week_counter/models/countdown.dart';
import 'package:week_counter/models/work_schedule.dart';

void main() {
  const trip = Countdown(
    id: '1',
    title: 'Trip to Almaty',
    date: CalendarDate(2026, 12, 24),
  );

  test('a countdown survives a JSON round trip', () {
    expect(Countdown.fromJson(trip.toJson()), trip);
    expect(trip.target, DateTime(2026, 12, 24));
  });

  test('settings keep their countdowns', () {
    final settings = AppSettings.fromJson(
      const AppSettings(countdowns: [trip]).toJson(),
    );
    expect(settings.countdowns, [trip]);
  });

  test('settings saved before countdowns still load', () {
    final settings = AppSettings.fromJson({
      'countryCode': 'RU',
      'schedule': WorkSchedule.standard.toJson(),
      'overrides': <String, dynamic>{},
    });
    expect(settings.countryCode, 'RU');
    expect(settings.countdowns, isEmpty);
  });
}
