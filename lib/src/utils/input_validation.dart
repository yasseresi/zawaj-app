/// Shared client-side input rules for values used across the app.
///
/// These rules improve feedback but are intentionally mirrored by the API;
/// the server remains the source of truth for uniqueness and authorization.
abstract final class AppInputValidation {
  static const usernameMinLength = 3;
  static const usernameMaxLength = 120;
  static const passwordMinLength = 8;
  static const passwordMaxLength = 72;
  static const _commonPasswords = {
    'password',
    'password1',
    'password123',
    '12345678',
    'qwerty123',
  };

  static String normalizeUsername(String value) => value.trim().toLowerCase();

  static String? usernameError(String? value) {
    if (value == null || value.trim().isEmpty) return 'auth.username_required';
    final username = value.trim();
    if (username.length < usernameMinLength) return 'auth.username_too_short';
    if (username.length > usernameMaxLength) return 'auth.username_too_long';
    if (RegExp(r'\s').hasMatch(username)) return 'auth.username_no_spaces';
    if (!RegExp(r'^[a-zA-Z0-9._@-]+$').hasMatch(username)) {
      return 'auth.username_invalid';
    }
    return null;
  }

  static String? passwordError(String? value) {
    if (value == null || value.isEmpty) return 'auth.password_required';
    if (value.length < passwordMinLength) return 'auth.password_too_short';
    if (value.length > passwordMaxLength) return 'auth.password_too_long';
    if (RegExp(r'\s').hasMatch(value)) return 'auth.password_no_spaces';
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'auth.password_needs_letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'auth.password_needs_lowercase';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'auth.password_needs_uppercase';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'auth.password_needs_number';
    if (!RegExp(r'[^A-Za-z0-9\s]').hasMatch(value)) {
      return 'auth.password_needs_symbol';
    }
    if (_commonPasswords.contains(value.toLowerCase())) {
      return 'auth.password_too_common';
    }
    return null;
  }
}
