import '../../services/auth_service.dart';
import '../../utils/typedefs.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

/// Delegates to [AuthService] (which owns the HTTP calls and token persistence).
/// Kept as a seam so providers depend on the [AuthRepository] interface and can
/// be tested with a fake.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({AuthService? service}) : _service = service ?? AuthService.instance;

  final AuthService _service;

  @override
  FutureEither<AuthResult> register({
    required String username,
    required String displayName,
    required String password,
  }) =>
      _service.register(username: username, displayName: displayName, password: password);

  @override
  FutureEither<AuthResult> login({required String username, required String password}) =>
      _service.login(username: username, password: password);

  @override
  FutureEither<AuthResult> recover({
    required String username,
    required String recoveryCode,
    required String newPassword,
  }) =>
      _service.recover(username: username, recoveryCode: recoveryCode, newPassword: newPassword);

  @override
  FutureEitherVoid changePassword({required String oldPassword, required String newPassword}) =>
      _service.changePassword(oldPassword: oldPassword, newPassword: newPassword);

  @override
  FutureEitherVoid logout() => _service.logout();

  @override
  FutureEither<AppUser> me() => _service.getMe();
}
