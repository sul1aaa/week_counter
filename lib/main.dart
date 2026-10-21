import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'services/holiday_api.dart';
import 'services/holiday_repository.dart';
import 'services/local_store.dart';
import 'services/settings_repository.dart';
import 'services/widget_sync.dart';
import 'state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The widget text is formatted before MaterialApp loads any locale data.
  await initializeDateFormatting();
  if (HomeWidgetSync.isSupported) await HomeWidgetSync.init();

  final store = SharedPrefsLocalStore();
  final controller = AppController(
    settingsRepository: SettingsRepository(store),
    holidayRepository: HolidayRepository(store, NagerDateApi()),
    widgetSync: HomeWidgetSync.isSupported
        ? HomeWidgetSync()
        : NoopWidgetSync(),
  );
  await controller.init();

  runApp(WeekCounterApp(controller: controller));
}
