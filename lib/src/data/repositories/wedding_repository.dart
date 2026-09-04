import '../models/wedding_member_model.dart';
import '../models/invite_link_model.dart';
import '../models/wedding_model.dart';
import '../../utils/typedefs.dart';

/// Data boundary for weddings. Providers depend on this interface (not the
/// service) so they can be tested with a fake.
abstract interface class WeddingRepository {
  /// `GET /weddings` — the caller's weddings, each with role + guest count,
  /// newest first.
  FutureEither<List<Wedding>> myWeddings();

  /// `POST /weddings` — create a wedding owned by the caller. [eventDate] is an
  /// optional `YYYY-MM-DD` string; [description] optional.
  FutureEither<Wedding> create({
    required String name,
    String? eventDate,
    String? description,
  });

  /// `DELETE /weddings/:id` — permanently delete a wedding. Owner-only.
  FutureEither<void> delete(String id);

  /// `GET /weddings/:id/members` — the wedding's collaborators.
  FutureEither<List<WeddingMember>> members(String id);

  /// `PATCH /weddings/:id/members/:userId` — change a member's role.
  FutureEither<void> setMemberRole(String id, String userId, String role);

  /// `DELETE /weddings/:id/members/:userId` — remove a collaborator.
  FutureEither<void> removeMember(String id, String userId);
  FutureEither<InviteLink> createInviteLink(String id, String role);
  FutureEither<List<InviteLink>> listInviteLinks(String id);
  FutureEither<void> revokeInviteLink(String id, String linkId);
  FutureEither<InvitePreview> previewInvite(String token);
  FutureEither<InvitePreview> acceptInviteLink(String token);
}
