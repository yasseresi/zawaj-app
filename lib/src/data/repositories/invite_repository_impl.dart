import '../models/pending_invite_model.dart';
import '../../services/invite_service.dart';
import '../../utils/typedefs.dart';
import 'invite_repository.dart';

/// Default [InviteRepository] backed by [InviteService] (live HTTP).
class InviteRepositoryImpl implements InviteRepository {
  InviteRepositoryImpl({InviteService? service})
      : _service = service ?? InviteService.instance;

  final InviteService _service;

  @override
  FutureEither<List<PendingInvite>> list() => _service.list();

  @override
  FutureEither<void> accept(String inviteId) => _service.accept(inviteId);

  @override
  FutureEither<void> decline(String inviteId) => _service.decline(inviteId);

  @override
  FutureEither<void> invite(String weddingId, String username, String role) =>
      _service.invite(weddingId, username, role);
}
