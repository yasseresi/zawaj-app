import 'package:equatable/equatable.dart';

/// The caller's permission level on a wedding. Mirrors the backend `models.Role`
/// (owner > editor > viewer). Unknown/absent values default to [viewer] — the
/// least-privileged role — so the UI never over-grants.
enum WeddingRole {
  owner,
  editor,
  viewer;

  static WeddingRole fromString(String? value) {
    switch (value) {
      case 'owner':
        return WeddingRole.owner;
      case 'editor':
        return WeddingRole.editor;
      default:
        return WeddingRole.viewer;
    }
  }

  bool get canEdit => this == owner || this == editor;
  bool get isOwner => this == owner;
}

/// A wedding as returned by `GET /weddings` (the `WeddingListItem` shape):
/// the wedding plus the caller's role and its guest count.
///
/// Hand-written [fromJson] — the stack uses no build_runner — and tolerant of
/// the backend omitting `event_date`/`description` (they carry `omitempty`).
class Wedding extends Equatable {
  final String id;
  final String name;
  final DateTime? eventDate;
  final String description;
  final String ownerId;
  final WeddingRole role;
  final int guestCount;
  final DateTime? createdAt;

  const Wedding({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.role,
    this.eventDate,
    this.description = '',
    this.guestCount = 0,
    this.createdAt,
  });

  factory Wedding.fromJson(Map<String, dynamic> json) {
    return Wedding(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      eventDate: _date(json['event_date']),
      description: (json['description'] ?? '').toString(),
      ownerId: (json['owner_id'] ?? '').toString(),
      role: WeddingRole.fromString(json['my_role']?.toString()),
      guestCount: _int(json['guest_count']),
      createdAt: _date(json['created_at']),
    );
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
  List<Object?> get props =>
      [id, name, eventDate, description, ownerId, role, guestCount, createdAt];
}
