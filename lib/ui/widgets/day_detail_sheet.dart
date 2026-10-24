import 'package:flutter/material.dart';

import '../../core/calendar_date.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../models/app_settings.dart';
import '../../state/app_controller.dart';
import '../kit/buttons.dart';
import '../kit/controls.dart';
import '../kit/group.dart';
import '../kit/sheet.dart';
import '../theme/tokens.dart';

Future<void> showDayDetailSheet(
  BuildContext context,
  AppController controller,
  CalendarDate date,
) => showAppSheet<void>(
  context,
  title: AppLocalizations.of(context).longDate(date),
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
    final vacation =
        widget.controller.settings.overrides[widget.date]?.vacation ?? false;
    widget.controller.setOverride(
      [widget.date],
      switch (_choice) {
        _Choice.auto => null,
        // A vacation day stays part of the vacation, or it would split in two.
        _Choice.dayOff => DayOverride(
          OverrideKind.dayOff,
          note: note.isEmpty ? null : note,
          vacation: vacation,
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
    final t = context.tokens;
    final info = widget.controller.classify(widget.date);
    final status = info.isOff
        ? l10n.statusDayOff
        : info.isExtraWorkday
        ? l10n.statusExtraWorkday
        : l10n.statusWorkday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          status,
          textAlign: TextAlign.center,
          style: t.callout.copyWith(
            color: t.violetInk,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (info.holidays.isNotEmpty) ...[
          const SizedBox(height: 16),
          Group(
            margin: EdgeInsets.zero,
            color: t.sheetCard,
            children: [
              for (final holiday in info.holidays)
                GroupRow(
                  icon: Icons.celebration_rounded,
                  title: l10n.holidayName(holiday),
                  subtitle: [
                    if (holiday.localName != l10n.holidayName(holiday))
                      holiday.localName
                    else if (holiday.name != l10n.holidayName(holiday))
                      holiday.name,
                    if (info.isWork) l10n.holidayIgnored,
                  ].join('\n').orNull,
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Segmented<_Choice>(
          segments: [
            (_Choice.auto, l10n.overrideAuto),
            (_Choice.dayOff, l10n.overrideDayOff),
            (_Choice.workday, l10n.overrideWorkday),
          ],
          selected: _choice,
          onChanged: (choice) => setState(() => _choice = choice),
        ),
        AnimatedSize(
          duration: Motion.mid,
          curve: Motion.ios,
          alignment: Alignment.topCenter,
          child: _choice == _Choice.auto
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextField(
                    controller: _note,
                    style: t.body,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: l10n.noteHint,
                      hintStyle: t.body.copyWith(color: t.ink3),
                      filled: true,
                      fillColor: t.sheetCard,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 20),
        AppButton(label: l10n.save, onTap: _save),
      ],
    );
  }
}

extension on String {
  /// Null instead of an empty string.
  String? get orNull => isEmpty ? null : this;
}
