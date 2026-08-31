import 'package:equatable/equatable.dart';

/// Domain user. The backend returns two shapes:
/// - minimal `{id, username, display_name}` from register/login/`GET /me`;
/// - full `{…, email, dark_mode, notif_*, is_premium}` from `PATCH /me/settings`.
///
/// [fromJson] tolerates both (preference fields default to sane values when the
/// minimal shape omits them). Hand-written — the stack uses no build_runner.
class AppUser extends Equatable {
  final String id;
  final String username;
  final String displayName;
  final String? email;
  final bool darkMode;
  final bool notifPush;
  final bool notifEmail;
  final bool notifRsvp;
  final bool isPremium;

  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.email,
    this.darkMode = false,
    this.notifPush = true,
    this.notifEmail = false,
    this.notifRsvp = true,
    this.isPremium = false,
  });

  factory AppUser.empty() =>
      const AppUser(id: '', username: '', displayName: '');

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      displayName: (json['display_name'] ?? json['username'] ?? '').toString(),
      email: json['email']?.toString(),
      darkMode: _bool(json['dark_mode'], false),
      notifPush: _bool(json['notif_push'], true),
      notifEmail: _bool(json['notif_email'], false),
      notifRsvp: _bool(json['notif_rsvp'], true),
      isPremium: _bool(json['is_premium'], false),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        if (email != null) 'email': email,
        'dark_mode': darkMode,
        'notif_push': notifPush,
        'notif_email': notifEmail,
        'notif_rsvp': notifRsvp,
        'is_premium': isPremium,
      };

  AppUser copyWith({
    String? displayName,
    String? email,
    bool? darkMode,
    bool? notifPush,
    bool? notifEmail,
    bool? notifRsvp,
    bool? isPremium,
  }) =>
      AppUser(
        id: id,
        username: username,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        darkMode: darkMode ?? this.darkMode,
        notifPush: notifPush ?? this.notifPush,
        notifEmail: notifEmail ?? this.notifEmail,
        notifRsvp: notifRsvp ?? this.notifRsvp,
        isPremium: isPremium ?? this.isPremium,
      );

  static bool _bool(dynamic v, bool fallback) {
    if (v == null) return fallback;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    return fallback;
  }

  @override
  List<Object?> get props =>
      [id, username, displayName, email, darkMode, notifPush, notifEmail, notifRsvp, isPremium];
}

/// Result of register/login/recover: the user plus token pair, and (only on
/// register/recover) the one-time recovery code the client MUST surface once.
class AuthResult {
  final AppUser user;
  final String access;
  final String refresh;
  final String? recoveryCode;

  const AuthResult({
    required this.user,
    required this.access,
    required this.refresh,
    this.recoveryCode,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        user: AppUser.fromJson(
            (json['user'] as Map?)?.cast<String, dynamic>() ?? const {}),
        access: (json['access'] ?? '').toString(),
        refresh: (json['refresh'] ?? '').toString(),
        recoveryCode: json['recovery_code']?.toString(),
      );
}
