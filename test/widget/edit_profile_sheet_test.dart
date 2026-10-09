import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/data/models/user_model.dart';
import 'package:zawaj_app/src/shared/widgets/app_button.dart';
import 'package:zawaj_app/src/theme/theme.dart';
import 'package:zawaj_app/src/ui/settings/widgets/edit_profile_sheet.dart';

const _user = AppUser(
    id: 'u1', username: 'sarah', displayName: 'Sarah', phone: '0672859965');

Widget _host(Future<bool> Function(String, String) onSave) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (context, child) => MaterialApp(
      theme: buildLightTheme(primaryColorHex: '#E91E63'),
      home: Scaffold(
        body: EditProfileSheet(user: _user, onSave: onSave),
      ),
    ),
  );
}

AppButton _saveButton(WidgetTester tester) =>
    tester.widget<AppButton>(find.byType(AppButton));

void main() {
  testWidgets('prefills current values and disables Save until a change',
      (tester) async {
    await tester.pumpWidget(_host((_, __) async => true));

    expect(find.text('Sarah'), findsOneWidget);
    expect(find.text('0672 85 99 65'), findsOneWidget);
    expect(_saveButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextFormField).first, 'Sara');
    await tester.pump();
    expect(_saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('an invalid phone keeps Save disabled', (tester) async {
    await tester.pumpWidget(_host((_, __) async => true));

    await tester.enterText(find.byType(TextFormField).last, '0551');
    await tester.pump();
    expect(_saveButton(tester).onPressed, isNull);
  });

  testWidgets('an empty name keeps Save disabled', (tester) async {
    await tester.pumpWidget(_host((_, __) async => true));

    await tester.enterText(find.byType(TextFormField).first, '  ');
    await tester.pump();
    expect(_saveButton(tester).onPressed, isNull);
  });

  testWidgets('Save passes the edited values to onSave', (tester) async {
    String? savedName;
    String? savedPhone;
    await tester.pumpWidget(_host((name, phone) async {
      savedName = name;
      savedPhone = phone;
      return false; // stay open
    }));

    await tester.enterText(find.byType(TextFormField).last, '');
    await tester.pump();
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    expect(savedName, 'Sarah');
    expect(savedPhone, '');
    // Failure keeps the sheet (and the user's input) on screen.
    expect(find.byType(EditProfileSheet), findsOneWidget);
  });
}
