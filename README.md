# Week Counter

Counts down to the end of your last shift before the next weekend or public holiday, with home-screen widgets for Android and iOS. English and Russian.

- **Countdown:** counts down to when work actually ends, e.g. Friday 18:00, using your workdays and shift hours. A Wednesday holiday counts to Tuesday 18:00. A Friday holiday turns the weekend into a long weekend starting Thursday 18:00. While you're off, it counts down to the start of your next shift.
- **Public holidays:** from [Nager.Date](https://date.nager.at) for your country. They're cached per year, so the app works offline.
- **Calendar:** tap a day to mark it as a day off (vacation) or as a workday. A workday override covers things like Russian transferred working Saturdays, or ignoring a holiday you work on. To select a range, long-press the first day, then tap the last.
- **Design:** the iOS 26 look from the «Выходные» prototype: Wabi neutrals with lime and violet, a glass tab bar, an orb that fills as the week goes by, a line of the week with a crossed-out joke, and a "Weekend!" screen with confetti when time off starts. Light and dark follow the phone; reduced motion turns the animations off.
- **Widgets:** the app precomputes about three months of countdown text and hands it to the native widget, so the widget stays correct without the app being open.

## Run

```sh
flutter pub get
flutter test
flutter run
```

## Code map

| Path | What |
| --- | --- |
| `lib/domain/day_classifier.dart` | Decides whether a day is a workday or a day off, and why |
| `lib/domain/countdown_engine.dart` | Groups days off into blocks and computes the countdown target |
| `lib/domain/widget_payload.dart` | The JSON segments the native widgets render |
| `lib/state/app_controller.dart` | App state; every change saves, recomputes and updates the widget |
| `lib/ui/theme/tokens.dart` | Colors, type ramp and motion curves for light and dark |
| `lib/ui/kit/` | Shared components: glass, buttons, grouped rows, toggle, sheet, orb, rolling timer |
| `lib/l10n/jokes.dart` | The lines under the orb, in English and Russian, and which fit when |
| `lib/services/` | Storage, the Nager.Date client and its cache, the widget bridge (`home_widget`) |
| `lib/l10n/` | ARB files for English and Russian, plus shared labels |
| `assets/fonts/` | Inter, Inter Tight and JetBrains Mono (Latin and Cyrillic, SIL OFL 1.1) |
| `android/app/src/main/kotlin/.../WeekCounterWidgetProvider.kt` | Android widget |
| `ios/WeekCounterWidget/` | iOS WidgetKit extension |

## Android widget

To add it, long-press the home screen, open **Widgets**, and choose **Week Counter**. Settings also has an "Add widget" button if your launcher supports it.

The widget ticks every second when the app is allowed to use exact alarms. On Android 14+ that's off by default. Settings shows a **Precise widget countdown › Allow** row that opens the system permission screen. Without the permission, the widget shows "2d 3h" and refreshes about every 30 minutes.

## iOS widget

The `WeekCounterWidget` extension target is already in the Xcode project, with the App Group `group.com.example.weekCounter` on both the app and the extension. To add it, long-press the home screen, tap **Edit › Add Widget**, and search for **Week Counter**.

**Simulator:** works as is.

**Real device:** App Groups need a paid Apple Developer team (the project uses `9746P6DV47`).

1. Open `ios/Runner.xcworkspace`.
2. Under **Signing & Capabilities**, select the **Runner** target and then the **WeekCounterWidget** target. Let Xcode register the App Group for each.
3. If Xcode says the group ID is taken, change `group.com.example.weekCounter` in these 4 places:
   - `lib/services/widget_sync.dart` (`HomeWidgetSync.appGroupId`)
   - `ios/WeekCounterWidget/WeekCounterWidget.swift` (`PayloadStore.groupId`)
   - `ios/Runner/Runner.entitlements`
   - `ios/WeekCounterWidget/WeekCounterWidget.entitlements`

   Change the bundle IDs (`com.example.weekCounter…`) the same way if they're taken.

## Known limits

- Nager.Date has national holidays only. It has no regional holidays and no Russian transferred workdays; use the calendar overrides for those.
- The widget's text is written by the app. After changing the phone's language or time zone, open the app once to update the widget.
