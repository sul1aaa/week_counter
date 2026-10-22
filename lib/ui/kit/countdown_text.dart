import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/tokens.dart';

/// "2d 04h 12m", "4h 05m", or "47:09" in the last hour. Seconds only show
/// when they matter.
String timerText(Duration remaining, AppLocalizations l10n) {
  final d = remaining.isNegative ? Duration.zero : remaining;
  String two(int n) => n.toString().padLeft(2, '0');
  final days = d.inDays, hours = d.inHours % 24, minutes = d.inMinutes % 60;
  final (dd, hh, mm) = (l10n.timerDay, l10n.timerHour, l10n.timerMinute);
  if (days >= 10) return '$days$dd ${two(hours)}$hh';
  if (days > 0) return '$days$dd ${two(hours)}$hh ${two(minutes)}$mm';
  if (d.inHours > 0) return '${d.inHours}$hh ${two(minutes)}$mm';
  return '${two(minutes)}:${two(d.inSeconds % 60)}';
}

/// The big countdown. Digits roll in when they change; units are smaller.
class CountdownText extends StatelessWidget {
  const CountdownText({
    super.key,
    required this.text,
    required this.semanticLabel,
    this.fontSize = 88,
    this.color,
  });

  final String text;
  final String semanticLabel;
  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = TextStyle(
      fontFamily: Fonts.display,
      fontSize: fontSize,
      height: 1,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.05 * fontSize,
      fontFeatures: Fonts.tabular,
      color: color ?? t.ink,
    );
    final unitStyle = style.copyWith(
      fontSize: fontSize * 0.36,
      letterSpacing: -0.02 * fontSize * 0.36,
      color: t.ink2,
    );
    final chars = text.split('');
    final children = <Widget>[];
    for (final (i, c) in chars.indexed) {
      if (c == ' ') continue;
      if (RegExp(r'\d').hasMatch(c)) {
        children.add(_Digit(key: ValueKey(i), digit: c, style: style));
      } else if (c == ':') {
        children.add(
          Transform.translate(
            offset: Offset(0, -0.06 * fontSize),
            child: Text(':', style: style.copyWith(color: t.ink3)),
          ),
        );
      } else {
        final last = i == chars.length - 1;
        children.add(
          Padding(
            padding: EdgeInsets.only(
              left: 0.06 * fontSize,
              right: last ? 0 : 0.32 * fontSize,
            ),
            child: Text(c, style: unitStyle),
          ),
        );
      }
    }
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: children,
        ),
      ),
    );
  }
}

class _Digit extends StatelessWidget {
  const _Digit({super.key, required this.digit, required this.style});

  final String digit;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final current = ValueKey(digit);
    return ClipRect(
      child: AnimatedSwitcher(
        duration: context.reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 260),
        switchInCurve: Motion.out,
        transitionBuilder: (child, animation) {
          // The old digit just disappears; the new one drops in from above.
          if (child.key != current) return const SizedBox.shrink();
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, -0.6),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Text(digit, key: current, style: style),
      ),
    );
  }
}
