import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/routing/invite_deep_link.dart';

void main() {
  test('extracts token from the custom scheme', () {
    expect(parseInviteToken(Uri.parse('zawaj://i/ABC123')), 'ABC123');
  });

  test('extracts token from the HTTPS share URL', () {
    expect(parseInviteToken(Uri.parse('https://zawaj.app/i/ABC123')), 'ABC123');
  });

  test('rejects unrelated URLs and malformed invite paths', () {
    expect(parseInviteToken(Uri.parse('https://example.com/i/ABC123')), isNull);
    expect(parseInviteToken(Uri.parse('zawaj://i/')), isNull);
    expect(parseInviteToken(Uri.parse('zawaj://other/ABC123')), isNull);
  });
}
