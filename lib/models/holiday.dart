import 'package:flutter/foundation.dart';

import '../core/calendar_date.dart';

/// A public holiday as returned by the Nager.Date API.
@immutable
class Holiday {
  const Holiday({
    required this.date,
    required this.name,
    required this.localName,
    required this.countryCode,
    this.global = true,
    this.types = const ['Public'],
  });

  /// Parses one item of `GET /api/v3/PublicHolidays/{year}/{countryCode}`.
  factory Holiday.fromNager(Map<String, dynamic> json) => Holiday(
    date: CalendarDate.parse(json['date'] as String),
    name: json['name'] as String,
    localName: json['localName'] as String? ?? json['name'] as String,
    countryCode: json['countryCode'] as String,
    global: json['global'] as bool? ?? true,
    types: [for (final t in json['types'] as List? ?? const []) t as String],
  );

  final CalendarDate date;

  /// English name.
  final String name;

  /// Name in the country's own language.
  final String localName;
  final String countryCode;

  /// False for holidays observed only in some regions.
  final bool global;
  final List<String> types;

  /// Whether this holiday gives everyone in the country a day off.
  bool get isNationalDayOff => global && types.contains('Public');

  Map<String, dynamic> toJson() => {
    'date': date.toIso(),
    'name': name,
    'localName': localName,
    'countryCode': countryCode,
    'global': global,
    'types': types,
  };
}

@immutable
class Country {
  const Country(this.code, this.name);

  /// Parses one item of `GET /api/v3/AvailableCountries`.
  factory Country.fromNager(Map<String, dynamic> json) =>
      Country(json['countryCode'] as String, json['name'] as String);

  final String code;
  final String name;

  Map<String, dynamic> toJson() => {'countryCode': code, 'name': name};
}
