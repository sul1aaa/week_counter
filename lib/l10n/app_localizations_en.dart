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
  String get navCountdown => 'Countdown';

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
  String untilWhen(String when) {
    return 'until $when';
  }

  @override
  String dayNofM(int n, int m) {
    return 'Day $n of $m';
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
  String get boxDays => 'days';

  @override
  String get boxHours => 'hours';

  @override
  String get boxMinutes => 'min';

  @override
  String get boxSeconds => 'sec';

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
  String get nextWeekend => 'Next weekend';

  @override
  String get nextHoliday => 'Next holiday';

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
  String get pickCountryBanner =>
      'Choose your country to include public holidays.';

  @override
  String get chooseCountry => 'Choose country';

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
  String get holidaysThisMonth => 'Holidays this month';

  @override
  String get noHolidaysThisMonth => 'No public holidays this month';

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
  String get widgetSetUp => 'Open the app to set up';
}
