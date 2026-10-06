import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../data/services/token_storage.dart';
import '../imports/core_imports.dart';

/// Owns the single shared [Dio] instance and its interceptors.
///
/// Interceptors (in order):
/// 1. attach `Authorization: Bearer <access>` (from [TokenStorage]) + a
///    per-request `X-Request-ID`;
/// 2. on `401`, single-flight `POST /auth/refresh`, persist the rotated pair,
///    and retry the original request once. If refresh fails, clear tokens and
///    fire [onSessionExpired] (drives the router redirect to login).
///
/// A separate bare [Dio] ([_refreshDio], no interceptors) performs the refresh
/// call so it can't recurse through the 401 handler.
class AppConfig {
  AppConfig._();

  static late final Dio dio;
  static late final Dio _refreshDio;

  /// Set by the session layer; invoked when a refresh attempt fails and the
  /// user must re-authenticate.
  static void Function()? onSessionExpired;

  static String get baseUrl => _getBaseUrl();

  // Auth endpoints must never trigger the refresh-retry loop.
  static const _authPaths = {
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/recover',
    '/auth/logout',
  };

  static Future<void> init() async {
    final options = BaseOptions(
      baseUrl: _getBaseUrl(),
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    dio = Dio(options);
    _refreshDio = Dio(options);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: (response, handler) {
          AppLogger.info(
              '✅ [DIO] ${response.statusCode} ${response.requestOptions.path}');
          handler.next(response);
        },
        onError: _onError,
      ),
    );
  }

  static Future<void> _onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await TokenStorage.instance.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['X-Request-ID'] = _requestId();
    AppLogger.info('🌐 [DIO] ${options.method} ${options.path}');
    handler.next(options);
  }

  static Future<void> _onError(
      DioException e, ErrorInterceptorHandler handler) async {
    final status = e.response?.statusCode;
    final path = e.requestOptions.path;
    final isAuthPath = _authPaths.any(path.endsWith);

    AppLogger.error('❌ [DIO] $status $path');

    // Only try to recover genuine session expiry on non-auth calls, once.
    // `skipAuthRefresh`: the caller treats 401 as a business error (e.g. a
    // wrong password re-check) — retrying would repeat that attempt.
    if (status == 401 &&
        !isAuthPath &&
        e.requestOptions.extra['retried'] != true &&
        e.requestOptions.extra['skipAuthRefresh'] != true) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        try {
          final opts = e.requestOptions..extra['retried'] = true;
          final token = await TokenStorage.instance.accessToken;
          opts.headers['Authorization'] = 'Bearer $token';
          final response = await dio.fetch<dynamic>(opts);
          return handler.resolve(response);
        } catch (err) {
          return handler.next(err is DioException ? err : e);
        }
      } else {
        await TokenStorage.instance.clear();
        onSessionExpired?.call();
      }
    }
    handler.next(e);
  }

  // Single-flight refresh: concurrent 401s await the same in-flight attempt.
  static Future<bool>? _refreshing;

  static Future<bool> _tryRefresh() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  static Future<bool> _doRefresh() async {
    final refresh = await TokenStorage.instance.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await _refreshDio.post<dynamic>('/auth/refresh', data: {'refresh': refresh});
      final data = res.data is Map ? (res.data['data'] ?? res.data) : null;
      if (data is Map && data['access'] != null && data['refresh'] != null) {
        await TokenStorage.instance.save(
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

  static final _rand = Random();
  static String _requestId() {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final r = _rand.nextInt(0x7fffffff).toRadixString(16);
    return '$ts-$r';
  }

  static String _getBaseUrl() =>
      resolveBaseUrl(dotenv.get('API_BASE_URL', fallback: ''),
          isAndroid: PlatformInfo.isAndroid);

  /// Resolves the configured base URL for the current platform.
  ///
  /// `.env` authors the URL against `localhost`. The Android emulator cannot
  /// reach the host via `localhost` — it needs the `10.0.2.2` host alias —
  /// while the iOS simulator reaches the host *only* via `localhost`. So on
  /// Android we rewrite the `localhost` host to `10.0.2.2`; everywhere else the
  /// URL passes through unchanged. Pure + parameterized so it is unit-testable.
  static String resolveBaseUrl(String raw, {required bool isAndroid}) {
    if (!isAndroid) return raw;
    return raw.replaceFirst('localhost', '10.0.2.2');
  }
}
