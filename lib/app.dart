import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'state/app_controller.dart';
import 'ui/root_shell.dart';
import 'ui/theme/tokens.dart';

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
  final t = brightness == Brightness.dark ? Tokens.dark : Tokens.light;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Tokens.violet,
        brightness: brightness,
      ).copyWith(
        primary: t.violetInk,
        onPrimary: brightness == Brightness.dark ? Colors.black : Colors.white,
        surface: t.bg,
        onSurface: t.ink,
        onSurfaceVariant: t.ink2,
        error: t.danger,
        outline: t.ink3,
        outlineVariant: t.line,
      );
  const transitions = CupertinoPageTransitionsBuilder();
  return ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: t.bg,
    canvasColor: t.bg,
    fontFamily: Fonts.text,
    extensions: [t],
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Tokens.violet,
      selectionColor: Tokens.violet.withValues(alpha: 0.3),
      selectionHandleColor: Tokens.violet,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: t.inverse,
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: TextStyle(color: t.onInverse, fontSize: 13),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: transitions,
        TargetPlatform.iOS: transitions,
        TargetPlatform.macOS: transitions,
        TargetPlatform.linux: transitions,
        TargetPlatform.windows: transitions,
        TargetPlatform.fuchsia: transitions,
      },
    ),
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: brightness,
      primaryColor: Tokens.violet,
    ),
  );
}
