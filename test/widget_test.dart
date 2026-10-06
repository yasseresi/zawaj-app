import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zawaj_app/src/app.dart';
import 'package:zawaj_app/src/data/models/user_model.dart';
import 'package:zawaj_app/src/data/repositories/auth_repository.dart';
import 'package:zawaj_app/src/ui/auth/login_screen.dart';
import 'package:zawaj_app/src/ui/auth/providers/auth_provider.dart';
import 'package:zawaj_app/src/ui/auth/providers/session_provider.dart';
import 'package:zawaj_app/src/theme/theme.dart';
import 'package:zawaj_app/src/utils/failure.dart';
import 'package:zawaj_app/src/utils/typedefs.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  FutureEitherVoid changePassword(
          {required String oldPassword, required String newPassword}) async =>
      const Right(null);

  @override
  FutureEither<AuthResult> login(
          {required String username, required String password}) async =>
      const Left(AuthFailure('nope'));
  @override
  FutureEither<AuthResult> register({
    required String username,
    required String displayName,
    required String password,
  }) async =>
      const Left(AuthFailure('nope'));
  @override
  FutureEither<AuthResult> recover({
    required String username,
    required String recoveryCode,
    required String newPassword,
  }) async =>
      const Left(AuthFailure('nope'));
  @override
  FutureEitherVoid logout() async => const Right(null);
  @override
  FutureEither<AppUser> me() async => const Left(AuthFailure('nope'));

  @override
  FutureEither<AppUser> updateProfile({String? displayName, String? phone}) async =>
      throw UnimplementedError();

  @override
  FutureEither<AppUser> updateSettings({bool? notifPush, bool? notifRsvp}) async =>
      throw UnimplementedError();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Login screen renders username, password and login button',
      (tester) async {
    await EasyLocalization.ensureInitialized();
    final repo = _FakeAuthRepository();
    final session = SessionProvider(repository: repo);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: Builder(
          builder: (context) => ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (context, _) => ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(repository: repo, session: session),
              child: MaterialApp(
                theme: buildLightTheme(primaryColorHex: kBrandPrimaryHex),
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                home: const LoginScreen(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Log in'), findsWidgets);
  });

  test('App exports a brand seed color', () {
    expect(kBrandPrimaryHex, '#C9796A');
  });
}
