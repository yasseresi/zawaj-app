import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../data/repositories/guest_repository.dart';
import '../../../data/repositories/guest_repository_impl.dart';
import '../../../shared/enums/app_status.dart';

enum ActivityItemType {
  confirmed,
  added,
  reminder,
  declined,
  collaboratorJoined,
  updated,
  exported,
}

class ActivityItem extends Equatable {
  const ActivityItem({
    required this.id,
    required this.type,
    required this.textKey,
    this.textArgs,
    required this.whenKey,
    this.whenArgs,
    this.rawText,
    this.rawWhen,
  });

  final String id;
  final ActivityItemType type;
  final String textKey;
  final Map<String, String>? textArgs;
  final String whenKey;
  final Map<String, String>? whenArgs;
  final String? rawText;
  final String? rawWhen;

  String formattedText() {
    if (rawText != null && rawText!.isNotEmpty) {
      return rawText!;
    }
    if (textArgs != null && textArgs!.isNotEmpty) {
      return textKey.tr(namedArgs: textArgs!);
    }
    return textKey.tr();
  }

  String formattedWhen() {
    if (rawWhen != null && rawWhen!.isNotEmpty) {
      return rawWhen!;
    }
    if (whenArgs != null && whenArgs!.isNotEmpty) {
      return whenKey.tr(namedArgs: whenArgs!);
    }
    return whenKey.tr();
  }

  @override
  List<Object?> get props => [
        id,
        type,
        textKey,
        textArgs,
        whenKey,
        whenArgs,
        rawText,
        rawWhen,
      ];
}

class ActivityGroup extends Equatable {
  const ActivityGroup({
    required this.titleKey,
    required this.items,
  });

  final String titleKey;
  final List<ActivityItem> items;

  @override
  List<Object?> get props => [titleKey, items];
}

class ActivityLogProvider extends ChangeNotifier {
  ActivityLogProvider({
    required String weddingId,
    GuestRepository? repository,
    List<ActivityGroup>? initialGroups,
  })  : _weddingId = weddingId,
        _repository = repository ?? GuestRepositoryImpl(),
        _groups = initialGroups ?? const [];

  final String _weddingId;
  final GuestRepository _repository;

  AppStatus _status = AppStatus.initial;
  List<ActivityGroup> _groups;
  String? _errorMessage;

  String get weddingId => _weddingId;
  GuestRepository get repository => _repository;
  AppStatus get status => _status;
  List<ActivityGroup> get groups => _groups;
  String? get errorMessage => _errorMessage;

  bool get isEmpty => _status.isSuccess && _groups.isEmpty;
  bool get isLoading => _status.isLoading;

  Future<void> load() async {
    _status = AppStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_groups.isEmpty) {
        _groups = _defaultGroups();
      }
      _status = AppStatus.success;
    } catch (e) {
      _status = AppStatus.failure;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void setGroups(List<ActivityGroup> groups) {
    _groups = groups;
    _status = AppStatus.success;
    _errorMessage = null;
    notifyListeners();
  }

  void setError(String message) {
    _status = AppStatus.failure;
    _errorMessage = message;
    notifyListeners();
  }

  static List<ActivityGroup> _defaultGroups() {
    return const [
      ActivityGroup(
        titleKey: 'activity.today',
        items: [
          ActivityItem(
            id: '1',
            type: ActivityItemType.confirmed,
            textKey: 'activity.item_confirmed',
            textArgs: {'name': 'مريم الرشيد'},
            whenKey: 'activity.time_hours_ago',
            whenArgs: {'count': '2'},
          ),
          ActivityItem(
            id: '2',
            type: ActivityItemType.added,
            textKey: 'activity.item_added',
            textArgs: {'name': 'سارة', 'count': '12'},
            whenKey: 'activity.time_hours_ago',
            whenArgs: {'count': '3'},
          ),
          ActivityItem(
            id: '3',
            type: ActivityItemType.reminder,
            textKey: 'activity.item_reminders_sent',
            textArgs: {'count': '30'},
            whenKey: 'activity.time_hours_ago',
            whenArgs: {'count': '5'},
          ),
        ],
      ),
      ActivityGroup(
        titleKey: 'activity.yesterday',
        items: [
          ActivityItem(
            id: '4',
            type: ActivityItemType.declined,
            textKey: 'activity.item_declined',
            textArgs: {'name': 'خالد البلوشي'},
            whenKey: 'activity.time_at',
            whenArgs: {'time': '18:42'},
          ),
          ActivityItem(
            id: '5',
            type: ActivityItemType.collaboratorJoined,
            textKey: 'activity.item_collaborator_joined',
            textArgs: {'name': 'عمر'},
            whenKey: 'activity.time_at',
            whenArgs: {'time': '14:10'},
          ),
        ],
      ),
      ActivityGroup(
        titleKey: 'activity.this_week',
        items: [
          ActivityItem(
            id: '6',
            type: ActivityItemType.updated,
            textKey: 'activity.item_updated',
            textArgs: {'name': 'سارة', 'count': '4'},
            whenKey: '8 يونيو',
            rawWhen: '8 يونيو',
          ),
          ActivityItem(
            id: '7',
            type: ActivityItemType.exported,
            textKey: 'activity.item_exported',
            whenKey: '6 يونيو',
            rawWhen: '6 يونيو',
          ),
        ],
      ),
    ];
  }
}
