import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:week_counter/app.dart';
import 'package:week_counter/core/calendar_date.dart';
import 'package:week_counter/domain/countdown_engine.dart';
import 'package:week_counter/models/work_schedule.dart';
import 'package:week_counter/services/holiday_api.dart';
import 'package:week_counter/services/holiday_repository.dart';
import 'package:week_counter/services/local_store.dart';
import 'package:week_counter/services/prefs_repository.dart';
import 'package:week_counter/services/settings_repository.dart';
import 'package:week_counter/services/widget_sync.dart';
import 'package:week_counter/state/app_controller.dart';
import 'package:week_counter/ui/kit/controls.dart';
import 'package:week_counter/ui/kit/glass.dart';
import 'package:week_counter/ui/kit/group.dart';
import 'package:week_counter/ui/screens/vacation_screen.dart';
import 'package:week_counter/ui/widgets/day_orb.dart';
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
    await tester.scrollUntilVisible(
      find.byType(JokeCarousel),
      200,
      // The page, not the orb pager.
      scrollable: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
    );
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
    await tester.scrollUntilVisible(
      find.text('Vacation'),
      200,
      scrollable: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
    );
    expect(find.text('Vacation'), findsOneWidget);
  });

  testWidgets('swiping the orb shows the day orb', (tester) async {
    reduceMotion(tester);
    // A phone screen, so the orb sits below the bar.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    now = DateTime(2026, 10, 21, 13, 30);
    final controller = await createController();
    await tester.pumpWidget(
      WeekCounterApp(controller: controller, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();
    expect(find.text('until the end of the shift at 18:00'), findsNothing);

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.text('until the end of the shift at 18:00'), findsOneWidget);
    // A screen reader reads the whole page in one go.
    expect(
      tester.getSemantics(find.byType(DayOrb)).label,
      "50% of today's shift done\n4 hours 30 min\n"
      'until the end of the shift at 18:00',
    );
    expect(find.text('tap the orb for a new line'), findsNothing);
    // The week's countdown above stays put.
    expect(find.textContaining('of the week done'), findsOneWidget);
  });

  testWidgets('switches the schedule to a rotation and back', (tester) async {
    reduceMotion(tester);
    final controller = await createController();
    await tester.pumpWidget(
      WeekCounterApp(controller: controller, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Schedule'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rotation'));
    await tester.pumpAndSettle();
    expect(
      controller.settings.schedule.rotation!.preset,
      RotationPreset.twoTwo,
    );
    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('Workday 1'), findsOneWidget);
    expect(find.text('Week starts'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('rotation.pattern')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Day/night'));
    await tester.pumpAndSettle();
    expect(
      controller.settings.schedule.rotation!.preset,
      RotationPreset.dayNight,
    );
    expect(find.text('Night shift'), findsOneWidget);

    // Today is the first day off, after last night's shift.
    await tester.tap(find.byKey(const ValueKey('rotation.today')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('choice.2')));
    await tester.pumpAndSettle();
    expect(find.text('Day off 1'), findsOneWidget);
    expect(controller.snapshot.state, isA<OffNow>());
    expect(controller.celebrationDue, isNull);

    await tester.tap(find.text('Weekdays'));
    await tester.pumpAndSettle();
    expect(controller.settings.schedule.rotation, isNull);
    expect(find.text('Week starts'), findsOneWidget);
    expect(controller.snapshot.state, isA<CountingDown>());
  });

  testWidgets('the money ticker shows on the day orb once turned on', (
    tester,
  ) async {
    reduceMotion(tester);
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    now = DateTime(2026, 10, 21, 13, 30);
    final controller = await createController();
    await tester.pumpWidget(
      WeekCounterApp(controller: controller, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('until the end of the shift at 18:00'), findsOneWidget);
    expect(find.textContaining('earned today'), findsNothing);

    await tester.tap(find.byTooltip('Schedule'));
    await tester.pumpAndSettle();
    final toggle = find.descendant(
      of: find.widgetWithText(GroupRow, 'Money ticker'),
      matching: find.byType(AppToggle),
    );
    await tester.scrollUntilVisible(toggle, 200);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    // The first time it asks for the pay, in the currency of the country.
    expect(find.text('Per month'), findsOneWidget);
    await tester.tap(find.text('Per hour'));
    await tester.enterText(find.byKey(const ValueKey('pay.amount')), '1 000');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('₽1,000 an hour'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    final money = find.text('₽4,500 earned today');
    expect(money, findsOneWidget);
    // The pager grows to fit the line instead of cutting it off.
    expect(
      tester.getRect(money).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(PageView)).bottom),
    );
  });

  testWidgets('the vacation orb holds still when motion is reduced', (
    tester,
  ) async {
    reduceMotion(tester);
    final controller = await createController();
    await tester.pumpWidget(
      WeekCounterApp(controller: controller, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Schedule'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Vacation'),
      200,
      scrollable: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vacation'));
    // Settles only if nothing on the screen loops.
    await tester.pumpAndSettle();

    expect(find.byType(VacationScreen), findsOneWidget);
  });

  testWidgets('the back button returns to Week from another tab', (
    tester,
  ) async {
    reduceMotion(tester);
    final controller = await createController();
    await tester.pumpWidget(
      WeekCounterApp(controller: controller, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();
    await openTab(tester, 'awards');
    expect(find.text('First Friday'), findsOneWidget);

    // What Android sends when the back button is pressed.
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.navigation.name,
      SystemChannels.navigation.codec.encodeMethodCall(
        const MethodCall('popRoute'),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();

    expect(find.text('First Friday'), findsNothing);
    expect(find.text('tap the orb for a new line'), findsOneWidget);
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

  testWidgets(
    'the range bar stays above the tab bar',
    (tester) async {
      reduceMotion(tester);
      // A 48dp navigation bar, or the iPhone's home indicator.
      tester.view.padding = FakeViewPadding(
        bottom:
            (defaultTargetPlatform == TargetPlatform.android ? 48 : 34) *
            tester.view.devicePixelRatio,
      );
      addTearDown(tester.view.reset);
      final controller = await createController();
      await tester.pumpWidget(
        WeekCounterApp(controller: controller, locale: const Locale('en')),
      );
      await tester.pumpAndSettle();
      await openTab(tester, 'calendar');

      final day = find.text('28').first;
      await tester.ensureVisible(day);
      await tester.pumpAndSettle();
      await tester.longPress(day);
      await tester.pumpAndSettle();

      Rect glassAround(Finder finder) => tester.getRect(
        find.ancestor(of: finder, matching: find.byType(Glass)).first,
      );
      final rangeBar = glassAround(find.text('Mark as days off'));
      final tabBar = glassAround(find.byKey(const ValueKey('tab.calendar')));
      expect(rangeBar.bottom, lessThan(tabBar.top));
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets('adds, edits and deletes a countdown on the Week screen', (
    tester,
  ) async {
    reduceMotion(tester);
    final controller = await createController();
    await tester.pumpWidget(
      WeekCounterApp(controller: controller, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();
    final page = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    final add = find.byKey(const ValueKey('countdown.add'));
    await tester.scrollUntilVisible(add, 200, scrollable: page);
    expect(find.text('Count down to your own dates'), findsOneWidget);

    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text('New countdown'), findsOneWidget);
    // Nothing to save without a name.
    await tester.tap(find.byKey(const ValueKey('countdown.save')));
    await tester.pumpAndSettle();
    expect(find.text('New countdown'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('countdown.title')),
      'Trip',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('countdown.save')));
    await tester.pumpAndSettle();

    // Tomorrow by default: Thursday midnight, 12 hours from Wednesday noon.
    expect(
      controller.upcomingCountdowns.single.date,
      const CalendarDate(2026, 10, 22),
    );
    await tester.scrollUntilVisible(find.text('Trip'), 200, scrollable: page);
    expect(find.text('Thu, Oct 22'), findsOneWidget);
    expect(find.text('12h 00m'), findsOneWidget);
    expect(find.text('Count down to your own dates'), findsNothing);

    // It ticks with the clock.
    now = now.add(const Duration(hours: 1, minutes: 30));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('10h 30m'), findsOneWidget);

    await tester.tap(find.text('Trip'));
    await tester.pumpAndSettle();
    expect(find.text('Edit countdown'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('countdown.delete')));
    await tester.pumpAndSettle();
    expect(find.text('Trip'), findsNothing);
    expect(controller.upcomingCountdowns, isEmpty);
    expect(find.text('Count down to your own dates'), findsOneWidget);
  });
}
