import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../models/work_schedule.dart';
import '../../state/app_controller.dart';
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

  Future<ShiftTime?> _pickTime(ShiftTime initial, String help) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
      helpText: help,
    );
    return picked == null ? null : ShiftTime(picked.hour, picked.minute);
  }

  Future<void> _editShift(
    Shift shift,
    String label,
    ValueChanged<Shift> onChanged,
  ) async {
    final l10n = AppLocalizations.of(context);
    final start = await _pickTime(shift.start, '$label · ${l10n.shiftStarts}');
    if (start == null || !mounted) return;
    final end = await _pickTime(shift.end, '$label · ${l10n.shiftEnds}');
    if (end == null) return;
    onChanged(Shift(start, end));
  }

  List<int> _orderedWeekdays(BuildContext context) {
    // MaterialLocalizations counts from Sunday = 0; DateTime from Monday = 1.
    final index = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final first = index == 0 ? DateTime.sunday : index;
    return [for (var i = 0; i < 7; i++) (first - 1 + i) % 7 + 1];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final settings = _controller.settings;
        final schedule = settings.schedule;
        final code = settings.countryCode;
        final weekdays = _orderedWeekdays(context);
        return Scaffold(
          appBar: AppBar(title: Text(l10n.navSettings)),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _Header(l10n.sectionHolidays),
              ListTile(
                leading: code == null
                    ? const Icon(Icons.public)
                    : Text(
                        countryFlag(code),
                        style: const TextStyle(fontSize: 24),
                      ),
                title: Text(l10n.country),
                subtitle: Text(
                  _controller.countryName(code) ?? l10n.noCountry,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => CountryPickerScreen.open(context, _controller),
              ),
              if (code != null) _holidayStatusTile(l10n),
              _Header(l10n.sectionWorkTime),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  l10n.workdays,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final day in weekdays)
                      FilterChip(
                        label: Text(l10n.weekdayShort(day)),
                        selected: schedule.workdays.contains(day),
                        onSelected: (on) => _controller.updateSchedule(
                          schedule.copyWith(
                            workdays: on
                                ? {...schedule.workdays, day}
                                : ({...schedule.workdays}..remove(day)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (!schedule.hasCustomShifts) ...[
                ListTile(
                  leading: const Icon(Icons.login),
                  title: Text(l10n.shiftStarts),
                  trailing: Text(_format(l10n, schedule.defaultShift.start)),
                  onTap: () async {
                    final t = await _pickTime(
                      schedule.defaultShift.start,
                      l10n.shiftStarts,
                    );
                    if (t == null) return;
                    _controller.updateSchedule(
                      _schedule.copyWith(
                        defaultShift: Shift(t, _schedule.defaultShift.end),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(l10n.shiftEnds),
                  subtitle: schedule.defaultShift.isOvernight
                      ? Text(l10n.endsNextDay)
                      : null,
                  trailing: Text(_format(l10n, schedule.defaultShift.end)),
                  onTap: () async {
                    final t = await _pickTime(
                      schedule.defaultShift.end,
                      l10n.shiftEnds,
                    );
                    if (t == null) return;
                    _controller.updateSchedule(
                      _schedule.copyWith(
                        defaultShift: Shift(_schedule.defaultShift.start, t),
                      ),
                    );
                  },
                ),
              ],
              SwitchListTile(
                secondary: const Icon(Icons.tune),
                title: Text(l10n.perDayHours),
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
              if (schedule.hasCustomShifts)
                for (final day in weekdays)
                  if (schedule.workdays.contains(day))
                    _perDayTile(l10n, day, schedule.shiftFor(day)),
              _Header(l10n.sectionWidget),
              _widgetSection(l10n),
              _Header(l10n.sectionAbout),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.dataSource),
              ),
            ],
          ),
        );
      },
    );
  }

  String _format(AppLocalizations l10n, ShiftTime t) =>
      l10n.time(DateTime(2000, 1, 1, t.hour, t.minute));

  Widget _holidayStatusTile(AppLocalizations l10n) {
    final updated = _controller.holidays.lastFetched;
    return ListTile(
      leading: const Icon(Icons.event_available),
      title: Text(
        updated == null
            ? l10n.holidaysNotLoadedYet
            : l10n.holidaysUpdated(l10n.dateTime(updated)),
      ),
      subtitle: _controller.missingYears.isEmpty ? null : Text(l10n.loadFailed),
      trailing: _controller.loadingHolidays
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              tooltip: l10n.refresh,
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.refreshHolidays(force: true),
            ),
    );
  }

  Widget _perDayTile(AppLocalizations l10n, int day, Shift shift) {
    final name = l10n.weekdayShort(day);
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
      title: Text(name),
      subtitle: shift.isOvernight ? Text(l10n.endsNextDay) : null,
      trailing: Text(
        '${_format(l10n, shift.start)} – ${_format(l10n, shift.end)}',
      ),
      onTap: () => _editShift(
        shift,
        name,
        (updated) => _controller.updateSchedule(
          _schedule.copyWith(
            customShifts: {..._schedule.customShifts, day: updated},
          ),
        ),
      ),
    );
  }

  Widget _widgetSection(AppLocalizations l10n) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ListTile(
        leading: const Icon(Icons.widgets_outlined),
        title: Text(l10n.widgetHowToIos),
      );
    }
    return FutureBuilder(
      future: _widgetStatus,
      builder: (context, snapshot) {
        final status = snapshot.data;
        return Column(
          children: [
            if (status != null && !status.exact)
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: Text(l10n.preciseWidget),
                subtitle: Text(l10n.preciseWidgetHint),
                isThreeLine: true,
                trailing: FilledButton.tonal(
                  onPressed: _controller.widgetSync.openExactAlarmSettings,
                  child: Text(l10n.allow),
                ),
              ),
            if (status?.canPin ?? false)
              ListTile(
                leading: const Icon(Icons.add_to_home_screen),
                title: Text(l10n.addWidget),
                onTap: _controller.widgetSync.pinWidget,
              ),
            ListTile(
              leading: const Icon(Icons.widgets_outlined),
              title: Text(l10n.widgetHowToAndroid),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
