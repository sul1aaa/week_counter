// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Счётчик выходных';

  @override
  String get navCountdown => 'Отсчёт';

  @override
  String get navCalendar => 'Календарь';

  @override
  String get navSettings => 'Настройки';

  @override
  String get untilWeekend => 'До выходных';

  @override
  String get untilLongWeekend => 'До длинных выходных';

  @override
  String get untilHoliday => 'До праздника';

  @override
  String get untilDaysOff => 'До отдыха';

  @override
  String get youreOff => 'Вы отдыхаете!';

  @override
  String get backToWorkIn => 'До работы';

  @override
  String backToWorkAt(String when) {
    return 'На работу: $when';
  }

  @override
  String get noWorkAhead => 'Рабочих дней не предвидится';

  @override
  String inShiftUntil(String time) {
    return 'Смена до $time';
  }

  @override
  String untilWhen(String when) {
    return 'до $when';
  }

  @override
  String dayNofM(int n, int m) {
    return 'День $n из $m';
  }

  @override
  String daysOffCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня отдыха',
      many: '$count дней отдыха',
      few: '$count дня отдыха',
      one: '$count день отдыха',
    );
    return '$_temp0';
  }

  @override
  String inDuration(String duration) {
    return 'через $duration';
  }

  @override
  String get boxDays => 'дн';

  @override
  String get boxHours => 'ч';

  @override
  String get boxMinutes => 'мин';

  @override
  String get boxSeconds => 'сек';

  @override
  String get dayShort => 'д';

  @override
  String get hourShort => 'ч';

  @override
  String get minuteShort => 'мин';

  @override
  String get kindWeekend => 'Выходные';

  @override
  String get kindLongWeekend => 'Длинные выходные';

  @override
  String get kindHoliday => 'Праздник';

  @override
  String get kindDaysOff => 'Отдых';

  @override
  String get nextWeekend => 'Ближайшие выходные';

  @override
  String get nextHoliday => 'Ближайший праздник';

  @override
  String get noneComing => 'Не будет в ближайший год';

  @override
  String get upcomingDaysOff => 'Предстоящие выходные';

  @override
  String get noWorkdaysTitle => 'Рабочие дни не выбраны';

  @override
  String get noWorkdaysBody =>
      'Выберите рабочие дни в настройках, чтобы начать отсчёт.';

  @override
  String get noDaysOffTitle => 'Выходных не предвидится';

  @override
  String get noDaysOffBody =>
      'Весь следующий год — рабочие дни. Отметьте выходные в календаре.';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get openCalendar => 'Открыть календарь';

  @override
  String get pickCountryBanner =>
      'Выберите страну, чтобы учитывать государственные праздники.';

  @override
  String get chooseCountry => 'Выбрать страну';

  @override
  String holidaysNotLoaded(String years) {
    return 'Не удалось загрузить праздники за $years. Выходные всё равно учитываются.';
  }

  @override
  String get retry => 'Повторить';

  @override
  String get legendWeekend => 'Выходной';

  @override
  String get legendHoliday => 'Праздник';

  @override
  String get legendDayOff => 'Ваш выходной';

  @override
  String get legendWorkday => 'Рабочий (перенос)';

  @override
  String get holidaysThisMonth => 'Праздники в этом месяце';

  @override
  String get noHolidaysThisMonth => 'В этом месяце нет праздников';

  @override
  String get calendarHint =>
      'Нажмите на день, чтобы изменить его. Удерживайте, чтобы выбрать несколько дней.';

  @override
  String get overrideAuto => 'Авто';

  @override
  String get overrideDayOff => 'Выходной';

  @override
  String get overrideWorkday => 'Рабочий';

  @override
  String get statusWorkday => 'Рабочий день';

  @override
  String get statusDayOff => 'Выходной день';

  @override
  String get statusExtraWorkday => 'Рабочий день (перенос)';

  @override
  String get holidayIgnored => 'Не учитывается: отмечен как рабочий';

  @override
  String get noteHint => 'Заметка, например «отпуск» (необязательно)';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String daysSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Выбрано $count дня',
      many: 'Выбрано $count дней',
      few: 'Выбрано $count дня',
      one: 'Выбран $count день',
    );
    return '$_temp0';
  }

  @override
  String get markDaysOff => 'Сделать выходными';

  @override
  String get resetToAuto => 'Сбросить';

  @override
  String get sectionHolidays => 'Государственные праздники';

  @override
  String get country => 'Страна';

  @override
  String get noCountry => 'Не выбрана';

  @override
  String get searchCountry => 'Поиск страны';

  @override
  String get noCountryOption => 'Без праздников';

  @override
  String holidaysUpdated(String date) {
    return 'Обновлено $date';
  }

  @override
  String get holidaysNotLoadedYet => 'Ещё не загружены';

  @override
  String get refresh => 'Обновить';

  @override
  String get loadFailed =>
      'Не удалось загрузить. Проверьте подключение к интернету.';

  @override
  String get sectionWorkTime => 'Рабочее время';

  @override
  String get workdays => 'Рабочие дни';

  @override
  String get shiftStarts => 'Начало смены';

  @override
  String get shiftEnds => 'Конец смены';

  @override
  String get endsNextDay => 'Заканчивается на следующий день';

  @override
  String get perDayHours => 'Разное время по дням';

  @override
  String get sectionWidget => 'Виджет на экране «Домой»';

  @override
  String get addWidget => 'Добавить виджет на экран';

  @override
  String get preciseWidget => 'Точный отсчёт в виджете';

  @override
  String get preciseWidgetHint =>
      'Разрешите «Будильники и напоминания», чтобы виджет обновлялся каждую секунду. Иначе он обновляется примерно раз в 30 минут.';

  @override
  String get allow => 'Разрешить';

  @override
  String get widgetHowToAndroid =>
      'Удерживайте палец на главном экране, откройте «Виджеты» и найдите «Счётчик выходных».';

  @override
  String get widgetHowToIos =>
      'Удерживайте палец на экране «Домой», нажмите «Править» › «Добавить виджет» и найдите «Счётчик выходных».';

  @override
  String get sectionAbout => 'О приложении';

  @override
  String get dataSource => 'Праздники: Nager.Date (date.nager.at)';

  @override
  String get widgetSetUp => 'Откройте приложение для настройки';
}
