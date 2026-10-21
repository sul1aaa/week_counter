import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_controller.dart';
import '../root_shell.dart';
import '../widgets/block_cards.dart';
import '../widgets/hero_countdown_card.dart';
import '../widgets/status_banner.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final snapshot = _controller.snapshot;
        final now = _controller.clock();
        final missing = _controller.missingYears;
        final upcoming = snapshot.upcoming.take(10).toList();
        return Scaffold(
          appBar: AppBar(title: Text(l10n.appTitle)),
          body: RefreshIndicator(
            onRefresh: () => _controller.refreshHolidays(force: true),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (_controller.settings.countryCode == null) ...[
                  StatusBanner(
                    icon: Icons.public,
                    message: l10n.pickCountryBanner,
                    action: l10n.chooseCountry,
                    onAction: () => CountryPickerScreen.open(
                      context,
                      _controller,
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else if (missing.isNotEmpty) ...[
                  StatusBanner(
                    icon: Icons.cloud_off,
                    message: l10n.holidaysNotLoaded(missing.join(', ')),
                    action: l10n.retry,
                    onAction: () => _controller.refreshHolidays(force: true),
                  ),
                  const SizedBox(height: 12),
                ],
                HeroCountdownCard(
                  snapshot: snapshot,
                  now: now,
                  onOpenSettings: () => widget.onOpenTab(AppTab.settings),
                  onOpenCalendar: () => widget.onOpenTab(AppTab.calendar),
                ),
                if (snapshot.blocks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: BlockCard(
                            title: l10n.nextWeekend,
                            icon: Icons.weekend_outlined,
                            block: snapshot.nextWeekend,
                            now: now,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: BlockCard(
                            title: l10n.nextHoliday,
                            icon: Icons.celebration_outlined,
                            block: snapshot.nextHoliday,
                            now: now,
                            loading:
                                _controller.loadingHolidays &&
                                _controller.holidays.byDate.isEmpty,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (upcoming.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
                    child: Text(
                      l10n.upcomingDaysOff,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  UpcomingList(blocks: upcoming, now: now),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
