import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:week_counter/core/calendar_date.dart';
import 'package:week_counter/services/holiday_api.dart';

NagerDateApi apiReturning(int status, [Object? body]) => NagerDateApi(
  client: MockClient(
    (_) async => http.Response.bytes(
      body == null ? const [] : utf8.encode(jsonEncode(body)),
      status,
    ),
  ),
);

void main() {
  test('keeps only national days off', () async {
    final api = apiReturning(200, [
      {
        'date': '2026-10-03',
        'localName': 'Tag der Deutschen Einheit',
        'name': 'German Unity Day',
        'countryCode': 'DE',
        'global': true,
        'types': ['Public'],
      },
      {
        'date': '2026-10-31',
        'localName': 'Reformationstag',
        'name': 'Reformation Day',
        'countryCode': 'DE',
        'global': false,
        'counties': ['DE-BB'],
        'types': ['Public'],
      },
      {
        'date': '2026-12-24',
        'localName': 'Heiligabend',
        'name': 'Christmas Eve',
        'countryCode': 'DE',
        'global': true,
        'types': ['Observance'],
      },
    ]);
    final holidays = await api.fetchHolidays(2026, 'DE');
    expect(holidays, hasLength(1));
    expect(holidays.single.date, const CalendarDate(2026, 10, 3));
    expect(holidays.single.localName, 'Tag der Deutschen Einheit');
  });

  test('204 means no holidays', () async {
    expect(await apiReturning(204).fetchHolidays(2026, 'XX'), isEmpty);
  });

  test('404 throws', () {
    expect(
      apiReturning(404).fetchHolidays(2026, 'XX'),
      throwsA(isA<HolidayApiException>()),
    );
  });

  test('network errors throw HolidayApiException', () {
    final api = NagerDateApi(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    expect(api.fetchCountries(), throwsA(isA<HolidayApiException>()));
  });

  test('countries are sorted by name', () async {
    final api = apiReturning(200, [
      {'countryCode': 'US', 'name': 'United States'},
      {'countryCode': 'DE', 'name': 'Germany'},
    ]);
    final countries = await api.fetchCountries();
    expect(countries.map((c) => c.code), ['DE', 'US']);
  });
}
