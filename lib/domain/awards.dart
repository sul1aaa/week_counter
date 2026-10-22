import 'package:flutter/foundation.dart';

enum AwardShape { circle, hex, shield, octagon, star }

enum Enamel { violet, lime, silver }

/// A badge for waiting out weeks, or for something special along the way.
@immutable
class Award {
  const Award(this.id, this.shape, this.enamel, {this.weeks});

  final String id;
  final AwardShape shape;
  final Enamel enamel;

  /// Earned after this many weekends; null for special awards.
  final int? weeks;

  bool get isWeekly => weeks != null;
}

const awards = [
  Award('w1', AwardShape.circle, Enamel.violet, weeks: 1),
  Award('w4', AwardShape.hex, Enamel.lime, weeks: 4),
  Award('w10', AwardShape.shield, Enamel.violet, weeks: 10),
  Award('w26', AwardShape.octagon, Enamel.lime, weeks: 26),
  Award('w52', AwardShape.star, Enamel.silver, weeks: 52),
  // Time off started on Friday the 13th.
  Award('friday13', AwardShape.hex, Enamel.violet),
  // A public holiday took a workday out of the week.
  Award('shortWeek', AwardShape.circle, Enamel.lime),
  // The week ended with a night shift.
  Award('nightShift', AwardShape.shield, Enamel.silver),
  // Planned a vacation.
  Award('vacation', AwardShape.octagon, Enamel.lime),
  // Had the app open in the last minute of the week.
  Award('lastMinute', AwardShape.star, Enamel.violet),
  // Went through the widget setup.
  Award('widget', AwardShape.circle, Enamel.silver),
];

Award awardById(String id) => awards.firstWhere((a) => a.id == id);

/// The next weekly award still to earn after [weeks], or null when all are
/// earned.
Award? nextWeeklyAward(int weeks) =>
    awards.where((a) => a.isWeekly && a.weeks! > weeks).firstOrNull;
