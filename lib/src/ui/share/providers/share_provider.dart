import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../data/models/invite_link_model.dart';
import '../../../data/models/join_request_model.dart';
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
import '../../../utils/typedefs.dart';

/// Share screen state: collaborators, join requests, invite links and exports.
/// Owner-only sections (invites, join requests, links, member management) key
/// off [isOwner]; the role comes from the passed [Wedding] or, when
/// deep-linked, `GET /weddings/:id`.
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

  /// Pending requests to join through an invite link (owner only), oldest
  /// first.
  List<JoinRequest> joinRequests = const [];
  final Set<String> _deciding = {};
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
    // Invite links and join requests are owner-only server-side; don't
    // request them otherwise.
    if (isOwner) {
      final (linkResult, requestResult) = await (
        _weddings.listInviteLinks(weddingId),
        _weddings.listJoinRequests(weddingId),
      ).wait;
      linkResult.match((f) => errorMessage ??= f.message, (v) => links = v);
      requestResult.match(
          (f) => errorMessage ??= f.message, (v) => joinRequests = v);
    } else {
      links = const [];
      joinRequests = const [];
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

  /// Whether a decision on request [id] is in flight (its buttons disable).
  bool isDeciding(String id) => _deciding.contains(id);

  /// Approve a join request (owner), optionally at a lower [role] than
  /// requested. The row leaves the list at once; on success members reload so
  /// the newcomer appears.
  Future<bool> approveRequest(JoinRequest request, {WeddingRole? role}) =>
      _decide(
        request,
        () => _weddings.approveJoinRequest(weddingId, request.id,
            role: role == null || role == request.role ? null : role),
        onSuccess: _reloadMembers,
      );

  /// Decline a join request (owner). The row leaves the list at once.
  Future<bool> declineRequest(JoinRequest request) => _decide(
        request,
        () => _weddings.declineJoinRequest(weddingId, request.id),
      );

  /// Optimistic decision shared by approve/decline. Failure puts the row back
  /// (if no refresh replaced the list meanwhile) and sets [errorMessage]; a 404
  /// means another device already decided, so the list is refreshed instead.
  Future<bool> _decide(
    JoinRequest request,
    FutureEither<void> Function() call, {
    Future<void> Function()? onSuccess,
  }) async {
    if (!_deciding.add(request.id)) return false;
    final index = joinRequests.indexWhere((r) => r.id == request.id);
    errorMessage = null;
    joinRequests = joinRequests.where((r) => r.id != request.id).toList();
    notifyListeners();

    final result = await call();
    final ok = await result.match((f) async {
      if (f is NotFoundFailure) {
        errorMessage = 'share.request_already_handled'.tr();
        await _reloadRequests();
      } else {
        errorMessage = AppErrorHandler.userMessage(f);
        if (!joinRequests.any((r) => r.id == request.id)) {
          final at = index < 0 ? 0 : index.clamp(0, joinRequests.length);
          joinRequests = [...joinRequests]..insert(at, request);
        }
      }
      return false;
    }, (_) async {
      await onSuccess?.call();
      return true;
    });
    _deciding.remove(request.id);
    notifyListeners();
    return ok;
  }

  Future<void> _reloadMembers() async {
    final result = await _weddings.members(weddingId);
    result.match((_) {}, (v) => members = v);
  }

  Future<void> _reloadRequests() async {
    final result = await _weddings.listJoinRequests(weddingId);
    result.match((_) {}, (v) => joinRequests = v);
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
