import '../../data/models/app_notification_model.dart';

/// Where tapping [n] should take the user, or null to stay put.
///
/// - `join_requested` (to the owner): the share screen, to review it.
/// - `join_declined` (to the requester): nowhere — they aren't a member.
/// - anything else tied to a wedding (incl. `join_approved`): that wedding.
String? notificationRoute(AppNotification n) {
  final weddingId = n.weddingId;
  if (weddingId == null || weddingId.isEmpty) return null;
  return switch (n.type) {
    'join_requested' => '/weddings/$weddingId/share',
    'join_declined' => null,
    _ => '/weddings/$weddingId',
  };
}
