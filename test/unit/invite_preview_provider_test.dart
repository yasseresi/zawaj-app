import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/models/invite_link_model.dart';
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
  Either<Failure, InvitePreview> acceptResult = const Right(
    InvitePreview(
        weddingId: 'w1', weddingName: 'Leila & Karim', role: 'editor'),
  );

  @override
  FutureEither<InvitePreview> previewInvite(String token) async =>
      previewResult;

  @override
  FutureEither<InvitePreview> acceptInviteLink(String token) async =>
      acceptResult;

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

void main() {
  test('loads preview and accepts the invite through the repository', () async {
    final provider = InvitePreviewProvider(
      token: 'TOKEN',
      repository: _FakeWeddingRepository(),
    );

    await provider.load();
    expect(provider.preview?.weddingId, 'w1');
    expect(provider.isLoading, isFalse);

    final accepted = await provider.accept();
    expect(accepted, isTrue);
    expect(provider.accepted?.weddingId, 'w1');
  });

  test('surfaces preview failures', () async {
    final provider = InvitePreviewProvider(
      token: 'TOKEN',
      repository: _FakeWeddingRepository()
        ..previewResult = const Left(ServerFailure('invalid invite')),
    );

    await provider.load();

    expect(provider.errorMessage, 'invalid invite');
    expect(provider.preview, isNull);
  });
}
