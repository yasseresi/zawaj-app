import '../models/guest_detail_model.dart';
import '../models/guest_model.dart';
import '../../services/guest_service.dart';
import '../../utils/typedefs.dart';
import 'guest_repository.dart';

/// Default [GuestRepository] backed by [GuestService] (the live HTTP transport).
class GuestRepositoryImpl implements GuestRepository {
  GuestRepositoryImpl({GuestService? service})
      : _service = service ?? GuestService.instance;

  final GuestService _service;

  @override
  FutureEither<GuestListResult> list(
    String weddingId, {
    String? status,
    String? query,
  }) =>
      _service.list(weddingId, status: status, query: query);

  @override
  FutureEither<GuestDetail> get(String weddingId, String guestId) =>
      _service.get(weddingId, guestId);

  @override
  FutureEither<Guest> create(
    String weddingId, {
    required String fullName,
    String? contact,
    String? relationship,
    String? status,
    int? companions,
    String? tableLabel,
    String? meal,
    String? note,
  }) =>
      _service.create(
        weddingId,
        fullName: fullName,
        contact: contact,
        relationship: relationship,
        status: status,
        companions: companions,
        tableLabel: tableLabel,
        meal: meal,
        note: note,
      );

  @override
  FutureEither<Guest> setStatus(String weddingId, String guestId, String status) =>
      _service.setStatus(weddingId, guestId, status);

  @override
  FutureEither<GuestNote> addNote(String weddingId, String guestId, String body) =>
      _service.addNote(weddingId, guestId, body);

  @override
  FutureEither<int> sendReminders(String weddingId) =>
      _service.sendReminders(weddingId);
}
