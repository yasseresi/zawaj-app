import 'package:equatable/equatable.dart';

import 'wedding_model.dart';

/// Outcome of `POST /invite/:token/accept`. Joining through a link needs the
/// owner's approval, so a non-member gets a pending request (202); someone
/// already in the wedding gets their current role back (200).
class JoinResult extends Equatable {
  const JoinResult({
    required this.weddingId,
    required this.weddingName,
    required this.role,
    required this.isPending,
    this.requestId,
  });

  final String weddingId;
  final String weddingName;

  /// The role requested (pending) or held (member).
  final WeddingRole role;

  /// True while the owner hasn't decided; false when already a member.
  final bool isPending;
  final String? requestId;

  factory JoinResult.fromJson(Map<String, dynamic> json) => JoinResult(
        weddingId: (json['wedding_id'] ?? '').toString(),
        weddingName: (json['wedding_name'] ?? '').toString(),
        role: WeddingRole.fromString(json['role']?.toString()),
        isPending: json['status'] == 'pending',
        requestId: json['request_id']?.toString(),
      );

  @override
  List<Object?> get props =>
      [weddingId, weddingName, role, isPending, requestId];
}

/// A pending request to join a wedding, as listed to its owner
/// (`GET /weddings/:id/join-requests`).
class JoinRequest extends Equatable {
  const JoinRequest({
    required this.id,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.role,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String username;
  final String displayName;

  /// The role the invite link grants (the most the owner can approve).
  final WeddingRole role;
  final DateTime? createdAt;

  /// Best display label: the display name if present, else the username.
  String get label => displayName.trim().isNotEmpty ? displayName : username;

  String get avatarInitial {
    final source = label.trim();
    return source.isEmpty ? '' : source.substring(0, 1);
  }

  factory JoinRequest.fromJson(Map<String, dynamic> json) => JoinRequest(
        id: (json['id'] ?? '').toString(),
        userId: (json['user_id'] ?? '').toString(),
        username: (json['username'] ?? '').toString(),
        displayName: (json['display_name'] ?? '').toString(),
        role: WeddingRole.fromString(json['role']?.toString()),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );

  @override
  List<Object?> get props =>
      [id, userId, username, displayName, role, createdAt];
}
