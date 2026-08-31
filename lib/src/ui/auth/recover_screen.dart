import 'package:zawaj_app/src/imports/core_imports.dart';
import 'package:zawaj_app/src/imports/packages_imports.dart';

import 'package:zawaj_app/src/ui/auth/providers/auth_provider.dart';
import 'package:zawaj_app/src/ui/auth/widgets/recovery_code_dialog.dart';

/// Password reset via recovery code (the only reset path — no email).
/// username + recovery_code + new_password → a NEW one-time recovery code is
/// issued and must be shown before the session is promoted.
class RecoverScreen extends StatefulWidget {
  const RecoverScreen({super.key});

  @override
  State<RecoverScreen> createState() => _RecoverScreenState();
}

class _RecoverScreenState extends State<RecoverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.hideKeyboard();
    final auth = context.read<AuthProvider>();
    final ok = await auth.recover(
      username: _username.text.trim(),
      recoveryCode: _code.text.trim(),
      newPassword: _password.text,
    );
    if (!mounted) return;
    if (!ok) {
      showToast(context, message: auth.errorMessage ?? 'errors.server'.tr(), status: 'error');
      return;
    }
    await showAppDialog<bool>(
      dismissible: false,
      child: RecoveryCodeDialog(code: auth.pendingRecoveryCode ?? ''),
    );
    auth.confirmPending();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select((AuthProvider p) => p.isLoading);
    final cs = context.colors;
    final tt = context.textTheme;

    return Scaffold(
      appBar: const AppTopBar(title: ''),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: AppSpacing.md.h),
                  Text('auth.recover_title'.tr(),
                      textAlign: TextAlign.center,
                      style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: AppSpacing.xs.h),
                  Text('auth.recover_subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  SizedBox(height: AppSpacing.xl.h),
                  AppTextField(
                    controller: _username,
                    enabled: !isLoading,
                    label: 'auth.username'.tr(),
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (v) =>
                        AppUtils.isBlank(v) ? 'auth.username_required'.tr() : null,
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  AppTextField(
                    controller: _code,
                    enabled: !isLoading,
                    label: 'auth.recovery_code'.tr(),
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.vpn_key_outlined),
                    validator: (v) =>
                        AppUtils.isBlank(v) ? 'auth.recovery_code_required'.tr() : null,
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  AppTextField(
                    controller: _password,
                    enabled: !isLoading,
                    label: 'auth.new_password'.tr(),
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) {
                      if (AppUtils.isBlank(v)) return 'auth.password_required'.tr();
                      if (v!.length < 8) return 'auth.password_too_short'.tr();
                      return null;
                    },
                  ),
                  SizedBox(height: AppSpacing.lg.h),
                  AppButton(
                    label: 'auth.recover_button'.tr(),
                    isLoading: isLoading,
                    isFullWidth: true,
                    onPressed: isLoading ? null : _submit,
                  ),
                  SizedBox(height: AppSpacing.md.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
