import 'package:zawaj_app/src/imports/imports.dart';

/// One-time recovery-code reveal. Shown after register/recover — this is the
/// ONLY time the code is visible (the backend stores only a hash), and it's the
/// sole account-reset path, so the user must acknowledge saving it before we
/// continue. Non-dismissible by design.
class RecoveryCodeDialog extends StatelessWidget {
  const RecoveryCodeDialog({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.shield_outlined, size: 44.sp, color: cs.primary),
            SizedBox(height: AppSpacing.md.h),
            Text('auth.recovery_title'.tr(),
                textAlign: TextAlign.center,
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: AppSpacing.sm.h),
            Text('auth.recovery_desc'.tr(),
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            SizedBox(height: AppSpacing.lg.h),
            InkWell(
              borderRadius: AppBorders.md,
              onTap: () async {
                await CopyService.instance.copy(code);
                showGlobalToast(message: 'auth.recovery_copied'.tr(), status: 'success');
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                    vertical: AppSpacing.md.h, horizontal: AppSpacing.md.w),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: AppBorders.md,
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        code,
                        style: tt.titleMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Icon(Icons.copy_rounded, size: 20.sp, color: cs.primary),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppSpacing.lg.h),
            AppButton(
              label: 'auth.recovery_saved'.tr(),
              isFullWidth: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}
