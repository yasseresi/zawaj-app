import 'package:zawaj_app/src/imports/core_imports.dart';
import 'package:zawaj_app/src/imports/packages_imports.dart';

/// Mockup screen 7 "add note" sheet: a single multiline field + save button.
/// Pops the entered note body (or null on cancel). Present via [showAppSheet];
/// the caller persists it. Validates required + ≤2000 chars.
class AddNoteSheet extends StatefulWidget {
  const AddNoteSheet({super.key});

  @override
  State<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<AddNoteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _body = TextEditingController();

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.hideKeyboard();
    Navigator.of(context).pop(_body.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppBorders.bottomSheet,
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg.w,
        right: AppSpacing.lg.w,
        top: AppSpacing.sm.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg.h,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: AppSpacing.md.h),
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              'guests.add_note_title'.tr(),
              style: context.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppSpacing.lg.h),
            AppTextField(
              controller: _body,
              hint: 'guests.note_body_hint'.tr(),
              maxLines: 5,
              minLines: 4,
              autofocus: true,
              keyboardType: TextInputType.multiline,
              validator: (v) {
                if (AppUtils.isBlank(v)) return 'guests.note_required'.tr();
                if (v!.trim().length > 2000) return 'guests.note_too_long'.tr();
                return null;
              },
            ),
            SizedBox(height: AppSpacing.lg.h),
            AppButton(
              label: 'guests.save_note'.tr(),
              isFullWidth: true,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
