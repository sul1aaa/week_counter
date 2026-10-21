import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../state/app_controller.dart';
import 'screens/calendar_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

enum AppTab { countdown, calendar, settings }

class RootShell extends StatefulWidget {
  const RootShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  AppTab _tab = AppTab.countdown;

  void _open(AppTab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _tab.index,
        children: [
          HomeScreen(controller: widget.controller, onOpenTab: _open),
          CalendarScreen(controller: widget.controller),
          SettingsScreen(controller: widget.controller),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab.index,
        onDestinationSelected: (i) => _open(AppTab.values[i]),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.hourglass_empty),
            selectedIcon: const Icon(Icons.hourglass_bottom),
            label: l10n.navCountdown,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: l10n.navCalendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
