import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/utils/relative_time.dart';

void main() {
  final now = DateTime(2026, 10, 8, 12);

  test('under a minute (or in the future) is "just now"', () {
    final r = relativeTime(now.subtract(const Duration(seconds: 30)), now: now);
    expect((r.key, r.count), ('time.just_now', null));
    expect(relativeTime(now.add(const Duration(minutes: 5)), now: now).key,
        'time.just_now');
  });

  test('minutes, hours, then days, with a count for pluralization', () {
    final m = relativeTime(now.subtract(const Duration(minutes: 7)), now: now);
    expect((m.key, m.count), ('time.minutes_ago', 7));
    final h = relativeTime(now.subtract(const Duration(hours: 3)), now: now);
    expect((h.key, h.count), ('time.hours_ago', 3));
    final d = relativeTime(now.subtract(const Duration(days: 2)), now: now);
    expect((d.key, d.count), ('time.days_ago', 2));
  });
}
