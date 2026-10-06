import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/models/user_model.dart';
import 'package:zawaj_app/src/data/models/wedding_member_model.dart';
import 'package:zawaj_app/src/data/models/wedding_model.dart';
import 'package:zawaj_app/src/data/repositories/auth_repository.dart';
import 'package:zawaj_app/src/data/repositories/wedding_repository.dart';
import 'package:zawaj_app/src/shared/enums/app_status.dart';
import 'package:zawaj_app/src/ui/auth/providers/session_provider.dart';
import 'package:zawaj_app/src/ui/settings/providers/delete_account_provider.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

const _mine = Wedding(
    id: 'w1',
    name: 'Ours',
    ownerId: 'u1',
    role: WeddingRole.owner,
    guestCount: 80);
const _solo = Wedding(
    id: 'w2',
    name: 'Draft',
    ownerId: 'u1',
    role: WeddingRole.owner,
    guestCount: 3);
const _theirs =
    Wedding(id: 'w3', name: 'Cousin', ownerId: 'u9', role: WeddingRole.editor);

WeddingMember _member(String id, WeddingRole role) =>
    WeddingMember(userId: id, username: id, displayName: id, role: role);

class _FakeWeddingRepository implements WeddingRepository {
  int memberCalls = 0;

  @override
  FutureEither<List<Wedding>> myWeddings() async =>
      const Right([_mine, _solo, _theirs]);

  @override
  FutureEither<List<WeddingMember>> members(String id) async {
    memberCalls++;
    return Right(switch (id) {
      'w1' => [
          _member('u1', WeddingRole.owner),
          _member('u2', WeddingRole.editor),
          _member('u3', WeddingRole.viewer),
        ],
      _ => [_member('u1', WeddingRole.owner)],
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeAuthRepository implements AuthRepository {
  Either<Failure, void> deleteResult = const Right(null);

  @override
  FutureEitherVoid deleteAccount({required String password}) async =>
      deleteResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late _FakeWeddingRepository weddings;
  late _FakeAuthRepository auth;
  late SessionProvider session;
  late DeleteAccountProvider provider;

  setUp(() {
    weddings = _FakeWeddingRepository();
    auth = _FakeAuthRepository();
    session = SessionProvider(repository: auth)
      ..setAuthenticated(
          const AppUser(id: 'u1', username: 'sarah', displayName: 'Sarah'));
    provider =
        DeleteAccountProvider(weddingRepository: weddings, session: session);
  });

  test('summarizes owned weddings with collaborators and shared ones',
      () async {
    await provider.load();

    expect(provider.status, AppStatus.success);
    expect(provider.owned.map((o) => o.wedding.id), ['w1', 'w2']);
    expect(provider.owned.first.collaborators, 2);
    expect(provider.owned.last.collaborators, 0);
    expect(provider.sharedCount, 1);
    // Members are only fetched for owned weddings.
    expect(weddings.memberCalls, 2);
  });

  test('a successful delete ends the session', () async {
    final outcome = await provider.submit('Password123!');

    expect(outcome, DeleteOutcome.deleted);
    expect(session.isAuthenticated, isFalse);
  });

  test('a wrong password is reported inline and keeps the session', () async {
    auth.deleteResult = const Left(AuthFailure('password is incorrect'));

    final outcome = await provider.submit('nope');

    expect(outcome, DeleteOutcome.wrongPassword);
    expect(session.isAuthenticated, isTrue);
    expect(provider.isSubmitting, isFalse);
  });

  test('a locked account is reported as locked', () async {
    auth.deleteResult = const Left(ServerFailure('locked', code: 'locked'));

    expect(await provider.submit('x'), DeleteOutcome.locked);
  });

  test('other failures expose a message', () async {
    auth.deleteResult = const Left(ServerFailure('boom'));

    expect(await provider.submit('x'), DeleteOutcome.failed);
    expect(provider.errorMessage, isNotNull);
  });
}
