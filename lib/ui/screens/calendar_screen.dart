import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/calendar_date.dart';
import '../../domain/day_classifier.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../models/app_settings.dart';
import '../../state/app_controller.dart';
import '../widgets/day_detail_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focused = widget.controller.clock();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeMode = RangeSelectionMode.toggledOff;

  AppController get _controller => widget.controller;

  static CalendarDate _date(DateTime day) =>
      CalendarDate(day.year, day.month, day.day);

  List<CalendarDate> get _selectedDates {
    final start = _rangeStart;
    if (start == null) return const [];
    final first = _date(start);
    final last = _rangeEnd == null ? first : _date(_rangeEnd!);
    return [
      for (var d = first; d <= last; d = d.addDays(1)) d,
    ];
  }

  void _clearRange() => setState(() {
    _rangeStart = null;
    _rangeEnd = null;
    _rangeMode = RangeSelectionMode.toggledOff;
  });

  Future<void> _applyToRange(DayOverride? value) async {
    final dates = _selectedDates;
    _clearRange();
    await _controller.setOverride(dates, value);
  }

  void _onDaySelected(DateTime day, DateTime focused) {
    if (_rangeMode == RangeSelectionMode.toggledOn) {
      // A long press while selecting turns range mode off again.
      _clearRange();
      return;
    }
    setState(() => _focused = focused);
    showDayDetailSheet(context, _controller, _date(day));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = _controller.clock();
    final firstDayIndex = MaterialLocalizations.of(context).firstDayOfWeekIndex;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final holidays = _controller.holidays.inMonth(
          _focused.year,
          _focused.month,
        );
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.navCalendar),
            actions: [
              IconButton(
                icon: const Icon(Icons.today),
                onPressed: () => setState(() => _focused = now),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              TableCalendar<void>(
                locale: l10n.localeName,
                firstDay: DateTime(now.year, 1, 1),
                lastDay: DateTime(now.year + 1, 12, 31),
                focusedDay: _focused,
                currentDay: now,
                // MaterialLocalizations counts from Sunday = 0.
                startingDayOfWeek:
                    StartingDayOfWeek.values[(firstDayIndex + 6) % 7],
                availableCalendarFormats: const {CalendarFormat.month: ''},
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                weekendDays: const [],
                rowHeight: 48,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  rangeHighlightColor: theme.colorScheme.primary.withValues(
                    alpha: 0.15,
                  ),
                  rangeStartDecoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  withinRangeTextStyle: TextStyle(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                rangeSelectionMode: _rangeMode,
                rangeStartDay: _rangeStart,
                rangeEndDay: _rangeEnd,
                onDaySelected: _onDaySelected,
                onRangeSelected: (start, end, focused) => setState(() {
                  _rangeStart = start;
                  _rangeEnd = end;
                  _focused = focused;
                  _rangeMode = RangeSelectionMode.toggledOn;
                }),
                onPageChanged: (focused) => setState(() => _focused = focused),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, _) => _DayCell(
                    day: day,
                    info: _controller.classify(_date(day)),
                  ),
                  todayBuilder: (context, day, _) => _DayCell(
                    day: day,
                    info: _controller.classify(_date(day)),
                    isToday: true,
                  ),
                ),
              ),
              if (_rangeMode == RangeSelectionMode.toggledOn &&
                  _rangeStart != null)
                _RangeBar(
                  count: _selectedDates.length,
                  onCancel: _clearRange,
                  onReset: () => _applyToRange(null),
                  onMarkOff: () =>
                      _applyToRange(const DayOverride(OverrideKind.dayOff)),
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _Legend(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  l10n.calendarHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
                child: Text(
                  l10n.holidaysThisMonth,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (holidays.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l10n.noHolidaysThisMonth,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              for (final holiday in holidays)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.errorContainer,
                    foregroundColor: theme.colorScheme.onErrorContainer,
                    child: Text('${holiday.date.day}'),
                  ),
                  title: Text(l10n.holidayName(holiday)),
                  subtitle: Text(l10n.date(holiday.date)),
                  onTap: () =>
                      showDayDetailSheet(context, _controller, holiday.date),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Colors shared by calendar cells and the legend.
({Color background, Color foreground})? _dayColors(
  ColorScheme scheme,
  DayInfo info,
) {
  if (info.isWork) return null;
  if (info.reasons.contains(OffReason.publicHoliday)) {
    return (
      background: scheme.errorContainer,
      foreground: scheme.onErrorContainer,
    );
  }
  if (info.reasons.contains(OffReason.custom)) {
    return (background: scheme.primary, foreground: scheme.onPrimary);
  }
  return (
    background: scheme.secondaryContainer,
    foreground: scheme.onSecondaryContainer,
  );
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.info, this.isToday = false});

  final DateTime day;
  final DayInfo info;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = _dayColors(scheme, info);
    final foreground = colors?.foreground ?? scheme.onSurface;
    final hasNote = info.override?.note?.isNotEmpty ?? false;
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors?.background,
        borderRadius: BorderRadius.circular(12),
        border: isToday
            ? Border.all(color: scheme.primary, width: 2)
            : info.isExtraWorkday
            ? Border.all(color: scheme.outline, width: 1.5)
            : null,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: foreground,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          if (hasNote)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    Widget item(String label, {Color? color, Color? border}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: border == null ? null : Border.all(color: border),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        item(l10n.legendWeekend, color: scheme.secondaryContainer),
        item(l10n.legendHoliday, color: scheme.errorContainer),
        item(l10n.legendDayOff, color: scheme.primary),
        item(l10n.legendWorkday, border: scheme.outline),
      ],
    );
  }
}

class _RangeBar extends StatelessWidget {
  const _RangeBar({
    required this.count,
    required this.onCancel,
    required this.onReset,
    required this.onMarkOff,
  });

  final int count;
  final VoidCallback onCancel;
  final VoidCallback onReset;
  final VoidCallback onMarkOff;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.daysSelected(count),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 4,
                children: [
                  TextButton(onPressed: onCancel, child: Text(l10n.cancel)),
                  TextButton(onPressed: onReset, child: Text(l10n.resetToAuto)),
                  FilledButton(
                    onPressed: onMarkOff,
                    child: Text(l10n.markDaysOff),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
