import '../../imports/core_imports.dart';

/// Platform-adaptive confirmation dialog.
///
/// iOS → [CupertinoAlertDialog]; everything else → Material [AlertDialog].
///
/// Returns `true` when the confirm action is tapped, `false`/`null` otherwise.
/// [isDestructive] uses the platform's destructive action treatment.
Future<bool?> showAdaptiveConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  bool isDestructive = false,
}) {
  final cancel = cancelLabel ?? 'actions.cancel'.tr();

  if (PlatformInfo.isIOS) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            isDestructiveAction: isDestructive,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(message, textAlign: TextAlign.center),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(cancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: isDestructive
                    ? FilledButton.styleFrom(
                        backgroundColor: ctx.colors.error,
                        foregroundColor: ctx.colors.onError,
                      )
                    : null,
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(confirmLabel),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
