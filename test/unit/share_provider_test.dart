import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/models/invite_link_model.dart';
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

  @override
  FutureEither<List<WeddingMember>> members(String id) async =>
      const Right([_owner, _omar]);

  @override
  FutureEither<List<InviteLink>> listInviteLinks(String id) async {
    linkCalls++;
    return const Right([InviteLink(id: 'l1', token: 't', role: 'viewer')]);
  }

  @override
  FutureEither<void> setMemberRole(
      String id, String userId, String role) async {
    roleCalls.add((userId, role));
    await setRoleGate?.future;
    return setRoleResult;
  }

  Either<Failure, void> revokeResult = const Right(null);
  final revoked = <String>[];

  @override
  FutureEither<void> revokeInviteLink(String id, String linkId) async {
    revoked.add(linkId);
    return revokeResult;
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

  test('InviteLink parses created_at', () {
    final link = InviteLink.fromJson(const {
      'id': 'l1',
      'token': 't',
      'role': 'editor',
      'created_at': '2026-10-01T10:00:00Z',
    });
    expect(link.createdAt, DateTime.utc(2026, 10, 1, 10));
  });
}
