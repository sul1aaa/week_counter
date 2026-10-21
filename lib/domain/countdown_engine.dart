import 'package:flutter/foundation.dart';

import '../core/calendar_date.dart';
import '../models/app_settings.dart';
import '../models/holiday.dart';
import '../models/work_schedule.dart';
import 'day_classifier.dart';

enum BlockKind {
  /// Only the usual days off.
  weekend,

  /// A weekend made longer by a holiday or a day off, up to four days.
  longWeekend,

  /// Public holidays, not counting weekends that may be attached.
  holiday,

  /// Longer time off that includes the user's own days off, e.g. a vacation.
  daysOff,
}

/// A run of consecutive days off.
@immutable
class OffBlock {
  const OffBlock({
    required this.days,
    required this.offStart,
    required this.offEnd,
  });

  final List<DayInfo> days;

  /// When the last shift before the block ends. Null if the block started
  /// before the look-back window.
  final DateTime? offStart;

  /// When the first shift after the block starts. Null if there is no
  /// workday within the horizon.
  final DateTime? offEnd;

  CalendarDate get first => days.first.date;
  CalendarDate get last => days.last.date;
  int get length => days.length;

  bool get hasScheduledOff =>
      days.any((d) => d.reasons.contains(OffReason.scheduled));

  bool get hasExtraOff => days.any((d) => d.isExtraOff);

  /// Public holidays that fall inside this block.
  List<Holiday> get holidays => [
    for (final d in days)
      if (d.reasons.contains(OffReason.publicHoliday)) ...d.holidays,
  ];

  /// Notes the user attached to their own days off in this block.
  List<String> get notes => days
      .map((d) => d.override?.note ?? '')
      .where((note) => note.isNotEmpty)
      .toList();

  BlockKind get kind {
    if (!hasExtraOff) return BlockKind.weekend;
    final hasCustom = days.any(
      (d) =>
          d.isExtraOff &&
          d.reasons.contains(OffReason.custom) &&
          !d.reasons.contains(OffReason.publicHoliday),
    );
    final short = length <= 4;
    if (hasCustom) {
      return hasScheduledOff && short ? BlockKind.longWeekend : BlockKind.daysOff;
    }
    return hasScheduledOff && short ? BlockKind.longWeekend : BlockKind.holiday;
  }

  /// Whether [date] is one of this block's days.
  bool contains(CalendarDate date) => first <= date && date <= last;
}

sealed class CountdownState {
  const CountdownState();
}

/// Work is ongoing; counting down to the end of the last shift before
/// [block].
final class CountingDown extends CountdownState {
  const CountingDown({
    required this.target,
    required this.block,
    this.inShiftUntil,
  });

  final DateTime target;
  final OffBlock block;

  /// End of the shift happening right now, if any.
  final DateTime? inShiftUntil;
}

/// Currently off work, counting down to [backToWork].
final class OffNow extends CountdownState {
  const OffNow({required this.block, this.backToWork, this.dayNumber});

  final OffBlock block;

  /// Null when no workday is coming within the horizon.
  final DateTime? backToWork;

  /// 1-based index of today within [block]; null on the evening before the
  /// block's first day.
  final int? dayNumber;
}

/// The schedule has no workdays, so there is nothing to count down to.
final class NoWorkdays extends CountdownState {
  const NoWorkdays();
}

/// Every day within the horizon is a workday.
final class NoDaysOff extends CountdownState {
  const NoDaysOff();
}

@immutable
class CountdownSnapshot {
  const CountdownSnapshot({
    required this.computedAt,
    required this.state,
    required this.blocks,
    required this.validUntil,
    this.nextWeekend,
    this.nextHoliday,
  });

  final DateTime computedAt;
  final CountdownState state;

  /// The current block (if off now) followed by upcoming blocks.
  final List<OffBlock> blocks;

  /// Next block that includes a normal weekend and hasn't started yet.
  final OffBlock? nextWeekend;

  /// Next block with a holiday or day off on a workday, not started yet.
  final OffBlock? nextHoliday;

  /// When [state] may change and the snapshot should be recomputed.
  final DateTime validUntil;

  /// Blocks that haven't started yet.
  Iterable<OffBlock> get upcoming => blocks.where(
    (b) => b.offStart != null && b.offStart!.isAfter(computedAt),
  );
}

/// Finds off-blocks and the countdown target from a [DayClassifier].
class CountdownEngine {
  CountdownEngine(
    this.classifier, {
    this.horizonDays = 400,
    this.lookbackDays = 60,
    this.maxBlocks = 24,
  });

  final DayClassifier classifier;
  final int horizonDays;
  final int lookbackDays;
  final int maxBlocks;

  WorkSchedule get schedule => classifier.schedule;

  DayInfo _day(CalendarDate date) => classifier.classify(date);

  /// Off-blocks that haven't ended yet at [now], oldest first.
  ///
  /// The scan starts at yesterday and walks back through any days off, so a
  /// block that is still running (e.g. Monday 07:00 before a 09:00 shift) is
  /// found with its real start.
  List<OffBlock> blocks(DateTime now) {
    final today = CalendarDate.fromDateTime(now);
    final limit = today.addDays(horizonDays);

    var start = today.addDays(-1);
    for (var i = 0; i < lookbackDays && _day(start).isOff; i++) {
      start = start.addDays(-1);
    }

    final result = <OffBlock>[];
    var date = start;
    while (date <= limit && result.length < maxBlocks) {
      if (_day(date).isWork) {
        date = date.addDays(1);
        continue;
      }
      final firstDay = date;
      final days = <DayInfo>[];
      while (date <= limit && _day(date).isOff) {
        days.add(_day(date));
        date = date.addDays(1);
      }
      // `date` is now the first workday after the block, or past the limit.
      final offStart = firstDay == start
          ? null
          : schedule.shiftEndOn(firstDay.addDays(-1));
      final offEnd = date <= limit ? schedule.shiftStartOn(date) : null;
      if (offEnd == null || offEnd.isAfter(now)) {
        result.add(OffBlock(days: days, offStart: offStart, offEnd: offEnd));
      }
    }
    return result;
  }

  /// End of the shift in progress at [now], or null between shifts.
  DateTime? currentShiftEnd(DateTime now) {
    final today = CalendarDate.fromDateTime(now);
    // Yesterday's shift may still be running if it is overnight.
    for (final date in [today.addDays(-1), today]) {
      if (_day(date).isOff) continue;
      final start = schedule.shiftStartOn(date);
      final end = schedule.shiftEndOn(date);
      if (!now.isBefore(start) && now.isBefore(end)) return end;
    }
    return null;
  }

  CountdownSnapshot snapshot(DateTime now) {
    final today = CalendarDate.fromDateTime(now);
    var validUntil = today.addDays(1).startOfDay;
    void until(DateTime? time) {
      if (time != null && time.isAfter(now) && time.isBefore(validUntil)) {
        validUntil = time;
      }
    }

    final hasForcedWorkdays = classifier.overrides.values.any(
      (o) => o.kind == OverrideKind.workday,
    );
    if (schedule.workdays.isEmpty && !hasForcedWorkdays) {
      return CountdownSnapshot(
        computedAt: now,
        state: const NoWorkdays(),
        blocks: const [],
        validUntil: validUntil,
      );
    }

    final all = blocks(now);
    if (all.isEmpty) {
      return CountdownSnapshot(
        computedAt: now,
        state: const NoDaysOff(),
        blocks: const [],
        validUntil: validUntil,
      );
    }

    final current = all.first;
    final CountdownState state;
    if (current.offStart == null || !current.offStart!.isAfter(now)) {
      state = OffNow(
        block: current,
        backToWork: current.offEnd,
        dayNumber: current.contains(today)
            ? current.first.daysUntil(today) + 1
            : null,
      );
      until(current.offEnd);
    } else {
      final inShift = currentShiftEnd(now);
      state = CountingDown(
        target: current.offStart!,
        block: current,
        inShiftUntil: inShift,
      );
      until(current.offStart);
      until(inShift);
      // A shift starting later today shows the "in shift" chip.
      if (_day(today).isWork) until(schedule.shiftStartOn(today));
    }

    final upcoming = all.where(
      (b) => b.offStart != null && b.offStart!.isAfter(now),
    );
    return CountdownSnapshot(
      computedAt: now,
      state: state,
      blocks: all,
      validUntil: validUntil,
      nextWeekend: upcoming.where((b) => b.hasScheduledOff).firstOrNull,
      nextHoliday: upcoming.where((b) => b.hasExtraOff).firstOrNull,
    );
  }
}
