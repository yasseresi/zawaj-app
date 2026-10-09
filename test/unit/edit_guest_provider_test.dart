import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/models/guest_model.dart';
import 'package:zawaj_app/src/data/repositories/guest_repository.dart';
import 'package:zawaj_app/src/ui/weddings/providers/edit_guest_provider.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

typedef _Call = ({
  String? fullName,
  String? contact,
  String? relationship,
  String? status,
  int? companions,
  String? tableLabel,
  String? meal,
});

class _FakeGuestRepository implements GuestRepository {
  Either<Failure, Guest>? updateResult;
  final calls = <_Call>[];

  @override
  FutureEither<Guest> update(
    String weddingId,
    String guestId, {
    String? fullName,
    String? contact,
    String? relationship,
    String? status,
    int? companions,
    String? tableLabel,
    String? meal,
  }) async {
    calls.add((
      fullName: fullName,
      contact: contact,
      relationship: relationship,
      status: status,
      companions: companions,
      tableLabel: tableLabel,
      meal: meal,
    ));
    return updateResult!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _guest = Guest(
  id: 'g1',
  fullName: 'Amina',
  contact: '0672859965',
  relationship: 'Cousin',
  status: RsvpStatus.pending,
  companions: 2,
  tableLabel: '5',
  meal: '',
);

GuestFormValues _values({
  String fullName = 'Amina',
  String contact = '0672 85 99 65',
  String relationship = 'Cousin',
  RsvpStatus status = RsvpStatus.pending,
  int companions = 2,
}) =>
    GuestFormValues(
      fullName: fullName,
      contact: contact,
      relationship: relationship,
      status: status,
      companions: companions,
    );

void main() {
  late _FakeGuestRepository repo;
  late EditGuestProvider provider;

  setUp(() {
    repo = _FakeGuestRepository();
    provider =
        EditGuestProvider(weddingId: 'w1', guest: _guest, repository: repo);
  });

  test('the prefilled values are not dirty (phone formatting ignored)', () {
    expect(provider.isDirty(_values()), isFalse);
  });

  test('changing only companions sends only companions', () async {
    repo.updateResult = const Right(_guest);

    await provider.save(_values(companions: 3));

    expect(repo.calls.single, (
      fullName: null,
      contact: null,
      relationship: null,
      status: null,
      companions: 3,
      tableLabel: null,
      meal: null,
    ));
  });

  test('sends a normalized phone, trimmed text and status wire values',
      () async {
    repo.updateResult = const Right(_guest);

    await provider.save(_values(
        fullName: ' Amina B ',
        contact: '+213 551 23 45 67',
        status: RsvpStatus.confirmed,
        relationship: ' Aunt '));

    final call = repo.calls.single;
    expect(call.fullName, 'Amina B');
    expect(call.contact, '0551234567');
    expect(call.status, 'confirmed');
    expect(call.relationship, 'Aunt');
    expect(call.meal, isNull); // table/meal are no longer edited
  });

  test('clearing an optional field sends an empty string', () async {
    repo.updateResult = const Right(_guest);

    await provider.save(_values(contact: '', relationship: ' '));

    expect(repo.calls.single.contact, '');
    expect(repo.calls.single.relationship, '');
  });

  test('an unchanged legacy contact is not sent', () async {
    const legacy = Guest(id: 'g2', fullName: 'Ali', contact: 'ali@x.dz');
    final p =
        EditGuestProvider(weddingId: 'w1', guest: legacy, repository: repo);
    repo.updateResult = const Right(legacy);

    expect(p.legacyContact, 'ali@x.dz');
    await p.save(const GuestFormValues(
        fullName: 'Ali B',
        contact: 'ali@x.dz',
        relationship: '',
        status: RsvpStatus.pending,
        companions: 0));

    expect(repo.calls.single.contact, isNull);
    expect(repo.calls.single.fullName, 'Ali B');
  });

  test('a phone contact has no legacy value', () {
    expect(provider.legacyContact, isNull);
  });

  test('no request when nothing changed; null + error on failure', () async {
    expect(await provider.save(_values()), _guest);
    expect(repo.calls, isEmpty);

    repo.updateResult = const Left(ServerFailure('boom'));
    expect(await provider.save(_values(fullName: 'X')), isNull);
    expect(provider.errorMessage, isNotNull);
    expect(provider.isSaving, isFalse);
  });
}
