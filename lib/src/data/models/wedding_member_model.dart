import 'package:equatable/equatable.dart';

import 'wedding_model.dart';

/// A collaborator on a wedding (screen 10 member list). Mirrors the backend
/// `repository.MembershipView` returned by `GET /weddings/:id/members`:
/// `{ user_id, username, display_name, role, joined_at }`.
class WeddingMember extends Equatable {
  const WeddingMember({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.role,
    this.joinedAt,
  });

  final String userId;
  final String username;
  final String displayName;
  final WeddingRole role;
  final DateTime? joinedAt;

  /// Best display label: the display name if present, else the username.
  String get label => displayName.trim().isNotEmpty ? displayName : username;

  String get avatarInitial {
    final source = label.trim();
    return source.isEmpty ? '' : source.substring(0, 1);
  }

  WeddingMember copyWith({WeddingRole? role}) => WeddingMember(
        userId: userId,
        username: username,
        displayName: displayName,
        role: role ?? this.role,
        joinedAt: joinedAt,
      );

  factory WeddingMember.fromJson(Map<String, dynamic> json) {
    return WeddingMember(
      userId: (json['user_id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      displayName: (json['display_name'] ?? '').toString(),
      role: WeddingRole.fromString(json['role']?.toString()),
      joinedAt: DateTime.tryParse((json['joined_at'] ?? '').toString()),
    );
  }

  @override
  List<Object?> get props => [userId, username, displayName, role, joinedAt];
}
