import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/models/invite_link_model.dart';
import 'package:zawaj_app/src/data/models/join_request_model.dart';
import 'package:zawaj_app/src/data/models/wedding_member_model.dart';
import 'package:zawaj_app/src/data/models/wedding_model.dart';
import 'package:zawaj_app/src/data/repositories/wedding_repository.dart';
import 'package:zawaj_app/src/ui/share/providers/invite_preview_provider.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _FakeWeddingRepository implements WeddingRepository {
  @override
  FutureEither<void> transferOwnership(String id, String userId) async =>
      throw UnimplementedError();

  @override
  FutureEither<Wedding> get(String id) async => throw UnimplementedError();

  @override
  FutureEither<Wedding> update(String id,
          {String? name, String? eventDate, String? description}) async =>
      throw UnimplementedError();

  Either<Failure, InvitePreview> previewResult = const Right(
    InvitePreview(
        weddingId: 'w1', weddingName: 'Leila & Karim', role: 'editor'),
  );
  Either<Failure, JoinResult> acceptResult = const Right(
    JoinResult(
        weddingId: 'w1',
        weddingName: 'Leila & Karim',
        role: WeddingRole.editor,
        isPending: true,
        requestId: 'r1'),
  );

  int previewCalls = 0;
  String? previewedToken;

  @override
  FutureEither<InvitePreview> previewInvite(String token) async {
    previewCalls++;
    previewedToken = token;
    return previewResult;
  }

  @override
  FutureEither<JoinResult> acceptInviteLink(String token) async => acceptResult;
  @override
  FutureEither<List<JoinRequest>> listJoinRequests(String weddingId) =>
      throw UnimplementedError();
  @override
  FutureEither<void> approveJoinRequest(String weddingId, String requestId,
          {WeddingRole? role}) =>
      throw UnimplementedError();
  @override
  FutureEither<void> declineJoinRequest(String weddingId, String requestId) =>
      throw UnimplementedError();

  @override
  FutureEither<InviteLink> createInviteLink(String id, String role) =>
      throw UnimplementedError();
  @override
  FutureEither<List<InviteLink>> listInviteLinks(String id) =>
      throw UnimplementedError();
  @override
  FutureEither<void> revokeInviteLink(String id, String linkId) =>
      throw UnimplementedError();
  @override
  FutureEither<List<Wedding>> myWeddings() => throw UnimplementedError();
  @override
  FutureEither<Wedding> create(
          {required String name, String? eventDate, String? description}) =>
      throw UnimplementedError();
  @override
  FutureEither<void> delete(String id) => throw UnimplementedError();
  @override
  FutureEither<List<WeddingMember>> members(String id) =>
      throw UnimplementedError();
  @override
  FutureEither<void> setMemberRole(String id, String userId, String role) =>
      throw UnimplementedError();
  @override
  FutureEither<void> removeMember(String id, String userId) =>
      throw UnimplementedError();
}

const _token = 'MFRGGZDFMZTWQ2LKNNWG23TP';

void main() {
  test('a lower-cased link is sent in canonical form', () async {
    final repo = _FakeWeddingRepository();
    await InvitePreviewProvider(token: _token.toLowerCase(), repository: repo)
        .load();
    expect(repo.previewedToken, _token);
  });

  test('a malformed token fails without calling the server', () async {
    final repo = _FakeWeddingRepository();
    final provider = InvitePreviewProvider(token: '../x', repository: repo);

    await provider.load();

    expect(repo.previewCalls, 0);
    expect(provider.preview, isNull);
    expect(provider.errorMessage, 'invites.invalid_link');
  });

  test('loads preview and accepts the invite through the repository', () async {
    final provider = InvitePreviewProvider(
      token: _token,
      repository: _FakeWeddingRepository(),
    );

    await provider.load();
    expect(provider.preview?.weddingId, 'w1');
    expect(provider.isLoading, isFalse);

    final accepted = await provider.accept();
    expect(accepted, isTrue);
    expect(provider.accepted?.weddingId, 'w1');
  });

  test('a removed user accepting a link sees why they were refused', () async {
    final provider = InvitePreviewProvider(
      token: _token,
      repository: _FakeWeddingRepository()
        ..acceptResult = const Left(
            ForbiddenFailure('removed', code: 'removed_from_wedding')),
    );
    await provider.load();

    expect(await provider.accept(), isFalse);
    expect(provider.errorMessage, 'invites.removed_from_wedding');
  });

  test('surfaces preview failures', () async {
    final provider = InvitePreviewProvider(
      token: _token,
      repository: _FakeWeddingRepository()
        ..previewResult = const Left(ServerFailure('invalid invite')),
    );

    await provider.load();

    expect(provider.errorMessage, 'invalid invite');
    expect(provider.preview, isNull);
  });
}
