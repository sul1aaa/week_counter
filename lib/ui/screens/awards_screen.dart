import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/calendar_date.dart';
import '../../domain/awards.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/award_copy.dart';
import '../../l10n/labels.dart';
import '../../state/app_controller.dart';
import '../kit/app_page.dart';
import '../kit/award_badge.dart';
import '../kit/pressable.dart';
import '../kit/sheet.dart';
import '../theme/tokens.dart';

/// How many weekends you waited out, and the badges for it.
class AwardsScreen extends StatelessWidget {
  const AwardsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final heroSize = (MediaQuery.sizeOf(context).width * 0.26)
        .clamp(72, 112)
        .toDouble();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final prefs = controller.prefs;
        final earned = [
          for (final a in awards)
            if (prefs.earned.containsKey(a.id)) a,
        ];
        return AppPage(
          title: l10n.navAwards,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      '${prefs.weeks}',
                      style: TextStyle(
                        fontFamily: Fonts.display,
                        fontSize: heroSize,
                        height: 0.85,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.06 * heroSize,
                        fontFeatures: Fonts.tabular,
                        color: t.ink,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      l10n.awardsHero,
                      textAlign: TextAlign.end,
                      style: t.callout.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  if (earned.isNotEmpty)
                    SizedBox(
                      width: 40 + 26.0 * (math.min(4, earned.length) - 1),
                      height: 40,
                      child: Stack(
                        children: [
                          for (final (i, a) in earned.take(4).indexed)
                            Positioned(
                              left: 26.0 * i,
                              child: AwardBadge(
                                award: a,
                                mark: awardCopy(l10n.localeName, a.id).mark,
                                size: 40,
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (earned.isNotEmpty) const SizedBox(width: 12),
                  Text(
                    earned.length > 4
                        ? l10n.awardsMore(earned.length - 4)
                        : l10n.awardsCount(earned.length),
                    style: t.callout,
                  ),
                ],
              ),
            ),
            _Section(
              title: l10n.awardsWeekly,
              awards: awards.where((a) => a.isWeekly).toList(),
              controller: controller,
            ),
            _Section(
              title: l10n.awardsSpecial,
              awards: awards.where((a) => !a.isWeekly).toList(),
              controller: controller,
            ),
          ],
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.awards,
    required this.controller,
  });

  final String title;
  final List<Award> awards;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final earned = controller.prefs.earned;
    final got = awards.where((a) => earned.containsKey(a.id)).length;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: t.sectionTitle),
                ),
                Text(
                  l10n.awardsProgress(got, awards.length),
                  style: t.footnote,
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, award) in awards.indexed) ...[
                    if (i > 0) const SizedBox(width: 12),
                    _AwardCard(award: award, controller: controller),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AwardCard extends StatelessWidget {
  const _AwardCard({required this.award, required this.controller});

  final Award award;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final copy = awardCopy(l10n.localeName, award.id);
    final at = controller.prefs.earned[award.id];
    final weeks = controller.prefs.weeks;
    return Pressable(
      onTap: () => showAwardSheet(context, controller, award),
      semanticLabel: at == null
          ? '${copy.name}, ${l10n.awardLocked}'
          : copy.name,
      child: Container(
        width: 132,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            AwardBadge(
              award: award,
              mark: copy.mark,
              size: 88,
              locked: at == null,
            ),
            const SizedBox(height: 8),
            Text(
              copy.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: Fonts.text,
                fontSize: 13,
                height: 17 / 13,
                fontWeight: FontWeight.w600,
                color: t.ink,
              ),
            ),
            const SizedBox(height: 8),
            if (at != null)
              Text(
                l10n.dayMonth(CalendarDate.fromDateTime(at)),
                style: t.footnote.copyWith(fontSize: 12, height: 16 / 12),
              )
            else if (award.isWeekly) ...[
              FractionallySizedBox(
                widthFactor: 0.8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: math.min(1, weeks / award.weeks!),
                    minHeight: 4,
                    backgroundColor: t.surface2,
                    color: Tokens.violet,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$weeks / ${award.weeks}',
                style: t.footnote.copyWith(fontSize: 12, height: 16 / 12),
              ),
            ] else
              Text(
                l10n.awardLocked,
                style: t.footnote.copyWith(fontSize: 12, height: 16 / 12),
              ),
          ],
        ),
      ),
    );
  }
}

/// One award up close: tilt it with a finger.
Future<void> showAwardSheet(
  BuildContext context,
  AppController controller,
  Award award,
) => showAppSheet<void>(
  context,
  builder: (_) => _AwardSheet(controller: controller, award: award),
);

class _AwardSheet extends StatefulWidget {
  const _AwardSheet({required this.controller, required this.award});

  final AppController controller;
  final Award award;

  @override
  State<_AwardSheet> createState() => _AwardSheetState();
}

class _AwardSheetState extends State<_AwardSheet> {
  Offset _tilt = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final award = widget.award;
    final copy = awardCopy(l10n.localeName, award.id);
    final at = widget.controller.prefs.earned[award.id];
    final weeks = widget.controller.prefs.weeks;
    final left = award.isWeekly ? award.weeks! - weeks : 0;
    final badge = AwardBadge(
      award: award,
      mark: copy.mark,
      size: 200,
      locked: at == null,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      child: Column(
        children: [
          GestureDetector(
            onPanUpdate: at == null
                ? null
                : (d) => setState(() {
                    _tilt = Offset(
                      (_tilt.dx + d.delta.dx / 200).clamp(-0.5, 0.5),
                      (_tilt.dy + d.delta.dy / 200).clamp(-0.5, 0.5),
                    );
                  }),
            onPanEnd: (_) => setState(() => _tilt = Offset.zero),
            child: TweenAnimationBuilder<Offset>(
              tween: Tween(end: _tilt),
              duration: const Duration(milliseconds: 120),
              builder: (context, tilt, child) => Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 1 / 600)
                  ..rotateX(-tilt.dy * 0.6)
                  ..rotateY(tilt.dx * 0.75),
                child: child,
              ),
              child: badge,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            copy.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: Fonts.display,
              fontSize: 28,
              height: 34 / 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.84,
              color: t.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            at != null
                ? l10n.awardEarnedOn(
                    l10n.dayMonth(CalendarDate.fromDateTime(at)),
                  )
                : award.isWeekly
                ? l10n.awardWeeksLeft(l10n.weeksCount(left))
                : l10n.awardLocked,
            style: t.mono,
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              at == null && copy.how.isNotEmpty ? copy.how : copy.why,
              textAlign: TextAlign.center,
              style: t.body.copyWith(color: t.ink2, height: 23 / 17),
            ),
          ),
          if (at == null && award.isWeekly) ...[
            const SizedBox(height: 16),
            FractionallySizedBox(
              widthFactor: 0.7,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: math.min(1, weeks / award.weeks!),
                  minHeight: 6,
                  backgroundColor: t.surface2,
                  color: Tokens.violet,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
