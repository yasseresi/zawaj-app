import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../config/app_config.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../data/services/token_storage.dart';
import '../../../services/push_notification_service.dart';
import '../../../utils/failure.dart';
import '../../../utils/logger.dart';

enum SessionStatus { unknown, authenticated, unauthenticated }

/// Single source of truth for auth state. Exposed as a global so the GoRouter
/// can use it as `refreshListenable` and read [status] in its redirect guard
/// (the same instance is provided to the widget tree via `.value`).
class SessionProvider extends ChangeNotifier {
  SessionProvider({AuthRepository? repository})
      : _repository = repository ?? AuthRepositoryImpl();

  final AuthRepository _repository;

  SessionStatus _status = SessionStatus.unknown;
  AppUser? _user;

  SessionStatus get status => _status;
  AppUser? get user => _user;
  bool get isAuthenticated => _status == SessionStatus.authenticated;

  /// Called once at startup: warm the token cache, and if a token exists try to
  /// fetch the user (the Dio interceptor silently refreshes an expired access
  /// token). Any failure → unauthenticated.
  Future<void> bootstrap() async {
    // React to a refresh-failure surfaced by the network layer.
    AppConfig.onSessionExpired = _onExpired;

    await TokenStorage.instance.load();
    final access = await TokenStorage.instance.accessToken;
    if (access == null || access.isEmpty) {
      _set(SessionStatus.unauthenticated, null);
      return;
    }
    final result = await _repository.me();
    result.match(
      (failure) {
        AppLogger.warning('Session bootstrap failed: ${failure.message}');
        _set(SessionStatus.unauthenticated, null);
      },
      (user) => _set(SessionStatus.authenticated, user),
    );
  }

  /// Promote to authenticated after a successful login/register/recover.
  void setAuthenticated(AppUser user) {
    _set(SessionStatus.authenticated, user);
    unawaited(PushNotificationService.instance.registerCurrentDevice());
  }

  /// Update the cached user in place (e.g. after editing profile/settings).
  void updateUser(AppUser user) {
    if (_status == SessionStatus.authenticated) {
      _set(SessionStatus.authenticated, user);
    }
  }

  Future<void> signOut() async {
    await PushNotificationService.instance.unregisterCurrentDevice();
    await _repository.logout();
    _set(SessionStatus.unauthenticated, null);
  }

  /// Permanently delete the account (password re-check on the server). On
  /// success the server has already dropped the device tokens, so this only
  /// ends the local session. Returns the failure, or null on success.
  Future<Failure?> deleteAccount(String password) async {
    final result = await _repository.deleteAccount(password: password);
    return result.match((failure) => failure, (_) {
      _set(SessionStatus.unauthenticated, null);
      return null;
    });
  }

  void _onExpired() {
    AppLogger.warning('Session expired — forcing re-auth');
    _set(SessionStatus.unauthenticated, null);
  }

  void _set(SessionStatus status, AppUser? user) {
    if (_status == status && _user == user) return;
    _status = status;
    _user = user;
    notifyListeners();
  }
}

/// Global session instance. Constructed here so both the router and the widget
/// tree share exactly one. Bootstrapped in `main()` before `runApp`.
final SessionProvider sessionProvider = SessionProvider();
