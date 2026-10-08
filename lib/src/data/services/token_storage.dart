import '../../config/auth_interceptor.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT access/refresh pair in platform secure storage
/// (Keychain on iOS, Keystore-backed on Android).
///
/// Kept deliberately exception-light (plain futures, no [FutureEither]) so the
/// Dio auth interceptor can read/write tokens inline without unwrapping an
/// [Either]. Backend contract: access TTL 15m, refresh TTL 30d, rotation with
/// reuse-detection — always overwrite BOTH tokens together on refresh.
class TokenStorage implements AuthTokens {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions.defaultOptions,
  );

  // In-memory mirror so the request interceptor avoids a Keychain hit per call.
  String? _accessCache;
  String? _refreshCache;

  @override
  Future<String?> get accessToken async =>
      _accessCache ??= await _storage.read(key: _kAccess);

  @override
  Future<String?> get refreshToken async =>
      _refreshCache ??= await _storage.read(key: _kRefresh);

  bool get hasCachedAccess => _accessCache != null;

  /// Overwrites both tokens atomically after login/register/refresh/recover.
  @override
  Future<void> save({required String access, required String refresh}) async {
    _accessCache = access;
    _refreshCache = refresh;
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  /// Warms the in-memory cache from disk at startup (call once before session
  /// bootstrap so [hasCachedAccess] is meaningful).
  Future<void> load() async {
    _accessCache = await _storage.read(key: _kAccess);
    _refreshCache = await _storage.read(key: _kRefresh);
  }

  @override
  Future<void> clear() async {
    _accessCache = null;
    _refreshCache = null;
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}
