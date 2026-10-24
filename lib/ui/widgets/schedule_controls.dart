import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../models/work_schedule.dart';
import '../../state/app_controller.dart';
import '../kit/buttons.dart';
import '../kit/group.dart';
import '../kit/pressable.dart';
import '../kit/sheet.dart';
import '../theme/tokens.dart';
import 'week_strip.dart';

/// The days of the week in the locale's order, Monday = 1.
List<int> orderedWeekdays(BuildContext context) {
  final first = firstWeekday(context);
  return [for (var i = 0; i < 7; i++) (first - 1 + i) % 7 + 1];
}

/// [workdays] in the order of [weekdays], starting on the day a run of
/// workdays begins: Sun–Thu stays Sun–Thu in a week that starts on Monday.
List<int> workWeek(Set<int> workdays, List<int> weekdays) {
  final days = [
    for (final day in weekdays)
      if (workdays.contains(day)) day,
  ];
  // (d + 5) % 7 + 1 is the day before d: Sunday for Monday.
  final first = days.indexWhere((d) => !workdays.contains((d + 5) % 7 + 1));
  return first <= 0 ? days : [...days.skip(first), ...days.take(first)];
}

String capitalized(String text) =>
    text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';

/// "Friday", "пятница" for [weekday].
String weekdayLong(AppLocalizations l10n, int weekday) =>
    // 1 January 2024 was a Monday.
    DateFormat.EEEE(l10n.localeName).format(DateTime(2024, 1, weekday));

/// Seven round day buttons. Workdays are violet; the first and last day of
/// each run of workdays are filled black, like the ends of a range.
class DaysPicker extends StatelessWidget {
  const DaysPicker({
    super.key,
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
    bool works(int i) => workdays.contains(weekdays[i % 7]);
    // Runs wrap around the week, so Sun–Thu has its ends on Sunday and
    // Thursday. Seven workdays have no ends; the row's ends stand in.
    bool runEnd(int i) => workdays.length == 7
        ? i == 0 || i == 6
        : !works(i + 6) || !works(i + 1);
    return Row(
      children: [
        for (final (i, day) in weekdays.indexed) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              toggled: works(i),
              label: weekdayLong(l10n, day),
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
                      color: !works(i)
                          ? t.surface
                          : runEnd(i)
                          ? t.inverse
                          : t.violetSoft,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        capitalized(l10n.weekdayShort(day)),
                        style: TextStyle(
                          fontFamily: Fonts.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: !works(i)
                              ? t.ink
                              : runEnd(i)
                              ? t.onInverse
                              : t.violetInk,
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

/// "Week starts · Monday 09:00" and "Week ends · Friday 18:00". The times
/// apply to every workday.
List<Widget> weekTimeRows(
  BuildContext context,
  AppController controller, {
  Color? cardColor,
}) {
  final l10n = AppLocalizations.of(context);
  final schedule = controller.settings.schedule;
  final days = workWeek(schedule.workdays, orderedWeekdays(context));
  String format(ShiftTime t) =>
      l10n.time(DateTime(2000, 1, 1, t.hour, t.minute));
  final shift = schedule.defaultShift;
  return [
    GroupRow(
      title: l10n.weekStarts,
      subtitle: days.isEmpty ? null : weekdayLong(l10n, days.first),
      trailing: ValuePill(
        text: format(shift.start),
        semanticLabel: l10n.weekStarts,
        onTap: () async {
          final start = await showTimeSheet(
            context,
            l10n.weekStarts,
            shift.start,
          );
          if (start == null) return;
          final current = controller.settings.schedule;
          controller.updateSchedule(
            current.copyWith(
              defaultShift: Shift(start, current.defaultShift.end),
            ),
          );
        },
      ),
    ),
    GroupRow(
      title: l10n.weekEnds,
      subtitle: days.isEmpty
          ? null
          : shift.isOvernight
          ? l10n.atNight(weekdayLong(l10n, days.last % 7 + 1))
          : weekdayLong(l10n, days.last),
      trailing: ValuePill(
        text: format(shift.end),
        semanticLabel: l10n.weekEnds,
        onTap: () async {
          final end = await showTimeSheet(context, l10n.weekEnds, shift.end);
          if (end == null) return;
          final current = controller.settings.schedule;
          controller.updateSchedule(
            current.copyWith(
              defaultShift: Shift(current.defaultShift.start, end),
            ),
          );
        },
      ),
    ),
  ];
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
