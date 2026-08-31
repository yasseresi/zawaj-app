import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/config/app_config.dart';

/// Regression guard for the "no internet on iOS simulator" bug.
///
/// `.env` holds `localhost`. The Android emulator cannot reach the host via
/// `localhost` (it needs `10.0.2.2`), while the iOS simulator reaches the host
/// *only* via `localhost` — `10.0.2.2` is a dead address there. A single
/// hardcoded value breaks one platform or the other, so the base URL must be
/// resolved per-platform at runtime.
void main() {
  group('AppConfig.resolveBaseUrl', () {
    const envUrl = 'http://localhost:8080/api/v1';

    test('iOS keeps localhost so it can reach the host machine', () {
      final url = AppConfig.resolveBaseUrl(envUrl, isAndroid: false);
      expect(url, 'http://localhost:8080/api/v1');
    });

    test('Android rewrites localhost to the 10.0.2.2 host alias', () {
      final url = AppConfig.resolveBaseUrl(envUrl, isAndroid: true);
      expect(url, 'http://10.0.2.2:8080/api/v1');
    });

    test('Android only rewrites the host, leaving 127.0.0.1 as authored', () {
      final url = AppConfig.resolveBaseUrl(
        'http://127.0.0.1:8080/api/v1',
        isAndroid: true,
      );
      // Only the literal `localhost` token is aliased; other hosts pass through.
      expect(url, 'http://127.0.0.1:8080/api/v1');
    });

    test('non-localhost URLs pass through unchanged on both platforms', () {
      const lan = 'http://192.168.1.20:8080/api/v1';
      expect(AppConfig.resolveBaseUrl(lan, isAndroid: true), lan);
      expect(AppConfig.resolveBaseUrl(lan, isAndroid: false), lan);
    });
  });
}
