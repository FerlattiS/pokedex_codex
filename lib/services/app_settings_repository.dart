import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AppSettingsRepository {
  Future<ThemeMode> readThemeMode();

  Future<void> writeThemeMode(ThemeMode themeMode);
}

class SharedPreferencesAppSettingsRepository implements AppSettingsRepository {
  SharedPreferencesAppSettingsRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _themeModeKey = 'app.settings.themeMode';

  @override
  Future<ThemeMode> readThemeMode() async {
    final value = _preferences.getString(_themeModeKey);

    return switch (value) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }

  @override
  Future<void> writeThemeMode(ThemeMode themeMode) async {
    await _preferences.setString(_themeModeKey, themeMode.name);
  }
}
