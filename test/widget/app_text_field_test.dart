import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/shared/widgets/app_text_field.dart';

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: child),
        ),
      ),
    );

void main() {
  testWidgets('password fields are LTR inside an RTL layout', (tester) async {
    await tester.pumpWidget(_host(const AppTextField(obscureText: true)));

    expect(tester.widget<EditableText>(find.byType(EditableText)).textDirection,
        TextDirection.ltr);
  });

  testWidgets('regular fields follow the ambient (RTL) direction',
      (tester) async {
    await tester.pumpWidget(_host(const AppTextField()));

    // null = inherit the ambient Directionality (RTL here).
    expect(tester.widget<EditableText>(find.byType(EditableText)).textDirection,
        isNull);
  });
}
