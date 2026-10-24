import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../core/calendar_date.dart';
import '../domain/awards.dart';
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
  String? _freshAward;

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

  /// The award earned when the latest time off started, once.
  String? takeFreshAward() {
    final id = _freshAward;
    _freshAward = null;
    return id;
  }

  /// Gives the award [id] if it isn't earned yet. True if it is new.
  bool earn(String id) {
    if (_prefs.earned.containsKey(id)) return false;
    unawaited(
      _updatePrefs(_prefs.copyWith(earned: {..._prefs.earned, id: clock()})),
    );
    return true;
  }

  Future<void> completeOnboarding() =>
      _updatePrefs(_prefs.copyWith(onboarded: true));

  Future<void> setConfetti(bool on) =>
      _updatePrefs(_prefs.copyWith(confetti: on));

  /// The vacation that is on now or comes next.
  ({CalendarDate first, CalendarDate last})? get vacation {
    final today = CalendarDate.fromDateTime(clock());
    final dates = [
      for (final e in _settings.overrides.entries)
        if (e.value.vacation) e.key,
    ]..sort();
    for (var i = 0; i < dates.length; i++) {
      final first = dates[i];
      var last = first;
      while (i + 1 < dates.length && dates[i + 1] == last.addDays(1)) {
        last = dates[++i];
      }
      if (last >= today) return (first: first, last: last);
    }
    return null;
  }

  /// Marks [days] days from [first] as vacation.
  Future<void> planVacation(CalendarDate first, int days, String note) {
    earn('vacation');
    return setOverride([
      for (var i = 0; i < days; i++) first.addDays(i),
    ], DayOverride(OverrideKind.dayOff, note: note, vacation: true));
  }

  /// Cancels the coming vacation, or ends the current one today.
  Future<void> cancelVacation() {
    final range = vacation;
    if (range == null) return Future.value();
    final today = CalendarDate.fromDateTime(clock());
    final from = range.first < today ? today : range.first;
    return setOverride([
      for (var d = from; d <= range.last; d = d.addDays(1)) d,
    ], null);
  }

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
    // Don't greet a new user with a party for a weekend already underway,
    // and count weekends from now on.
    _prefs =
        prefs ??
        UiPrefs(
          onboarded: saved != null,
          celebratedUntil: clock(),
          countedUntil: clock(),
        );
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
    _countTimeOff();
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
    _acceptChange();
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
    _countTimeOff();
    notifyListeners();
  }

  Future<void> onResume() async {
    _rebuild();
    _countTimeOff();
    await refreshHolidays();
  }

  /// The widget's text is localized in Dart, so it is re-sent in the new
  /// language.
  void onLocaleChanged() => unawaited(_pushWidget());

  Future<void> _update(AppSettings settings) async {
    _settings = settings;
    _rebuild();
    _acceptChange();
    await _settingsRepository.save(settings);
  }

  /// After the user edits the schedule, time off that "started" only
  /// because of the edit is neither counted nor celebrated.
  void _acceptChange() {
    final state = _snapshot.state;
    final start = state is OffNow ? state.block.offStart : null;
    final celebrated = _prefs.celebratedUntil;
    _prefs = _prefs.copyWith(
      countedUntil: clock(),
      celebratedUntil:
          start != null && (celebrated == null || start.isAfter(celebrated))
          ? start
          : null,
    );
    unawaited(_prefsRepository.save(_prefs));
  }

  /// Counts time off that started since the last look, and hands out
  /// weekly and special awards for it.
  void _countTimeOff() {
    final now = clock();
    final from = _prefs.countedUntil;
    if (from != null && !now.isAfter(from)) return;
    final starts = from == null
        ? const <({DateTime start, CalendarDate lastWorkday})>[]
        : _engine.timeOffStarts(from, now);
    var weeks = _prefs.weeks;
    final earned = {..._prefs.earned};
    void give(String id, DateTime at) {
      if (earned.containsKey(id)) return;
      earned[id] = at;
      _freshAward = id;
    }

    for (final (:start, :lastWorkday) in starts) {
      weeks++;
      for (final award in awards) {
        if (award.weeks == weeks) give(award.id, start);
      }
      // The day the week ended, even if its last shift ran past midnight.
      if (lastWorkday.weekday == DateTime.friday && lastWorkday.day == 13) {
        give('friday13', start);
      }
      // A holiday on a workday anywhere in the time off, such as the
      // Monday after the weekend. Two weeks covers the longest holidays.
      final daysOff = [
        for (var i = 1; i <= 14; i++) classify(lastWorkday.addDays(i)),
      ].takeWhile((day) => day.isOff);
      if (daysOff.any(
        (day) =>
            day.isScheduledWorkday &&
            day.reasons.contains(OffReason.publicHoliday),
      )) {
        give('shortWeek', start);
      }
      if (_settings.schedule.shiftFor(lastWorkday.weekday).isOvernight) {
        give('nightShift', start);
      }
    }
    _prefs = _prefs.copyWith(countedUntil: now, weeks: weeks, earned: earned);
    unawaited(_prefsRepository.save(_prefs));
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
