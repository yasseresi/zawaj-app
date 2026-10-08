import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/models/invite_link_model.dart';
import 'package:zawaj_app/src/data/models/join_request_model.dart';
import 'package:zawaj_app/src/data/models/wedding_member_model.dart';
import 'package:zawaj_app/src/data/models/wedding_model.dart';
import 'package:zawaj_app/src/data/repositories/invite_repository.dart';
import 'package:zawaj_app/src/data/repositories/wedding_repository.dart';
import 'package:zawaj_app/src/shared/enums/app_status.dart';
import 'package:zawaj_app/src/ui/share/providers/share_provider.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

const _owner = WeddingMember(
    userId: 'u1',
    username: 'sarah',
    displayName: 'Sarah',
    role: WeddingRole.owner);
const _omar = WeddingMember(
    userId: 'u2',
    username: 'omar',
    displayName: 'Omar',
    role: WeddingRole.editor);

const _request = JoinRequest(
    id: 'r1',
    userId: 'u3',
    username: 'lina',
    displayName: 'Lina',
    role: WeddingRole.editor);

Wedding _wedding(WeddingRole role) =>
    Wedding(id: 'w1', name: 'L&O', ownerId: 'u1', role: role);

class _FakeWeddingRepository implements WeddingRepository {
  Either<Failure, Wedding>? getResult;
  Either<Failure, void> setRoleResult = const Right(null);
  Completer<void>? setRoleGate;
  int linkCalls = 0;
  int getCalls = 0;
  final roleCalls = <(String, String)>[];

  @override
  FutureEither<Wedding> get(String id) async {
    getCalls++;
    return getResult!;
  }

  bool membersThrow = false;

  @override
  FutureEither<List<WeddingMember>> members(String id) async {
    memberCalls++;
    if (membersThrow) throw StateError('reload blew up');
    return _members();
  }

  Either<Failure, List<WeddingMember>> _members() =>
      Right(transferred
          ? [
              _owner.copyWith(role: WeddingRole.editor),
              _omar.copyWith(role: WeddingRole.owner)
            ]
          : const [_owner, _omar]);

  List<InviteLink> linkList = const [
    InviteLink(id: 'l1', token: 't', role: 'viewer')
  ];

  @override
  FutureEither<List<InviteLink>> listInviteLinks(String id) async {
    linkCalls++;
    return Right(linkList);
  }

  @override
  FutureEither<void> setMemberRole(
      String id, String userId, String role) async {
    roleCalls.add((userId, role));
    await setRoleGate?.future;
    return setRoleResult;
  }

  Either<Failure, void> transferResult = const Right(null);
  final transfers = <String>[];
  bool transferred = false;

  @override
  FutureEither<void> transferOwnership(String id, String userId) async {
    transfers.add(userId);
    transferred = transferResult.isRight();
    return transferResult;
  }

  Either<Failure, void> revokeResult = const Right(null);
  final revoked = <String>[];

  @override
  FutureEither<void> revokeInviteLink(String id, String linkId) async {
    revoked.add(linkId);
    return revokeResult;
  }

  @override
  FutureEither<void> removeMember(String id, String userId) async =>
      const Right(null);

  // Join requests (owner review).
  List<JoinRequest> requestList = const [_request];
  int requestCalls = 0;
  int memberCalls = 0;
  Either<Failure, void> approveResult = const Right(null);
  Either<Failure, void> declineResult = const Right(null);
  final approvals = <(String, WeddingRole?)>[];
  final declines = <String>[];

  @override
  FutureEither<List<JoinRequest>> listJoinRequests(String weddingId) async {
    requestCalls++;
    return Right(requestList);
  }

  bool approveThrows = false;

  @override
  FutureEither<void> approveJoinRequest(String weddingId, String requestId,
      {WeddingRole? role}) async {
    approvals.add((requestId, role));
    if (approveThrows) throw StateError('transport blew up');
    return approveResult;
  }

  @override
  FutureEither<void> declineJoinRequest(
      String weddingId, String requestId) async {
    declines.add(requestId);
    return declineResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _UnusedInviteRepository implements InviteRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

ShareProvider _provider(_FakeWeddingRepository repo, {Wedding? wedding}) =>
    ShareProvider(
      weddingId: 'w1',
      wedding: wedding,
      weddingRepository: repo,
      inviteRepository: _UnusedInviteRepository(),
    );

void main() {
  group('role awareness', () {
    test('owner loads members and invite links', () async {
      final repo = _FakeWeddingRepository();
      final p = _provider(repo, wedding: _wedding(WeddingRole.owner));

      await p.load();

      expect(p.isOwner, isTrue);
      expect(p.status, AppStatus.success);
      expect(p.links, hasLength(1));
    });

    test('editors never request the owner-only invite links', () async {
      final repo = _FakeWeddingRepository();
      final p = _provider(repo, wedding: _wedding(WeddingRole.editor));

      await p.load();

      expect(p.isOwner, isFalse);
      expect(p.status, AppStatus.success);
      expect(p.errorMessage, isNull);
      expect(repo.linkCalls, 0);
      expect(p.members, [_owner, _omar]);
    });

    test('without a wedding the role is fetched first', () async {
      final repo = _FakeWeddingRepository()
        ..getResult = Right(_wedding(WeddingRole.owner));
      final p = _provider(repo);

      await p.load();

      expect(repo.getCalls, 1);
      expect(p.isOwner, isTrue);
      expect(repo.linkCalls, 1);
    });
  });

  group('setRole', () {
    test('updates the member immediately and keeps it on success', () async {
      final repo = _FakeWeddingRepository()..setRoleGate = Completer<void>();
      final p = _provider(repo, wedding: _wedding(WeddingRole.owner));
      await p.load();

      final pending = p.setRole('u2', WeddingRole.viewer);
      expect(p.members.last.role, WeddingRole.viewer); // optimistic
      repo.setRoleGate!.complete();

      expect(await pending, isTrue);
      expect(repo.roleCalls.single, ('u2', 'viewer'));
      expect(p.members.last.role, WeddingRole.viewer);
    });

    test('rolls back and exposes the error on failure', () async {
      final repo = _FakeWeddingRepository()
        ..setRoleResult = const Left(ForbiddenFailure('no'));
      final p = _provider(repo, wedding: _wedding(WeddingRole.owner));
      await p.load();

      expect(await p.setRole('u2', WeddingRole.viewer), isFalse);
      expect(p.members.last.role, WeddingRole.editor);
      expect(p.errorMessage, isNotNull);
    });

    test('is a no-op for the same role', () async {
      final repo = _FakeWeddingRepository();
      final p = _provider(repo, wedding: _wedding(WeddingRole.owner));
      await p.load();

      expect(await p.setRole('u2', WeddingRole.editor), isTrue);
      expect(repo.roleCalls, isEmpty);
    });
  });

  group('revokeLink', () {
    test('drops the link from the active list', () async {
      final repo = _FakeWeddingRepository();
      final p = _provider(repo, wedding: _wedding(WeddingRole.owner));
      await p.load();
      expect(p.link?.id, 'l1');

      expect(await p.revokeLink('l1'), isTrue);

      expect(repo.revoked.single, 'l1');
      expect(p.activeLinks, isEmpty);
      expect(p.link, isNull); // the shown link/QR clears
    });

    test('an already-revoked link (404) counts as success', () async {
      final repo = _FakeWeddingRepository()
        ..revokeResult = const Left(NotFoundFailure('gone'));
      final p = _provider(repo, wedding: _wedding(WeddingRole.owner));
      await p.load();

      expect(await p.revokeLink('l1'), isTrue);
      expect(p.activeLinks, isEmpty);
    });

    test('other failures keep the link and expose the error', () async {
      final repo = _FakeWeddingRepository()
        ..revokeResult = const Left(ServerFailure('boom'));
      final p = _provider(repo, wedding: _wedding(WeddingRole.owner));
      await p.load();

      expect(await p.revokeLink('l1'), isFalse);
      expect(p.activeLinks, hasLength(1));
      expect(p.errorMessage, isNotNull);
    });
  });

  group('join requests', () {
    test('owners load pending requests; editors never ask', () async {
      final owner = _FakeWeddingRepository();
      final p = _provider(owner, wedding: _wedding(WeddingRole.owner));
      await p.load();
      expect(p.joinRequests, [_request]);

      final editor = _FakeWeddingRepository();
      await _provider(editor, wedding: _wedding(WeddingRole.editor)).load();
      expect(editor.requestCalls, 0);
    });

    test('approve removes the row at once and reloads members', () async {
      final repo = _FakeWeddingRepository();
      final p = _provider(repo, wedding: _wedding(WeddingRole.owner));
      await p.load();
      final membersBefore = repo.memberCalls;

      expect(await p.approveRequest(_request, role: WeddingRole.viewer), isTrue);

      expect(repo.approvals.single, ('r1', WeddingRole.viewer));
      expect(p.joinRequests, isEmpty);
      expect(repo.memberCalls, membersBefore + 1);
    });

    test('approving at the requested role sends no role', () async {
      final repo = _FakeWeddingRepository();
      final p = _provider(repo, wedding: _wedding(WeddingRole.owner));
      await p.load();

      await p.approveRequest(_request, role: WeddingRole.editor);
      expect(repo.approvals.single, ('r1', null));
    });

    test('a failed approval puts the row back and exposes the error', () async {
      final repo = _FakeWeddingRepository()
        ..approveResult = const Left(ServerFailure('boom'));
      final p = _provider(repo, wedding: _wedding(WeddingRole.owner));
      await p.load();

      expect(await p.approveRequest(_request), isFalse);
      expect(p.joinRequests, [_request]);
      expect(p.errorMessage, isNotNull);
    });

    test('a request already decided elsewhere (404) refreshes the list',
        () async {
      final repo = _FakeWeddingRepository()
        ..approveResult = const Left(NotFoundFailure('gone'));
      final p = _provider(repo, wedding: _wedding(WeddingRole.owner));
      await p.load();
      repo.requestList = const [];

      expect(await p.approveRequest(_request), isFalse);
      expect(p.joinRequests, isEmpty);
      expect(p.errorMessage, 'share.request_already_handled');
    });

    test('decline removes the row; failure puts it back', () async {
      final repo = _FakeWeddingRepository();
      final p = _provider(repo, wedding: _wedding(WeddingRole.owner));
      await p.load();
      expect(await p.declineRequest(_request), isTrue);
      expect(repo.declines.single, 'r1');
      expect(p.joinRequests, isEmpty);

      final failing = _FakeWeddingRepository()
        ..declineResult = const Left(ServerFailure('boom'));
      final q = _provider(failing, wedding: _wedding(WeddingRole.owner));
      await q.load();
      expect(await q.declineRequest(_request), isFalse);
      expect(q.joinRequests, [_request]);
    });

    test('a decision that throws still clears the in-flight guard', () async {
      final repo = _FakeWeddingRepository()..approveThrows = true;
      final p = _provider(repo, wedding: _wedding(WeddingRole.owner));
      await p.load();

      await expectLater(p.approveRequest(_request), throwsStateError);
      expect(p.isDeciding('r1'), isFalse);
      expect(p.joinRequests, [_request]);
    });

    test('an approval stays approved if the follow-up reload throws',
        () async {
      final repo = _FakeWeddingRepository();
      final p = _provider(repo, wedding: _wedding(WeddingRole.owner));
      await p.load();
      repo.membersThrow = true;

      expect(await p.approveRequest(_request), isTrue);
      expect(p.joinRequests, isEmpty); // not put back
      expect(p.isDeciding('r1'), isFalse);
    });

    test('ignores a second decision while one is in flight', () async {
      final repo = _FakeWeddingRepository();
      final p = _provider(repo, wedding: _wedding(WeddingRole.owner));
      await p.load();

      final first = p.approveRequest(_request);
      expect(p.isDeciding('r1'), isTrue);
      expect(await p.declineRequest(_request), isFalse);
      await first;
      expect(repo.declines, isEmpty);
    });
  });

  test('InviteLink parses created_at', () {
    final link = InviteLink.fromJson(const {
      'id': 'l1',
      'token': 't',
      'role': 'editor',
      'created_at': '2026-10-01T10:00:00Z',
    });
    expect(link.createdAt, DateTime.utc(2026, 10, 1, 10));
  });

  group('transferOwnership', () {
    test('demotes the caller to editor and reloads members', () async {
      final repo = _FakeWeddingRepository();
      final p = _provider(repo, wedding: _wedding(WeddingRole.owner));
      await p.load();

      expect(await p.transferOwnership('u2'), isTrue);

      expect(repo.transfers.single, 'u2');
      expect(p.isOwner, isFalse);
      expect(p.role, WeddingRole.editor);
      expect(p.members.firstWhere((m) => m.userId == 'u2').role,
          WeddingRole.owner);
      expect(p.links, isEmpty); // owner-only data is dropped
    });

    test('keeps ownership and exposes the error on failure', () async {
      final repo = _FakeWeddingRepository()
        ..transferResult = const Left(ValidationFailure('bad'));
      final p = _provider(repo, wedding: _wedding(WeddingRole.owner));
      await p.load();

      expect(await p.transferOwnership('u2'), isFalse);
      expect(p.isOwner, isTrue);
      expect(p.errorMessage, isNotNull);
    });
  });
}
