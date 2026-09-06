import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/utils/input_validation.dart';

void main() {
  group('AppInputValidation', () {
    test('normalizes usernames consistently', () {
      expect(AppInputValidation.normalizeUsername('  Leila  '), 'leila');
    });

    test('rejects blank, short, spaced, and invalid usernames', () {
      expect(AppInputValidation.usernameError(''), 'auth.username_required');
      expect(AppInputValidation.usernameError('ab'), 'auth.username_too_short');
      expect(AppInputValidation.usernameError('le ila'),
          'auth.username_no_spaces');
      expect(
          AppInputValidation.usernameError('leila!'), 'auth.username_invalid');
      expect(AppInputValidation.usernameError('leila'), isNull);
    });

    test('requires a stronger password than length alone', () {
      expect(AppInputValidation.passwordError(''), 'auth.password_required');
      expect(AppInputValidation.passwordError('short1'),
          'auth.password_too_short');
      expect(AppInputValidation.passwordError('password'),
          'auth.password_needs_uppercase');
      expect(AppInputValidation.passwordError('12345678'),
          'auth.password_needs_letter');
      expect(AppInputValidation.passwordError('Password1'),
          'auth.password_needs_symbol');
      expect(AppInputValidation.passwordError('Password1!'), isNull);
    });
  });
}
