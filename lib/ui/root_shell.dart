import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/awards.dart';
import '../l10n/app_localizations.dart';
import '../state/app_controller.dart';
import 'kit/glass.dart';
import 'kit/pressable.dart';
import 'screens/awards_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/celebrate_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/tokens.dart';

enum AppTab { countdown, calendar, awards }

class RootShell extends StatefulWidget {
  const RootShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  AppTab _tab = AppTab.countdown;
  bool _celebrating = false;

  AppController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCelebrate());
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    super.dispose();
  }

  void _open(AppTab tab) => setState(() => _tab = tab);

  void _onChange() {
    // Onboarding ends by changing prefs, which swaps in the tabs.
    if (_shownOnboarded != _controller.prefs.onboarded) setState(() {});
    _maybeCelebrate();
  }

  /// Whether the last build showed the tabs rather than onboarding.
  bool _shownOnboarded = true;

  /// Throws the party once each time off starts, whichever tab is open.
  Future<void> _maybeCelebrate() async {
    final block = _controller.celebrationDue;
    if (block == null ||
        _celebrating ||
        !mounted ||
        !_controller.prefs.onboarded) {
      return;
    }
    _celebrating = true;
    await _controller.markCelebrated(block);
    if (!mounted) return;
    final award = await CelebrateScreen.open(
      context,
      _controller,
      block,
      award: _controller.takeFreshAward(),
    );
    _celebrating = false;
    if (!mounted) return;
    if (award == null) {
      _open(AppTab.countdown);
    } else {
      _open(AppTab.awards);
      await showAwardSheet(context, _controller, awardById(award));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final bottom = MediaQuery.paddingOf(context).bottom;
    _shownOnboarded = _controller.prefs.onboarded;
    if (!_shownOnboarded) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: t.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: OnboardingFlow(controller: _controller),
      );
    }
    final screens = [
      HomeScreen(controller: _controller, onOpenTab: _open),
      CalendarScreen(controller: _controller),
      AwardsScreen(controller: _controller),
    ];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: t.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: t.bg,
        body: Stack(
          children: [
            // Android's back button returns to Week before it closes the app.
            PopScope(
              canPop: _tab == AppTab.countdown,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) _open(AppTab.countdown);
              },
              child: IndexedStack(
                index: _tab.index,
                children: [
                  for (final (i, screen) in screens.indexed)
                    TickerMode(enabled: i == _tab.index, child: screen),
                ],
              ),
            ),
            // Content fades out under the floating tab bar.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: bottom + 96,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [t.bg.withAlpha(0), t.bg, t.bg],
                      stops: const [0, 0.7, 1],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              // iOS tucks the bar into the home indicator's inset. Android's
              // navigation buttons and gesture handle live in that inset, so
              // the bar sits above it.
              bottom: bottom == 0
                  ? 12
                  : defaultTargetPlatform == TargetPlatform.android
                  ? bottom + 8
                  : (bottom - 13).clamp(8, 48),
              child: Center(
                child: _TabBar(
                  selected: _tab,
                  onSelect: _open,
                  items: [
                    (Icons.timer_rounded, l10n.navCountdown),
                    (Icons.calendar_month_rounded, l10n.navCalendar),
                    (Icons.emoji_events_rounded, l10n.navAwards),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS 26 tab bar: a floating glass capsule with a sliding highlight.
class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.selected,
    required this.onSelect,
    required this.items,
  });

  final AppTab selected;
  final ValueChanged<AppTab> onSelect;
  final List<(IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final width = (MediaQuery.sizeOf(context).width - 42).clamp(0.0, 330.0);
    final tabWidth = (width - 8) / items.length;
    return Semantics(
      container: true,
      child: SizedBox(
        width: width,
        height: 62,
        child: Glass(
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: Motion.mid,
                  curve: Motion.ios,
                  left: tabWidth * selected.index,
                  top: 0,
                  bottom: 0,
                  width: tabWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: t.surface2,
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final (i, (icon, label)) in items.indexed)
                      Expanded(
                        child: Semantics(
                          selected: i == selected.index,
                          child: Pressable(
                            key: ValueKey('tab.${AppTab.values[i].name}'),
                            scale: 0.92,
                            onTap: () => onSelect(AppTab.values[i]),
                            child: _TabItem(
                              icon: icon,
                              label: label,
                              selected: i == selected.index,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = selected ? t.violetInk : t.ink;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: Fonts.text,
            fontSize: 10,
            height: 12 / 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
