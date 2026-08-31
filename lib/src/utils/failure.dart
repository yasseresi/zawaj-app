import 'package:equatable/equatable.dart';

/// Base type for every recoverable error surfaced to the UI. Repositories return
/// `Left(Failure)`; view models `.fold` it. Nothing throws past the repository.
///
/// [code] mirrors the backend's stable error code (`validation_error`,
/// `unauthenticated`, `forbidden`, `not_found`, `conflict`, `locked`,
/// `rate_limited`, `internal`) when the failure originated from an API envelope,
/// or a local sentinel (`network`, `cache`, `unknown`) otherwise.
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final dynamic error;

  const Failure(this.message, {this.code, this.error});

  @override
  List<Object?> get props => [message, code, error];

  @override
  String toString() => 'Failure($code): $message';
}

/// 5xx / untyped server error, or an API envelope error without a more specific
/// mapping.
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code, super.error});
}

/// 400 `validation_error`. [details] carries the backend's `error.details` when
/// present (e.g. field-level messages).
class ValidationFailure extends Failure {
  final dynamic details;
  const ValidationFailure(super.message, {super.code = 'validation_error', this.details, super.error});

  @override
  List<Object?> get props => [...super.props, details];
}

/// 401 `unauthenticated` — invalid credentials or an unusable/expired session
/// that could not be refreshed.
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code = 'unauthenticated', super.error});
}

/// 403 `forbidden` — authenticated but not permitted (insufficient role).
class ForbiddenFailure extends Failure {
  const ForbiddenFailure(super.message, {super.code = 'forbidden', super.error});
}

/// 404 `not_found`. Note: for wedding-scoped routes the backend returns 404 to
/// hide existence from non-members, so this can also mean "no access".
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code = 'not_found', super.error});
}

/// 409 `conflict` — e.g. username already taken, or idempotency-key reuse with a
/// different body.
class ConflictFailure extends Failure {
  const ConflictFailure(super.message, {super.code = 'conflict', super.error});
}

/// 423 `locked` — account lockout after too many failed login/recover attempts.
class LockedFailure extends Failure {
  const LockedFailure(super.message, {super.code = 'locked', super.error});
}

/// 429 `rate_limited`. [retryAfter] seconds from the `Retry-After` header.
class RateLimitFailure extends Failure {
  final int? retryAfter;
  const RateLimitFailure(super.message, {super.code = 'rate_limited', this.retryAfter, super.error});

  @override
  List<Object?> get props => [...super.props, retryAfter];
}

/// No/failed internet connection (local, before any request).
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code = 'network', super.error});
}

/// Local cache miss/expiry — used as control flow for cache-then-network reads.
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code = 'cache', super.error});
}

/// Anything unclassified.
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code = 'unknown', super.error});
}
