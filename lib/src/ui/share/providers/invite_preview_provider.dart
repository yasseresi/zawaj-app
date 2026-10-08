import 'package:flutter/foundation.dart';

import '../../../data/models/invite_link_model.dart';
import '../../../data/models/join_request_model.dart';
import '../../../data/repositories/wedding_repository.dart';
import '../../../data/repositories/wedding_repository_impl.dart';
import '../../../shared/enums/app_status.dart';
import '../../../utils/error_handler.dart';

class InvitePreviewProvider extends ChangeNotifier {
  InvitePreviewProvider({
    required this.token,
    WeddingRepository? repository,
  }) : _repository = repository ?? WeddingRepositoryImpl();

  final String token;
  final WeddingRepository _repository;

  AppStatus status = AppStatus.initial;
  InvitePreview? preview;

  /// Outcome of accepting: a pending join request, or (already a member) the
  /// wedding to open.
  JoinResult? accepted;
  String? errorMessage;
  bool isAccepting = false;

  bool get isLoading => status.isLoading;

  Future<void> load() async {
    status = AppStatus.loading;
    errorMessage = null;
    notifyListeners();

    final result = await _repository.previewInvite(token);
    result.match(
      (failure) {
        status = AppStatus.failure;
        errorMessage = AppErrorHandler.userMessage(failure);
      },
      (value) {
        status = AppStatus.success;
        preview = value;
      },
    );
    notifyListeners();
  }

  Future<bool> accept() async {
    if (preview == null || isAccepting) return false;
    isAccepting = true;
    errorMessage = null;
    notifyListeners();

    final result = await _repository.acceptInviteLink(token);
    final success = result.match(
      (failure) {
        errorMessage = AppErrorHandler.userMessage(failure);
        return false;
      },
      (value) {
        accepted = value;
        return true;
      },
    );
    isAccepting = false;
    notifyListeners();
    return success;
  }
}
