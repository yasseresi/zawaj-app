import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<String>> _render(
    WidgetTester tester, Locale locale, List<(String, int)> cases) async {
  final out = <String>[];
  await tester.runAsync(() => tester.pumpWidget(EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: locale,
        ignorePluralRules: false,
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: Builder(builder: (context) {
              out
                ..clear()
                ..addAll([for (final (k, n) in cases) k.plural(n)]);
              return const SizedBox();
            }),
          ),
        ),
      )));
  await tester.pumpAndSettle();
  return out;
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('Arabic uses singular, dual, few and many forms', (tester) async {
    final r = await _render(tester, const Locale('ar'), [
      ('time.minutes_ago', 1),
      ('time.minutes_ago', 2),
      ('time.minutes_ago', 5),
      ('time.days_ago', 11),
      ('weddings.guests_count', 5), // existing key: was "5 ضيف" before
    ]);
    expect(r, [
      'منذ دقيقة',
      'منذ دقيقتين',
      'منذ 5 دقائق',
      'منذ 11 يومًا',
      '5 ضيوف',
    ]);
  });

  testWidgets('French distinguishes one from many', (tester) async {
    final r = await _render(tester, const Locale('fr'),
        [('time.days_ago', 1), ('time.days_ago', 3)]);
    expect(r, ['il y a 1 jour', 'il y a 3 jours']);
  });
}
