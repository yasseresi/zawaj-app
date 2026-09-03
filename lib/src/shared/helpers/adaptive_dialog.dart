import '../../imports/core_imports.dart';

/// Platform-adaptive confirmation dialog.
///
/// iOS → [CupertinoAlertDialog]; everything else → Material [AlertDialog].
///
/// Returns `true` when the confirm action is tapped, `false`/`null` otherwise.
/// [isDestructive] tints the confirm action with the error color.
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
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancel),
        ),
        TextButton(
          style: isDestructive
              ? TextButton.styleFrom(foregroundColor: ctx.colors.error)
              : null,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
