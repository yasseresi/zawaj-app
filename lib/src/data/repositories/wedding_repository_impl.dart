import '../../services/wedding_service.dart';
import '../../utils/typedefs.dart';
import '../models/wedding_member_model.dart';
import '../models/invite_link_model.dart';
import '../models/join_request_model.dart';
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
      _service.create(
          name: name, eventDate: eventDate, description: description);

  @override
  FutureEither<Wedding> get(String id) => _service.get(id);

  @override
  FutureEither<Wedding> update(String id,
          {String? name, String? eventDate, String? description}) =>
      _service.update(id,
          name: name, eventDate: eventDate, description: description);

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

  @override
  FutureEither<void> transferOwnership(String id, String userId) =>
      _service.transferOwnership(id, userId);

  @override
  FutureEither<InviteLink> createInviteLink(String id, String role) =>
      _service.createInviteLink(id, role);
  @override
  FutureEither<List<InviteLink>> listInviteLinks(String id) =>
      _service.listInviteLinks(id);
  @override
  FutureEither<void> revokeInviteLink(String id, String linkId) =>
      _service.revokeInviteLink(id, linkId);

  @override
  FutureEither<InvitePreview> previewInvite(String token) =>
      _service.previewInvite(token);

  @override
  FutureEither<JoinResult> acceptInviteLink(String token) =>
      _service.acceptInviteLink(token);

  @override
  FutureEither<List<JoinRequest>> listJoinRequests(String weddingId) =>
      _service.listJoinRequests(weddingId);

  @override
  FutureEither<void> approveJoinRequest(String weddingId, String requestId,
          {WeddingRole? role}) =>
      _service.approveJoinRequest(weddingId, requestId, role: role);

  @override
  FutureEither<void> declineJoinRequest(String weddingId, String requestId) =>
      _service.declineJoinRequest(weddingId, requestId);
}
