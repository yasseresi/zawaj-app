import '../models/pending_invite_model.dart';
import '../../utils/typedefs.dart';

/// Data boundary for the current user's collaborator invites (screen 10).
/// Providers depend on this interface (not the service) so they can be tested
/// with a fake.
abstract interface class InviteRepository {
  /// `GET /invites` — the caller's pending invites.
  FutureEither<List<PendingInvite>> list();

  /// `POST /invites/:id/accept` — join the wedding per the invite's role.
  FutureEither<void> accept(String inviteId);

  /// `POST /invites/:id/decline` — dismiss the invite.
  FutureEither<void> decline(String inviteId);
}
