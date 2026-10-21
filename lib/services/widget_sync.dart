import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../domain/widget_payload.dart';

/// Sends countdown data to the native home-screen widgets.
abstract interface class WidgetSync {
  Future<void> push(WidgetPayload payload);

  /// Android only: whether the widget can tick every second (exact alarms).
  Future<bool> canScheduleExact();

  /// Android only: whether the launcher supports adding a widget from the app.
  Future<bool> canPinWidget();
  Future<void> pinWidget();

  /// Android 12+: opens the "Alarms & reminders" permission screen.
  Future<void> openExactAlarmSettings();
}

class HomeWidgetSync implements WidgetSync {
  static const appGroupId = 'group.com.example.weekCounter';
  static const iOSName = 'WeekCounterWidget';
  static const androidName =
      'com.example.week_counter.WeekCounterWidgetProvider';
  static const _system = MethodChannel('week_counter/system');

  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Must run before the first [push] so iOS writes to the shared App Group.
  static Future<void> init() async {
    if (!kIsWeb && Platform.isIOS) {
      await HomeWidget.setAppGroupId(appGroupId);
    }
  }

  Future<void> _pending = Future.value();

  @override
  Future<void> push(WidgetPayload payload) =>
      _pending = _pending.then((_) => _push(payload));

  Future<void> _push(WidgetPayload payload) async {
    try {
      await HomeWidget.saveWidgetData<String>(
        widgetPayloadKey,
        payload.encode(),
      );
      await HomeWidget.updateWidget(
        iOSName: iOSName,
        qualifiedAndroidName: androidName,
      );
      if (Platform.isAndroid) {
        await HomeWidget.scheduleWidgetUpdates(
          payload.boundaryTimes(DateTime.now()),
          qualifiedAndroidName: androidName,
        );
      }
    } on PlatformException catch (e) {
      // Before the iOS App Group is set up the widget simply has no data.
      debugPrint('Widget update failed: $e');
    }
  }

  @override
  Future<bool> canScheduleExact() async {
    if (!Platform.isAndroid) return true;
    return await HomeWidget.canScheduleExactWidgetUpdates() ?? true;
  }

  @override
  Future<bool> canPinWidget() async {
    if (!Platform.isAndroid) return false;
    return await HomeWidget.isRequestPinWidgetSupported() ?? false;
  }

  @override
  Future<void> pinWidget() =>
      HomeWidget.requestPinWidget(qualifiedAndroidName: androidName);

  @override
  Future<void> openExactAlarmSettings() =>
      _system.invokeMethod('openExactAlarmSettings');
}

/// Used in tests and on platforms without home-screen widgets.
class NoopWidgetSync implements WidgetSync {
  WidgetPayload? lastPayload;

  @override
  Future<void> push(WidgetPayload payload) async => lastPayload = payload;

  @override
  Future<bool> canScheduleExact() async => true;

  @override
  Future<bool> canPinWidget() async => false;

  @override
  Future<void> pinWidget() async {}

  @override
  Future<void> openExactAlarmSettings() async {}
}
