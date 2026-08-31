import 'package:flutter/material.dart';

import '../../services/storage_service.dart';

/// Owns the app [ThemeMode] (system / light / dark), persisted in
/// SharedPreferences via [StorageService]. Wired into `MaterialApp.themeMode`.
///
/// When authenticated, the settings screen also mirrors the choice to the
/// backend (`PATCH /me/settings.dark_mode`); this controller stays local so the
/// theme works pre-login.
class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  bool isDark(BuildContext context) => switch (_mode) {
        ThemeMode.dark => true,
        ThemeMode.light => false,
        ThemeMode.system =>
          MediaQuery.platformBrightnessOf(context) == Brightness.dark,
      };

  /// Reads the persisted value. Safe to call after [StorageService.init].
  void load() {
    _mode = _parse(StorageService.instance.getString(_key));
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await StorageService.instance.setString(_key, mode.name);
  }

  /// Convenience for a light/dark switch (resolves `system` against [context]).
  Future<void> toggle(BuildContext context) =>
      setMode(isDark(context) ? ThemeMode.light : ThemeMode.dark);

  static ThemeMode _parse(String? name) => switch (name) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}
