import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../utils/logger.dart';

/// Where the interceptor reads and rotates the session tokens
/// (`TokenStorage` in the app; an in-memory fake in tests).
abstract interface class AuthTokens {
  Future<String?> get accessToken;
  Future<String?> get refreshToken;
  Future<void> save({required String access, required String refresh});
  Future<void> clear();
}

/// Attaches `Authorization: Bearer <access>` and an `X-Request-ID` to every
/// request, and recovers an expired session:
///
/// - on a `401` from a non-auth endpoint, refresh once (single-flight:
///   concurrent 401s share one `POST /auth/refresh`), persist the rotated
///   pair, and retry the original request once;
/// - if the refresh fails, clear the tokens and call [onSessionExpired] (the
///   router then redirects to login), and surface the original `401`;
/// - requests marked `extra['skipAuthRefresh'] = true` treat 401 as a business
///   error (e.g. a wrong password re-check) and are never retried, so the
///   attempt isn't repeated or double-counted toward a lockout.
///
/// [refreshDio] must have no interceptors, so a 401 from the refresh call
/// can't recurse into this handler.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required Dio refreshDio,
    required AuthTokens tokens,
    this.onSessionExpired,
  })  : assert(!identical(dio, refreshDio),
            'refreshDio must be a separate client from dio'),
        assert(!refreshDio.interceptors.any((i) => i is AuthInterceptor),
            'refreshDio must not carry an AuthInterceptor'),
        _dio = dio,
        _refreshDio = refreshDio,
        _tokens = tokens;

  final Dio _dio;
  final Dio _refreshDio;
  final AuthTokens _tokens;

  /// Invoked when a refresh fails and the user must sign in again.
  void Function()? onSessionExpired;

  // Auth endpoints must never trigger the refresh-retry loop.
  static const _authPaths = {
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/recover',
    '/auth/logout',
  };

  Future<bool>? _refreshing;
  final _rand = Random();

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokens.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['X-Request-ID'] = _requestId();
    AppLogger.info('🌐 [DIO] ${options.method} ${_logPath(options.path)}');
    handler.next(options);
  }

  @override
  void onResponse(
      Response<dynamic> response, ResponseInterceptorHandler handler) {
    AppLogger.info(
        '✅ [DIO] ${response.statusCode} ${_logPath(response.requestOptions.path)}');
    handler.next(response);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final opts = err.requestOptions;
    AppLogger.error('❌ [DIO] $status ${_logPath(opts.path)}');

    final recoverable = status == 401 &&
        !_authPaths.any(opts.path.endsWith) &&
        opts.extra['retried'] != true &&
        opts.extra['skipAuthRefresh'] != true;
    if (!recoverable) return handler.next(err);

    if (!await _refresh()) {
      await _tokens.clear();
      onSessionExpired?.call();
      return handler.next(err);
    }
    try {
      opts.extra['retried'] = true;
      opts.headers['Authorization'] = 'Bearer ${await _tokens.accessToken}';
      return handler.resolve(await _dio.fetch<dynamic>(opts));
    } on DioException catch (retryError) {
      return handler.next(retryError);
    } catch (_) {
      return handler.next(err);
    }
  }

  // Single-flight: concurrent 401s await the same in-flight attempt.
  Future<bool> _refresh() =>
      _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final refresh = await _tokens.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await _refreshDio
          .post<dynamic>('/auth/refresh', data: {'refresh': refresh});
      final body = res.data;
      final data = body is Map ? (body['data'] ?? body) : null;
      if (data is Map && data['access'] != null && data['refresh'] != null) {
        await _tokens.save(
          access: data['access'].toString(),
          refresh: data['refresh'].toString(),
        );
        AppLogger.info('🔄 [DIO] token refreshed');
        return true;
      }
      return false;
    } catch (err) {
      AppLogger.warning('🔄 [DIO] refresh failed: $err');
      return false;
    }
  }

  String _requestId() {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final r = _rand.nextInt(0x7fffffff).toRadixString(16);
    return '$ts-$r';
  }
}

/// [path] with the invite token masked: debug logs must not hold a bearer
/// token for joining a wedding (the backend logs route templates likewise).
@visibleForTesting
String logPathForTesting(String path) => _logPath(path);

String _logPath(String path) =>
    path.replaceAll(RegExp(r'/invite/[^/?]+'), '/invite/:token');
