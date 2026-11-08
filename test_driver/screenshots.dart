import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:week_counter/app.dart';
import 'package:week_counter/services/holiday_api.dart';
import 'package:week_counter/services/holiday_repository.dart';
import 'package:week_counter/services/local_store.dart';
import 'package:week_counter/services/prefs_repository.dart';
import 'package:week_counter/services/settings_repository.dart';
import 'package:week_counter/services/widget_sync.dart';
import 'package:week_counter/state/app_controller.dart';

/// The app as the App Store screenshots show it: a fresh user, past onboarding,
/// on a clock that test_driver/screenshots_test.dart moves.
///
/// Run with `--dart-define=SHOT_LOCALE=en` (US holidays) or `ru` (Russian ones).
Future<void> main() async {
  // Thursday afternoon: the orb is about three quarters full.
  var now = DateTime(2026, 11, 19, 15);
  enableFlutterDriverExtension(
    handler: (message) async {
      // "time:2026-11-20T18:00:05" moves the clock.
      if (message != null && message.startsWith('time:')) {
        now = DateTime.parse(message.substring(5));
        return 'ok';
      }
      return 'unknown: $message';
    },
  );
  await initializeDateFormatting();

  const language = String.fromEnvironment('SHOT_LOCALE', defaultValue: 'en');
  final locale = language == 'ru'
      ? const Locale('ru', 'RU')
      : const Locale('en', 'US');
  final store = InMemoryLocalStore();
  final controller = AppController(
    settingsRepository: SettingsRepository(store),
    holidayRepository: HolidayRepository(store, NagerDateApi()),
    prefsRepository: PrefsRepository(store),
    widgetSync: NoopWidgetSync(),
    clock: () => now,
    deviceLocales: () => [locale],
  );
  await controller.init();
  await controller.completeOnboarding();

  runApp(WeekCounterApp(controller: controller, locale: Locale(language)));
}
