import '../models/user_model.dart';
import '../../utils/typedefs.dart';

/// Authentication boundary used by the session/auth providers. Matches the
/// backend's username + recovery-code model — no email/social auth.
abstract interface class AuthRepository {
  /// Create an account. Result carries the one-time `recoveryCode` to surface.
  FutureEither<AuthResult> register({
    required String username,
    required String displayName,
    required String password,
  });

  FutureEither<AuthResult> login({
    required String username,
    required String password,
  });

  /// Reset the password via recovery code. Result carries a NEW recovery code.
  FutureEither<AuthResult> recover({
    required String username,
    required String recoveryCode,
    required String newPassword,
  });

  FutureEitherVoid logout();

  /// Fetch the authenticated user (`GET /me`) — used to bootstrap the session
  /// from a persisted token pair.
  FutureEither<AppUser> me();
}
