# Orbity on the App Store

Everything to fill in on App Store Connect for version 1.0. English is the primary language; add Russian under **App Information › Localizable Information** and in the version's Russian tab.

## App Information

| Field | Value |
| --- | --- |
| Name | Orbity |
| Bundle ID | `io.github.sul1aaa.orbity` |
| Primary category | Productivity |
| Secondary category | Lifestyle |
| Age rating | 4+ (answer "None" to every question) |
| Price | Free |
| Devices | iPhone only |

## Version 1.0

### Subtitle (30 characters max)

- **English:** Countdown to your weekend
- **Russian:** Отсчёт до выходных

### Promotional text (170 max)

**English:**

> Watch your week fill up. Orbity counts down to the end of your last shift before the weekend or a holiday, right on your home screen.

**Russian:**

> Смотрите, как наполняется неделя. Orbity считает время до конца последней смены перед выходными или праздником — прямо на экране «Домой».

### Description

**English:**

```text
Orbity counts down to the moment your work week actually ends: Friday at 18:00, or whenever your last shift before time off is over.

WATCH YOUR WEEK FILL UP
A glass orb fills with violet as the week goes by. When time off starts, it turns lime and slowly drains back toward Monday. Tap it for a new line about your week.

A COUNTDOWN THAT KNOWS YOUR SCHEDULE
• Set your workdays and shift hours.
• Public holidays for your country load automatically and work offline.
• A Wednesday holiday counts down to Tuesday evening. A Friday holiday turns your weekend into a long one.
• Mark vacation days and extra working days in the calendar.

ON YOUR HOME SCREEN
Small and medium widgets show the countdown, the orb and a progress bar. They stay up to date even when the app is closed.

EVERY WEEKEND GETS A PARTY
When time off starts, Orbity greets it with a "Weekend!" screen and confetti.

A BADGE FOR EVERY WEEK
Earn badges for the weekends you reach, from your first Friday to a full year, plus a few special ones.

PRIVATE BY DESIGN
No account, no ads, no tracking. Your schedule stays on your phone.

In English and Russian, in light and dark mode.
```

**Russian:**

```text
Orbity считает время до момента, когда рабочая неделя действительно заканчивается: до пятницы 18:00 или до конца последней смены перед отдыхом.

НЕДЕЛЯ НАПОЛНЯЕТСЯ НА ГЛАЗАХ
Стеклянный шар наполняется фиолетовым по мере того, как идёт неделя. Когда начинается отдых, он становится лаймовым и медленно убывает к понедельнику. Нажмите на шар, чтобы сменить фразу о неделе.

ОТСЧЁТ ПО ВАШЕМУ ГРАФИКУ
• Укажите рабочие дни и часы смены.
• Праздники вашей страны загружаются сами и работают без интернета.
• Праздник в среду — отсчёт до вечера вторника. Праздник в пятницу превращает выходные в длинные.
• Отмечайте в календаре отпуск и рабочие субботы.

НА ЭКРАНЕ «ДОМОЙ»
Маленький и средний виджеты показывают отсчёт, шар и полоску прогресса. Они обновляются, даже когда приложение закрыто.

КАЖДЫЕ ВЫХОДНЫЕ — ПРАЗДНИК
Когда начинается отдых, Orbity встречает его экраном «Выходные!» и конфетти.

НАГРАДА ЗА КАЖДУЮ НЕДЕЛЮ
Получайте награды за каждые выходные — от первой пятницы до целого года, а ещё несколько особых.

БЕЗ ЛИШНЕГО
Без аккаунта, без рекламы, без слежки. Ваш график остаётся на телефоне.

На русском и английском, в светлой и тёмной теме.
```

### Keywords (100 max, commas, no spaces)

- **English:** `friday,holidays,timer,work week,shift,days off,vacation,widget,calendar,tgif,office,schedule,hours`
- **Russian:** `пятница,праздники,таймер,рабочая неделя,смена,отпуск,виджет,календарь,график,офис,выходной`

Words from the name and subtitle are left out; the App Store already searches those.

### Screenshots

iPhone 6.9" display, 1320 × 2868, in this order:

- English: `store/screenshots/en/1-week.png` … `5-awards.png`
- Russian: `store/screenshots/ru/1-week.png` … `5-awards.png`

App Store Connect scales them down for smaller iPhones. To make them again after a UI change, see "App Store screenshots" in the README.

### URLs

| Field | Value |
| --- | --- |
| Support URL | https://github.com/sul1aaa/week_counter/issues |
| Privacy Policy URL | https://github.com/sul1aaa/week_counter/blob/main/PRIVACY.md |
| Marketing URL | leave empty |

The privacy policy URL works once `PRIVACY.md` is merged to `main`.

### Copyright

`2026 <your name>`

## App Privacy

Answer **"No, we do not collect data from this app."** The app has no account, ads or analytics. Your schedule, calendar marks and awards stay on the phone. The one network request asks Nager.Date for a country's public holidays, and the app doesn't keep or send anything about the person.

## App Review notes

```text
No sign-in is needed. On first launch, onboarding asks for the workdays, shift hours and country, then the main screen counts down to the end of the last shift before the weekend.

Public holidays come from the free Nager.Date API (date.nager.at). The home-screen widgets are in the widget gallery under "Orbity".
```

## Export compliance

The build already answers it: `ITSAppUsesNonExemptEncryption` is `NO`. The app only uses standard HTTPS to download public holidays.
