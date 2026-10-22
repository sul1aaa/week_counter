import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'local_store.dart';

/// Small bits of UI state that survive restarts.
@immutable
class UiPrefs {
  const UiPrefs({
    this.onboarded = true,
    this.celebratedUntil,
    this.countedUntil,
    this.weeks = 0,
    this.earned = const {},
    this.widgetTipDone = false,
    this.orbTipDone = false,
    this.confetti = true,
  });

  factory UiPrefs.fromJson(Map<String, dynamic> json) {
    DateTime? time(Object? ms) =>
        ms is int ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
    return UiPrefs(
      // Older versions had no onboarding, so their users have seen the app.
      onboarded: json['onboarded'] as bool? ?? true,
      celebratedUntil: time(json['celebratedUntil']),
      countedUntil: time(json['countedUntil']),
      weeks: json['weeks'] as int? ?? 0,
      earned: {
        for (final e in (json['earned'] as Map<String, dynamic>? ?? {}).entries)
          e.key: ?time(e.value),
      },
      widgetTipDone: json['widgetTipDone'] as bool? ?? false,
      orbTipDone: json['orbTipDone'] as bool? ?? false,
      confetti: json['confetti'] as bool? ?? true,
    );
  }

  final bool onboarded;

  /// Start of the latest time off that was already celebrated.
  final DateTime? celebratedUntil;

  /// Time off that started up to here is already in [weeks].
  final DateTime? countedUntil;

  /// How many times time off has started since the app was installed.
  final int weeks;

  /// Award id → when it was earned.
  final Map<String, DateTime> earned;

  /// The "add a widget" card on the home screen was dismissed.
  final bool widgetTipDone;

  /// The orb was tapped at least once, so its hint can go.
  final bool orbTipDone;

  /// Confetti and the flood on the "Weekend!" screen.
  final bool confetti;

  UiPrefs copyWith({
    bool? onboarded,
    DateTime? celebratedUntil,
    DateTime? countedUntil,
    int? weeks,
    Map<String, DateTime>? earned,
    bool? widgetTipDone,
    bool? orbTipDone,
    bool? confetti,
  }) => UiPrefs(
    onboarded: onboarded ?? this.onboarded,
    celebratedUntil: celebratedUntil ?? this.celebratedUntil,
    countedUntil: countedUntil ?? this.countedUntil,
    weeks: weeks ?? this.weeks,
    earned: earned ?? this.earned,
    widgetTipDone: widgetTipDone ?? this.widgetTipDone,
    orbTipDone: orbTipDone ?? this.orbTipDone,
    confetti: confetti ?? this.confetti,
  );

  Map<String, dynamic> toJson() => {
    'onboarded': onboarded,
    'celebratedUntil': celebratedUntil?.millisecondsSinceEpoch,
    'countedUntil': countedUntil?.millisecondsSinceEpoch,
    'weeks': weeks,
    'earned': {
      for (final e in earned.entries) e.key: e.value.millisecondsSinceEpoch,
    },
    'widgetTipDone': widgetTipDone,
    'orbTipDone': orbTipDone,
    'confetti': confetti,
  };
}

class PrefsRepository {
  PrefsRepository(this._store);

  static const _key = 'ui.v1';

  final LocalStore _store;

  /// Saved prefs, or null on first launch.
  Future<UiPrefs?> load() async {
    final raw = await _store.getString(_key);
    if (raw == null) return null;
    try {
      return UiPrefs.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return const UiPrefs();
    }
  }

  Future<void> save(UiPrefs prefs) =>
      _store.setString(_key, jsonEncode(prefs.toJson()));
}
