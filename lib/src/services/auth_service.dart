import 'package:fpdart/fpdart.dart';

import '../data/models/user_model.dart';
import '../data/services/api_client.dart';
import '../data/services/token_storage.dart';
import '../utils/utils.dart';

/// API surface for authentication + the current-user (`/me`) endpoints.
///
/// Pure transport: every method returns a [FutureEither] of a domain object and
/// persists tokens through [TokenStorage] on the happy path. Session state and
/// navigation live in the session/auth providers, not here (no [BuildContext]).
///
/// Backend contract: username + password + one-time recovery code; JWT access
/// (15m) + refresh (30d) with rotation.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final ApiClient _api = ApiClient.instance;
  final TokenStorage _tokens = TokenStorage.instance;

  /// `POST /auth/register` → user + tokens + one-time recovery code (201).
  FutureEither<AuthResult> register({
    required String username,
    required String displayName,
    required String password,
  }) async {
    final result = await _api.post<AuthResult>(
      '/auth/register',
      body: {
        'username': username,
        'display_name': displayName,
        'password': password,
      },
      parse: (d) => AuthResult.fromJson((d as Map).cast<String, dynamic>()),
    );
    final r = result.toNullable();
    if (r != null) await _persist(r);
    return result;
  }

  /// `POST /auth/login` → user + tokens (no recovery code).
  FutureEither<AuthResult> login({
    required String username,
    required String password,
  }) async {
    final result = await _api.post<AuthResult>(
      '/auth/login',
      body: {'username': username, 'password': password},
      parse: (d) => AuthResult.fromJson((d as Map).cast<String, dynamic>()),
    );
    final r = result.toNullable();
    if (r != null) await _persist(r);
    return result;
  }

  /// `POST /auth/recover` → new tokens + a fresh one-time recovery code; kills
  /// all prior sessions server-side.
  FutureEither<AuthResult> recover({
    required String username,
    required String recoveryCode,
    required String newPassword,
  }) async {
    final result = await _api.post<AuthResult>(
      '/auth/recover',
      body: {
        'username': username,
        'recovery_code': recoveryCode,
        'new_password': newPassword,
      },
      parse: (d) => AuthResult.fromJson((d as Map).cast<String, dynamic>()),
    );
    final r = result.toNullable();
    if (r != null) await _persist(r);
    return result;
  }

  /// `POST /auth/logout` — revokes the refresh token (idempotent), then clears
  /// local tokens regardless of the server outcome.
  FutureEitherVoid logout() async {
    final refresh = await _tokens.refreshToken;
    if (refresh != null && refresh.isNotEmpty) {
      await _api.post<void>('/auth/logout', body: {'refresh': refresh}, parse: parseVoid);
    }
    await _tokens.clear();
    return const Right<Failure, void>(null);
  }

  /// `GET /me` — the authenticated user (minimal shape).
  FutureEither<AppUser> getMe() => _api.get<AppUser>(
        '/me',
        parse: (d) => AppUser.fromJson((d as Map).cast<String, dynamic>()),
      );

  /// `PATCH /me` — update display name and/or phone. Only non-null fields are
  /// sent; `phone: ''` clears the phone.
  FutureEither<AppUser> updateProfile({String? displayName, String? phone}) => _api.patch<AppUser>(
        '/me',
        body: {
          if (displayName != null) 'display_name': displayName,
          if (phone != null) 'phone': phone,
        },
        parse: (d) => AppUser.fromJson((d as Map).cast<String, dynamic>()),
      );

  /// `PATCH /me/password` — kills all sessions; caller must re-authenticate.
  FutureEitherVoid changePassword({required String oldPassword, required String newPassword}) =>
      _api.patch<void>(
        '/me/password',
        body: {'old_password': oldPassword, 'new_password': newPassword},
        parse: parseVoid,
      );

  /// `PATCH /me/settings` — update preferences (`notif_push`, `notif_rsvp`, …);
  /// returns the updated user.
  FutureEither<AppUser> updateSettings(Map<String, dynamic> patch) => _api.patch<AppUser>(
        '/me/settings',
        body: patch,
        parse: (d) => AppUser.fromJson((d as Map).cast<String, dynamic>()),
      );

  /// `DELETE /me` — hard-delete account + cascade owned weddings.
  FutureEitherVoid deleteAccount() async {
    final result = await _api.delete<void>('/me', parse: parseVoid);
    if (result.isRight()) await _tokens.clear();
    return result;
  }

  Future<void> _persist(AuthResult r) =>
      _tokens.save(access: r.access, refresh: r.refresh);
}
