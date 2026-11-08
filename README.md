# Orbity

Counts down to the end of your last shift before the next weekend or public holiday, with home-screen widgets for Android and iOS. English and Russian.

- **Countdown:** counts down to when work actually ends, e.g. Friday 18:00, using your workdays and shift hours. A Wednesday holiday counts to Tuesday 18:00. A Friday holiday turns the weekend into a long weekend starting Thursday 18:00. While you're off, it counts down to the start of your next shift.
- **Public holidays:** from [Nager.Date](https://date.nager.at) for your country. They're cached per year, so the app works offline.
- **Calendar:** tap a day to mark it as a day off (vacation) or as a workday. A workday override covers things like Russian transferred working Saturdays, or ignoring a holiday you work on. To select a range, long-press the first day, then tap the last.
- **Design:** the iOS 26 look from the «Выходные» prototype: Wabi neutrals with lime and violet, a glass tab bar (Week, Calendar, Awards), an orb that fills as the week goes by, a line of the week with a crossed-out joke, and a "Weekend!" screen with confetti when time off starts. Light and dark follow the phone; reduced motion turns the animations off.
- **Schedule, vacation, awards:** the tune button on the Week screen opens Schedule (workdays, hours, holidays, vacation, widget). Vacation marks a run of days off and counts down to your return. Awards count every time off that starts, with badges for 1–52 weeks and a few special ones. First launch walks through a short onboarding.
- **Widgets:** the app precomputes about three months of countdown text and hands it to the native widget, so the widget stays correct without the app being open. Like the preview in the app's Widgets sheet, the widgets show the orb and the progress bar, filled to how far the week or the time off has gone.

## Run

```sh
flutter pub get
flutter test
flutter run
```

The project pins Flutter 3.44.9 with fvm (`.fvmrc`), and `.vscode/settings.json` points VS Code at the same SDK. Keep the terminal and the editor on one SDK. Otherwise each one's `pub get` regenerates `ios/Flutter/ephemeral` its own way, and the iOS build fails with "Missing package product".

`.vscode/settings.json` also turns off the Dart extension's automatic `pub get` (`dart.runPubGetOnPubspecChanges: never`). home_widget needs iOS 14, but `pub get` writes the generated plugin package with iOS 13. `flutter run` raises it to the Runner's deployment target (14.0) just before Xcode builds. The build strips extended attributes from every project file, including `pubspec.yaml`. The extension took that as an edit and ran `pub get` mid-build, which reset the package to 13.0 and failed with "home-widget requires minimum platform version 14.0". `flutter run` and `flutter build` already run `pub get` when `pubspec.yaml` changes. If you edit dependencies without running the app, run `flutter pub get` yourself.

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
| `lib/domain/awards.dart`, `lib/l10n/award_copy.dart` | Award definitions and their names in both languages |
| `lib/services/` | Storage, the Nager.Date client and its cache, the widget bridge (`home_widget`) |
| `lib/l10n/` | ARB files for English and Russian, plus shared labels |
| `assets/fonts/` | Inter, Inter Tight and JetBrains Mono (Latin and Cyrillic, SIL OFL 1.1) |
| `android/app/src/main/kotlin/.../WeekCounterWidgetProvider.kt` | Android widget |
| `ios/WeekCounterWidget/` | iOS WidgetKit extension |

## Android widget

To add it, long-press the home screen, open **Widgets**, and choose **Orbity**. Settings also has an "Add widget" button if your launcher supports it.

The widget ticks every second when the app is allowed to use exact alarms. On Android 14+ that's off by default. Settings shows a **Precise widget countdown › Allow** row that opens the system permission screen. Without the permission, the widget shows "2d 3h" and refreshes about every 30 minutes.

The orb is drawn into a bitmap (`OrbRenderer.kt`), since a widget can't run custom drawing. It needs width beside the number: from 260dp wide (3 cells on most phones) the widget shows a large orb, from 200dp a smaller one, and below that none. The progress bar shows once the widget is tall enough for all the text. Both catch up on each refresh, about every 30 minutes.

## iOS widget

The `WeekCounterWidget` extension target is already in the Xcode project, with the App Group `group.io.github.sul1aaa.orbity` on both the app and the extension. To add it, long-press the home screen, tap **Edit › Add Widget**, and search for **Orbity**.

**Simulator:** works as is.

**Real device:** App Groups need a paid Apple Developer team (the project uses `9746P6DV47`).

1. Open `ios/Runner.xcworkspace`.
2. Under **Signing & Capabilities**, select the **Runner** target and then the **WeekCounterWidget** target. Let Xcode register the App Group for each.
3. If Xcode says the group ID is taken, change `group.io.github.sul1aaa.orbity` in these 4 places:
   - `lib/services/widget_sync.dart` (`HomeWidgetSync.appGroupId`)
   - `ios/WeekCounterWidget/WeekCounterWidget.swift` (`PayloadStore.groupId`)
   - `ios/Runner/Runner.entitlements`
   - `ios/WeekCounterWidget/WeekCounterWidget.entitlements`

   Change the bundle IDs (`io.github.sul1aaa.orbity…`) the same way if they're taken.

## App Store

- `store/app-store.md` has the listing text in English and Russian, plus the answers for App Privacy, App Review and export compliance.
- `PRIVACY.md` is the privacy policy that the listing links to.
- `store/screenshots/` has the iPhone screenshots: `6.3-inch` (1206 × 2622, the size App Store Connect asks for) and `6.9-inch` (1320 × 2868).
- `design/app-icon.png` is the 1024 px icon source.

### App Store screenshots

`test_driver/screenshots.dart` runs the app as a fresh user on a fixed clock: Thursday 15:00, then Friday 18:00 for the "Weekend!" screen. `test_driver/screenshots_test.dart` taps through it and saves simulator screenshots with the status bar set to match. Run it once per language on an iPhone 17 Pro Max simulator:

```sh
DEVICE=<simulator id>   # xcrun simctl list devices | grep "17 Pro Max"
for L in en ru; do
  SHOTS_DEVICE=$DEVICE SHOTS_DIR=build/shots/$L SHOTS_LOCALE=$L flutter drive \
    --driver=test_driver/screenshots_test.dart --target=test_driver/screenshots.dart \
    -d $DEVICE --dart-define=SHOT_LOCALE=$L
done
```

Then `store/frame/make.sh build/shots` adds the captions and frames and draws the widgets picture with the widget's own views. It writes `store/screenshots/`.

## Known limits

- Nager.Date has national holidays only. It has no regional holidays and no Russian transferred workdays; use the calendar overrides for those.
- The widget's text is written by the app. After changing the phone's language or time zone, open the app once to update the widget.
