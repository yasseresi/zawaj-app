import 'package:flutter/material.dart';

import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../shared/enums/app_status.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../utils/error_handler.dart';
import '../../../utils/phone.dart';
import '../../../utils/typedefs.dart';
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
  bool _isSavingProfile = false;
  String? _profileErrorMessage;
  bool _isSavingNotifPush = false;
  bool _isSavingNotifRsvp = false;
  String? _preferencesErrorMessage;

  Locale get locale => _locale;

  ThemeMode get themeMode => _themeProvider?.mode ?? _themeMode;

  bool get isDarkMode => _themeProvider != null
      ? (_themeProvider.mode == ThemeMode.dark)
      : _themeMode == ThemeMode.dark;

  bool get isLoggingOut => _isLoggingOut;
  bool get isChangingPassword => _passwordStatus.isLoading;
  String? get passwordErrorMessage => _passwordErrorMessage;
  bool get isSavingProfile => _isSavingProfile;
  String? get profileErrorMessage => _profileErrorMessage;
  bool get isSavingNotifPush => _isSavingNotifPush;
  bool get isSavingNotifRsvp => _isSavingNotifRsvp;
  String? get preferencesErrorMessage => _preferencesErrorMessage;

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

  /// `PATCH /me` with only the fields that differ from the session user.
  /// [phone] is raw input: normalized to national format, `''` clears it.
  /// Returns true on success (or when nothing changed); on failure the session
  /// is untouched and [profileErrorMessage] carries the reason.
  Future<bool> updateProfile(
      {required String displayName, required String phone}) async {
    final current = _session.user;
    if (current == null) return false;

    final name = displayName.trim();
    final normalizedPhone = phone.trim().isEmpty ? '' : normalizePhone(phone);
    if (normalizedPhone == null) return false; // the form validates first
    final nameChanged = name != current.displayName;
    final phoneChanged = normalizedPhone != (current.phone ?? '');
    if (!nameChanged && !phoneChanged) return true;

    _isSavingProfile = true;
    _profileErrorMessage = null;
    notifyListeners();

    final result = await _authRepository.updateProfile(
      displayName: nameChanged ? name : null,
      phone: phoneChanged ? normalizedPhone : null,
    );
    _isSavingProfile = false;
    return result.match(
      (failure) {
        _profileErrorMessage = AppErrorHandler.userMessage(failure);
        notifyListeners();
        return false;
      },
      (user) {
        _session.updateUser(user);
        notifyListeners();
        return true;
      },
    );
  }

  /// Toggle push notifications (`notif_push`). Optimistic: the session flips
  /// immediately and rolls back on failure. Taps while a request is in flight
  /// are ignored (returns false).
  Future<bool> setNotifPush(bool value) async {
    if (_isSavingNotifPush) return false;
    _isSavingNotifPush = true;
    final ok = await _savePreference(
      value: value,
      read: (u) => u.notifPush,
      write: (u, v) => u.copyWith(notifPush: v),
      request: () => _authRepository.updateSettings(notifPush: value),
    );
    _isSavingNotifPush = false;
    notifyListeners();
    return ok;
  }

  /// Toggle RSVP-change alerts (`notif_rsvp`). Same optimistic contract as
  /// [setNotifPush].
  Future<bool> setNotifRsvp(bool value) async {
    if (_isSavingNotifRsvp) return false;
    _isSavingNotifRsvp = true;
    final ok = await _savePreference(
      value: value,
      read: (u) => u.notifRsvp,
      write: (u, v) => u.copyWith(notifRsvp: v),
      request: () => _authRepository.updateSettings(notifRsvp: value),
    );
    _isSavingNotifRsvp = false;
    notifyListeners();
    return ok;
  }

  /// Applies one preference optimistically. The rollback (failure) and the
  /// server value (success) are written to that field only, on the session
  /// user as it is *now*, so an overlapping toggle or profile edit is never
  /// reverted by a stale snapshot or reply.
  Future<bool> _savePreference({
    required bool value,
    required bool Function(AppUser) read,
    required AppUser Function(AppUser, bool) write,
    required FutureEither<AppUser> Function() request,
  }) async {
    final before = _session.user;
    if (before == null) return false;
    final previous = read(before);
    _preferencesErrorMessage = null;
    _session.updateUser(write(before, value));
    notifyListeners();

    final result = await request();
    final current = _session.user;
    if (current == null) return false; // signed out meanwhile
    return result.match(
      (failure) {
        _session.updateUser(write(current, previous));
        _preferencesErrorMessage = AppErrorHandler.userMessage(failure);
        return false;
      },
      (user) {
        _session.updateUser(write(current, read(user)));
        return true;
      },
    );
  }
}
