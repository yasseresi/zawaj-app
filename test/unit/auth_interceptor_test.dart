import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/config/auth_interceptor.dart';

/// In-memory tokens, recording what the interceptor saves and clears.
class _Tokens implements AuthTokens {
  _Tokens({this.access, this.refresh});
  String? access;
  String? refresh;
  int clears = 0;

  @override
  Future<String?> get accessToken async => access;
  @override
  Future<String?> get refreshToken async => refresh;
  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<void> clear() async {
    clears++;
    access = refresh = null;
  }
}

/// Answers by path: `/auth/refresh` issues new tokens (or fails), anything
/// else is 200 only with the current valid access token, else 401.
class _Server implements HttpClientAdapter {
  _Server({this.refreshWorks = true});
  String validAccess = 'new-access';
  String issuedAccess = 'new-access';
  bool refreshWorks;
  final requests = <RequestOptions>[];
  int refreshCalls = 0;
  Completer<void>? refreshGate;

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? body,
      Future<void>? cancelFuture) async {
    requests.add(o);
    if (o.path.endsWith('/auth/refresh')) {
      refreshCalls++;
      await refreshGate?.future;
      return refreshWorks
          ? _json(200, {
              'data': {'access': issuedAccess, 'refresh': 'new-refresh'}
            })
          : _json(401, {
              'data': null,
              'error': {'code': 'unauthenticated', 'message': 'expired'}
            });
    }
    final ok = o.headers['Authorization'] == 'Bearer $validAccess';
    return ok
        ? _json(200, {
            'data': {'ok': true}
          })
        : _json(401, {
            'data': null,
            'error': {'code': 'unauthenticated', 'message': 'token expired'}
          });
  }

  ResponseBody _json(int status, Object body) => ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        },
      );

  @override
  void close({bool force = false}) {}
}

({Dio dio, _Server server, _Tokens tokens, List<int> expired}) _setup(
    {String access = 'old-access', bool refreshWorks = true}) {
  final server = _Server(refreshWorks: refreshWorks);
  final tokens = _Tokens(access: access, refresh: 'old-refresh');
  final expired = <int>[];
  final options = BaseOptions(baseUrl: 'https://api.test');
  final dio = Dio(options)..httpClientAdapter = server;
  final refreshDio = Dio(options)..httpClientAdapter = server;
  dio.interceptors.add(AuthInterceptor(
    dio: dio,
    refreshDio: refreshDio,
    tokens: tokens,
    onSessionExpired: () => expired.add(1),
  ));
  return (dio: dio, server: server, tokens: tokens, expired: expired);
}

void main() {
  test('attaches the bearer token and a request id', () async {
    final s = _setup(access: 'new-access');
    await s.dio.get<dynamic>('/weddings');
    final sent = s.server.requests.single;
    expect(sent.headers['Authorization'], 'Bearer new-access');
    expect(sent.headers['X-Request-ID'], isNotEmpty);
  });

  test('a 401 refreshes once, saves the new pair and retries', () async {
    final s = _setup();
    final res = await s.dio.get<dynamic>('/weddings');

    expect(res.statusCode, 200);
    expect(s.server.refreshCalls, 1);
    expect((s.tokens.access, s.tokens.refresh), ('new-access', 'new-refresh'));
    final paths = s.server.requests.map((r) => r.path).toList();
    expect(paths, ['/weddings', '/auth/refresh', '/weddings']);
    expect(
        s.server.requests.last.headers['Authorization'], 'Bearer new-access');
  });

  test('concurrent 401s share a single refresh', () async {
    final s = _setup();
    s.server.refreshGate = Completer<void>();
    final calls = [
      s.dio.get<dynamic>('/a'),
      s.dio.get<dynamic>('/b'),
      s.dio.get<dynamic>('/c')
    ];
    await Future<void>.delayed(Duration.zero);
    s.server.refreshGate!.complete();
    final results = await Future.wait(calls);

    expect(results.map((r) => r.statusCode), [200, 200, 200]);
    expect(s.server.refreshCalls, 1);
  });

  test('a failed refresh clears the session once and surfaces the 401',
      () async {
    final s = _setup(refreshWorks: false);
    await expectLater(
      s.dio.get<dynamic>('/weddings'),
      throwsA(isA<DioException>()
          .having((e) => e.response?.statusCode, 'status', 401)),
    );
    expect(s.tokens.clears, 1);
    expect(s.expired, [1]);
    expect(s.server.refreshCalls, 1); // no loop
  });

  test('skipAuthRefresh: a 401 is returned as is, no refresh', () async {
    final s = _setup();
    await expectLater(
      s.dio.delete<dynamic>('/me',
          options: Options(extra: {'skipAuthRefresh': true})),
      throwsA(isA<DioException>()),
    );
    expect(s.server.refreshCalls, 0);
    expect(s.tokens.clears, 0);
  });

  test('auth endpoints never trigger a refresh', () async {
    final s = _setup();
    await expectLater(
        s.dio.post<dynamic>('/auth/login'), throwsA(isA<DioException>()));
    expect(s.server.refreshCalls, 0);
  });

  test('a retried request that is still 401 is not refreshed again', () async {
    final s = _setup();
    s.server.validAccess =
        'never-valid'; // refresh "works", new token still bad
    await expectLater(
        s.dio.get<dynamic>('/weddings'), throwsA(isA<DioException>()));
    expect(s.server.refreshCalls, 1);
    expect(s.server.requests.where((r) => r.path == '/weddings'), hasLength(2));
  });
}
