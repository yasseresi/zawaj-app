import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/models/user_model.dart';
import 'package:zawaj_app/src/data/repositories/auth_repository.dart';
import 'package:zawaj_app/src/shared/providers/theme_provider.dart';
import 'package:zawaj_app/src/ui/auth/providers/session_provider.dart';
import 'package:zawaj_app/src/ui/settings/providers/settings_provider.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _FakeAuthRepository implements AuthRepository {
  bool logoutCalled = false;

  @override
  FutureEitherVoid logout() async {
    logoutCalled = true;
    return const Right(null);
  }

  @override
  FutureEither<AuthResult> login({required String username, required String password}) async =>
      throw UnimplementedError();

  @override
  FutureEither<AuthResult> register({
    required String username,
    required String displayName,
    required String password,
  }) async =>
      throw UnimplementedError();

  @override
  FutureEither<AuthResult> recover({
    required String username,
    required String recoveryCode,
    required String newPassword,
  }) async =>
      throw UnimplementedError();

  @override
  FutureEither<AppUser> me() async => throw UnimplementedError();
}

void main() {
  group('SettingsProvider', () {
    late _FakeAuthRepository repo;
    late SessionProvider session;
    late SettingsProvider provider;

    setUp(() {
      repo = _FakeAuthRepository();
      session = SessionProvider(repository: repo);
      provider = SettingsProvider(
        session: session,
        initialLocale: const Locale('ar'),
      );
    });

    test('initial state is correctly set', () {
      expect(provider.locale, const Locale('ar'));
      expect(provider.themeMode, ThemeMode.system);
      expect(provider.isDarkMode, isFalse);
      expect(provider.isLoggingOut, isFalse);
    });

    test('setLocale updates locale and notifies listeners', () {
      var notified = false;
      provider.addListener(() {
        notified = true;
      });

      provider.setLocale(const Locale('en'));

      expect(provider.locale, const Locale('en'));
      expect(notified, isTrue);
    });

    test('setLocale does not notify if locale is unchanged', () {
      var notified = false;
      provider.addListener(() {
        notified = true;
      });

      provider.setLocale(const Locale('ar'));

      expect(notified, isFalse);
    });

    test('setThemeMode updates themeMode and notifies listeners', () async {
      var notified = false;
      provider.addListener(() {
        notified = true;
      });

      await provider.setThemeMode(ThemeMode.dark);

      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.isDarkMode, isTrue);
      expect(notified, isTrue);
    });

    test('toggleDarkMode toggles between dark and light mode', () async {
      await provider.toggleDarkMode(true);
      expect(provider.isDarkMode, isTrue);
      expect(provider.themeMode, ThemeMode.dark);

      await provider.toggleDarkMode(false);
      expect(provider.isDarkMode, isFalse);
      expect(provider.themeMode, ThemeMode.light);
    });

    test('logout invokes session signOut and resets isLoggingOut', () async {
      var notifiedCount = 0;
      provider.addListener(() {
        notifiedCount++;
      });

      final logoutFuture = provider.logout();
      expect(provider.isLoggingOut, isTrue);

      await logoutFuture;

      expect(provider.isLoggingOut, isFalse);
      expect(repo.logoutCalled, isTrue);
      expect(session.isAuthenticated, isFalse);
      expect(notifiedCount, 2);
    });

    test('interacts correctly with ThemeProvider when provided', () async {
      final themeProvider = ThemeProvider();
      final providerWithTheme = SettingsProvider(
        themeProvider: themeProvider,
        session: session,
      );

      expect(providerWithTheme.themeMode, ThemeMode.system);

      await providerWithTheme.setThemeMode(ThemeMode.dark);
      expect(themeProvider.mode, ThemeMode.dark);
      expect(providerWithTheme.isDarkMode, isTrue);
    });
  });
}
