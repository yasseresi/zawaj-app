import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/services/api_client.dart';
import 'package:zawaj_app/src/services/auth_service.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

typedef _Call = ({String method, String path, bool skipAuthRefresh});

/// Records calls; `GET /me` answers [meResult], writes answer [writeResult].
class _FakeApi implements ApiClient {
  final calls = <_Call>[];
  Either<Failure, dynamic> meResult = const Right({
    'id': 'u1',
    'username': 'sarah',
    'display_name': 'Sarah',
  });
  Either<Failure, dynamic> writeResult = const Left(ServerFailure('wrong'));

  FutureEither<T> _answer<T>(
          Either<Failure, dynamic> r, T Function(dynamic) parse) async =>
      r.map(parse);

  @override
  FutureEither<T> get<T>(String path,
      {Map<String, dynamic>? query, required T Function(dynamic data) parse}) {
    calls.add((method: 'GET', path: path, skipAuthRefresh: false));
    return _answer(meResult, parse);
  }

  @override
  FutureEither<T> patch<T>(String path,
      {Object? body,
      Map<String, dynamic>? query,
      bool skipAuthRefresh = false,
      required T Function(dynamic data) parse}) {
    calls.add((method: 'PATCH', path: path, skipAuthRefresh: skipAuthRefresh));
    return _answer(writeResult, parse);
  }

  @override
  FutureEither<T> delete<T>(String path,
      {Object? body,
      Map<String, dynamic>? query,
      bool skipAuthRefresh = false,
      required T Function(dynamic data) parse}) {
    calls.add((method: 'DELETE', path: path, skipAuthRefresh: skipAuthRefresh));
    return _answer(writeResult, parse);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeApi api;
  late AuthService service;

  setUp(() {
    api = _FakeApi();
    service = AuthService.test(api: api);
  });

  // 401 on these endpoints means "wrong password". A refresh-and-retry would
  // replay it and count twice toward the server lockout, so the call opts out
  // and a GET /me first refreshes an expired access token instead.
  group('password-confirmed calls skip the 401 refresh-retry', () {
    test('changePassword pre-flights GET /me, then PATCHes without retry',
        () async {
      final result = await service.changePassword(
          oldPassword: 'bad', newPassword: 'NewPassword1!');

      expect(result.isLeft(), isTrue);
      expect(api.calls, [
        (method: 'GET', path: '/me', skipAuthRefresh: false),
        (method: 'PATCH', path: '/me/password', skipAuthRefresh: true),
      ]);
    });

    test('changePassword stops when the session pre-flight fails', () async {
      api.meResult = const Left(ServerFailure('expired'));

      final result = await service.changePassword(
          oldPassword: 'x', newPassword: 'NewPassword1!');

      expect(result.isLeft(), isTrue);
      expect(api.calls.map((c) => c.method), ['GET']);
    });

    test('deleteAccount pre-flights GET /me, then DELETEs without retry',
        () async {
      final result = await service.deleteAccount(password: 'bad');

      expect(result.isLeft(), isTrue);
      expect(api.calls, [
        (method: 'GET', path: '/me', skipAuthRefresh: false),
        (method: 'DELETE', path: '/me', skipAuthRefresh: true),
      ]);
    });
  });
}
