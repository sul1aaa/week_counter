import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../models/holiday.dart';
import '../../state/app_controller.dart';
import '../kit/app_page.dart';
import '../kit/buttons.dart';
import '../kit/glass.dart';
import '../kit/group.dart';
import '../theme/tokens.dart';

/// Flag emoji for an ISO 3166-1 alpha-2 code.
String countryFlag(String code) => String.fromCharCodes(
  code.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 0x41),
);

class CountryPickerScreen extends StatefulWidget {
  const CountryPickerScreen({super.key, required this.controller});

  final AppController controller;

  static Future<void> open(BuildContext context, AppController controller) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CountryPickerScreen(controller: controller),
        ),
      );

  @override
  State<CountryPickerScreen> createState() => _CountryPickerScreenState();
}

class _CountryPickerScreenState extends State<CountryPickerScreen> {
  late Future<List<Country>> _countries;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _countries = _load();
  }

  Future<List<Country>> _load() {
    final cached = widget.controller.countries;
    return cached != null
        ? Future.value(cached)
        : widget.controller.loadCountries();
  }

  void _select(String? code) {
    widget.controller.setCountry(code);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final current = widget.controller.settings.countryCode;
    return Scaffold(
      backgroundColor: t.bg,
      body: FutureBuilder<List<Country>>(
        future: _countries,
        builder: (context, snapshot) {
          final countries = snapshot.data;
          String name(Country c) => l10n.countryLabel(c.code, c.name);
          final matches =
              (countries ?? const <Country>[])
                  .where(
                    (c) =>
                        _query.isEmpty ||
                        name(c).toLowerCase().contains(_query) ||
                        c.name.toLowerCase().contains(_query) ||
                        c.code.toLowerCase() == _query,
                  )
                  .toList()
                ..sort((a, b) => name(a).compareTo(name(b)));
          return AppPage(
            title: l10n.country,
            bottomPadding: MediaQuery.paddingOf(context).bottom + 24,
            leading: GlassButton(
              icon: Icons.arrow_back_ios_new_rounded,
              label: l10n.back,
              onTap: () => Navigator.of(context).pop(),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: CupertinoSearchTextField(
                  autofocus: true,
                  placeholder: l10n.searchCountry,
                  style: t.body,
                  backgroundColor: t.surface2,
                  borderRadius: BorderRadius.circular(12),
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                ),
              ),
              if (snapshot.hasError)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text(
                        l10n.loadFailed,
                        textAlign: TextAlign.center,
                        style: t.callout,
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: l10n.retry,
                        kind: ButtonKind.secondary,
                        expand: false,
                        onTap: () => setState(
                          () => _countries = widget.controller.loadCountries(),
                        ),
                      ),
                    ],
                  ),
                )
              else if (countries == null)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: CupertinoActivityIndicator(),
                )
              else
                Group(
                  children: [
                    if (_query.isEmpty)
                      GroupRow(
                        icon: Icons.block_rounded,
                        title: l10n.noCountryOption,
                        selected: current == null,
                        onTap: () => _select(null),
                      ),
                    for (final country in matches)
                      GroupRow(
                        leading: SizedBox(
                          width: 28,
                          child: Text(
                            countryFlag(country.code),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                        title: name(country),
                        subtitle: country.code,
                        selected: country.code == current,
                        onTap: () => _select(country.code),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
