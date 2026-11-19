import 'package:flutter/material.dart';

import '../../core/calendar_date.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../models/work_schedule.dart';
import '../../state/app_controller.dart';
import '../kit/buttons.dart';
import '../kit/controls.dart';
import '../kit/group.dart';
import '../kit/sheet.dart';
import '../theme/tokens.dart';
import 'schedule_controls.dart';

/// "Workday 2", "Night shift", "Day off 1": day [index] of [cycle].
String cycleDayLabel(
  AppLocalizations l10n,
  List<RotationDay> cycle,
  int index,
) {
  final kind = cycle[index];
  final n = cycle.take(index + 1).where((d) => d == kind).length;
  final total = cycle.where((d) => d == kind).length;
  return switch (kind) {
    RotationDay.night => l10n.rotationNightShift,
    RotationDay.day when cycle.contains(RotationDay.night) =>
      l10n.rotationDayShift,
    RotationDay.day when total == 1 => l10n.rotationShift,
    RotationDay.day => l10n.rotationWorkday(n),
    RotationDay.off => l10n.rotationDayOff(n),
  };
}

/// Pattern, today's place in it, the hours and holidays of a [rotation].
List<Widget> rotationRows(
  BuildContext context,
  AppController controller,
  ShiftRotation rotation,
) {
  final l10n = AppLocalizations.of(context);
  final today = CalendarDate.fromDateTime(controller.clock());
  String format(ShiftTime t) =>
      l10n.time(DateTime(2000, 1, 1, t.hour, t.minute));

  void save(ShiftRotation Function(ShiftRotation current) change) {
    final schedule = controller.settings.schedule;
    final current = schedule.rotation;
    if (current == null) return;
    controller.updateSchedule(
      schedule.copyWith(rotation: () => change(current)),
    );
  }

  Widget shiftRow(String title, Shift shift, bool night) => GroupRow(
    title: title,
    subtitle: shift.start == shift.end
        ? l10n.rotationRoundTheClock
        : shift.isOvernight
        ? l10n.endsNextDay
        : null,
    trailing: ValuePill(
      text: '${format(shift.start)} – ${format(shift.end)}',
      semanticLabel: title,
      onTap: () async {
        final updated = await showShiftSheet(context, title, shift);
        if (updated == null) return;
        save(
          (r) => night
              ? r.copyWith(nightShift: updated)
              : r.copyWith(dayShift: updated),
        );
      },
    ),
  );

  final preset = rotation.preset;
  final index = rotation.indexOn(today);
  return [
    GroupRow(
      key: const ValueKey('rotation.pattern'),
      title: l10n.rotationPattern,
      value: l10n.rotationName(preset?.name ?? 'other'),
      onTap: () async {
        final picked = await _showChoiceSheet(
          context,
          title: l10n.rotationPattern,
          selected: preset?.index,
          options: [
            for (final p in RotationPreset.values)
              (l10n.rotationName(p.name), l10n.rotationAbout(p.name)),
          ],
        );
        if (picked == null) return;
        save((r) => r.withPreset(RotationPreset.values[picked], today));
      },
    ),
    GroupRow(
      key: const ValueKey('rotation.today'),
      title: l10n.rotationToday,
      value: cycleDayLabel(l10n, rotation.cycle, index),
      onTap: () async {
        final picked = await _showChoiceSheet(
          context,
          title: l10n.rotationToday,
          selected: index,
          options: [
            for (var i = 0; i < rotation.cycle.length; i++)
              (cycleDayLabel(l10n, rotation.cycle, i), null),
          ],
        );
        if (picked == null) return;
        save((r) => r.copyWith(start: today.addDays(-picked)));
      },
    ),
    if (rotation.hasNight) ...[
      shiftRow(l10n.rotationDayShift, rotation.dayShift, false),
      shiftRow(l10n.rotationNightShift, rotation.nightShift, true),
    ] else
      shiftRow(l10n.rotationShift, rotation.dayShift, false),
    GroupRow(
      title: l10n.rotationHolidaysOff,
      subtitle: l10n.rotationHolidaysOffHint,
      trailing: AppToggle(
        label: l10n.rotationHolidaysOff,
        value: rotation.holidaysOff,
        onChanged: (on) => save((r) => r.copyWith(holidaysOff: on)),
      ),
    ),
  ];
}

/// A list with a check mark on [selected]; the tapped index, or null when
/// dismissed.
Future<int?> _showChoiceSheet(
  BuildContext context, {
  required String title,
  required int? selected,
  required List<(String, String?)> options,
}) => showAppSheet<int>(
  context,
  title: title,
  builder: (context) => Group(
    margin: EdgeInsets.zero,
    color: context.tokens.sheetCard,
    children: [
      for (final (i, (label, about)) in options.indexed)
        GroupRow(
          key: ValueKey('choice.$i'),
          title: label,
          subtitle: about,
          selected: i == selected,
          chevron: false,
          onTap: () => Navigator.of(context).pop(i),
        ),
    ],
  ),
);

/// The next two weeks of [rotation], from [today]: day shifts violet, night
/// shifts black, days off plain.
class RotationPreview extends StatelessWidget {
  const RotationPreview({
    super.key,
    required this.rotation,
    required this.today,
  });

  final ShiftRotation rotation;
  final CalendarDate today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    Widget cell(CalendarDate date) {
      final kind = rotation.dayOn(date);
      final (background, number, status) = switch (kind) {
        RotationDay.day => (t.violetSoft, t.violetInk, l10n.statusWorkday),
        RotationDay.night => (t.inverse, t.onInverse, l10n.rotationNightShift),
        RotationDay.off => (t.surface, t.ink2, l10n.statusDayOff),
      };
      final isToday = date == today;
      return Semantics(
        label: '${l10n.longDate(date)}, $status',
        excludeSemantics: true,
        child: Column(
          children: [
            Text(
              capitalized(l10n.weekdayShort(date.weekday)),
              style: t.footnote.copyWith(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isToday ? t.ink : t.ink3,
              ),
            ),
            const SizedBox(height: 4),
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: background,
                  border: isToday ? Border.all(color: t.ink, width: 2) : null,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontFamily: Fonts.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: number,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var week = 0; week < 2; week++) ...[
          if (week > 0) const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(child: cell(today.addDays(week * 7 + i))),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
