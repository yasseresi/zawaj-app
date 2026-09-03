import '../../services/wedding_service.dart';
import '../../utils/typedefs.dart';
import '../models/wedding_member_model.dart';
import '../models/wedding_model.dart';
import 'wedding_repository.dart';

/// Delegates to [WeddingService] (which owns the HTTP calls). Kept as a seam so
/// providers depend on the [WeddingRepository] interface and can be faked.
class WeddingRepositoryImpl implements WeddingRepository {
  WeddingRepositoryImpl({WeddingService? service})
      : _service = service ?? WeddingService.instance;

  final WeddingService _service;

  @override
  FutureEither<List<Wedding>> myWeddings() => _service.list();

  @override
  FutureEither<Wedding> create({
    required String name,
    String? eventDate,
    String? description,
  }) =>
      _service.create(name: name, eventDate: eventDate, description: description);

  @override
  FutureEither<void> delete(String id) => _service.delete(id);

  @override
  FutureEither<List<WeddingMember>> members(String id) => _service.members(id);

  @override
  FutureEither<void> setMemberRole(String id, String userId, String role) =>
      _service.setMemberRole(id, userId, role);

  @override
  FutureEither<void> removeMember(String id, String userId) =>
      _service.removeMember(id, userId);
}
