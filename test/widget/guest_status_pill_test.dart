import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/data/models/guest_model.dart';
import 'package:zawaj_app/src/shared/widgets/guest_status_pill.dart';

Widget _buildPill({
  required RsvpStatus status,
  bool compact = false,
  bool showIcon = false,
}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (context, child) => MaterialApp(
      home: Scaffold(
        body: GuestStatusPill(
          status: status,
          compact: compact,
          showIcon: showIcon,
        ),
      ),
    ),
  );
}

void main() {
  group('GuestStatusPill widget tests', () {
    testWidgets('renders confirmed status with correct icon when showIcon is true', (tester) async {
      await tester.pumpWidget(_buildPill(status: RsvpStatus.confirmed, showIcon: true));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('renders pending status with correct icon when showIcon is true', (tester) async {
      await tester.pumpWidget(_buildPill(status: RsvpStatus.pending, showIcon: true));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('renders declined status with correct icon when showIcon is true', (tester) async {
      await tester.pumpWidget(_buildPill(status: RsvpStatus.declined, showIcon: true));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    });
  });
}
