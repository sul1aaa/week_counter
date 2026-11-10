import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/countdown_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../kit/countdown_text.dart';
import '../kit/orb.dart';
import '../theme/tokens.dart';

/// The orb for today: fills up through the shift and counts down to its end.
class DayOrb extends StatelessWidget {
  const DayOrb({
    super.key,
    required this.shift,
    required this.now,
    required this.size,
  });

  /// Null on a day off.
  final DayShift? shift;
  final DateTime now;
  final double size;

  /// Room under the orb for the two lines of text.
  static const textHeight = 10.0 + 36 + 4 + 16;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final titleStyle = TextStyle(
      fontFamily: Fonts.display,
      fontSize: 26,
      height: 1,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.6,
      color: t.ink,
    );

    final Widget title;
    final String subtitle;
    final double fill;
    final OrbMode mode;
    switch (shift) {
      case null:
        title = Text(l10n.dayOrbOffTitle, style: titleStyle);
        subtitle = l10n.dayOrbOffBody;
        fill = 0.42;
        mode = OrbMode.paused;
      case DayShift(:final start) when now.isBefore(start):
        title = Text(l10n.time(start), style: titleStyle);
        subtitle = l10n.dayOrbStarts;
        fill = 0.06;
        mode = OrbMode.work;
      case DayShift(:final end) when !now.isBefore(end):
        title = Text(l10n.dayOrbDoneTitle, style: titleStyle);
        subtitle = l10n.dayOrbDoneBody(l10n.time(end));
        fill = 1;
        mode = OrbMode.weekend;
      case final DayShift s:
        final remaining = s.end.difference(now);
        title = CountdownText(
          text: timerText(remaining, l10n),
          semanticLabel: l10n.humanDuration(remaining),
          fontSize: 34,
        );
        subtitle = l10n.dayOrbLeft(l10n.time(s.end));
        fill = math.max(0.06, s.progress(now));
        mode = OrbMode.work;
    }
    final percent = ((shift?.progress(now) ?? 0) * 100).floor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Orb(
          size: size,
          fill: fill,
          mode: mode,
          semanticLabel: shift == null ? null : l10n.dayOrbLabel(percent),
        ),
        const SizedBox(height: 10),
        SizedBox(height: 36, child: Center(child: title)),
        const SizedBox(height: 4),
        SizedBox(
          height: 16,
          child: Text(subtitle, style: t.mono.copyWith(fontSize: 12)),
        ),
      ],
    );
  }
}
