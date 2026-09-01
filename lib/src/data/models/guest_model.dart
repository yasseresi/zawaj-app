import 'package:equatable/equatable.dart';

/// A guest's RSVP state. Mirrors the backend `models.RSVPStatus`. Unknown/absent
/// values default to [pending] (the UI "مدعو/invited" state).
enum RsvpStatus {
  pending,
  confirmed,
  declined;

  static RsvpStatus fromString(String? value) {
    switch (value) {
      case 'confirmed':
        return RsvpStatus.confirmed;
      case 'declined':
        return RsvpStatus.declined;
      default:
        return RsvpStatus.pending;
    }
  }

  /// The wire value sent to the backend (`?status=` filter, PATCH body).
  String get wire => name;
}

/// One invitee on a wedding's guest list, as returned by
/// `GET /weddings/:id/guests` (the `models.Guest` shape). One row covers the
/// guest plus [companions] accompanying people (total people = 1 + companions).
///
/// Hand-written [fromJson] — the stack uses no build_runner — and tolerant of
/// the backend omitting optional fields (they carry `omitempty`).
class Guest extends Equatable {
  final String id;
  final String fullName;
  final String contact; // phone OR email
  final String relationship;
  final RsvpStatus status;
  final int companions;
  final String tableLabel;
  final String meal;
  final DateTime? createdAt;

  const Guest({
    required this.id,
    required this.fullName,
    this.contact = '',
    this.relationship = '',
    this.status = RsvpStatus.pending,
    this.companions = 0,
    this.tableLabel = '',
    this.meal = '',
    this.createdAt,
  });

  factory Guest.fromJson(Map<String, dynamic> json) {
    return Guest(
      id: (json['id'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      contact: (json['contact'] ?? '').toString(),
      relationship: (json['relationship'] ?? '').toString(),
      status: RsvpStatus.fromString(json['status']?.toString()),
      companions: _int(json['companions']),
      tableLabel: (json['table_label'] ?? '').toString(),
      meal: (json['meal'] ?? '').toString(),
      createdAt: _date(json['created_at']),
    );
  }

  /// First character of [fullName], for the avatar bubble. Empty when nameless.
  String get initial {
    final trimmed = fullName.trim();
    return trimmed.isEmpty ? '' : trimmed.substring(0, 1);
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        contact,
        relationship,
        status,
        companions,
        tableLabel,
        meal,
        createdAt,
      ];
}

/// Global RSVP tab counts for a wedding (`counts` in the list response). These
/// are wedding-wide totals — the backend computes them ignoring the active
/// status/search filter — so tabs keep their counts as the user filters.
class GuestCounts extends Equatable {
  final int all;
  final int confirmed;
  final int pending;
  final int declined;

  const GuestCounts({
    this.all = 0,
    this.confirmed = 0,
    this.pending = 0,
    this.declined = 0,
  });

  factory GuestCounts.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GuestCounts();
    return GuestCounts(
      all: Guest._int(json['all']),
      confirmed: Guest._int(json['confirmed']),
      pending: Guest._int(json['pending']),
      declined: Guest._int(json['declined']),
    );
  }

  @override
  List<Object?> get props => [all, confirmed, pending, declined];
}

/// The guest list payload: the filtered page of [items] plus wedding-wide
/// [counts]. Maps the `{ items, counts }` object under the response envelope.
class GuestListResult extends Equatable {
  final List<Guest> items;
  final GuestCounts counts;

  const GuestListResult({this.items = const [], this.counts = const GuestCounts()});

  factory GuestListResult.fromJson(dynamic data) {
    final map = data is Map ? data.cast<String, dynamic>() : const <String, dynamic>{};
    final rawItems = map['items'];
    return GuestListResult(
      items: [
        if (rawItems is List)
          for (final e in rawItems)
            if (e is Map) Guest.fromJson(e.cast<String, dynamic>()),
      ],
      counts: GuestCounts.fromJson(
        map['counts'] is Map ? (map['counts'] as Map).cast<String, dynamic>() : null,
      ),
    );
  }

  @override
  List<Object?> get props => [items, counts];
}
