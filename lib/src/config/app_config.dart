import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../data/services/token_storage.dart';
import 'auth_interceptor.dart';
import '../imports/core_imports.dart';

/// Owns the single shared [Dio] instance. Auth headers and the 401
/// refresh-and-retry live in [AuthInterceptor] (see there); when a refresh
/// fails it fires [onSessionExpired], which drives the redirect to login.
class AppConfig {
  AppConfig._();

  static late final Dio dio;

  /// Set by the session layer; invoked when a refresh attempt fails and the
  /// user must re-authenticate.
  static void Function()? onSessionExpired;

  static String get baseUrl => _getBaseUrl();

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
    // Bare client for the refresh call, so a 401 there can't recurse.
    final refreshDio = Dio(options);
    dio.interceptors.add(AuthInterceptor(
      dio: dio,
      refreshDio: refreshDio,
      tokens: TokenStorage.instance,
      // Read at call time: the session layer may set the hook after init.
      onSessionExpired: () => onSessionExpired?.call(),
    ));
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
