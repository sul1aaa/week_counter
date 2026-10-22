import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../models/work_schedule.dart';
import '../../state/app_controller.dart';
import '../kit/app_page.dart';
import '../kit/buttons.dart';
import '../kit/controls.dart';
import '../kit/group.dart';
import '../kit/pressable.dart';
import '../kit/sheet.dart';
import '../theme/tokens.dart';
import '../widgets/week_strip.dart';
import '../widgets/widget_sheet.dart';
import 'country_picker_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AppLifecycleListener _lifecycle;
  late Future<({bool exact, bool canPin})> _widgetStatus;

  AppController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _widgetStatus = _loadWidgetStatus();
    // The exact-alarm permission is granted in system settings, so check
    // again when the user comes back.
    _lifecycle = AppLifecycleListener(
      onResume: () => setState(() => _widgetStatus = _loadWidgetStatus()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<({bool exact, bool canPin})> _loadWidgetStatus() async => (
    exact: await _controller.widgetSync.canScheduleExact(),
    canPin: await _controller.widgetSync.canPinWidget(),
  );

  WorkSchedule get _schedule => _controller.settings.schedule;

  List<int> _orderedWeekdays(BuildContext context) {
    final first = firstWeekday(context);
    return [for (var i = 0; i < 7; i++) (first - 1 + i) % 7 + 1];
  }

  String _format(AppLocalizations l10n, ShiftTime t) =>
      l10n.time(DateTime(2000, 1, 1, t.hour, t.minute));

  String _weekdayLong(AppLocalizations l10n, int day) {
    // 1 January 2024 was a Monday.
    final name = DateFormat.EEEE(
      l10n.localeName,
    ).format(DateTime(2024, 1, day));
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  Future<void> _editStart(AppLocalizations l10n) async {
    final start = await showTimeSheet(
      context,
      l10n.shiftStarts,
      _schedule.defaultShift.start,
    );
    if (start == null) return;
    _controller.updateSchedule(
      _schedule.copyWith(
        defaultShift: Shift(start, _schedule.defaultShift.end),
      ),
    );
  }

  Future<void> _editEnd(AppLocalizations l10n) async {
    final end = await showTimeSheet(
      context,
      l10n.shiftEnds,
      _schedule.defaultShift.end,
    );
    if (end == null) return;
    _controller.updateSchedule(
      _schedule.copyWith(
        defaultShift: Shift(_schedule.defaultShift.start, end),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final settings = _controller.settings;
        final schedule = settings.schedule;
        final code = settings.countryCode;
        final weekdays = _orderedWeekdays(context);
        return AppPage(
          title: l10n.navSettings,
          subtitle: l10n.settingsSubtitle,
          children: [
            GroupHeader(l10n.sectionHolidays),
            Group(
              children: [
                GroupRow(
                  icon: code == null ? Icons.public_rounded : null,
                  leading: code == null
                      ? null
                      : SizedBox(
                          width: 28,
                          child: Text(
                            countryFlag(code),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                  title: l10n.country,
                  value: _controller.countryName(code) ?? l10n.noCountry,
                  onTap: () => CountryPickerScreen.open(context, _controller),
                ),
                if (code != null) _holidayStatusRow(l10n, t),
              ],
            ),
            GroupHeader(l10n.sectionWorkTime),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _DaysPicker(
                weekdays: weekdays,
                workdays: schedule.workdays,
                onToggle: (day) => _controller.updateSchedule(
                  schedule.copyWith(
                    workdays: schedule.workdays.contains(day)
                        ? ({...schedule.workdays}..remove(day))
                        : {...schedule.workdays, day},
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 16),
              child: Text(l10n.workdaysHint, style: t.footnote),
            ),
            Group(
              children: [
                if (!schedule.hasCustomShifts) ...[
                  GroupRow(
                    icon: Icons.login_rounded,
                    title: l10n.shiftStarts,
                    trailing: ValuePill(
                      text: _format(l10n, schedule.defaultShift.start),
                      semanticLabel: l10n.shiftStarts,
                      onTap: () => _editStart(l10n),
                    ),
                  ),
                  GroupRow(
                    icon: Icons.logout_rounded,
                    title: l10n.shiftEnds,
                    subtitle: schedule.defaultShift.isOvernight
                        ? l10n.endsNextDay
                        : null,
                    trailing: ValuePill(
                      text: _format(l10n, schedule.defaultShift.end),
                      semanticLabel: l10n.shiftEnds,
                      onTap: () => _editEnd(l10n),
                    ),
                  ),
                ],
                GroupRow(
                  icon: Icons.tune_rounded,
                  title: l10n.perDayHours,
                  trailing: AppToggle(
                    label: l10n.perDayHours,
                    value: schedule.hasCustomShifts,
                    onChanged: (on) => _controller.updateSchedule(
                      schedule.copyWith(
                        customShifts: on
                            ? {
                                for (final d in weekdays)
                                  d: schedule.defaultShift,
                              }
                            : {},
                      ),
                    ),
                  ),
                ),
                if (schedule.hasCustomShifts)
                  for (final day in weekdays)
                    if (schedule.workdays.contains(day))
                      _perDayRow(l10n, day, schedule.shiftFor(day)),
              ],
            ),
            GroupHeader(l10n.sectionWidget),
            _widgetSection(l10n),
            GroupHeader(l10n.sectionAbout),
            Group(
              children: [
                GroupRow(icon: Icons.info_rounded, title: l10n.dataSource),
                GroupRow(
                  icon: Icons.description_rounded,
                  title: MaterialLocalizations.of(
                    context,
                  ).viewLicensesButtonLabel,
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: l10n.appTitle,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _holidayStatusRow(AppLocalizations l10n, Tokens t) {
    final updated = _controller.holidays.lastFetched;
    return GroupRow(
      icon: Icons.event_available_rounded,
      title: updated == null
          ? l10n.holidaysNotLoadedYet
          : l10n.holidaysUpdated(l10n.dateTime(updated)),
      subtitle: _controller.missingYears.isEmpty ? null : l10n.loadFailed,
      trailing: _controller.loadingHolidays
          ? const SizedBox.square(
              dimension: 44,
              child: CupertinoActivityIndicator(),
            )
          : Pressable(
              onTap: () => _controller.refreshHolidays(force: true),
              scale: 0.9,
              semanticLabel: l10n.refresh,
              child: SizedBox.square(
                dimension: 44,
                child: Icon(Icons.refresh_rounded, color: t.ink2),
              ),
            ),
    );
  }

  Widget _perDayRow(AppLocalizations l10n, int day, Shift shift) {
    final name = _weekdayLong(l10n, day);
    return GroupRow(
      title: name,
      subtitle: shift.isOvernight ? l10n.endsNextDay : null,
      trailing: ValuePill(
        text: '${_format(l10n, shift.start)} – ${_format(l10n, shift.end)}',
        semanticLabel: name,
        onTap: () async {
          final updated = await showShiftSheet(context, name, shift);
          if (updated == null) return;
          _controller.updateSchedule(
            _schedule.copyWith(
              customShifts: {..._schedule.customShifts, day: updated},
            ),
          );
        },
      ),
    );
  }

  Widget _widgetSection(AppLocalizations l10n) {
    final android = defaultTargetPlatform == TargetPlatform.android;
    return FutureBuilder(
      future: _widgetStatus,
      builder: (context, snapshot) {
        final status = snapshot.data;
        return Group(
          children: [
            if (android && status != null && !status.exact)
              GroupRow(
                icon: Icons.timer_rounded,
                title: l10n.preciseWidget,
                subtitle: l10n.preciseWidgetHint,
                trailing: ValuePill(
                  text: l10n.allow,
                  selected: true,
                  onTap: _controller.widgetSync.openExactAlarmSettings,
                ),
              ),
            if (status?.canPin ?? false)
              GroupRow(
                icon: Icons.add_to_home_screen_rounded,
                title: l10n.addWidget,
                onTap: _controller.widgetSync.pinWidget,
              ),
            GroupRow(
              icon: Icons.widgets_rounded,
              title: l10n.widgetsTitle,
              subtitle: android ? l10n.widgetHowToAndroid : l10n.widgetHowToIos,
              onTap: () => showWidgetSheet(context, _controller),
            ),
          ],
        );
      },
    );
  }
}

/// Seven round day buttons; violet ones are workdays.
class _DaysPicker extends StatelessWidget {
  const _DaysPicker({
    required this.weekdays,
    required this.workdays,
    required this.onToggle,
  });

  final List<int> weekdays;
  final Set<int> workdays;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    return Row(
      children: [
        for (final (i, day) in weekdays.indexed) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              toggled: workdays.contains(day),
              label: l10n.weekdayShort(day),
              excludeSemantics: true,
              onTap: () => onToggle(day),
              child: Pressable(
                scale: 0.9,
                onTap: () => onToggle(day),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AnimatedContainer(
                    duration: Motion.fast,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: workdays.contains(day) ? t.violetSoft : t.surface,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        l10n.weekdayShort(day),
                        style: TextStyle(
                          fontFamily: Fonts.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: workdays.contains(day) ? t.violetInk : t.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A time wheel in a sheet; null when dismissed.
Future<ShiftTime?> showTimeSheet(
  BuildContext context,
  String title,
  ShiftTime initial,
) => showAppSheet<ShiftTime>(
  context,
  title: title,
  builder: (context) => _TimeSheet(initial: [initial]),
);

/// Start and end wheels side by side; null when dismissed.
Future<Shift?> showShiftSheet(
  BuildContext context,
  String title,
  Shift shift,
) => showAppSheet<List<ShiftTime>>(
  context,
  title: title,
  builder: (context) => _TimeSheet(initial: [shift.start, shift.end]),
).then((times) => times == null ? null : Shift(times[0], times[1]));

class _TimeSheet extends StatefulWidget {
  const _TimeSheet({required this.initial});

  final List<ShiftTime> initial;

  @override
  State<_TimeSheet> createState() => _TimeSheetState();
}

class _TimeSheetState extends State<_TimeSheet> {
  late final List<ShiftTime> _times = [...widget.initial];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final labels = [l10n.shiftStartsAt, l10n.shiftEndsAt];
    final pair = _times.length == 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoTheme(
          data: CupertinoThemeData(
            brightness: t.brightness,
            textTheme: CupertinoTextThemeData(
              dateTimePickerTextStyle: TextStyle(
                fontFamily: Fonts.text,
                fontSize: 22,
                color: t.ink,
              ),
            ),
          ),
          child: Row(
            children: [
              for (final (i, time) in _times.indexed)
                Expanded(
                  child: Column(
                    children: [
                      if (pair)
                        Text(
                          labels[i],
                          style: t.footnote.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      SizedBox(
                        height: 200,
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.time,
                          use24hFormat: true,
                          initialDateTime: DateTime(
                            2000,
                            1,
                            1,
                            time.hour,
                            time.minute,
                          ),
                          onDateTimeChanged: (value) =>
                              _times[i] = ShiftTime(value.hour, value.minute),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: l10n.done,
          onTap: () =>
              Navigator.of(context).pop(pair ? [..._times] : _times.first),
        ),
      ],
    );
  }
}
