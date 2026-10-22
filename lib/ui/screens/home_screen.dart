import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/calendar_date.dart';
import '../../domain/countdown_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/jokes.dart';
import '../../l10n/labels.dart';
import '../../state/app_controller.dart';
import '../kit/app_page.dart';
import '../kit/buttons.dart';
import '../kit/controls.dart';
import '../kit/countdown_text.dart';
import '../kit/orb.dart';
import '../kit/strike.dart';
import '../root_shell.dart';
import '../theme/tokens.dart';
import '../widgets/joke_carousel.dart';
import '../widgets/week_strip.dart';
import '../widgets/widget_sheet.dart';
import 'country_picker_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.onOpenTab,
  });

  final AppController controller;
  final ValueChanged<AppTab> onOpenTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Timer _ticker;

  /// Which line of the pool comes first; the orb and the refresh button move
  /// it along. Starts at a different line each day.
  late int _jokeSeed = _controller.clock().day;

  AppController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = _controller.clock();
      if (!now.isBefore(_controller.snapshot.validUntil)) {
        _controller.recompute();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  void _nextJoke(int by) {
    setState(() => _jokeSeed += by);
    _controller.markOrbTipDone();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final snapshot = _controller.snapshot;
        final state = snapshot.state;
        final now = _controller.clock();
        final today = CalendarDate.fromDateTime(now);
        final width = MediaQuery.sizeOf(context).width;
        final hint = _hint(context, l10n, snapshot, now);
        final holidayToday = _controller
            .classify(today)
            .holidays
            .map(l10n.holidayName)
            .firstOrNull;
        final lines = jokes(
          l10n,
          state,
          _controller.settings.schedule,
          now,
          holidayToday: holidayToday,
        );
        final shown = [
          for (var i = 0; i < math.min(3, lines.length); i++)
            lines[(_jokeSeed + i) % lines.length],
        ];
        final week = weekOf(today, firstWeekday(context));
        final countable = state is CountingDown || state is OffNow;

        return AppPage(
          largeTitle: false,
          barAlways: true,
          leading: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: Text(
              l10n.date(today),
              style: t.callout.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          onRefresh: () => _controller.refreshHolidays(force: true),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _Hero(
                state: state,
                now: now,
                fontSize: (width * 0.21).clamp(56, 88).toDouble(),
                onOpenSettings: () => widget.onOpenTab(AppTab.settings),
                onOpenCalendar: () => widget.onOpenTab(AppTab.calendar),
              ),
            ),
            if (hint != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: hint,
              ),
            const SizedBox(height: 20),
            _OrbSection(
              state: state,
              now: now,
              size: (width * 0.54).clamp(176, 240).toDouble(),
              showTip: !_controller.prefs.orbTipDone && shown.length > 1,
              onTap: shown.length > 1 ? () => _nextJoke(1) : null,
            ),
            if (countable) ...[
              const SizedBox(height: 16),
              WeekStrip(
                days: [for (final d in week) _controller.classify(d)],
                schedule: _controller.settings.schedule,
                now: now,
                offNow: state is OffNow,
              ),
            ],
            if (shown.isNotEmpty) ...[
              const SizedBox(height: 24),
              JokeCarousel(lines: shown, onMore: () => _nextJoke(shown.length)),
            ],
            if (_showWidgetTip)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: InlineCard(
                  icon: Icons.widgets_rounded,
                  title: l10n.widgetTipTitle,
                  subtitle: l10n.widgetTipBody,
                  onTap: () => showWidgetSheet(context, _controller),
                ),
              ),
          ],
        );
      },
    );
  }

  bool get _showWidgetTip =>
      !_controller.prefs.widgetTipDone &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  /// The one notice worth showing under the timer, most urgent first.
  Widget? _hint(
    BuildContext context,
    AppLocalizations l10n,
    CountdownSnapshot snapshot,
    DateTime now,
  ) {
    if (_controller.settings.countryCode == null) {
      return InlineCard(
        icon: Icons.public_rounded,
        title: l10n.hintCountryTitle,
        subtitle: l10n.hintCountryBody,
        onTap: () => CountryPickerScreen.open(context, _controller),
      );
    }
    final missing = _controller.missingYears;
    if (missing.isNotEmpty) {
      return InlineCard(
        icon: Icons.cloud_off_rounded,
        tone: InlineTone.warn,
        title: l10n.hintHolidaysFailedTitle,
        subtitle: l10n.holidaysNotLoaded(missing.join(', ')),
        trailing: _controller.loadingHolidays
            ? const CupertinoActivityIndicator()
            : Icon(Icons.refresh_rounded, color: context.tokens.ink3),
        onTap: () => _controller.refreshHolidays(force: true),
      );
    }

    String details(OffBlock block) => [
      ?l10n.blockDetails(block),
      l10n.dateRange(block.first, block.last),
      if (block.length > 1) l10n.daysOffCount(block.length),
    ].join(' · ');

    switch (snapshot.state) {
      case OffNow(:final block) when block.hasExtraOff:
        final extra = block.days.where((d) => d.isExtraOff).length;
        return InlineCard(
          icon: block.kind == BlockKind.daysOff
              ? Icons.beach_access_rounded
              : Icons.celebration_rounded,
          tone: InlineTone.lime,
          title: block.kind == BlockKind.longWeekend
              ? l10n.weekendLonger(extra)
              : l10n.blockDetails(block) ?? l10n.kindLabel(block.kind),
          subtitle: block.kind == BlockKind.longWeekend
              ? l10n.blockDetails(block) ?? details(block)
              : details(block),
          onTap: () => widget.onOpenTab(AppTab.calendar),
        );
      case CountingDown(:final block) when block.hasExtraOff:
        return _aheadCard(l10n, block, details(block));
      case CountingDown() || OffNow():
        final next = snapshot.nextHoliday;
        if (next == null ||
            next.offStart!.difference(now) > const Duration(days: 30)) {
          return null;
        }
        return _aheadCard(
          l10n,
          next,
          '${details(next)} · '
          '${l10n.inDuration(l10n.compactDuration(next.offStart!.difference(now)))}',
        );
      case NoWorkdays() || NoDaysOff():
        return null;
    }
  }

  Widget _aheadCard(AppLocalizations l10n, OffBlock block, String subtitle) =>
      InlineCard(
        icon: block.kind == BlockKind.daysOff
            ? Icons.beach_access_rounded
            : Icons.celebration_rounded,
        title: switch (block.kind) {
          BlockKind.longWeekend || BlockKind.weekend => l10n.aheadLongWeekend,
          BlockKind.holiday => l10n.aheadHoliday,
          BlockKind.daysOff => l10n.aheadDaysOff,
        },
        subtitle: subtitle,
        onTap: () => widget.onOpenTab(AppTab.calendar),
      );
}

/// Eyebrow, big timer and the line under it.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.state,
    required this.now,
    required this.fontSize,
    required this.onOpenSettings,
    required this.onOpenCalendar,
  });

  final CountdownState state;
  final DateTime now;
  final double fontSize;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;

    Widget message(
      String title,
      String body,
      String? action,
      VoidCallback? onAction,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: t.largeTitle.copyWith(fontSize: 40, height: 42 / 40),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          style: t.body.copyWith(color: t.ink2, height: 23 / 17),
        ),
        if (action != null) ...[
          const SizedBox(height: 20),
          AppButton(label: action, onTap: onAction, expand: false),
        ],
      ],
    );

    switch (state) {
      case CountingDown(:final target, :final block) && final s:
        final lastHour = target.difference(now) <= const Duration(hours: 1);
        // The day the week ends on, e.g. Friday for Friday 18:00.
        final endDay = target.subtract(const Duration(minutes: 1)).weekday;
        final eyebrow = lastHour
            ? [
                (l10n.eyebrowLastHourPrefix, false),
                (l10n.eyebrowLastHourStrike, true),
                (l10n.eyebrowLastHourSuffix, false),
              ]
            : [
                (l10n.eyebrowUntil, false),
                (l10n.weekdayName('$endDay'), true),
                (l10n.eyebrowFreedom, false),
              ];
        final meta = [
          l10n.weekDone((s.progress(now) * 100).floor()),
          if (block.kind != BlockKind.weekend)
            l10n.kindLabel(block.kind).toLowerCase(),
        ];
        return _layout(context, eyebrow, target, meta);
      case OffNow(:final block, backToWork: final target?):
        final eyebrow = switch (block.kind) {
          BlockKind.weekend => [
            (l10n.eyebrowOffStrike, true),
            (l10n.eyebrowWeekendLeft, false),
          ],
          BlockKind.longWeekend => [
            (l10n.eyebrowOffStrike, true),
            (l10n.eyebrowLongWeekendLeft, false),
          ],
          BlockKind.holiday => [
            (l10n.eyebrowHolidayStrike, true),
            (l10n.eyebrowHolidayLeft, false),
          ],
          BlockKind.daysOff => [
            (l10n.eyebrowDaysOffStrike, true),
            (l10n.eyebrowDaysOffLeft, false),
          ],
        };
        final meta = [l10n.backToWorkLower];
        return _layout(context, eyebrow, target, meta);
      case OffNow():
        return message(l10n.youreOff, l10n.noWorkAhead, null, null);
      case NoWorkdays():
        return message(
          l10n.noWorkdaysTitle,
          l10n.noWorkdaysBody,
          l10n.openSettings,
          onOpenSettings,
        );
      case NoDaysOff():
        return message(
          l10n.noDaysOffTitle,
          l10n.noDaysOffBody,
          l10n.openCalendar,
          onOpenCalendar,
        );
    }
  }

  Widget _layout(
    BuildContext context,
    List<(String, bool)> eyebrow,
    DateTime target,
    List<String> meta,
  ) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final eyebrowStyle = TextStyle(
      fontFamily: Fonts.display,
      fontSize: 20,
      height: 26 / 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
      color: t.ink,
    );
    final remaining = target.difference(now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: eyebrow.map((e) => e.$1).join(' '),
          excludeSemantics: true,
          child: Wrap(
            spacing: 6,
            children: [
              for (final (text, strike) in eyebrow)
                strike
                    ? StrikeText(
                        text,
                        key: ValueKey(text),
                        style: eyebrowStyle.copyWith(color: t.ink3),
                      )
                    : Text(text, style: eyebrowStyle),
            ],
          ),
        ),
        const SizedBox(height: 10),
        CountdownText(
          text: timerText(remaining, l10n),
          semanticLabel: l10n.humanDuration(remaining),
          fontSize: fontSize,
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: l10n.when(target, now),
                style: TextStyle(
                  fontFamily: Fonts.display,
                  fontSize: 17,
                  height: 22 / 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.34,
                  color: t.ink,
                ),
              ),
              for (final part in meta) TextSpan(text: ' · $part'),
            ],
          ),
          style: t.mono,
        ),
      ],
    );
  }
}

class _OrbSection extends StatelessWidget {
  const _OrbSection({
    required this.state,
    required this.now,
    required this.size,
    required this.showTip,
    required this.onTap,
  });

  final CountdownState state;
  final DateTime now;
  final double size;
  final bool showTip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final (fill, mode, percent) = switch (state) {
      CountingDown() && final s => (
        math.max(0.06, s.progress(now)),
        OrbMode.work,
        (s.progress(now) * 100).floor(),
      ),
      OffNow(:final block) && final s => (
        math.max(0.08, 1 - s.progress(now)),
        block.kind == BlockKind.daysOff ? OrbMode.paused : OrbMode.weekend,
        (s.progress(now) * 100).floor(),
      ),
      _ => (0.42, OrbMode.paused, 0),
    };
    final inShift = switch (state) {
      CountingDown(:final inShiftUntil?, :final target)
          when inShiftUntil != target =>
        inShiftUntil,
      _ => null,
    };
    final caption = inShift != null
        ? l10n.inShiftUntil(l10n.time(inShift))
        : showTip
        ? l10n.orbTip
        : '';
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 236),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Orb(
            size: size,
            fill: fill,
            mode: mode,
            onTap: onTap,
            semanticLabel: l10n.orbLabel(percent),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 16,
            child: Text(caption, style: t.mono.copyWith(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
