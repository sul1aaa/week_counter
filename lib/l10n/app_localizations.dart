import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Week Counter'**
  String get appTitle;

  /// No description provided for @navCountdown.
  ///
  /// In en, this message translates to:
  /// **'Countdown'**
  String get navCountdown;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @untilWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend in'**
  String get untilWeekend;

  /// No description provided for @untilLongWeekend.
  ///
  /// In en, this message translates to:
  /// **'Long weekend in'**
  String get untilLongWeekend;

  /// No description provided for @untilHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holiday in'**
  String get untilHoliday;

  /// No description provided for @untilDaysOff.
  ///
  /// In en, this message translates to:
  /// **'Days off in'**
  String get untilDaysOff;

  /// No description provided for @youreOff.
  ///
  /// In en, this message translates to:
  /// **'You\'re off!'**
  String get youreOff;

  /// No description provided for @backToWorkIn.
  ///
  /// In en, this message translates to:
  /// **'Back to work in'**
  String get backToWorkIn;

  /// No description provided for @backToWorkAt.
  ///
  /// In en, this message translates to:
  /// **'Back to work {when}'**
  String backToWorkAt(String when);

  /// No description provided for @noWorkAhead.
  ///
  /// In en, this message translates to:
  /// **'No workdays ahead'**
  String get noWorkAhead;

  /// No description provided for @inShiftUntil.
  ///
  /// In en, this message translates to:
  /// **'In shift until {time}'**
  String inShiftUntil(String time);

  /// No description provided for @untilWhen.
  ///
  /// In en, this message translates to:
  /// **'until {when}'**
  String untilWhen(String when);

  /// No description provided for @dayNofM.
  ///
  /// In en, this message translates to:
  /// **'Day {n} of {m}'**
  String dayNofM(int n, int m);

  /// No description provided for @daysOffCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day off} other{{count} days off}}'**
  String daysOffCount(int count);

  /// No description provided for @inDuration.
  ///
  /// In en, this message translates to:
  /// **'in {duration}'**
  String inDuration(String duration);

  /// No description provided for @boxDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get boxDays;

  /// No description provided for @boxHours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get boxHours;

  /// No description provided for @boxMinutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get boxMinutes;

  /// No description provided for @boxSeconds.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get boxSeconds;

  /// No description provided for @dayShort.
  ///
  /// In en, this message translates to:
  /// **'d'**
  String get dayShort;

  /// No description provided for @hourShort.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hourShort;

  /// No description provided for @minuteShort.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get minuteShort;

  /// No description provided for @kindWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get kindWeekend;

  /// No description provided for @kindLongWeekend.
  ///
  /// In en, this message translates to:
  /// **'Long weekend'**
  String get kindLongWeekend;

  /// No description provided for @kindHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get kindHoliday;

  /// No description provided for @kindDaysOff.
  ///
  /// In en, this message translates to:
  /// **'Days off'**
  String get kindDaysOff;

  /// No description provided for @nextWeekend.
  ///
  /// In en, this message translates to:
  /// **'Next weekend'**
  String get nextWeekend;

  /// No description provided for @nextHoliday.
  ///
  /// In en, this message translates to:
  /// **'Next holiday'**
  String get nextHoliday;

  /// No description provided for @noneComing.
  ///
  /// In en, this message translates to:
  /// **'None in the next year'**
  String get noneComing;

  /// No description provided for @upcomingDaysOff.
  ///
  /// In en, this message translates to:
  /// **'Upcoming days off'**
  String get upcomingDaysOff;

  /// No description provided for @noWorkdaysTitle.
  ///
  /// In en, this message translates to:
  /// **'No workdays set'**
  String get noWorkdaysTitle;

  /// No description provided for @noWorkdaysBody.
  ///
  /// In en, this message translates to:
  /// **'Choose your workdays in Settings to start the countdown.'**
  String get noWorkdaysBody;

  /// No description provided for @noDaysOffTitle.
  ///
  /// In en, this message translates to:
  /// **'No days off ahead'**
  String get noDaysOffTitle;

  /// No description provided for @noDaysOffBody.
  ///
  /// In en, this message translates to:
  /// **'Every day in the next year is a workday. Mark days off in the calendar.'**
  String get noDaysOffBody;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @openCalendar.
  ///
  /// In en, this message translates to:
  /// **'Open calendar'**
  String get openCalendar;

  /// No description provided for @pickCountryBanner.
  ///
  /// In en, this message translates to:
  /// **'Choose your country to include public holidays.'**
  String get pickCountryBanner;

  /// No description provided for @chooseCountry.
  ///
  /// In en, this message translates to:
  /// **'Choose country'**
  String get chooseCountry;

  /// No description provided for @holidaysNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load public holidays for {years}. Weekends are still counted.'**
  String holidaysNotLoaded(String years);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @legendWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get legendWeekend;

  /// No description provided for @legendHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get legendHoliday;

  /// No description provided for @legendDayOff.
  ///
  /// In en, this message translates to:
  /// **'Your day off'**
  String get legendDayOff;

  /// No description provided for @legendWorkday.
  ///
  /// In en, this message translates to:
  /// **'Extra workday'**
  String get legendWorkday;

  /// No description provided for @holidaysThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Holidays this month'**
  String get holidaysThisMonth;

  /// No description provided for @noHolidaysThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No public holidays this month'**
  String get noHolidaysThisMonth;

  /// No description provided for @calendarHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a day to change it. Long-press to select several days.'**
  String get calendarHint;

  /// No description provided for @overrideAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get overrideAuto;

  /// No description provided for @overrideDayOff.
  ///
  /// In en, this message translates to:
  /// **'Day off'**
  String get overrideDayOff;

  /// No description provided for @overrideWorkday.
  ///
  /// In en, this message translates to:
  /// **'Workday'**
  String get overrideWorkday;

  /// No description provided for @statusWorkday.
  ///
  /// In en, this message translates to:
  /// **'Workday'**
  String get statusWorkday;

  /// No description provided for @statusDayOff.
  ///
  /// In en, this message translates to:
  /// **'Day off'**
  String get statusDayOff;

  /// No description provided for @statusExtraWorkday.
  ///
  /// In en, this message translates to:
  /// **'Workday (moved)'**
  String get statusExtraWorkday;

  /// No description provided for @holidayIgnored.
  ///
  /// In en, this message translates to:
  /// **'Ignored: marked as a workday'**
  String get holidayIgnored;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Note, e.g. vacation (optional)'**
  String get noteHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @daysSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day selected} other{{count} days selected}}'**
  String daysSelected(int count);

  /// No description provided for @markDaysOff.
  ///
  /// In en, this message translates to:
  /// **'Mark as days off'**
  String get markDaysOff;

  /// No description provided for @resetToAuto.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetToAuto;

  /// No description provided for @sectionHolidays.
  ///
  /// In en, this message translates to:
  /// **'Public holidays'**
  String get sectionHolidays;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @noCountry.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get noCountry;

  /// No description provided for @searchCountry.
  ///
  /// In en, this message translates to:
  /// **'Search country'**
  String get searchCountry;

  /// No description provided for @noCountryOption.
  ///
  /// In en, this message translates to:
  /// **'No public holidays'**
  String get noCountryOption;

  /// No description provided for @holidaysUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String holidaysUpdated(String date);

  /// No description provided for @holidaysNotLoadedYet.
  ///
  /// In en, this message translates to:
  /// **'Not loaded yet'**
  String get holidaysNotLoadedYet;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load. Check your internet connection.'**
  String get loadFailed;

  /// No description provided for @sectionWorkTime.
  ///
  /// In en, this message translates to:
  /// **'Working time'**
  String get sectionWorkTime;

  /// No description provided for @workdays.
  ///
  /// In en, this message translates to:
  /// **'Workdays'**
  String get workdays;

  /// No description provided for @shiftStarts.
  ///
  /// In en, this message translates to:
  /// **'Shift starts'**
  String get shiftStarts;

  /// No description provided for @shiftEnds.
  ///
  /// In en, this message translates to:
  /// **'Shift ends'**
  String get shiftEnds;

  /// No description provided for @endsNextDay.
  ///
  /// In en, this message translates to:
  /// **'Ends the next day'**
  String get endsNextDay;

  /// No description provided for @perDayHours.
  ///
  /// In en, this message translates to:
  /// **'Different hours per day'**
  String get perDayHours;

  /// No description provided for @sectionWidget.
  ///
  /// In en, this message translates to:
  /// **'Home screen widget'**
  String get sectionWidget;

  /// No description provided for @addWidget.
  ///
  /// In en, this message translates to:
  /// **'Add widget to home screen'**
  String get addWidget;

  /// No description provided for @preciseWidget.
  ///
  /// In en, this message translates to:
  /// **'Precise widget countdown'**
  String get preciseWidget;

  /// No description provided for @preciseWidgetHint.
  ///
  /// In en, this message translates to:
  /// **'Allow alarms & reminders so the widget ticks every second. Otherwise it updates about every 30 minutes.'**
  String get preciseWidgetHint;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @widgetHowToAndroid.
  ///
  /// In en, this message translates to:
  /// **'Long-press the home screen, open Widgets and find Week Counter.'**
  String get widgetHowToAndroid;

  /// No description provided for @widgetHowToIos.
  ///
  /// In en, this message translates to:
  /// **'Long-press the home screen, tap Edit › Add Widget and search for Week Counter.'**
  String get widgetHowToIos;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @dataSource.
  ///
  /// In en, this message translates to:
  /// **'Public holidays from Nager.Date (date.nager.at)'**
  String get dataSource;

  /// No description provided for @widgetSetUp.
  ///
  /// In en, this message translates to:
  /// **'Open the app to set up'**
  String get widgetSetUp;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
