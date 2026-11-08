import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

/// Taps through test_driver/screenshots.dart and saves real simulator screenshots,
/// status bar included, for the App Store.
///
/// ```sh
/// SHOTS_DEVICE=<simulator id> SHOTS_DIR=<folder> SHOTS_LOCALE=en flutter drive \
///   --driver=test_driver/screenshots_test.dart --target=test_driver/screenshots.dart \
///   -d <simulator id> --dart-define=SHOT_LOCALE=en
/// ```
Future<void> main() async {
  final device = Platform.environment['SHOTS_DEVICE']!;
  final dir = Platform.environment['SHOTS_DIR']!;
  // The "Weekend!" screen's button, from lib/l10n (celebrateCta).
  final restButton = Platform.environment['SHOTS_LOCALE'] == 'ru'
      ? 'Ура, отдыхаю'
      : 'Yay, time to rest';
  Directory(dir).createSync(recursive: true);

  final driver = await FlutterDriver.connect();
  // The orb never stops moving, so don't wait for the app to settle.
  Future<void> tap(String key) =>
      driver.runUnsynchronized(() => driver.tap(find.byValueKey(key)));
  Future<void> simctl(List<String> args) async {
    final result = await Process.run('xcrun', ['simctl', ...args]);
    if (result.exitCode != 0) throw Exception(result.stderr);
  }

  /// The status bar shows the app's clock [time], full battery and signal.
  /// simctl takes the time only as UTC ISO 8601 with milliseconds.
  Future<void> statusBar(DateTime time) => simctl([
    ...['status_bar', device, 'override'],
    ...['--time', time.toUtc().toIso8601String()],
    ...['--batteryState', 'charged', '--batteryLevel', '100'],
    ...['--cellularBars', '4', '--wifiBars', '3'],
  ]);
  Future<void> shot(String name) async {
    // Let page transitions and the holiday download finish.
    await Future<void>.delayed(const Duration(seconds: 3));
    await simctl(['io', device, 'screenshot', '$dir/$name.png']);
    stdout.writeln('saved $dir/$name.png');
  }

  // Same times as test_driver/screenshots.dart.
  await statusBar(DateTime(2026, 11, 19, 15));
  await driver.runUnsynchronized(driver.waitUntilFirstFrameRasterized);
  await shot('week');
  await tap('tab.calendar');
  await shot('calendar');

  // Friday 18:00: the weekend starts and the app celebrates.
  await tap('tab.countdown');
  final weekend = DateTime(2026, 11, 20, 18, 0, 5);
  await statusBar(weekend);
  await driver.runUnsynchronized(
    () => driver.requestData('time:${weekend.toIso8601String()}'),
  );
  await Future<void>.delayed(const Duration(seconds: 3));
  await shot('weekend');

  // The weekend earned the first award.
  await driver.runUnsynchronized(() => driver.tap(find.text(restButton)));
  await Future<void>.delayed(const Duration(seconds: 2));
  await tap('tab.awards');
  await shot('awards');

  await driver.close();
}
