import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/shared/widgets/app_phone_field.dart';

Widget _host({
  required TextEditingController controller,
  required GlobalKey<FormState> formKey,
  bool required = false,
  TextDirection direction = TextDirection.rtl,
}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (context, child) => MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Form(
            key: formKey,
            child: AppPhoneField(controller: controller, required: required),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('accepts a spaced mobile number and exposes the canonical value',
      (tester) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(_host(controller: controller, formKey: formKey));

    await tester.enterText(find.byType(TextFormField), '0672 85 99 65');
    expect(formKey.currentState!.validate(), isTrue);
    expect(AppPhoneField.valueOf(controller.text), '0672859965');
  });

  testWidgets('shows an inline error for an invalid number', (tester) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(_host(controller: controller, formKey: formKey));

    await tester.enterText(find.byType(TextFormField), '123');
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('phone.invalid'), findsOneWidget);
  });

  testWidgets('empty is valid when optional and invalid when required',
      (tester) async {
    final optionalKey = GlobalKey<FormState>();
    await tester.pumpWidget(
        _host(controller: TextEditingController(), formKey: optionalKey));
    expect(optionalKey.currentState!.validate(), isTrue);
    expect(AppPhoneField.valueOf(''), '');

    final requiredKey = GlobalKey<FormState>();
    await tester.pumpWidget(_host(
        controller: TextEditingController(),
        formKey: requiredKey,
        required: true));
    expect(requiredKey.currentState!.validate(), isFalse);
  });

  testWidgets('drops letters while typing', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
        _host(controller: controller, formKey: GlobalKey<FormState>()));

    await tester.enterText(find.byType(TextFormField), '06a72');
    expect(controller.text, '0672');
  });

  testWidgets('renders the number left-to-right inside an RTL layout',
      (tester) async {
    await tester.pumpWidget(_host(
        controller: TextEditingController(text: '0672859965'),
        formKey: GlobalKey<FormState>()));

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.textDirection, TextDirection.ltr);
  });
}
