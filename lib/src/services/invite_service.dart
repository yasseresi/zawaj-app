import '../data/models/pending_invite_model.dart';
import '../data/services/api_client.dart';
import '../utils/typedefs.dart';

/// API surface for the current user's collaborator invites (screen 10). Pure
/// transport.
///
/// Backend contract: `GET /invites` returns `{ items }`; `POST /invites/:id/
/// accept` grants membership; `POST /invites/:id/decline` dismisses it. All
/// under the standard `{data,error}` envelope.
class InviteService {
  InviteService._();
  static final InviteService instance = InviteService._();

  final ApiClient _api = ApiClient.instance;

  /// `GET /invites` → the caller's pending invites.
  FutureEither<List<PendingInvite>> list() => _api.get<List<PendingInvite>>(
        '/invites',
        parse: (data) {
          final map = data is Map ? data.cast<String, dynamic>() : const <String, dynamic>{};
          final items = map['items'];
          return [
            if (items is List)
              for (final e in items)
                if (e is Map) PendingInvite.fromJson(e.cast<String, dynamic>()),
          ];
        },
      );

  /// `POST /invites/:id/accept` → join the wedding per the invite's role.
  FutureEither<void> accept(String inviteId) => _api.post<void>(
        '/invites/$inviteId/accept',
        parse: (_) {},
      );

  /// `POST /invites/:id/decline` → dismiss the invite.
  FutureEither<void> decline(String inviteId) => _api.post<void>(
        '/invites/$inviteId/decline',
        parse: (_) {},
      );

  /// `POST /weddings/:id/invites` → invite a registered user (by exact
  /// [username]) to [weddingId] with [role] (`editor` | `viewer`). Owner-only
  /// server-side. Returns unit on 201; surfaces 404 (unknown user) / 409
  /// (already a member or pending) as typed failures.
  FutureEither<void> invite(
    String weddingId,
    String username,
    String role,
  ) =>
      _api.post<void>(
        '/weddings/$weddingId/invites',
        body: {'username': username, 'role': role},
        parse: (_) {},
      );
}
