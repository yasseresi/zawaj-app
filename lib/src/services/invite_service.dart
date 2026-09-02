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
}
