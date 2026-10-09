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
    await tester.pumpWidget(
        _host(formKey: formKey, name: TextEditingController(text: 'a' * 121)));

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

  testWidgets('opens the picker for a date outside the default window',
      (tester) async {
    // A wedding saved years ago: the picker must widen its bounds instead of
    // asserting initialDate >= firstDate.
    await tester.pumpWidget(
        _host(formKey: GlobalKey<FormState>(), date: DateTime(2019, 6, 1)));

    await tester.tap(find.text('2019-06-01'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  test('pickerBounds always contains the current value', () {
    final now = DateTime(2026, 10, 7);
    final old = WeddingFormFields.pickerBounds(now, DateTime(2019, 6, 1));
    expect(old.first, DateTime(2019, 6, 1));
    expect(old.last, DateTime(2031));

    final far = WeddingFormFields.pickerBounds(now, DateTime(2040, 1, 1));
    expect(far.first, DateTime(2025));
    expect(far.last, DateTime(2040, 1, 1));

    final none = WeddingFormFields.pickerBounds(now, null);
    expect((none.first, none.last), (DateTime(2025), DateTime(2031)));
  });
}
