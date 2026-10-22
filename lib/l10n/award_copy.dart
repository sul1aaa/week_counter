/// Award names and descriptions. `why` says what it was given for, `how`
/// what to do to get a special one. `mark` is stamped on the badge.
typedef AwardCopy = ({String name, String why, String how, String mark});

AwardCopy awardCopy(String localeName, String id) =>
    (localeName.startsWith('ru') ? _ru : _en)[id]!;

const _en = <String, AwardCopy>{
  'w1': (
    name: 'First Friday',
    why: 'Your first week with the timer is done',
    how: '',
    mark: '1',
  ),
  'w4': (
    name: 'A month, no panic',
    why: 'Made it to the weekend four times',
    how: '',
    mark: '4',
  ),
  'w10': (
    name: 'Top ten',
    why: 'Ten weeks. That’s a habit now',
    how: '',
    mark: '10',
  ),
  'w26': (
    name: 'Half a year strong',
    why: 'Twenty-six Fridays waited for you',
    how: '',
    mark: '26',
  ),
  'w52': (
    name: 'A year of Fridays',
    why: 'Fifty-two weeks. Time for a vacation',
    how: '',
    mark: '52',
  ),
  'friday13': (
    name: 'Friday the 13th',
    why: 'Made it to the weekend on Friday the 13th and didn’t even notice',
    how: 'Make it to the weekend on Friday the 13th',
    mark: '13',
  ),
  'shortWeek': (
    name: 'Short week',
    why: 'A holiday ate a workday',
    how: 'Make it through a week with a holiday',
    mark: '4d',
  ),
  'nightShift': (
    name: 'Night watch',
    why: 'Made it to the weekend on night shifts',
    how: 'Finish a week of night shifts',
    mark: 'N',
  ),
  'vacation': (
    name: 'Vacationer',
    why: 'Planned your first vacation',
    how: 'Plan a vacation in Schedule',
    mark: 'V',
  ),
  'lastMinute': (
    name: 'Right on the minute',
    why: 'Had the app open in the last minute of the week',
    how: 'Open the app in the last minute of the week',
    mark: '60',
  ),
  'widget': (
    name: 'Home screen regular',
    why: 'Set up the widget: the timer shows without the app',
    how: 'Put the widget on your home screen',
    mark: 'W',
  ),
};

const _ru = <String, AwardCopy>{
  'w1': (
    name: 'Первая пятница',
    why: 'Первая неделя с таймером позади',
    how: '',
    mark: '1',
  ),
  'w4': (
    name: 'Месяц без паники',
    why: 'Четыре раза дождались выходных',
    how: '',
    mark: '4',
  ),
  'w10': (
    name: 'Десятка',
    why: 'Десять недель. Это уже привычка',
    how: '',
    mark: '10',
  ),
  'w26': (
    name: 'Полгода стойкости',
    why: 'Двадцать шесть пятниц дождались вас',
    how: '',
    mark: '26',
  ),
  'w52': (
    name: 'Год пятниц',
    why: 'Пятьдесят две недели. Можно в отпуск',
    how: '',
    mark: '52',
  ),
  'friday13': (
    name: 'Пятница, 13-е',
    why: 'Дождались выходных в пятницу, 13-е, и даже не заметили',
    how: 'Дождитесь выходных в пятницу, 13-е',
    mark: '13',
  ),
  'shortWeek': (
    name: 'Короткая неделя',
    why: 'Праздник съел один рабочий день',
    how: 'Дождитесь недели с праздником',
    mark: '4д',
  ),
  'nightShift': (
    name: 'Ночной дозор',
    why: 'Дождались выходных на ночных сменах',
    how: 'Отработайте неделю ночными сменами',
    mark: 'Н',
  ),
  'vacation': (
    name: 'Отпускник',
    why: 'Запланировали первый отпуск',
    how: 'Запланируйте отпуск в «Графике»',
    mark: 'О',
  ),
  'lastMinute': (
    name: 'Минута в минуту',
    why: 'Были в приложении в последнюю минуту недели',
    how: 'Откройте приложение в последнюю минуту недели',
    mark: '60',
  ),
  'widget': (
    name: 'Прописался на экране',
    why: 'Поставили виджет: таймер видно без приложения',
    how: 'Поставьте виджет на главный экран',
    mark: 'W',
  ),
};
