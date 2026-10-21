import 'package:flutter_test/flutter_test.dart';
import 'package:week_counter/core/calendar_date.dart';
import 'package:week_counter/services/holiday_api.dart';
import 'package:week_counter/services/holiday_repository.dart';
import 'package:week_counter/services/local_store.dart';

import 'fake_nager.dart';

void main() {
  late FakeNager server;
  late InMemoryLocalStore store;
  late HolidayRepository repository;
  final now = DateTime(2026, 10, 21, 12);

  setUp(() {
    server = FakeNager();
    store = InMemoryLocalStore();
    repository = HolidayRepository(store, NagerDateApi(client: server.client));
  });

  test('fetches each year once, then serves the cache', () async {
    final first = await repository.load('RU', {2026, 2027}, now: now);
    expect(server.requests, 2);
    expect(first.loadedYears, {2026, 2027});
    expect(first.byDate[const CalendarDate(2026, 11, 4)]!.single.name,
        'Unity Day');
    expect(first.lastFetched, now);

    await repository.load('RU', {2026, 2027}, now: now);
    expect(server.requests, 2);
  });

  test('refetches stale years and when forced', () async {
    await repository.load('RU', {2026}, now: now);
    await repository.load('RU', {2026}, now: now, force: true);
    expect(server.requests, 2);
    await repository.load(
      'RU',
      {2026},
      now: now.add(const Duration(days: 31)),
    );
    expect(server.requests, 3);
  });

  test('offline uses the stale cache without failing', () async {
    await repository.load('RU', {2026}, now: now);
    server.offline = true;
    final result = await repository.load(
      'RU',
      {2026},
      now: now.add(const Duration(days: 60)),
    );
    expect(result.loadedYears, {2026});
    expect(result.failedYears, isEmpty);
  });

  test('offline with no cache marks the year as failed', () async {
    server.offline = true;
    final result = await repository.load('RU', {2026}, now: now);
    expect(result.failedYears, {2026});
    expect(result.byDate, isEmpty);
  });

  test('cache-only load never touches the network', () async {
    final result = await repository.load(
      'RU',
      {2026},
      now: now,
      network: false,
    );
    expect(server.requests, 0);
    expect(result.loadedYears, isEmpty);
    expect(result.failedYears, isEmpty);
  });

  test('countries fall back to the cache when offline', () async {
    await repository.fetchCountries();
    server.offline = true;
    final countries = await repository.fetchCountries();
    expect(countries.map((c) => c.code), ['RU', 'US']);
  });
}
