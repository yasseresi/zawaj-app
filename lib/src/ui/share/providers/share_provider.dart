import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../data/models/invite_link_model.dart';
import '../../../data/models/wedding_member_model.dart';
import '../../../data/repositories/invite_repository.dart';
import '../../../data/repositories/invite_repository_impl.dart';
import '../../../data/repositories/wedding_repository.dart';
import '../../../data/repositories/wedding_repository_impl.dart';
import '../../../shared/enums/app_status.dart';
import '../../../services/export_service.dart';
import '../../../utils/error_handler.dart';
import '../../../utils/input_validation.dart';

class ShareProvider extends ChangeNotifier {
  ShareProvider(
      {required this.weddingId,
      WeddingRepository? weddingRepository,
      InviteRepository? inviteRepository})
      : _weddings = weddingRepository ?? WeddingRepositoryImpl(),
        _invites = inviteRepository ?? InviteRepositoryImpl();
  final String weddingId;
  final WeddingRepository _weddings;
  final InviteRepository _invites;
  AppStatus status = AppStatus.initial;
  List<WeddingMember> members = const [];
  List<InviteLink> links = const [];
  String? errorMessage;
  bool busy = false;
  ExportFormat? exporting;

  InviteLink? get link {
    for (final candidate in links) {
      if (!candidate.revoked) return candidate;
    }
    return null;
  }

  Future<void> load() async {
    status = AppStatus.loading;
    errorMessage = null;
    notifyListeners();
    final results = await Future.wait(
        [_weddings.members(weddingId), _weddings.listInviteLinks(weddingId)]);
    final memberResult = results[0] as dynamic;
    final linkResult = results[1] as dynamic;
    memberResult.match((f) => errorMessage = f.message, (v) => members = v);
    linkResult.match((f) => errorMessage ??= f.message, (v) => links = v);
    status = errorMessage == null ? AppStatus.success : AppStatus.failure;
    notifyListeners();
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
