import 'package:equatable/equatable.dart';

import 'guest_detail_model.dart' show ActivityAction;

/// One enriched entry in a wedding's activity feed (screen 9). Mirrors the
/// backend `repository.ActivityFeedRow`: an activity log joined with the actor's
/// display name and, when the entry targets a guest, the guest's name. [meta]
/// carries action-specific data (e.g. `{count}` for reminders, `{status}` for a
/// status change).
class ActivityFeedEntry extends Equatable {
  const ActivityFeedEntry({
    required this.id,
    required this.action,
    this.actorName = '',
    this.guestName,
    this.meta = const {},
    this.createdAt,
  });

  final String id;
  final ActivityAction action;
  final String actorName;
  final String? guestName;
  final Map<String, dynamic> meta;
  final DateTime? createdAt;

  /// Reads an int from [meta] (e.g. reminder count); 0 when absent/invalid.
  int metaInt(String key) {
    final v = meta[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}') ?? 0;
  }

  /// Reads a string from [meta] (e.g. the new status); empty when absent.
  String metaString(String key) => (meta[key] ?? '').toString();

  factory ActivityFeedEntry.fromJson(Map<String, dynamic> json) {
    final rawMeta = json['meta'];
    return ActivityFeedEntry(
      id: (json['id'] ?? '').toString(),
      action: ActivityAction.fromString(json['action']?.toString()),
      actorName: (json['actor_name'] ?? '').toString(),
      guestName: json['guest_name']?.toString(),
      meta: rawMeta is Map ? rawMeta.cast<String, dynamic>() : const {},
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString())?.toLocal(),
    );
  }

  @override
  List<Object?> get props => [id, action, actorName, guestName, meta, createdAt];
}

/// A page of activity feed entries plus the opaque keyset [nextCursor]
/// (`null`/empty when there are no more rows). Maps the `{ items, next_cursor }`
/// object under the response envelope (`GET /weddings/:id/activity`).
class ActivityFeedPage extends Equatable {
  const ActivityFeedPage({this.items = const [], this.nextCursor});

  final List<ActivityFeedEntry> items;
  final String? nextCursor;

  factory ActivityFeedPage.fromJson(dynamic data) {
    final map = data is Map ? data.cast<String, dynamic>() : const <String, dynamic>{};
    final rawItems = map['items'];
    final cursor = map['next_cursor']?.toString();
    return ActivityFeedPage(
      items: [
        if (rawItems is List)
          for (final e in rawItems)
            if (e is Map) ActivityFeedEntry.fromJson(e.cast<String, dynamic>()),
      ],
      nextCursor: (cursor == null || cursor.isEmpty) ? null : cursor,
    );
  }

  @override
  List<Object?> get props => [items, nextCursor];
}
