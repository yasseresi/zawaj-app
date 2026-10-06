import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:zawaj_app/src/data/models/user_model.dart';
import 'package:zawaj_app/src/data/repositories/auth_repository.dart';
import 'package:zawaj_app/src/shared/providers/theme_provider.dart';
import 'package:zawaj_app/src/ui/auth/providers/session_provider.dart';
import 'package:zawaj_app/src/ui/settings/providers/settings_provider.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _FakeAuthRepository implements AuthRepository {
  bool logoutCalled = false;
  bool changePasswordCalled = false;
  String? oldPassword;
  String? newPassword;

  @override
  FutureEitherVoid changePassword(
      {required String oldPassword, required String newPassword}) async {
    changePasswordCalled = true;
    this.oldPassword = oldPassword;
    this.newPassword = newPassword;
    return const Right(null);
  }

  @override
  FutureEitherVoid logout() async {
    logoutCalled = true;
    return const Right(null);
  }

  @override
  FutureEither<AuthResult> login(
          {required String username, required String password}) async =>
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

  Either<Failure, void> deleteResult = const Right(null);
  String? deletedWithPassword;

  @override
  FutureEitherVoid deleteAccount({required String password}) async {
    deletedWithPassword = password;
    return deleteResult;
  }

  /// Recorded calls + canned results for profile/settings writes.
  final profileCalls = <({String? displayName, String? phone})>[];
  final settingsCalls = <({bool? notifPush, bool? notifRsvp})>[];
  Either<Failure, AppUser>? profileResult;
  Either<Failure, AppUser>? settingsResult;

  @override
  FutureEither<AppUser> updateProfile({String? displayName, String? phone}) async {
    profileCalls.add((displayName: displayName, phone: phone));
    return profileResult!;
  }

  @override
  FutureEither<AppUser> updateSettings({bool? notifPush, bool? notifRsvp}) async {
    settingsCalls.add((notifPush: notifPush, notifRsvp: notifRsvp));
    return settingsResult!;
  }
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
        authRepository: repo,
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

    test('changePassword delegates credentials and reports success', () async {
      final ok = await provider.changePassword(
        oldPassword: 'OldPassword1!',
        newPassword: 'NewPassword1!',
      );

      expect(ok, isTrue);
      expect(repo.changePasswordCalled, isTrue);
      expect(repo.oldPassword, 'OldPassword1!');
      expect(repo.newPassword, 'NewPassword1!');
      expect(provider.isChangingPassword, isFalse);
      expect(provider.passwordErrorMessage, isNull);
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

    group('updateProfile', () {
      const current = AppUser(id: 'u1', username: 'sarah', displayName: 'Sarah', phone: '0672859965');

      setUp(() => session.setAuthenticated(current));

      test('sends only the changed display name and updates the session', () async {
        repo.profileResult = Right(current.copyWith(displayName: 'Sara'));

        final ok = await provider.updateProfile(displayName: ' Sara ', phone: '0672 85 99 65');

        expect(ok, isTrue);
        expect(repo.profileCalls.single, (displayName: 'Sara', phone: null));
        expect(session.user!.displayName, 'Sara');
      });

      test('sends an empty phone to clear it', () async {
        repo.profileResult = const Right(AppUser(id: 'u1', username: 'sarah', displayName: 'Sarah'));

        await provider.updateProfile(displayName: 'Sarah', phone: '');

        expect(repo.profileCalls.single, (displayName: null, phone: ''));
        expect(session.user!.phone, isNull);
      });

      test('normalizes a changed phone before sending', () async {
        repo.profileResult = const Right(current);

        await provider.updateProfile(displayName: 'Sarah', phone: '+213 551 23 45 67');

        expect(repo.profileCalls.single, (displayName: null, phone: '0551234567'));
      });

      test('makes no request when nothing changed', () async {
        final ok = await provider.updateProfile(displayName: 'Sarah', phone: '0672859965');

        expect(ok, isTrue);
        expect(repo.profileCalls, isEmpty);
      });

      test('keeps the session and exposes an error on failure', () async {
        repo.profileResult = const Left(ServerFailure('boom'));

        final ok = await provider.updateProfile(displayName: 'Other', phone: '0672859965');

        expect(ok, isFalse);
        expect(provider.profileErrorMessage, isNotNull);
        expect(provider.isSavingProfile, isFalse);
        expect(session.user, current);
      });
    });

    group('notification preferences', () {
      const current = AppUser(id: 'u1', username: 'sarah', displayName: 'Sarah');

      setUp(() => session.setAuthenticated(current));

      test('push toggle updates the session optimistically and keeps the server copy', () async {
        repo.settingsResult = Right(current.copyWith(notifPush: false));

        final pending = provider.setNotifPush(false);
        expect(session.user!.notifPush, isFalse); // optimistic, before the reply
        final ok = await pending;

        expect(ok, isTrue);
        expect(repo.settingsCalls.single, (notifPush: false, notifRsvp: null));
        expect(session.user!.notifPush, isFalse);
      });

      test('a failed toggle rolls back and exposes an error', () async {
        repo.settingsResult = const Left(ServerFailure('boom'));

        final ok = await provider.setNotifRsvp(false);

        expect(ok, isFalse);
        expect(repo.settingsCalls.single, (notifPush: null, notifRsvp: false));
        expect(session.user!.notifRsvp, isTrue);
        expect(provider.preferencesErrorMessage, isNotNull);
      });

      test('ignores taps while a request for the same switch is in flight', () async {
        repo.settingsResult = Right(current.copyWith(notifPush: false));

        final first = provider.setNotifPush(false);
        expect(provider.isSavingNotifPush, isTrue);
        final second = await provider.setNotifPush(true);
        await first;

        expect(second, isFalse);
        expect(repo.settingsCalls, hasLength(1));
        expect(provider.isSavingNotifPush, isFalse);
      });
    });

    group('SessionProvider.deleteAccount', () {
      const user = AppUser(id: 'u1', username: 'sarah', displayName: 'Sarah');

      setUp(() => session.setAuthenticated(user));

      test('signs out locally after the server deletes the account', () async {
        final failure = await session.deleteAccount('Password123!');

        expect(failure, isNull);
        expect(repo.deletedWithPassword, 'Password123!');
        expect(session.status, SessionStatus.unauthenticated);
        expect(session.user, isNull);
      });

      test('stays signed in and returns the failure on a wrong password', () async {
        repo.deleteResult = const Left(AuthFailure('password is incorrect'));

        final failure = await session.deleteAccount('nope');

        expect(failure, isA<AuthFailure>());
        expect(session.status, SessionStatus.authenticated);
        expect(session.user, user);
      });
    });
  });
}
