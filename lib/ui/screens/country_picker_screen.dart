import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/holiday.dart';
import '../../state/app_controller.dart';

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
    final current = widget.controller.settings.countryCode;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.searchCountry,
            border: InputBorder.none,
          ),
          onChanged: (value) => setState(() => _query = value.toLowerCase()),
        ),
      ),
      body: FutureBuilder<List<Country>>(
        future: _countries,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.loadFailed),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => setState(
                      () => _countries = widget.controller.loadCountries(),
                    ),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }
          final countries = snapshot.data;
          if (countries == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final matches = countries.where(
            (c) =>
                _query.isEmpty ||
                c.name.toLowerCase().contains(_query) ||
                c.code.toLowerCase() == _query,
          );
          return ListView(
            children: [
              if (_query.isEmpty)
                ListTile(
                  leading: const Icon(Icons.block),
                  title: Text(l10n.noCountryOption),
                  trailing: current == null ? const Icon(Icons.check) : null,
                  onTap: () => _select(null),
                ),
              for (final country in matches)
                ListTile(
                  leading: Text(
                    countryFlag(country.code),
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(country.name),
                  subtitle: Text(country.code),
                  trailing: country.code == current
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => _select(country.code),
                ),
            ],
          );
        },
      ),
    );
  }
}
