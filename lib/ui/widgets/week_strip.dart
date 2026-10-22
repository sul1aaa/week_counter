import 'package:flutter/material.dart';

import '../../core/calendar_date.dart';
import '../../domain/day_classifier.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../models/work_schedule.dart';
import '../theme/tokens.dart';

/// First day of the week for the current locale, as [DateTime.monday]…
/// [DateTime.sunday].
int firstWeekday(BuildContext context) {
  // MaterialLocalizations counts from Sunday = 0.
  final index = MaterialLocalizations.of(context).firstDayOfWeekIndex;
  return index == 0 ? DateTime.sunday : index;
}

/// The seven days of the week containing [today], starting at [first].
List<CalendarDate> weekOf(CalendarDate today, int first) {
  final start = today.addDays(-((today.weekday - first + 7) % 7));
  return [for (var i = 0; i < 7; i++) start.addDays(i)];
}

/// This week at a glance: workdays fill with violet as they pass, days off
/// are lime.
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.days,
    required this.schedule,
    required this.now,
    required this.offNow,
  });

  final List<DayInfo> days;
  final WorkSchedule schedule;
  final DateTime now;

  /// Highlights today in full lime while off.
  final bool offNow;

  double _fill(DayInfo day) {
    if (day.isOff) return 0;
    final start = schedule.shiftStartOn(day.date);
    final end = schedule.shiftEndOn(day.date);
    final done =
        now.difference(start).inMilliseconds /
        end.difference(start).inMilliseconds;
    return done.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final today = CalendarDate.fromDateTime(now);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final (i, day) in days.indexed) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: _DayCell(
                day: day,
                fill: _fill(day),
                today: day.date == today,
                offNow: offNow,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.fill,
    required this.today,
    required this.offNow,
  });

  final DayInfo day;
  final double fill;
  final bool today;
  final bool offNow;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l10n = AppLocalizations.of(context);
    final holiday = day.reasons.contains(OffReason.publicHoliday);
    final ownDayOff = day.isExtraOff && day.reasons.contains(OffReason.custom);
    final done = day.isWork && fill >= 1;

    Color background = t.surface;
    Color number = t.ink;
    if (ownDayOff) {
      number = t.ink2;
    } else if (day.isOff) {
      background = today && offNow ? Tokens.lime : t.limeSoft;
      number = today && offNow ? const Color(0xFF111111) : t.limeInk;
    } else if (done) {
      number = Colors.white;
    }

    final status = day.isWork
        ? (today
              ? '${l10n.statusWorkday}, ${(fill * 100).round()}%'
              : l10n.statusWorkday)
        : holiday
        ? day.holidays.map(l10n.holidayName).join(', ')
        : l10n.statusDayOff;

    return Semantics(
      label: '${l10n.longDate(day.date)}, $status',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            l10n.weekdayCaps(day.date.weekday),
            style: TextStyle(
              fontFamily: Fonts.text,
              fontSize: 11,
              height: 14 / 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.22,
              color: today ? t.ink : t.ink2,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 58),
            child: AspectRatio(
              aspectRatio: 1 / 1.32,
              child: Container(
                clipBehavior: Clip.antiAlias,
                foregroundDecoration: today
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: t.ink, width: 2),
                      )
                    : null,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    if (ownDayOff)
                      Positioned.fill(
                        child: CustomPaint(painter: StripesPainter(t.surface2)),
                      ),
                    if (day.isWork)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: fill),
                          duration: const Duration(seconds: 1),
                          curve: Motion.ios,
                          builder: (context, value, _) => FractionallySizedBox(
                            heightFactor: value,
                            widthFactor: 1,
                            child: const ColoredBox(color: Tokens.violet),
                          ),
                        ),
                      ),
                    if (holiday)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: t.ink,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    Center(
                      child: Container(
                        padding: today && day.isWork && !done
                            ? const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              )
                            : EdgeInsets.zero,
                        decoration: today && day.isWork && !done
                            ? BoxDecoration(
                                color: t.surface,
                                borderRadius: BorderRadius.circular(9),
                              )
                            : null,
                        child: Text(
                          '${day.date.day}',
                          style: TextStyle(
                            fontFamily: Fonts.display,
                            fontSize: 17,
                            height: 1,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                            fontFeatures: Fonts.tabular,
                            color: number,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Diagonal stripes for the user's own days off (vacation and the like).
class StripesPainter extends CustomPainter {
  const StripesPainter(this.color, {this.gap = 6});

  final Color color;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = gap * 0.7;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var x = -size.height; x < size.width; x += gap * 2) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(StripesPainter old) =>
      old.color != color || old.gap != gap;
}
