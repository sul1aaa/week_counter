import 'package:flutter/material.dart';

import '../../core/calendar_date.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../state/app_controller.dart';
import '../kit/app_page.dart';
import '../kit/buttons.dart';
import '../kit/controls.dart';
import '../kit/glass.dart';
import '../kit/group.dart';
import '../kit/orb.dart';
import '../theme/tokens.dart';

/// Plan time away: the days become days off and the countdown runs to the
/// day you're back.
class VacationScreen extends StatefulWidget {
  const VacationScreen({super.key, required this.controller});

  final AppController controller;

  static Future<void> open(BuildContext context, AppController controller) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VacationScreen(controller: controller),
        ),
      );

  @override
  State<VacationScreen> createState() => _VacationScreenState();
}

class _VacationScreenState extends State<VacationScreen> {
  int _days = 14;
  bool _fromMonday = true;

  AppController get _controller => widget.controller;

  CalendarDate get _today => CalendarDate.fromDateTime(_controller.clock());

  CalendarDate get _first {
    final today = _today;
    if (!_fromMonday) return today.addDays(1);
    final untilMonday = (DateTime.monday - today.weekday + 7) % 7;
    return today.addDays(untilMonday == 0 ? 7 : untilMonday);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: t.bg,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final vacation = _controller.vacation;
          final active = vacation != null;
          final started = active && vacation.first <= _today;
          final first = _first;
          final last = first.addDays(_days - 1);
          return Stack(
            children: [
              AppPage(
                title: l10n.vacationTitle,
                largeTitle: false,
                titleOnScroll: true,
                bottomPadding: bottom + 104,
                leading: GlassButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  label: l10n.back,
                  onTap: () => Navigator.of(context).pop(),
                ),
                children: [
                  const SizedBox(height: 8),
                  _Hero(
                    title: !active
                        ? l10n.vacationTitle
                        : started
                        ? l10n.vacationActive
                        : l10n.vacationPlanned,
                    body: !active
                        ? l10n.vacationIntro
                        : started
                        ? l10n.vacationActiveBody(l10n.dayMonth(vacation.last))
                        : l10n.vacationPlannedBody(
                            l10n.dayMonth(vacation.first),
                            l10n.dayMonth(vacation.last),
                          ),
                  ),
                  if (!active) ...[
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: MergeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.vacationTitle, style: t.footnote),
                            Text(
                              '${l10n.dayMonth(first)} – ${l10n.dayMonth(last)}',
                              style: TextStyle(
                                fontFamily: Fonts.display,
                                fontSize: 22,
                                height: 28 / 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.44,
                                color: t.ink,
                              ),
                            ),
                            Text(l10n.durationDays(_days), style: t.footnote),
                          ],
                        ),
                      ),
                    ),
                    GroupHeader(l10n.vacationHowLong),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Segmented<int>(
                        segments: [
                          for (final weeks in [1, 2, 3, 4])
                            (weeks * 7, l10n.vacationWeeks(weeks)),
                        ],
                        selected: _days,
                        onChanged: (days) => setState(() => _days = days),
                      ),
                    ),
                    GroupHeader(l10n.vacationFrom),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Segmented<bool>(
                        segments: [
                          (false, l10n.vacationFromTomorrow),
                          (true, l10n.vacationFromMonday),
                        ],
                        selected: _fromMonday,
                        onChanged: (monday) =>
                            setState(() => _fromMonday = monday),
                      ),
                    ),
                  ],
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BottomAction(
                  children: [
                    if (active)
                      AppButton(
                        label: started
                            ? l10n.vacationEndEarly
                            : l10n.vacationCancel,
                        kind: ButtonKind.secondary,
                        onTap: () async {
                          await _controller.cancelVacation();
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      )
                    else
                      AppButton(
                        label: l10n.vacationGo(l10n.durationDays(_days)),
                        onTap: () async {
                          await _controller.planVacation(
                            first,
                            _days,
                            l10n.vacationNote,
                          );
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Orb(size: 150, fill: 0.42, mode: OrbMode.paused, still: false),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: Fonts.display,
                fontSize: 28,
                height: 34 / 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.98,
                color: t.ink,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 310),
            child: Text(body, textAlign: TextAlign.center, style: t.callout),
          ),
        ],
      ),
    );
  }
}
