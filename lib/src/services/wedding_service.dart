import '../data/models/wedding_member_model.dart';
import '../data/models/invite_link_model.dart';
import '../data/models/wedding_model.dart';
import '../data/services/api_client.dart';
import '../utils/typedefs.dart';

/// API surface for the weddings endpoints. Pure transport: returns
/// [FutureEither] of domain objects, no [BuildContext], no session state.
///
/// Backend contract: `GET /weddings` returns `{ "items": [ WeddingListItem ] }`
/// under the standard `{data,error}` envelope (unwrapped by [ApiClient]).
class WeddingService {
  WeddingService._();
  static final WeddingService instance = WeddingService._();

  final ApiClient _api = ApiClient.instance;

  FutureEither<List<Wedding>> list() => _api.get<List<Wedding>>(
        '/weddings',
        parse: _parseItems,
      );

  /// `POST /weddings` → the created wedding (201). Only non-null optional fields
  /// are sent so the backend's `omitempty` validators apply.
  FutureEither<Wedding> create({
    required String name,
    String? eventDate,
    String? description,
  }) =>
      _api.post<Wedding>(
        '/weddings',
        body: {
          'name': name,
          if (eventDate != null) 'event_date': eventDate,
          if (description != null) 'description': description,
        },
        parse: (d) => Wedding.fromJson((d as Map).cast<String, dynamic>()),
      );

  /// `DELETE /weddings/:id` → 200 `{deleted:true}`. Owner-only (enforced
  /// server-side via RequireRole). Body is discarded.
  FutureEither<void> delete(String id) => _api.delete<void>(
        '/weddings/$id',
        parse: parseVoid,
      );

  /// `GET /weddings/:id/members` → the wedding's collaborators. Any member
  /// (viewer+) may read.
  FutureEither<List<WeddingMember>> members(String weddingId) =>
      _api.get<List<WeddingMember>>(
        '/weddings/$weddingId/members',
        parse: _parseMembers,
      );

  /// `PATCH /weddings/:id/members/:userId` → change a member's role
  /// (`editor` | `viewer`). Owner-only server-side.
  FutureEither<void> setMemberRole(
    String weddingId,
    String userId,
    String role,
  ) =>
      _api.patch<void>(
        '/weddings/$weddingId/members/$userId',
        body: {'role': role},
        parse: parseVoid,
      );

  /// `DELETE /weddings/:id/members/:userId` → remove a collaborator (or leave,
  /// when it's the caller). Owner-only for removing others.
  FutureEither<void> removeMember(String weddingId, String userId) =>
      _api.delete<void>(
        '/weddings/$weddingId/members/$userId',
        parse: parseVoid,
      );

  FutureEither<InviteLink> createInviteLink(String weddingId, String role) =>
      _api.post<InviteLink>(
        '/weddings/$weddingId/invite-links',
        body: {'role': role},
        parse: (d) => InviteLink.fromJson((d as Map).cast<String, dynamic>()),
      );

  FutureEither<List<InviteLink>> listInviteLinks(String weddingId) =>
      _api.get<List<InviteLink>>('/weddings/$weddingId/invite-links',
          parse: (d) {
        final items = d is Map ? d['items'] : d;
        return [
          if (items is List)
            for (final e in items)
              if (e is Map) InviteLink.fromJson(e.cast<String, dynamic>())
        ];
      });

  FutureEither<void> revokeInviteLink(String weddingId, String linkId) =>
      _api.delete<void>('/weddings/$weddingId/invite-links/$linkId',
          parse: parseVoid);

  FutureEither<InvitePreview> previewInvite(String token) =>
      _api.get<InvitePreview>('/invite/$token',
          parse: (d) =>
              InvitePreview.fromJson((d as Map).cast<String, dynamic>()));

  FutureEither<InvitePreview> acceptInviteLink(String token) =>
      _api.post<InvitePreview>('/invite/$token/accept',
          parse: (d) =>
              InvitePreview.fromJson((d as Map).cast<String, dynamic>()));

  static List<WeddingMember> _parseMembers(dynamic data) {
    final items = (data is Map ? data['items'] : data) as List? ?? const [];
    return [
      for (final e in items)
        if (e is Map) WeddingMember.fromJson(e.cast<String, dynamic>()),
    ];
  }

  static List<Wedding> _parseItems(dynamic data) {
    final items = (data is Map ? data['items'] : data) as List? ?? const [];
    return [
      for (final e in items)
        if (e is Map) Wedding.fromJson(e.cast<String, dynamic>()),
    ];
  }
}
