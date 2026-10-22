import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/countdown_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../state/app_controller.dart';
import '../kit/buttons.dart';
import '../kit/orb.dart';
import '../kit/sheet.dart';
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
        const SizedBox(height: 12),
        Center(
          child: WidgetPreview(
            snapshot: controller.snapshot,
            now: controller.clock(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.widgetUpdatesNote,
          textAlign: TextAlign.center,
          style: t.footnote,
        ),
        const SizedBox(height: 8),
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
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

/// A picture of the medium home-screen widget.
class WidgetPreview extends StatelessWidget {
  const WidgetPreview({super.key, required this.snapshot, required this.now});

  final CountdownSnapshot snapshot;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (title, target, progress, mode) = switch (snapshot.state) {
      CountingDown(:final target, :final block) && final s => (
        l10n.untilTitle(block.kind),
        target,
        s.progress(now),
        OrbMode.work,
      ),
      OffNow(:final backToWork) && final s => (
        l10n.backToWorkIn,
        backToWork,
        1 - s.progress(now),
        OrbMode.weekend,
      ),
      _ => (l10n.appTitle, null, 0.5, OrbMode.paused),
    };
    const ink2 = Tokens.widgetInk2;
    return ExcludeSemantics(
      child: FittedBox(
        child: Container(
          width: 346,
          height: 162,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.tokens.widgetBg,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0x1AFFFFFF), width: 0.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: Fonts.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ink2,
                      ),
                    ),
                    Text(
                      target == null
                          ? '—'
                          : l10n.compactDuration(target.difference(now)),
                      maxLines: 1,
                      style: const TextStyle(
                        fontFamily: Fonts.display,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.7,
                        fontFeatures: Fonts.tabular,
                        color: Tokens.widgetInk,
                      ),
                    ),
                    if (target != null)
                      Text(
                        l10n.when(target, now),
                        style: const TextStyle(
                          fontFamily: Fonts.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ink2,
                        ),
                      ),
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: const Color(0x1FFFFFFF),
                        color: mode == OrbMode.weekend
                            ? Tokens.lime
                            : const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Orb(
                size: 104,
                fill: progress,
                mode: mode,
                still: true,
                dark: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
