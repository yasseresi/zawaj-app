import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zawaj_app/src/data/models/wedding_member_model.dart';
import 'package:zawaj_app/src/data/models/wedding_model.dart';
import 'package:zawaj_app/src/theme/theme.dart';
import 'package:zawaj_app/src/ui/share/widgets/member_tile.dart';
import 'package:zawaj_app/src/ui/share/widgets/role_picker_sheet.dart';

const _omar = WeddingMember(
    userId: 'u2',
    username: 'omar',
    displayName: 'Omar',
    role: WeddingRole.editor);

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(
        theme: buildLightTheme(primaryColorHex: '#E91E63'),
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('a read-only tile has no actions menu', (tester) async {
    await tester.pumpWidget(_host(const MemberTile(member: _omar)));

    expect(find.byTooltip('share.member_actions'), findsNothing);
    expect(find.text('share.role_editor'), findsOneWidget);
  });

  testWidgets('menu lists only the provided actions', (tester) async {
    var changed = 0;
    await tester.pumpWidget(_host(MemberTile(
      member: _omar,
      onChangeRole: () => changed++,
      onRemove: () {},
    )));

    await tester.tap(find.byTooltip('share.member_actions'));
    await tester.pumpAndSettle();
    expect(find.text('share.change_role'), findsOneWidget);
    expect(find.text('share.remove_confirm'), findsOneWidget);
    expect(find.text('share.make_owner'), findsNothing);

    await tester.tap(find.text('share.change_role'));
    await tester.pumpAndSettle();
    expect(changed, 1);
  });

  testWidgets('role picker preselects the current role and pops the choice',
      (tester) async {
    WeddingRole? picked;
    await tester.pumpWidget(_host(Builder(
      builder: (context) => TextButton(
        onPressed: () async => picked = await showModalBottomSheet<WeddingRole>(
          context: context,
          builder: (_) => const RolePickerSheet(member: _omar),
        ),
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final editor = tester.widget<RadioListTile<WeddingRole>>(
        find.byType(RadioListTile<WeddingRole>).first);
    expect(editor.value, WeddingRole.editor);
    expect(find.text('share.role_viewer_desc'), findsOneWidget);

    await tester.tap(find.text('share.role_viewer'));
    await tester.pumpAndSettle();
    expect(picked, WeddingRole.viewer);
  });
}
