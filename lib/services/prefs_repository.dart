import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'local_store.dart';

/// Small bits of UI state that survive restarts.
@immutable
class UiPrefs {
  const UiPrefs({
    this.celebratedUntil,
    this.widgetTipDone = false,
    this.orbTipDone = false,
  });

  factory UiPrefs.fromJson(Map<String, dynamic> json) => UiPrefs(
    celebratedUntil: switch (json['celebratedUntil']) {
      final int ms => DateTime.fromMillisecondsSinceEpoch(ms),
      _ => null,
    },
    widgetTipDone: json['widgetTipDone'] as bool? ?? false,
    orbTipDone: json['orbTipDone'] as bool? ?? false,
  );

  /// Start of the latest time off that was already celebrated.
  final DateTime? celebratedUntil;

  /// The "add a widget" card on the home screen was dismissed.
  final bool widgetTipDone;

  /// The orb was tapped at least once, so its hint can go.
  final bool orbTipDone;

  UiPrefs copyWith({
    DateTime? celebratedUntil,
    bool? widgetTipDone,
    bool? orbTipDone,
  }) => UiPrefs(
    celebratedUntil: celebratedUntil ?? this.celebratedUntil,
    widgetTipDone: widgetTipDone ?? this.widgetTipDone,
    orbTipDone: orbTipDone ?? this.orbTipDone,
  );

  Map<String, dynamic> toJson() => {
    'celebratedUntil': celebratedUntil?.millisecondsSinceEpoch,
    'widgetTipDone': widgetTipDone,
    'orbTipDone': orbTipDone,
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
