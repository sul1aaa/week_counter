import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/holiday.dart';

class HolidayApiException implements Exception {
  HolidayApiException(this.message);

  final String message;

  @override
  String toString() => 'HolidayApiException: $message';
}

/// Client for the free Nager.Date public holiday API (no key needed).
class NagerDateApi {
  NagerDateApi({http.Client? client}) : _client = client ?? http.Client();

  static final _base = Uri.parse('https://date.nager.at/api/v3/');
  static const _timeout = Duration(seconds: 15);

  final http.Client _client;

  Future<List<Country>> fetchCountries() async {
    final body = await _get('AvailableCountries');
    return [
      for (final item in body ?? const [])
        Country.fromNager(item as Map<String, dynamic>),
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  /// National days off for [countryCode] in [year]. Regional holidays and
  /// observances that aren't days off are left out.
  Future<List<Holiday>> fetchHolidays(int year, String countryCode) async {
    final body = await _get('PublicHolidays/$year/$countryCode');
    return [
      for (final item in body ?? const [])
        Holiday.fromNager(item as Map<String, dynamic>),
    ].where((h) => h.isNationalDayOff).toList();
  }

  Future<List<dynamic>?> _get(String path) async {
    final http.Response response;
    try {
      response = await _client.get(_base.resolve(path)).timeout(_timeout);
    } on TimeoutException {
      throw HolidayApiException('Timed out');
    } on http.ClientException catch (e) {
      throw HolidayApiException(e.message);
    }
    switch (response.statusCode) {
      case 200:
        return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      case 204:
        return null;
      default:
        throw HolidayApiException('HTTP ${response.statusCode} for $path');
    }
  }
}
