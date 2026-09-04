import 'package:flutter/foundation.dart';
import '../../../data/models/invite_link_model.dart';
import '../../../data/models/wedding_member_model.dart';
import '../../../data/repositories/invite_repository.dart';
import '../../../data/repositories/invite_repository_impl.dart';
import '../../../data/repositories/wedding_repository.dart';
import '../../../data/repositories/wedding_repository_impl.dart';
import '../../../shared/enums/app_status.dart';

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

  InviteLink? get link => links.where((l) => !l.revoked).isEmpty
      ? null
      : links.firstWhere((l) => !l.revoked);

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
    if (username.trim().isEmpty) return false;
    busy = true;
    errorMessage = null;
    notifyListeners();
    final result = await _invites.invite(weddingId, username.trim(), role);
    final ok = result.match((f) {
      errorMessage = f.message;
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
}
