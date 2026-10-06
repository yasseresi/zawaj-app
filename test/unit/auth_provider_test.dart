import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/models/user_model.dart';
import 'package:zawaj_app/src/data/repositories/auth_repository.dart';
import 'package:zawaj_app/src/shared/enums/app_status.dart';
import 'package:zawaj_app/src/ui/auth/providers/auth_provider.dart';
import 'package:zawaj_app/src/ui/auth/providers/session_provider.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _FakeAuthRepository implements AuthRepository {
  Either<Failure, AuthResult>? loginResult;
  Either<Failure, AuthResult>? registerResult;

  @override
  FutureEitherVoid changePassword(
          {required String oldPassword, required String newPassword}) async =>
      const Right(null);

  @override
  FutureEither<AuthResult> login(
          {required String username, required String password}) async =>
      loginResult!;

  @override
  FutureEither<AuthResult> register({
    required String username,
    required String displayName,
    required String password,
  }) async =>
      registerResult!;

  @override
  FutureEither<AuthResult> recover({
    required String username,
    required String recoveryCode,
    required String newPassword,
  }) async =>
      throw UnimplementedError();

  @override
  FutureEitherVoid logout() async => const Right(null);

  @override
  FutureEither<AppUser> me() async => throw UnimplementedError();

  @override
  FutureEither<AppUser> updateProfile({String? displayName, String? phone}) async =>
      throw UnimplementedError();

  @override
  FutureEither<AppUser> updateSettings({bool? notifPush, bool? notifRsvp}) async =>
      throw UnimplementedError();
}

const _user = AppUser(id: '1', username: 'leila', displayName: 'Leila');

void main() {
  group('AuthProvider', () {
    late _FakeAuthRepository repo;
    late SessionProvider session;
    late AuthProvider auth;

    setUp(() {
      repo = _FakeAuthRepository();
      session = SessionProvider(repository: repo);
      auth = AuthProvider(repository: repo, session: session);
    });

    test('login success promotes the session and reports success', () async {
      repo.loginResult = const Right(
        AuthResult(user: _user, access: 'a', refresh: 'r'),
      );

      final ok = await auth.login(username: 'leila', password: 'Password1!');

      expect(ok, isTrue);
      expect(auth.status, AppStatus.success);
      expect(session.isAuthenticated, isTrue);
      expect(session.user, _user);
    });

    test('login failure sets error message and does not authenticate',
        () async {
      repo.loginResult =
          const Left(AuthFailure('invalid username or password'));

      final ok = await auth.login(username: 'leila', password: 'wrong');

      expect(ok, isFalse);
      expect(auth.status, AppStatus.failure);
      expect(auth.errorMessage, 'invalid username or password');
      expect(session.isAuthenticated, isFalse);
    });

    test('register defers session promotion until recovery code is confirmed',
        () async {
      repo.registerResult = const Right(
        AuthResult(
            user: _user, access: 'a', refresh: 'r', recoveryCode: 'CODE-1'),
      );

      final ok = await auth.register(
          username: 'leila', displayName: 'Leila', password: 'Password1!');

      expect(ok, isTrue);
      expect(auth.pendingRecoveryCode, 'CODE-1');
      expect(session.isAuthenticated, isFalse); // not yet

      auth.confirmPending();
      expect(session.isAuthenticated, isTrue);
    });
  });
}
