/// How long ago [when] was, as a translation key plus its named args (pure,
/// so it's testable without a locale). Future times read as "just now".
///
/// Keys: `time.just_now`, `time.minutes_ago`, `time.hours_ago`,
/// `time.days_ago` (each with `{count}` except just_now).
({String key, Map<String, String> args}) relativeTime(DateTime when,
    {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(when);
  if (diff.inMinutes < 1) return (key: 'time.just_now', args: const {});
  if (diff.inHours < 1) {
    return (key: 'time.minutes_ago', args: {'count': '${diff.inMinutes}'});
  }
  if (diff.inDays < 1) {
    return (key: 'time.hours_ago', args: {'count': '${diff.inHours}'});
  }
  return (key: 'time.days_ago', args: {'count': '${diff.inDays}'});
}
