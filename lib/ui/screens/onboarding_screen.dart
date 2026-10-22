import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../state/app_controller.dart';
import '../kit/app_page.dart';
import '../kit/buttons.dart';
import '../kit/glass.dart';
import '../kit/group.dart';
import '../kit/orb.dart';
import '../kit/pressable.dart';
import '../kit/strike.dart';
import '../theme/tokens.dart';
import '../widgets/schedule_controls.dart';
import '../widgets/widget_sheet.dart';
import 'country_picker_screen.dart';

/// First launch: a welcome screen, then the work week in three steps.
/// Changes apply right away; skipping keeps the defaults.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, required this.controller});

  final AppController controller;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _navigator = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return NavigatorPopHandler(
      onPopWithResult: (_) => _navigator.currentState?.maybePop(),
      child: Navigator(
        key: _navigator,
        onGenerateRoute: (_) => CupertinoPageRoute<void>(
          builder: (_) => _Welcome(controller: widget.controller),
        ),
      ),
    );
  }
}

void _push(BuildContext context, Widget page) =>
    Navigator.of(context).push(CupertinoPageRoute<void>(builder: (_) => page));

class _Welcome extends StatelessWidget {
  const _Welcome({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final headline = TextStyle(
      fontFamily: Fonts.display,
      fontSize: 40,
      height: 42 / 40,
      fontWeight: FontWeight.w700,
      letterSpacing: -1,
      color: t.ink,
    );
    return Scaffold(
      backgroundColor: t.bg,
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              // Centered on tall screens, scrolls on short ones.
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 52, 16, 120),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 172,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Orb(
                          size: math.min(
                            200,
                            MediaQuery.sizeOf(context).width * 0.5,
                          ),
                          fill: 0.62,
                          semanticLabel: l10n.orbTip,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(l10n.appTitle, style: _stepStyle(t)),
                      const SizedBox(height: 8),
                      Semantics(
                        header: true,
                        label:
                            '${l10n.onbWelcomePrefix} ${l10n.onbWelcomeStrike} '
                            '${l10n.onbWelcomeSuffix}',
                        excludeSemantics: true,
                        child: Wrap(
                          spacing: 10,
                          children: [
                            Text(l10n.onbWelcomePrefix, style: headline),
                            StrikeText(
                              l10n.onbWelcomeStrike,
                              style: headline.copyWith(color: t.ink3),
                            ),
                            Text(l10n.onbWelcomeSuffix, style: headline),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.onbWelcomeBody,
                        style: t.body.copyWith(color: t.ink2, height: 23 / 17),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: NavBar(
              showFade: false,
              trailing: _TextGlassButton(
                label: l10n.onbSkip,
                onTap: controller.completeOnboarding,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomAction(
              children: [
                AppButton(
                  label: l10n.onbStart,
                  onTap: () =>
                      _push(context, _TypeStep(controller: controller)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle _stepStyle(Tokens t) => t.mono.copyWith(fontWeight: FontWeight.w600);

/// The frame of a numbered step: back button, progress, title, content and
/// the actions at the bottom.
class _Step extends StatelessWidget {
  const _Step({
    required this.step,
    required this.title,
    required this.children,
    required this.actions,
  });

  final int step;
  final String title;
  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bg,
      body: Stack(
        children: [
          AppPage(
            largeTitle: false,
            bottomPadding: MediaQuery.paddingOf(context).bottom + 150,
            leading: GlassButton(
              icon: Icons.arrow_back_ios_new_rounded,
              label: l10n.back,
              onTap: () => Navigator.of(context).pop(),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Row(
                        children: [
                          for (var i = 1; i <= 3; i++) ...[
                            if (i > 1) const SizedBox(width: 4),
                            Expanded(child: _ProgressBar(filled: i <= step)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.onbStep(step, 3), style: _stepStyle(t)),
                    const SizedBox(height: 8),
                    FractionallySizedBox(
                      widthFactor: 0.92,
                      child: Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: Fonts.display,
                            fontSize: 34,
                            height: 38 / 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.85,
                            color: t.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...children,
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomAction(children: actions),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: t.surface3),
            if (filled)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Motion.slow,
                curve: Motion.ios,
                builder: (context, v, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: v,
                  child: ColoredBox(color: t.ink),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const _fiveDays = {1, 2, 3, 4, 5};

class _TypeStep extends StatefulWidget {
  const _TypeStep({required this.controller});

  final AppController controller;

  @override
  State<_TypeStep> createState() => _TypeStepState();
}

class _TypeStepState extends State<_TypeStep> {
  late bool _custom = !_isFiveDay;

  bool get _isFiveDay {
    final days = widget.controller.settings.schedule.workdays;
    return days.length == 5 && days.containsAll(_fiveDays);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = widget.controller;
    return _Step(
      step: 1,
      title: l10n.onbTypeTitle,
      actions: [
        AppButton(
          label: l10n.onbNext,
          onTap: () => _push(context, _TimeStep(controller: controller)),
        ),
      ],
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Column(
            children: [
              _Option(
                badge: '5/2',
                title: l10n.onbFiveDay,
                subtitle: l10n.onbFiveDayHint,
                selected: !_custom,
                onTap: () {
                  setState(() => _custom = false);
                  controller.updateSchedule(
                    controller.settings.schedule.copyWith(workdays: _fiveDays),
                  );
                },
              ),
              const SizedBox(height: 8),
              _Option(
                badge: '?/?',
                title: l10n.onbCustom,
                subtitle: l10n.onbCustomHint,
                selected: _custom,
                onTap: () => setState(() => _custom = true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String badge;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: Pressable(
        onTap: onTap,
        scale: 0.985,
        child: AnimatedContainer(
          duration: Motion.fast,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? t.ink : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.surface2,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontFamily: Fonts.display,
                    fontSize: 22,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.88,
                    color: t.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: t.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: t.callout),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: Motion.fast,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? t.ink : t.surface3,
                    width: selected ? 7 : 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeStep extends StatelessWidget {
  const _TimeStep({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final schedule = controller.settings.schedule;
        final code = controller.settings.countryCode;
        return _Step(
          step: 2,
          title: l10n.onbTimeTitle,
          actions: [
            AppButton(
              label: l10n.onbNext,
              onTap: schedule.workdays.isEmpty
                  ? null
                  : () => _push(context, _WidgetStep(controller: controller)),
            ),
          ],
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: DaysPicker(
                weekdays: orderedWeekdays(context),
                workdays: schedule.workdays,
                onToggle: (day) => controller.updateSchedule(
                  schedule.copyWith(
                    workdays: schedule.workdays.contains(day)
                        ? ({...schedule.workdays}..remove(day))
                        : {...schedule.workdays, day},
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(l10n.workdaysHint, style: t.footnote),
            ),
            Group(children: weekTimeRows(context, controller)),
            const SizedBox(height: 16),
            Group(
              children: [
                GroupRow(
                  title: l10n.holidaysShort,
                  subtitle: l10n.holidaysShortHint,
                  value: code == null
                      ? l10n.noCountry
                      : l10n.countryLabel(code, controller.countryName(code)),
                  onTap: () => CountryPickerScreen.open(context, controller),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _WidgetStep extends StatelessWidget {
  const _WidgetStep({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    return _Step(
      step: 3,
      title: l10n.widgetTipTitle,
      actions: [
        AppButton(
          label: l10n.onbHowToWidget,
          onTap: () async {
            await showWidgetSheet(context, controller);
            await controller.completeOnboarding();
          },
        ),
        AppButton(
          label: l10n.onbNotNow,
          kind: ButtonKind.ghost,
          onTap: controller.completeOnboarding,
        ),
      ],
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            l10n.onbWidgetBody,
            style: t.body.copyWith(color: t.ink2, height: 23 / 17),
          ),
        ),
        const SizedBox(height: 24),
        Center(child: _PhoneMock(controller: controller)),
      ],
    );
  }
}

/// A tilted phone with the widget on its home screen.
class _PhoneMock extends StatelessWidget {
  const _PhoneMock({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final width = math.min(214.0, MediaQuery.sizeOf(context).width * 0.56);
    return ExcludeSemantics(
      child: Transform.rotate(
        angle: -3 * math.pi / 180,
        child: Container(
          width: width,
          height: width * 16 / 9,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: t.surface2, width: 6),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 60,
                spreadRadius: -20,
                offset: Offset(0, 30),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 28),
              WidgetPreview(
                snapshot: controller.snapshot,
                now: controller.clock(),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    for (var i = 0; i < 12; i++)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: t.surface2,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A glass pill with a text label, like "Skip".
class _TextGlassButton extends StatelessWidget {
  const _TextGlassButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onTap,
      scale: 0.92,
      child: SizedBox(
        height: 44,
        child: Glass(
          shadow: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                label,
                style: t.navTitle.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
