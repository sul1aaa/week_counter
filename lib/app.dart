import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'state/app_controller.dart';
import 'ui/root_shell.dart';

class WeekCounterApp extends StatefulWidget {
  const WeekCounterApp({super.key, required this.controller, this.locale});

  final AppController controller;

  /// Forces a language (tests); null follows the phone.
  final Locale? locale;

  @override
  State<WeekCounterApp> createState() => _WeekCounterAppState();
}

class _WeekCounterAppState extends State<WeekCounterApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.controller.onResume();
  }

  @override
  void didChangeLocales(List<Locale>? locales) =>
      widget.controller.onLocaleChanged();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      locale: widget.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RootShell(controller: widget.controller),
    );
  }
}

ThemeData _theme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF4F46E5),
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: scheme,
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    appBarTheme: const AppBarTheme(centerTitle: false),
  );
}
