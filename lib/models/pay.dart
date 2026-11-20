import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

enum PayPeriod { hour, day, week, twoWeeks, month }

/// What the user earns, for the money ticker on the day orb.
@immutable
class Pay {
  const Pay({
    this.on = false,
    this.period = PayPeriod.month,
    this.amount = 0,
    this.currency = '',
  });

  factory Pay.fromJson(Map<String, dynamic> json) => Pay(
    on: json['on'] as bool? ?? false,
    period: PayPeriod.values.byName(json['period'] as String),
    amount: (json['amount'] as num).toDouble(),
    currency: json['currency'] as String? ?? '',
  );

  /// The ticker is switched on. The amount stays when it's switched off.
  final bool on;
  final PayPeriod period;

  /// Per [period]; zero until the user enters it.
  final double amount;

  /// A symbol or short code, e.g. ₸ or USD.
  final String currency;

  /// Switched on and with an amount to count.
  bool get ticks => on && amount > 0;

  Pay copyWith({
    bool? on,
    PayPeriod? period,
    double? amount,
    String? currency,
  }) => Pay(
    on: on ?? this.on,
    period: period ?? this.period,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
  );

  Map<String, dynamic> toJson() => {
    'on': on,
    'period': period.name,
    'amount': amount,
    'currency': currency,
  };

  @override
  bool operator ==(Object other) =>
      other is Pay &&
      other.on == on &&
      other.period == period &&
      other.amount == amount &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(on, period, amount, currency);
}

/// Countries that pay in euros.
const _euro = {
  'AT',
  'BE',
  'CY',
  'DE',
  'EE',
  'ES',
  'FI',
  'FR',
  'GR',
  'HR',
  'IE',
  'IT',
  'LT',
  'LU',
  'LV',
  'MT',
  'NL',
  'PT',
  'SI',
  'SK',
};

const _symbols = {
  'KZ': '₸',
  'RU': '₽',
  'BY': 'Br',
  'UA': '₴',
  'US': r'$',
  'GB': '£',
  'TR': '₺',
  'PL': 'zł',
  'GE': '₾',
  'AM': '֏',
  'AZ': '₼',
  'KG': 'сом',
  'UZ': 'soʻm',
};

/// The currency symbol for [countryCode], or the one of [locale] for
/// countries not listed.
String guessCurrency(String? countryCode, String locale) =>
    _symbols[countryCode] ??
    (_euro.contains(countryCode)
        ? '€'
        : NumberFormat.simpleCurrency(locale: locale).currencySymbol);
