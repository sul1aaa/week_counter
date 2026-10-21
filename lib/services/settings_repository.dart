import 'dart:convert';

import '../models/app_settings.dart';
import 'local_store.dart';

class SettingsRepository {
  SettingsRepository(this._store);

  static const _key = 'settings.v1';

  final LocalStore _store;

  /// Saved settings, or null on first launch.
  Future<AppSettings?> load() async {
    final raw = await _store.getString(_key);
    if (raw == null) return null;
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // Unreadable settings are treated as a first launch.
      return null;
    }
  }

  Future<void> save(AppSettings settings) =>
      _store.setString(_key, jsonEncode(settings.toJson()));
}
