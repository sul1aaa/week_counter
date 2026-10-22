import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../core/calendar_date.dart';
import '../domain/countdown_engine.dart';
import '../domain/day_classifier.dart';
import '../domain/widget_payload.dart';
import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/holiday.dart';
import '../models/work_schedule.dart';
import '../services/holiday_repository.dart';
import '../services/local_store.dart';
import '../services/prefs_repository.dart';
import '../services/settings_repository.dart';
import '../services/widget_sync.dart';

/// App state: settings, holidays and the current countdown.
///
/// Every change persists the settings, rebuilds the countdown, notifies the
/// UI and pushes fresh data to the home-screen widget.
class AppController extends ChangeNotifier {
  AppController({
    required SettingsRepository settingsRepository,
    required HolidayRepository holidayRepository,
    required this.widgetSync,
    PrefsRepository? prefsRepository,
    this.clock = DateTime.now,
    Locale Function()? deviceLocale,
  }) : _settingsRepository = settingsRepository,
       _holidayRepository = holidayRepository,
       _prefsRepository =
           prefsRepository ?? PrefsRepository(InMemoryLocalStore()),
       _deviceLocale =
           deviceLocale ?? (() => PlatformDispatcher.instance.locale);

  /// How long after time off starts it is still worth celebrating.
  static const celebrateWithin = Duration(days: 2);

  final SettingsRepository _settingsRepository;
  final HolidayRepository _holidayRepository;
  final PrefsRepository _prefsRepository;
  final WidgetSync widgetSync;
  final Clock clock;
  final Locale Function() _deviceLocale;

  AppSettings _settings = const AppSettings();
  UiPrefs _prefs = const UiPrefs();
  HolidayCalendar _holidays = HolidayCalendar.empty;
  List<Country>? _countries;
  bool _loadingHolidays = false;
  int _holidayRequest = 0;
  late CountdownEngine _engine;
  late CountdownSnapshot _snapshot;

  AppSettings get settings => _settings;
  HolidayCalendar get holidays => _holidays;
  List<Country>? get countries => _countries;
  bool get loadingHolidays => _loadingHolidays;
  CountdownSnapshot get snapshot => _snapshot;
  UiPrefs get prefs => _prefs;

  /// Needed years whose holidays couldn't be loaded.
  List<int> get missingYears =>
      (_holidays.failedYears.intersection(_neededYears).toList()..sort());

  String? countryName(String? code) {
    if (code == null) return null;
    return _countries?.where((c) => c.code == code).firstOrNull?.name ?? code;
  }

  DayInfo classify(CalendarDate date) => _engine.classifier.classify(date);

  /// National public holidays from today on, soonest first.
  List<Holiday> upcomingHolidays({int limit = 6}) {
    final today = CalendarDate.fromDateTime(clock());
    return ([
      for (final e in _holidays.byDate.entries)
        if (e.key >= today) ...e.value.where((h) => h.isNationalDayOff),
    ]..sort((a, b) => a.date.compareTo(b.date))).take(limit).toList();
  }

  /// The time off that just started and hasn't been celebrated yet.
  OffBlock? get celebrationDue {
    final state = _snapshot.state;
    if (state is! OffNow) return null;
    final start = state.block.offStart;
    if (start == null) return null;
    if (clock().difference(start) > celebrateWithin) return null;
    final done = _prefs.celebratedUntil;
    if (done != null && !start.isAfter(done)) return null;
    return state.block;
  }

  Future<void> markCelebrated(OffBlock block) =>
      _updatePrefs(_prefs.copyWith(celebratedUntil: block.offStart ?? clock()));

  Future<void> dismissWidgetTip() =>
      _updatePrefs(_prefs.copyWith(widgetTipDone: true));

  Future<void> markOrbTipDone() => _prefs.orbTipDone
      ? Future.value()
      : _updatePrefs(_prefs.copyWith(orbTipDone: true));

  Future<void> _updatePrefs(UiPrefs prefs) {
    _prefs = prefs;
    notifyListeners();
    return _prefsRepository.save(prefs);
  }

  Set<int> get _neededYears {
    final now = clock();
    // In January the countdown may look back into December.
    return {if (now.month == 1) now.year - 1, now.year, now.year + 1};
  }

  Future<void> init() async {
    final saved = await _settingsRepository.load();
    if (saved == null) {
      // First launch: guess the country from the phone's region.
      _settings = AppSettings(
        countryCode: _deviceLocale().countryCode?.toUpperCase(),
      );
      await _settingsRepository.save(_settings);
    } else {
      _settings = saved;
    }
    final prefs = await _prefsRepository.load();
    // Don't greet a new user with a party for a weekend already underway.
    _prefs = prefs ?? UiPrefs(celebratedUntil: clock());
    if (prefs == null) await _prefsRepository.save(_prefs);
    _countries = await _holidayRepository.cachedCountries();
    final code = _settings.countryCode;
    if (code != null) {
      _holidays = await _holidayRepository.load(
        code,
        _neededYears,
        now: clock(),
        network: false,
      );
    }
    _rebuild();
    unawaited(refreshHolidays());
    if (_countries == null) unawaited(_loadCountriesQuietly());
  }

  /// Fetches missing or outdated holidays (all of them when [force] is true).
  Future<void> refreshHolidays({bool force = false}) async {
    final code = _settings.countryCode;
    if (code == null) return;
    final request = ++_holidayRequest;
    _loadingHolidays = true;
    notifyListeners();
    final result = await _holidayRepository.load(
      code,
      _neededYears,
      now: clock(),
      force: force,
    );
    // Ignore results for a country the user has since switched away from.
    if (request != _holidayRequest) return;
    _loadingHolidays = false;
    _holidays = result;
    _rebuild();
  }

  Future<List<Country>> loadCountries() async {
    final countries = await _holidayRepository.fetchCountries();
    _countries = countries;
    notifyListeners();
    return countries;
  }

  Future<void> _loadCountriesQuietly() async {
    try {
      await loadCountries();
    } on Object {
      // Only used for display names; the picker retries on its own.
    }
  }

  Future<void> setCountry(String? code) async {
    _settings = _settings.copyWith(countryCode: () => code);
    _holidayRequest++;
    _loadingHolidays = false;
    _holidays = code == null
        ? HolidayCalendar.empty
        : await _holidayRepository.load(
            code,
            _neededYears,
            now: clock(),
            network: false,
          );
    _rebuild();
    await _settingsRepository.save(_settings);
    if (code != null) unawaited(refreshHolidays());
  }

  Future<void> updateSchedule(WorkSchedule schedule) =>
      _update(_settings.copyWith(schedule: schedule));

  /// Sets or clears (with null) the user's choice for [dates].
  Future<void> setOverride(Iterable<CalendarDate> dates, DayOverride? value) {
    final overrides = {..._settings.overrides};
    for (final date in dates) {
      if (value == null) {
        overrides.remove(date);
      } else {
        overrides[date] = value;
      }
    }
    return _update(_settings.copyWith(overrides: overrides));
  }

  /// Recomputes the countdown, e.g. when a shift ends or the day changes.
  void recompute() {
    _snapshot = _engine.snapshot(clock());
    notifyListeners();
  }

  Future<void> onResume() async {
    _rebuild();
    await refreshHolidays();
  }

  /// The widget's text is localized in Dart, so it is re-sent in the new
  /// language.
  void onLocaleChanged() => unawaited(_pushWidget());

  Future<void> _update(AppSettings settings) async {
    _settings = settings;
    _rebuild();
    await _settingsRepository.save(settings);
  }

  void _rebuild() {
    final holidays = _holidays.countryCode == _settings.countryCode
        ? _holidays.byDate
        : const <CalendarDate, List<Holiday>>{};
    _engine = CountdownEngine(
      DayClassifier(
        schedule: _settings.schedule,
        holidays: holidays,
        overrides: _settings.overrides,
      ),
    );
    _snapshot = _engine.snapshot(clock());
    notifyListeners();
    unawaited(_pushWidget());
  }

  Future<void> _pushWidget() {
    final language = _deviceLocale().languageCode == 'ru' ? 'ru' : 'en';
    final l10n = lookupAppLocalizations(Locale(language));
    return widgetSync.push(buildWidgetPayload(_snapshot, l10n));
  }
}
