import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:week_counter/core/calendar_date.dart';
import 'package:week_counter/domain/countdown_engine.dart';
import 'package:week_counter/domain/day_classifier.dart';
import 'package:week_counter/domain/widget_payload.dart';
import 'package:week_counter/l10n/app_localizations.dart';
import 'package:week_counter/models/holiday.dart';
import 'package:week_counter/models/work_schedule.dart';

CountdownSnapshot snapshotAt(DateTime now, {WorkSchedule? schedule}) {
  const unityDay = CalendarDate(2026, 11, 4);
  return CountdownEngine(
    DayClassifier(
      schedule: schedule ?? WorkSchedule.standard,
      holidays: {
        unityDay: [
          const Holiday(
            date: unityDay,
            name: 'Unity Day',
            localName: 'День народного единства',
            countryCode: 'RU',
          ),
        ],
      },
      overrides: const {},
    ),
  ).snapshot(now);
}

void main() {
  setUpAll(initializeDateFormatting);

  final en = lookupAppLocalizations(const Locale('en'));
  final ru = lookupAppLocalizations(const Locale('ru'));
  final now = DateTime(2026, 10, 21, 12);

  test('segments are contiguous and alternate', () {
    final payload = buildWidgetPayload(snapshotAt(now), en);
    final segments = payload.segments;
    expect(segments, hasLength(24));
    expect(segments.first.start, now);
    for (var i = 1; i < segments.length; i++) {
      expect(segments[i].start, segments[i - 1].end);
      expect(segments[i].counting, isNot(segments[i - 1].counting));
    }
  });

  test('first segment counts down to the weekend', () {
    final first = buildWidgetPayload(snapshotAt(now), en).segments.first;
    expect(first.counting, isTrue);
    expect(first.target, DateTime(2026, 10, 23, 18));
    expect(first.end, first.target);
    expect(first.title, 'Weekend in');
    expect(first.subtitle, 'Fri 18:00 · 2 days off');
  });

  test('holiday segment has its name, in Russian too', () {
    // Segments 0–3 are the next two weekends; 4 counts down to Unity Day.
    final enSeg = buildWidgetPayload(snapshotAt(now), en).segments[4];
    expect(enSeg.title, 'Holiday in');
    expect(enSeg.secondary, 'Unity Day');

    final ruPayload = buildWidgetPayload(snapshotAt(now), ru);
    expect(ruPayload.segments.first.title, 'До выходных');
    expect(ruPayload.segments[4].secondary, 'День народного единства');
    expect(ruPayload.strings['dayShort'], 'д');
  });

  test('starts with an off segment while off', () {
    final payload = buildWidgetPayload(
      snapshotAt(DateTime(2026, 10, 24, 10)),
      en,
    );
    final first = payload.segments.first;
    expect(first.counting, isFalse);
    expect(first.title, "You're off!");
    expect(first.subtitle, 'Back to work Mon 09:00');
    expect(first.target, DateTime(2026, 10, 26, 9));
  });

  test('no workdays gives no segments and a message', () {
    final payload = buildWidgetPayload(
      snapshotAt(now, schedule: WorkSchedule.standard.copyWith(workdays: {})),
      en,
    );
    expect(payload.segments, isEmpty);
    expect(payload.strings['empty'], en.noWorkdaysTitle);
  });

  test('boundary times are sorted, future and include day ticks', () {
    final payload = buildWidgetPayload(snapshotAt(now), en);
    final times = payload.boundaryTimes(now);
    expect(times, isNotEmpty);
    expect(times.every((t) => t.isAfter(now)), isTrue);
    for (var i = 1; i < times.length; i++) {
      expect(times[i].isAfter(times[i - 1]), isTrue);
    }
    final friday = DateTime(2026, 10, 23, 18);
    expect(times, contains(friday));
    expect(times, contains(friday.subtract(const Duration(days: 1))));
    expect(times, contains(friday.subtract(const Duration(days: 2))));
  });

  test('encodes to JSON the native widgets can read', () {
    final json =
        jsonDecode(buildWidgetPayload(snapshotAt(now), en).encode())
            as Map<String, dynamic>;
    expect(json['v'], 1);
    final first = (json['segments'] as List).first as Map<String, dynamic>;
    expect(first['mode'], 'countdown');
    expect(first['target'], DateTime(2026, 10, 23, 18).millisecondsSinceEpoch);
  });
}
