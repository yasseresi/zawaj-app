import '../../imports/core_imports.dart';

/// Asks before throwing away unsaved form edits. Returns true to discard.
Future<bool> confirmDiscardChanges(BuildContext context) async =>
    await showAdaptiveConfirmDialog(
      context,
      title: 'actions.discard_title'.tr(),
      message: 'actions.discard_message'.tr(),
      confirmLabel: 'actions.discard'.tr(),
      cancelLabel: 'actions.keep_editing'.tr(),
      isDestructive: true,
    ) ??
    false;
