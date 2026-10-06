import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/ui/weddings/widgets/wedding_form_fields.dart';

Widget _host({
  required GlobalKey<FormState> formKey,
  TextEditingController? name,
  DateTime? date,
  bool canClearDate = true,
}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (context, child) => MaterialApp(
      home: Scaffold(
        body: Form(
          key: formKey,
          child: WeddingFormFields(
            name: name ?? TextEditingController(),
            description: TextEditingController(),
            date: date,
            onDateChanged: (_) {},
            canClearDate: canClearDate,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('name is required', (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(_host(formKey: formKey));

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('weddings.name_required'), findsOneWidget);
  });

  testWidgets('name longer than 120 characters is rejected', (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(_host(
        formKey: formKey, name: TextEditingController(text: 'a' * 121)));

    expect(formKey.currentState!.validate(), isFalse);
  });

  testWidgets('shows the selected date with a clear button by default',
      (tester) async {
    await tester.pumpWidget(
        _host(formKey: GlobalKey<FormState>(), date: DateTime(2026, 12, 1)));

    expect(find.text('2026-12-01'), findsOneWidget);
    expect(find.byIcon(Icons.clear), findsOneWidget);
  });

  testWidgets('hides the clear button when the date cannot be cleared',
      (tester) async {
    await tester.pumpWidget(_host(
        formKey: GlobalKey<FormState>(),
        date: DateTime(2026, 12, 1),
        canClearDate: false));

    expect(find.byIcon(Icons.clear), findsNothing);
  });
}
