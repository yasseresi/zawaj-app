import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';

import 'failure.dart';

/// Central translation of raw errors into typed [Failure]s.
///
/// Handles the backend envelope `{ "data": null, "error": {code, message,
/// details} }` first (mapping the stable `code` to a typed failure and
/// preferring the server's human message), then falls back to Dio transport
/// classification, then anything else. Generic connectivity/timeout copy is
/// localized via `errors.*` keys; server-supplied messages pass through as-is.
class AppErrorHandler {
  const AppErrorHandler._();

  /// Legacy string extractor kept for callers that only need a message.
  static String format(dynamic error) => toFailure(error).message;

  /// Converts typed failures into stable, localized UI copy. A server message
  /// is still retained on [Failure] for logging/debugging, but screens should
  /// use this method so common cases do not leak backend wording.
  static String userMessage(Failure failure, {String? context}) {
    if (context == 'share_username') {
      if (failure is NotFoundFailure) return _tr('share.username_not_found');
      if (failure.code == 'invite_pending') {
        return _tr('share.invite_already_pending');
      }
      if (failure.code == 'already_member') {
        return _tr('share.already_collaborator');
      }
      if (failure.code == 'self_invite') {
        return _tr('share.cannot_invite_self');
      }
      if (failure is ConflictFailure &&
          failure.message.toLowerCase().contains('pending')) {
        return _tr('share.invite_already_pending');
      }
      if (failure is ConflictFailure &&
          failure.message.toLowerCase().contains('member')) {
        return _tr('share.already_collaborator');
      }
      if (failure is ValidationFailure &&
          failure.message.toLowerCase().contains('yourself')) {
        return _tr('share.cannot_invite_self');
      }
    }
    if (failure.code == 'username_taken' ||
        (failure is ConflictFailure &&
            failure.message.toLowerCase().contains('username'))) {
      return _tr('auth.username_taken');
    }
    if (failure.code == 'removed_from_wedding') {
      return _tr('invites.removed_from_wedding');
    }
    if (failure.code == 'join_request_declined') {
      return _tr('invites.join_declined_recently');
    }
    if (failure.code == 'join_queue_full') {
      return _tr('invites.join_queue_full');
    }
    if (failure is LockedFailure) return _tr('errors.locked');
    if (failure is RateLimitFailure) return _tr('errors.rate_limited');
    if (failure is ValidationFailure) return _tr('errors.validation');
    if (failure is NotFoundFailure) return _tr('errors.not_found');
    if (failure is ConflictFailure) return _tr('errors.conflict');
    return failure.message;
  }

  static Failure toFailure(dynamic error) {
    if (error is Failure) return error;
    if (error is DioException) return _fromDio(error);
    return UnknownFailure(error?.toString() ?? _tr('errors.unknown'));
  }

  static Failure _fromDio(DioException e) {
    final response = e.response;

    // 1) Structured envelope error from our API.
    final data = response?.data;
    if (data is Map && data['error'] is Map) {
      final err = data['error'] as Map;
      final code = err['code']?.toString();
      final message = (err['message']?.toString().trim().isNotEmpty ?? false)
          ? err['message'].toString()
          : _messageForCode(code);
      final details = err['details'];
      return _byCode(code, message, details, e, response);
    }

    // 2) Transport-level failure (no usable body).
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return NetworkFailure(_tr('errors.timeout'), error: e);
      case DioExceptionType.connectionError:
        return NetworkFailure(_tr('errors.no_connection'), error: e);
      case DioExceptionType.badCertificate:
        return NetworkFailure(_tr('errors.no_connection'), error: e);
      case DioExceptionType.cancel:
        return UnknownFailure(_tr('errors.cancelled'), error: e);
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        // Fall through to status-based mapping below.
        break;
    }

    // 3) HTTP status without an envelope.
    final status = response?.statusCode ?? 0;
    return _byStatus(status, _messageForStatus(status), e, response);
  }

  static Failure _byCode(String? code, String message, dynamic details,
      DioException e, Response<dynamic>? response) {
    switch (code) {
      case 'validation_error':
        return ValidationFailure(message, details: details, error: e);
      case 'unauthenticated':
        return AuthFailure(message, error: e);
      case 'forbidden':
        return ForbiddenFailure(message, error: e);
      case 'removed_from_wedding':
        return ForbiddenFailure(message, code: code, error: e);
      case 'join_request_declined':
        return ConflictFailure(message, code: code, error: e);
      case 'not_found':
        return NotFoundFailure(message, error: e);
      case 'conflict':
        return ConflictFailure(message, error: e);
      case 'username_taken':
        return ConflictFailure(message, code: code, error: e);
      case 'invite_pending':
        return ConflictFailure(message, code: code, error: e);
      case 'already_member':
        return ConflictFailure(message, code: code, error: e);
      case 'self_invite':
        return ValidationFailure(message, code: code, error: e);
      case 'locked':
        return LockedFailure(message, error: e);
      case 'rate_limited':
        return RateLimitFailure(message,
            retryAfter: _retryAfter(response), error: e);
      case 'internal':
        return ServerFailure(message, code: 'internal', error: e);
      default:
        return ServerFailure(message, code: code, error: e);
    }
  }

  static Failure _byStatus(
      int status, String message, DioException e, Response<dynamic>? response) {
    switch (status) {
      case 400:
        return ValidationFailure(message, error: e);
      case 401:
        return AuthFailure(message, error: e);
      case 403:
        return ForbiddenFailure(message, error: e);
      case 404:
        return NotFoundFailure(message, error: e);
      case 409:
        return ConflictFailure(message, error: e);
      case 423:
        return LockedFailure(message, error: e);
      case 429:
        return RateLimitFailure(message,
            retryAfter: _retryAfter(response), error: e);
      default:
        return ServerFailure(message, code: 'internal', error: e);
    }
  }

  static int? _retryAfter(Response<dynamic>? response) {
    final raw = response?.headers.value('retry-after');
    return raw == null ? null : int.tryParse(raw);
  }

  static String _messageForCode(String? code) => switch (code) {
        'validation_error' => _tr('errors.validation'),
        'unauthenticated' => _tr('errors.unauthenticated'),
        'forbidden' => _tr('errors.forbidden'),
        'not_found' => _tr('errors.not_found'),
        'conflict' => _tr('errors.conflict'),
        'locked' => _tr('errors.locked'),
        'rate_limited' => _tr('errors.rate_limited'),
        _ => _tr('errors.server'),
      };

  static String _messageForStatus(int status) => switch (status) {
        400 => _tr('errors.validation'),
        401 => _tr('errors.unauthenticated'),
        403 => _tr('errors.forbidden'),
        404 => _tr('errors.not_found'),
        409 => _tr('errors.conflict'),
        423 => _tr('errors.locked'),
        429 => _tr('errors.rate_limited'),
        _ => _tr('errors.server'),
      };

  /// `tr()` returns the key itself if localization isn't initialized (e.g. in
  /// unit tests), which is acceptable — no crash.
  static String _tr(String key) => key.tr();
}
