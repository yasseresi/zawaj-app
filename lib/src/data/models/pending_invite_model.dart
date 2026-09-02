import 'package:equatable/equatable.dart';

/// A pending collaborator invite addressed to the current user (screen 10).
/// Mirrors the backend `repository.PendingInviteView` returned by `GET /invites`:
/// `{ id, wedding_id, wedding_name, event_date, inviter_name, role, created_at }`.
class PendingInvite extends Equatable {
  const PendingInvite({
    required this.id,
    required this.event,
    required this.sender,
    required this.date,
    this.weddingId = '',
    this.role = '',
    this.initial,
  });

  final String id;

  /// The wedding name (display title).
  final String event;

  /// The inviter's display name.
  final String sender;

  /// When the invite was sent, as `YYYY-MM-DD` (language-neutral).
  final String date;

  final String weddingId;

  /// The role the invite grants (`editor` | `viewer`).
  final String role;

  final String? initial;

  String get avatarInitial {
    if (initial != null && initial!.isNotEmpty) return initial!;
    final trimmed = sender.trim();
    return trimmed.isEmpty ? '' : trimmed.substring(0, 1);
  }

  factory PendingInvite.fromJson(Map<String, dynamic> json) {
    final created = DateTime.tryParse((json['created_at'] ?? '').toString());
    final date = created != null
        ? '${created.year.toString().padLeft(4, '0')}-'
            '${created.month.toString().padLeft(2, '0')}-'
            '${created.day.toString().padLeft(2, '0')}'
        : '';
    return PendingInvite(
      id: (json['id'] ?? '').toString(),
      event: (json['wedding_name'] ?? '').toString(),
      sender: (json['inviter_name'] ?? '').toString(),
      date: date,
      weddingId: (json['wedding_id'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
    );
  }

  @override
  List<Object?> get props => [id, event, sender, date, weddingId, role, initial];
}
