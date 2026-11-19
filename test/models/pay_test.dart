import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:week_counter/models/app_settings.dart';
import 'package:week_counter/models/pay.dart';

void main() {
  test('pay survives a save', () {
    const pay = Pay(
      on: true,
      period: PayPeriod.hour,
      amount: 12.5,
      currency: r'$',
    );
    final saved = jsonDecode(jsonEncode(pay.toJson())) as Map<String, dynamic>;
    expect(Pay.fromJson(saved), pay);
  });

  test('settings keep the pay', () {
    const settings = AppSettings(pay: Pay(amount: 400000, currency: '₸'));
    final saved =
        jsonDecode(jsonEncode(settings.toJson())) as Map<String, dynamic>;
    expect(AppSettings.fromJson(saved).pay, settings.pay);
  });

  test('settings saved before the money ticker still load', () {
    final settings = AppSettings.fromJson({
      'countryCode': 'KZ',
      'schedule': {
        'workdays': [1, 2, 3, 4, 5],
        'defaultShift': {'start': '09:00', 'end': '18:00'},
      },
      'overrides': <String, dynamic>{},
    });
    expect(settings.pay, isNull);
    expect(settings.toJson(), isNot(contains('pay')));
  });

  test('is ticking only when on and with an amount', () {
    expect(const Pay(amount: 100).ticks, isFalse);
    expect(const Pay(on: true).ticks, isFalse);
    expect(const Pay(on: true, amount: 100).ticks, isTrue);
  });

  test('guesses the currency from the country, then the language', () {
    expect(guessCurrency('KZ', 'ru'), '₸');
    expect(guessCurrency('RU', 'en'), '₽');
    expect(guessCurrency('DE', 'en'), '€');
    expect(guessCurrency(null, 'en'), r'$');
    expect(guessCurrency(null, 'ru'), isNotEmpty);
  });
}
