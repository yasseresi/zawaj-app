import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/data/models/join_request_model.dart';
import 'package:zawaj_app/src/data/models/wedding_model.dart';
import 'package:zawaj_app/src/theme/theme.dart';
import 'package:zawaj_app/src/ui/share/widgets/join_request_tile.dart';

const _lina = JoinRequest(
    id: 'r1',
    userId: 'u3',
    username: 'lina',
    displayName: 'Lina',
    role: WeddingRole.editor);

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(
        theme: buildLightTheme(primaryColorHex: '#E91E63'),
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('shows who asks and wires approve/decline', (tester) async {
    var approved = 0, declined = 0;
    await tester.pumpWidget(_host(JoinRequestTile(
      request: _lina,
      onApprove: () => approved++,
      onDecline: () => declined++,
    )));

    expect(find.text('Lina'), findsOneWidget);
    expect(find.text('share.join_request_subtitle'), findsOneWidget);

    await tester.tap(find.text('share.approve'));
    await tester.tap(find.text('share.decline'));
    expect((approved, declined), (1, 1));
  });

  testWidgets('buttons are disabled while a decision is in flight',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(JoinRequestTile(
      request: _lina,
      deciding: true,
      onApprove: () => taps++,
      onDecline: () => taps++,
    )));

    await tester.tap(find.text('share.approve'));
    await tester.tap(find.text('share.decline'));
    expect(taps, 0);
  });
}
