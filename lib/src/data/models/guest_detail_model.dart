import 'package:equatable/equatable.dart';

import 'guest_model.dart';

/// One authored note on a guest (mockup screen 7 note cards). Mirrors the
/// backend `models.GuestNote`.
class GuestNote extends Equatable {
  final String id;
  final String authorId;
  final String body;
  final DateTime? createdAt;

  const GuestNote({
    required this.id,
    required this.body,
    this.authorId = '',
    this.createdAt,
  });

  factory GuestNote.fromJson(Map<String, dynamic> json) {
    return GuestNote(
      id: (json['id'] ?? '').toString(),
      authorId: (json['author_id'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      createdAt: _date(json['created_at']),
    );
  }

  @override
  List<Object?> get props => [id, authorId, body, createdAt];
}

/// The kind of change recorded in a guest's history timeline. Mirrors the
/// backend `models.ActivityAction`; unknown values fall back to [unknown].
enum ActivityAction {
  guestAdded,
  guestUpdated,
  guestStatusChanged,
  noteAdded,
  collaboratorJoined,
  listExported,
  remindersSent,
  unknown;

  static ActivityAction fromString(String? value) {
    switch (value) {
      case 'guest_added':
        return ActivityAction.guestAdded;
      case 'guest_updated':
        return ActivityAction.guestUpdated;
      case 'guest_status_changed':
        return ActivityAction.guestStatusChanged;
      case 'note_added':
        return ActivityAction.noteAdded;
      case 'collaborator_joined':
        return ActivityAction.collaboratorJoined;
      case 'list_exported':
        return ActivityAction.listExported;
      case 'reminders_sent':
        return ActivityAction.remindersSent;
      default:
        return ActivityAction.unknown;
    }
  }
}

/// One entry in a guest's change history (mockup screen 7 timeline). Mirrors the
/// backend `models.ActivityLog`.
class ActivityLog extends Equatable {
  final String id;
  final ActivityAction action;
  final String actorId;
  final DateTime? createdAt;

  const ActivityLog({
    required this.id,
    required this.action,
    this.actorId = '',
    this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: (json['id'] ?? '').toString(),
      action: ActivityAction.fromString(json['action']?.toString()),
      actorId: (json['actor_id'] ?? '').toString(),
      createdAt: _date(json['created_at']),
    );
  }

  @override
  List<Object?> get props => [id, action, actorId, createdAt];
}

/// The full guest-detail payload: the [guest], its [notes] thread, and its
/// change [history]. Maps the `{ guest, notes, history }` object under the
/// response envelope (`GET /weddings/:id/guests/:gid`).
class GuestDetail extends Equatable {
  final Guest guest;
  final List<GuestNote> notes;
  final List<ActivityLog> history;

  const GuestDetail({
    required this.guest,
    this.notes = const [],
    this.history = const [],
  });

  factory GuestDetail.fromJson(dynamic data) {
    final map = data is Map ? data.cast<String, dynamic>() : const <String, dynamic>{};
    final rawGuest = map['guest'];
    return GuestDetail(
      guest: Guest.fromJson(
        rawGuest is Map ? rawGuest.cast<String, dynamic>() : const <String, dynamic>{},
      ),
      notes: _list(map['notes'], GuestNote.fromJson),
      history: _list(map['history'], ActivityLog.fromJson),
    );
  }

  static List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) parse) {
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is Map) parse(e.cast<String, dynamic>()),
    ];
  }

  @override
  List<Object?> get props => [guest, notes, history];
}

DateTime? _date(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}
