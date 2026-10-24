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
  String get navCountdown => 'Неделя';

  @override
  String get navCalendar => 'Календарь';

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
  String get noneComing => 'Не будет в ближайший год';

  @override
  String get noWorkdaysTitle => 'Рабочие дни не выбраны';

  @override
  String get noWorkdaysBody =>
      'Выберите рабочие дни в «Графике», чтобы начать отсчёт.';

  @override
  String get noDaysOffTitle => 'Выходных не предвидится';

  @override
  String get noDaysOffBody =>
      'Весь следующий год — рабочие дни. Отметьте выходные в календаре.';

  @override
  String get openSettings => 'Открыть график';

  @override
  String get openCalendar => 'Открыть календарь';

  @override
  String holidaysNotLoaded(String years) {
    return 'Не удалось загрузить праздники за $years. Выходные всё равно учитываются.';
  }

  @override
  String get retry => 'Повторить';

  @override
  String get legendWeekend => 'выходные';

  @override
  String get legendHoliday => 'праздник';

  @override
  String get legendDayOff => 'отпуск';

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
  String get workdays => 'Рабочие дни';

  @override
  String get endsNextDay => 'Заканчивается на следующий день';

  @override
  String get perDayHours => 'Разное время по дням';

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
  String get sectionAbout => 'О приложении';

  @override
  String get dataSource => 'Праздники: Nager.Date (date.nager.at)';

  @override
  String weekdayName(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'понедельника',
      '2': 'вторника',
      '3': 'среды',
      '4': 'четверга',
      '5': 'пятницы',
      '6': 'субботы',
      '7': 'воскресенья',
      'other': 'пятницы',
    });
    return '$_temp0';
  }

  @override
  String monthIn(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      '1': 'в январе',
      '2': 'в феврале',
      '3': 'в марте',
      '4': 'в апреле',
      '5': 'в мае',
      '6': 'в июне',
      '7': 'в июле',
      '8': 'в августе',
      '9': 'в сентябре',
      '10': 'в октябре',
      '11': 'в ноябре',
      '12': 'в декабре',
      'other': 'в этом месяце',
    });
    return '$_temp0';
  }

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count часа',
      many: '$count часов',
      few: '$count часа',
      one: '$count час',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    return '$count мин';
  }

  @override
  String durationSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count секунды',
      many: '$count секунд',
      few: '$count секунды',
      one: '$count секунда',
    );
    return '$_temp0';
  }

  @override
  String get timerDay => 'д';

  @override
  String get timerHour => 'ч';

  @override
  String get timerMinute => 'м';

  @override
  String get whenToday => 'сегодня';

  @override
  String get whenTomorrow => 'завтра';

  @override
  String whenAt(String day, String time) {
    return '$day, $time';
  }

  @override
  String get eyebrowUntil => 'до';

  @override
  String get eyebrowFreedom => 'свободы';

  @override
  String get eyebrowLastHourPrefix => 'до свободы';

  @override
  String get eyebrowLastHourStrike => 'вечность';

  @override
  String get eyebrowLastHourSuffix => 'меньше часа';

  @override
  String get eyebrowOffStrike => 'до работы';

  @override
  String get eyebrowWeekendLeft => 'выходные ещё';

  @override
  String get eyebrowLongWeekendLeft => 'длинные выходные ещё';

  @override
  String get eyebrowHolidayStrike => 'рабочий день';

  @override
  String get eyebrowHolidayLeft => 'праздник';

  @override
  String weekDone(int percent) {
    return '$percent% недели позади';
  }

  @override
  String get backToWorkLower => 'снова на работу';

  @override
  String get orbTip => 'нажмите на шар, чтобы сменить фразу';

  @override
  String orbLabel(int percent) {
    return '$percent% позади. Нажмите, чтобы сменить фразу';
  }

  @override
  String get jokesLabel => 'Фразы недели';

  @override
  String get jokesMore => 'Другие фразы';

  @override
  String get hintCountryTitle => 'Учитывать праздники';

  @override
  String get hintCountryBody => 'Выберите страну, и праздники сократят неделю';

  @override
  String get hintHolidaysFailedTitle => 'Праздники не загружены';

  @override
  String weekendLonger(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Выходные длиннее на $count дня',
      many: 'Выходные длиннее на $count дней',
      few: 'Выходные длиннее на $count дня',
      one: 'Выходные длиннее на $count день',
    );
    return '$_temp0';
  }

  @override
  String get widgetTipTitle => 'Таймер на главном экране';

  @override
  String get widgetTipBody => 'Добавьте виджет за полминуты';

  @override
  String get widgetsTitle => 'Виджеты';

  @override
  String get widgetStepIos1 =>
      'Нажмите и подержите пустое место на экране «Домой»';

  @override
  String get widgetStepIos2 => 'Нажмите «Править», затем «Добавить виджет»';

  @override
  String get widgetStepIos3 => 'Найдите «Счётчик выходных» и выберите размер';

  @override
  String get widgetStepAndroid1 =>
      'Удерживайте палец на пустом месте главного экрана';

  @override
  String get widgetStepAndroid2 => 'Откройте «Виджеты»';

  @override
  String get widgetStepAndroid3 =>
      'Найдите «Счётчик выходных» и перетащите на экран';

  @override
  String get widgetUpdatesNote =>
      'Цифры обновляются сами, даже когда приложение закрыто.';

  @override
  String get gotIt => 'Понятно';

  @override
  String get done => 'Готово';

  @override
  String get close => 'Закрыть';

  @override
  String get back => 'Назад';

  @override
  String get today => 'Сегодня';

  @override
  String daysOffIn(String monthIn) {
    return 'Свободных дней $monthIn';
  }

  @override
  String holidayOn(String date) {
    return 'праздник $date';
  }

  @override
  String get noHolidaysShort => 'без праздников';

  @override
  String get upcomingHolidays => 'Ближайшие праздники';

  @override
  String get noUpcomingHolidays => 'Выберите страну, чтобы видеть праздники';

  @override
  String get settingsSubtitle =>
      'Сохраняем сразу. Таймер и виджет пересчитаются сами.';

  @override
  String get workdaysHint => 'Нажмите на день, чтобы выбрать свои';

  @override
  String get shiftStartsAt => 'Начало';

  @override
  String get shiftEndsAt => 'Конец';

  @override
  String get celebrateWeekend => 'Выходные!';

  @override
  String get celebrateLongWeekend => 'Длинные выходные!';

  @override
  String get celebrateHoliday => 'Праздник!';

  @override
  String get celebrateDaysOff => 'Отдых!';

  @override
  String get celebrateEyebrow => 'неделя позади';

  @override
  String get celebrateLateEyebrow => 'с опозданием, но от души';

  @override
  String get celebrateWas => 'работа';

  @override
  String celebrateBody(String duration) {
    return 'Работа закончилась. Впереди $duration без работы.';
  }

  @override
  String get celebrateBodyOpen => 'Работа закончилась. Отдыхайте.';

  @override
  String celebrateLateBody(String when) {
    return 'Неделя закончилась $when. Празднуем всё равно.';
  }

  @override
  String get celebrateCta => 'Ура, отдыхаю';

  @override
  String get navAwards => 'Награды';

  @override
  String get scheduleTitle => 'График';

  @override
  String get weekHeader => 'Неделя';

  @override
  String get weekStarts => 'Начало недели';

  @override
  String get weekEnds => 'Конец недели';

  @override
  String get holidaysShort => 'Праздники';

  @override
  String get holidaysShortHint => 'Короткие недели и переносы';

  @override
  String get sectionExtras => 'Виджеты и эффекты';

  @override
  String get confetti => 'Конфетти';

  @override
  String get confettiHint =>
      'Если в iPhone включено «Уменьшение движения», покажем открытку без анимации';

  @override
  String weeksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count недели',
      many: '$count недель',
      few: '$count недели',
      one: '$count неделя',
    );
    return '$_temp0';
  }

  @override
  String get vacationTitle => 'Отпуск';

  @override
  String get vacationNone => 'Нет';

  @override
  String get vacationIntro =>
      'В отпуске считаем дни до возвращения. Недели для наград сохранятся.';

  @override
  String get vacationHowLong => 'Сколько';

  @override
  String get vacationFrom => 'С какого дня';

  @override
  String vacationWeeks(int count) {
    return '$count нед';
  }

  @override
  String get vacationFromTomorrow => 'С завтра';

  @override
  String get vacationFromMonday => 'С понедельника';

  @override
  String vacationGo(String days) {
    return 'Уйти в отпуск на $days';
  }

  @override
  String get vacationActive => 'Вы в отпуске';

  @override
  String get vacationPlanned => 'Отпуск запланирован';

  @override
  String vacationActiveBody(String date) {
    return 'До $date включительно. Считаем дни до возвращения, недели для наград сохранятся.';
  }

  @override
  String vacationPlannedBody(String from, String to) {
    return 'С $from по $to включительно. Считаем дни до возвращения, недели для наград сохранятся.';
  }

  @override
  String get vacationEndEarly => 'Вернуться раньше';

  @override
  String get vacationCancel => 'Отменить отпуск';

  @override
  String get vacationNote => 'Отпуск';

  @override
  String untilInclusive(String date) {
    return 'До $date включительно';
  }

  @override
  String holidayMidweek(String when) {
    return 'Праздник посреди недели. Работа $when';
  }

  @override
  String get eyebrowVacationPrefix => 'отпуск · до';

  @override
  String get eyebrowVacationStrike => 'работы';

  @override
  String get eyebrowVacationSuffix => 'возвращения';

  @override
  String get onbSkip => 'Пропустить';

  @override
  String get onbStart => 'Начать';

  @override
  String get onbNext => 'Дальше';

  @override
  String onbStep(int n, int m) {
    return 'Шаг $n из $m';
  }

  @override
  String get onbWelcomePrefix => 'Считаем до';

  @override
  String get onbWelcomeStrike => 'пятницы';

  @override
  String get onbWelcomeSuffix => 'свободы';

  @override
  String get onbWelcomeBody =>
      'Скажите, когда заканчивается ваша рабочая неделя. Шар будет заполняться к выходным, а когда они начнутся, будет маленький праздник.';

  @override
  String get onbTypeTitle => 'Как вы работаете?';

  @override
  String get onbFiveDay => 'Пятидневка';

  @override
  String get onbFiveDayHint => 'Пн–Пт, выходные в субботу и воскресенье';

  @override
  String get onbCustom => 'Свой график';

  @override
  String get onbCustomHint => 'Свои дни, например вт–сб';

  @override
  String get onbTimeTitle => 'Когда ваша рабочая неделя?';

  @override
  String get onbWidgetBody =>
      'Виджет покажет, сколько осталось, даже если приложение закрыто.';

  @override
  String get onbHowToWidget => 'Как добавить виджет';

  @override
  String get onbNotNow => 'Не сейчас';

  @override
  String get awardsHero => 'раз дождались\nвыходных';

  @override
  String awardsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count награды',
      many: '$count наград',
      few: '$count награды',
      one: '$count награда',
      zero: 'наград пока нет',
    );
    return '$_temp0';
  }

  @override
  String awardsMore(int count) {
    return 'и ещё $count';
  }

  @override
  String get awardsWeekly => 'Недели';

  @override
  String get awardsSpecial => 'Особые';

  @override
  String awardsProgress(int got, int total) {
    return '$got из $total получено';
  }

  @override
  String get awardLocked => 'ещё не получена';

  @override
  String awardEarnedOn(String date) {
    return 'получена $date';
  }

  @override
  String awardWeeksLeft(String weeks) {
    return 'ещё $weeks';
  }

  @override
  String awardNew(String name) {
    return 'Новая награда: $name';
  }

  @override
  String celebrateWeeks(String weeks) {
    return '$weeks позади';
  }

  @override
  String celebrateNext(String weeks, String name) {
    return 'До «$name» ещё $weeks';
  }

  @override
  String get celebrateAllDone => 'Все награды за недели собраны';

  @override
  String atNight(String day) {
    return '$day, ночью';
  }

  @override
  String get widgetSetUp => 'Откройте приложение для настройки';
}
