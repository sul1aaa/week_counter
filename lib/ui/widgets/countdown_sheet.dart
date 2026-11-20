import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/calendar_date.dart';
import '../../l10n/app_localizations.dart';
import '../../models/countdown.dart';
import '../../state/app_controller.dart';
import '../kit/buttons.dart';
import '../kit/sheet.dart';
import '../theme/tokens.dart';

/// Adds a countdown, or edits or deletes [countdown].
Future<void> showCountdownSheet(
  BuildContext context,
  AppController controller, {
  Countdown? countdown,
}) {
  final l10n = AppLocalizations.of(context);
  return showAppSheet<void>(
    context,
    title: countdown == null ? l10n.countdownNew : l10n.countdownEdit,
    builder: (_) =>
        _CountdownSheet(controller: controller, countdown: countdown),
  );
}

class _CountdownSheet extends StatefulWidget {
  const _CountdownSheet({required this.controller, this.countdown});

  final AppController controller;
  final Countdown? countdown;

  @override
  State<_CountdownSheet> createState() => _CountdownSheetState();
}

class _CountdownSheetState extends State<_CountdownSheet> {
  late final _title = TextEditingController(
    text: widget.countdown?.title ?? '',
  );
  late final _today = CalendarDate.fromDateTime(widget.controller.clock());
  late CalendarDate _date = widget.countdown?.date ?? _today.addDays(1);

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    final countdown = widget.countdown;
    if (countdown == null) {
      widget.controller.addCountdown(title, _date);
    } else {
      widget.controller.updateCountdown(
        countdown.copyWith(title: title, date: _date),
      );
    }
    Navigator.of(context).pop();
  }

  void _delete() {
    widget.controller.removeCountdown(widget.countdown!.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('countdown.title'),
          controller: _title,
          style: t.body,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: l10n.countdownTitleHint,
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
        const SizedBox(height: 8),
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
          child: SizedBox(
            height: 200,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: _date.startOfDay,
              minimumDate: _today.startOfDay,
              onDateTimeChanged: (value) =>
                  _date = CalendarDate.fromDateTime(value),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AppButton(
          key: const ValueKey('countdown.save'),
          label: l10n.save,
          onTap: _title.text.trim().isEmpty ? null : _save,
        ),
        if (widget.countdown != null) ...[
          const SizedBox(height: 4),
          AppButton(
            key: const ValueKey('countdown.delete'),
            label: l10n.countdownDelete,
            kind: ButtonKind.ghost,
            onTap: _delete,
          ),
        ],
      ],
    );
  }
}
