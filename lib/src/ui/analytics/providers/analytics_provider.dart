import 'package:flutter/foundation.dart';

import '../../../data/models/wedding_stats_model.dart';
import '../../../data/repositories/stats_repository.dart';
import '../../../data/repositories/stats_repository_impl.dart';
import '../../../shared/enums/app_status.dart';

enum BroadcastState {
  idle,
  confirm,
  sending,
  success,
  error,
}

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsProvider({
    required String weddingId,
    StatsRepository? repository,
  })  : _weddingId = weddingId,
        _repository = repository ?? StatsRepositoryImpl();

  final String _weddingId;
  final StatsRepository _repository;

  AppStatus _status = AppStatus.initial;
  WeddingStats _stats = const WeddingStats();
  String? _errorMessage;
  BroadcastState _broadcastState = BroadcastState.idle;
  int _lastSentCount = 0;
  final List<int> _timelineData = const [12, 28, 45, 68, 92, 118, 142];

  String get weddingId => _weddingId;
  AppStatus get status => _status;
  WeddingStats get stats => _stats;
  String? get errorMessage => _errorMessage;
  BroadcastState get broadcastState => _broadcastState;
  int get lastSentCount => _lastSentCount;
  List<int> get timelineData => _timelineData;

  int get totalGuests => _stats.totalGuests;
  int get confirmedCount => _stats.confirmed;
  int get declinedCount => _stats.declined;
  int get pendingCount => _stats.pending;

  bool get isEmpty => _status == AppStatus.success && _stats.totalGuests == 0;
  bool get isLoading => _status == AppStatus.loading;

  Future<void> load() async {
    _status = AppStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.stats(_weddingId);
    result.match(
      (failure) {
        _status = AppStatus.failure;
        _errorMessage = failure.message;
        notifyListeners();
      },
      (data) {
        _stats = data;
        _status = AppStatus.success;
        notifyListeners();
      },
    );
  }

  void openBroadcastConfirm() {
    _broadcastState = BroadcastState.confirm;
    notifyListeners();
  }

  void cancelBroadcast() {
    _broadcastState = BroadcastState.idle;
    notifyListeners();
  }

  Future<void> sendReminders() async {
    _broadcastState = BroadcastState.sending;
    notifyListeners();

    final result = await _repository.sendReminders(_weddingId);
    result.match(
      (failure) {
        _broadcastState = BroadcastState.error;
        _errorMessage = failure.message;
        notifyListeners();
      },
      (count) {
        _lastSentCount = count > 0 ? count : _stats.pending;
        _broadcastState = BroadcastState.success;
        notifyListeners();
      },
    );
  }

  void dismissBroadcastResult() {
    _broadcastState = BroadcastState.idle;
    notifyListeners();
  }
}
