import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';
import 'countdown_engine.dart';

/// Key under which the payload is stored for the native widgets.
const widgetPayloadKey = 'wc_payload_v1';

/// One stretch of time during which the widget shows the same text.
///
/// Segments alternate between counting down to time off and being off.
@immutable
class WidgetSegment {
  const WidgetSegment({
    required this.start,
    required this.end,
    required this.counting,
    required this.title,
    required this.subtitle,
    this.target,
    this.from,
    this.secondary,
  });

  final DateTime start;
  final DateTime end;

  /// True while counting down to time off, false while off.
  final bool counting;

  /// What the timer counts down to; null when off with no workday ahead.
  final DateTime? target;

  /// Start of the run of workdays or of the time off, which can be before
  /// [start]. The orb's fill is how far now is from here to [target], as in
  /// the app. Null when unknown: the orb then shows empty (full while off).
  final DateTime? from;
  final String title;
  final String subtitle;
  final String? secondary;

  Map<String, dynamic> toJson() => {
    'start': start.millisecondsSinceEpoch,
    'end': end.millisecondsSinceEpoch,
    'mode': counting ? 'countdown' : 'off',
    'target': target?.millisecondsSinceEpoch,
    'from': from?.millisecondsSinceEpoch,
    'title': title,
    'subtitle': subtitle,
    'secondary': secondary,
  };
}

/// Pre-localized countdown data the native widgets render without running
/// Dart. They show the first segment whose end is still in the future.
@immutable
class WidgetPayload {
  const WidgetPayload({
    required this.generatedAt,
    required this.locale,
    required this.strings,
    required this.segments,
  });

  final DateTime generatedAt;
  final String locale;

  /// Unit abbreviations and the text shown when no segment applies.
  final Map<String, String> strings;
  final List<WidgetSegment> segments;

  Map<String, dynamic> toJson() => {
    'v': 1,
    'generatedAt': generatedAt.millisecondsSinceEpoch,
    'locale': locale,
    'strings': strings,
    'segments': [for (final s in segments) s.toJson()],
  };

  String encode() => jsonEncode(toJson());

  /// Times when the widget's text changes: segment ends and the moments the
  /// whole-days number ticks down. Android schedules widget updates at these.
  List<DateTime> boundaryTimes(
    DateTime now, {
    Duration window = const Duration(days: 60),
    int max = 300,
  }) {
    final limit = now.add(window);
    final times = <DateTime>{};
    void add(DateTime time) {
      if (time.isAfter(now) && !time.isAfter(limit)) times.add(time);
    }

    for (final segment in segments) {
      if (segment.start.isAfter(limit)) break;
      add(segment.end);
      final target = segment.target;
      if (target == null) continue;
      for (var days = 1; ; days++) {
        final time = target.subtract(Duration(days: days));
        if (!time.isAfter(segment.start) || time.isBefore(now)) break;
        add(time);
      }
    }
    return (times.toList()..sort()).take(max).toList();
  }
}

/// Builds the widget data from up to [maxBlocks] blocks of [snapshot].
WidgetPayload buildWidgetPayload(
  CountdownSnapshot snapshot,
  AppLocalizations l10n, {
  int maxBlocks = 12,
}) {
  final now = snapshot.computedAt;
  final state = snapshot.state;
  final segments = <WidgetSegment>[];
  var cursor = now;

  for (final (i, block) in snapshot.blocks.take(maxBlocks).indexed) {
    final details = l10n.blockDetails(block);
    final offStart = block.offStart;
    if (offStart != null && offStart.isAfter(cursor)) {
      segments.add(
        WidgetSegment(
          start: cursor,
          end: offStart,
          counting: true,
          target: offStart,
          // The current run began before now; each later one begins when
          // the time off before it ends.
          from: i == 0 && state is CountingDown ? state.since : cursor,
          title: l10n.untilTitle(block.kind),
          subtitle:
              '${l10n.shortWhen(offStart, cursor)} · '
              '${l10n.daysOffCount(block.length)}',
          secondary: details,
        ),
      );
      cursor = offStart;
    }

    final offEnd = block.offEnd;
    final end = offEnd ?? cursor.add(const Duration(days: 3650));
    segments.add(
      WidgetSegment(
        start: cursor,
        end: end,
        counting: false,
        target: offEnd,
        from: offStart,
        title: l10n.youreOff,
        subtitle: offEnd == null
            ? l10n.noWorkAhead
            : l10n.backToWorkAt(l10n.shortWhen(offEnd, cursor)),
        secondary: details,
      ),
    );
    cursor = end;
    if (offEnd == null) break;
  }

  return WidgetPayload(
    generatedAt: now,
    locale: l10n.localeName,
    strings: {
      'dayShort': l10n.dayShort,
      'hourShort': l10n.hourShort,
      'minuteShort': l10n.minuteShort,
      'empty': switch (snapshot.state) {
        NoWorkdays() => l10n.noWorkdaysTitle,
        NoDaysOff() => l10n.noDaysOffTitle,
        _ => l10n.widgetSetUp,
      },
    },
    segments: segments,
  );
}
