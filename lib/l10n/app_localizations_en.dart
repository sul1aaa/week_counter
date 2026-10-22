// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Week Counter';

  @override
  String get navCountdown => 'Week';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navSettings => 'Settings';

  @override
  String get untilWeekend => 'Weekend in';

  @override
  String get untilLongWeekend => 'Long weekend in';

  @override
  String get untilHoliday => 'Holiday in';

  @override
  String get untilDaysOff => 'Days off in';

  @override
  String get youreOff => 'You\'re off!';

  @override
  String get backToWorkIn => 'Back to work in';

  @override
  String backToWorkAt(String when) {
    return 'Back to work $when';
  }

  @override
  String get noWorkAhead => 'No workdays ahead';

  @override
  String inShiftUntil(String time) {
    return 'In shift until $time';
  }

  @override
  String daysOffCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days off',
      one: '1 day off',
    );
    return '$_temp0';
  }

  @override
  String inDuration(String duration) {
    return 'in $duration';
  }

  @override
  String get dayShort => 'd';

  @override
  String get hourShort => 'h';

  @override
  String get minuteShort => 'm';

  @override
  String get kindWeekend => 'Weekend';

  @override
  String get kindLongWeekend => 'Long weekend';

  @override
  String get kindHoliday => 'Holiday';

  @override
  String get kindDaysOff => 'Days off';

  @override
  String get noneComing => 'None in the next year';

  @override
  String get upcomingDaysOff => 'Upcoming days off';

  @override
  String get noWorkdaysTitle => 'No workdays set';

  @override
  String get noWorkdaysBody =>
      'Choose your workdays in Settings to start the countdown.';

  @override
  String get noDaysOffTitle => 'No days off ahead';

  @override
  String get noDaysOffBody =>
      'Every day in the next year is a workday. Mark days off in the calendar.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get openCalendar => 'Open calendar';

  @override
  String holidaysNotLoaded(String years) {
    return 'Couldn\'t load public holidays for $years. Weekends are still counted.';
  }

  @override
  String get retry => 'Retry';

  @override
  String get legendWeekend => 'Weekend';

  @override
  String get legendHoliday => 'Holiday';

  @override
  String get legendDayOff => 'Your day off';

  @override
  String get legendWorkday => 'Extra workday';

  @override
  String get calendarHint =>
      'Tap a day to change it. Long-press to select several days.';

  @override
  String get overrideAuto => 'Auto';

  @override
  String get overrideDayOff => 'Day off';

  @override
  String get overrideWorkday => 'Workday';

  @override
  String get statusWorkday => 'Workday';

  @override
  String get statusDayOff => 'Day off';

  @override
  String get statusExtraWorkday => 'Workday (moved)';

  @override
  String get holidayIgnored => 'Ignored: marked as a workday';

  @override
  String get noteHint => 'Note, e.g. vacation (optional)';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String daysSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days selected',
      one: '1 day selected',
    );
    return '$_temp0';
  }

  @override
  String get markDaysOff => 'Mark as days off';

  @override
  String get resetToAuto => 'Reset';

  @override
  String get sectionHolidays => 'Public holidays';

  @override
  String get country => 'Country';

  @override
  String get noCountry => 'Not selected';

  @override
  String get searchCountry => 'Search country';

  @override
  String get noCountryOption => 'No public holidays';

  @override
  String holidaysUpdated(String date) {
    return 'Updated $date';
  }

  @override
  String get holidaysNotLoadedYet => 'Not loaded yet';

  @override
  String get refresh => 'Refresh';

  @override
  String get loadFailed => 'Couldn\'t load. Check your internet connection.';

  @override
  String get sectionWorkTime => 'Working time';

  @override
  String get workdays => 'Workdays';

  @override
  String get shiftStarts => 'Shift starts';

  @override
  String get shiftEnds => 'Shift ends';

  @override
  String get endsNextDay => 'Ends the next day';

  @override
  String get perDayHours => 'Different hours per day';

  @override
  String get sectionWidget => 'Home screen widget';

  @override
  String get addWidget => 'Add widget to home screen';

  @override
  String get preciseWidget => 'Precise widget countdown';

  @override
  String get preciseWidgetHint =>
      'Allow alarms & reminders so the widget ticks every second. Otherwise it updates about every 30 minutes.';

  @override
  String get allow => 'Allow';

  @override
  String get widgetHowToAndroid =>
      'Long-press the home screen, open Widgets and find Week Counter.';

  @override
  String get widgetHowToIos =>
      'Long-press the home screen, tap Edit › Add Widget and search for Week Counter.';

  @override
  String get sectionAbout => 'About';

  @override
  String get dataSource => 'Public holidays from Nager.Date (date.nager.at)';

  @override
  String weekdayName(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'Monday',
      '2': 'Tuesday',
      '3': 'Wednesday',
      '4': 'Thursday',
      '5': 'Friday',
      '6': 'Saturday',
      '7': 'Sunday',
      'other': 'Friday',
    });
    return '$_temp0';
  }

  @override
  String monthIn(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      '1': 'in January',
      '2': 'in February',
      '3': 'in March',
      '4': 'in April',
      '5': 'in May',
      '6': 'in June',
      '7': 'in July',
      '8': 'in August',
      '9': 'in September',
      '10': 'in October',
      '11': 'in November',
      '12': 'in December',
      'other': 'this month',
    });
    return '$_temp0';
  }

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    return '$count min';
  }

  @override
  String durationSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds',
      one: '1 second',
    );
    return '$_temp0';
  }

  @override
  String get timerDay => 'd';

  @override
  String get timerHour => 'h';

  @override
  String get timerMinute => 'm';

  @override
  String get whenToday => 'today';

  @override
  String get whenTomorrow => 'tomorrow';

  @override
  String whenAt(String day, String time) {
    return '$day, $time';
  }

  @override
  String get eyebrowUntil => 'until';

  @override
  String get eyebrowFreedom => 'freedom';

  @override
  String get eyebrowLastHourPrefix => 'freedom in';

  @override
  String get eyebrowLastHourStrike => 'forever';

  @override
  String get eyebrowLastHourSuffix => 'under an hour';

  @override
  String get eyebrowOffStrike => 'until work';

  @override
  String get eyebrowWeekendLeft => 'weekend left';

  @override
  String get eyebrowLongWeekendLeft => 'long weekend left';

  @override
  String get eyebrowHolidayStrike => 'workday';

  @override
  String get eyebrowHolidayLeft => 'holiday';

  @override
  String get eyebrowDaysOffStrike => 'work';

  @override
  String get eyebrowDaysOffLeft => 'still off for';

  @override
  String weekDone(int percent) {
    return '$percent% of the week done';
  }

  @override
  String get backToWorkLower => 'back to work';

  @override
  String get orbTip => 'tap the orb for a new line';

  @override
  String orbLabel(int percent) {
    return '$percent% done. Tap for a new line';
  }

  @override
  String get jokesLabel => 'Lines of the week';

  @override
  String get jokesMore => 'Other lines';

  @override
  String get hintCountryTitle => 'Count public holidays';

  @override
  String get hintCountryBody =>
      'Choose your country so holidays shorten the week';

  @override
  String get hintHolidaysFailedTitle => 'Holidays not loaded';

  @override
  String weekendLonger(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The weekend is $count days longer',
      one: 'The weekend is 1 day longer',
    );
    return '$_temp0';
  }

  @override
  String get aheadLongWeekend => 'Long weekend ahead';

  @override
  String get aheadHoliday => 'Holiday ahead';

  @override
  String get aheadDaysOff => 'Time off ahead';

  @override
  String get widgetTipTitle => 'Countdown on your home screen';

  @override
  String get widgetTipBody => 'Add the widget in half a minute';

  @override
  String get widgetsTitle => 'Widgets';

  @override
  String get widgetStepIos1 =>
      'Touch and hold an empty spot on the home screen';

  @override
  String get widgetStepIos2 => 'Tap Edit, then Add Widget';

  @override
  String get widgetStepIos3 => 'Find Week Counter and pick a size';

  @override
  String get widgetStepAndroid1 =>
      'Touch and hold an empty spot on the home screen';

  @override
  String get widgetStepAndroid2 => 'Open Widgets';

  @override
  String get widgetStepAndroid3 =>
      'Find Week Counter and drag it onto the screen';

  @override
  String get widgetUpdatesNote =>
      'The numbers update on their own, even when the app is closed.';

  @override
  String get gotIt => 'Got it';

  @override
  String get done => 'Done';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get today => 'Today';

  @override
  String daysOffIn(String monthIn) {
    return 'Days off $monthIn';
  }

  @override
  String holidayOn(String date) {
    return 'holiday $date';
  }

  @override
  String get noHolidaysShort => 'no holidays';

  @override
  String get upcomingHolidays => 'Upcoming holidays';

  @override
  String get noUpcomingHolidays => 'Choose a country to see public holidays';

  @override
  String get settingsSubtitle =>
      'Changes save right away. The countdown and widget update on their own.';

  @override
  String get workdaysHint => 'Tap a day to make it a workday or a day off';

  @override
  String get shiftStartsAt => 'Starts';

  @override
  String get shiftEndsAt => 'Ends';

  @override
  String get celebrateWeekend => 'Weekend!';

  @override
  String get celebrateLongWeekend => 'Long weekend!';

  @override
  String get celebrateHoliday => 'Holiday!';

  @override
  String get celebrateDaysOff => 'Time off!';

  @override
  String get celebrateEyebrow => 'the week is done';

  @override
  String get celebrateLateEyebrow => 'late, but from the heart';

  @override
  String get celebrateWas => 'work';

  @override
  String celebrateBody(String duration) {
    return 'Work\'s over. The next $duration are yours.';
  }

  @override
  String get celebrateBodyOpen => 'Work\'s over. Enjoy it.';

  @override
  String celebrateLateBody(String when) {
    return 'The week ended $when. Celebrating anyway.';
  }

  @override
  String get celebrateCta => 'Yay, time to rest';

  @override
  String get widgetSetUp => 'Open the app to set up';
}
