import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/calendar_date.dart';
import '../../domain/countdown_engine.dart';
import '../../domain/day_classifier.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../models/app_settings.dart';
import '../../state/app_controller.dart';
import '../kit/app_page.dart';
import '../kit/buttons.dart';
import '../kit/glass.dart';
import '../kit/group.dart';
import '../kit/pressable.dart';
import '../theme/tokens.dart';
import '../widgets/day_detail_sheet.dart';
import '../widgets/week_strip.dart';
import 'country_picker_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _scroll = ScrollController();
  CalendarDate? _rangeStart;
  CalendarDate? _rangeEnd;

  AppController get _controller => widget.controller;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<CalendarDate> get _selectedDates {
    final start = _rangeStart;
    if (start == null) return const [];
    final end = _rangeEnd ?? start;
    final (first, last) = start <= end ? (start, end) : (end, start);
    return [for (var d = first; d <= last; d = d.addDays(1)) d];
  }

  void _clearRange() => setState(() {
    _rangeStart = null;
    _rangeEnd = null;
  });

  Future<void> _applyToRange(DayOverride? value) async {
    final dates = _selectedDates;
    _clearRange();
    await _controller.setOverride(dates, value);
  }

  void _onTap(CalendarDate date) {
    if (_rangeStart != null) {
      setState(() => _rangeEnd = date);
      return;
    }
    showDayDetailSheet(context, _controller, date);
  }

  void _onLongPress(CalendarDate date) => setState(() {
    _rangeStart = date;
    _rangeEnd = null;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final now = _controller.clock();
        final today = CalendarDate.fromDateTime(now);
        final first = firstWeekday(context);
        final selected = _selectedDates.toSet();
        final holidays = _controller.upcomingHolidays();
        final code = _controller.settings.countryCode;

        return Stack(
          children: [
            AppPage(
              title: l10n.navCalendar,
              controller: _scroll,
              onRefresh: () => _controller.refreshHolidays(force: true),
              bottomPadding: bottom + (selected.isEmpty ? 104 : 260),
              children: [
                const SizedBox(height: 16),
                _Summary(controller: _controller, now: now),
                const _Legend(),
                const SizedBox(height: 12),
                Group(
                  children: [
                    GroupRow(
                      title: l10n.holidaysShort,
                      value: code == null
                          ? l10n.noCountry
                          : l10n.countryLabel(
                              code,
                              _controller.countryName(code),
                            ),
                      onTap: () =>
                          CountryPickerScreen.open(context, _controller),
                    ),
                  ],
                ),
                for (var i = 0; i < 6; i++)
                  _MonthGrid(
                    month: DateTime(today.year, today.month + i),
                    today: today,
                    firstWeekday: first,
                    classify: _controller.classify,
                    selected: selected,
                    onTap: _onTap,
                    onLongPress: _onLongPress,
                  ),
                GroupHeader(l10n.upcomingHolidays),
                Group(
                  children: [
                    if (code == null || holidays.isEmpty)
                      GroupRow(
                        title: code == null
                            ? l10n.noUpcomingHolidays
                            : l10n.noneComing,
                        onTap: code == null
                            ? () =>
                                  CountryPickerScreen.open(context, _controller)
                            : null,
                      ),
                    for (final holiday in holidays)
                      GroupRow(
                        title: l10n.holidayName(holiday),
                        value: l10n.dayMonth(holiday.date),
                        monoValue: true,
                        chevron: false,
                        onTap: () => showDayDetailSheet(
                          context,
                          _controller,
                          holiday.date,
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 12, 32, 0),
                  child: Text(l10n.calendarHint, style: t.footnote),
                ),
              ],
            ),
            if (selected.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: (bottom > 0 ? bottom - 13 : 12) + 62 + 12,
                child: _RangeBar(
                  count: selected.length,
                  onCancel: _clearRange,
                  onReset: () => _applyToRange(null),
                  onMarkOff: () =>
                      _applyToRange(const DayOverride(OverrideKind.dayOff)),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Two cards: time to the next change, and days off this month.
class _Summary extends StatelessWidget {
  const _Summary({required this.controller, required this.now});

  final AppController controller;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = CalendarDate.fromDateTime(now);
    final (label, target) = switch (controller.snapshot.state) {
      CountingDown(:final target, :final block) => (
        l10n.untilTitle(block.kind),
        target,
      ),
      OffNow(:final backToWork) => (l10n.backToWorkIn, backToWork),
      _ => (l10n.appTitle, null),
    };
    var daysOff = 0;
    for (
      var d = CalendarDate(today.year, today.month, 1);
      d.month == today.month;
      d = d.addDays(1)
    ) {
      if (controller.classify(d).isOff) daysOff++;
    }
    final nextHoliday = controller.upcomingHolidays(limit: 1).firstOrNull;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _SummaryCard(
                label: label,
                value: target == null
                    ? '—'
                    : l10n.compactDuration(target.difference(now)),
                detail: target == null ? null : l10n.when(target, now),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                label: l10n.daysOffIn(l10n.monthIn('${today.month}')),
                value: '$daysOff',
                detail: nextHoliday == null
                    ? l10n.noHolidaysShort
                    : l10n.holidayOn(l10n.dayMonth(nextHoliday.date)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, this.detail});

  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: t.footnote),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontFamily: Fonts.display,
                  fontSize: 26,
                  height: 30 / 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.04,
                  fontFeatures: Fonts.tabular,
                  color: t.ink,
                ),
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 4),
              Text(detail!, style: t.footnote),
            ],
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    Widget item(String label, Widget swatch) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: 6),
        Text(label, style: t.footnote),
      ],
    );
    Widget square({Color? color, Widget? child, Border? border}) => Container(
      width: 12,
      height: 12,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: border,
      ),
      child: child,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          item(
            l10n.legendWeekend,
            square(
              color: t.limeSoft,
              border: Border.all(
                color: t.limeInk.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
          ),
          item(
            l10n.legendHoliday,
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: t.ink, shape: BoxShape.circle),
            ),
          ),
          item(
            l10n.legendDayOff,
            square(
              color: t.surface,
              child: CustomPaint(painter: StripesPainter(t.surface3, gap: 3)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.today,
    required this.firstWeekday,
    required this.classify,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final DateTime month;
  final CalendarDate today;
  final int firstWeekday;
  final DayInfo Function(CalendarDate) classify;
  final Set<CalendarDate> selected;
  final ValueChanged<CalendarDate> onTap;
  final ValueChanged<CalendarDate> onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final first = CalendarDate(month.year, month.month, 1);
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final lead = (first.weekday - firstWeekday + 7) % 7;
    final name = DateFormat.LLLL(l10n.localeName).format(month);
    final title =
        '${name[0].toUpperCase()}${name.substring(1)}'
        '${month.year != today.year ? ' ${month.year}' : ''}';

    final cells = <Widget>[
      for (var i = 0; i < lead; i++) const SizedBox(),
      for (var d = 1; d <= days; d++)
        _CalendarDay(
          date: CalendarDate(month.year, month.month, d),
          today: today,
          classify: classify,
          selected: selected,
          rowStart: (lead + d - 1) % 7 == 0,
          rowEnd: (lead + d - 1) % 7 == 6,
          monthEnd: d == days,
          onTap: onTap,
          onLongPress: onLongPress,
        ),
    ];
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              ExcludeSemantics(
                child: Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            l10n.weekdayCaps((firstWeekday - 1 + i) % 7 + 1),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: Fonts.text,
                              fontSize: 11,
                              height: 14 / 11,
                              fontWeight: FontWeight.w600,
                              color: t.ink2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              for (var row = 0; row < cells.length ~/ 7; row++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      for (final cell in cells.skip(row * 7).take(7))
                        Expanded(child: SizedBox(height: 44, child: cell)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.today,
    required this.classify,
    required this.selected,
    required this.rowStart,
    required this.rowEnd,
    required this.monthEnd,
    required this.onTap,
    required this.onLongPress,
  });

  final CalendarDate date;
  final CalendarDate today;
  final DayInfo Function(CalendarDate) classify;
  final Set<CalendarDate> selected;
  final bool rowStart;
  final bool rowEnd;
  final bool monthEnd;
  final ValueChanged<CalendarDate> onTap;
  final ValueChanged<CalendarDate> onLongPress;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = AppLocalizations.of(context);
    final info = classify(date);
    final ownOff = info.isExtraOff && info.reasons.contains(OffReason.custom);
    final off = info.isOff;
    final past = date < today;
    final isToday = date == today;
    final holiday = info.holidays.isNotEmpty;
    final inRange = selected.contains(date);

    // Bars run across consecutive days; round where a run starts or ends.
    bool sameKind(CalendarDate other) {
      final o = classify(other);
      final otherOwn = o.isExtraOff && o.reasons.contains(OffReason.custom);
      return o.isOff && otherOwn == ownOff;
    }

    final startsRun = rowStart || date.day == 1 || !sameKind(date.addDays(-1));
    final endsRun = rowEnd || monthEnd || !sameKind(date.addDays(1));
    final rangeStarts =
        rowStart || date.day == 1 || !selected.contains(date.addDays(-1));
    final rangeEnds = rowEnd || monthEnd || !selected.contains(date.addDays(1));
    BorderRadius bar(bool starts, bool ends) => BorderRadius.horizontal(
      left: starts ? const Radius.circular(18) : Radius.zero,
      right: ends ? const Radius.circular(18) : Radius.zero,
    );
    EdgeInsets inset(bool starts, bool ends) =>
        EdgeInsets.fromLTRB(starts ? 4 : 0, 4, ends ? 4 : 0, 4);

    Color number = past ? t.ink2 : t.ink;
    if (off && !ownOff) number = past ? t.ink2 : t.limeInk;
    if (ownOff) number = t.ink2;
    final rangeEdge = inRange && (rangeStarts || rangeEnds);
    if (isToday) number = t.onInverse;
    if (rangeEdge) number = Colors.white;

    final status = info.isOff
        ? [
            if (holiday) info.holidays.map(l10n.holidayName).join(', '),
            if (ownOff && info.override?.note != null) info.override!.note!,
            if (!holiday && !(ownOff && info.override?.note != null))
              l10n.statusDayOff,
          ].join(', ')
        : info.isExtraWorkday
        ? l10n.statusExtraWorkday
        : l10n.statusWorkday;

    return Semantics(
      button: true,
      selected: inRange,
      label: '${l10n.longDate(date)}, $status',
      excludeSemantics: true,
      onTap: () => onTap(date),
      onLongPress: () => onLongPress(date),
      child: Pressable(
        scale: 0.9,
        onTap: () => onTap(date),
        onLongPress: () => onLongPress(date),
        child: Stack(
          children: [
            if (off)
              Positioned.fill(
                child: Padding(
                  padding: inset(startsRun, endsRun),
                  child: Opacity(
                    opacity: past ? 0.6 : 1,
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: ownOff ? null : t.limeSoft,
                        borderRadius: bar(startsRun, endsRun),
                      ),
                      child: ownOff
                          ? CustomPaint(
                              painter: StripesPainter(t.surface2, gap: 5),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            if (inRange)
              Positioned.fill(
                child: Padding(
                  padding: inset(rangeStarts, rangeEnds),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: t.violetSoft.withValues(alpha: 0.85),
                      borderRadius: bar(rangeStarts, rangeEnds),
                    ),
                  ),
                ),
              ),
            Center(
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rangeEdge
                      ? Tokens.violet
                      : isToday
                      ? t.inverse
                      : null,
                  border: info.isExtraWorkday && !isToday && !rangeEdge
                      ? Border.all(color: t.ink2, width: 1.5)
                      : null,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontFamily: Fonts.display,
                        fontSize: 16,
                        height: 1,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.32,
                        fontFeatures: Fonts.tabular,
                        color: number,
                      ),
                    ),
                    if (holiday)
                      Positioned(
                        top: -9,
                        right: -9,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isToday ? t.onInverse : t.ink,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    if (info.override?.note?.isNotEmpty ?? false)
                      Positioned(
                        bottom: -9,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: number,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
    final t = context.tokens;
    return Glass(
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(l10n.daysSelected(count), style: t.navTitle),
            ),
            const SizedBox(height: 12),
            AppButton(label: l10n.markDaysOff, onTap: onMarkOff),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: l10n.cancel,
                    kind: ButtonKind.ghost,
                    onTap: onCancel,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: l10n.resetToAuto,
                    kind: ButtonKind.secondary,
                    onTap: onReset,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
