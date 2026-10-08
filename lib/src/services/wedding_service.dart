import 'package:flutter/foundation.dart';

import '../data/models/invite_link_model.dart';
import '../data/models/join_request_model.dart';
import '../data/models/wedding_member_model.dart';
import '../data/models/wedding_model.dart';
import '../data/services/api_client.dart';
import '../utils/typedefs.dart';

/// API surface for the weddings endpoints. Pure transport: returns
/// [FutureEither] of domain objects, no [BuildContext], no session state.
///
/// Backend contract: `GET /weddings` returns `{ "items": [ WeddingListItem ] }`
/// under the standard `{data,error}` envelope (unwrapped by [ApiClient]).
class WeddingService {
  WeddingService._({ApiClient? api}) : _api = api ?? ApiClient.instance;
  static final WeddingService instance = WeddingService._();

  @visibleForTesting
  factory WeddingService.test({required ApiClient api}) =>
      WeddingService._(api: api);

  final ApiClient _api;

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

  /// `GET /weddings/:id` → `{wedding, my_role}` (viewer+). The response has no
  /// guest count, so the returned [Wedding.guestCount] is 0.
  FutureEither<Wedding> get(String id) => _api.get<Wedding>(
        '/weddings/$id',
        parse: (d) {
          final map = (d as Map).cast<String, dynamic>();
          return Wedding.fromJson({
            ...((map['wedding'] as Map?)?.cast<String, dynamic>() ?? const {}),
            'my_role': map['my_role'],
          });
        },
      );

  /// `PATCH /weddings/:id` (owner) with only the given fields → the bare
  /// wedding. The response carries no `my_role`/guest count; merge it into the
  /// cached item (see `WeddingsProvider.applyUpdate`).
  FutureEither<Wedding> update(
    String id, {
    String? name,
    String? eventDate,
    String? description,
  }) =>
      _api.patch<Wedding>(
        '/weddings/$id',
        body: {
          if (name != null) 'name': name,
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

  /// `POST /weddings/:id/transfer` `{user_id}` (owner). The target must already
  /// be a member; the server makes them owner and demotes the caller to editor.
  FutureEither<void> transferOwnership(String weddingId, String userId) =>
      _api.post<void>(
        '/weddings/$weddingId/transfer',
        body: {'user_id': userId},
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
      _api.get<InvitePreview>('/invite/${Uri.encodeComponent(token)}',
          parse: (d) =>
              InvitePreview.fromJson((d as Map).cast<String, dynamic>()));

  /// `POST /invite/:token/accept` → a pending join request the owner must
  /// approve, or the caller's role if they're already a member. Errors:
  /// `removed_from_wedding` (403), `join_request_declined` (409, cooldown).
  FutureEither<JoinResult> acceptInviteLink(String token) =>
      _api.post<JoinResult>('/invite/${Uri.encodeComponent(token)}/accept',
          parse: (d) =>
              JoinResult.fromJson((d as Map).cast<String, dynamic>()));

  /// `GET /weddings/:id/join-requests` (owner) → pending requests, oldest first.
  FutureEither<List<JoinRequest>> listJoinRequests(String weddingId) =>
      _api.get<List<JoinRequest>>('/weddings/$weddingId/join-requests',
          parse: (d) {
        final items = (d is Map ? d['items'] : d) as List? ?? const [];
        return [
          for (final e in items)
            if (e is Map) JoinRequest.fromJson(e.cast<String, dynamic>()),
        ];
      });

  /// `POST /weddings/:id/join-requests/:rid/approve` (owner). [role] may lower
  /// the requested role (never raise it); omitted keeps it.
  FutureEither<void> approveJoinRequest(String weddingId, String requestId,
          {WeddingRole? role}) =>
      _api.post<void>('/weddings/$weddingId/join-requests/$requestId/approve',
          body: role == null ? null : {'role': role.name}, parse: parseVoid);

  /// `POST /weddings/:id/join-requests/:rid/decline` (owner).
  FutureEither<void> declineJoinRequest(String weddingId, String requestId) =>
      _api.post<void>('/weddings/$weddingId/join-requests/$requestId/decline',
          parse: parseVoid);

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
