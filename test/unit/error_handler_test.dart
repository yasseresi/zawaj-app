import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/utils/error_handler.dart';
import 'package:zawaj_app/src/utils/failure.dart';

DioException _dioWith({int? status, dynamic data, DioExceptionType type = DioExceptionType.badResponse}) {
  final req = RequestOptions(path: '/x');
  return DioException(
    requestOptions: req,
    type: type,
    response: status == null && data == null
        ? null
        : Response<dynamic>(requestOptions: req, statusCode: status, data: data),
  );
}

void main() {
  group('AppErrorHandler.toFailure — envelope mapping', () {
    test('validation_error -> ValidationFailure with server message', () {
      final f = AppErrorHandler.toFailure(_dioWith(
        status: 400,
        data: {
          'data': null,
          'error': {'code': 'validation_error', 'message': 'username too short'},
        },
      ));
      expect(f, isA<ValidationFailure>());
      expect(f.code, 'validation_error');
      expect(f.message, 'username too short');
    });

    test('unauthenticated -> AuthFailure', () {
      final f = AppErrorHandler.toFailure(_dioWith(
        status: 401,
        data: {'error': {'code': 'unauthenticated', 'message': 'invalid username or password'}},
      ));
      expect(f, isA<AuthFailure>());
    });

    test('conflict -> ConflictFailure', () {
      final f = AppErrorHandler.toFailure(_dioWith(
        status: 409,
        data: {'error': {'code': 'conflict', 'message': 'username already taken'}},
      ));
      expect(f, isA<ConflictFailure>());
    });

    test('locked -> LockedFailure', () {
      final f = AppErrorHandler.toFailure(_dioWith(
        status: 423,
        data: {'error': {'code': 'locked', 'message': 'account locked'}},
      ));
      expect(f, isA<LockedFailure>());
    });
  });

  group('AppErrorHandler.toFailure — transport', () {
    test('connection timeout -> NetworkFailure', () {
      final f = AppErrorHandler.toFailure(_dioWith(type: DioExceptionType.connectionTimeout));
      expect(f, isA<NetworkFailure>());
    });

    test('connection error -> NetworkFailure', () {
      final f = AppErrorHandler.toFailure(_dioWith(type: DioExceptionType.connectionError));
      expect(f, isA<NetworkFailure>());
    });

    test('bare 500 without envelope -> ServerFailure', () {
      final f = AppErrorHandler.toFailure(_dioWith(status: 500, data: 'oops'));
      expect(f, isA<ServerFailure>());
    });
  });

  test('non-Dio error -> UnknownFailure', () {
    final f = AppErrorHandler.toFailure(StateError('boom'));
    expect(f, isA<UnknownFailure>());
  });
}
