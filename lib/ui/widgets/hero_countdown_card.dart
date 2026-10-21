import 'package:flutter/material.dart';

import '../../domain/countdown_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import 'countdown_display.dart';

/// The big countdown at the top of the home screen.
class HeroCountdownCard extends StatelessWidget {
  const HeroCountdownCard({
    super.key,
    required this.snapshot,
    required this.now,
    required this.onOpenSettings,
    required this.onOpenCalendar,
  });

  final CountdownSnapshot snapshot;
  final DateTime now;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    String caption(List<String?> parts) =>
        parts.whereType<String>().join(' · ');

    switch (snapshot.state) {
      case CountingDown(:final target, :final block, :final inShiftUntil):
        return _GradientCard(
          colors: [scheme.primary, scheme.tertiary],
          foreground: scheme.onPrimary,
          chip: inShiftUntil == null
              ? null
              : l10n.inShiftUntil(l10n.time(inShiftUntil)),
          title: l10n.untilTitle(block.kind),
          remaining: target.difference(now),
          lines: [
            l10n.untilWhen(l10n.dateTime(target)),
            caption([
              l10n.daysOffCount(block.length),
              l10n.blockDetails(block),
            ]),
          ],
        );
      case OffNow(:final block, :final backToWork?, :final dayNumber):
        return _GradientCard(
          colors: [scheme.tertiary, scheme.secondary],
          foreground: scheme.onTertiary,
          headline: l10n.youreOff,
          title: l10n.backToWorkIn,
          remaining: backToWork.difference(now),
          lines: [
            l10n.dateTime(backToWork),
            caption([
              dayNumber == null
                  ? l10n.daysOffCount(block.length)
                  : l10n.dayNofM(dayNumber, block.length),
              l10n.blockDetails(block),
            ]),
          ],
        );
      case OffNow():
        return _MessageCard(
          icon: Icons.beach_access,
          title: l10n.youreOff,
          body: l10n.noWorkAhead,
        );
      case NoWorkdays():
        return _MessageCard(
          icon: Icons.event_busy,
          title: l10n.noWorkdaysTitle,
          body: l10n.noWorkdaysBody,
          action: l10n.openSettings,
          onAction: onOpenSettings,
        );
      case NoDaysOff():
        return _MessageCard(
          icon: Icons.work_history_outlined,
          title: l10n.noDaysOffTitle,
          body: l10n.noDaysOffBody,
          action: l10n.openCalendar,
          onAction: onOpenCalendar,
        );
    }
  }
}

class _GradientCard extends StatelessWidget {
  const _GradientCard({
    required this.colors,
    required this.foreground,
    required this.title,
    required this.remaining,
    required this.lines,
    this.headline,
    this.chip,
  });

  final List<Color> colors;
  final Color foreground;
  final String? headline;
  final String title;
  final String? chip;
  final Duration remaining;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chip != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: foreground.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.work_outline, size: 14, color: foreground),
                  const SizedBox(width: 6),
                  Text(
                    chip!,
                    style: text.labelMedium?.copyWith(color: foreground),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (headline != null)
            Text(
              headline!,
              style: text.headlineMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          Text(
            title,
            style: (headline == null ? text.headlineSmall : text.titleMedium)
                ?.copyWith(color: foreground, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          CountdownDisplay(remaining: remaining, foreground: foreground),
          const SizedBox(height: 16),
          for (final line in lines)
            if (line.isNotEmpty)
              Text(
                line,
                style: text.bodyMedium?.copyWith(
                  color: foreground.withValues(alpha: 0.9),
                ),
              ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(body, style: theme.textTheme.bodyMedium),
            if (action != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(onPressed: onAction, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}
