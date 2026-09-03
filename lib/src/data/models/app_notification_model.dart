import 'package:equatable/equatable.dart';

/// A personal notification for the current user. Mirrors the backend
/// `models.Notification` returned by `GET /notifications`:
/// `{ id, user_id, wedding_id, type, title, body, data, read_at, created_at }`.
///
/// Common [type] values: `invite_received`, `guest_added`,
/// `guest_status_changed`.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body = '',
    this.weddingId,
    this.readAt,
    this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;

  /// The wedding this notification concerns, if any. Used to deep-navigate.
  final String? weddingId;

  final DateTime? readAt;
  final DateTime? createdAt;

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final wedding = (json['wedding_id'] ?? '').toString();
    return AppNotification(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      weddingId: wedding.isEmpty ? null : wedding,
      readAt: DateTime.tryParse((json['read_at'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }

  AppNotification copyWith({DateTime? readAt}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        weddingId: weddingId,
        readAt: readAt ?? this.readAt,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props =>
      [id, type, title, body, weddingId, readAt, createdAt];
}
