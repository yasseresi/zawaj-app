import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/utils/relative_time.dart';

void main() {
  final now = DateTime(2026, 10, 8, 12);

  test('under a minute (or in the future) is "just now"', () {
    expect(relativeTime(now.subtract(const Duration(seconds: 30)), now: now).key,
        'time.just_now');
    expect(relativeTime(now.add(const Duration(minutes: 5)), now: now).key,
        'time.just_now');
  });

  test('minutes, hours, then days', () {
    final m = relativeTime(now.subtract(const Duration(minutes: 7)), now: now);
    expect(m.key, 'time.minutes_ago');
    expect(m.args, {'count': '7'});
    final h = relativeTime(now.subtract(const Duration(hours: 3)), now: now);
    expect(h.key, 'time.hours_ago');
    expect(h.args, {'count': '3'});
    final d = relativeTime(now.subtract(const Duration(days: 2)), now: now);
    expect(d.key, 'time.days_ago');
    expect(d.args, {'count': '2'});
  });
}
