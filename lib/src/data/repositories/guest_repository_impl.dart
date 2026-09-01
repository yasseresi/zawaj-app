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
}
