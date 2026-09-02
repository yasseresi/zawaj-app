import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../data/models/activity_feed_model.dart';
import '../../../data/models/guest_detail_model.dart' show ActivityAction;
import '../../../data/repositories/activity_repository.dart';
import '../../../data/repositories/activity_repository_impl.dart';
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
    ActivityRepository? repository,
    List<ActivityGroup>? initialGroups,
    DateTime Function()? now,
  })  : _weddingId = weddingId,
        _repository = repository ?? ActivityRepositoryImpl(),
        _now = now ?? DateTime.now,
        _groups = initialGroups ?? const [];

  final String _weddingId;
  final ActivityRepository _repository;
  final DateTime Function() _now;

  AppStatus _status = AppStatus.initial;
  List<ActivityGroup> _groups;
  String? _errorMessage;

  String get weddingId => _weddingId;
  ActivityRepository get repository => _repository;
  AppStatus get status => _status;
  List<ActivityGroup> get groups => _groups;
  String? get errorMessage => _errorMessage;

  bool get isEmpty => _status.isSuccess && _groups.isEmpty;
  bool get isLoading => _status.isLoading;

  Future<void> load() async {
    _status = AppStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.feed(_weddingId);
    result.match(
      (failure) {
        _status = AppStatus.failure;
        _errorMessage = failure.message;
        notifyListeners();
      },
      (page) {
        _groups = _groupByDay(page.items);
        _status = AppStatus.success;
        notifyListeners();
      },
    );
  }

  void setError(String message) {
    _status = AppStatus.failure;
    _errorMessage = message;
    notifyListeners();
  }

  /// Buckets entries into today / yesterday / this-week / earlier groups
  /// (newest-first) and maps each to a display [ActivityItem].
  List<ActivityGroup> _groupByDay(List<ActivityFeedEntry> entries) {
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(const Duration(days: 7));

    final buckets = <String, List<ActivityItem>>{
      'activity.today': [],
      'activity.yesterday': [],
      'activity.this_week': [],
      'activity.earlier': [],
    };

    for (final e in entries) {
      final when = e.createdAt ?? now;
      final day = DateTime(when.year, when.month, when.day);
      final String key;
      if (!day.isBefore(today)) {
        key = 'activity.today';
      } else if (!day.isBefore(yesterday)) {
        key = 'activity.yesterday';
      } else if (!day.isBefore(weekStart)) {
        key = 'activity.this_week';
      } else {
        key = 'activity.earlier';
      }
      buckets[key]!.add(_mapEntry(e, now));
    }

    return [
      for (final entry in buckets.entries)
        if (entry.value.isNotEmpty)
          ActivityGroup(titleKey: entry.key, items: entry.value),
    ];
  }

  ActivityItem _mapEntry(ActivityFeedEntry e, DateTime now) {
    final when = e.createdAt ?? now;
    final whenParts = _relativeWhen(when, now);

    switch (e.action) {
      case ActivityAction.guestStatusChanged:
        final status = e.metaString('status');
        final name = e.guestName ?? e.actorName;
        if (status == 'confirmed') {
          return _item(e, ActivityItemType.confirmed, 'activity.item_confirmed',
              {'name': name}, whenParts);
        }
        if (status == 'declined') {
          return _item(e, ActivityItemType.declined, 'activity.item_declined',
              {'name': name}, whenParts);
        }
        return _item(e, ActivityItemType.updated, 'activity.item_updated',
            {'name': name, 'count': '1'}, whenParts);
      case ActivityAction.guestAdded:
        final count = e.metaInt('count');
        return _item(e, ActivityItemType.added, 'activity.item_added',
            {'name': e.actorName, 'count': '${count > 0 ? count : 1}'}, whenParts);
      case ActivityAction.guestUpdated:
        return _item(e, ActivityItemType.updated, 'activity.item_updated',
            {'name': e.guestName ?? e.actorName, 'count': '1'}, whenParts);
      case ActivityAction.remindersSent:
        return _item(e, ActivityItemType.reminder, 'activity.item_reminders_sent',
            {'count': '${e.metaInt('count')}'}, whenParts);
      case ActivityAction.collaboratorJoined:
        return _item(e, ActivityItemType.collaboratorJoined,
            'activity.item_collaborator_joined', {'name': e.actorName}, whenParts);
      case ActivityAction.listExported:
        return _item(e, ActivityItemType.exported, 'activity.item_exported',
            const {}, whenParts);
      case ActivityAction.noteAdded:
      case ActivityAction.unknown:
        return _item(e, ActivityItemType.updated, 'activity.item_updated',
            {'name': e.guestName ?? e.actorName, 'count': '1'}, whenParts);
    }
  }

  ActivityItem _item(
    ActivityFeedEntry e,
    ActivityItemType type,
    String textKey,
    Map<String, String> textArgs,
    ({String key, Map<String, String> args}) when,
  ) {
    return ActivityItem(
      id: e.id,
      type: type,
      textKey: textKey,
      textArgs: textArgs,
      whenKey: when.key,
      whenArgs: when.args,
    );
  }

  /// Within-day recency: hours-ago for entries under a day old, else the local
  /// HH:mm the entry landed. Both are localized via translation keys.
  ({String key, Map<String, String> args}) _relativeWhen(
      DateTime when, DateTime now) {
    final diff = now.difference(when);
    if (diff.inHours < 24 && !diff.isNegative) {
      final hours = diff.inHours < 1 ? 1 : diff.inHours;
      return (key: 'activity.time_hours_ago', args: {'count': '$hours'});
    }
    final hh = when.hour.toString().padLeft(2, '0');
    final mm = when.minute.toString().padLeft(2, '0');
    return (key: 'activity.time_at', args: {'time': '$hh:$mm'});
  }
}
