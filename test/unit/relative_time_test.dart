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

  test('unit boundaries: 59m, 1h, 23h59m, 24h', () {
    ({String key, int? count}) at(Duration d) =>
        relativeTime(now.subtract(d), now: now);
    expect(at(const Duration(minutes: 59)), (key: 'time.minutes_ago', count: 59));
    expect(at(const Duration(hours: 1)), (key: 'time.hours_ago', count: 1));
    expect(at(const Duration(hours: 23, minutes: 59)),
        (key: 'time.hours_ago', count: 23));
    expect(at(const Duration(hours: 24)), (key: 'time.days_ago', count: 1));
  });
}
