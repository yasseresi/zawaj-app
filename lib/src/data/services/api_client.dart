import 'package:dio/dio.dart';

import '../../config/app_config.dart';
import '../../utils/utils.dart';

/// Thin typed wrapper over the shared authenticated [Dio] instance.
///
/// Responsibilities:
/// - unwrap the backend envelope `{ "data": ..., "error": null }` and hand the
///   inner `data` to a caller-supplied [parse] function;
/// - run every call through [runTask] so exceptions become typed [Failure]s
///   (via `AppErrorHandler`) and the result is a [FutureEither];
/// - never leak `DioException` or envelope shape past this layer.
///
/// Auth headers and 401→refresh retry are handled by interceptors in
/// [AppConfig]; this client stays transport-agnostic.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  Dio get _dio => AppConfig.dio;

  FutureEither<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(dynamic data) parse,
  }) =>
      _send(() => _dio.get(path, queryParameters: query), parse);

  FutureEither<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
    required T Function(dynamic data) parse,
  }) =>
      _send(
        () => _dio.post(path,
            data: body, queryParameters: query, options: _opts(headers)),
        parse,
      );

  FutureEither<T> patch<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    required T Function(dynamic data) parse,
  }) =>
      _send(() => _dio.patch(path, data: body, queryParameters: query), parse);

  /// [skipAuthRefresh]: don't refresh-and-retry on 401 — for endpoints where
  /// 401 means "wrong password", not an expired session.
  FutureEither<T> delete<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool skipAuthRefresh = false,
    required T Function(dynamic data) parse,
  }) =>
      _send(
        () => _dio.delete(path,
            data: body,
            queryParameters: query,
            options: skipAuthRefresh
                ? Options(extra: {'skipAuthRefresh': true})
                : null),
        parse,
      );

  /// Raw response accessor for non-enveloped endpoints (e.g. CSV export).
  FutureEither<Response<T>> raw<T>(Future<Response<T>> Function() call) =>
      runTask(call, requiresNetwork: true);

  FutureEither<T> _send<T>(
    Future<Response<dynamic>> Function() call,
    T Function(dynamic data) parse,
  ) =>
      runTask(() async {
        final res = await call();
        final body = res.data;
        // Envelope-aware: pull `data` when the body is our standard envelope,
        // otherwise pass the raw body through (defensive against non-enveloped
        // or empty 204-style responses).
        final payload = (body is Map && body.containsKey('data')) ? body['data'] : body;
        return parse(payload);
      }, requiresNetwork: true);

  Options? _opts(Map<String, dynamic>? headers) =>
      headers == null ? null : Options(headers: headers);
}

/// Convenience parser for endpoints whose `data` we don't need (e.g. `{deleted:
/// true}`) — returns unit.
void parseVoid(dynamic _) {}
