import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:week_counter/app.dart';
import 'package:week_counter/core/calendar_date.dart';
import 'package:week_counter/services/holiday_api.dart';
import 'package:week_counter/services/holiday_repository.dart';
import 'package:week_counter/services/local_store.dart';
import 'package:week_counter/services/prefs_repository.dart';
import 'package:week_counter/services/settings_repository.dart';
import 'package:week_counter/services/widget_sync.dart';
import 'package:week_counter/state/app_controller.dart';
import 'package:week_counter/ui/widgets/joke_carousel.dart';

import 'services/fake_nager.dart';

void main() {
  setUpAll(initializeDateFormatting);

  late NoopWidgetSync widgetSync;
  // Wednesday noon.
  var now = DateTime(2026, 10, 21, 12);

  setUp(() => now = DateTime(2026, 10, 21, 12));

  Future<AppController> createController({
    bool onboarded = true,
    List<Locale> Function()? deviceLocales,
  }) async {
    final store = InMemoryLocalStore();
    widgetSync = NoopWidgetSync();
    final controller = AppController(
      settingsRepository: SettingsRepository(store),
      holidayRepository: HolidayRepository(
        store,
        NagerDateApi(client: FakeNager().client),
      ),
      prefsRepository: PrefsRepository(store),
      widgetSync: widgetSync,
      clock: () => now,
      deviceLocales: deviceLocales ?? () => const [Locale('ru', 'RU')],
    );
    await controller.init();
    if (onboarded) await controller.completeOnboarding();
    return controller;
  }

  /// The orb and confetti move forever unless motion is reduced.
  void reduceMotion(WidgetTester tester) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  Future<void> openTab(WidgetTester tester, String name) async {
    await tester.tap(find.byKey(ValueKey('tab.$name')));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the countdown and navigates between tabs', (tester) async {
    reduceMotion(tester);
    final controller = await createController();
    await tester.pumpWidget(
      WeekCounterApp(controller: controller, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    // The country was guessed from the phone's region.
    expect(controller.settings.countryCode, 'RU');
    expect(find.text('Wed, October 21'), findsOneWidget);
    expect(find.text('until'), findsOneWidget);
    expect(find.text('Friday'), findsOneWidget);
    expect(find.text('freedom'), findsOneWidget);
    expect(find.textContaining('of the week done'), findsOneWidget);
    expect(find.text('tap the orb for a new line'), findsOneWidget);
    await tester.scrollUntilVisible(find.byType(JokeCarousel), 200);
    expect(find.byType(JokeCarousel), findsOneWidget);

    await openTab(tester, 'calendar');
    expect(find.text('October'), findsOneWidget);
    expect(find.text('Days off in October'), findsOneWidget);
    expect(find.text('Russia'), findsOneWidget);

    await openTab(tester, 'awards');
    expect(find.text('First Friday'), findsOneWidget);
    expect(find.text('no awards yet'), findsOneWidget);

    await openTab(tester, 'countdown');
    await tester.tap(find.byTooltip('Schedule'));
    await tester.pumpAndSettle();
    expect(find.text('Week starts'), findsOneWidget);
    expect(find.text('Vacation'), findsOneWidget);
  });

  testWidgets('renders in Russian and feeds the widget', (tester) async {
    reduceMotion(tester);
    final controller = await createController();
    await tester.pumpWidget(
      WeekCounterApp(controller: controller, locale: const Locale('ru')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ср, 21 октября'), findsOneWidget);
    expect(find.text('до'), findsOneWidget);
    expect(find.text('пятницы'), findsOneWidget);
    expect(find.text('свободы'), findsOneWidget);

    final payload = widgetSync.lastPayload!;
    expect(payload.locale, 'ru');
    expect(payload.segments.first.title, 'До выходных');
  });

  testWidgets('the app and the widget pick the same language', (tester) async {
    reduceMotion(tester);
    tester.platformDispatcher.localesTestValue = const [
      Locale('uk', 'UA'),
      Locale('ru', 'RU'),
    ];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final controller = await createController(
      deviceLocales: () => tester.platformDispatcher.locales,
    );
    await tester.pumpWidget(WeekCounterApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Ср, 21 октября'), findsOneWidget);
    expect(widgetSync.lastPayload!.locale, 'ru');
  });

  testWidgets('unchecking every workday shows the empty state', (tester) async {
    reduceMotion(tester);
    final controller = await createController();
    await controller.updateSchedule(
      controller.settings.schedule.copyWith(workdays: {}),
    );
    await tester.pumpWidget(
      WeekCounterApp(controller: controller, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    expect(find.text('No workdays set'), findsOneWidget);
    await tester.tap(find.text('Open schedule'));
    await tester.pumpAndSettle();
    expect(find.text('Week starts'), findsOneWidget);
  });

  testWidgets('first launch walks through onboarding', (tester) async {
    reduceMotion(tester);
    final controller = await createController(onboarded: false);
    await tester.pumpWidget(
      WeekCounterApp(controller: controller, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('How do you work?'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('When is your work week?'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(controller.prefs.onboarded, isTrue);
    expect(find.text('freedom'), findsOneWidget);
  });

  testWidgets('celebrates once when the weekend starts', (tester) async {
    reduceMotion(tester);
    now = DateTime(2026, 10, 23, 17, 59, 58);
    final controller = await createController();
    await tester.pumpWidget(
      WeekCounterApp(controller: controller, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Yay, time to rest'), findsNothing);

    now = DateTime(2026, 10, 23, 18, 0, 1);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Yay, time to rest'), findsOneWidget);
    // The first weekend earns the first award.
    expect(controller.prefs.weeks, 1);
    expect(find.text('New award: First Friday'), findsOneWidget);

    await tester.tap(find.text('Yay, time to rest'));
    await tester.pumpAndSettle();
    expect(find.text('Yay, time to rest'), findsNothing);
    expect(find.text('weekend left'), findsOneWidget);

    now = DateTime(2026, 10, 23, 18, 0, 5);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Yay, time to rest'), findsNothing);
  });

  testWidgets('saving a vacation day keeps it in the vacation', (tester) async {
    reduceMotion(tester);
    final controller = await createController();
    await controller.planVacation(
      const CalendarDate(2026, 10, 26),
      14,
      'Отпуск',
    );
    await tester.pumpWidget(
      WeekCounterApp(controller: controller, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();
    await openTab(tester, 'calendar');

    // October 28 is the first "28" on the calendar.
    final day = find.text('28').first;
    await tester.ensureVisible(day);
    await tester.pumpAndSettle();
    await tester.tap(day);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(controller.vacation, (
      first: const CalendarDate(2026, 10, 26),
      last: const CalendarDate(2026, 11, 8),
    ));
  });

  testWidgets(
    'the confetti hint names the motion setting of the platform',
    (tester) async {
      reduceMotion(tester);
      final controller = await createController();
      await tester.pumpWidget(
        WeekCounterApp(controller: controller, locale: const Locale('en')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Schedule'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Confetti'), 200);

      final android = defaultTargetPlatform == TargetPlatform.android;
      expect(
        find.textContaining('Reduce Motion'),
        android ? findsNothing : findsOneWidget,
      );
      expect(
        find.text(
          'With animations off in Settings, you get a still card instead',
        ),
        android ? findsOneWidget : findsNothing,
      );
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );
}
