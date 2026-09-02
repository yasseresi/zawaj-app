import 'package:flutter/material.dart';

import '../../../shared/providers/theme_provider.dart';
import '../../auth/providers/session_provider.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    ThemeProvider? themeProvider,
    SessionProvider? session,
    Locale? initialLocale,
  })  : _themeProvider = themeProvider,
        _session = session ?? sessionProvider,
        _locale = initialLocale ?? const Locale('ar');

  final ThemeProvider? _themeProvider;
  final SessionProvider _session;

  Locale _locale;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoggingOut = false;

  Locale get locale => _locale;

  ThemeMode get themeMode => _themeProvider?.mode ?? _themeMode;

  bool get isDarkMode => _themeProvider != null
      ? (_themeProvider.mode == ThemeMode.dark)
      : _themeMode == ThemeMode.dark;

  bool get isLoggingOut => _isLoggingOut;

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    if (_themeProvider != null) {
      await _themeProvider.setMode(mode);
    }
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool isDark) async {
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> logout() async {
    _isLoggingOut = true;
    notifyListeners();
    try {
      await _session.signOut();
    } finally {
      _isLoggingOut = false;
      notifyListeners();
    }
  }
}
