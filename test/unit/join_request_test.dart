import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/models/join_request_model.dart';
import 'package:zawaj_app/src/data/models/wedding_model.dart';
import 'package:zawaj_app/src/data/services/api_client.dart';
import 'package:zawaj_app/src/services/wedding_service.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

typedef _Call = ({String method, String path, Object? body});

/// Records calls and answers [reply] (already-unwrapped envelope `data`).
class _FakeApi implements ApiClient {
  final calls = <_Call>[];
  Either<Failure, dynamic> reply = const Right(null);

  FutureEither<T> _answer<T>(T Function(dynamic) parse) async =>
      reply.map(parse);

  @override
  FutureEither<T> get<T>(String path,
      {Map<String, dynamic>? query, required T Function(dynamic data) parse}) {
    calls.add((method: 'GET', path: path, body: null));
    return _answer(parse);
  }

  @override
  FutureEither<T> post<T>(String path,
      {Object? body,
      Map<String, dynamic>? query,
      Map<String, dynamic>? headers,
      required T Function(dynamic data) parse}) {
    calls.add((method: 'POST', path: path, body: body));
    return _answer(parse);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('JoinResult.fromJson', () {
    test('pending request carries its id', () {
      final r = JoinResult.fromJson(const {
        'wedding_id': 'w1',
        'wedding_name': 'L&O',
        'role': 'editor',
        'status': 'pending',
        'request_id': 'r1',
      });
      expect(r.isPending, isTrue);
      expect(r.requestId, 'r1');
      expect(r.role, WeddingRole.editor);
      expect(r.weddingName, 'L&O');
    });

    test('member outcome (already in the wedding)', () {
      final r = JoinResult.fromJson(const {
        'wedding_id': 'w1',
        'wedding_name': 'L&O',
        'role': 'owner',
        'status': 'member',
      });
      expect(r.isPending, isFalse);
      expect(r.requestId, isNull);
      expect(r.role, WeddingRole.owner);
    });
  });

  test('JoinRequest.fromJson and display helpers', () {
    final j = JoinRequest.fromJson(const {
      'id': 'r1',
      'user_id': 'u2',
      'username': 'omar',
      'display_name': '',
      'role': 'viewer',
      'created_at': '2026-10-08T09:30:00Z',
    });
    expect(j.id, 'r1');
    expect(j.role, WeddingRole.viewer);
    expect(j.label, 'omar'); // falls back to the username
    expect(j.avatarInitial, 'o');
    expect(j.createdAt, DateTime.utc(2026, 10, 8, 9, 30));
  });

  test('avatar initial keeps a whole emoji / grapheme', () {
    const j = JoinRequest(
        id: 'r1',
        userId: 'u2',
        username: 'x',
        displayName: '🎉 Party',
        role: WeddingRole.viewer);
    expect(j.avatarInitial, '🎉');
  });

  group('WeddingService join-request contract', () {
    late _FakeApi api;
    late WeddingService service;

    setUp(() {
      api = _FakeApi();
      service = WeddingService.test(api: api);
    });

    test('acceptInviteLink posts to the token and parses the outcome',
        () async {
      api.reply = const Right({
        'wedding_id': 'w1',
        'wedding_name': 'L&O',
        'role': 'editor',
        'status': 'pending',
        'request_id': 'r1',
      });
      final result = await service.acceptInviteLink('TOK');

      expect(api.calls.single,
          (method: 'POST', path: '/invite/TOK/accept', body: null));
      expect(result.getOrElse((_) => throw 'failed').isPending, isTrue);
    });

    test('the token is URL-encoded into the path', () async {
      api.reply = const Right({'status': 'pending'});
      await service.acceptInviteLink('A/B');
      expect(api.calls.single.path, '/invite/A%2FB/accept');
    });

    test('listJoinRequests reads the items list', () async {
      api.reply = const Right({
        'items': [
          {'id': 'r1', 'user_id': 'u2', 'username': 'omar', 'role': 'editor'}
        ]
      });
      final result = await service.listJoinRequests('w1');

      expect(api.calls.single.path, '/weddings/w1/join-requests');
      expect(result.getOrElse((_) => const []).single.username, 'omar');
    });

    test('approve sends the role only when lowering it', () async {
      await service.approveJoinRequest('w1', 'r1');
      await service.approveJoinRequest('w1', 'r1', role: WeddingRole.viewer);

      expect(api.calls[0], (
        method: 'POST',
        path: '/weddings/w1/join-requests/r1/approve',
        body: null
      ));
      expect(api.calls[1].body, {'role': 'viewer'});
    });

    test('decline posts to the request', () async {
      await service.declineJoinRequest('w1', 'r1');
      expect(api.calls.single, (
        method: 'POST',
        path: '/weddings/w1/join-requests/r1/decline',
        body: null
      ));
    });
  });
}
