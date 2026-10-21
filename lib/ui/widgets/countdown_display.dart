import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Days, hours, minutes and seconds in four boxes.
class CountdownDisplay extends StatelessWidget {
  const CountdownDisplay({
    super.key,
    required this.remaining,
    required this.foreground,
  });

  final Duration remaining;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final d = remaining.isNegative ? Duration.zero : remaining;
    String two(int n) => n.toString().padLeft(2, '0');
    final parts = [
      ('${d.inDays}', l10n.boxDays),
      (two(d.inHours % 24), l10n.boxHours),
      (two(d.inMinutes % 60), l10n.boxMinutes),
      (two(d.inSeconds % 60), l10n.boxSeconds),
    ];
    return Row(
      children: [
        for (final (i, (value, label)) in parts.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _Box(value: value, label: label, foreground: foreground),
          ),
        ],
      ],
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.value,
    required this.label,
    required this.foreground,
  });

  final String value;
  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          FittedBox(
            child: Text(
              value,
              style: text.headlineMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Text(
            label,
            style: text.labelSmall?.copyWith(
              color: foreground.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
