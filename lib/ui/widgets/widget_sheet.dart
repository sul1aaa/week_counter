import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/countdown_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/award_copy.dart';
import '../../l10n/labels.dart';
import '../../state/app_controller.dart';
import '../kit/buttons.dart';
import '../kit/orb.dart';
import '../kit/sheet.dart';
import '../kit/toast.dart';
import '../theme/tokens.dart';

/// How to put the countdown on the home screen, with a preview.
Future<void> showWidgetSheet(BuildContext context, AppController controller) {
  final l10n = AppLocalizations.of(context);
  return showAppSheet<void>(
    context,
    title: l10n.widgetsTitle,
    builder: (context) => _WidgetSheet(controller: controller),
  );
}

class _WidgetSheet extends StatelessWidget {
  const _WidgetSheet({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = AppLocalizations.of(context);
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    final steps = ios
        ? [l10n.widgetStepIos1, l10n.widgetStepIos2, l10n.widgetStepIos3]
        : [
            l10n.widgetStepAndroid1,
            l10n.widgetStepAndroid2,
            l10n.widgetStepAndroid3,
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        WidgetPreview(snapshot: controller.snapshot, now: controller.clock()),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: WidgetPreview(
                snapshot: controller.snapshot,
                now: controller.clock(),
                small: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.widgetUpdatesNote, style: t.footnote)),
          ],
        ),
        const SizedBox(height: 16),
        for (final (i, step) in steps.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.surface2,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: t.mono.copyWith(
                      fontWeight: FontWeight.w600,
                      color: t.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(step, style: t.body),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        FutureBuilder<bool>(
          future: controller.widgetSync.canPinWidget(),
          builder: (context, pin) => pin.data ?? false
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppButton(
                    label: l10n.addWidget,
                    kind: ButtonKind.secondary,
                    icon: Icons.add_to_home_screen_rounded,
                    onTap: controller.widgetSync.pinWidget,
                  ),
                )
              : const SizedBox(),
        ),
        AppButton(
          label: l10n.gotIt,
          onTap: () {
            controller.dismissWidgetTip();
            final fresh = controller.earn('widget');
            Navigator.of(context).pop();
            if (fresh) {
              showToast(
                context,
                l10n.awardNew(awardCopy(l10n.localeName, 'widget').name),
              );
            }
          },
        ),
      ],
    );
  }
}

/// A picture of the home-screen widget, medium or small.
class WidgetPreview extends StatelessWidget {
  const WidgetPreview({
    super.key,
    required this.snapshot,
    required this.now,
    this.small = false,
  });

  final CountdownSnapshot snapshot;
  final DateTime now;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, target, progress, mode) = switch (snapshot.state) {
      CountingDown(:final target, :final block) && final s => (
        l10n.untilTitle(block.kind).toLowerCase(),
        target,
        s.progress(now),
        OrbMode.work,
      ),
      OffNow(:final backToWork, :final block) && final s => (
        block.kind == BlockKind.longWeekend
            ? l10n.eyebrowLongWeekendLeft
            : l10n.eyebrowWeekendLeft,
        backToWork,
        1 - s.progress(now),
        OrbMode.weekend,
      ),
      _ => (l10n.appTitle, null, 0.5, OrbMode.paused),
    };
    const ink2 = Tokens.widgetInk2;
    const labelStyle = TextStyle(
      fontFamily: Fonts.text,
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      color: ink2,
    );
    final time = Text.rich(
      TextSpan(
        children: [
          if (target == null)
            const TextSpan(text: '—')
          else
            for (final (i, (value, unit)) in _parts(
              target.difference(now),
              l10n,
            ).indexed) ...[
              if (i > 0) const TextSpan(text: ' '),
              TextSpan(text: value),
              TextSpan(
                text: unit,
                style: const TextStyle(
                  fontSize: 18,
                  letterSpacing: -0.36,
                  color: ink2,
                ),
              ),
            ],
        ],
      ),
      maxLines: 1,
      style: const TextStyle(
        fontFamily: Fonts.display,
        fontSize: 36,
        height: 1,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.8,
        fontFeatures: Fonts.tabular,
        color: Tokens.widgetInk,
      ),
    );
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 6,
        backgroundColor: const Color(0x1FFFFFFF),
        color: mode == OrbMode.weekend ? Tokens.lime : const Color(0xFF8B5CF6),
      ),
    );
    final when = target == null
        ? const SizedBox()
        : Text(l10n.when(target, now), style: labelStyle);
    final decoration = BoxDecoration(
      color: context.tokens.widgetBg,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: const Color(0x1AFFFFFF), width: 0.5),
    );

    final Widget card;
    if (small) {
      card = Container(
        width: 162,
        height: 162,
        padding: const EdgeInsets.all(14),
        decoration: decoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(label, style: labelStyle)),
                Orb(
                  size: 48,
                  fill: progress,
                  mode: mode,
                  still: true,
                  dark: true,
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: time,
            ),
            const SizedBox(height: 6),
            when,
            const SizedBox(height: 10),
            bar,
          ],
        ),
      );
    } else {
      card = Container(
        width: 346,
        height: 162,
        padding: const EdgeInsets.all(16),
        decoration: decoration,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
                  const SizedBox(height: 4),
                  time,
                  const SizedBox(height: 4),
                  when,
                  const Spacer(),
                  bar,
                ],
              ),
            ),
            const SizedBox(width: 12),
            Orb(size: 112, fill: progress, mode: mode, still: true, dark: true),
          ],
        ),
      );
    }
    return ExcludeSemantics(
      child: FittedBox(alignment: Alignment.topLeft, child: card),
    );
  }

  /// "2d 4h" as value and unit pairs, like the native widget.
  static List<(String, String)> _parts(Duration d, AppLocalizations l10n) {
    if (d.isNegative) d = Duration.zero;
    final days = d.inDays, hours = d.inHours % 24, minutes = d.inMinutes % 60;
    if (days > 0) return [('$days', l10n.timerDay), ('$hours', l10n.timerHour)];
    if (hours > 0) {
      return [('$hours', l10n.timerHour), ('$minutes', l10n.timerMinute)];
    }
    return [('$minutes', l10n.timerMinute)];
  }
}
