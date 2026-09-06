import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zawaj_app/src/shared/helpers/adaptive_dialog.dart';

Future<Future<bool?>?> _pumpDialogHarness(WidgetTester tester) async {
  Future<bool?>? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () {
            result = showAdaptiveConfirmDialog(
              context,
              title: 'Confirm action',
              message: 'This cannot be undone.',
              confirmLabel: 'Confirm',
              cancelLabel: 'Cancel',
              isDestructive: true,
            );
          },
          child: const Text('Open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('iOS uses Cupertino dialog and cancel returns false',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      final result = await _pumpDialogHarness(tester);

      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await result, isFalse);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('iOS confirm returns true', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      final result = await _pumpDialogHarness(tester);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Android uses styled Material dialog and cancel returns false',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final result = await _pumpDialogHarness(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(CupertinoAlertDialog), findsNothing);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await result, isFalse);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Android confirm returns true', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final result = await _pumpDialogHarness(tester);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
