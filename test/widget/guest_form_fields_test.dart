import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/data/models/guest_model.dart';
import 'package:zawaj_app/src/ui/weddings/widgets/guest_form_fields.dart';

Widget _host({
  required GlobalKey<FormState> formKey,
  required TextEditingController contact,
  bool showDetails = false,
  String? legacyContact,
}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (context, child) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: GuestFormFields(
              name: TextEditingController(text: 'Amina'),
              contact: contact,
              status: RsvpStatus.pending,
              onStatusChanged: (_) {},
              companions: 0,
              onCompanionsChanged: (_) {},
              showDetails: showDetails,
              relationship: TextEditingController(),
              tableLabel: TextEditingController(),
              meal: TextEditingController(),
              legacyContact: legacyContact,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('contact must be a valid Algerian phone number', (tester) async {
    final formKey = GlobalKey<FormState>();
    final contact = TextEditingController(text: '0551');
    await tester.pumpWidget(_host(formKey: formKey, contact: contact));

    expect(formKey.currentState!.validate(), isFalse);

    contact.text = '0551 23 45 67';
    expect(formKey.currentState!.validate(), isTrue);
  });

  testWidgets('an unchanged legacy (non-phone) contact stays valid',
      (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(_host(
        formKey: formKey,
        contact: TextEditingController(text: 'ali@x.dz'),
        legacyContact: 'ali@x.dz'));

    expect(formKey.currentState!.validate(), isTrue);
    expect(find.text('guests.contact_legacy_hint'), findsOneWidget);
  });

  testWidgets('relationship, table and meal only appear with showDetails',
      (tester) async {
    await tester.pumpWidget(_host(
        formKey: GlobalKey<FormState>(), contact: TextEditingController()));
    expect(find.text('guests.relationship_label'), findsNothing);

    await tester.pumpWidget(_host(
        formKey: GlobalKey<FormState>(),
        contact: TextEditingController(),
        showDetails: true));
    expect(find.text('guests.relationship_label'), findsOneWidget);
    expect(find.text('guests.table_field_label'), findsOneWidget);
    expect(find.text('guests.meal_field_label'), findsOneWidget);
  });
}
