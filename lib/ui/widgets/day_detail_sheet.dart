import 'package:flutter/material.dart';

import '../../core/calendar_date.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../models/app_settings.dart';
import '../../state/app_controller.dart';

Future<void> showDayDetailSheet(
  BuildContext context,
  AppController controller,
  CalendarDate date,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _DayDetailSheet(controller: controller, date: date),
);

enum _Choice { auto, dayOff, workday }

class _DayDetailSheet extends StatefulWidget {
  const _DayDetailSheet({required this.controller, required this.date});

  final AppController controller;
  final CalendarDate date;

  @override
  State<_DayDetailSheet> createState() => _DayDetailSheetState();
}

class _DayDetailSheetState extends State<_DayDetailSheet> {
  late _Choice _choice;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final override = widget.controller.settings.overrides[widget.date];
    _choice = switch (override?.kind) {
      null => _Choice.auto,
      OverrideKind.dayOff => _Choice.dayOff,
      OverrideKind.workday => _Choice.workday,
    };
    _note = TextEditingController(text: override?.note ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final note = _note.text.trim();
    widget.controller.setOverride(
      [widget.date],
      switch (_choice) {
        _Choice.auto => null,
        _Choice.dayOff => DayOverride(
          OverrideKind.dayOff,
          note: note.isEmpty ? null : note,
        ),
        _Choice.workday => DayOverride(
          OverrideKind.workday,
          note: note.isEmpty ? null : note,
        ),
      },
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final info = widget.controller.classify(widget.date);
    final status = info.isOff
        ? l10n.statusDayOff
        : info.isExtraWorkday
        ? l10n.statusExtraWorkday
        : l10n.statusWorkday;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.longDate(widget.date), style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            status,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          for (final holiday in info.holidays)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.celebration_outlined),
              title: Text(l10n.holidayName(holiday)),
              subtitle: Text(
                [
                  if (holiday.localName != l10n.holidayName(holiday))
                    holiday.localName
                  else if (holiday.name != l10n.holidayName(holiday))
                    holiday.name,
                  if (info.isWork) l10n.holidayIgnored,
                ].join('\n'),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<_Choice>(
              segments: [
                ButtonSegment(
                  value: _Choice.auto,
                  label: Text(l10n.overrideAuto),
                ),
                ButtonSegment(
                  value: _Choice.dayOff,
                  label: Text(l10n.overrideDayOff),
                ),
                ButtonSegment(
                  value: _Choice.workday,
                  label: Text(l10n.overrideWorkday),
                ),
              ],
              selected: {_choice},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _choice = s.first),
            ),
          ),
          if (_choice != _Choice.auto) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: InputDecoration(
                hintText: l10n.noteHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _save, child: Text(l10n.save)),
            ],
          ),
        ],
      ),
    );
  }
}
