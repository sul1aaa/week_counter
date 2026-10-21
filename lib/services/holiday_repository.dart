import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/calendar_date.dart';
import '../models/holiday.dart';
import 'holiday_api.dart';
import 'local_store.dart';

/// Public holidays for one country across the years the app needs.
@immutable
class HolidayCalendar {
  const HolidayCalendar({
    this.countryCode,
    this.byDate = const {},
    this.loadedYears = const {},
    this.failedYears = const {},
    this.lastFetched,
  });

  static const empty = HolidayCalendar();

  final String? countryCode;
  final Map<CalendarDate, List<Holiday>> byDate;

  /// Years with holiday data, fresh or cached.
  final Set<int> loadedYears;

  /// Years that couldn't be fetched and have no cached copy.
  final Set<int> failedYears;
  final DateTime? lastFetched;

  List<Holiday> inMonth(int year, int month) => [
    for (final e in byDate.entries)
      if (e.key.year == year && e.key.month == month) ...e.value,
  ]..sort((a, b) => a.date.compareTo(b.date));
}

/// Fetches holidays from Nager.Date and caches each country and year so the
/// app works offline.
class HolidayRepository {
  HolidayRepository(
    this._store,
    this._api, {
    this.maxAge = const Duration(days: 30),
  });

  static const _countriesKey = 'countries.v1';

  final LocalStore _store;
  final NagerDateApi _api;

  /// Cached years older than this are fetched again.
  final Duration maxAge;

  static String _yearKey(String countryCode, int year) =>
      'holidays.v1.$countryCode.$year';

  /// Loads [years] for [countryCode] from the cache, fetching missing or
  /// stale years when [network] is true (all of them when [force] is true).
  Future<HolidayCalendar> load(
    String countryCode,
    Set<int> years, {
    required DateTime now,
    bool network = true,
    bool force = false,
  }) async {
    final byDate = <CalendarDate, List<Holiday>>{};
    final loaded = <int>{};
    final failed = <int>{};
    DateTime? lastFetched;

    for (final year in years) {
      var cached = await _readYear(countryCode, year);
      final stale =
          cached == null || force || now.difference(cached.fetchedAt) > maxAge;
      if (network && stale) {
        try {
          final items = await _api.fetchHolidays(year, countryCode);
          cached = _CachedYear(now, items);
          await _store.setString(
            _yearKey(countryCode, year),
            jsonEncode(cached.toJson()),
          );
        } on Object {
          if (cached == null) failed.add(year);
        }
      }
      if (cached == null) continue;
      loaded.add(year);
      for (final h in cached.items) {
        byDate.putIfAbsent(h.date, () => []).add(h);
      }
      if (lastFetched == null || cached.fetchedAt.isAfter(lastFetched)) {
        lastFetched = cached.fetchedAt;
      }
    }

    return HolidayCalendar(
      countryCode: countryCode,
      byDate: byDate,
      loadedYears: loaded,
      failedYears: failed,
      lastFetched: lastFetched,
    );
  }

  Future<List<Country>?> cachedCountries() async {
    final raw = await _store.getString(_countriesKey);
    if (raw == null) return null;
    return [
      for (final item in jsonDecode(raw) as List)
        Country.fromNager(item as Map<String, dynamic>),
    ];
  }

  /// Fetches the country list, falling back to the cache when offline.
  Future<List<Country>> fetchCountries() async {
    try {
      final countries = await _api.fetchCountries();
      await _store.setString(
        _countriesKey,
        jsonEncode([for (final c in countries) c.toJson()]),
      );
      return countries;
    } on Object {
      final cached = await cachedCountries();
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<_CachedYear?> _readYear(String countryCode, int year) async {
    final raw = await _store.getString(_yearKey(countryCode, year));
    if (raw == null) return null;
    try {
      return _CachedYear.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }
}

class _CachedYear {
  _CachedYear(this.fetchedAt, this.items);

  factory _CachedYear.fromJson(Map<String, dynamic> json) => _CachedYear(
    DateTime.fromMillisecondsSinceEpoch(json['fetchedAt'] as int),
    [
      for (final item in json['items'] as List)
        Holiday.fromNager(item as Map<String, dynamic>),
    ],
  );

  final DateTime fetchedAt;
  final List<Holiday> items;

  Map<String, dynamic> toJson() => {
    'fetchedAt': fetchedAt.millisecondsSinceEpoch,
    'items': [for (final h in items) h.toJson()],
  };
}
