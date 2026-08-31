import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../data/models/user_model.dart';
import '../../../utils/failure.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../shared/enums/app_status.dart';
import 'session_provider.dart';

/// Drives the login / signup / recover forms. Holds an [AppStatus] + last error
/// message; screens bind to it and react (navigation is handled by the router's
/// session-aware redirect once [SessionProvider] flips to authenticated).
///
/// Signup and recover return a one-time recovery code that MUST be shown before
/// the session is promoted, so those two flows stash the result and expose
/// [pendingRecoveryCode]; the screen surfaces it then calls [confirmPending].
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository, SessionProvider? session})
      : _repository = repository ?? AuthRepositoryImpl(),
        _session = session ?? sessionProvider;

  final AuthRepository _repository;
  final SessionProvider _session;

  AppStatus _status = AppStatus.initial;
  String? _errorMessage;
  AuthResult? _pending;

  AppStatus get status => _status;
  bool get isLoading => _status.isLoading;
  String? get errorMessage => _errorMessage;
  String? get pendingRecoveryCode => _pending?.recoveryCode;

  /// Login: on success the session is promoted immediately (router redirects to
  /// home). Returns true on success.
  Future<bool> login({required String username, required String password}) {
    return _run(() => _repository.login(username: username, password: password),
        onSuccess: (r) => _session.setAuthenticated(r.user));
  }

  /// Register: does NOT promote the session yet — the screen must show the
  /// recovery code first, then call [confirmPending].
  Future<bool> register({
    required String username,
    required String displayName,
    required String password,
  }) {
    return _run(
      () => _repository.register(
          username: username, displayName: displayName, password: password),
      onSuccess: (r) => _pending = r,
    );
  }

  /// Recover: like register, yields a NEW recovery code to display before
  /// promoting the session.
  Future<bool> recover({
    required String username,
    required String recoveryCode,
    required String newPassword,
  }) {
    return _run(
      () => _repository.recover(
          username: username, recoveryCode: recoveryCode, newPassword: newPassword),
      onSuccess: (r) => _pending = r,
    );
  }

  /// Promote the session after the recovery code has been surfaced.
  void confirmPending() {
    final p = _pending;
    if (p != null) {
      _session.setAuthenticated(p.user);
      _pending = null;
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<bool> _run(
    Future<Either<Failure, AuthResult>> Function() action, {
    required void Function(AuthResult) onSuccess,
  }) async {
    _status = AppStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await action();
    return result.match(
      (failure) {
        _status = AppStatus.failure;
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (value) {
        _status = AppStatus.success;
        onSuccess(value);
        notifyListeners();
        return true;
      },
    );
  }
}
