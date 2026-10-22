import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../models/work_schedule.dart';
import '../../state/app_controller.dart';
import '../kit/app_page.dart';
import '../kit/buttons.dart';
import '../kit/controls.dart';
import '../kit/glass.dart';
import '../kit/group.dart';
import '../kit/pressable.dart';
import '../theme/tokens.dart';
import '../widgets/schedule_controls.dart';
import '../widgets/widget_sheet.dart';
import 'country_picker_screen.dart';
import 'vacation_screen.dart';

/// Workdays and hours, holidays, vacation and the widget.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, required this.controller});

  final AppController controller;

  static Future<void> open(BuildContext context, AppController controller) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ScheduleScreen(controller: controller),
        ),
      );

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
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

  String _format(AppLocalizations l10n, ShiftTime t) =>
      l10n.time(DateTime(2000, 1, 1, t.hour, t.minute));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bg,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final settings = _controller.settings;
          final schedule = settings.schedule;
          final code = settings.countryCode;
          final weekdays = orderedWeekdays(context);
          final vacation = _controller.vacation;
          return AppPage(
            title: l10n.scheduleTitle,
            subtitle: l10n.settingsSubtitle,
            bottomPadding: MediaQuery.paddingOf(context).bottom + 24,
            leading: GlassButton(
              icon: Icons.arrow_back_ios_new_rounded,
              label: l10n.back,
              onTap: () => Navigator.of(context).pop(),
            ),
            children: [
              GroupHeader(l10n.weekHeader),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: DaysPicker(
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(l10n.workdaysHint, style: t.footnote),
              ),
              Group(
                children: [
                  if (!schedule.hasCustomShifts)
                    ...weekTimeRows(context, _controller),
                  GroupRow(
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
              GroupHeader(l10n.navCalendar),
              Group(
                children: [
                  GroupRow(
                    icon: Icons.celebration_rounded,
                    title: l10n.holidaysShort,
                    value: code == null
                        ? l10n.noCountry
                        : l10n.countryLabel(
                            code,
                            _controller.countryName(code),
                          ),
                    onTap: () => CountryPickerScreen.open(context, _controller),
                  ),
                  GroupRow(
                    icon: Icons.beach_access_rounded,
                    title: l10n.vacationTitle,
                    value: vacation == null
                        ? l10n.vacationNone
                        : '${l10n.shortDate(vacation.first)}–'
                              '${l10n.shortDate(vacation.last)}',
                    onTap: () => VacationScreen.open(context, _controller),
                  ),
                ],
              ),
              GroupHeader(l10n.sectionExtras),
              _extrasSection(l10n),
              GroupHeader(l10n.sectionAbout),
              Group(
                children: [
                  _holidayDataRow(l10n, t),
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
      ),
    );
  }

  Widget _holidayDataRow(AppLocalizations l10n, Tokens t) {
    final updated = _controller.holidays.lastFetched;
    final subtitle = _controller.missingYears.isNotEmpty
        ? l10n.loadFailed
        : updated == null
        ? (_controller.settings.countryCode == null
              ? null
              : l10n.holidaysNotLoadedYet)
        : l10n.holidaysUpdated(l10n.dateTime(updated));
    return GroupRow(
      icon: Icons.info_rounded,
      title: l10n.dataSource,
      subtitle: subtitle,
      trailing: _controller.settings.countryCode == null
          ? null
          : _controller.loadingHolidays
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
    final name = capitalized(weekdayLong(l10n, day));
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

  Widget _extrasSection(AppLocalizations l10n) {
    final android = defaultTargetPlatform == TargetPlatform.android;
    return FutureBuilder(
      future: _widgetStatus,
      builder: (context, snapshot) {
        final status = snapshot.data;
        return Group(
          children: [
            GroupRow(
              icon: Icons.celebration_rounded,
              title: l10n.confetti,
              subtitle: l10n.confettiHint,
              trailing: AppToggle(
                label: l10n.confetti,
                value: _controller.prefs.confetti,
                onChanged: _controller.setConfetti,
              ),
            ),
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
              onTap: () => showWidgetSheet(context, _controller),
            ),
          ],
        );
      },
    );
  }
}
