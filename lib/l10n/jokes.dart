import '../core/calendar_date.dart';
import '../domain/countdown_engine.dart';
import '../models/work_schedule.dart';
import 'app_localizations.dart';
import 'labels.dart';

/// The lines under the orb. `~~word~~` is drawn struck through: the joke is
/// in what's crossed out. `{left}` is the time left ("2 days 4 hours"),
/// `{end}` the time work ends ("18:00") and `{holiday}` today's holiday,
/// only ever at the start of a line.
enum JokePool {
  monMorning,
  mon,
  tue,
  wed,
  thu,
  fri,
  lastDay,
  lastHour,
  weekend,
  sunEvening,
  preWork,
  holiday,
  daysOff,
  work,
  night,
}

const _en = <JokePool, List<String>>{
  JokePool.monMorning: [
    'Monday ~~is hard~~ is just a day. Coffee helps.',
    'The week just started and you already opened the timer. Respect.',
    'First coffee counted. The weekend is already closer than it was.',
    'Monday. Plan for the week: ~~get everything done~~ get to the weekend.',
    'Monday morning. Asked “how was your weekend?”, answer ~~honestly~~ briefly.',
  ],
  JokePool.mon: [
    'Monday is almost over. The hardest part ~~is just beginning~~ is done.',
    'Half of Monday is behind you. From here the week ~~drags~~ rolls on its own.',
    'Monday afternoon ~~drags on~~ is basically Tuesday.',
  ],
  JokePool.tue: [
    'Tuesday: Monday is behind you, ~~Friday~~ Wednesday is ahead.',
    'The quietest day of the week. Let’s slip through.',
    'Tuesday is a Monday that ~~gave up~~ settled in.',
    'Tuesday. Perfect time to ~~start on Monday~~ start on Tuesday.',
  ],
  JokePool.wed: [
    'Wednesday is the equator. From here it’s ~~uphill~~ downhill to Friday.',
    'Half the week is done. The second half ~~drags~~ flies by faster, it’s proven.',
    'Wednesday. Friday is ~~beyond~~ on the horizon.',
  ],
  JokePool.thu: [
    'Thursday is a ~~small~~ practice Friday.',
    'Tomorrow is Friday. Today you can rehearse.',
    'Thursday. Friday is ~~on the horizon~~ in the next tab.',
  ],
  JokePool.fri: [
    'Friday. “I’ll reply on Monday” mode turns on at {end}.',
    'Friday! Perfect time to ~~start a new project~~ close some tabs.',
    'The final push. The couch is already warming up.',
    'Friday. The hard stuff ~~gets done today~~ becomes Monday’s plan.',
  ],
  JokePool.lastDay: [
    'Last day of the week. Long emails ~~get sent~~ go to drafts.',
    'Last day. The couch is already ~~waiting~~ warming up.',
    'Today you can ~~start a new project~~ close some tabs.',
    'Last day. The week ends at {end}, no delays.',
  ],
  JokePool.lastHour: [
    'Home stretch. Hit “Save” and ~~“Reply all”~~ nothing else.',
    'Last hour. You may stare out the window with a clear conscience.',
    '{left} to go. Perfect time to ~~start a report~~ water the plant.',
    'Last hour. To “got a minute?” the answer is ~~yes~~ “after the weekend”.',
  ],
  JokePool.weekend: [
    'Weekend. The alarm clock is ~~off~~ fired.',
    'Work will wait. It’s patient, you’ve checked.',
    'Official: you may do nothing and feel no guilt.',
    'Weekend. The only deadline left is ~~the quarterly report~~ breakfast.',
  ],
  JokePool.sunEvening: [
    'Sunday evening. Don’t think about Monday, it will think about you.',
    'Sunday. The alarm clock is ~~back on duty~~ still on probation.',
  ],
  JokePool.preWork: [
    'The alarm clock is ~~back on duty~~ still on probation.',
    'A bit more freedom. Work ~~is waiting~~ can wait.',
    'The weekend is ending, but not right now.',
  ],
  JokePool.holiday: [
    'A holiday mid-week is like two little Fridays.',
    '{holiday}. The calendar is on your side today.',
    '{holiday}. Work is ~~postponed~~ cancelled for a good reason.',
  ],
  JokePool.daysOff: [
    'You’re off. “How’s work?” is a ~~serious~~ question for someone else.',
    'The work chat can ~~wait~~ manage without you.',
    'You’re off. Feel free to ~~forget~~ not think about your work password.',
  ],
  JokePool.work: [
    '{left} until the weekend. Counting together.',
    'The shift is on, the orb is filling up. All according to ~~plan~~ schedule.',
    'Middle of the work stretch. The weekend is ~~far away~~ closer than it seems.',
  ],
  JokePool.night: [
    'Night shift. Your ~~late dinner~~ lunch is right on schedule.',
  ],
};

const _ru = <JokePool, List<String>>{
  JokePool.monMorning: [
    'Понедельник ~~день тяжёлый~~ просто день. Кофе поможет.',
    'Неделя только началась, а вы уже открыли таймер. Уважаем.',
    'Первый кофе засчитан. До выходных уже меньше, чем было.',
    'Понедельник. План на неделю: ~~успеть всё~~ успеть к выходным.',
    'Утро понедельника. На «как выходные?» отвечаем ~~честно~~ коротко.',
  ],
  JokePool.mon: [
    'Понедельник почти позади. Самое сложное ~~только начинается~~ закончилось.',
    'Полпонедельника позади. Дальше неделя ~~тянется~~ катится сама.',
    'Понедельник после обеда ~~тянется~~ почти вторник.',
  ],
  JokePool.tue: [
    'Вторник: понедельник позади, ~~пятница~~ среда впереди.',
    'Самый незаметный день недели. Проскочим тихо.',
    'Вторник — это понедельник, который ~~смирился~~ освоился.',
    'Вторник. Самое время ~~начать с понедельника~~ начать со вторника.',
  ],
  JokePool.wed: [
    'Среда — экватор. Дальше ~~в гору~~ с горки, к пятнице.',
    'Половина недели позади. Вторая ~~тянется~~ пролетает быстрее, проверено.',
    'Среда. Пятница ~~за горизонтом~~ на горизонте.',
  ],
  JokePool.thu: [
    'Четверг — ~~маленькая~~ тренировочная пятница.',
    'Завтра пятница. Сегодня можно репетировать.',
    'Четверг. Пятница ~~на горизонте~~ в соседней вкладке.',
  ],
  JokePool.fri: [
    'Пятница. Режим «отвечу в понедельник» включается в {end}.',
    'Пятница! Самое время ~~начать новый проект~~ закрыть вкладки.',
    'Последний рывок. Диван уже прогревается.',
    'Пятница. Сложное ~~сделаем сегодня~~ назовём планом на понедельник.',
  ],
  JokePool.lastDay: [
    'Последний день недели. Длинные письма ~~пишем~~ сохраняем в черновики.',
    'Последний день. Диван уже ~~ждёт~~ прогревается.',
    'Сегодня можно ~~начать новый проект~~ закрыть вкладки.',
    'Последний день. Конец недели в {end}, без опозданий.',
  ],
  JokePool.lastHour: [
    'Финишная прямая. Нажмите «Сохранить» и ~~«Ответить всем»~~ больше ничего.',
    'Последний час. Можно смотреть в окно с чистой совестью.',
    'Осталось {left}. Самое время ~~начать отчёт~~ полить цветок.',
    'Последний час. На «есть минутка?» отвечаем ~~да~~ «после выходных».',
  ],
  JokePool.weekend: [
    'Выходные. Будильник ~~выключен~~ уволен.',
    'Работа подождёт. Она терпеливая, вы проверяли.',
    'Официально: можно ничего не делать и не чувствовать вину.',
    'Выходные. Из дедлайнов остался ~~квартальный отчёт~~ завтрак.',
  ],
  JokePool.sunEvening: [
    'Воскресный вечер. Не думайте о понедельнике, он подумает о вас сам.',
    'Воскресенье. Будильник ~~восстановлен в должности~~ пока на испытательном сроке.',
  ],
  JokePool.preWork: [
    'Будильник ~~восстановлен в должности~~ пока на испытательном сроке.',
    'Ещё немного свободы. Работа ~~ждёт~~ подождёт.',
    'Выходные заканчиваются, но не прямо сейчас.',
  ],
  JokePool.holiday: [
    'Праздник посреди недели — как две маленькие пятницы.',
    '{holiday}. Календарь сегодня на вашей стороне.',
    '{holiday}. Работа ~~переносится~~ отменяется по уважительной причине.',
  ],
  JokePool.daysOff: [
    'Вы отдыхаете. Вопрос «как дела на работе?» ~~важный~~ не к вам.',
    'Рабочий чат может ~~подождать~~ обойтись без вас.',
    'Вы отдыхаете. Рабочий пароль можно ~~забыть~~ не вспоминать.',
  ],
  JokePool.work: [
    'До выходных {left}. Считаем вместе.',
    'Смена идёт, шар наполняется. Всё по ~~плану~~ графику.',
    'Середина рабочего блока. Выходные ~~далеко~~ ближе, чем кажется.',
  ],
  JokePool.night: ['Ночная смена. У вас ~~поздний ужин~~ обед по расписанию.'],
};

List<String> jokeLines(String localeName, JokePool pool) =>
    (localeName.startsWith('ru') ? _ru : _en)[pool]!;

bool _isFiveDay(WorkSchedule schedule) =>
    schedule.workdays.length == 5 &&
    schedule.workdays.every((d) => d <= DateTime.friday);

/// Which pools fit [state] at [now].
List<JokePool> jokePools(
  CountdownState state,
  WorkSchedule schedule,
  DateTime now,
) {
  final today = CalendarDate.fromDateTime(now);
  final five = _isFiveDay(schedule);
  switch (state) {
    case OffNow(:final block, :final backToWork):
      if (block.kind == BlockKind.daysOff) return [JokePool.daysOff];
      if (block.kind == BlockKind.holiday) return [JokePool.holiday];
      if (five && now.weekday == DateTime.sunday && now.hour >= 16) {
        return [JokePool.sunEvening];
      }
      if (backToWork != null &&
          backToWork.difference(now) < const Duration(hours: 8)) {
        return [JokePool.preWork];
      }
      return [JokePool.weekend];
    case CountingDown(:final target, :final block):
      if (target.difference(now) <= const Duration(hours: 1)) {
        return [JokePool.lastHour];
      }
      final lastShiftDay = block.first.addDays(-1);
      final overnight = schedule.shiftFor(lastShiftDay.weekday).isOvernight;
      final lastDay =
          today == lastShiftDay || (overnight && today == block.first);
      return [
        if (schedule.shiftFor(today.weekday).isOvernight) JokePool.night,
        if (lastDay)
          five && now.weekday == DateTime.friday
              ? JokePool.fri
              : JokePool.lastDay
        else if (five)
          switch (now.weekday) {
            DateTime.monday =>
              now.hour < 12 ? JokePool.monMorning : JokePool.mon,
            DateTime.tuesday => JokePool.tue,
            DateTime.wednesday => JokePool.wed,
            DateTime.thursday => JokePool.thu,
            DateTime.friday => JokePool.fri,
            _ => JokePool.work,
          }
        else
          JokePool.work,
      ];
    case NoWorkdays() || NoDaysOff():
      return const [];
  }
}

/// The lines for [state], placeholders filled in.
List<String> jokes(
  AppLocalizations l10n,
  CountdownState state,
  WorkSchedule schedule,
  DateTime now, {
  String? holidayToday,
}) {
  final (left, end) = switch (state) {
    CountingDown(:final target) => (target.difference(now), target),
    OffNow(:final backToWork?) => (backToWork.difference(now), backToWork),
    _ => (Duration.zero, null),
  };
  return [
    for (final pool in jokePools(state, schedule, now))
      for (final line in jokeLines(l10n.localeName, pool))
        if (holidayToday != null || !line.contains('{holiday}'))
          line
              .replaceAll('{left}', l10n.humanDuration(left))
              .replaceAll('{end}', end == null ? '' : l10n.time(end))
              .replaceAll('{holiday}', holidayToday ?? ''),
  ];
}
