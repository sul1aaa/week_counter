import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/pay.dart';
import '../kit/buttons.dart';
import '../kit/controls.dart';
import '../kit/sheet.dart';
import '../theme/tokens.dart';

/// Pay period, amount and currency in a sheet. Returns the pay switched on,
/// or null when dismissed.
Future<Pay?> showPaySheet(BuildContext context, Pay initial) =>
    showAppSheet<Pay>(
      context,
      title: AppLocalizations.of(context).payTitle,
      builder: (_) => _PaySheet(initial: initial),
    );

class _PaySheet extends StatefulWidget {
  const _PaySheet({required this.initial});

  final Pay initial;

  @override
  State<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<_PaySheet> {
  late PayPeriod _period = widget.initial.period;
  late final _amount = TextEditingController(text: _plain(widget.initial));
  late final _currency = TextEditingController(text: widget.initial.currency);

  /// "400000" or "12.5", without grouping, for editing.
  static String _plain(Pay pay) => pay.amount <= 0
      ? ''
      : pay.amount == pay.amount.truncateToDouble()
      ? pay.amount.toInt().toString()
      : pay.amount.toString();

  /// The amount typed, accepting "400 000" and "12,50"; null unless above 0.
  double? get _parsed {
    final value = double.tryParse(
      _amount.text.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.'),
    );
    return value != null && value.isFinite && value > 0 ? value : null;
  }

  @override
  void dispose() {
    _amount.dispose();
    _currency.dispose();
    super.dispose();
  }

  InputDecoration _decoration(Tokens t, String hint) => InputDecoration(
    hintText: hint,
    hintStyle: t.body.copyWith(color: t.ink3),
    filled: true,
    fillColor: t.sheetCard,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final amount = _parsed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Segmented<PayPeriod>(
          segments: [
            (PayPeriod.hour, l10n.payPeriodHour),
            (PayPeriod.day, l10n.payPeriodDay),
            (PayPeriod.week, l10n.payPeriodWeek),
            (PayPeriod.twoWeeks, l10n.payPeriodTwoWeeks),
            (PayPeriod.month, l10n.payPeriodMonth),
          ],
          selected: _period,
          onChanged: (period) => setState(() => _period = period),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('pay.amount'),
                controller: _amount,
                autofocus: widget.initial.amount <= 0,
                style: t.body,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 .,]')),
                ],
                decoration: _decoration(t, l10n.payAmountHint),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 96,
              child: TextField(
                key: const ValueKey('pay.currency'),
                controller: _currency,
                style: t.body,
                textAlign: TextAlign.center,
                inputFormatters: [LengthLimitingTextInputFormatter(5)],
                decoration: _decoration(t, l10n.payCurrencyHint),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(switch (_period) {
            PayPeriod.hour => l10n.payHourNote,
            PayPeriod.day => l10n.payDayNote,
            PayPeriod.week => l10n.payWeekNote,
            PayPeriod.twoWeeks => l10n.payTwoWeeksNote,
            PayPeriod.month => l10n.payMonthNote,
          }, style: t.footnote),
        ),
        const SizedBox(height: 20),
        AppButton(
          label: l10n.save,
          onTap: amount == null
              ? null
              : () => Navigator.of(context).pop(
                  Pay(
                    on: true,
                    period: _period,
                    amount: amount,
                    currency: _currency.text.trim(),
                  ),
                ),
        ),
      ],
    );
  }
}
