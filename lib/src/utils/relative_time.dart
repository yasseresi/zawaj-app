/// How long ago [when] was, as a translation key plus the count to pluralize
/// it with (pure, so it's testable without a locale). Render with
/// `key.plural(count)` when [count] is non-null, else `key.tr()`. Future
/// times read as "just now".
///
/// Keys: `time.just_now`, and plural `time.minutes_ago`, `time.hours_ago`,
/// `time.days_ago` (forms per language, e.g. Arabic dual/few/many).
({String key, int? count}) relativeTime(DateTime when, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(when);
  if (diff.inMinutes < 1) return (key: 'time.just_now', count: null);
  if (diff.inHours < 1) return (key: 'time.minutes_ago', count: diff.inMinutes);
  if (diff.inDays < 1) return (key: 'time.hours_ago', count: diff.inHours);
  return (key: 'time.days_ago', count: diff.inDays);
}
