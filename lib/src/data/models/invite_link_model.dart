import 'package:equatable/equatable.dart';

class InviteLink extends Equatable {
  const InviteLink(
      {required this.id,
      required this.token,
      required this.role,
      this.revoked = false});
  final String id;
  final String token;
  final String role;
  final bool revoked;
  String get appUrl => 'zawaj://i/$token';
  String get displayUrl => 'zawaj.app/i/$token';

  factory InviteLink.fromJson(Map<String, dynamic> json) => InviteLink(
        id: (json['id'] ?? '').toString(),
        token: (json['token'] ?? '').toString(),
        role: (json['role'] ?? 'viewer').toString(),
        revoked: json['revoked'] == true,
      );
  @override
  List<Object?> get props => [id, token, role, revoked];
}

class InvitePreview extends Equatable {
  const InvitePreview(
      {required this.weddingId, required this.weddingName, required this.role});
  final String weddingId;
  final String weddingName;
  final String role;
  factory InvitePreview.fromJson(Map<String, dynamic> json) => InvitePreview(
        weddingId: (json['wedding_id'] ?? '').toString(),
        weddingName: (json['wedding_name'] ?? '').toString(),
        role: (json['role'] ?? 'viewer').toString(),
      );
  @override
  List<Object?> get props => [weddingId, weddingName, role];
}
