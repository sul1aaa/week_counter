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

Upload them under **iPhone with Dynamic Island (medium display)**, which takes 1206 × 2622, in this order:

- English: `store/screenshots/6.3-inch/en/1-week.png` … `5-awards.png`
- Russian: `store/screenshots/6.3-inch/ru/1-week.png` … `5-awards.png`

`store/screenshots/6.9-inch` has the same images at 1320 × 2868, for a large-display group if App Store Connect asks for one. To make them again after a UI change, see "App Store screenshots" in the README.

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

Version 1.0 was rejected under Guideline 2.1 (Information Needed): Apple asked for a screen recording and the five answers below. Paste this into **App Review Information › Notes** (4,000 characters max), and attach the recording there or link to it.

```text
SCREEN RECORDING
Recorded on a physical iPhone running iOS 26.6.2, build 1.0.0 (1): attached in the Attachment field below. It starts at launch and shows onboarding, the countdown, schedule, calendar, awards and the home-screen widget.

1. PURPOSE AND AUDIENCE
Orbity counts down to the end of your work week. It's for adults with a job, office workers and shift workers alike, who want to know exactly how long is left until the weekend or the next holiday. A plain timer can't answer that because the end of the week depends on your workdays, shift hours, public holidays and vacation. Orbity takes all of these into account and counts down to the end of your last shift before time off. A glass orb fills as the week goes by, home-screen widgets show the countdown, and you earn a badge for each weekend you reach.

2. SETUP AND MAIN FEATURES
No account, login, sample files or purchases are needed. The app is free and has no in-app purchases, ads or user-generated content.
- Launch the app and tap "Get started".
- Step 1: choose "Five-day week" or "Your own schedule".
- Step 2: set the work day's start and end time. The country is filled in from the device region. Tap it to change.
- Step 3: shows how to add the widget. Tap "Not now" to finish.
- Week tab: time left until the end of the last shift before time off. Tap the orb for a new line about the week. Pull down to refresh holidays. The Schedule button (top right) changes workdays, hours, country and vacation.
- Calendar tab: public holidays are marked. Tap a day to change it. Long-press to select several days.
- Awards tab: badges for the weekends you reach.
- Widget: touch and hold the home screen, tap Edit > Add Widget, then choose Orbity (small or medium).
When time off starts, the app shows a "Weekend!" screen with confetti.

3. EXTERNAL SERVICES
The only one is Nager.Date (https://date.nager.at), a free public holiday API that needs no key or account. The app requests the list of countries and the public holidays for the chosen country and year. Responses are cached on the device, so the app also works offline. There is no authentication, payment, analytics, advertising or AI service, and no personal data is collected.

4. REGIONAL DIFFERENCES
The app works the same in all regions. The only regional difference is content: it shows the public holidays of the country the user chooses (Nager.Date covers more than 100 countries). If a country isn't covered, or the device is offline with nothing cached, the countdown still works from the user's own schedule, just without public holidays. The app is available in English and Russian.

5. REGULATED INDUSTRY / THIRD-PARTY MATERIAL
Not applicable. The app isn't in a regulated industry and contains no protected third-party material. Holiday dates come from Nager.Date's free public API.
```

## Export compliance

The build already answers it: `ITSAppUsesNonExemptEncryption` is `NO`. The app only uses standard HTTPS to download public holidays.
