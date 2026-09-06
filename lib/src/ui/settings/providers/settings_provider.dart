import 'package:flutter/material.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../shared/enums/app_status.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../utils/error_handler.dart';
import '../../auth/providers/session_provider.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    ThemeProvider? themeProvider,
    SessionProvider? session,
    AuthRepository? authRepository,
    Locale? initialLocale,
  })  : _themeProvider = themeProvider,
        _session = session ?? sessionProvider,
        _authRepository = authRepository ?? AuthRepositoryImpl(),
        _locale = initialLocale ?? const Locale('ar');

  final ThemeProvider? _themeProvider;
  final SessionProvider _session;
  final AuthRepository _authRepository;

  Locale _locale;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoggingOut = false;
  AppStatus _passwordStatus = AppStatus.initial;
  String? _passwordErrorMessage;

  Locale get locale => _locale;

  ThemeMode get themeMode => _themeProvider?.mode ?? _themeMode;

  bool get isDarkMode => _themeProvider != null
      ? (_themeProvider.mode == ThemeMode.dark)
      : _themeMode == ThemeMode.dark;

  bool get isLoggingOut => _isLoggingOut;
  bool get isChangingPassword => _passwordStatus.isLoading;
  String? get passwordErrorMessage => _passwordErrorMessage;

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

  Future<bool> changePassword(
      {required String oldPassword, required String newPassword}) async {
    _passwordStatus = AppStatus.loading;
    _passwordErrorMessage = null;
    notifyListeners();

    final result = await _authRepository.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    return result.match(
      (failure) {
        _passwordStatus = AppStatus.failure;
        _passwordErrorMessage = AppErrorHandler.userMessage(failure);
        notifyListeners();
        return false;
      },
      (_) {
        _passwordStatus = AppStatus.success;
        notifyListeners();
        return true;
      },
    );
  }
}
