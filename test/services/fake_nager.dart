import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A fake Nager.Date server with Russian holidays for 2026 and 2027.
class FakeNager {
  int requests = 0;
  bool offline = false;

  static const holidays = {
    '2026': [
      {
        'date': '2026-11-04',
        'localName': 'День народного единства',
        'name': 'Unity Day',
        'countryCode': 'RU',
        'global': true,
        'types': ['Public'],
      },
    ],
    '2027': [
      {
        'date': '2027-01-01',
        'localName': 'Новый год',
        'name': "New Year's Day",
        'countryCode': 'RU',
        'global': true,
        'types': ['Public'],
      },
    ],
  };

  late final client = MockClient((request) async {
    requests++;
    if (offline) throw http.ClientException('offline');
    final segments = request.url.pathSegments;
    if (segments.last == 'AvailableCountries') {
      return _json([
        {'countryCode': 'US', 'name': 'United States'},
        {'countryCode': 'RU', 'name': 'Russia'},
      ]);
    }
    if (segments.contains('PublicHolidays') && segments.last == 'RU') {
      return _json(holidays[segments[segments.length - 2]] ?? const []);
    }
    return http.Response('', 404);
  });

  static http.Response _json(Object body) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    200,
    headers: {'content-type': 'application/json'},
  );
}
