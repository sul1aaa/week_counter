import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:week_counter/core/calendar_date.dart';
import 'package:week_counter/domain/countdown_engine.dart';
import 'package:week_counter/domain/day_classifier.dart';
import 'package:week_counter/domain/earnings.dart';
import 'package:week_counter/l10n/app_localizations.dart';
import 'package:week_counter/l10n/labels.dart';
import 'package:week_counter/models/app_settings.dart';
import 'package:week_counter/models/holiday.dart';
import 'package:week_counter/models/pay.dart';
import 'package:week_counter/models/work_schedule.dart';
import 'package:week_counter/services/holiday_api.dart';
import 'package:week_counter/services/holiday_repository.dart';
import 'package:week_counter/services/local_store.dart';
import 'package:week_counter/services/prefs_repository.dart';
import 'package:week_counter/services/settings_repository.dart';
import 'package:week_counter/services/widget_sync.dart';
import 'package:week_counter/state/app_controller.dart';

import '../services/fake_nager.dart';

DayClassifier classifier({
  WorkSchedule schedule = WorkSchedule.standard,
  List<CalendarDate> holidays = const [],
  Map<CalendarDate, DayOverride> overrides = const {},
}) => DayClassifier(
  schedule: schedule,
  holidays: {
    for (final date in holidays)
      date: [
        Holiday(
          date: date,
          name: 'Unity Day',
          localName: 'Unity Day',
          countryCode: 'RU',
        ),
      ],
  },
  overrides: overrides,
);

// November 2026 starts on a Sunday and has 21 days from Monday to Friday.
const november = CalendarDate(2026, 11, 18);
const unityDay = CalendarDate(2026, 11, 4); // Wednesday

void main() {
  setUpAll(initializeDateFormatting);

  group('work hours in a month', () {
    test('count every workday shift', () {
      expect(monthWorkHours(classifier(), november), 21 * 9);
    });

    test('leave out holidays and days off', () {
      expect(
        monthWorkHours(classifier(holidays: [unityDay]), november),
        20 * 9,
      );
      final vacation = {
        for (var day = 23; day <= 27; day++)
          CalendarDate(2026, 11, day): const DayOverride(
            OverrideKind.dayOff,
            vacation: true,
          ),
      };
      expect(monthWorkHours(classifier(overrides: vacation), november), 16 * 9);
    });

    test('count a working Saturday', () {
      final saturday = {
        const CalendarDate(2026, 11, 28): const DayOverride(
          OverrideKind.workday,
        ),
      };
      expect(monthWorkHours(classifier(overrides: saturday), november), 22 * 9);
    });

    test('give a night shift to the month it starts in', () {
      final nights = WorkSchedule.standard.copyWith(
        defaultShift: const Shift(ShiftTime(22, 0), ShiftTime(6, 0)),
      );
      // Monday 30 November ends on 1 December and still counts.
      expect(monthWorkHours(classifier(schedule: nights), november), 21 * 8);
    });

    test('follow a 2/2 rotation, holidays worked', () {
      final twoTwo = WorkSchedule.standard.copyWith(
        rotation: () => ShiftRotation(
          cycle: RotationPreset.twoTwo.cycle,
          start: const CalendarDate(2026, 11, 3),
        ),
      );
      // 14 shifts of 12 hours, from 3–4 to 27–28 November. Unity Day is
      // one of them and still counts.
      expect(
        monthWorkHours(
          classifier(schedule: twoTwo, holidays: [unityDay]),
          november,
        ),
        14 * 12,
      );
    });
  });

  group('hourly rate', () {
    test('is the amount for hourly pay', () {
      expect(
        hourlyRate(const Pay(period: PayPeriod.hour, amount: 20), 189),
        20,
      );
    });

    test('spreads a monthly salary over the month', () {
      const pay = Pay(amount: 189000);
      expect(hourlyRate(pay, 21 * 9), 1000);
      // A holiday leaves fewer hours, so each pays more.
      expect(hourlyRate(pay, 20 * 9), 1050);
      expect(hourlyRate(pay, 0), 0);
    });
  });

  group('earned in a shift', () {
    final shift = DayShift(
      start: DateTime(2026, 10, 21, 9),
      end: DateTime(2026, 10, 21, 18),
    );

    test('nothing before it starts', () {
      expect(earnedIn(shift, DateTime(2026, 10, 21, 8), 1000), 0);
    });

    test('grows during it', () {
      expect(earnedIn(shift, DateTime(2026, 10, 21, 13, 30), 1000), 4500);
      expect(
        earnedIn(shift, DateTime(2026, 10, 21, 13, 30, 1), 3600),
        closeTo(4.5 * 3600 + 1, 1e-6),
      );
    });

    test('all of it once it ends', () {
      expect(earnedIn(shift, DateTime(2026, 10, 21, 20), 1000), 9000);
    });

    test('across midnight', () {
      final night = DayShift(
        start: DateTime(2026, 10, 21, 22),
        end: DateTime(2026, 10, 22, 6),
      );
      expect(earnedIn(night, DateTime(2026, 10, 22, 2), 100), 400);
    });
  });

  test('shows cents only when whole units would tick slowly', () {
    Earned at(double perHour) =>
        Earned(amount: 0, perHour: perHour, currency: '');
    expect(at(20).cents, isTrue);
    expect(at(595).cents, isTrue);
    expect(at(2380).cents, isFalse);
  });

  test('formats money in the app language, rounded down', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final ru = lookupAppLocalizations(const Locale('ru'));
    expect(en.money(4230.99, '₸'), '₸4,230');
    expect(en.money(12.579, r'$', cents: true), r'$12.57');
    expect(ru.money(4230.99, '₸'), '4 230 ₸');
    expect(ru.money(12.5, '₽', cents: true), '12,50 ₽');
  });

  group('the controller', () {
    late DateTime now;
    late InMemoryLocalStore store;

    Future<AppController> create() async {
      final controller = AppController(
        settingsRepository: SettingsRepository(store),
        holidayRepository: HolidayRepository(
          store,
          NagerDateApi(client: FakeNager().client),
        ),
        prefsRepository: PrefsRepository(store),
        widgetSync: NoopWidgetSync(),
        clock: () => now,
        deviceLocales: () => const [Locale('ru', 'RU')],
      );
      await controller.init();
      return controller;
    }

    setUp(() {
      now = DateTime(2026, 11, 18, 13, 30); // Wednesday
      store = InMemoryLocalStore();
    });

    test('counts nothing until the ticker is on', () async {
      final c = await create();
      expect(c.settings.pay, isNull);
      expect(c.earnedToday(now), isNull);
    });

    test('counts today with hourly pay', () async {
      final c = await create();
      await c.setPay(
        const Pay(
          on: true,
          period: PayPeriod.hour,
          amount: 1000,
          currency: '₽',
        ),
      );
      final earned = c.earnedToday(now)!;
      expect(earned.amount, 4500);
      expect(earned.currency, '₽');
    });

    test('spreads a monthly salary over the month without holidays', () async {
      final c = await create();
      await c.setPay(const Pay(on: true, amount: 189000, currency: '₽'));
      // 21 workdays of 9 hours before the holidays load.
      expect(c.earnedToday(now)!.perHour, 1000);
      await c.refreshHolidays();
      // Unity Day leaves 20.
      expect(c.earnedToday(now)!.perHour, 1050);
    });

    test('shows nothing on a day off', () async {
      now = DateTime(2026, 11, 21, 13, 30); // Saturday
      final c = await create();
      await c.setPay(
        const Pay(
          on: true,
          period: PayPeriod.hour,
          amount: 1000,
          currency: '₽',
        ),
      );
      expect(c.earnedToday(now), isNull);
    });

    test('keeps the pay when switched off, and after a restart', () async {
      final c = await create();
      const pay = Pay(
        on: true,
        period: PayPeriod.hour,
        amount: 1000,
        currency: '₽',
      );
      await c.setPay(pay);
      await c.setPay(pay.copyWith(on: false));
      expect(c.earnedToday(now), isNull);

      final restarted = await create();
      expect(restarted.settings.pay, pay.copyWith(on: false));
    });
  });
}
