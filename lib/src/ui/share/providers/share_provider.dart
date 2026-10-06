import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../data/models/invite_link_model.dart';
import '../../../data/models/wedding_member_model.dart';
import '../../../data/models/wedding_model.dart';
import '../../../data/repositories/invite_repository.dart';
import '../../../data/repositories/invite_repository_impl.dart';
import '../../../data/repositories/wedding_repository.dart';
import '../../../data/repositories/wedding_repository_impl.dart';
import '../../../shared/enums/app_status.dart';
import '../../../services/export_service.dart';
import '../../../utils/error_handler.dart';
import '../../../utils/failure.dart';
import '../../../utils/input_validation.dart';

/// Share screen state: collaborators, invite links and exports. Owner-only
/// sections (invites, links, member management) key off [isOwner]; the role
/// comes from the passed [Wedding] or, when deep-linked, `GET /weddings/:id`.
class ShareProvider extends ChangeNotifier {
  ShareProvider(
      {required this.weddingId,
      Wedding? wedding,
      WeddingRepository? weddingRepository,
      InviteRepository? inviteRepository})
      : _role = wedding?.role,
        _weddings = weddingRepository ?? WeddingRepositoryImpl(),
        _invites = inviteRepository ?? InviteRepositoryImpl();
  final String weddingId;
  WeddingRole? _role;
  final WeddingRepository _weddings;
  final InviteRepository _invites;
  AppStatus status = AppStatus.initial;
  List<WeddingMember> members = const [];
  List<InviteLink> links = const [];
  String? errorMessage;
  bool busy = false;
  ExportFormat? exporting;

  WeddingRole? get role => _role;
  bool get isOwner => _role == WeddingRole.owner;

  /// Links that still work, newest first (as returned).
  List<InviteLink> get activeLinks =>
      links.where((l) => !l.revoked).toList(growable: false);

  /// The link shown as URL / QR: the newest active one.
  InviteLink? get link => activeLinks.isEmpty ? null : activeLinks.first;

  Future<void> load() async {
    status = AppStatus.loading;
    errorMessage = null;
    notifyListeners();
    if (_role == null) {
      final wedding = await _weddings.get(weddingId);
      wedding.match((f) => errorMessage = f.message, (w) => _role = w.role);
    }
    final memberResult = await _weddings.members(weddingId);
    memberResult.match((f) => errorMessage ??= f.message, (v) => members = v);
    // Invite links are owner-only server-side; don't request them otherwise.
    if (isOwner) {
      final linkResult = await _weddings.listInviteLinks(weddingId);
      linkResult.match((f) => errorMessage ??= f.message, (v) => links = v);
    } else {
      links = const [];
    }
    status = errorMessage == null ? AppStatus.success : AppStatus.failure;
    notifyListeners();
  }

  /// Change a collaborator's role (owner). Optimistic: the member updates at
  /// once and reverts on failure with [errorMessage] set.
  Future<bool> setRole(String userId, WeddingRole role) async {
    final index = members.indexWhere((m) => m.userId == userId);
    if (index < 0) return false;
    final previous = members[index];
    if (previous.role == role) return true;

    errorMessage = null;
    members = [...members]..[index] = previous.copyWith(role: role);
    notifyListeners();

    final result = await _weddings.setMemberRole(weddingId, userId, role.name);
    return result.match((f) {
      final i = members.indexWhere((m) => m.userId == userId);
      if (i >= 0) members = [...members]..[i] = previous;
      errorMessage = AppErrorHandler.userMessage(f);
      notifyListeners();
      return false;
    }, (_) => true);
  }

  Future<bool> invite(String username, String role) async {
    final usernameError = AppInputValidation.usernameError(username);
    if (usernameError != null) {
      errorMessage = usernameError.tr();
      notifyListeners();
      return false;
    }
    busy = true;
    errorMessage = null;
    notifyListeners();
    final normalizedUsername = AppInputValidation.normalizeUsername(username);
    final result = await _invites.invite(weddingId, normalizedUsername, role);
    final ok = result.match((f) {
      errorMessage = AppErrorHandler.userMessage(f, context: 'share_username');
      return false;
    }, (_) => true);
    busy = false;
    notifyListeners();
    if (ok) await load();
    return ok;
  }

  Future<bool> createLink(String role) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    final result = await _weddings.createInviteLink(weddingId, role);
    final ok = result.match((f) {
      errorMessage = f.message;
      return false;
    }, (v) {
      links = [v, ...links];
      return true;
    });
    busy = false;
    notifyListeners();
    return ok;
  }

  /// Hand the wedding to [userId] (owner). On success the caller is now an
  /// editor: owner-only data is dropped and members reload.
  Future<bool> transferOwnership(String userId) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    final result = await _weddings.transferOwnership(weddingId, userId);
    final ok = result.match((f) {
      errorMessage = AppErrorHandler.userMessage(f);
      return false;
    }, (_) => true);
    busy = false;
    if (!ok) {
      notifyListeners();
      return false;
    }
    _role = WeddingRole.editor;
    await load();
    return true;
  }

  /// Revoke an invite link (owner). People who haven't joined can no longer
  /// use it. A 404 means it's already gone — treated as success.
  Future<bool> revokeLink(String linkId) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    final result = await _weddings.revokeInviteLink(weddingId, linkId);
    final ok = result.match(
      (f) {
        if (f is NotFoundFailure) return true;
        errorMessage = AppErrorHandler.userMessage(f);
        return false;
      },
      (_) => true,
    );
    if (ok) links = links.where((l) => l.id != linkId).toList();
    busy = false;
    notifyListeners();
    return ok;
  }

  Future<bool> removeMember(String userId) async {
    busy = true;
    notifyListeners();
    final result = await _weddings.removeMember(weddingId, userId);
    final ok = result.match((f) {
      errorMessage = f.message;
      return false;
    }, (_) {
      members = members.where((m) => m.userId != userId).toList();
      return true;
    });
    busy = false;
    notifyListeners();
    return ok;
  }

  Future<File?> export(ExportFormat format, {String? languageCode}) async {
    exporting = format;
    errorMessage = null;
    notifyListeners();
    final result = await ExportService.instance.download(
      weddingId,
      format,
      languageCode: languageCode,
    );
    final file = result.match((failure) {
      errorMessage = failure.message;
      return null;
    }, (value) => value);
    exporting = null;
    notifyListeners();
    return file;
  }
}
