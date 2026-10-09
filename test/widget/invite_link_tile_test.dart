import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/data/models/invite_link_model.dart';
import 'package:zawaj_app/src/theme/theme.dart';
import 'package:zawaj_app/src/ui/share/widgets/invite_link_tile.dart';

void main() {
  testWidgets('shows the granted role and fires revoke', (tester) async {
    var revoked = 0;
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(
        theme: buildLightTheme(primaryColorHex: '#E91E63'),
        home: Scaffold(
          body: InviteLinkTile(
            link: InviteLink(
                id: 'l1',
                token: 't',
                role: 'editor',
                createdAt: DateTime(2026, 10, 1)),
            onRevoke: () => revoked++,
          ),
        ),
      ),
    ));

    expect(find.text('share.link_grants'), findsOneWidget);
    expect(find.text('share.link_created_on'), findsOneWidget);

    await tester.tap(find.byTooltip('share.revoke_link'));
    expect(revoked, 1);
  });
}
